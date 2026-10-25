# Lab2 实现规格与提示词

日期：2026-10-22。下面是本次实现使用的结构化任务规格，由助手根据课程手册整理；不是用户原始消息的逐字转录。格式按课程纪要插图的 PROMPT、RELY、GUARANTEE、SPECIFICATION 四段组织。

用户确认范围：先完成所有内容，再提供学习路线。因此包含 SLUB 选做。

## 1. 物理内存初始化

```text
[PROMPT]
在 kern/mm/pmm.c 的 lab2 function1 位置实现 static void page_init(void)。

[RELY]
dtb_init 已解析设备树；get_memory_base/size 提供一个连续 RAM 区间。
当前框架以 DRAM_BASE 为描述符数组原点，映射上界为 PHYSICAL_MEMORY_END。
可用 end、Page、PADDR、PPN、ROUNDUP/ROUNDDOWN、init_memmap。

[GUARANTEE]
区分物理地址、虚拟地址、页号和描述符地址。不得把 OpenSBI、内核或
Page 数组分配出去。设备树无效时 panic；空闲区不足一页时不注册。

[SPECIFICATION]
检查 RAM 区间及溢出，设置 va_pa_offset，限制管理上界并向下按页对齐。
npage 为管理上界的绝对页号；pages 位于 end 后的页对齐虚拟地址。
为 npage-nbase 个描述符初始化 reserved、ref、property 和链表。
数组末尾转为物理地址后向上对齐，把剩余完整页交给 init_memmap。
打印实际 RAM 区间、管理上界、数组及空闲区，保留 lab2 注释并填学号 2413170。
```

## 2. Best Fit

```text
[PROMPT]
在 best_fit_pmm.c 的 lab2 function2-2 位置实现完整 Best Fit 并注册管理器。
[RELY]
阅读 default_pmm.c、pmm.h、list.h 和本文件的两个框架检查函数。
[GUARANTEE]
basic_check 和 best_fit_check 必须原样保留。free_list、nr_free 状态约定兼容。
空闲块按地址排序；只在空闲块首描述符设置 PG_property。
[SPECIFICATION]
实现 init、init_memmap、alloc_pages、free_pages、nr_free_pages、manager。
分配遍历全部空闲块，选最小且足够大的块，相同大小选低地址；精确命中可停止。
拆分后保留余块；释放按地址插入，先合并前邻再合并后邻，准确维护页数。
将 pmm.c 默认管理器切换为 best_fit_pmm_manager。不得改评分测试。
```

## 3. Buddy System 实现

```text
[PROMPT]
从零实现 buddy_pmm.c/h，并通过 PMM=buddy 构建接入内核。
[RELY]
pmm_manager 的 alloc_pages 允许返回至少 n 页；有效 free 与原始请求 n 配对。
物理页号由 page2ppn 获得，PG_property 表示空闲块首，property 记录块页数。
[GUARANTEE]
不改变 Best Fit 默认构建和课程评分逻辑。伙伴关系用绝对物理页号 XOR 求得。
非 2 的幂请求向上取整；释放同样按原请求取整，内部碎片须在报告中说明。
[SPECIFICATION]
按阶维护空闲链表和空闲页总数。将初始非对齐连续区间拆为最大对齐幂次块。
分配从足够大的最小非空阶逐级拆分；释放只与同阶且空闲的真实伙伴递归合并。
分配失败不改变状态。拒绝 0 页请求，超大请求返回 NULL。
保留头页实际容量用于检查配对释放；不得使用动态内存保存自身元数据。
```

## 4. Buddy System 测试（独立测试任务规格）

```text
[PROMPT]
针对上述 Buddy 模块设计内核检查函数，并在 PMM=buddy 启动时执行。
[RELY]
允许调用模块内部检查辅助函数；所有请求均有匹配释放；不得依赖具体空闲页起始地址。
[GUARANTEE]
检查不能只验证打印字符串；断言失败必须终止并显示具体位置。
隔离小型非对齐测试区，结束后恢复真实空闲区及计数，不能丢失页面。
[SPECIFICATION]
检查初始化分解、物理地址对齐、分配不重叠、请求 3 页取整为 4 页、计数变化。
检查大块拆分、相邻但非伙伴不能合并、不同顺序释放后的递归合并。
穷尽测试区后再分配失败，失败前后计数不变；测试超大请求失败。
最后验证所有阶链表结构、property 与物理对齐以及总页数恢复。
```

## 5. GDB 观察地址翻译

```text
[PROMPT]
使用本机 QEMU 4.1.1 的带符号构建和 GDB，记录真实的地址翻译观测。
[RELY]
宿主 GDB 调试 x86_64 QEMU，RISC-V GDB 连接 QEMU stub 调试内核。
entry.S 根表第 511 项是 1GiB 叶映射，不能预设一定遍历三级。
[GUARANTEE]
只把真实输出写入日志。区分调试器读内存与 CPU 访存触发的翻译。
[SPECIFICATION]
记录 Bare 与 Sv39 的分支差异，定位 tlb_fill、get_physical_address、tlb_set_page。
对 kern_init 的虚拟地址设置条件断点，观察 satp、根表物理地址、索引、PTE、
叶级别、权限检查和最终 PA，记录 TLB 插入路径并解释快路径查询位置。
提供可重复执行的命令或脚本及日志，报告中说明优化构建的单步局限。
```

## 6. SLUB 实现（选做）

```text
[PROMPT]
从零实现简化的 SLUB 风格 kmalloc/kfree，两层分别使用现有页分配器和对象缓存。
[RELY]
单核顺序执行；物理页可加 va_pa_offset 转为内核指针；页大小 4096。
Best Fit 分配恰好 n 页，Buddy 分配至少 n 页；free_pages 必须传原请求页数。
[GUARANTEE]
返回至少满足请求的 16 字节对齐空间，0 字节返回 NULL，kfree(NULL) 无操作。
不用动态内存管理分配器元数据。完整页释放回底层，不能永久泄漏空 slab。
[SPECIFICATION]
用 16/32/64/128/256/512/1024/2048 八个大小类管理小对象，每个 slab 占一页。
页内头记录缓存、空闲对象链、已用数和分配位图；缓存维护 partial slab 链表。
大于 2048 字节时按页申请连续空间，页头记录原请求页数供释放。
检查大小溢出、非法边界和重复释放；简单版本不包含多核锁和 per-CPU 缓存。
```

## 7. SLUB 测试（独立测试任务规格，选做）

```text
[PROMPT]
为上述 SLUB 分配器编写真实的内核断言测试，并在两种底层 PMM 上运行。
[RELY]
kmalloc/kfree 已接入 kern_init；nr_free_pages 可度量页面回收。
[GUARANTEE]
测试写入并核对每个对象的全部请求空间；不得只验证返回指针非 NULL。
[SPECIFICATION]
覆盖每个大小类边界、超过一页的大对象、0 字节、NULL 释放和超大失败请求。
检查指针对齐及不同存活对象不重叠。连续申请 300 个最小对象以跨越 slab。
交错释放并重新申请，验证存活对象内容不变。释放全部对象后检查空闲页数恢复。
使用 Best Fit 与 Buddy 分别启动运行，检验大对象的原请求页数释放约定。
```
