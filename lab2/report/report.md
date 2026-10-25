# Lab2：物理内存和页表实验报告

> 更新日期：2026 年 10 月 24 日。本文根据 Lab2 指导书全部章节、当前源代码、实际提示词和编译运行记录整理。报告按提交要求命名为 `report.md`；个人分工及提交标识的待确认事项见第十三节。

完整提示词汇总见 [prompt.md](prompt.md)，题目一实操对话见 [gdb_test_1.md](gdb_test_1.md)。

## 一、实验信息、目标与完成情况

| 项目 | 内容 |
| --- | --- |
| 实验名称 | Lab2：物理内存和页表 |
| 成员信息 | 仓库 Lab1 报告登记为 2413170—李孟德、2412075—朱钟铭；Lab2 分工需成员确认 |
| 代码目录 | [code](../code/) |
| AI 辅助工具 | Codex；用于概念解释、引导审阅、按规格实现和验证，具体模型版本未另行记录 |
| 实验范围 | 物理内存探测、页描述符、First-Fit、Best-Fit、Buddy、SLUB，以及 Sv39/TLB 调试 |

实验的目标是建立从硬件内存描述到可用物理页、再到字节大小对象的管理链条，同时理解内核如何通过页表访问这些物理内存。算法实现和地址翻译是相互配合的两部分：页分配器确定一段物理内存归谁使用，页表确定处理器如何通过虚拟地址访问它。

| 指导书任务 | 当前完成内容 | 验证依据 |
| --- | --- | --- |
| 模块一任务一 | `page_init()` 探测、布局、描述符初始化及空闲区登记 | 完整内核启动，RAM 和空闲区输出符合计算 |
| 模块一 Challenge | 获取硬件可用内存范围的思考题 | 第五节 |
| 模块二任务一 | 理解 First-Fit 四个核心函数及改进空间 | 源码分析；三后端测试运行原有检查 |
| 模块二任务二 | Best-Fit 完整模块、注册、精确匹配提前退出 | 原有 `basic_check()`、`best_fit_check()` 在专项驱动中执行 |
| 模块二任务三 | Buddy 模块、接入及独立测试 | 完整内核及专项驱动通过 Buddy 全部检查 |
| SLUB Challenge | 对象分配模块、接入、设计说明及测试 | 完整内核通过；三种 PMM 后端专项验证通过 |
| GDB 分支任务 | 实际访存指令、QEMU 查表、TLB 查询与回填、M 模式对照 | 第十节及保存的两层 GDB 日志 |

当前 `init_pmm_manager()` 选择 `buddy_pmm_manager`，是完成任务三后的最终状态。Best-Fit 阶段的实现仍保留并可注册；专项驱动实际选择它执行了原有检查。不能将当前 Buddy 启动日志称为“当前内核正在运行 Best-Fit”。

## 二、实验环境与证据

### 2.1 编译和运行环境

实验使用 Linux、RV64 交叉工具链和 QEMU `virt` 开发板，默认 RAM 为 128 MiB。

| 工具 | 实际路径与版本 |
| --- | --- |
| 交叉编译器 | `/home/viewfinder/toolchains/os-freedom-tools/bin/riscv64-unknown-elf-gcc`，10.2.0 |
| 本轮标准启动及源码调试的 QEMU | `/home/viewfinder/qemu-4.1.1/riscv64-softmmu/qemu-system-riscv64`，4.1.1，带调试信息 |
| 对应固件 | QEMU 4.1.1 默认 OpenSBI v0.4 |
| 先前专项测试使用的 QEMU | `/opt/qemu-4.1.1/bin/qemu-system-riscv64`，**实际为 7.0.0** |
| 调试器 | 宿主机 GDB 调试 QEMU 进程；RISC-V GDB 通过 GDB stub 调试内核 |

目录名不能作为软件版本证据。本轮执行 `--version` 后发现 `/opt/qemu-4.1.1/` 中实际安装的是 7.0.0，已更正先前记录。QEMU 版本、固件和源码必须匹配，尤其是设置源码行断点时。版本原始输出见 [versions.txt](evidence/versions.txt)。

内核使用 GNU C99、`-mcmodel=medany`、`-nostdinc`、`-fno-builtin` 等选项，依赖实验自带头文件，不能用宿主机 GCC 的默认环境代替。先前编辑器配置中出现宿主 GCC 覆盖交叉编译器、头文件路径只覆盖 Lab1 的问题，已在前期配置工作中调整；编辑器不报错本身不能证明内核运行正确。

### 2.2 验证记录与边界

原始记录集中于 [evidence/README.md](evidence/README.md)：完整交叉编译日志、真实 QEMU 4.1.1 启动日志、三种后端的 Sv39 专项日志，以及宿主机和内核 GDB 脚本与输出。ELF/镜像摘要用于标明本轮调试对应的构建，报告中的地址只对该构建有效。

本次补全报告没有修改 `code` 中的实现。测试结论限于当前单核教学平台和所列用例；没有进行多核并发、全部畸形设备树输入或长期随机负载的穷尽验证。

## 三、本章整体逻辑与启动关系

指导书先介绍地址空间、分页和 TLB，再解释内核启动如何建立初始映射；随后研究如何发现 RAM、建立页描述符、组织连续空闲物理页，最后以 SLUB 将页级分配扩展到对象级分配。GDB 分支任务则从模拟器内部观察此前依赖的地址翻译机制。

实际启动链为：

```text
OpenSBI：准备启动参数，a1 指向 DTB
  → kern_entry：准备栈、设置 satp、sfence.vma、切换到内核高地址
  → kern_init：清理 BSS，初始化控制台和 DTB
      → dtb_init：解析并保存 RAM 起点、大小
      → pmm_init
          → init_pmm_manager：选择 Buddy，初始化管理器内部状态
          → page_init：建立 pages[]，排除占用区
              → init_memmap：调用当前管理器登记可用页
          → check_alloc_page：运行当前管理器检查
      → slub_init → slub_check
      → 内核现有空闲循环
```

`pmm_init() → init_pmm_manager() → page_init() → init_memmap() → alloc_pages()/free_pages()` 表示功能上的推进链，后几个函数并非都由前一个逐项直接调用。`pmm.c` 的 `init_memmap()` 已经提供转发；任务一需要补的是 `page_init()`，不需要重新发明这层公共接口。

`struct pmm_manager` 用函数指针统一 `init`、`init_memmap`、`alloc_pages`、`free_pages`、`nr_free_pages` 和 `check`。First-Fit、Best-Fit、Buddy 改变内部策略，上层页分配接口保持一致；SLUB 位于这一接口之上。

启动顺序还有一个依赖：早期先通过静态页表建立可访问 RAM 的映射，之后才使用动态物理页管理器。因此初始页表不依赖 SLUB 或尚未初始化的 PMM。

## 四、功能模块一任务一：物理内存初始化

实现位置：[pmm.c](../code/kern/mm/pmm.c)。

### 4.1 功能规格与提示词设计

`static void page_init(void)` 无参数、无返回值。其前提是 DTB 已解析、当前管理器已经初始化、内核直接映射可用。成功返回时必须满足：

1. 设置 `va_pa_offset`、`npage` 和 `pages`，建立描述符与物理页的对应关系。
2. 根据硬件信息及平台上界确定管理范围，输出原始、裁剪后和最终空闲范围。
3. 描述符数组位于内核镜像之后，所有被占用页面不会进入空闲区。
4. 全部描述符先处于已初始化的保留状态，只有完整可用页交给管理器。
5. 无效内存信息终止初始化；没有可用完整页时不调用 `init_memmap()`，当前实现选择 `panic()`。

