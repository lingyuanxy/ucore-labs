#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <defs.h>

// All successful allocations are at least 16-byte aligned.
void slub_init(void);
void *slub_alloc(size_t size);
void slub_free(void *ptr);
size_t slub_usable_size(const void *ptr);
// Boot-time tests require no pre-existing live SLUB objects.
void slub_check(void);

#endif /* !__KERN_MM_SLUB_H__ */
