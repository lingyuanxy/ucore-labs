#include <slub.h>
#include <pmm.h>
#include <list.h>
#include <stdio.h>
#include <string.h>

/* lab2 SLUB challenge 2413170: single-hart teaching implementation. */
#define NCLASS 8
#define SLAB_MAGIC 0x534c5542534d414cUL
#define LARGE_MAGIC 0x534c55424c415247UL

struct object_cache {
    size_t size;
    list_entry_t partial;
};

/* 96-byte header leaves up to 250 sixteen-byte slots; 256 bitmap bits suffice. */
struct slab_page {
    uint64_t magic;
    list_entry_t link;
    struct object_cache *cache;
    void *free;
    size_t inuse;
    size_t capacity;
    size_t npages;
    uint64_t allocated[4];
};

static struct object_cache caches[NCLASS];

void slub_init(void) {
    assert(sizeof(struct slab_page) % 16 == 0);
    for (unsigned i = 0; i < NCLASS; i++) {
        caches[i].size = (size_t)16 << i;
        list_init(&caches[i].partial);
    }
}

static struct slab_page *new_slab(struct object_cache *cache) {
    struct Page *p = alloc_page();
    if (p == NULL) return NULL;
    struct slab_page *slab = (void *)(page2pa(p) + va_pa_offset);
    memset(slab, 0, PGSIZE);
    slab->magic = SLAB_MAGIC;
    slab->cache = cache;
    slab->capacity = (PGSIZE - sizeof(*slab)) / cache->size;
    slab->npages = 1;
    char *data = (char *)(slab + 1);
    for (size_t i = slab->capacity; i > 0; i--) {
        void *object = data + (i - 1) * cache->size;
        *(void **)object = slab->free;
        slab->free = object;
    }
    list_add(&cache->partial, &slab->link);
    return slab;
}

void *kmalloc(size_t size) {
    if (size == 0) return NULL;
    if (size > caches[NCLASS - 1].size) {
        if (size > (size_t)-1 - sizeof(struct slab_page) - (PGSIZE - 1)) return NULL;
        size_t n = ROUNDUP(size + sizeof(struct slab_page), PGSIZE) / PGSIZE;
        struct Page *p = alloc_pages(n);
        if (p == NULL) return NULL;
        struct slab_page *header = (void *)(page2pa(p) + va_pa_offset);
        memset(header, 0, sizeof(*header));
        header->magic = LARGE_MAGIC;
        header->npages = n;
        header->capacity = size;
        return header + 1;
    }
    unsigned index = 0;
    while (caches[index].size < size) index++;
    struct object_cache *cache = &caches[index];
    struct slab_page *slab;
    if (list_empty(&cache->partial)) {
        slab = new_slab(cache);
        if (slab == NULL) return NULL;
    } else {
        slab = to_struct(list_next(&cache->partial), struct slab_page, link);
    }
    void *object = slab->free;
    assert(object != NULL && slab->inuse < slab->capacity);
    slab->free = *(void **)object;
    size_t slot = ((char *)object - (char *)(slab + 1)) / cache->size;
    uint64_t bit = (uint64_t)1 << (slot % 64);
    assert(!(slab->allocated[slot / 64] & bit));
    slab->allocated[slot / 64] |= bit;
    if (++slab->inuse == slab->capacity) list_del(&slab->link);
    return object;
}

void kfree(void *ptr) {
    if (ptr == NULL) return;
    struct slab_page *slab = (void *)ROUNDDOWN((uintptr_t)ptr, PGSIZE);
    if (slab->magic == LARGE_MAGIC) {
        assert(ptr == slab + 1);
        size_t n = slab->npages;
        slab->magic = 0;
        free_pages(pa2page(PADDR(slab)), n);
        return;
    }
    assert(slab->magic == SLAB_MAGIC);
    struct object_cache *cache = slab->cache;
    uintptr_t offset = (uintptr_t)ptr - (uintptr_t)(slab + 1);
    assert((uintptr_t)ptr >= (uintptr_t)(slab + 1));
    assert(offset % cache->size == 0);
    size_t slot = offset / cache->size;
    assert(slot < slab->capacity && slab->inuse > 0);
    uint64_t bit = (uint64_t)1 << (slot % 64);
    assert(slab->allocated[slot / 64] & bit);
    slab->allocated[slot / 64] &= ~bit;
    if (slab->inuse == slab->capacity) list_add(&cache->partial, &slab->link);
    *(void **)ptr = slab->free;
    slab->free = ptr;
    if (--slab->inuse == 0) {
        list_del(&slab->link);
        slab->magic = 0;
        free_page(pa2page(PADDR(slab)));
    }
}

static void verify_bytes(void *p, size_t size, unsigned char value) {
    unsigned char *bytes = p;
    for (size_t i = 0; i < size; i++) assert(bytes[i] == value);
}

void slub_check(void) {
    size_t before = nr_free_pages();
    assert(kmalloc(0) == NULL);
    kfree(NULL);
    assert(kmalloc((size_t)-1) == NULL && nr_free_pages() == before);
    const size_t sizes[] = {1, 16, 17, 31, 32, 33, 63, 64, 65, 127, 128,
        129, 255, 256, 257, 511, 512, 513, 1023, 1024, 1025, 2047, 2048,
        2049, 4096, 4097, 8193};
    void *objects[sizeof(sizes) / sizeof(sizes[0])];
    for (size_t i = 0; i < sizeof(objects) / sizeof(objects[0]); i++) {
        objects[i] = kmalloc(sizes[i]);
        assert(objects[i] != NULL && ((uintptr_t)objects[i] & 15) == 0);
        for (size_t j = 0; j < i; j++) {
            uintptr_t a = (uintptr_t)objects[i], b = (uintptr_t)objects[j];
            assert(a + sizes[i] <= b || b + sizes[j] <= a);
        }
        memset(objects[i], (unsigned char)(i + 1), sizes[i]);
    }
    for (size_t i = 0; i < sizeof(objects) / sizeof(objects[0]); i++) {
        verify_bytes(objects[i], sizes[i], i + 1);
        kfree(objects[i]);
    }
    assert(nr_free_pages() == before);

    void *small[300];
    for (size_t i = 0; i < 300; i++) {
        small[i] = kmalloc(16);
        assert(small[i] != NULL);
        memset(small[i], (unsigned char)i, 16);
    }
    for (size_t i = 0; i < 300; i += 2) kfree(small[i]);
    for (size_t i = 0; i < 300; i += 2) {
        small[i] = kmalloc(16);
        assert(small[i] != NULL);
        memset(small[i], (unsigned char)i, 16);
    }
    for (size_t i = 0; i < 300; i++) {
        verify_bytes(small[i], 16, (unsigned char)i);
        kfree(small[i]);
    }
    assert(nr_free_pages() == before);
    for (unsigned i = 0; i < NCLASS; i++) assert(list_empty(&caches[i].partial));
    cprintf("[SLUB] size classes, alignment, payload, multi-slab, reuse, large objects and reclaim: PASS\n");
}
