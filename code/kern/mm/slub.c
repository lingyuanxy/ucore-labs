#include <slub.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>

// LAB2 Challenge: a single-core, two-layer object allocator above the PMM.
#define SLUB_ALIGNMENT 16
#define SLUB_CLASSES 8
#define SLUB_MAX_SLOTS (PGSIZE / SLUB_ALIGNMENT)
#define SLUB_BITMAP_WORDS ((SLUB_MAX_SLOTS + 63) / 64)
#define SLUB_MAGIC 0x534c55424c414232ULL
#define SLUB_SMALL 1
#define SLUB_LARGE 2
#define SLUB_FRAME_CAPACITY ((PHYSICAL_MEMORY_END - DRAM_BASE) / PGSIZE)

struct slub_cache {
    size_t object_size;
    list_entry_t partial;
    list_entry_t full;
    size_t slabs;
    size_t inuse;
};

struct slub_slab {
    uint64_t magic;
    size_t kind;
    struct Page *page;
    struct slub_cache *cache;
    list_entry_t link;
    size_t npages;              // Original PMM request, including this header.
    size_t requested;           // Large-object usable size.
    size_t total;
    size_t inuse;
    void *free_head;            // Next pointer lives only in a free object.
    uint64_t allocated[SLUB_BITMAP_WORDS];
};

#define SLUB_DATA_OFFSET \
    ((sizeof(struct slub_slab) + SLUB_ALIGNMENT - 1) & ~(SLUB_ALIGNMENT - 1UL))

static struct slub_cache caches[SLUB_CLASSES];
static list_entry_t large_objects;
static size_t large_count;
static bool initialized;

static size_t
slub_select_size_class(size_t size) {
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
        if (size <= caches[i].object_size) {
            return i;
        }
    }
    return SLUB_CLASSES;
}

static uintptr_t
slub_physical_limit(void) {
    uintptr_t limit = npage * PGSIZE;
    return limit < PHYSICAL_MEMORY_END ? limit : PHYSICAL_MEMORY_END;
}

// KADDR is commented out in this project. Use its direct-map relationship,
// with explicit physical range checks, instead of casting a Page descriptor.
static void *
slub_page_address(struct Page *page, size_t npages) {
    uintptr_t pa = page2pa(page);
    uintptr_t limit = slub_physical_limit();
    if (pa < KERNEL_BEGIN_PADDR || pa >= limit ||
        npages == 0 || npages > (limit - pa) / PGSIZE) {
        return NULL;
    }
    return (void *)(pa + va_pa_offset);
}

static void *
slub_object_at(struct slub_slab *slab, size_t index) {
    return (void *)((uintptr_t)slab + SLUB_DATA_OFFSET +
                   index * slab->cache->object_size);
}

static size_t
slub_object_index(struct slub_slab *slab, const void *ptr) {
    uintptr_t start = (uintptr_t)slab + SLUB_DATA_OFFSET;
    uintptr_t address = (uintptr_t)ptr;
    assert(address >= start);
    size_t offset = address - start;
    assert(offset % slab->cache->object_size == 0);
    size_t index = offset / slab->cache->object_size;
    assert(index < slab->total);
    return index;
}

static bool
slub_slot_allocated(struct slub_slab *slab, size_t index) {
    return (slab->allocated[index / 64] >> (index % 64)) & 1;
}

static struct slub_slab *
slub_lookup(const void *ptr) {
    assert(initialized);
    uintptr_t address = ROUNDDOWN((uintptr_t)ptr, PGSIZE);
    uintptr_t pa = address - va_pa_offset;
    assert(pa >= KERNEL_BEGIN_PADDR && pa < slub_physical_limit());
    struct slub_slab *slab = (struct slub_slab *)address;
    assert(slab->magic == SLUB_MAGIC && slab->page == pa2page(pa));
    if (slab->kind == SLUB_SMALL) {
        assert(slab->cache != NULL);
        size_t index = slub_object_index(slab, ptr);
        assert(slub_slot_allocated(slab, index));
    } else {
        assert(slab->kind == SLUB_LARGE);
        assert((uintptr_t)ptr == address + SLUB_DATA_OFFSET);
    }
    return slab;
}

