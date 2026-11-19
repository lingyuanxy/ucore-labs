#include <default_pmm.h>
#include <buddy_pmm.h>
#include <defs.h>
#include <error.h>
#include <kmalloc.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <sync.h>
#include <vmm.h>
#include <riscv.h>
#include <dtb.h>

// virtual address of physical page array
struct Page *pages;
// amount of physical memory (in pages)
size_t npage = 0;
// The kernel image is mapped at VA=KERNBASE and PA=info.base
uint_t va_pa_offset;
// memory starts at 0x80000000 in RISC-V
const size_t nbase = DRAM_BASE / PGSIZE;

// virtual address of boot-time page directory
pde_t *boot_pgdir_va = NULL;
// physical address of boot-time page directory
uintptr_t boot_pgdir_pa;

// physical memory management
const struct pmm_manager *pmm_manager;

static void check_alloc_page(void);
static void check_pgdir(void);
static void check_boot_pgdir(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void)
{
#ifdef LAB4_USE_BUDDY
    pmm_manager = &buddy_pmm_manager;
#else
    pmm_manager = &default_pmm_manager;
#endif
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
static void init_memmap(struct Page *base, size_t n)
{
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n)
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
    }
    local_intr_restore(intr_flag);
    return page;
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
    }
    local_intr_restore(intr_flag);
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void)
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
    }
    local_intr_restore(intr_flag);
    return ret;
}

// lab2 2413170: physical memory discovery and Page initialization.
static void page_init(void) {
    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    uint64_t mem_base = get_memory_base();
    uint64_t mem_size = get_memory_size();
    uint64_t mem_end = mem_base + mem_size;
    cprintf("Original physical memory: base = 0x%016lx, size = 0x%016lx, end = 0x%016lx\n", mem_base, mem_size, mem_end);
    if(mem_base > KERNEL_BEGIN_PADDR) {
        panic("invalid memory base");
    }
    if(mem_base < DRAM_BASE) {
        mem_base = DRAM_BASE;
    }
    if(mem_end > PHYSICAL_MEMORY_END) {
        mem_end = PHYSICAL_MEMORY_END;
    }
    mem_size = mem_end - mem_base;
    if(mem_size == 0 || mem_end <= mem_base) {
        panic("invalid memory size");
    }

    cprintf("Available physical memory: base = 0x%016lx, size = 0x%016lx, end = 0x%016lx\n", mem_base, mem_size, mem_end);
    va_pa_offset = KERNBASE - KERNEL_BEGIN_PADDR;
    npage = mem_end / PGSIZE;

    size_t page_num = npage - nbase;
    uint64_t page_array_size = ROUNDUP(page_num * sizeof(struct Page),PGSIZE);

    extern char end[];   //链接脚本，为虚拟地址

    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);

    uintptr_t desc_end = (uintptr_t)pages + page_array_size;
    uintptr_t free_start = PADDR(ROUNDUP(desc_end, PGSIZE));   //虚拟地址转换为物理地址

    uintptr_t free_end = ROUNDDOWN(mem_end, PGSIZE);

    cprintf("Free physical memory: start = 0x%016lx, end = 0x%016lx, size = 0x%016lx\n", free_start, free_end, free_end - free_start);

    if(free_start >= free_end) {
        panic("no free memory available");
    }

    for(size_t i = 0 ; i < page_num; i++){
        pages[i].flags = 0;
        pages[i].property =0;
        set_page_ref(&pages[i], 0);
        list_init(&(pages[i].page_link));
        SetPageReserved(&pages[i]);
    }

    init_memmap(pa2page(free_start),(free_end - free_start) / PGSIZE);
}

void load_sv39_pgdir(uintptr_t pgdir_pa)
{
    write_csr(satp, ((uintptr_t)SATP_MODE_SV39 << 60) |
                    (pgdir_pa >> RISCV_PGSHIFT));
    flush_tlb();
}

// boot_map_segment - setup&enable the paging mechanism
// parameters
//  la:   linear address of this memory need to map (after x86 segment map)
//  size: memory size
//  pa:   physical address of this memory
//  perm: permission of this memory
static void boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size,
                             uintptr_t pa, uint32_t perm)
{
    assert(PGOFF(la) == PGOFF(pa));
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    for (; n > 0; n--, la += PGSIZE, pa += PGSIZE)
    {
        pte_t *ptep = get_pte(pgdir, la, 1);
        assert(ptep != NULL);
        *ptep = pte_create(pa >> PGSHIFT, perm | PTE_A | PTE_D);
    }
}

