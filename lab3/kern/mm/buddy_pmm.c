#include <buddy_pmm.h>
#include <stdio.h>

// LAB2 task 3: Buddy System, with original-size and partial-release support.
#define BUDDY_PAGE_CAPACITY ((PHYSICAL_MEMORY_END - DRAM_BASE) / PGSIZE)
#define BUDDY_ORDERS (sizeof(size_t) * 8)
#define BUDDY_NO_RECORD ((uint32_t)-1)
#define BUDDY_TEST_PAGES 64

struct buddy_allocation {
    uint32_t start;
    uint32_t span;
    uint32_t live;
    union {
        uint32_t requested;
        uint32_t next;
    };
};

struct buddy_state {
    list_entry_t free_list[BUDDY_ORDERS];
    size_t nr_free;
    size_t nr_managed;
    size_t max_order;
    uint32_t first_record;
    // Allocation records are separate from page heads: a partially freed head
    // may be reallocated while its original allocation still owns other pages.
    struct buddy_allocation allocation[BUDDY_PAGE_CAPACITY];
    uint32_t owner[BUDDY_PAGE_CAPACITY]; // record index + 1; zero means unowned
    unsigned char managed[BUDDY_PAGE_CAPACITY];
};

static struct buddy_state kernel_state;
static struct buddy_state test_state;
static struct buddy_state *buddy = &kernel_state;
static void buddy_check(void);

static size_t
buddy_page_count(void) {
    assert(npage >= nbase);
    assert(npage - nbase <= BUDDY_PAGE_CAPACITY);
    return npage - nbase;
}

static size_t
buddy_range_index(struct Page *base, size_t n) {
    size_t count = buddy_page_count();
    assert(base >= pages && base < pages + count);
    size_t index = base - pages;
    assert(n > 0 && n <= count - index);
    return index;
}

static size_t
buddy_get_order(size_t n) {
    size_t order = 0, size = 1;
    while (size < n && order < buddy->max_order) {
        order++;
        size <<= 1;
    }
    return size >= n ? order : BUDDY_ORDERS;
}

static void
buddy_init(void) {
    for (size_t order = 0; order < BUDDY_ORDERS; order++) {
        list_init(&buddy->free_list[order]);
    }
    buddy->nr_free = buddy->nr_managed = 0;
    buddy->max_order = 0;
    while (buddy->max_order + 1 < BUDDY_ORDERS &&
           ((size_t)1 << (buddy->max_order + 1)) <= BUDDY_PAGE_CAPACITY) {
        buddy->max_order++;
    }
    buddy->first_record = 0;
    for (size_t i = 0; i < BUDDY_PAGE_CAPACITY; i++) {
        buddy->owner[i] = buddy->managed[i] = 0;
        buddy->allocation[i].live = 0;
        buddy->allocation[i].next = i + 1 < BUDDY_PAGE_CAPACITY
                                      ? i + 1 : BUDDY_NO_RECORD;
    }
}

static void
buddy_insert_block(struct Page *base, size_t order) {
    size_t size = (size_t)1 << order;
    assert((page2ppn(base) & (size - 1)) == 0);
    base->property = size;
    SetPageProperty(base);
    list_entry_t *head = &buddy->free_list[order];
    list_entry_t *le = list_next(head);
    for (; le != head; le = list_next(le)) {
        if (base < le2page(le, page_link)) {
            break;
        }
    }
    list_add_before(le, &base->page_link);
}

static void
buddy_remove_block(struct Page *base) {
    assert(PageProperty(base));
    list_del(&base->page_link);
    list_init(&base->page_link);
    ClearPageProperty(base);
    base->property = 0;
}

static struct Page *
buddy_find_partner(struct Page *base, size_t order) {
    size_t size = (size_t)1 << order;
    size_t ppn = page2ppn(base);
    assert((ppn & (size - 1)) == 0);
    size_t partner_ppn = ppn ^ size;
    size_t count = buddy_page_count();
    if (partner_ppn < nbase || partner_ppn - nbase >= count) {
        return NULL;
    }
    size_t index = partner_ppn - nbase;
    if (size > count - index || !buddy->managed[index] ||
        buddy->owner[index] != 0) {
        return NULL;
    }
    struct Page *partner = pages + index;
    if (PageReserved(partner) || !PageProperty(partner) ||
        partner->property != size) {
        return NULL;
    }
    return partner;
}