这一阶段实际采用“本人编写，AI 引导审阅，本人修改”的方式，代表性原始提问为：

> 帮我核定一下page_init的正误并引导我修改，不要直接肯定或否定我，要引导式教学，如果发现我有一些地方理解错误要指出来

> 如何检查内存信息是否有效

> pages[] 描述符数组 怎么放置？从哪开始放置

规格是根据指导书的成功条件、地址边界和接口前置条件逐步明确的，没有使用一条提示词直接生成整个最终函数。这里保留实际交互方式，不把事后整理的规格当作最初提交的生成提示词。

### 4.2 检查 RAM 范围

`get_memory_base()`、`get_memory_size()` 返回 DTB 解析结果。先用原始起点和大小计算末端，再裁剪区间，避免改变起点后错误地平移整个 RAM 范围。

当前代码检查 RAM 起点不能高于 `KERNEL_BEGIN_PADDR`，将低于 `DRAM_BASE` 的起点提升到 `DRAM_BASE`，将超过 `PHYSICAL_MEMORY_END` 的末端裁剪到该上界，再计算 `mem_size = mem_end - mem_base` 并拒绝空区间或反向区间。后续还检查描述符之后是否有完整空闲页。

需要区分“设备树报告 RAM”和“现在可以分配的 RAM”。`Available physical memory` 这一输出标签实际表示裁剪后的管理范围，其中仍包含内核等占用部分；`Free physical memory` 才是提交给 PMM 的区间。

本轮验证了默认 DTB 的正常路径。设备树加法溢出、多个离散内存段、保留节点等复杂输入尚未完成独立注入测试，不能仅根据正常启动宣称所有硬件布局都已支持。当前实现以本实验的单段 RAM 和固定平台上界为前提。

### 4.3 四类地址与页描述符

| 概念 | 本实验中的含义 |
| --- | --- |
| 物理地址 PA | RAM 中的字节地址，如 `0x804d6000` |
| 物理页号 PPN | `PA / PGSIZE`，不含页内偏移 |
| 内核虚拟地址 VA | 处理器开启分页后使用的地址 |
| `struct Page *` | 指向管理信息的指针，不是对应物理页的数据地址 |

`va_pa_offset` 保存内核直接映射区的固定偏移：

```text
va_pa_offset = KERNBASE - KERNEL_BEGIN_PADDR = 0xffffffff40000000
VA = PA + va_pa_offset
PA = VA - va_pa_offset
```

该关系只适用于当前直接映射范围，不能用于任意用户虚拟地址。

`nbase = DRAM_BASE / PGSIZE` 是起始物理页号，`npage = mem_end / PGSIZE` 是页号上界，因此描述符数量是 `npage - nbase`。`mem_base` 用来解释和裁剪硬件范围；数组下标约定则由框架固定的 `DRAM_BASE` 决定，两者职责不同。不能因为数量公式中没有再次出现 `mem_base`，就认为它没有用途。

```text
pa2page(pa) = pages + (PPN(pa) - nbase)
page2ppn(page) = (page - pages) + nbase
page2pa(page) = page2ppn(page) * PGSIZE
```

`pa2page()` 返回包含该物理地址的页的描述符。通过 `Page *` 找到数据，要先 `page2pa()`，再按直接映射关系转换为内核可访问地址。

`struct Page` 在本次 RV64 构建中大小为 40 字节：

| 字段 | 用途 |
| --- | --- |
| `ref` | 页面引用计数 |
| `flags` | 保留状态、空闲块首页等标志 |
| `property` | 对空闲块首页记录连续块页数；其含义需结合标志判断 |
| `page_link` | 嵌入的双向链表节点，连接空闲块首页 |

管理信息和物理页数据分开，使页面可以完整存放内核数据，也能在不访问或覆盖页内数据的情况下检查空闲状态。`page_link` 保存前后链表节点地址；`le2page()` 借助成员偏移找到所属描述符。链表中一个节点可以代表多页，不是每个空闲页都必须各占一个节点。

### 4.4 描述符布局与初始化

`end` 是链接脚本给出的内核虚拟地址末端，包含 BSS。数组起点向上按页对齐：

```c
pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
size_t page_num = npage - nbase;
uint64_t page_array_size = ROUNDUP(page_num * sizeof(struct Page), PGSIZE);
uintptr_t desc_end = (uintptr_t)pages + page_array_size;
uintptr_t free_start = PADDR(ROUNDUP(desc_end, PGSIZE));
uintptr_t free_end = ROUNDDOWN(mem_end, PGSIZE);
```

先确认 `free_start < free_end`，然后遍历 `page_num` 个描述符，清零标志、引用计数和 `property`，初始化链表节点并设置 `PageReserved`。给 `pages` 赋值只确定数组位置，不会自动初始化每个元素。

`pages + page_num` 按元素移动，已经隐含乘以 `sizeof(struct Page)`；`(uintptr_t)pages + byte_count` 才按字节移动。因此 `(uintptr_t)(pages + page_num)` 是正确的未对齐数组末端表达式，不能再乘一次描述符大小。

随后执行：

```c
init_memmap(pa2page(free_start), (free_end - free_start) / PGSIZE);
```

公共函数转发到当前管理器。管理器解除这部分页的保留状态并组织空闲块；OpenSBI、内核镜像、启动页表、静态管理数据和描述符数组仍被排除。

内核占用的 RAM 属于物理内存，但当前不属于可分配的空闲物理内存。描述符需要覆盖这些页，才能统一表示它们的状态，所以描述符数量大于空闲页数。

`page_init()` 不设置 `base->property = n`，因为它负责确定和初始化页面全集；`default_init_memmap()` 才负责把给定空闲区组织成一个块，块首页的 `property = n` 属于分配器自己的表示。Buddy 还可能将同一区间拆成多个不同阶的块。

### 4.5 本次布局的实际核对

完整启动日志给出 RAM `[0x80000000, 0x88000000)`，以下均采用左闭右开区间：

| 项目 | 实际值或由实际值计算的结果 |
| --- | --- |
| 页大小 | `0x1000`，4096 字节 |
| `nbase` / `npage` | `0x80000` / `0x88000` |
| 描述符数量 | `0x8000`，32768 |
| 链接符号 `end` | `0xffffffffc0395a90` |
| `pages` 起点 | `0xffffffffc0396000`，物理地址 `0x80396000` |
| 数组占用 | `32768 × 40 = 0x140000` 字节 |
| 最终空闲区 | `[0x804d6000, 0x88000000)` |
| 初始空闲页数 | `0x7b2a000 / 0x1000 = 31530` |

这里不是把 32768 页全部加入空闲链表。描述符数组本身占用 320 页；其前面的固件、内核等占用也必须排除。Buddy 和测试状态的静态数组已经计入内核 `end`，不会再次被分配。

## 五、模块一 Challenge：如何获取可用物理内存范围

如果 OS 无法预先知道 RAM 范围，首选由固件或引导程序提供硬件内存描述。本实验通过 OpenSBI 传入的 DTB 地址，解析内存节点 `reg` 属性取得 RAM 的起点和长度。

其他平台可通过 BIOS E820、UEFI `GetMemoryMap()`，或引导协议传递的内存映射获得各段地址及其类型。在特定嵌入式平台上，也可由板级程序读取内存控制器配置或按硬件手册提供布局。一般情况下应保存多个区间，并区分普通 RAM、固件保留区、设备地址和内存空洞。