// boot_alloc_page - allocate one page using pmm->alloc_pages(1)
// return value: the kernel virtual address of this allocated page
// note: this function is used to get the memory for PDT(Page Directory
// Table)&PT(Page Table)
static void *boot_alloc_page(void)
{
    struct Page *p = alloc_page();
    if (p == NULL)
    {
        panic("boot_alloc_page failed.\n");
    }
    return page2kva(p);
}

// pmm_init - setup a pmm to manage physical memory, build PDT&PT to setup
// paging mechanism
//         - check the correctness of pmm & paging mechanism, print PDT&PT
void pmm_init(void)
{
    // We need to alloc/free the physical memory (granularity is 4KB or other
    // size).
    // So a framework of physical memory manager (struct pmm_manager)is defined
    // in pmm.h
    // First we should init a physical memory manager(pmm) based on the
    // framework.
    // Then pmm can alloc/free the physical memory.
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();

    // use pmm->check to verify the correctness of the alloc/free function in a
    // pmm
    check_alloc_page();
    // Build finer mappings while still running on the startup gigapage.
    extern char kernel_rodata_start[], kernel_data_start[];
    uintptr_t rodata = (uintptr_t)kernel_rodata_start;
    uintptr_t data = (uintptr_t)kernel_data_start;
    boot_pgdir_va = boot_alloc_page();
    memset(boot_pgdir_va, 0, PGSIZE);
    boot_pgdir_pa = PADDR(boot_pgdir_va);
    boot_map_segment(boot_pgdir_va, KERNBASE, rodata - KERNBASE,
                     KERNEL_BEGIN_PADDR, PTE_R | PTE_X);
    boot_map_segment(boot_pgdir_va, rodata, data - rodata,
                     PADDR(rodata), PTE_R);
    boot_map_segment(boot_pgdir_va, data, npage * PGSIZE - PADDR(data),
                     PADDR(data), PTE_R | PTE_W);
    load_sv39_pgdir(boot_pgdir_pa);

    check_pgdir();

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // now the basic virtual memory map(see memalyout.h) is established.
    // check the correctness of the basic virtual memory map.
    check_boot_pgdir();

    kmalloc_init();
}

// get_pte - get pte and return the kernel virtual address of this pte for la
//        - if the PT contians this pte didn't exist, alloc a page for PT
// parameter:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
    struct Page *new_directory = NULL;
    if (!(*pdep1 & PTE_V))
    {
        if (!create || (new_directory = alloc_page()) == NULL)
        {
            return NULL;
        }
        set_page_ref(new_directory, 1);
        memset(page2kva(new_directory), 0, PGSIZE);
        *pdep1 = pte_create(page2ppn(new_directory), 0);
    }
    if (!PTE_TABLE(*pdep1))
    {
        return NULL;
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V))
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
        {
            if (new_directory != NULL)
            {
                *pdep1 = 0;
                tlb_invalidate(pgdir, la);
                free_page(new_directory);
            }
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep0 = pte_create(page2ppn(page), 0);
    }
    if (!PTE_TABLE(*pdep0))
    {
        return NULL;
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
}

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
    pte_t *ptep = get_pte(pgdir, la, 0);
    if (ptep_store != NULL)
    {
        *ptep_store = ptep;
    }
    if (ptep != NULL && *ptep & PTE_V)
    {
        return pte2page(*ptep);
    }
    return NULL;
}

// LAB4 function1 2413170
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    pte_t *ptep = get_pte(pgdir, la, 1);
    if (ptep == NULL)
    {
        local_intr_restore(intr_flag);
        return -E_NO_MEM;
    }

    struct Page *old = (*ptep & PTE_V) ? pte2page(*ptep) : NULL;
    if (old != page)
    {
        page_ref_inc(page);
    }
    // Permission 0 defaults to readable, and Sv39 write permission needs R.
    if (!(perm & PTE_X) || (perm & PTE_W))
    {
        perm |= PTE_R;
    }
    *ptep = pte_create(page2ppn(page), perm);
    tlb_invalidate(pgdir, la);
    if (old != NULL && old != page && page_ref_dec(old) == 0)
    {
        free_page(old);
    }
    local_intr_restore(intr_flag);
    return 0;
}

