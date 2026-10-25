/* Extra audit cases. The original driver and allocator sources stay unchanged. */
#define test_main preserved_driver_main
#include "../report/evidence/slub_test.c"
#undef test_main

/* Include the unchanged reference implementation to inspect its private list. */
#include "../code/kern/mm/default_pmm.c"

static void audit_reset(const struct pmm_manager *manager) {
    pmm_manager = manager;
    pmm_manager->init();
    for (size_t i = 0; i < TEST_PAGES; i++) {
        pages[i].flags = pages[i].property = 0;
        pages[i].ref = 0;
        list_init(&pages[i].page_link);
        SetPageReserved(pages + i);
    }
}

static bool reference_list_valid(size_t expected) {
    list_entry_t *head = &free_list;
    list_entry_t *previous = head;
    list_entry_t *node = list_next(head);
    size_t count = 0;
    while (node != head && count <= expected) {
        if (list_prev(node) != previous) {
            return 0;
        }
        previous = node;
        node = list_next(node);
        count++;
    }
    return node == head && count == expected && list_prev(head) == previous;
}

void test_main(void) {
    const struct pmm_manager *managers[] = {
        &default_pmm_manager, &best_fit_pmm_manager, &buddy_pmm_manager
    };
    size_t known_failures = 0;
    for (size_t m = 0; m < sizeof(managers) / sizeof(managers[0]); m++) {
        struct Page *base = pages + FREE_START;
        audit_reset(managers[m]);
        pmm_manager->init_memmap(base, 2);
        pmm_manager->init_memmap(base + 4, 2);
        assert(nr_free_pages() == 4);
        if (m == 0 && !reference_list_valid(2)) {
            cprintf("KNOWN_FAILURE First-Fit init_memmap tail insertion: "
                    "tail.prev == tail: %d; disjoint blocks [0,2), [4,6)\n",
                    list_prev(&(base + 4)->page_link) == &(base + 4)->page_link);
            known_failures++;
        } else {
            struct Page *a = alloc_pages(2);
            struct Page *b = alloc_pages(2);
            assert(a == base && b == base + 4 && nr_free_pages() == 0);
            free_pages(a, 2);
            free_pages(b, 2);
            assert(nr_free_pages() == 4);
            cprintf("PASS %s: disjoint init_memmap tail insertion\n", pmm_manager->name);
        }

        audit_reset(managers[m]);
        pmm_manager->init_memmap(base, 8);
        struct Page *allocated[4];
        for (size_t i = 0; i < 4; i++) {
            allocated[i] = alloc_pages(2);
            assert(allocated[i] == base + 2 * i);
        }
        assert(nr_free_pages() == 0);
        free_pages(allocated[0], 2);
        free_pages(allocated[2], 2);
        assert(nr_free_pages() == 4);
        if (m == 0 && !reference_list_valid(2)) {
            cprintf("KNOWN_FAILURE First-Fit free_pages tail insertion: "
                    "tail.prev == tail: %d; freed blocks [0,2), [4,6)\n",
                    list_prev(&allocated[2]->page_link) == &allocated[2]->page_link);
            known_failures++;
        } else {
            struct Page *a = alloc_pages(2);
            struct Page *b = alloc_pages(2);
            assert(a == allocated[0] && b == allocated[2]);
            assert(nr_free_pages() == 0);
            free_pages(a, 2);
            free_pages(b, 2);
            free_pages(allocated[1], 2);
            free_pages(allocated[3], 2);
            assert(nr_free_pages() == 8);
            cprintf("PASS %s: free_pages tail insertion and recovery\n", pmm_manager->name);
        }
    }
    cprintf("AUDIT COMPLETE: %lu known failures; unchanged sources\n", known_failures);
    assert(known_failures == 2);
    /* Success here means the audit reproduced its two expected defects. */
    *(volatile unsigned int *)0x100000 = 0x5555;
    for (;;) {}
}