// Only the caller updates nr_free; splitting and merging preserve page count.
static void
buddy_release_block(struct Page *base, size_t order) {
    while (order < buddy->max_order) {
        struct Page *partner = buddy_find_partner(base, order);
        if (partner == NULL) {
            break;
        }
        buddy_remove_block(partner);
        if (partner < base) {
            base = partner;
        }
        order++;
    }
    buddy_insert_block(base, order);
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    size_t index = buddy_range_index(base, n);
    for (size_t i = 0; i < n; i++) {
        assert(PageReserved(base + i));
        assert(!buddy->managed[index + i]);
    }
    for (size_t i = 0; i < n; i++) {
        struct Page *page = base + i;
        page->flags = page->property = 0;
        set_page_ref(page, 0);
        list_init(&page->page_link);
        buddy->managed[index + i] = 1;
        buddy->owner[index + i] = 0;
    }
    buddy->nr_free += n;
    buddy->nr_managed += n;
    while (n != 0) {
        size_t order = 0;
        while (order < buddy->max_order) {
            size_t next_size = (size_t)1 << (order + 1);
            if (next_size > n || (page2ppn(base) & (next_size - 1)) != 0) {
                break;
            }
            order++;
        }
        size_t size = (size_t)1 << order;
        buddy_release_block(base, order);
        base += size;
        n -= size;
    }
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    size_t order = buddy_get_order(n);
    if (order == BUDDY_ORDERS) {
        return NULL;
    }
    size_t size = (size_t)1 << order;
    if (size > buddy->nr_free) {
        return NULL;
    }
    size_t found = order;
    while (found <= buddy->max_order && list_empty(&buddy->free_list[found])) {
        found++;
    }
    if (found > buddy->max_order) {
        return NULL;
    }
    struct Page *base = le2page(list_next(&buddy->free_list[found]), page_link);
    buddy_remove_block(base);
    while (found > order) {
        found--;
        buddy_insert_block(base + ((size_t)1 << found), found);
    }
    uint32_t id = buddy->first_record;
    assert(id != BUDDY_NO_RECORD);
    struct buddy_allocation *allocation = &buddy->allocation[id];
    buddy->first_record = allocation->next;
    size_t index = buddy_range_index(base, size);
    allocation->start = index;
    allocation->span = size;
    allocation->requested = n;
    allocation->live = n;
    for (size_t i = 0; i < size; i++) {
        assert(buddy->managed[index + i] && buddy->owner[index + i] == 0);
        assert(!PageReserved(base + i) && !PageProperty(base + i));
        buddy->owner[index + i] = id + 1;
    }
    buddy->nr_free -= size;
    return base;
}

static void
buddy_release_page(size_t index) {
    struct Page *page = pages + index;
    buddy->owner[index] = 0;
    page->flags = page->property = 0;
    set_page_ref(page, 0);
    buddy->nr_free++;
    buddy_release_block(page, 0);
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    size_t index = buddy_range_index(base, n);
    // Validate the entire caller-visible range before changing any state.
    // A release may cover a subrange, or adjacent allocations without padding.
    for (size_t i = index; i < index + n; i++) {
        assert(buddy->managed[i] && buddy->owner[i] != 0);
        assert(!PageReserved(pages + i) && !PageProperty(pages + i));
        struct buddy_allocation *allocation = &buddy->allocation[buddy->owner[i] - 1];
        assert(allocation->live > 0 && i >= allocation->start);
        assert(i - allocation->start < allocation->requested);
    }
    for (size_t i = index; i < index + n; i++) {
        uint32_t id = buddy->owner[i] - 1;
        struct buddy_allocation *allocation = &buddy->allocation[id];
        buddy_release_page(i);
        allocation->live--;
        if (allocation->live == 0) {
            // Keep rounded-up tail pages until the last requested page is freed.
            // This also handles freeing and reusing an allocation's head first.
            for (size_t tail = allocation->requested; tail < allocation->span; tail++) {
                size_t padding = allocation->start + tail;
                assert(buddy->owner[padding] == id + 1);
                buddy_release_page(padding);
            }
            allocation->next = buddy->first_record;
            buddy->first_record = id;
        }
    }
}