得到 RAM 列表之后，还要扣除内核、固件、页表、描述符、仍需使用的 DTB 等占用，再按页边界整理成空闲区。设备树的保留区信息也应纳入一般实现；当前实验代码主要处理单段 RAM 和固定前缀占用，不能当作通用多区间实现。

不宜通过任意地址试写、读回来普遍探测内存：该地址可能对应 MMIO、触发设备副作用或访问异常。早期系统可以在严格约束下做平台相关探测，但这不能代替可靠的硬件描述。本题是方法分析，没有新增固件查询模块。

## 六、功能模块二任务一：First-Fit

本节解释框架提供的 [default_pmm.c](../code/kern/mm/default_pmm.c)，该文件保留为参考实现。

### 6.1 初始化、分配和回收

`default_init()` 将空闲链表初始化为空，空闲页计数 `nr_free` 置零。`default_init_memmap(base, n)` 检查这 `n` 页原先为保留状态，清理标志和引用计数，设置首页 `property = n` 和 `PageProperty`，按地址顺序插入链表，并增加空闲页计数。

`default_alloc_pages(n)` 从链表头开始扫描，选择遇到的第一个 `property >= n` 的块。恰好满足时取走整个块；块更大时取出前 `n` 页，将余下部分组织为新空闲块，保留在原链表位置。分配后扣减 `nr_free`，清除已分配块首页的空闲块标志，返回首页描述符。没有足够大的连续块则返回 `NULL`，即使总空闲页数可能足够。

`default_free_pages(base, n)` 把已分配页面重新登记为空闲块，按地址顺序插入，然后检查前驱、后继是否与它物理连续。满足 `prev + prev->property == base` 或 `base + base->property == next` 才能合并，合并后删除多余块头并更新长度。

```text
释放前：[空闲 2 页][已分配 3 页][空闲 4 页]
释放后：[             空闲 9 页             ]
```

链表相邻只是候选关系，不等于物理相邻。释放新增的 `n` 页只计数一次，合并不再增加总空闲页数；释放也不自动清零物理页的数据。调用者必须遵守已分配区间的释放契约。

### 6.2 原有 First-Fit 是否有改进空间

有，但要区分“提高同一策略的实现效率”和“改用另一种选择策略”。设空闲块数量为 `F`，当前链表查找和有序插入最坏为 `O(F)`。

- 可使用按地址排序、节点额外保存子树最大块长度的平衡树，跳过不可能满足申请的子树，同时保持地址最低的首次适配语义。
- Next-Fit 从上次位置继续扫描，可减少重复检查链表前部，但改变选择策略，不能保证所有负载的碎片都更少。
- 多次 `init_memmap()` 若登记相邻范围，可以在初始化插入时合并。当前释放路径已经合并，不能把“增加释放合并”写成尚未实现的优化。
- 可比较 Best-Fit 和 Buddy，但两者分别有扫描成本、小碎片或内部碎片的代价，不存在无条件最优的分配算法。

本任务是阅读与思考题，规格是说明四个函数的状态变化、分裂、回收和合并条件；没有另行生成 First-Fit 代码。AI 交互围绕“`default_free_pages` 在做什么”和“`page_link` 记录什么”等问题展开。

## 七、功能模块二任务二：Best-Fit

实现：[best_fit_pmm.c](../code/kern/mm/best_fit_pmm.c)。完整原始提示词：[writing-block.md](writing-block.md)。

### 7.1 规格、提示词与接口

原文件只给出 `basic_check()` 和 `best_fit_check()`。提示词要求阅读 `struct pmm_manager` 后补齐状态、六个管理入口和注册结构，不修改这两个测试，不修改 First-Fit 参考实现，并遵守 `PageReserved`、`PageProperty`、`property` 和 `nr_free` 的约定。

规格将分配选择明确为：在所有容量至少为 `n` 的空闲块中选容量最小者；相同大小选地址较低者；从块头分配，剩余部分继续保留；失败返回 `NULL` 且不改变状态。释放时按地址插入并与物理连续的前后块合并。提示词还列出了空链表、恰好满足、分裂、总量不足、总量够但不连续及链表首尾插入等边界。

实际对话中最初说“补充 `default_pmm.c`”，但上传提示词要求实现 `best_fit_pmm.c` 并保留 First-Fit。澄清后采用用户明确选择的“按提示词实现 best_fit_pmm.c，保留 First-Fit 参考实现”，避免改错文件。

### 7.2 核心实现

`best_fit_init()` 初始化 `free_area`。`best_fit_init_memmap()` 初始化给定页面并用 `best_fit_insert_block()` 按地址插入。`best_fit_alloc_pages()` 维护当前最小可用块 `best`；严格使用更小容量更新，保持相同大小时先遇到的低地址块。选中后拆分并更新计数和状态。

`best_fit_free_pages()` 清理释放区间，登记块头，按地址插入并先后检查前驱、后继。合并时清除被吞并块头的标志和长度，避免后续误认为它还是独立空闲块。`best_fit_nr_free_pages()` 返回页数，注册结构将这些函数与原有检查函数连接。

与 First-Fit 的关键差异是选择哪个块，而不是释放方式。空闲页总量充足但最大连续块不足，Best-Fit 同样会失败。

### 7.3 合理性、按地址还是按大小排序，以及已完成的优化

保留地址有序链表适合本实验：释放时找到插入点后，物理相邻块只需检查前后候选，分裂余块也容易保留原有顺序。代价是分配通常要扫描所有空闲块，最坏 `O(F)`。

按大小排序能更快定位最小合适块，但单一链表仍可能线性扫描，释放时查找地址相邻块也不方便。若要同时优化两方面，可以维护按大小和按地址的双索引，或大小树配合页边界元数据；这会增加维护成本。因此当前小规模教学实现使用地址有序链表是合理取舍。

已经按后续用户要求实现：**找到 `property == n` 的块就立即结束搜索**。精确匹配的剩余量为零，不可能出现更优容量；由于链表按地址排序，第一次精确匹配也满足低地址优先。原提示词中“完整遍历”的要求在这一步被后续明确指令细化，原提示词文件保持原样用于记录过程。

后续可考虑大小分桶或平衡树、独立维护最大块信息以加速失败判断，以及基于真实负载比较扫描次数和碎片分布。Best-Fit 倾向保留大块，但可能留下大量小碎片；本实验没有测得其普遍优于 First-Fit 的性能结论，也没有实现双索引。

### 7.4 验证

原有两个检查函数保持不变，三后端 Sv39 驱动实际执行 `best_fit_pmm_manager.check()`，然后运行 SLUB 测试并核对页数恢复。`best_fit_check()` 包含 5 页区域的局部释放，验证从不同大小的块中选择更合适者及恢复状态。该运行不等同于开启评分宏得到新的“6/6”评分输出，报告以保存日志中的实际成功标志为准。

## 八、功能模块二任务三：Buddy System

实现：[buddy_pmm.c](../code/kern/mm/buddy_pmm.c)、[buddy_pmm.h](../code/kern/mm/buddy_pmm.h)。

两份完整提示词分别是 [writing-block-1.md](writing-block-1.md)（生成并接入分配器）、[writing-block-2.md](writing-block-2.md)（生成测试）。

### 8.1 规格和提示词设计

第一份提示词提供 PMM 接口、描述符状态、链表操作和伙伴算法性质，要求从零建立模块，不破坏已有两个分配器。功能规格包括任意初始区间分解、非二次幂请求向上取整、逐级分裂、真正伙伴合并、原请求页数释放及计数一致。

第二份提示词将测试与实现分开，要求验证基本分配、初始化、拆分、合并、伙伴计算、非二次幂、耗尽、压力和不变量。特别约束不能清空真实管理器后冒充恢复、不能把任意页面当作测试区，也不能用浅拷贝链表头破坏原有节点指向。