void
slub_init(void) {
    if (initialized) {
        return; // Do not reset lists if callers already own objects.
    }
    assert(pmm_manager != NULL && npage > nbase);
    assert((va_pa_offset & (PGSIZE - 1)) == 0);
    assert(SLUB_DATA_OFFSET < PGSIZE);
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
        caches[i].object_size = (size_t)SLUB_ALIGNMENT << i;
        list_init(&caches[i].partial);
        list_init(&caches[i].full);
        caches[i].slabs = caches[i].inuse = 0;
    }
    list_init(&large_objects);
    large_count = 0;
    initialized = 1;
    cprintf("slub_init: caches 16..2048 bytes, alignment 16\n");
}

static struct slub_slab *
slub_new_slab(struct slub_cache *cache) {
    struct Page *page = alloc_page();
    if (page == NULL) {
        return NULL;
    }
    struct slub_slab *slab = slub_page_address(page, 1);
    if (slab == NULL) {
        free_page(page);
        return NULL;
    }
    memset(slab, 0, sizeof(*slab));
    slab->magic = SLUB_MAGIC;
    slab->kind = SLUB_SMALL;
    slab->page = page;
    slab->cache = cache;
    slab->npages = 1;
    slab->total = (PGSIZE - SLUB_DATA_OFFSET) / cache->object_size;
    assert(slab->total > 0 && slab->total <= SLUB_MAX_SLOTS);
    for (size_t i = slab->total; i > 0; i--) {
        void *object = slub_object_at(slab, i - 1);
        *(void **)object = slab->free_head;
        slab->free_head = object;
    }
    list_add(&cache->partial, &slab->link);
    cache->slabs++;
    return slab;
}

static void *
slub_alloc_from_slab(struct slub_slab *slab) {
    assert(slab->inuse < slab->total && slab->free_head != NULL);
    void *object = slab->free_head;
    size_t index = slub_object_index(slab, object);
    assert(!slub_slot_allocated(slab, index));
    slab->free_head = *(void **)object;
    slab->allocated[index / 64] |= (uint64_t)1 << (index % 64);
    slab->inuse++;
    slab->cache->inuse++;
    if (slab->inuse == slab->total) {
        assert(slab->free_head == NULL);
        list_del(&slab->link);
        list_add(&slab->cache->full, &slab->link);
    }
    return object;
}

void *
slub_alloc(size_t size) {
    if (!initialized || size == 0) {
        return NULL;
    }
    size_t index = slub_select_size_class(size);
    if (index < SLUB_CLASSES) {
        struct slub_cache *cache = &caches[index];
        struct slub_slab *slab;
        if (list_empty(&cache->partial)) {
            slab = slub_new_slab(cache);
            if (slab == NULL) {
                return NULL;
            }
        } else {
            slab = to_struct(list_next(&cache->partial), struct slub_slab, link);
        }
        return slub_alloc_from_slab(slab);
    }
    if (size > ~(size_t)0 - SLUB_DATA_OFFSET) {
        return NULL;
    }
    size_t bytes = size + SLUB_DATA_OFFSET;
    size_t npages = (bytes - 1) / PGSIZE + 1;
    if (npage < nbase || npages > npage - nbase) {
        return NULL;
    }
    struct Page *page = alloc_pages(npages);
    if (page == NULL) {
        return NULL;
    }
    struct slub_slab *slab = slub_page_address(page, npages);
    if (slab == NULL) {
        free_pages(page, npages);
        return NULL;
    }
    memset(slab, 0, sizeof(*slab));
    slab->magic = SLUB_MAGIC;
    slab->kind = SLUB_LARGE;
    slab->page = page;
    slab->npages = npages;
    slab->requested = size;
    slab->inuse = 1;
    list_add(&large_objects, &slab->link);
    large_count++;
    return (void *)((uintptr_t)slab + SLUB_DATA_OFFSET);
}