void page_remove(pde_t *pgdir, uintptr_t la)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    pte_t *ptep = get_pte(pgdir, la, 0);
    if (ptep != NULL && (*ptep & PTE_V))
    {
        struct Page *page = pte2page(*ptep);
        *ptep = 0;
        tlb_invalidate(pgdir, la);
        if (page_ref_dec(page) == 0)
        {
            free_page(page);
        }
    }
    local_intr_restore(intr_flag);
}

// Lab4 uses one hart and ASID 0, so invalidating by address is sufficient.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la) : "memory");
}

static void check_alloc_page(void)
{
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}

static void check_pgdir(void)
{
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
    assert(pte2page(*ptep) == p1);
    assert(page_ref(p1) == 1);

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
    assert(*ptep & PTE_U);
    assert(*ptep & PTE_W);
    assert(PTE_TABLE(boot_pgdir_va[0]) && !(boot_pgdir_va[0] & PTE_U));
    assert(page_ref(p2) == 1);

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
    assert(page_ref(p1) == 2);
    assert(page_ref(p2) == 0);
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
    assert(pte2page(*ptep) == p1);
    assert((*ptep & PTE_U) == 0);

    page_remove(boot_pgdir_va, 0x0);
    assert(page_ref(p1) == 1);
    assert(page_ref(p2) == 0);

    page_remove(boot_pgdir_va, PGSIZE);
    assert(page_ref(p1) == 0);
    assert(page_ref(p2) == 0);

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
    flush_tlb();

    assert(nr_free_store == nr_free_pages());

    cprintf("check_pgdir() succeeded!\n");
}

static void check_boot_pgdir(void)
{
    size_t nr_free_store;
    pte_t *ptep;

    nr_free_store = nr_free_pages();

    for (uintptr_t pa = KERNEL_BEGIN_PADDR; pa < npage * PGSIZE; pa += PGSIZE)
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(pa), 0)) != NULL);
        assert((*ptep & PTE_V) && PTE_ADDR(*ptep) == pa);
    }

    assert(boot_pgdir_va[0] == 0);

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
    assert(page_ref(p) == 1);
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
    assert(page_ref(p) == 2);

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);

    *(char *)(page2kva(p) + 0x100) = '\0';
    assert(strlen((const char *)0x100) == 0);

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
    flush_tlb();

    assert(nr_free_store == nr_free_pages());

    cprintf("check_boot_pgdir() succeeded!\n");
}

// perm2str - use string 'u,r,w,-' to present the permission
static const char *perm2str(int perm)
{
    static char str[4];
    str[0] = (perm & PTE_U) ? 'u' : '-';
    str[1] = 'r';
    str[2] = (perm & PTE_W) ? 'w' : '-';
    str[3] = '\0';
    return str;
}

// get_pgtable_items - In [left, right] range of PDT or PT, find a continuous
// linear addr space
//                  - (left_store*X_SIZE~right_store*X_SIZE) for PDT or PT
//                  - X_SIZE=PTSIZE=4M, if PDT; X_SIZE=PGSIZE=4K, if PT
// paramemters:
//  left:        no use ???
//  right:       the high side of table's range
//  start:       the low side of table's range
//  table:       the beginning addr of table
//  left_store:  the pointer of the high side of table's next range
//  right_store: the pointer of the low side of table's next range
//  return value: 0 - not a invalid item range, perm - a valid item range with
//  perm permission
static int get_pgtable_items(size_t left, size_t right, size_t start,
                             uintptr_t *table, size_t *left_store,
                             size_t *right_store)
{
    if (start >= right)
    {
        return 0;
    }
    while (start < right && !(table[start] & PTE_V))
    {
        start++;
    }
    if (start < right)
    {
        if (left_store != NULL)
        {
            *left_store = start;
        }
        int perm = (table[start++] & PTE_USER);
        while (start < right && (table[start] & PTE_USER) == perm)
        {
            start++;
        }
        if (right_store != NULL)
        {
            *right_store = start;
        }
        return perm;
    }
    return 0;
}