### 8.2 数据结构与初始化

每个阶 `order` 对应 `2^order` 页，维护一条地址有序空闲链表。块头 `property` 记录页数，不是阶数。除空闲链表和页数外，还维护受管页标记、逐页归属和独立的分配记录池。

`buddy_init_memmap()` 不要求输入本身是二的幂或天然对齐。它从起点开始，每次选择不超出剩余区间、且物理页号满足对齐的最大块，登记并尝试合并。这样不会为了凑成大块越过可用内存边界。

伙伴页号为：

```text
partner_ppn = page2ppn(base) XOR (1 << order)
```

必须使用与物理对齐一致的绝对页号，并检查伙伴在描述符范围内、属于管理区、未被分配、是同阶空闲块头。两个同样大小且相邻的块不一定是伙伴，不能只凭相邻关系合并。

### 8.3 分配、非二次幂和释放契约

`buddy_alloc_pages(n)` 将请求向上取整到最小二次幂，寻找对应阶或更大阶的块。取出后逐级分裂，保留左半块继续处理，将右半块放回相应链表。最终扣除的是取整后的实际占用页数。

例如请求 3 页会占用 4 页，但调用者只拥有请求的 3 页有效范围，释放仍使用 `free_pages(base, 3)`。实现记录请求数、取整后块大小、存活请求页数和逐页归属，最后一页请求范围释放后才归还多出来的填充页。

当前接口还兼容合法局部释放，以及跨相邻分配但不包含填充页的合法释放区间。完整校验释放区间之后再改变状态，逐页归还并向上尝试伙伴合并。

分配记录独立于首页描述符很关键：如果先释放首页并重新分配它，而原分配的尾页仍在使用，原归属信息不能随首页重用而丢失。独立记录池解决这一生命周期问题。

### 8.4 测试覆盖及有效性

测试从真实管理器取得 64 页专用区域，使用独立 `test_state`，通过状态指针切换隔离测试链表。测试结束恢复页面的已分配描述符状态，切回 `kernel_state` 再归还整个区域，并核对原空闲页数和结构。

| 检查函数 | 覆盖行为与边界 | 为什么能检验实现 |
| --- | --- | --- |
| `buddy_check_basic` | 单页与多页申请、不同返回区间、释放后可用 | 发现重复分配、错误计数和基本接口问题 |
| `buddy_check_init_memmap` | 非整幂长度、非大块对齐、多段初始化 | 发现越界凑块、遗漏页面和初始化状态错误 |
| `buddy_check_split` | 从大阶连续拆到目标阶 | 核对返回块及各阶余块，发现分裂位置或阶数错误 |
| `buddy_check_merge` | 不同释放顺序、递归合并、缺少空闲伙伴 | 既要求能合并，也要求不提前错误合并 |
| `buddy_check_partner` | 真伙伴、非伙伴及边界 | 发现把相邻块当伙伴、异或基准或范围检查错误 |
| `buddy_check_non_power_two` | 3、5 等请求、按原大小释放、局部释放及首页重用 | 发现向下取整、填充页泄漏、重复归还和归属丢失 |
| `buddy_check_exhaustion` | 耗尽后返回 `NULL`，失败不改状态，释放后恢复 | 发现空链表误取节点和失败路径副作用 |
| `buddy_check_stress` | 固定种子 256 次交错操作 | 让分裂合并反复交叉，检查区间重叠与数据结构累积错误 |
| `buddy_check_invariants` | 各阶链表、对齐、块头、归属、覆盖与计数 | 独立重算而非只看成功返回，发现隐藏泄漏和重复覆盖 |

逐项检查后还有整体状态核对。只验证 `nr_free` 相同不足以证明正确：一个错误块与一个遗漏块可能抵消，所以测试还检查页面覆盖、重叠、伙伴合并及分配记录。

### 8.5 结果与改进空间

标准 QEMU 4.1.1 内核启动和三后端专项运行均输出 Buddy 全部检查通过、内核状态已恢复。没有通过删除断言或放宽预期获得通过。

伙伴算法的拆分合并层数受阶数限制，但本实现的链表有序插入需要扫描，且为兼容局部释放会处理逐页归属，不能笼统声称全部操作都是 `O(log N)`。静态容量依据本平台 128 MiB 设置，两套状态及测试数组增加内核占用。进一步可减少测试状态常驻开销、优化索引和记录结构，并为多核增加同步。

代价方面，3 页占用 4 页、5 页占用 8 页体现内部碎片；某些相邻空闲块因不满足伙伴关系也不能立即合成任意大小块。Buddy 简化的是受限块结构下的管理，不保证任意连续请求都没有碎片。

## 九、Challenge：简化 SLUB 对象分配器

实现：[slub.c](../code/kern/mm/slub.c)、[slub.h](../code/kern/mm/slub.h)；补充设计：[slub_design.md](slub_design.md)。

两份完整提示词：[writing-block-2-1.md](writing-block-2-1.md)（实现和集成）、[writing-block-2-2.md](writing-block-2-2.md)（测试）。

### 9.1 规格与两层架构

底层 PMM 按页提供连续物理内存，上层 SLUB 将一页划成多个可复用对象，提供：

```c
void slub_init(void);
void *slub_alloc(size_t size);
void slub_free(void *ptr);
size_t slub_usable_size(const void *ptr);
void slub_check(void);
```

实现提示词明确了 16 字节对齐、小对象共享物理页、对象元数据不能覆盖有效数据、大对象记录释放所需页数、溢出返回 `NULL`、完全空闲 Slab 立即归还 PMM 等条件。测试提示词进一步要求真实写读、跨页访问、对象不重叠、失败路径和状态恢复，而非只检查指针非空。

`slub_init()` 在 `pmm_init()` 完成后调用。重复初始化不抛弃已有活动对象；初始化前申请返回 `NULL`，`slub_free(NULL)` 无操作，`slub_usable_size(NULL)` 返回 0。只要求释放合法接口返回指针，不将任意伪造地址的容错当作接口保证。

### 9.2 Cache、Slab 和小对象流程

设置 16、32、64、128、256、512、1024、2048 字节八个类别，选择不小于请求的最小类别。例如 17 字节放入 32 字节类别。每个 Cache 有 Partial 和 Full 链表及统计信息。

每个小对象 Slab 占一物理页，页首放管理头，后面是对齐对象槽位。当前 RV64 构建的管理头为 120 字节，向上对齐后对象起点为 128 字节。

| 类别大小（字节） | 16 | 32 | 64 | 128 | 256 | 512 | 1024 | 2048 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 单页对象数 | 248 | 124 | 62 | 31 | 15 | 7 | 3 | 1 |

空闲槽位内保存下一个空闲对象指针，并用位图检查已分配状态。对象分配后，这段内存归调用者，不能再当作链表指针读取。分配优先从 Partial Slab 取槽位，满后移入 Full；没有可用 Slab 才向 PMM 申请页。

释放对象时清除活动位并放回空闲链。Full 释放一个对象后回到 Partial；最后一个活动对象释放后摘除整个 Slab 并归还物理页，其他活动对象所在页不会提前释放。

### 9.3 大对象、地址转换和碎片

请求大于 2048 字节走直接页分配路径，计入 128 字节头部并向上按页取整。例如：

```text
5000 字节请求：ceil((5000 + 128) / 4096) = 2 页
8192 字节请求：ceil((8192 + 128) / 4096) = 3 页
```