void
slub_free(void *ptr) {
    if (ptr == NULL) {
        return;
    }
    struct slub_slab *slab = slub_lookup(ptr);
    if (slab->kind == SLUB_LARGE) {
        struct Page *page = slab->page;
        size_t npages = slab->npages;
        list_del(&slab->link);
        large_count--;
        slab->magic = 0;
        free_pages(page, npages); // Original request; PMM owns any Buddy padding.
        return;
    }
    struct slub_cache *cache = slab->cache;
    size_t index = slub_object_index(slab, ptr);
    bool was_full = slab->inuse == slab->total;
    slab->allocated[index / 64] &= ~((uint64_t)1 << (index % 64));
    *(void **)ptr = slab->free_head;
    slab->free_head = ptr;
    slab->inuse--;
    cache->inuse--;
    if (was_full) {
        list_del(&slab->link);
        list_add(&cache->partial, &slab->link);
    }
    if (slab->inuse == 0) {
        struct Page *page = slab->page;
        list_del(&slab->link);
        cache->slabs--;
        slab->magic = 0;
        free_page(page);
    }
}

size_t
slub_usable_size(const void *ptr) {
    if (ptr == NULL) {
        return 0;
    }
    struct slub_slab *slab = slub_lookup(ptr);
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
}

// Keep test storage out of the small kernel stack.
static unsigned char checked_frames[SLUB_FRAME_CAPACITY];
static void *test_objects[2 * SLUB_MAX_SLOTS + 1];

static void
slub_check_mark_pages(struct slub_slab *slab) {
    assert(slab->magic == SLUB_MAGIC);
    assert(slub_page_address(slab->page, slab->npages) == (void *)slab);
    size_t index = slab->page - pages;
    assert(npage >= nbase && npage - nbase <= SLUB_FRAME_CAPACITY);
    assert(index < npage - nbase && slab->npages <= npage - nbase - index);
    for (size_t i = index; i < index + slab->npages; i++) {
        assert(!checked_frames[i]);
        assert(!PageReserved(pages + i) && !PageProperty(pages + i));
        checked_frames[i] = 1;
    }
}

static void
slub_check_slab(struct slub_slab *slab, struct slub_cache *cache, bool full) {
    slub_check_mark_pages(slab);
    assert(slab->kind == SLUB_SMALL && slab->cache == cache && slab->npages == 1);
    assert(slab->total == (PGSIZE - SLUB_DATA_OFFSET) / cache->object_size);
    assert(slab->total > 0 && slab->total <= SLUB_MAX_SLOTS);
    assert(slab->inuse > 0 && slab->inuse <= slab->total);
    assert(full ? slab->inuse == slab->total : slab->inuse < slab->total);
    unsigned char seen[SLUB_MAX_SLOTS] = {0};
    size_t free_count = 0;
    void *object = slab->free_head;
    while (object != NULL) {
        size_t index = slub_object_index(slab, object);
        assert(!seen[index] && !slub_slot_allocated(slab, index));
        assert(++free_count <= slab->total);
        seen[index] = 1;
        object = *(void **)object;
    }
    assert(free_count + slab->inuse == slab->total);
    assert(!full || slab->free_head == NULL);
    size_t allocated = 0;
    for (size_t i = 0; i < SLUB_MAX_SLOTS; i++) {
        bool used = slub_slot_allocated(slab, i);
        if (i >= slab->total) {
            assert(!used);
            continue;
        }
        uintptr_t address = (uintptr_t)slub_object_at(slab, i);
        assert(address >= (uintptr_t)slab + SLUB_DATA_OFFSET);
        assert(address + cache->object_size <= (uintptr_t)slab + PGSIZE);
        assert((address & (SLUB_ALIGNMENT - 1)) == 0);
        assert(used ? !seen[i] : seen[i]);
        allocated += used;
    }
    assert(allocated == slab->inuse);
}