static size_t
buddy_nr_free_pages(void) {
    return buddy->nr_free;
}

// Test scratch is static so the checks fit the kernel's small boot stack.
static unsigned char check_free[BUDDY_PAGE_CAPACITY];
static unsigned char check_records[BUDDY_PAGE_CAPACITY];
static uint32_t check_live[BUDDY_PAGE_CAPACITY];

static void
buddy_check_invariants(void) {
    size_t count = buddy_page_count();
    for (size_t i = 0; i < BUDDY_PAGE_CAPACITY; i++) {
        check_free[i] = check_records[i] = 0;
        check_live[i] = 0;
    }
    size_t free_count = 0, nodes = 0;
    for (size_t order = 0; order < BUDDY_ORDERS; order++) {
        list_entry_t *head = &buddy->free_list[order];
        assert(list_next(list_prev(head)) == head);
        assert(list_prev(list_next(head)) == head);
        list_entry_t *le = list_next(head);
        struct Page *previous = NULL;
        while (le != head) {
            assert(order <= buddy->max_order && ++nodes <= count);
            assert(list_next(list_prev(le)) == le);
            assert(list_prev(list_next(le)) == le);
            struct Page *base = le2page(le, page_link);
            size_t size = (size_t)1 << order;
            size_t index = buddy_range_index(base, size);
            assert(previous == NULL || previous < base);
            previous = base;
            assert(PageProperty(base) && base->property == size);
            assert((page2ppn(base) & (size - 1)) == 0);
            for (size_t i = index; i < index + size; i++) {
                assert(buddy->managed[i] && buddy->owner[i] == 0);
                assert(!PageReserved(pages + i) && page_ref(pages + i) == 0);
                assert(!check_free[i]);
                assert(i == index || !PageProperty(pages + i));
                check_free[i] = 1;
            }
            if (order < buddy->max_order) {
                assert(buddy_find_partner(base, order) == NULL);
            }
            free_count += size;
            le = list_next(le);
        }
    }
    assert(free_count == buddy->nr_free);
    size_t managed = 0, owned = 0;
    for (size_t i = 0; i < BUDDY_PAGE_CAPACITY; i++) {
        if (!buddy->managed[i]) {
            assert(buddy->owner[i] == 0 && !check_free[i]);
            continue;
        }
        assert(i < count && !PageReserved(pages + i));
        managed++;
        if (buddy->owner[i] == 0) {
            assert(check_free[i]);
            continue;
        }
        owned++;
        assert(!check_free[i] && !PageProperty(pages + i));
        uint32_t id = buddy->owner[i] - 1;
        assert(id < BUDDY_PAGE_CAPACITY);
        struct buddy_allocation *allocation = &buddy->allocation[id];
        assert(allocation->live > 0 && allocation->requested > 0);
        assert(allocation->requested <= allocation->span);
        assert(i >= allocation->start && i - allocation->start < allocation->span);
        if (i - allocation->start < allocation->requested) {
            check_live[id]++;
        }
    }
    assert(managed == buddy->nr_managed && free_count + owned == managed);
    uint32_t id = buddy->first_record;
    size_t free_records = 0;
    while (id != BUDDY_NO_RECORD) {
        assert(id < BUDDY_PAGE_CAPACITY && ++free_records <= BUDDY_PAGE_CAPACITY);
        assert(!check_records[id] && buddy->allocation[id].live == 0);
        check_records[id] = 1;
        id = buddy->allocation[id].next;
    }
    for (size_t i = 0; i < BUDDY_PAGE_CAPACITY; i++) {
        struct buddy_allocation *allocation = &buddy->allocation[i];
        assert(allocation->live == check_live[i]);
        if (allocation->live == 0) {
            assert(check_records[i]);
            continue;
        }
        assert(!check_records[i]);
        size_t size = allocation->span;
        assert(size > 0 && (size & (size - 1)) == 0);
        assert(size <= count && allocation->start <= count - size);
        assert(((nbase + allocation->start) & (size - 1)) == 0);
        for (size_t tail = allocation->requested; tail < size; tail++) {
            assert(buddy->owner[allocation->start + tail] == i + 1);
        }
    }
}