这是独立的大对象路径，不表示每个大对象都必然超过一页；例如 3000 字节连同头部仍可放入一页。若后端是 Buddy，3 页请求实际占用 4 页，但 SLUB 记录并按原请求 3 页调用释放，由 Buddy 负责填充页回收。不能自行错误地按用户字节数或未知的取整结果释放。

头部记录首页、原 PMM 请求页数及用户请求字节数。小对象 `slub_usable_size()` 返回类别容量，大对象返回请求容量，均排除管理头。

`Page *` 不能直接强转成数据指针。实际使用 `page2pa(page) + va_pa_offset` 并检查物理范围和页数，得到连续可访问的内核直接映射地址；当前工程的 `KADDR` 宏被注释，不能仅凭教程名称调用不存在的接口。映射检查失败会归还刚申请的页。

申请前检查 `size + metadata` 的溢出，页数计算使用等价于 `(bytes - 1) / PGSIZE + 1` 的安全取整。小对象类别向上取整、页内尾部空隙、管理头以及 Buddy 的页数取整都会产生不同来源的空间开销。

### 9.4 测试覆盖及有效性

| 检查函数 | 覆盖内容 | 主要检出问题 |
| --- | --- | --- |
| `slub_check_basic` | 基本分配、容量、释放和继续使用 | 接口、元数据和基本生命周期错误 |
| `slub_check_size_classes` | 各类别及相邻边界 | 类别选择偏差、可用容量不足 |
| `slub_check_alignment` | 多种大小返回指针 16 字节对齐 | 头部与槽位偏移不正确 |
| `slub_check_data_integrity` | 各对象写不同模式并交叉核对 | 对象重叠、链表覆盖活动数据 |
| `slub_check_reuse` | 释放槽位复用，不多占页 | 空闲链丢失、Full/Partial 转换错误 |
| `slub_check_multi_slab` | 32 字节类申请 `2N+1` 个对象形成三页 | 满页越界、跨 Slab 识别和链表维护错误 |
| `slub_check_large_alloc` | 2049、3000、4096、4097、5000、8192 字节 | 未计头部、页数取整、跨页访问和释放错误 |
| `slub_check_page_reclaim` | 八个 16 字节对象共享一页；逐个释放及大对象回收 | 每对象浪费一页、过早回收、页泄漏 |
| `slub_check_boundary` | 零申请、空指针、极大请求、溢出、受控失败和重复初始化 | 失败路径改状态、整数溢出、初始化丢失活动对象 |
| `slub_check_stress` | 16 个活动槽位、固定种子 256 次交错操作 | 长序列下数据损坏、重复分配和累积泄漏 |
| `slub_check_invariants` | Cache/Slab 链表、位图、对象数、大对象和统计一致性 | 成功返回背后的隐藏状态错误 |

5000 字节对象显式写读第 0、4095、4096、4999 字节，验证跨页有效空间，所有下标均在有效范围内。测试不读取已经释放对象，也不要求新分配对象保留旧内容。

`slub_check()` 用于冷启动阶段，要求没有外部活动 SLUB 对象且至少有 64 页可用内存。结束时检查所有测试对象释放、Slab 与大对象链表清空、PMM 页数恢复，之后再执行一次正常申请释放。

独立 Sv39 驱动还分别用 Buddy、Best-Fit、First-Fit 作为真实后端运行上述测试。在驱动的 PMM 转发边界临时注入返回 `NULL`，验证新 Slab 和大对象失败不破坏状态；已有 Partial Slab 时，即使 PMM 失败仍可复用空闲槽位。注入只存在于验证驱动，没有改动实际分配器。

### 9.5 与 Linux SLUB 的区别及改进空间

本实现体现“页分配器之上的固定类别对象缓存”思想，属于单核教学简化版本。未实现 per-CPU 快路径、NUMA、并发同步、构造析构回调及红区/毒化调试等完整机制。

立即回收空 Slab 有利于验证无泄漏，但频繁申请释放可能反复向 PMM 要页。可保留少量空 Slab、调整类别以适应负载、减少头部和位图开销，再用测量决定是否值得增加复杂度。不能把这些尚未实施的方案写成已经取得的性能提升。

## 十、分页、Sv39 与 GDB 分支任务

### 10.1 启动页表和地址翻译原理

Sv39 的虚拟地址有效部分为 39 位，其中三级索引各 9 位、页内偏移 12 位；RV64 地址高位必须是第 38 位的符号扩展。每个页表项 8 字节，每页 512 项。`satp` 的 MODE=8 表示 Sv39，另含 ASID 和根页表物理页号。

普通 4 KiB 页会依次查询三级页表；合法叶项也可出现在较高层，形成 2 MiB 或 1 GiB 大页，因此不能把“配置三级”理解为每次必走完三级。

实际启动根页表 `boot_page_table_sv39` 的第 511 项为：

```text
PTE = (0x80000 << 10) | 0xcf = 0x200000cf
V/R/W/X/A/D = 1，U/G = 0
```

它是根层的 1 GiB 叶项，将高地址 `[0xffffffffc0000000, 2^64)` 映射到物理地址 `[0x80000000, 0xc0000000)`。这只是映射覆盖范围，并不表示其中全部都是可用 RAM；本机实际 RAM 上界仍为 `0x88000000`。

PMM 以 4 KiB 页框管理，与启动映射使用 1 GiB 叶项并不矛盾：物理分配粒度和页表映射粒度分别解决资源管理与地址转换问题。

设置 `satp` 后，`sfence.vma` 用于同步地址翻译相关状态。它不是数据缓存或指令缓存的一般刷新指令。TLB 缓存近期转换以利用局部性，多级页表则通过按需建立下级结构减少稀疏地址空间的页表开销。

### 10.2 两个 GDB 的职责和实际方法

RISC-V GDB 连接 QEMU 的 guest stub，查看的是客户机 PC、寄存器和内核符号；宿主机 GDB 调试的是运行在 x86 主机上的 QEMU C 代码。两者的断点、符号和执行状态属于不同层次。

本轮先用客户机 GDB 确定一条必经的 BSS 清零写指令及地址，再独立运行宿主机 GDB，以 `satp`、访问类型和目标虚拟页作为条件直接停在 QEMU 翻译函数。这样不必在每次固件访存时手工继续，也不要求两层 GDB 始终同时挂起。记录见 [kernel_store_debug.log](evidence/kernel_store_debug.log) 和 [qemu_mmu_debug.log](evidence/qemu_mmu_debug.log)。

### 10.3 一条真实存储指令的完整翻译

本次构建的客户机 GDB 停在 `memset`：

```text
pc   = 0xffffffffc0205d1e
指令 = sb a1,-1(a5)
a5   = 0xffffffffc020c021
a1   = 0
satp = 0x800000000008020b
有效虚拟地址 = a5 - 1 = 0xffffffffc020c020
```

单步后 PC 为 `0xffffffffc0205d22`，目标字节读得 `0x00`。该操作正在清理 `edata` 开始的 BSS，日志中的符号名称也对应 Buddy 测试静态数组 `check_free`。

宿主机 GDB 在 QEMU 4.1.1 中实际捕获相同虚拟地址的 `MMU_DATA_STORE`，`mmu_idx=1`，即 S 模式。调用栈从底层向上可整理为：

```text
TCG 生成代码 → helper_ret_stb_mmu → store_helper
  → tlb_fill → riscv_cpu_tlb_fill → get_physical_address
```

查表过程的实测值及推导如下：