static void
slub_check_invariants(void) {
    assert(initialized);
    memset(checked_frames, 0, sizeof(checked_frames));
    size_t visited = 0;
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
        struct slub_cache *cache = &caches[i];
        assert(cache->object_size == ((size_t)SLUB_ALIGNMENT << i));
        size_t slabs = 0, inuse = 0;
        for (size_t full = 0; full < 2; full++) {
            list_entry_t *head = full ? &cache->full : &cache->partial;
            assert(list_next(list_prev(head)) == head);
            assert(list_prev(list_next(head)) == head);
            for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
                assert(++visited <= SLUB_FRAME_CAPACITY);
                assert(list_next(list_prev(le)) == le);
                assert(list_prev(list_next(le)) == le);
                struct slub_slab *slab = to_struct(le, struct slub_slab, link);
                slub_check_slab(slab, cache, full);
                slabs++;
                inuse += slab->inuse;
            }
        }
        assert(slabs == cache->slabs && inuse == cache->inuse);
    }
    size_t large = 0;
    assert(list_next(list_prev(&large_objects)) == &large_objects);
    assert(list_prev(list_next(&large_objects)) == &large_objects);
    for (list_entry_t *le = list_next(&large_objects); le != &large_objects;
         le = list_next(le)) {
        assert(++visited <= SLUB_FRAME_CAPACITY);
        assert(list_next(list_prev(le)) == le);
        assert(list_prev(list_next(le)) == le);
        struct slub_slab *slab = to_struct(le, struct slub_slab, link);
        slub_check_mark_pages(slab);
        assert(slab->kind == SLUB_LARGE && slab->cache == NULL && slab->inuse == 1);
        assert(slab->requested > caches[SLUB_CLASSES - 1].object_size);
        assert(slab->requested <= ~(size_t)0 - SLUB_DATA_OFFSET);
        assert(slab->npages == (slab->requested + SLUB_DATA_OFFSET - 1) / PGSIZE + 1);
        assert(slab->requested <= slab->npages * PGSIZE - SLUB_DATA_OFFSET);
        large++;
    }
    assert(large == large_count);
}

static void
slub_check_empty(void) {
    assert(list_empty(&large_objects) && large_count == 0);
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
        assert(caches[i].slabs == 0 && caches[i].inuse == 0);
        assert(list_empty(&caches[i].partial) && list_empty(&caches[i].full));
    }
}

static unsigned char
slub_test_pattern(size_t index, unsigned char seed) {
    return (unsigned char)(seed + index * 37);
}

static void
slub_test_fill(void *ptr, size_t size, unsigned char seed) {
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
    unsigned char *bytes = ptr;
    for (size_t i = 0; i < size; i++) {
        bytes[i] = slub_test_pattern(i, seed);
    }
}

static void
slub_test_verify(const void *ptr, size_t size, unsigned char seed) {
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
    const unsigned char *bytes = ptr;
    for (size_t i = 0; i < size; i++) {
        assert(bytes[i] == slub_test_pattern(i, seed));
    }
}

static void
slub_test_disjoint(void *a, void *b) {
    uintptr_t start_a = (uintptr_t)a, start_b = (uintptr_t)b;
    assert(a != NULL && b != NULL);
    assert(start_a + slub_usable_size(a) <= start_b ||
           start_b + slub_usable_size(b) <= start_a);
}

static void
slub_check_basic(void) {
    size_t before = nr_free_pages();
    for (size_t round = 0; round < 4; round++) {
        void *a = slub_alloc(16);
        void *b = slub_alloc(100);
        void *c = slub_alloc(64);
        assert(a != NULL && b != NULL && c != NULL);
        slub_test_disjoint(a, b);
        slub_test_disjoint(a, c);
        slub_test_disjoint(b, c);
        slub_test_fill(b, 100, 0x31);
        slub_test_verify(b, 100, 0x31);
        slub_check_invariants();
        slub_free(b);
        slub_free(a);
        slub_free(c);
        assert(nr_free_pages() == before);
    }
}