static void
buddy_check_basic(void) {
    size_t before = nr_free_pages();
    for (size_t round = 0; round < 4; round++) {
        struct Page *a = alloc_pages(1);
        struct Page *b = alloc_pages(1);
        struct Page *c = alloc_pages(1);
        assert(a != NULL && b != NULL && c != NULL);
        assert(a != b && a != c && b != c);
        assert(page2ppn(a) >= nbase && page2ppn(a) < npage);
        assert(page2ppn(b) >= nbase && page2ppn(b) < npage);
        assert(page2ppn(c) >= nbase && page2ppn(c) < npage);
        assert(page_ref(a) == 0 && page_ref(b) == 0 && page_ref(c) == 0);
        assert(!PageProperty(a) && !PageProperty(b) && !PageProperty(c));
        assert(nr_free_pages() == before - 3);
        free_pages(b, 1);
        free_pages(a, 1);
        free_pages(c, 1);
        assert(nr_free_pages() == before);
        buddy_check_invariants();
    }
}

// The arena is held by a live kernel allocation throughout these tests.
// Switch to a separate state object; never copy circular list sentinels.
static void
buddy_test_reset(struct Page *arena) {
    assert(buddy == &test_state);
    buddy_init();
    for (size_t i = 0; i < BUDDY_TEST_PAGES; i++) {
        arena[i].flags = arena[i].property = 0;
        set_page_ref(arena + i, 0);
        list_init(&arena[i].page_link);
        SetPageReserved(arena + i);
    }
}

static void
buddy_check_init_memmap(struct Page *arena) {
    const size_t sizes[] = {1, 2, 4, 8, 3, 13};
    for (size_t i = 0; i < sizeof(sizes) / sizeof(sizes[0]); i++) {
        buddy_test_reset(arena);
        buddy_init_memmap(arena, sizes[i]);
        assert(nr_free_pages() == sizes[i]);
        if ((sizes[i] & (sizes[i] - 1)) == 0) {
            assert(PageProperty(arena) && arena->property == sizes[i]);
        }
        buddy_check_invariants();
    }
    buddy_test_reset(arena);
    buddy_init_memmap(arena + 1, 13);
    assert(nr_free_pages() == 13 && PageReserved(arena));
    buddy_check_invariants();

    buddy_test_reset(arena);
    buddy_init_memmap(arena + 1, 3);
    buddy_init_memmap(arena + 8, 5);
    assert(nr_free_pages() == 8);
    for (size_t i = 4; i < 8; i++) {
        assert(PageReserved(arena + i));
    }
    buddy_check_invariants();
    struct Page *p = alloc_pages(4);
    assert(p == arena + 8);
    free_pages(p, 4);
    assert(nr_free_pages() == 8);
    buddy_check_invariants();

    buddy_test_reset(arena);
    buddy_init_memmap(arena, 3);
    buddy_init_memmap(arena + 3, 5);
    assert(nr_free_pages() == 8 && arena->property == 8);
    buddy_check_invariants();
}

static void
buddy_check_split(struct Page *arena) {
    const size_t requests[] = {4, 2, 1, 8};
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
        buddy_test_reset(arena);
        buddy_init_memmap(arena, 8);
        size_t request = requests[i];
        struct Page *p = alloc_pages(request);
        assert(p == arena && !PageProperty(p));
        assert(nr_free_pages() == 8 - request);
        for (size_t size = request; size < 8; size <<= 1) {
            assert(PageProperty(arena + size));
            assert(arena[size].property == size);
        }
        buddy_check_invariants();
        free_pages(p, request);
        assert(nr_free_pages() == 8 && arena->property == 8);
        buddy_check_invariants();
    }
}

static void
buddy_check_merge(struct Page *arena) {
    for (size_t reverse = 0; reverse < 2; reverse++) {
        buddy_test_reset(arena);
        buddy_init_memmap(arena, 8);
        struct Page *allocated[8];
        for (size_t i = 0; i < 8; i++) {
            allocated[i] = alloc_pages(1);
            assert(allocated[i] == arena + i);
        }
        for (size_t i = 0; i < 8; i++) {
            free_pages(allocated[reverse ? 7 - i : i], 1);
            assert(nr_free_pages() == i + 1);
            if (!reverse && (i == 1 || i == 3 || i == 7)) {
                assert(arena->property == i + 1);
            }
            buddy_check_invariants();
        }
        assert(PageProperty(arena) && arena->property == 8);
    }
}

