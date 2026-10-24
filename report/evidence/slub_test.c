#include <pmm.h>
#include <default_pmm.h>
#include <best_fit_pmm.h>
#include <buddy_pmm.h>
#include <slub.h>
#include <stdio.h>

#define TEST_PAGES 32768
#define FREE_START 4096
static struct Page descriptors[TEST_PAGES];
struct Page *pages = descriptors;
const size_t nbase = DRAM_BASE / PGSIZE;
size_t npage = DRAM_BASE / PGSIZE + TEST_PAGES;
uint64_t va_pa_offset = PHYSICAL_MEMORY_OFFSET;
const struct pmm_manager *pmm_manager = &buddy_pmm_manager;
static bool fail_pmm;
static size_t page_requests;

static void uart_putch(int ch, void *unused) {
    (void)unused;
    volatile unsigned char *uart = (volatile unsigned char *)0x10000000;
    while (!(uart[5] & 0x20)) {}
    uart[0] = ch;
}
int cprintf(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vprintfmt(uart_putch, NULL, fmt, ap);
    va_end(ap);
    return 0;
}
void __noreturn __panic(const char *file, int line, const char *fmt, ...) {
    cprintf("FAIL %s:%d: ", file, line);
    va_list ap;
    va_start(ap, fmt);
    vprintfmt(uart_putch, NULL, fmt, ap);
    va_end(ap);
    cprintf("\n");
    *(volatile unsigned int *)0x100000 = 0x13333;
    for (;;) {}
}
struct Page *alloc_pages(size_t n) {
    page_requests++;
    return fail_pmm ? NULL : pmm_manager->alloc_pages(n);
}
void free_pages(struct Page *base, size_t n) { pmm_manager->free_pages(base, n); }
size_t nr_free_pages(void) { return pmm_manager->nr_free_pages(); }

void test_main(void) {
    assert(((uintptr_t)test_main) >= KERNBASE);
    assert(slub_alloc(1) == NULL && page_requests == 0);
    assert(slub_usable_size(NULL) == 0);
    slub_free(NULL);
    cprintf("PASS pre-init guards; Sv39 supervisor direct mapping active\n");
    const struct pmm_manager *managers[] = {
        &buddy_pmm_manager, &best_fit_pmm_manager, &default_pmm_manager
    };
    for (size_t manager = 0; manager < sizeof(managers) / sizeof(managers[0]); manager++) {
        pmm_manager = managers[manager];
        pmm_manager->init();
        for (size_t i = 0; i < TEST_PAGES; i++) {
            pages[i].flags = pages[i].property = 0;
            pages[i].ref = 0;
            list_init(&pages[i].page_link);
            SetPageReserved(pages + i);
        }
        pmm_manager->init_memmap(pages + FREE_START, TEST_PAGES - FREE_START);
        size_t before = nr_free_pages();
        cprintf("TEST backend: %s, free pages: %lu\n", pmm_manager->name, before);
        pmm_manager->check();
        assert(nr_free_pages() == before);
        slub_init();
        fail_pmm = 1;
        assert(slub_alloc(16) == NULL && slub_alloc(5000) == NULL);
        assert(nr_free_pages() == before);
        fail_pmm = 0;
        void *held = slub_alloc(16);
        assert(held != NULL);
        size_t requests = page_requests;
        fail_pmm = 1;
        void *reused = slub_alloc(16);
        assert(reused != NULL && page_requests == requests);
        assert(slub_alloc(64) == NULL);
        slub_free(held);
        slub_free(reused);
        fail_pmm = 0;
        assert(nr_free_pages() == before);
        cprintf("PASS injected PMM failure, existing-slab reuse and recovery\n");
        slub_check();
        assert(nr_free_pages() == before);
        unsigned char *continued = slub_alloc(5000);
        assert(continued != NULL && (uintptr_t)continued >= KERNBASE);
        continued[0] = 0xAA;
        continued[4999] = 0x55;
        assert(continued[0] == 0xAA && continued[4999] == 0x55);
        slub_free(continued);
        assert(nr_free_pages() == before);
        cprintf("PASS backend %s: SLUB complete and pages restored\n", pmm_manager->name);
    }
    cprintf("ALL SLUB SV39 TESTS PASSED\n");
    *(volatile unsigned int *)0x100000 = 0x5555;
    for (;;) {}
}