static void
slub_check_size_classes(void) {
    const size_t requests[] = {1, 8, 15, 16, 17, 24, 31, 32, 33, 63, 64, 65,
        100, 127, 128, 129, 255, 256, 257, 511, 512, 513, 1023, 1024, 1025, 2048, 2049};
    size_t count = sizeof(requests) / sizeof(requests[0]);
    size_t before = nr_free_pages();
    for (size_t i = 0; i < count; i++) {
        test_objects[i] = slub_alloc(requests[i]);
        assert(test_objects[i] != NULL);
        size_t expected = SLUB_ALIGNMENT;
        while (expected < requests[i] && expected < 2048) {
            expected <<= 1;
        }
        if (requests[i] > 2048) {
            expected = requests[i];
            assert(slub_lookup(test_objects[i])->kind == SLUB_LARGE);
        }
        assert(slub_usable_size(test_objects[i]) == expected);
        slub_test_fill(test_objects[i], expected, i);
        for (size_t j = 0; j < i; j++) {
            slub_test_disjoint(test_objects[i], test_objects[j]);
        }
    }
    slub_check_invariants();
    for (size_t i = 0; i < count; i++) {
        slub_test_verify(test_objects[i], slub_usable_size(test_objects[i]), i);
        slub_free(test_objects[i]);
    }
    assert(nr_free_pages() == before);
}

static void
slub_check_alignment(void) {
    const size_t requests[] = {1, 7, 16, 24, 64, 100, 512, 2048, 5000};
    size_t before = nr_free_pages();
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
        void *p = slub_alloc(requests[i]);
        assert(p != NULL && ((uintptr_t)p & (SLUB_ALIGNMENT - 1)) == 0);
        slub_test_fill(p, requests[i], 0x55);
        slub_test_verify(p, requests[i], 0x55);
        slub_free(p);
    }
    assert(nr_free_pages() == before);
}

static void
slub_check_data_integrity(void) {
    void *a = slub_alloc(32), *b = slub_alloc(64), *c = slub_alloc(128);
    slub_test_fill(a, 32, 0xAA);
    slub_test_fill(b, 64, 0x55);
    slub_test_fill(c, 128, 0xCC);
    slub_test_verify(a, 32, 0xAA);
    slub_test_verify(b, 64, 0x55);
    slub_test_verify(c, 128, 0xCC);
    slub_free(b);
    slub_test_verify(a, 32, 0xAA);
    slub_test_verify(c, 128, 0xCC);
    b = slub_alloc(64);
    slub_test_fill(b, 64, 0x77);
    slub_test_verify(a, 32, 0xAA);
    slub_test_verify(c, 128, 0xCC);
    slub_free(c);
    slub_free(a);
    slub_free(b);
}

static void
slub_check_reuse(void) {
    size_t before = nr_free_pages();
    for (size_t i = 0; i < 4; i++) {
        test_objects[i] = slub_alloc(32);
        slub_test_fill(test_objects[i], 32, i + 1);
        assert(ROUNDDOWN((uintptr_t)test_objects[i], PGSIZE) ==
               ROUNDDOWN((uintptr_t)test_objects[0], PGSIZE));
    }
    size_t occupied = nr_free_pages();
    void *released = test_objects[1];
    slub_free(released);
    assert(nr_free_pages() == occupied);
    test_objects[1] = slub_alloc(32);
    assert(test_objects[1] == released && nr_free_pages() == occupied);
    slub_test_fill(test_objects[1], 32, 2);
    for (size_t i = 0; i < 4; i++) {
        slub_test_verify(test_objects[i], 32, i + 1);
        slub_free(test_objects[i]);
    }
    assert(nr_free_pages() == before);
}