static void
buddy_check_partner(struct Page *arena) {
    buddy_test_reset(arena);
    buddy_init_memmap(arena, 8);
    struct Page *allocated[8];
    for (size_t i = 0; i < 8; i++) {
        allocated[i] = alloc_pages(1);
        assert(allocated[i] == arena + i);
    }
    free_pages(allocated[1], 1);
    free_pages(allocated[2], 1);
    assert(arena[1].property == 1 && arena[2].property == 1);
    assert((page2ppn(arena + 1) ^ 1) == page2ppn(arena));
    assert(buddy_find_partner(arena + 1, 0) == NULL);
    buddy_check_invariants();
    free_pages(allocated[0], 1);
    assert(arena->property == 2 && arena[2].property == 1);
    assert(buddy_find_partner(arena, 1) == NULL);
    assert(buddy_find_partner(arena + 5, 0) == NULL);
    for (size_t i = 3; i < 8; i++) {
        free_pages(allocated[i], 1);
    }
    assert(arena->property == 8 && nr_free_pages() == 8);
    buddy_check_invariants();

    buddy_test_reset(arena);
    buddy_init_memmap(arena + 1, 1);
    assert(buddy_find_partner(arena + 1, 0) == NULL);
    assert(PageReserved(arena));
    // The maximum-order partner of the DRAM base lies beyond this platform.
    assert(buddy_find_partner(pages, buddy->max_order) == NULL);
    buddy_check_invariants();
}

static void
buddy_check_non_power_two(struct Page *arena) {
    const size_t requests[] = {1, 2, 3, 5, 6, 7, 8, 9};
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
        buddy_test_reset(arena);
        buddy_init_memmap(arena, BUDDY_TEST_PAGES);
        size_t n = requests[i];
        size_t size = (size_t)1 << buddy_get_order(n);
        size_t before = nr_free_pages();
        struct Page *p = alloc_pages(n);
        assert(p != NULL && (page2ppn(p) & (size - 1)) == 0);
        assert(before - nr_free_pages() == size);
        uint32_t owner = buddy->owner[p - pages];
        assert(buddy->allocation[owner - 1].span == size);
        for (size_t j = 0; j < size; j++) {
            assert(!PageProperty(p + j) && buddy->owner[p - pages + j] == owner);
        }
        struct Page *other = alloc_pages(1);
        assert(other != NULL && (other < p || other >= p + size));
        free_pages(p, n);
        free_pages(other, 1);
        assert(nr_free_pages() == before && arena->property == BUDDY_TEST_PAGES);
        buddy_check_invariants();
    }

    // Release a head, reuse it, then release the rest of the old allocation.
    buddy_test_reset(arena);
    buddy_init_memmap(arena, 16);
    struct Page *p = alloc_pages(5);
    assert(p == arena && nr_free_pages() == 8);
    free_pages(p + 1, 2);
    free_pages(p, 1);
    assert(nr_free_pages() == 11);
    struct Page *replacement = alloc_pages(2);
    assert(replacement == p);
    buddy_check_invariants();
    free_pages(p + 3, 2);
    assert(nr_free_pages() == 14);
    buddy_check_invariants();
    free_pages(replacement, 2);
    assert(nr_free_pages() == 16 && arena->property == 16);
    buddy_check_invariants();

    struct Page *a = alloc_pages(2);
    struct Page *b = alloc_pages(2);
    assert(a == arena && b == a + 2);
    free_pages(a, 4);
    assert(nr_free_pages() == 16 && arena->property == 16);
    buddy_check_invariants();
}

static void
buddy_check_exhaustion(struct Page *arena) {
    buddy_test_reset(arena);
    buddy_init_memmap(arena, 8);
    struct Page *allocated[8];
    for (size_t i = 0; i < 8; i++) {
        allocated[i] = alloc_pages(1);
        assert(allocated[i] == arena + i);
    }
    assert(nr_free_pages() == 0 && alloc_pages(1) == NULL);
    buddy_check_invariants();
    for (size_t i = 0; i < 8; i += 2) {
        free_pages(allocated[i], 1);
    }
    assert(nr_free_pages() == 4 && alloc_pages(2) == NULL);
    buddy_check_invariants();
    for (size_t i = 1; i < 8; i += 2) {
        free_pages(allocated[i], 1);
    }
    assert(nr_free_pages() == 8);
    assert(alloc_pages(9) == NULL);
    assert(alloc_pages(BUDDY_PAGE_CAPACITY + 1) == NULL);
    assert(alloc_pages(~(size_t)0) == NULL);
    assert(alloc_pages((size_t)1 << (BUDDY_ORDERS - 1)) == NULL);
    assert(nr_free_pages() == 8);
    struct Page *p = alloc_pages(8);
    assert(p == arena);
    free_pages(p, 8);
    buddy_check_invariants();
}

