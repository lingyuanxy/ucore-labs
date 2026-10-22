#include <buddy_pmm.h>
#include <list.h>
#include <stdio.h>

/* lab2 buddy 2413170: the framework maps at most 32768 physical pages. */
#define MAX_ORDER 15
static list_entry_t areas[MAX_ORDER + 1];
static size_t free_count;

static size_t block_size(unsigned order) { return (size_t)1 << order; }

static unsigned request_order(size_t n) {
    unsigned order = 0;
    while (order <= MAX_ORDER && block_size(order) < n) order++;
    return order;
}

static void buddy_init(void) {
    for (unsigned i = 0; i <= MAX_ORDER; i++) list_init(&areas[i]);
    free_count = 0;
}

static void add_block(struct Page *base, unsigned order) {
    base->property = block_size(order);
    SetPageProperty(base);
    list_add(&areas[order], &base->page_link);
}

static void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    for (struct Page *p = base; p < base + n; p++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    free_count += n;
    while (n != 0) {
        unsigned order = 0;
        while (order < MAX_ORDER && block_size(order + 1) <= n &&
               (page2ppn(base) & (block_size(order + 1) - 1)) == 0) order++;
        add_block(base, order);
        base += block_size(order);
        n -= block_size(order);
    }
}

static struct Page *buddy_alloc_pages(size_t n) {
    assert(n > 0);
    unsigned target = request_order(n), order = target;
    if (target > MAX_ORDER || block_size(target) > free_count) return NULL;
    while (order <= MAX_ORDER && list_empty(&areas[order])) order++;
    if (order > MAX_ORDER) return NULL;
    struct Page *page = le2page(list_next(&areas[order]), page_link);
    list_del(&page->page_link);
    ClearPageProperty(page);
    while (order > target) {
        order--;
        add_block(page + block_size(order), order);
    }
    page->property = block_size(target); /* allocated capacity, not a free flag */
    free_count -= block_size(target);
    return page;
}

static void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    unsigned order = request_order(n);
    assert(order <= MAX_ORDER);
    size_t capacity = block_size(order);
    assert(base >= pages && base + capacity <= pages + npage - nbase);
    assert(!PageReserved(base) && !PageProperty(base));
    assert(base->property == capacity);
    assert((page2ppn(base) & (capacity - 1)) == 0);
    for (struct Page *p = base; p < base + capacity; p++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->property = 0;
        set_page_ref(p, 0);
    }
    free_count += capacity;
    while (order < MAX_ORDER) {
        size_t buddy_ppn = page2ppn(base) ^ block_size(order);
        if (buddy_ppn < nbase || buddy_ppn + block_size(order) > npage) break;
        struct Page *buddy = pages + buddy_ppn - nbase;
        if (!PageProperty(buddy) || buddy->property != block_size(order)) break;
        list_del(&buddy->page_link);
        ClearPageProperty(buddy);
        buddy->property = 0;
        if (buddy < base) base = buddy;
        order++;
    }
    add_block(base, order);
}

static size_t buddy_nr_free_pages(void) { return free_count; }

/* Check actual structure and accounting, rather than just boot messages. */
static void verify_lists(void) {
    size_t sum = 0;
    for (unsigned i = 0; i <= MAX_ORDER; i++) {
        list_entry_t *head = &areas[i];
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p) && !PageReserved(p));
            assert(p->property == block_size(i));
            assert((page2ppn(p) & (block_size(i) - 1)) == 0);
            assert(list_next(list_prev(le)) == le && list_prev(list_next(le)) == le);
            sum += p->property;
            assert(sum <= free_count);
        }
    }
    assert(sum == free_count);
}

static void buddy_check(void) {
    verify_lists();
    size_t initial = free_count;
    /* Borrow an aligned 32-page block; run all tests on its 31-page suffix. */
    struct Page *arena = buddy_alloc_pages(32);
    assert(arena != NULL);
    list_entry_t saved[MAX_ORDER + 1];
    for (unsigned i = 0; i <= MAX_ORDER; i++) saved[i] = areas[i];
    size_t saved_count = free_count;
    buddy_init();
    for (size_t i = 1; i < 32; i++) SetPageReserved(arena + i);
    buddy_init_memmap(arena + 1, 31);
    assert(free_count == 31);
    verify_lists();

    struct Page *a = buddy_alloc_pages(3);
    assert(a != NULL && a->property == 4 && free_count == 27);
    assert((page2ppn(a) & 3) == 0);
    struct Page *b = buddy_alloc_pages(8);
    assert(b != NULL && (a + 4 <= b || b + 8 <= a));
    buddy_free_pages(a, 3);
    buddy_free_pages(b, 8);
    assert(free_count == 31);
    verify_lists();

    struct Page *all[31];
    for (size_t i = 0; i < 31; i++) {
        all[i] = buddy_alloc_pages(1);
        assert(all[i] != NULL);
        for (size_t j = 0; j < i; j++) assert(all[i] != all[j]);
    }
    assert(free_count == 0 && buddy_alloc_pages(1) == NULL);
    assert(buddy_alloc_pages((size_t)-1) == NULL && free_count == 0);

    /* Adjacent physical pages 1 and 2 are not buddies: 1 XOR 1 = 0. */
    struct Page *p1 = arena + 1, *p2 = arena + 2;
    buddy_free_pages(p1, 1);
    buddy_free_pages(p2, 1);
    assert(free_count == 2 && buddy_alloc_pages(2) == NULL);
    assert(PageProperty(p1) && PageProperty(p2));
    for (int i = 30; i >= 0; i--)
        if (all[i] != p1 && all[i] != p2) buddy_free_pages(all[i], 1);
    assert(free_count == 31);
    verify_lists();
    struct Page *large = buddy_alloc_pages(16);
    assert(large == arena + 16); /* restored by recursive buddy coalescing */
    buddy_free_pages(large, 16);
    assert(buddy_alloc_pages(32) == NULL && free_count == 31);

    /* Drop isolated lists and return the borrowed block to the real allocator. */
    for (size_t i = 0; i < 32; i++) {
        arena[i].flags = arena[i].property = 0;
        set_page_ref(arena + i, 0);
    }
    arena->property = 32;
    for (unsigned i = 0; i <= MAX_ORDER; i++) areas[i] = saved[i];
    free_count = saved_count;
    buddy_free_pages(arena, 32);
    assert(free_count == initial);
    verify_lists();
    cprintf("[Buddy] alignment, rounding, splitting, exhaustion, non-buddy and coalescing: PASS\n");
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