static void
slub_check_multi_slab(void) {
    struct slub_cache *cache = &caches[1]; // 32-byte slots
    size_t total = (PGSIZE - SLUB_DATA_OFFSET) / cache->object_size;
    size_t count = 2 * total + 1;
    assert(count <= sizeof(test_objects) / sizeof(test_objects[0]));
    size_t before = nr_free_pages();
    for (size_t i = 0; i < count; i++) {
        test_objects[i] = slub_alloc(32);
        assert(test_objects[i] != NULL && ((uintptr_t)test_objects[i] & 15) == 0);
        slub_test_fill(test_objects[i], 32, i);
        for (size_t j = 0; j < i; j++) {
            slub_test_disjoint(test_objects[i], test_objects[j]);
        }
        if (i + 1 == total) {
            assert(cache->slabs == 1 && list_empty(&cache->partial));
            assert(!list_empty(&cache->full));
        }
    }
    assert(cache->slabs == 3 && nr_free_pages() == before - 3);
    size_t index = total / 2;
    void *released = test_objects[index];
    slub_free(released);
    assert(cache->slabs == 3 && nr_free_pages() == before - 3);
    test_objects[index] = slub_alloc(32);
    assert(test_objects[index] == released && nr_free_pages() == before - 3);
    slub_test_fill(test_objects[index], 32, index);
    slub_check_invariants();
    for (size_t i = 0; i < count; i++) {
        slub_test_verify(test_objects[i], 32, i);
        slub_free(test_objects[i]);
    }
    assert(cache->slabs == 0 && nr_free_pages() == before);
}

static void
slub_check_large_alloc(void) {
    const size_t requests[] = {2049, 3000, 4096, 4097, 5000, 8192};
    size_t before = nr_free_pages();
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
        test_objects[i] = slub_alloc(requests[i]);
        assert(test_objects[i] != NULL && ((uintptr_t)test_objects[i] & 15) == 0);
        struct slub_slab *slab = slub_lookup(test_objects[i]);
        assert(slab->kind == SLUB_LARGE);
        assert(slab->npages == (requests[i] + SLUB_DATA_OFFSET - 1) / PGSIZE + 1);
        assert(slub_usable_size(test_objects[i]) >= requests[i]);
        slub_test_fill(test_objects[i], requests[i], i + 10);
        for (size_t j = 0; j < i; j++) {
            slub_test_disjoint(test_objects[i], test_objects[j]);
        }
    }
    unsigned char *cross = test_objects[4];
    const size_t positions[] = {0, 4095, 4096, 4999};
    for (size_t i = 0; i < sizeof(positions) / sizeof(positions[0]); i++) {
        cross[positions[i]] = 0xE0 + i;
    }
    for (size_t i = 0; i < sizeof(positions) / sizeof(positions[0]); i++) {
        assert(cross[positions[i]] == 0xE0 + i);
        cross[positions[i]] = slub_test_pattern(positions[i], 14);
    }
    slub_check_invariants();
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
        slub_test_verify(test_objects[i], requests[i], i + 10);
        slub_free(test_objects[i]);
    }
    assert(nr_free_pages() == before);
}

static void
slub_check_page_reclaim(void) {
    size_t before = nr_free_pages();
    for (size_t i = 0; i < 8; i++) {
        test_objects[i] = slub_alloc(16);
        assert(test_objects[i] != NULL);
        assert(ROUNDDOWN((uintptr_t)test_objects[i], PGSIZE) ==
               ROUNDDOWN((uintptr_t)test_objects[0], PGSIZE));
    }
    assert(nr_free_pages() == before - 1);
    slub_free(test_objects[0]);
    assert(nr_free_pages() == before - 1);
    for (size_t i = 1; i < 8; i++) {
        slub_free(test_objects[i]);
    }
    assert(nr_free_pages() == before);
    void *p = slub_alloc(8192);
    assert(p != NULL && nr_free_pages() < before);
    slub_free(p);
    assert(nr_free_pages() == before);
}