| 步骤 | 结果 |
| --- | --- |
| 从 `satp` 取根页表页号 | `0x8020b` |
| 根页表物理基址 | `0x8020b000` |
| `VPN[2] = (VA >> 30) & 0x1ff` | 511 |
| 根项物理地址 `root + 511 × 8` | `0x8020bff8` |
| 实际读到的根项 | `0x200000cf` |
| 叶项物理页号 | `0x80000` |
| 高层叶项合入低位虚拟页号后的物理页基址 | `0x8020c000` |
| 页内偏移 | `0x020` |
| 最终字节物理地址 | **`0x8020c020`** |

GDB 中观察到 `levels=3`、`ptidxbits=9`、`ptshift=18`、`i=0`，但该根项已经是合法叶项，所以只进行一轮循环。下层两个虚拟页索引参与大页偏移，不会再去访问不存在的下级页表。

`get_physical_address()` 输出的 `physical` 是本次访问所在的 4 KiB 页基址；报告中的字节地址是再合入低 12 位偏移所得，不能将两者混淆。函数返回成功、权限 `prot=7`。随后实际停在 `tlb_set_page()`：

```text
vaddr = 0xffffffffc020c000
paddr = 0x8020c000
prot = 7
mmu_idx = 1
size = 4096
```

因此虽然页表采用 1 GiB 叶映射，观察到的 QEMU 软件 TLB 回填仍以这一 4 KiB 页为单位。上述地址还与直接映射计算 `VA - va_pa_offset` 相符，构成独立核对。

### 10.4 QEMU 页表代码的关键分支

对应源码为 QEMU 4.1.1 的 `target/riscv/cpu_helper.c`：

- `get_physical_address()` 首先处理实际有效特权级。普通 M 模式或无需翻译的路径直接返回地址；MPRV 等状态会影响有效模式，不能将所有 M 模式数据访问一概归为相同路径。
- 对 S/U 模式按 `satp` 模式决定 Bare 或分页，Sv39 设置三级、9 位索引及 8 字节 PTE，并检查虚拟地址的规范形式。
- 循环计算索引与 `pte_addr`，通过物理内存访问读取 PTE。`V=0` 失败；R/W/X 全为零才进入下一级；非法的 R/W 组合、权限不满足或大页 PPN 未对齐等情况失败。
- 找到合法叶项后，检查访问类型、U/S 权限及 SUM/MXR 等相关状态，处理必要的 A/D 位，再组合叶项 PPN 和大页所需低位虚拟页号。
- `riscv_cpu_tlb_fill()` 调用翻译函数并检查 PMP；成功后调用 `tlb_set_page()`，失败时按 probe 或异常路径处理。

本次实际经过的是“Sv39、S 模式写、根层合法叶项、允许读写执行”的成功路径；其他错误分支来自源码分析，未声称已逐个注入触发。

### 10.5 在哪里查 TLB，以及与真实 CPU TLB 的区别

QEMU 4.1.1 的 `accel/tcg/cputlb.c` 中，`store_helper()` 根据 `mmu_idx` 和虚拟地址计算 `tlb_index()`，取得对应条目并检查写标签。未命中时先尝试 victim TLB，仍未命中则进入 `tlb_fill()`，最终调用 RISC-V 的 `riscv_cpu_tlb_fill()`。读访问有对应的 `load_helper()` 路径。

实际存储调用栈包含这些函数，`store_helper` 栈帧中可观察到 `index=12`、`mmu_idx=1`、`tlb_off=8`，随后发生查表和回填。部分局部变量如条目指针、标签因优化被 GDB 显示为 `optimized out`；本报告不据此虚构条目的具体内容。TCG 生成代码通常还包含命中快路径，所以不能认为每次访存都必经完整 C helper 或页表查询。

`tlb_set_page()` / `tlb_set_page_with_attrs()` 除客户机虚拟页和物理页关系，还设置读写执行标签、MMIO/写脏相关标志，以及将客户地址换算成宿主 RAM 地址所需的 `addend`。本轮实测了回填入参；`addend` 的用途依据源码，不是日志中已打印出的具体数值。

为比较未开启虚拟地址空间的访问，本轮还实际捕获复位阶段 M 模式、`satp=0` 的取指：

```text
addr = 0x1000, access_type = MMU_INST_FETCH, mmu_idx = 3
get_physical_address() 返回 0x1000
调用栈：get_page_addr_code → tlb_fill → riscv_cpu_tlb_fill → get_physical_address
```

这里明确是 **M 模式、satp=0** 的对照，不能冒称已单独捕获 S 模式 Bare 的同类存储。它仍说明 QEMU 在无需 Sv39 查表时也可能进入软件 TLB 相关路径：模拟器还需要完成客户物理地址到宿主 RAM/MMIO 的定位。真实 CPU 的架构 TLB 主要缓存地址翻译及权限，不承担把客户物理地址变成另一个进程内宿主指针的职责。

真实处理器通常由硬件完成页表遍历；本实验中对应行为由 QEMU 的宿主软件实现，不能误认为 ucore 每次访存都调用了一个软件查表函数。

### 10.6 调试细节与 AI 协助过程

本分支先把问题限定为“找到一条实际写内存的指令，记录虚拟地址，再观察 QEMU 如何处理它”，再搜索 `get_physical_address`、`riscv_cpu_tlb_fill`、`tlb_fill`、`store_helper` 和 `tlb_set_page`，逐步核对调用关系。AI 用于整理双层调试方法、构造条件断点和解释现场变量，判断仍以源码和日志为准。

最明显的意外是名为 `qemu-4.1.1` 的安装目录中实际是 7.0.0。早先 loader-only 启动出现 OpenSBI `Next Address = 0`，曾通过临时启动适配程序验证内核；本轮查明版本后，用真正 4.1.1 和原项目参数直接成功。这说明应先检查工具和固件身份，再判断是否需要修改启动代码。

另一个细节是编译带有调试信息也不意味着所有局部变量都能看见：GDB 仍可能停在内联后的行号或显示 `optimized out`。本轮通过函数入口参数、调用栈、可见局部变量和返回值相互核对，没有把无法观察的值当作实测结果。

有趣的认识是“三级页表只走一层”和“不开分页也进入 QEMU 软件 TLB 路径”并不矛盾：前者由大页叶项决定，后者来自模拟器还承担宿主地址定位。只套用简化流程图容易误判，应结合具体状态解释。

## 十一、AI 提示词结构、问题与修正记录

### 11.1 提示词为什么这样写

五份上传文件采用相同的四段结构：`PROMPT` 定义任务与修改范围，`RELY` 给出已存在接口和前提，`GUARANTEE` 约束必须保持的性质，`SPECIFICATION` 逐函数列出输入、状态变化和边界。

| 任务 | 完整提示词文件 | 最关键的规格约束 |
| --- | --- | --- |
| Best-Fit | [writing-block.md](writing-block.md) | 最小可用块、同尺寸时低地址优先、原测试保持不变、原 First-Fit 保留 |
| Buddy 实现 | [writing-block-1.md](writing-block-1.md) | 任意初始区间、整幂块、拆分合并、非整幂释放记账 |
| Buddy 测试 | [writing-block-2.md](writing-block-2.md) | 状态隔离、核心行为和边界、完整恢复、不浅拷贝链表头 |
| SLUB 实现 | [writing-block-2-1.md](writing-block-2-1.md) | 两层架构、对齐、元数据、合法释放、失败回滚、内核集成 |
| SLUB 测试 | [writing-block-2-2.md](writing-block-2-2.md) | 实际写读、不重叠、类别边界、跨页、回收、受控失败 |

这些文件与报告一同保留，链接指向完整原文，不是删减后的摘要。把算法和测试分成两份提示词，有利于先明确公共契约，再以另一组可观察性质检查实现。最终不能只依赖 AI 宣称“完成”，还要看编译、真实运行和断言。