static void
buddy_check_stress(struct Page *arena) {
    buddy_test_reset(arena);
    buddy_init_memmap(arena, BUDDY_TEST_PAGES);
    struct Page *allocated[16] = {0};
    size_t requests[16] = {0};
    uint32_t seed = 0x20261024;
    for (size_t step = 0; step < 256; step++) {
        seed = seed * 1664525U + 1013904223U;
        size_t slot = (seed >> 16) % 16;
        size_t before = nr_free_pages();
        if (allocated[slot] != NULL) {
            size_t size = (size_t)1 << buddy_get_order(requests[slot]);
            free_pages(allocated[slot], requests[slot]);
            allocated[slot] = NULL;
            assert(nr_free_pages() == before + size);
        } else {
            seed = seed * 1664525U + 1013904223U;
            requests[slot] = 1 + (seed >> 16) % 9;
            allocated[slot] = alloc_pages(requests[slot]);
            size_t size = (size_t)1 << buddy_get_order(requests[slot]);
            assert(nr_free_pages() == before - (allocated[slot] != NULL ? size : 0));
        }
        for (size_t i = 0; i < 16; i++) {
            if (allocated[i] == NULL) {
                continue;
            }
            size_t size_i = (size_t)1 << buddy_get_order(requests[i]);
            for (size_t j = i + 1; j < 16; j++) {
                if (allocated[j] != NULL) {
                    size_t size_j = (size_t)1 << buddy_get_order(requests[j]);
                    assert(allocated[i] + size_i <= allocated[j] ||
                           allocated[j] + size_j <= allocated[i]);
                }
            }
        }
        buddy_check_invariants();
    }
    for (size_t i = 0; i < 16; i++) {
        if (allocated[i] != NULL) {
            free_pages(allocated[i], requests[i]);
        }
    }
    assert(nr_free_pages() == BUDDY_TEST_PAGES);
    assert(PageProperty(arena) && arena->property == BUDDY_TEST_PAGES);
    buddy_check_invariants();
}

static void
buddy_check(void) {
    assert(buddy == &kernel_state);
    cprintf("buddy_check: begin\n");
    buddy_check_invariants();
    buddy_check_basic();
    cprintf("buddy_check: basic passed\n");
    size_t before = nr_free_pages();
    struct Page *arena = alloc_pages(BUDDY_TEST_PAGES);
    assert(arena != NULL);
    buddy = &test_state;
    buddy_check_init_memmap(arena);
    cprintf("buddy_check: init_memmap passed\n");
    buddy_check_split(arena);
    cprintf("buddy_check: split passed\n");
    buddy_check_merge(arena);
    cprintf("buddy_check: merge passed\n");
    buddy_check_partner(arena);
    cprintf("buddy_check: partner passed\n");
    buddy_check_non_power_two(arena);
    cprintf("buddy_check: non_power_two and partial release passed\n");
    buddy_check_exhaustion(arena);
    cprintf("buddy_check: exhaustion passed\n");
    buddy_check_stress(arena);
    cprintf("buddy_check: stress passed\n");

    // Restore only the held arena's descriptors to their allocated state.
    // The kernel state's lists and allocation records were never copied/reset.
    for (size_t i = 0; i < BUDDY_TEST_PAGES; i++) {
        arena[i].flags = arena[i].property = 0;
        set_page_ref(arena + i, 0);
        list_init(&arena[i].page_link);
    }
    buddy = &kernel_state;
    free_pages(arena, BUDDY_TEST_PAGES);
    assert(nr_free_pages() == before);
    buddy_check_invariants();
    struct Page *continuation = alloc_pages(1);
    assert(continuation != NULL);
    free_pages(continuation, 1);
    assert(nr_free_pages() == before);
    cprintf("buddy_check: all tests passed; kernel state restored\n");
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