static void
slub_check_boundary(void) {
    size_t before = nr_free_pages();
    assert(slub_alloc(0) == NULL && slub_usable_size(NULL) == 0);
    slub_free(NULL);
    assert(slub_alloc(~(size_t)0) == NULL);
    assert(slub_alloc(~(size_t)0 - SLUB_DATA_OFFSET + 1) == NULL);
    assert(slub_alloc(~(size_t)0 - SLUB_DATA_OFFSET) == NULL);
    assert(before <= ~(size_t)0 / PGSIZE);
    // This needs more pages than are free; no unbounded exhaustion loop.
    assert(slub_alloc(before * PGSIZE) == NULL);
    assert(nr_free_pages() == before);
    void *p = slub_alloc(16);
    slub_test_fill(p, 16, 0x61);
    slub_init(); // Idempotent initialization must not discard a live object.
    slub_test_verify(p, 16, 0x61);
    slub_free(p);
    assert(nr_free_pages() == before);
    slub_check_invariants();
}

static void
slub_check_stress(void) {
    const size_t sizes[] = {1, 16, 17, 32, 33, 64, 100, 128,
        256, 513, 1024, 2048, 2049, 4096, 5000, 8192};
    void *objects[16] = {0};
    size_t requests[16] = {0};
    unsigned char patterns[16] = {0};
    uint32_t seed = 0x20261024;
    size_t before = nr_free_pages();
    for (size_t step = 0; step < 256; step++) {
        seed = seed * 1664525U + 1013904223U;
        size_t slot = (seed >> 16) % 16;
        if (objects[slot] != NULL) {
            slub_test_verify(objects[slot], requests[slot], patterns[slot]);
            slub_free(objects[slot]);
            objects[slot] = NULL;
        } else {
            seed = seed * 1664525U + 1013904223U;
            requests[slot] = sizes[(seed >> 16) % (sizeof(sizes) / sizeof(sizes[0]))];
            objects[slot] = slub_alloc(requests[slot]);
            assert(objects[slot] != NULL);
            patterns[slot] = step;
            slub_test_fill(objects[slot], requests[slot], patterns[slot]);
        }
        for (size_t i = 0; i < 16; i++) {
            if (objects[i] == NULL) {
                continue;
            }
            slub_test_verify(objects[i], requests[i], patterns[i]);
            for (size_t j = i + 1; j < 16; j++) {
                if (objects[j] != NULL) {
                    slub_test_disjoint(objects[i], objects[j]);
                }
            }
        }
        slub_check_invariants();
    }
    for (size_t i = 0; i < 16; i++) {
        if (objects[i] != NULL) {
            slub_test_verify(objects[i], requests[i], patterns[i]);
            slub_free(objects[i]);
        }
    }
    assert(nr_free_pages() == before);
}

void
slub_check(void) {
    assert(initialized);
    slub_check_empty();
    assert(nr_free_pages() >= 64);
    size_t before = nr_free_pages();
    cprintf("slub_check: begin\n");
    slub_check_invariants();
    slub_check_basic();
    cprintf("slub_check: basic passed\n");
    slub_check_size_classes();
    cprintf("slub_check: size_classes passed\n");
    slub_check_alignment();
    cprintf("slub_check: alignment passed\n");
    slub_check_data_integrity();
    cprintf("slub_check: data_integrity passed\n");
    slub_check_reuse();
    cprintf("slub_check: reuse passed\n");
    slub_check_multi_slab();
    cprintf("slub_check: multi_slab passed\n");
    slub_check_large_alloc();
    cprintf("slub_check: large_alloc passed\n");
    slub_check_page_reclaim();
    cprintf("slub_check: page_reclaim passed\n");
    slub_check_boundary();
    cprintf("slub_check: boundary passed\n");
    slub_check_stress();
    cprintf("slub_check: stress passed\n");
    slub_check_invariants();
    slub_check_empty();
    assert(nr_free_pages() == before);
    void *continuation = slub_alloc(24);
    assert(continuation != NULL);
    slub_free(continuation);
    assert(nr_free_pages() == before);
    cprintf("slub_check: all tests passed; PMM pages restored\n");
}