### 11.2 已实际遇到的问题及处理

| 阶段 | 实际问题或理解偏差 | 修正方法与依据 |
| --- | --- | --- |
| `page_init` | 虚拟起点与物理末端直接比较或相减 | 明确每个变量的地址空间，区间运算前用 `PADDR()` 转换起点，接口处避免重复转换 |
| `page_init` | 只确定 `pages` 地址，没有初始化描述符 | 遍历 `npage - nbase` 项，初始化字段并标记保留，满足管理器前置条件 |
| `page_init` | 调整起点后仍沿用旧大小，可能算错末端或输出 | 先算原始末端，再裁剪，最后重新计算长度 |
| `page_init` | 对 `pages + count` 是否还要乘结构体大小有疑问 | 区分 C 指针算术和整数地址加法，避免重复乘法 |
| 构建阶段 | Best-Fit 尚未补齐状态时，整体构建出现 `free_list`、`nr_free` 等未定义 | 补齐内部状态、宏、管理函数和注册结构后，完整交叉编译链接成功 |
| 任务范围 | 对话写 `default_pmm.c`，上传提示词指定 `best_fit_pmm.c` | 按用户明确澄清保留 First-Fit，在正确文件实现 Best-Fit |
| 运行验证 | 根据 `/opt/qemu-4.1.1/` 目录误认版本，loader-only 启动未进入内核 | 查 `--version` 和固件，改用真正 4.1.1 的可执行文件验证原启动路径；无需修改内核启动代码 |
| GDB | 源码行断点落入内联位置，部分变量被优化掉 | 使用实际匹配的源码、函数参数、返回值和调用栈交叉验证，保留观察局限 |

Buddy 与 SLUB 的设计还重点防止了几类容易生成的错误：只用首页保存归属导致局部释放后元数据丢失、浅拷贝链表哨兵、把 `Page *` 当数据地址、大对象页数未计头部、释放页数与 Buddy 契约不一致、空 Slab 过早回收及整数溢出。这些是规格审阅和实现中处理的风险，不能全部写成“曾在运行中触发的 bug”。现有保存记录没有出现 Buddy/SLUB 专项断言失败，不编造失败次数或修复前日志。

## 十二、验证结果和可复现命令

### 12.1 完整交叉编译

在仓库根目录执行下列命令可使用独立输出目录构建，不需要改 Makefile：

```bash
make -C code \
  GCCPREFIX=/home/viewfinder/toolchains/os-freedom-tools/bin/riscv64-unknown-elf- \
  OBJDIR=/tmp/ucore-lab2-report/obj \
  BINDIR=/tmp/ucore-lab2-report/bin
```

本轮实际使用的输出目录是 `/tmp/ucore-slub-c33jba6m/build/`，日志显示三个 PMM、SLUB、启动代码和公共库均完成编译，成功链接 ELF 并生成镜像，见 [build.log](evidence/build.log)。路径只是隔离构建产物的选择，不改变内核实现。

### 12.2 真正 QEMU 4.1.1 的完整内核启动

以下为可复现形式，镜像路径对应上一小节的输出：

```bash
/home/viewfinder/qemu-4.1.1/riscv64-softmmu/qemu-system-riscv64 \
  -machine virt -nographic -bios default \
  -device loader,file=/tmp/ucore-lab2-report/bin/ucore.img,addr=0x80200000
```

实际执行的原始参数另存于 [kernel_qemu_4_1_1.command.json](evidence/kernel_qemu_4_1_1.command.json)。完整输出见 [kernel_qemu_4_1_1.log](evidence/kernel_qemu_4_1_1.log)，关键结果为：

```text
memory management: buddy_pmm_manager
Free physical memory: start = 0x00000000804d6000, end = 0x0000000088000000, size = 0x0000000007b2a000
buddy_check: basic passed
buddy_check: init_memmap passed
buddy_check: split passed
buddy_check: merge passed
buddy_check: partner passed
buddy_check: non_power_two and partial release passed
buddy_check: exhaustion passed
buddy_check: stress passed
buddy_check: all tests passed; kernel state restored
check_alloc_page() succeeded!
satp virtual address: 0xffffffffc020b000
satp physical address: 0x000000008020b000
slub_check: basic passed
slub_check: size_classes passed
slub_check: alignment passed
slub_check: data_integrity passed
slub_check: reuse passed
slub_check: multi_slab passed
slub_check: large_alloc passed
slub_check: page_reclaim passed
slub_check: boundary passed
slub_check: stress passed
slub_check: all tests passed; PMM pages restored
```

测试后内核进入现有空闲循环，没有主动退出机制，测试驱动在观察到输出后结束 QEMU。这种受控结束不代表断言失败，也不应把超时本身当作测试通过的依据；依据是上述实际成功标志和没有触发 panic 的完整过程。

### 12.3 三后端 Sv39 专项验证

另一个独立入口建立真实 Sv39 高地址映射并进入 S 模式，登记 `[0x81000000, 0x88000000)` 共 28672 页，编译并调用项目真实的三种 PMM 和 SLUB 源文件。它不替代完整启动中的 DTB 和 `page_init()` 检查，用于隔离验证分配器及 SLUB 的后端兼容性。

该测试使用实际为 7.0.0 的 `/opt/qemu-4.1.1/bin/qemu-system-riscv64`，不是本节的标准 4.1.1 启动。运行每个后端的原有管理器检查、失败注入、全部 SLUB 检查，最后再次读写 5000 字节对象并释放，页数均恢复为初始值。日志 [slub_test.log](evidence/slub_test.log) 最终输出：

```text
PASS backend buddy_pmm_manager: SLUB complete and pages restored
PASS backend best_fit_pmm_manager: SLUB complete and pages restored
PASS backend default_pmm_manager: SLUB complete and pages restored
ALL SLUB SV39 TESTS PASSED
```

独立驱动和入口源码已保存在附件，便于区分验证环境和正式内核。当前完整内核只选择 Buddy，没有声称用同一条标准启动命令依次验证了三个不同配置。

### 12.4 仍未覆盖的验证

默认 DTB 的正常启动、当前算法测试和实际地址翻译已验证。尚未完整覆盖畸形 DTB 与所有整数边界、更多硬件内存布局、并发竞争、长期随机压力及性能基准。现有压力用例使用固定种子和有限次数，具有可重复性，但不是形式证明。

## 十三、重要知识点、原理联系及提交事项

### 13.1 本实验与 OS 原理的对应关系

| 实验知识点 | OS 原理中的含义 | 联系、差异及本实验边界 |
| --- | --- | --- |
| DTB 与 RAM 范围 | 硬件发现和资源描述 | 获取硬件提供的范围，再扣除占用；当前是单段 RAM 简化 |
| `Page` 数组、页号转换 | 页框管理与元数据 | 描述符管理页的状态，与实际页数据分离；有描述符不等于空闲 |
| 直接映射及 `va_pa_offset` | 虚拟地址与物理地址关系 | 固定偏移是内核的具体映射策略，不是所有虚拟内存的通用公式 |
| First-Fit/Best-Fit | 连续分配和外部碎片 | 选择策略不同；总空闲量不能代替最大连续块大小 |
| Buddy | 受限大小块、分裂和合并 | 降低伙伴定位难度，但取整产生内部碎片；当前实现兼容局部释放 |
| SLUB | 对象缓存与分层内存管理 | 多个对象共享页，降低小对象独占页的浪费；类别与头部仍有空间开销 |
| `pmm_manager` | 机制与策略分离 | 统一调用约定使算法可替换；后端释放契约仍需上层遵守 |
| Sv39 与大页 | 多级分页与地址空间映射 | 三级结构支持不同层叶项，启动实际用根层 1 GiB 叶项 |
| TLB 与 `sfence.vma` | 地址翻译缓存、局部性和一致性 | 页表与 TLB 是不同层次，修改页表后需考虑同步；不等同一般缓存刷新 |
| 引用计数和保留状态 | 资源生命周期管理 | 字段为后续功能提供基础；本次分配器没有因此实现完整共享页和回收体系 |
| QEMU 源码调试 | 硬件机制的软件模拟 | 可观察查表和缓存，但宿主地址定位属于模拟器额外职责 |

### 13.2 重要但本实验尚未实现的原理

- 用户进程独立地址空间、权限隔离、上下文切换与 ASID 管理；本次主要观察内核静态直接映射。
- 按需分配、缺页异常恢复、文件映射、交换和页面置换；本次失败申请返回空指针或启动错误终止，不会自动换页。
- 写时复制、共享内存、反向映射及完整引用计数回收机制；存在 `ref` 字段不等于完成这些功能。
- 多核分配同步、per-CPU 缓存与跨核 TLB shootdown；当前测试按单核启动场景设计。
- NUMA、页迁移、内存压缩、热插拔及通用保留区管理；固定平台上界不能代表这些能力。
- 完整 Linux SLUB 的调试、统计和性能机制；本次仅实现其对象分层与复用的主体思想。

### 13.3 提交状态、署名与本机验证补充（2026-10-25）

正式整合位置为 GitHub `main` 分支的 `lab2/`；源码位于 `lab2/code/`，本报告位于 `lab2/report/report.md`。搭档原 `lab2` 分支继续保留。此前整合与清理已经推送；本轮评分入口和截图补充随本轮提交更新，不再使用“尚未推送”的旧状态描述。

本次源码实现由朱钟铭独立完成（依据李孟德的说明）；小组分工表按要求留空，后续由成员填写：

| 成员 | 代码与实验分工 | 报告分工 |
| --- | --- | --- |
| 2413170-李孟德 |  |  |
| 2412075-朱钟铭 |  |  |

#### 源码标识与保护边界

`code/` 的 43 个原文件，包括源码、原 Makefile 和课程测试，仍与搭档 `1444f66` 完全一致；报告附件中的独立测试驱动同样保持不变。只更新本报告和截图目录说明这两份非代码文档，原始 77 文件清单仍保存于 [源文件清单](../validation/2026-10-25/partner-source-manifest.json)，用于追溯原始版本。

| 原源码位置 | 原注释标记 | 实现归属说明 |
| --- | --- | --- |
| `code/kern/mm/pmm.c:65` | `lab2 function1 YOUR CODE` | 2412075-朱钟铭 |
| `code/kern/mm/best_fit_pmm.c:6` | `lab2 function2-2 YOUR CODE` | 2412075-朱钟铭 |

这里是独立署名说明。用户要求不改动搭档代码，因此未替换原文件的 `YOUR CODE`；它不能冒充已经满足“必须在源码内替换标记”的字面要求。如果助教严格检查该项，仍需允许仅修改这两处注释。运行入口、署名说明和截图均不能替代这一源码内操作。

#### 日常 Buddy 与独立 Best Fit 验证

日常 `make`、`make qemu` 继续使用原版默认 Buddy。外层 `make grade` 现在运行独立的 Best Fit 验证入口：将原代码复制到临时目录，调用原框架的 `tools/inject.py` 注入课程测试，以 `-O0 -g` 调试配置构建；QEMU 暂停后，GDB 在 PMM 初始化前把当前管理器选择为 Best Fit，并确认实际进入 `best_fit_init()` 和 `best_fit_check()`，随后由原版 `tools/grade.sh` 检查真实启动结果。

该模式没有改写原评分脚本、伪造 PASS 输出或替换算法。临时目录中的课程注入是原评分流程已有的操作，工作区的原始 `code/` 文件未变；默认 Buddy 的选择也未变。使用 O0 是为了避免 O2 将打印参数提前缓存，保证调试切换后的打印与实际选择一致。这是一个独立验证配置，不能说日常 Buddy 内核本身变成了 Best Fit。

实测 [Best Fit 评分](../validation/2026-10-25/course-grade-best-fit.txt)为 **20/20**，[完整启动记录](../validation/2026-10-25/best-fit-grade-boot.txt)显示 Best Fit、页初始化、分配器检查和 SLUB 检查通过；[GDB 选择与真实检查断点](../validation/2026-10-25/best-fit-selection.txt)保存了实际调用栈。

`make grade-original` 仍保留原版默认 Buddy 直接评分方式，其 **10/20** 是该入口要求 Best Fit 与默认选择不同的结果，不代表 Buddy 算法错误，也不能直接等同于助教的实验最终成绩。原始两份课程测试文件均保持不变。

### 13.4 真实 IDE 调试截图

下面是 2026-10-25 对搭档原版代码进行真实 QEMU + GDB 调试时采集的 VS Code 窗口截图。窗口位于原有受信任的 `ucore-labs` 工作目录；该目录的原版代码与当前实验工作目录完全一致。截图保存原始 JPEG，没有用文本日志绘图或 AI 生成图像替代现场。

第一张显示 `buddy_check()` 的入口、实际调用栈以及之前经过 `kern_init()` 的断点输出。此时停在检查入口，截图本身不代表检查已全部执行完成。

![真实 Buddy 检查入口](images/01-buddy-breakpoint.jpg)

第二张显示默认 Buddy 检查返回后，到达 `slub_check()` 的入口及其调用栈。SLUB 的完整成功结论另由真实启动和三后端专项日志支持，不能仅由入口截图推出。

![真实 SLUB 检查入口](images/02-slub-breakpoint.jpg)

IDE 在该 QEMU 硬件断点上显示红色暂停原因标签，是 `Hit breakpoint` 的调试停止事件；不等于内核 panic。优化构建中部分变量显示 optimized out，仍按实测保留。截图、日志和对应 ELF 构建需一起阅读。

## 参考资料

本报告阅读了 Lab2 入口、目标、练习、文件说明、分页各节、内存管理各节、GDB 调试及报告要求，共 18 个页面。主要引用如下：

- [Lab2：物理内存和页表](http://oslab.mobisys.top/lab2026/_book/lab2/lab2.html)
- [实验目的](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_1_goal.html)、[实验内容](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_2_contents.html)、[练习](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_2_1_exercise.html)、[文件说明](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_2_2_files.html)
- [物理内存和页表](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_3_pmpt.html)、[相关原理](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_3_1_principles.html)、[分页机制](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_3_2_phymem_page.html)、[TLB](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_3_3_phymem_tlb.html)
- [页表建立](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_3_4_page.html)、[关键问题](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_3_4_1_key_problems_in_seg_page.html)、[内核初始化](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_3_4_2_kernel_initialization.html)
- [物理内存管理设计](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_3_5_pmpt.html)、[pmm_init](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_3_5_1_pmm_init.html)、[物理内存探测](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_3_5_2_search_phymem_layout.html)、[页面分配算法](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_3_5_3_phymem_allocation.html)
- [QEMU MMU 调试](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_4_qemu_mmu_debug.html)、[实验报告要求](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_5_labs_requirement.html)
- QEMU 4.1.1 对应源码：`target/riscv/cpu_helper.c`、`accel/tcg/cputlb.c`；本机路径 `/home/viewfinder/qemu-4.1.1/`，关键断点和实际调用栈见附件。
