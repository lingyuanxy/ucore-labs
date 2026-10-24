# Lab2 提示词汇总

本文汇总五份上传提示词的完整原文，以及本次对话中已记录的关键补充提示。终端输出与实操过程另见 [gdb_test_1.md](gdb_test_1.md)，实验结论见 [report.md](report.md)。

原始上传文件仍单独保留。原文中的路径属于设计提示词时的布局；`lab2/code/` 对应当前工作目录下的 `code/`，不更改原文以保留迭代记录。

## 一、环境配置与 page_init 引导审阅

以下为实际对话中的提示，按主题整理；这一阶段是本人编写、AI 引导审阅，没有单条生成完整函数的提示词。

> .vscode文件夹的参数有问题，这里应该用riscv-gcc交叉编译，现在有一些地方会报错，修改一下编译选项

> 把刚才写的默认 Lab2 构建任务删了，不要做多余的动作

> 帮我核定一下page_init的正误并引导我修改，不要直接肯定或否定我，要引导式教学，如果发现我有一些地方理解错误要指出来

> 如何检查内存信息是否有效

> pages[] 描述符数组 怎么放置？从哪开始放置

> uintptr_t desc_end = (uintptr_t)(pages + (npage - nbase)); 这个错了吧，为什么不乘描述符大小

> 第二点的意思是说，我在分配页面之前还需要给pages里的字段赋值？

> 内核不属于可分配的物理内存？

## 二、思考题与算法讨论

> 请回答一下扩展任务 Challenge：硬件的可用物理内存范围的获取方法（思考题）

> 为什么default_init_memmap需要设置base->property = n而我们写的init_page不需要

> page_link记录的什么

> default_free_pages是在干什么？

Best-Fit 任务在确认修改范围后，采用了用户明确选择：

> 按提示词实现 best_fit_pmm.c，保留 First-Fit 参考实现

后续讨论：

> 这里将块按照地址排序和按照大小排序哪个更合理

> 优化你说的第一条

最后一条在当时讨论中指“找到精确匹配后提前退出”。它细化了原始 Best-Fit 提示词中的完整遍历要求，最终代码保留地址排序和相同大小低地址优先。

## 三、Best-Fit 完整实现提示词

原始文件：[writing-block.md](writing-block.md)。

````markdown
# [PROMPT]

**任务**：修改文件 `kern/mm/best_fit_pmm.c`，实现完整的 **Best-Fit（最佳适应）物理内存管理模块**。

在完成任务一 First-Fit 物理内存分配器的基础上，参考 `kern/mm/default_pmm.c` 中的完整实现，在 `kern/mm/best_fit_pmm.c` 中标有 `LAB2` 和 `YOUR CODE` 的位置完成 Best-Fit 分配器。

Best-Fit 算法要求：在所有能够满足申请页数的连续空闲物理页块中，选择**大小最小且不小于申请页数**的空闲块进行分配，从而尽量减少本次分配产生的剩余空间。

除分配策略外，其余物理页管理行为应遵循项目现有 First-Fit 实现中的接口规范、数据结构和状态约定。

**操作要求**：

1. 必须在项目中直接修改真实文件 `kern/mm/best_fit_pmm.c`，而不是仅在对话中展示代码。
2. 首先阅读 `kern/mm/default_pmm.c`、`kern/mm/best_fit_pmm.c` 和 `kern/mm/pmm.h`，必要时阅读 `kern/mm/memlayout.h`、`kern/libs/list.h` 以及相关头文件，确认数据结构、宏定义、链表接口和分配器注册方式。
3. 在 `best_fit_pmm.c` 中补全所有缺失的管理函数、辅助代码、静态变量以及 `best_fit_pmm_manager` 注册结构。
4. 实现所有标有 `LAB2` 和 `YOUR CODE` 的相关代码，但不局限于这些标记。如果完成模块所需的函数声明或定义完全缺失，应自行补充。
5. 使用项目中已有的 `struct Page`、`free_area_t`、`list_entry_t` 和相关函数，不得自行创建不兼容的数据结构或外部接口。
6. 必须保留 `basic_check()` 和 `best_fit_check()` 的现有实现，不得修改其函数签名、测试逻辑、断言或测试数据。
7. 不得修改 `default_pmm.c`、`pmm.h`、公共链表实现以及其他已有模块。原则上仅修改 `kern/mm/best_fit_pmm.c`。
8. 算法的时间复杂度和空间复杂度不作要求，优先保证正确性和测试通过。

**输出要求**：

直接执行文件修改，并在完成后检查最终代码。

- 保留目标文件原有的测试函数及其他无关代码。
- 将新增的函数、静态变量和注册结构放置在合理位置，保证编译器能够正确识别。
- 不允许只给出代码片段而不修改文件。
- 不允许通过删除测试、弱化断言或硬编码测试结果的方式使测试通过。
- 完成后简要说明修改了哪些函数、Best-Fit 的实现方式，以及测试结果。
- 如果项目提供构建或测试命令，应运行相关测试并修复实现中的问题；不得为通过测试而修改测试代码。

# [RELY]

## 1. 参考实现

`kern/mm/default_pmm.c` 已实现完整的 First-Fit 物理内存管理器。

其模块内部状态使用：

```c
static free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)
```

其中：

- `free_list` 为管理空闲物理页块的循环双向链表，链表头是哨兵节点。
- `nr_free` 表示当前空闲物理页的总数量，而不是空闲块的数量。
- 每个链表节点通过 `struct Page` 的 `page_link` 字段连接。
- 每个空闲块由连续的物理页组成，链表中只保存空闲块首页对应的节点。
- 空闲块首页的 `property` 字段记录连续空闲页数。
- `PageProperty(page)` 用于判断对应页面是否为空闲块首页。
- 空闲块按物理页地址升序排列，以便释放页面时检查相邻空闲块并合并。

上述约定来自 `default_pmm.c`，Best-Fit 应与之兼容。

## 2. 物理页管理接口

参考工程中已有的操作：

```c
PageReserved(page)
PageProperty(page)

SetPageProperty(page)
ClearPageProperty(page)

set_page_ref(page, 0)

list_init(list)
list_empty(list)
list_next(le)
list_prev(le)
list_add(le, new_le)
list_add_before(le, new_le)
list_del(le)

le2page(le, page_link)
```

使用前应根据工程头文件确认其实际定义和参数含义，不得自行假设不存在的接口。

## 3. Page 状态约定

阅读 `pmm.h` 和 `memlayout.h` 中的相关定义，并遵守以下已有逻辑：

- `PG_reserved` 标志表示物理页是否被保留。
- `PG_property` 标志表示页面是否为空闲块首页。
- `property` 记录该空闲块包含的连续物理页数。
- `ref` 表示页面引用计数。
- 初始化或释放物理页时，应按照参考实现重置页面状态及引用计数。
- 对已经分配的页面，不能错误保留空闲块首页标志。
- 空闲块分裂或合并后，首页标志与 `property` 必须保持一致。

## 4. 管理器接口与测试

目标文件 `kern/mm/best_fit_pmm.c` 已提供：

```c
static void basic_check(void);
static void best_fit_check(void);
```

以上仅表示测试函数的预期签名，应以实际工程代码为准，不得重新实现或修改它们。

目标文件没有完整提供 Best-Fit 管理函数及 `best_fit_pmm_manager` 注册结构，需要自行实现。

必须阅读 `pmm.h` 中的 `struct pmm_manager`，确认其函数指针成员的名称、参数和返回值，并按照项目接口进行注册。

测试函数可能直接读取和修改 `free_list`、`nr_free`，或检查页面的 `property` 和 `PG_property` 状态。

因此，不能仅保证 `alloc_pages()` 的返回结果正确，还必须保证分配器内部状态符合测试函数的约定。

测试过程中可能暂存原空闲链表和空闲页数量、建立临时空闲链表，最后恢复原有状态。实现不得破坏这种测试方式。

# [GUARANTEE]

必须实现以下主要函数和注册结构。若目标文件不存在这些声明或定义，应自行添加。

```c
static void best_fit_init(void);

static void best_fit_init_memmap(
    struct Page *base,
    size_t n
);

static struct Page *best_fit_alloc_pages(
    size_t n
);

static void best_fit_free_pages(
    struct Page *base,
    size_t n
);

static size_t best_fit_nr_free_pages(void);

const struct pmm_manager best_fit_pmm_manager;
```

其中，`best_fit_pmm_manager` 必须提供完整定义，而不是仅声明变量。

注册时应按照实际 `struct pmm_manager` 定义，完成以下成员绑定：

```c
const struct pmm_manager best_fit_pmm_manager = {
    .name = "best_fit_pmm_manager",
    .init = best_fit_init,
    .init_memmap = best_fit_init_memmap,
    .alloc_pages = best_fit_alloc_pages,
    .free_pages = best_fit_free_pages,
    .nr_free_pages = best_fit_nr_free_pages,
    .check = best_fit_check,
};
```

参考实现的注册结构位于 `default_pmm.c` 末尾。如工程中的接口定义有所不同，应以实际头文件为准。

允许根据需要添加：

- 模块内部静态变量，例如 `free_area`。
- 模块内部宏定义，例如 `free_list`、`nr_free`。
- 辅助函数，例如用于有序插入空闲块或合并相邻空闲块的 `static` 函数。

不允许重复定义工程中已有的公共函数或修改公共接口。

# [SPECIFICATION]

## 1. best_fit_init()

**功能**：初始化 Best-Fit 分配器的内部管理状态。

要求：

1. 初始化空闲链表，使 `free_list` 成为空的循环双向链表。
2. 将空闲页计数 `nr_free` 设置为 0。
3. 使用与参考 First-Fit 实现兼容的 `free_area_t` 数据结构。

预期效果：

```c
list_empty(&free_list) == true
nr_free == 0
```

## 2. best_fit_init_memmap(struct Page *base, size_t n)

**功能**：将从 `base` 开始的连续 `n` 个物理页初始化为空闲内存块，并纳入空闲链表。

要求：

1. 使用 `assert(n > 0)` 检查参数。
2. 遍历 `[base, base + n)` 范围内的所有页面。
3. 检查页面原先处于保留状态，参照 `default_init_memmap()` 清除相关管理信息。
4. 将每个页面的引用计数设置为 0。
5. 设置 `base->property = n`。
6. 调用 `SetPageProperty(base)` 标记空闲块首页。
7. 将 `nr_free` 增加 `n`。
8. 将 `base->page_link` 插入 `free_list`，保持链表按物理地址升序排列。

需要处理的情况：

- Case 1：`free_list` 为空，直接插入。
- Case 2：新空闲块地址小于所有已有空闲块，插入链表开头。
- Case 3：新空闲块地址处于两个已有空闲块之间，插入对应位置。
- Case 4：新空闲块地址大于所有已有空闲块，插入链表末尾。
- Case 5：连续多次初始化不同内存区域，保证计数和链表状态正确。

初始化阶段的空闲块处理方式应与项目 First-Fit 参考实现及测试约定一致，不得擅自改变测试依赖的空闲块边界。

## 3. best_fit_alloc_pages(size_t n)

**功能**：采用 Best-Fit 算法分配连续 `n` 个物理页。

### 3.1 参数和容量检查

1. 使用 `assert(n > 0)`。
2. 如果 `n > nr_free`，直接返回 `NULL`。
3. 如果空闲总页数足够，但不存在单个长度不小于 `n` 的连续空闲块，仍然返回 `NULL`。

### 3.2 Best-Fit 查找策略

必须遍历整个空闲链表，查找满足：

```c
page->property >= n
```

的候选空闲块。

选择其中 `property` 最小的空闲块。

即：

```text
目标空闲块大小
= min { block.property | block.property >= n }
```

若多个候选块大小相同，优先选择链表中最先遇到的块，以保证行为确定。

**禁止找到第一个满足条件的空闲块后立即返回。** 这种方式属于 First-Fit，而不是 Best-Fit。

例如：

```text
空闲块 A：10 页
空闲块 B： 4 页
空闲块 C： 7 页

申请：3 页
```

Best-Fit 必须选择 B，而不能选择 A。

### 3.3 分配处理

**Case 1：没有符合要求的空闲块**

返回 `NULL`，不得修改空闲链表、空闲页计数和已有空闲块状态。

**Case 2：选中空闲块大小恰好为 n**

- 从空闲链表删除该块首页节点。
- 清除被分配块首页的 `PG_property` 标志。
- 将 `nr_free` 减少 `n`。
- 返回该块首页指针。

**Case 3：选中空闲块大小大于 n**

假设原空闲块大小为 `m`，且 `m > n`。

- 从该块起始位置分配连续 `n` 页。
- 剩余空闲块从 `page + n` 开始。
- 设置剩余块的 `property = m - n`。
- 为剩余块首页设置 `PG_property`。
- 从空闲链表移除原空闲块首页节点。
- 将剩余空闲块重新接入原位置，保持地址有序。
- 清除已分配块首页的 `PG_property`。
- 将 `nr_free` 减少 `n`。
- 返回原空闲块首页指针。

不得丢失剩余空闲页，也不得错误地将已分配页面保留在空闲链表中。

### 3.4 必须处理的边界情况

- Case 4：仅有一个空闲块，申请页数小于该块大小。
- Case 5：仅有一个空闲块，申请页数恰好等于该块大小。
- Case 6：存在多个候选空闲块，必须选择最小可用块。
- Case 7：存在多个大小相同的最优空闲块。
- Case 8：剩余空闲块只有 1 页。
- Case 9：空闲页总数足够，但没有足够大的连续空闲块。
- Case 10：连续进行多次分配，确保空闲块状态和 `nr_free` 始终正确。

## 4. best_fit_free_pages(struct Page *base, size_t n)

**功能**：释放从 `base` 开始的连续 `n` 个物理页，并合并相邻空闲块。

该函数的释放逻辑可以参考 `default_free_pages()`，因为 Best-Fit 与 First-Fit 的主要区别在于分配时选择哪个空闲块，而不是释放流程。

### 4.1 页面状态恢复

1. 使用 `assert(n > 0)`。
2. 遍历待释放范围内的所有页面。
3. 检查页面未设置 `PG_reserved` 和 `PG_property` 标志。
4. 清除页面 `flags`，并将引用计数设置为 0。
5. 设置 `base->property = n`。
6. 设置 `base` 的 `PG_property` 标志。
7. 将 `nr_free` 增加 `n`。

### 4.2 插入空闲链表

按照物理地址升序，将新释放的空闲块插入 `free_list`。

必须正确处理链表为空、插入表头、插入中间和插入表尾的情况。

### 4.3 合并相邻空闲块

插入后，检查前驱和后继空闲块是否在物理地址上连续。

**Case 1：前后均不相邻**

保持为独立空闲块。

**Case 2：仅与前一个空闲块相邻**

若满足：

```c
prev_page + prev_page->property == base
```

则：

- 增加前一个空闲块首页的 `property`。
- 清除原 `base` 的 `PG_property`。
- 删除原 `base` 的链表节点。
- 将合并后空闲块的首页更新为 `prev_page`。

**Case 3：仅与后一个空闲块相邻**

若满足：

```c
base + base->property == next_page
```

则：

- 增加 `base->property`。
- 清除后一个空闲块首页的 `PG_property`。
- 删除后一个空闲块首页的链表节点。

**Case 4：同时与前后两个空闲块相邻**

先与前一个空闲块合并，再基于更新后的空闲块首页与后一个空闲块合并。

最终三个连续空闲块必须成为一个空闲块。

**Case 5：空闲链表原先为空**

释放后形成一个新的空闲块。

**Case 6：多次连续释放和重新分配**

不得重复计数、丢失页面或保留已经失效的空闲块链表节点。

特别注意：

- `nr_free` 在释放时只增加一次 `n`。
- 合并空闲块不改变空闲页总数，因此合并阶段不得再次增加 `nr_free`。
- 合并后只能保留最终空闲块首页的 `PG_property` 标志。
- `list_del()` 只负责移除链表节点，不代表实际释放 `struct Page` 结构体。

## 5. best_fit_nr_free_pages()

**功能**：返回当前空闲物理页总数。

要求：

```c
return nr_free;
```

返回值必须与真实空闲物理页总数一致，并与分配、释放操作对 `nr_free` 的修改保持同步。

特别注意：已有测试函数可能直接设置 `nr_free = 0`，因此不得使用另一份独立计数器代替 `nr_free`。

## 6. best_fit_pmm_manager

**功能**：定义并注册 Best-Fit 物理内存管理器。

要求：

1. 定义工程要求的 `const struct pmm_manager best_fit_pmm_manager`。
2. 设置管理器名称为 `"best_fit_pmm_manager"`。
3. 将各函数指针关联到对应的 Best-Fit 实现。
4. 将 `.check` 成员指向现有 `best_fit_check()`。
5. 保证管理器可被现有物理内存管理框架正常使用。
6. 不得修改 `struct pmm_manager` 本身的定义。

## 7. 测试函数兼容性

必须保留：

```c
basic_check()
best_fit_check()
```

不得修改、替换、绕过或删除两个测试函数。

应检查测试函数中的实际断言，保证实现满足其状态要求，包括：

- 页面分配和释放结果正确。
- 分配后页面不再标记为空闲块首页。
- 空闲块首页的 `property` 正确。
- `free_list` 中的节点及顺序正确。
- `nr_free` 与真实空闲页总数一致。
- 空闲块分裂后，剩余块的状态正确。
- 相邻空闲块释放后能够正确合并。
- Best-Fit 能够选择符合要求的最小空闲块。
- 测试函数临时清空、保存和恢复 `free_list` 与 `nr_free` 时，分配器能够正常工作。

如果测试函数还有其他特定状态要求，必须根据实际代码满足这些要求。

## 8. 实现限制与最终检查

实现完成后，检查以下项目：

1. `best_fit_pmm.c` 中所有必须实现的接口均已定义。
2. `best_fit_pmm_manager` 已完整注册。
3. 模块使用的头文件、类型、宏和链表函数均存在于工程中。
4. 不存在重复定义、缺失声明、未定义符号或不兼容的函数签名。
5. 实现是 Best-Fit，而不是直接复制 First-Fit 的查找逻辑。
6. 链表在插入、删除、分裂、合并之后仍然保持正确。
7. `PageProperty`、`property`、`nr_free` 等状态符合测试约定。
8. `basic_check()` 和 `best_fit_check()` 未发生任何修改。
9. 除 `kern/mm/best_fit_pmm.c` 外，没有修改其他项目文件。
10. 若可以运行构建和测试，应验证通过，并如实报告结果。

**最终要求：直接修改工程中的 `kern/mm/best_fit_pmm.c`，完成能够参与现有 PMM 框架运行的 Best-Fit 分配器，不要仅输出实现建议或代码示例。**
````

## 四、Buddy System 实现提示词

原始文件：[writing-block-1.md](writing-block-1.md)。

````markdown
# [PROMPT]

**任务**：参考 ucore 操作系统现有的物理内存管理框架，从零实现 **Buddy System（伙伴系统）物理内存分配模块**，并将其接入内核，使其能够替代现有的 First-Fit 分配器运行。

主要目标文件：

- `kern/mm/buddy_pmm.c`：新建文件，实现 Buddy System 分配器。
- `kern/mm/buddy_pmm.h`：根据需要新建头文件，声明管理器注册结构。
- `kern/mm/pmm.c`：根据现有代码修改分配器选择或注册逻辑。
- 相关构建文件：只有在新模块无法自动参与编译时才进行必要修改。

**操作要求**：

1. 必须直接在实际工程中创建或修改文件，不能仅输出代码片段。
2. 首先阅读 `kern/mm/default_pmm.c`、`kern/mm/default_pmm.h`、`kern/mm/pmm.c`、`kern/mm/pmm.h` 及相关链表、物理页定义，理解 ucore 的物理内存管理框架。
3. 参考 First-Fit 分配器的接口组织方式，实现独立的 Buddy System 分配模块。
4. Buddy System 管理的每个空闲块必须包含连续的 \(2^k\) 个物理页，其中 \(k\) 为非负整数。
5. 分配时选择能够容纳请求的最小阶空闲块。如果只有更大的块，需要逐级分裂。
6. 释放时寻找对应的伙伴块，在满足条件时逐级向上合并。
7. 支持 `init_memmap(base, n)` 传入任意正整数页数，不能假设所有可用内存区域的大小都是 2 的幂。
8. 处理已有 PMM 接口允许的分配与释放方式，保证不会发生页重叠、越界分配或错误合并。
9. 根据工程实际的管理器选择方式，完成 Buddy System 的注册和内核接入。
10. 保留已有 First-Fit、Best-Fit 模块以及公共测试函数，不得为了运行新模块而删除或破坏原有实现。

算法时间复杂度和空间复杂度不作要求，优先保证正确性、可编译性及与 ucore 框架的兼容性。

**输出要求**：

直接创建或修改工程文件。完成后：

- 说明新增和修改的文件。
- 确认 Buddy System 已成为当前选用的物理内存管理器。
- 尝试编译并运行内核，解决实现导致的编译或运行错误。
- 简要说明阶数管理、分裂、伙伴识别和合并策略。
- 不得只生成代码而不执行文件操作。
- 如果当前环境无法编译或运行，应明确报告未验证的部分，不得声称已经通过测试。

# [RELY]

## 1. ucore 物理内存管理框架

项目已经具有完整的 First-Fit 物理内存管理器。

参考文件：

```text
kern/mm/default_pmm.c
kern/mm/default_pmm.h
kern/mm/pmm.c
kern/mm/pmm.h
```

`default_pmm.c` 实现了以下主要函数：

```c
static void default_init(void);

static void default_init_memmap(
    struct Page *base, size_t n
);

static struct Page *default_alloc_pages(
    size_t n
);

static void default_free_pages(
    struct Page *base, size_t n
);

static size_t default_nr_free_pages(void);
```

现有管理器注册方式为：

```c
const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",
    .init = default_init,
    .init_memmap = default_init_memmap,
    .alloc_pages = default_alloc_pages,
    .free_pages = default_free_pages,
    .nr_free_pages = default_nr_free_pages,
    .check = default_check,
};
```

Buddy System 必须遵循实际 `pmm.h` 中 `struct pmm_manager` 的接口定义。

## 2. 物理页元数据

参考 `pmm.h`、`memlayout.h` 中的 `struct Page` 和相关宏。

已知物理页管理涉及：

- `flags`：物理页状态标志。
- `property`：用于记录空闲块大小等管理信息。
- `ref`：物理页引用计数。
- `page_link`：双向链表节点。
- `PG_reserved`：保留页标志。
- `PG_property`：空闲块首页标志。

可使用已有接口：

```c
PageReserved(page)
PageProperty(page)
SetPageProperty(page)
ClearPageProperty(page)
set_page_ref(page, 0)
```

Buddy System 应保持这些字段的基本语义与现有 PMM 框架一致。

若需要记录分配块的阶数或大小，应优先利用模块内部数据结构或现有页面元数据，并保证不会破坏公共字段原有用途。

## 3. 链表接口

ucore 使用带哨兵头节点的循环双向链表。

可参考：

```c
list_init()
list_empty()
list_next()
list_prev()
list_add()
list_add_before()
list_del()
le2page()
```

应阅读实际的 `list.h`，确认具体接口及其参数含义。

## 4. Buddy System 基本原理

Buddy System 将空闲内存划分为大小为 \(2^k\) 页的块。

可以采用**按阶数维护多个空闲链表**的方式：

```text
Order 0：每块 1 页
Order 1：每块 2 页
Order 2：每块 4 页
Order 3：每块 8 页
Order 4：每块 16 页
...
```

每个阶数的空闲链表保存该阶所有可用空闲块的首页。

该设计仅为推荐实现方式。若采用其他内部结构，必须保证相同的分配、释放及伙伴合并语义。

伙伴块关系应根据同一页号坐标体系中的块编号计算。

对于起始页号为 `index`、阶数为 `k` 的有效块：

```c
buddy_index = index ^ (1UL << k);
```

使用上述公式的前提是：

- `index` 是从统一物理页编号基准计算的编号。
- 当前块起始页号满足 \(2^k\) 对齐。
- 伙伴块处于有效且由分配器管理的物理页范围内。
- 对应伙伴块确实是同阶空闲块。

不得直接对任意 `struct Page *` 指针地址做异或运算。

## 5. 现有框架的兼容要求

必须阅读 `pmm.c` 中对分配器接口的实际调用方式，特别检查：

- `alloc_pages(n)` 是否允许非 2 的幂次方页数。
- `free_pages(base, n)` 中的 `n` 是否为原始申请页数。
- 是否存在对已分配大块进行部分释放的情况。
- `init_memmap(base, n)` 的调用方式。
- 原有检查函数如何被调用。
- 分配器切换所依赖的头文件、符号及构建规则。

不能在未检查现有调用约定的情况下，擅自将公共接口限定为只能申请或释放 2 的幂次方页数。

# [GUARANTEE]

必须实现以下主要接口：

```c
static void buddy_init(void);

static void buddy_init_memmap(
    struct Page *base,
    size_t n
);

static struct Page *buddy_alloc_pages(
    size_t n
);

static void buddy_free_pages(
    struct Page *base,
    size_t n
);

static size_t buddy_nr_free_pages(void);

const struct pmm_manager buddy_pmm_manager;
```

还应提供可正常调用的检查函数入口：

```c
static void buddy_check(void);
```

第一阶段可以仅实现基本状态检查，并保留后续扩展位置。完整的算法测试由第二份 Prompt 实现。不得伪称第一阶段已经完成全部测试。

建议添加以下辅助功能，具体名称由实现决定：

```c
// 查找满足要求的阶数
static size_t buddy_get_order(size_t n);

// 向对应阶数的链表插入空闲块
static void buddy_insert_block(
    struct Page *base, size_t order
);

// 移除空闲块
static void buddy_remove_block(
    struct Page *base, size_t order
);

// 查找指定阶数的伙伴块
static struct Page *buddy_find_partner(
    struct Page *base, size_t order
);

// 将较大的块分裂到目标阶数
// 可根据实际设计添加参数
static void buddy_split_block(/* ... */);

// 合并空闲伙伴块
static void buddy_merge_block(/* ... */);
```

可以根据需要添加：

- 按阶数划分的空闲链表数组。
- 最大阶数常量或动态上界。
- 空闲物理页计数器。
- 已分配块大小或阶数记录。
- 辅助宏与内部 `static` 函数。

函数签名应以实际实现需求和工程类型定义为准，不允许引入未实现的外部依赖。

# [SPECIFICATION]

## 1. buddy_init()

**功能**：初始化 Buddy System 分配器的内部状态。

要求：

1. 建立能够按阶数管理空闲块的数据结构。
2. 若使用多条链表，则初始化每个阶数的链表头。
3. 将空闲物理页总数设为 0。
4. 初始化必要的分配元数据。
5. 所有链表必须满足 ucore 循环双向链表规范。

最大阶数应依据平台、可管理页数及整数位宽确定。

不得使用会发生移位溢出的表达式。

## 2. buddy_init_memmap(struct Page *base, size_t n)

**功能**：将一段连续可用物理内存划分为符合 Buddy System 要求的空闲块。

要求：

1. `assert(n > 0)`。
2. 检查页面初始状态。
3. 清理所管理页面的相关状态和引用计数。
4. 将 `[base, base + n)` 分解为若干大小为 \(2^k\) 的块。
5. 每个块必须满足其阶数对应的全局页号对齐要求。
6. 不得包含区间以外的物理页。
7. 设置每个空闲块首页的 `property` 和 `PG_property`。
8. 将空闲块插入对应阶数的链表。
9. 将空闲总页数增加 `n`。

**Case 1：n 为 2 的幂，且起始页号满足对齐**

例如，一段对齐的 8 页连续空闲区域可以直接登记为一个 Order 3 块。

**Case 2：n 不是 2 的幂**

例如，一个起始位置满足相应对齐条件的 13 页区间，可以划分为：

```text
8 页 + 4 页 + 1 页
```

若起始页号的对齐条件不允许这种划分，应采用其他合法的幂次方分解。

**Case 3：起始页号未按较大块大小对齐**

必须进一步分解，保证每个块满足对齐条件。

**Case 4：多次初始化不同物理内存区间**

不得错误地合并包含保留页、空洞或尚未纳入管理范围的物理地址区间。

应保证全部登记的空闲块互不重叠，且恰好覆盖所有初始化的可用页。

## 3. buddy_alloc_pages(size_t n)

**功能**：分配能够容纳 `n` 个连续物理页的最小 2 的幂次方块。

### 3.1 请求大小转换

要求：

```text
n = 1 → Order 0，分配 1 页
n = 2 → Order 1，分配 2 页
n = 3 → Order 2，分配 4 页
n = 4 → Order 2，分配 4 页
n = 5 → Order 3，分配 8 页
n = 8 → Order 3，分配 8 页
```

即选择最小的 `k`，使：

```text
2^k >= n
```

必须处理计算过程中的整数溢出。

### 3.2 查找空闲块

先检查目标阶数是否有空闲块。

若没有，则依次向更高阶数查找，直到找到可用块。

例如：

```text
请求：2 页（Order 1）

Order 1：空
Order 2：空
Order 3：存在 8 页块
```

应选择 Order 3 块并进行分裂。

若所有满足条件的阶数都没有空闲块，返回 `NULL`，不得修改已有空闲状态。

### 3.3 分裂较大的块

每次分裂将一个 Order k 块分成两个 Order k-1 块：

```text
8 页
 ├── 4 页
 │    ├── 2 页 → 分配
 │    └── 2 页 → 空闲
 └── 4 页     → 空闲
```

要求：

1. 从原阶数链表移除被分裂块。
2. 正确计算两个子块的起始位置。
3. 选择其中一个子块继续分裂或分配。
4. 将另一个子块插入对应阶数的空闲链表。
5. 更新所有受影响块的首页标志和大小信息。
6. 不得重复登记任何物理页。

### 3.4 分配完成

返回实际分配块的首页。

对于请求 `n`，内部占用大小为 `2^k` 时，应保证：

- 返回至少 `n` 个连续可用物理页。
- 整个 `2^k` 块不再被其他申请重复分配。
- 返回页面未错误地标记为空闲块首页。
- 记录实际占用的块大小或阶数，或采用其他能够正确释放的可靠机制。
- 空闲页计数按照实际被占用的页数减少。

例如，申请 3 页占用一个 4 页块，则空闲页数应减少 4，而不是 3。

### 3.5 必须处理的情况

- Case 1：请求 1 页。
- Case 2：请求的页数恰好为 2 的幂。
- Case 3：请求页数不是 2 的幂。
- Case 4：目标阶数恰好存在空闲块。
- Case 5：必须经过一次分裂。
- Case 6：必须经过多次递归分裂。
- Case 7：存在多个不同阶数的空闲块。
- Case 8：空闲总页数足够，但不存在能够提供所需连续块的可分配块。
- Case 9：可管理内存不足，返回 `NULL`。
- Case 10：连续分配多个块，不得出现地址重叠。

## 4. buddy_free_pages(struct Page *base, size_t n)

**功能**：释放指定物理内存块，并按照 Buddy System 规则进行伙伴合并。

### 4.1 释放参数与元数据

需要正确处理 `alloc_pages(n)` 与 `free_pages(base, n)` 的对应关系。

如果 `n` 不是 2 的幂，应根据申请时记录的实际块大小或一致的阶数计算规则，释放该次申请真正占用的整个块。

例如：

```text
alloc_pages(3) → 实际占用 4 页
free_pages(base, 3) → 恢复完整的 4 页块
```

不得只恢复前 3 页而遗失第 4 页。

必须先检查 `pmm.c` 及其他调用点是否存在部分释放行为。如果现有接口确实允许对已分配块的子区间进行释放，则需要设计兼容处理，不能简单地将此类合法调用视为完整块释放。

### 4.2 伙伴块定位

对于 Order k 的块，利用统一页号坐标体系计算：

```text
buddy_index = block_index XOR 2^k
```

只有同时满足以下条件，才允许合并：

1. 两个块均属于有效、已初始化的可管理物理页范围。
2. 两个块的阶数相同。
3. 两个块均为空闲状态。
4. 两个块满足严格的伙伴地址关系。
5. 合并后的块满足更高阶的对齐条件。

不能仅因为两个空闲块在物理地址上相邻，就认为它们是伙伴。

### 4.3 合并过程

若找到空闲伙伴：

1. 从对应阶数链表移除伙伴块。
2. 合并两个同阶块。
3. 使用较低物理页号作为合并后块的首页。
4. 更新合并后块大小和首页标志。
5. 将阶数增加 1。
6. 继续检查更高阶的伙伴块。

直到找不到能够合并的伙伴，或已经达到允许的最大阶数。

最后将合并结果插入对应阶数的空闲链表。

### 4.4 必须处理的情况

**Case 1：没有空闲伙伴**

直接将释放块加入对应阶数的空闲链表。

**Case 2：伙伴空闲且同阶**

合并成一个高一阶的空闲块。

**Case 3：伙伴处于已分配状态**

禁止合并。

**Case 4：相邻块大小不同**

即使物理地址连续，也不能直接合并，必须满足伙伴系统规定的同阶合并条件。

**Case 5：多次递归合并**

例如：

```text
1 + 1 → 2
2 + 2 → 4
4 + 4 → 8
```

如果伙伴持续满足条件，应完成多级合并。

**Case 6：伙伴位置超出有效内存范围**

不得访问或合并未初始化、保留或不可管理的页面。

**Case 7：释放非 2 的幂次方申请**

恢复完整的实际分配块，不得遗漏内部占用页。

**Case 8：连续分配、交错释放**

必须保证伙伴识别、块边界和空闲页统计始终正确。

### 4.5 空闲页计数

空闲页总数应按照实际恢复的物理页数增加。

伙伴合并仅改变块的组织形式，不改变空闲页总数，因此合并过程中不得重复增加计数。

## 5. buddy_nr_free_pages()

**功能**：返回当前可再次分配的物理页总数。

要求：

1. 返回 Buddy System 的真实空闲页数。
2. 分配时按照实际占用块大小减少。
3. 释放时按照实际释放块大小增加。
4. 分裂和合并操作不得重复修改计数。

若采用多阶空闲链表，应满足：

```text
nr_free = Σ(每个阶数的空闲块数 × 2^阶数)
```

## 6. buddy_pmm_manager

**功能**：注册 Buddy System 管理器。

应按照实际 `struct pmm_manager` 完成以下结构：

```c
const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
```

不得修改 `struct pmm_manager` 的公共定义。

## 7. 将 Buddy System 接入内核

阅读 `kern/mm/pmm.c`，确定当前分配器的选择方式。

要求：

1. 使 `buddy_pmm_manager` 能够被 PMM 框架引用。
2. 保证新模块参与编译和链接。
3. 将当前物理内存管理器切换为 Buddy System。
4. 不能破坏原有的 `alloc_pages()`、`free_pages()` 和 `nr_free_pages()` 等公共接口。
5. 保持原有 First-Fit 和 Best-Fit 代码完整。
6. 避免重复定义全局注册结构。
7. 保证 PMM 初始化完成之后可以正常进行物理页分配和释放。

如果工程提供了已有的管理器选择机制，应优先使用该机制；如果没有，则进行最小范围的必要修改。

## 8. 初步验证

本阶段尚未实现完整的 Buddy System 专项测试。

要求：

1. 提供有效的 `buddy_check()` 入口，使 PMM 框架能够正常调用。
2. 可以进行简单的初始化和状态一致性检查。
3. 不得修改或绕过已有的公共初始化流程。
4. 尝试使用项目实际支持的构建命令进行编译。
5. 如果启动失败，应区分编译错误、链接错误、内存管理错误及运行环境问题。

完整的 Buddy System 算法测试在第二阶段添加。

## 9. 最终检查

必须确认：

- [ ] 已创建 Buddy System 模块。
- [ ] 所有管理函数均已实现。
- [ ] 支持不同阶数的空闲块。
- [ ] 支持非 2 的幂次方大小的初始化区间。
- [ ] 支持按需分裂较大块。
- [ ] 支持严格按伙伴关系递归合并。
- [ ] 可以处理非 2 的幂次方分配请求。
- [ ] 空闲页计数准确。
- [ ] 不会跨越保留页或无效区域合并。
- [ ] `buddy_pmm_manager` 已注册。
- [ ] 已接入当前内核 PMM 框架。
- [ ] 没有破坏已有 First-Fit、Best-Fit 代码。
- [ ] 已尝试编译并如实报告结果。

**最终目标：生成完整的 Buddy System 物理内存管理模块，并将其接入 ucore，使内核能够使用 Buddy System 进行物理页分配与释放。**
````

## 五、Buddy System 测试提示词

原始文件：[writing-block-2.md](writing-block-2.md)。

````markdown
# [PROMPT]

**任务**：基于第一阶段已经实现的 Buddy System 物理内存管理模块，为其设计并实现完整的测试函数，检验分配器的正确性。

主要目标文件：

- `kern/mm/buddy_pmm.c`：添加或完善 Buddy System 测试函数。
- `kern/mm/buddy_pmm.h`：仅在测试实现确实需要新的声明时修改。
- 其他文件：原则上不修改，除非当前工程确实需要必要的测试注册或构建调整。

实验没有提供 Buddy System 测试框架，需要自行设计测试案例、断言和测试辅助函数。

测试必须覆盖 Buddy System 的主要算法特征，包括：

- 幂次方块管理。
- 非 2 的幂次方请求的向上取整。
- 较大空闲块的逐级分裂。
- 伙伴块关系识别。
- 同阶空闲伙伴合并。
- 多级递归合并。
- 非伙伴块禁止合并。
- 空闲页计数和数据结构一致性。
- 异常边界及测试结束后的内存状态恢复。

**操作要求**：

1. 必须直接修改实际工程文件，而不是仅在对话中给出测试代码。
2. 首先阅读第一阶段生成的 `buddy_pmm.c`、`buddy_pmm.h`，以及相关 `pmm.h`、`pmm.c` 和已有 First-Fit 测试代码。
3. 充分理解第一阶段 Buddy System 的内部表示方式，包括空闲链表、阶数、伙伴计算、分配块大小记录等。
4. 保留已经实现的管理函数及其接口，不得通过修改分配算法、降低断言要求或改变测试预期来掩盖错误。
5. 在 `buddy_pmm.c` 中设计测试函数，并通过 `buddy_check()` 统一执行。
6. 测试应使用 ucore 已有的 `assert()`、页面分配接口、空闲页统计接口及适当的内部状态检查。
7. 测试时不得访问越界页面、重复释放页面，或将未分配的页面当作合法块释放。
8. 测试过程中可以建立隔离的测试内存环境，但必须保证原有内核物理内存状态可正确恢复。
9. 测试结束后不得遗留未释放的测试内存，也不得破坏内核后续分配操作。
10. 算法时间复杂度和空间复杂度不作要求，优先保证测试的正确性、覆盖率和可重复性。

**输出要求**：

直接修改 `kern/mm/buddy_pmm.c`，完成所有测试函数及必要辅助函数。

完成后：

- 列出测试函数及其检查目标。
- 将所有测试接入 `buddy_check()`。
- 编译并运行相关测试。
- 对测试失败给出对应的断言位置和原因。
- 不得为通过测试而删除断言或修改 Buddy System 的预期规则。
- 如果发现分配算法存在错误，应报告具体问题及建议修复位置；未经必要性判断，不要擅自重写第一阶段整个模块。

# [RELY]

## 1. 已实现的 Buddy System 模块

第一阶段已生成 `kern/mm/buddy_pmm.c`，其中应包含：

```c
static void buddy_init(void);

static void buddy_init_memmap(
    struct Page *base, size_t n
);

static struct Page *buddy_alloc_pages(
    size_t n
);

static void buddy_free_pages(
    struct Page *base, size_t n
);

static size_t buddy_nr_free_pages(void);
```

这些接口构成测试的主要对象。

具体实现及内部状态必须通过读取第一阶段的实际代码确认，不得假设实现一定使用某种固定的链表名称或元数据布局。

## 2. 管理器注册

第一阶段已经定义：

```c
const struct pmm_manager buddy_pmm_manager;
```

测试必须通过其 `.check` 成员接入现有 PMM 框架。

## 3. 参考测试代码

可参考：

```text
kern/mm/default_pmm.c
```

其中现有的 `basic_check()` 和 `default_check()` 展示了：

- 使用 `assert()` 验证分配结果。
- 使用 `alloc_page()` 和 `alloc_pages()` 分配页面。
- 使用 `free_page()` 和 `free_pages()` 释放页面。
- 检查页面引用计数。
- 检查物理地址范围。
- 检查空闲链表及空闲页计数。
- 保存、隔离并恢复部分物理内存管理状态。

Buddy System 可以参考这种测试组织方法，但不能直接复制与 First-Fit 地址排序或任意连续页块分配语义绑定的断言。

## 4. Buddy System 核心性质

应依据第一阶段实现验证：

1. 每个空闲块大小均为 \(2^k\) 页。
2. 每个块起始页号满足对应的 \(2^k\) 对齐要求。
3. 同一物理页不能同时属于两个空闲块。
4. 已分配页不能仍处于空闲块链表中。
5. 分裂后的两个子块大小相等、地址连续且互不重叠。
6. 只有同阶且满足伙伴关系的空闲块才允许合并。
7. 可继续合并的同阶空闲伙伴不应长期同时保留为独立空闲块。
8. 空闲页计数应等于全部空闲块包含的物理页数之和。
9. `alloc_pages(n)` 的实际占用块大小应符合第一阶段明确采用的取整规则。
10. `free_pages(base, n)` 应正确恢复相应的已分配物理页。

# [GUARANTEE]

必须定义或完善以下测试入口：

```c
static void buddy_check(void);
```

建议将测试拆分为以下函数：

```c
static void buddy_check_basic(void);

static void buddy_check_init_memmap(void);

static void buddy_check_split(void);

static void buddy_check_merge(void);

static void buddy_check_partner(void);

static void buddy_check_non_power_two(void);

static void buddy_check_exhaustion(void);

static void buddy_check_stress(void);

static void buddy_check_invariants(void);
```

这些名称是建议，可以根据实际实现调整。

可以根据需要增加：

- 测试专用的静态辅助函数。
- 测试块大小及阶数计算函数。
- 受控测试内存区域。
- 状态快照和恢复函数。
- 空闲链表一致性检查函数。
- 分配区间重叠检查函数。

测试结束后必须保证实际系统的 PMM 状态与测试开始前保持一致，不得留下额外占用或错误登记的物理页。

禁止修改：

- 已有 First-Fit 和 Best-Fit 的测试函数。
- `struct pmm_manager` 的公共接口。
- PMM 的通用 API 定义。
- 与 Buddy System 无关的内核模块。

# [SPECIFICATION]

## 1. buddy_check_basic()

**功能**：检查基础页面分配和释放操作。

测试内容：

**Case 1：分配单页**

调用：

```c
struct Page *p = alloc_pages(1);
```

检查：

- 返回指针非 `NULL`。
- 返回物理页处于合法物理内存范围内。
- 页面引用计数符合现有 PMM 约定。
- 页面不再被标记为空闲块首页。

**Case 2：分配多个页面**

申请多个独立的页面，检查：

- 返回的物理页互不相同。
- 不存在页面重叠。
- 分配过程不破坏其他已分配页面。

**Case 3：释放页面**

对合法分配结果执行释放，检查：

- 页面重新成为可用内存。
- 空闲计数正确恢复。
- 后续仍然能够分配页面。

**Case 4：重复分配和释放**

连续执行多轮合法分配和释放，确认状态一致。

## 2. buddy_check_init_memmap()

**功能**：检查初始化阶段对空闲物理页范围的分解。

为了避免破坏内核原有状态，应在受控且安全的测试区域中进行。

测试案例：

| Case | 初始化范围 | 检查目标 |
|---|---|---|
| 1 | 1 页 | 应形成 Order 0 块 |
| 2 | 对齐的 2 页 | 应形成 Order 1 块 |
| 3 | 对齐的 4 页 | 应形成 Order 2 块 |
| 4 | 对齐的 8 页 | 应形成 Order 3 块 |
| 5 | 3 页 | 应被拆分成合法的幂次方块 |
| 6 | 13 页 | 全部 13 页均被正确登记 |
| 7 | 起始位置未按大块对齐 | 不得生成不满足对齐要求的块 |
| 8 | 不连续的可用区域 | 不得错误包含中间不可用页 |

应验证：

- 空闲块大小合法。
- 起始页号对齐正确。
- 所有初始化的物理页恰好被覆盖一次。
- 不出现越界或重叠。
- 空闲总页数正确。

如果实际工程不允许在正常运行期间重复调用全局 `init_memmap()`，应采用独立测试状态或受控测试辅助函数，不得直接破坏内核真实空闲链表。

## 3. buddy_check_split()

**功能**：检查较大空闲块能否按照 Buddy System 的规则逐级分裂。

构造一个包含 8 页的受控空闲块。

初始状态：

```text
Order 3：8 页
```

**Case 1：申请 4 页**

预期：

```text
8 页
 ├── 4 页 → 分配
 └── 4 页 → 空闲
```

检查：

- 返回 4 页块。
- 剩余 4 页块处于 Order 2。
- 分配区域和剩余区域互不重叠。
- 空闲页总数减少 4。

**Case 2：申请 2 页**

预期经过两次分裂：

```text
8 页
 ├── 4 页
 │    ├── 2 页 → 分配
 │    └── 2 页 → 空闲
 └── 4 页     → 空闲
```

检查剩余的 2 页和 4 页空闲块均位于正确阶数。

**Case 3：申请 1 页**

检查能够从更高阶连续分裂至 Order 0。

**Case 4：恰好分配整个块**

若请求大小与现有空闲块完全相同，不应产生不必要的分裂。

## 4. buddy_check_merge()

**功能**：检查释放后的伙伴合并行为。

### Case 1：两个同阶伙伴合并

准备两个真正具有伙伴关系的 Order 0 页面。

分别释放后，应合并成一个 Order 1 块：

```text
1 页 + 1 页 → 2 页
```

检查：

- 两个原块不再分别出现在 Order 0 空闲链表中。
- 新形成的块出现在 Order 1。
- 合并后首页正确。
- 总空闲页数正确。

### Case 2：不同释放顺序

分别测试：

```text
先释放低地址伙伴，再释放高地址伙伴
```

以及：

```text
先释放高地址伙伴，再释放低地址伙伴
```

两种顺序都应能够正确合并。

### Case 3：多级递归合并

构造一个包含 8 页的受控分配区域。

通过逐步释放，使其形成：

```text
Order 0 + Order 0 → Order 1

Order 1 + Order 1 → Order 2

Order 2 + Order 2 → Order 3
```

检查最终恢复为完整的 8 页空闲块。

### Case 4：没有空闲伙伴

若伙伴仍处于已分配状态，则释放块只能作为独立空闲块存在。

### Case 5：伙伴与其他空闲块交错分布

执行多次交错分配和释放，检查最终是否能够正确恢复完整空闲区域。

测试应检查内部结构，而不仅仅检查 `nr_free_pages()`。

## 5. buddy_check_partner()

**功能**：验证伙伴块判定条件。

必须覆盖以下情况。

**Case 1：两个同阶且互为伙伴的空闲块**

应允许合并。

**Case 2：两个物理地址相邻但不是同阶伙伴的块**

不得错误合并。

**Case 3：块大小不同**

不得直接进行同阶伙伴合并。

**Case 4：计算得到的伙伴位于无效或保留区域**

不得越界访问或合并。

**Case 5：伙伴已被分配**

不得将已分配页面重新加入空闲块。

**Case 6：伙伴页号的异或计算**

验证：

```text
buddy_index = block_index XOR 2^order
```

只在满足块对齐和有效范围条件时用于伙伴定位。

应结合第一阶段实际采用的页号基准验证计算结果。

## 6. buddy_check_non_power_two()

**功能**：检查非 2 的幂次方分配请求。

必须覆盖：

| 请求页数 | 预期实际占用 |
|---|---|
| 1 | 1 |
| 2 | 2 |
| 3 | 4 |
| 5 | 8 |
| 6 | 8 |
| 7 | 8 |
| 8 | 8 |
| 9 | 16 |

以上为分配器采用向上取整到最小 2 的幂次方块时的预期值。

对每个成功的请求，检查：

1. 实际分配块的大小。
2. 对应阶数是否正确。
3. 返回块是否满足所需对齐条件。
4. 空闲页总数是否按实际占用页数减少。
5. 使用原始申请大小执行相应合法释放后，空闲页数能否完整恢复。
6. 内部占用但未交付调用者的页面不会被重复分配。

例如：

```c
size_t before = nr_free_pages();

struct Page *p = alloc_pages(3);
assert(p != NULL);

assert(before - nr_free_pages() == 4);

free_pages(p, 3);

assert(nr_free_pages() == before);
```

上述示例必须在确认第一阶段采用这种接口契约后使用，并确保测试场景中不存在其他并发分配或额外状态变化。

如果第一阶段对非幂次方请求采用了不同但符合任务要求的管理策略，应先检查其契约，再设计对应断言，不能根据猜测硬编码结果。

## 7. buddy_check_exhaustion()

**功能**：检查内存不足时的分配行为。

测试内容：

**Case 1：申请超过最大可分配块大小的页数**

应返回 `NULL`，不得越界或修改原有空闲块。

**Case 2：空闲页总数足够，但没有满足要求的连续伙伴块**

应返回 `NULL`。

**Case 3：某个阶数链表为空，但更高阶链表存在可分裂块**

应能够向上查找并分裂，而不是立即失败。

**Case 4：申请失败后重新释放其他已分配块**

分配器应能够恢复正常分配。

**Case 5：申请大小计算可能发生溢出**

不得产生错误阶数、非法移位或越界分配。

对于极端输入，应遵循现有 API 的断言及失败返回约定，不得构造会直接导致无意义内核崩溃的非法测试。

## 8. buddy_check_stress()

**功能**：通过多轮不同大小、不同顺序的分配和释放，检查分配器状态。

设计一个确定性的测试序列，例如：

```text
申请 1 页
申请 2 页
申请 3 页
申请 4 页
释放第 2 次申请
申请 1 页
释放第 4 次申请
释放第 1 次申请
释放第 3 次申请
释放新增的 1 页申请
```

要求：

1. 使用数组保存成功的分配结果和对应请求大小。
2. 保证每次释放的参数与实际分配记录一致。
3. 检查不同活动分配块对应的实际占用区间不存在重叠。
4. 每次操作后检查空闲页计数。
5. 在关键步骤后检查各阶数空闲链表。
6. 最终释放所有测试分配块。
7. 确认空闲状态恢复。

还可以使用固定种子的伪随机序列增加覆盖率，但测试结果必须可以重复，不能依赖不可控的随机行为。

## 9. buddy_check_invariants()

**功能**：验证 Buddy System 的内部一致性。

如果第一阶段使用多阶空闲链表，则遍历所有阶数。

检查：

1. 每个链表中的空闲块阶数与实际块大小一致。
2. 每个空闲块首页都设置了 `PG_property`。
3. 每个空闲块包含 \(2^k\) 个物理页。
4. 块的起始页号满足阶数对齐要求。
5. 链表中没有重复节点。
6. 空闲块之间没有物理地址重叠。
7. 块没有覆盖内核保留区域或其他非法页面。
8. 空闲页总数等于所有空闲块大小之和。

例如：

```text
Order 0：3 个块 → 3 × 1 = 3 页
Order 1：2 个块 → 2 × 2 = 4 页
Order 2：1 个块 → 1 × 4 = 4 页

合计：11 页
```

应满足：

```c
assert(buddy_nr_free_pages() == 11);
```

这里的 11 仅为示例，实际测试应根据遍历得到的空闲块数量计算，不能硬编码。

此外，应检查不存在两个可以继续合并却未合并的同阶空闲伙伴块，除非第一阶段采用明确允许延迟合并的策略。

## 10. 测试内存隔离与恢复

这是必须重点处理的部分。

由于测试运行于内核 PMM 环境，错误修改全局空闲链表会影响内核后续运行。

要求：

1. 优先通过已有 PMM 接口获取测试所需的合法连续物理页。
2. 若需要确定性的分裂或合并测试，可以采用独立 Buddy 管理状态或受控测试内存区域。
3. 测试区域中的所有页必须处于已知、合法且互不冲突的状态。
4. 不得将仍属于原分配器空闲链表的页面直接重复登记到测试链表。
5. 如果需要暂存全局空闲链表，必须正确处理循环链表头节点与其前后驱的连接关系。
6. 不得仅通过浅拷贝多个 `list_entry_t` 头节点就假设完整链表状态已安全隔离。
7. 测试完成时，必须清理测试状态并恢复原有管理器状态。
8. 正常路径下，测试前后的空闲页总数必须一致。
9. 测试中所有暂时持有的物理页必须最终得到正确释放或恢复。

如果第一阶段的内部设计不适合直接隔离测试，应采用不破坏全局管理状态的黑盒测试，并结合只读内部状态检查辅助函数实现验证。

不能为了编写测试而直接重新初始化正在被内核使用的全局 PMM 状态。

## 11. buddy_check()

**功能**：作为 PMM 框架统一调用的 Buddy System 测试入口。

将设计完成的测试组织到该函数。

推荐结构：

```c
static void
buddy_check(void) {
    buddy_check_invariants();
    buddy_check_basic();
    buddy_check_init_memmap();
    buddy_check_split();
    buddy_check_merge();
    buddy_check_partner();
    buddy_check_non_power_two();
    buddy_check_exhaustion();
    buddy_check_stress();
    buddy_check_invariants();
}
```

上述顺序仅供参考，应根据测试状态隔离方式和实际依赖关系调整。

所有测试函数必须具有真实的测试逻辑。

不得定义只返回、没有任何有效断言的空测试函数来代替要求完成的测试。

确保：

```c
.check = buddy_check,
```

已经正确配置在 `buddy_pmm_manager` 中。

## 12. 编译、运行及结果判定

完成测试后，执行以下操作：

1. 检查测试代码是否存在编译错误或链接错误。
2. 使用项目提供的实际构建命令编译内核。
3. 通过项目支持的 QEMU 或其他运行方式启动内核。
4. 确保 Buddy System 管理器已被选用。
5. 确认 `buddy_check()` 被实际执行，而不是仅仅参与编译。
6. 观察所有断言的执行结果。
7. 如果发生失败，分析是测试设计错误、状态污染还是分配器实现错误。
8. 保留有效的失败断言，不能删除失败测试以获得表面上的通过结果。
9. 测试全部通过后，检查内核能否继续正常运行。

可以在测试开始和结束时使用项目已有输出接口打印适当信息。

## 13. 最终检查

完成后确认：

- [ ] 已实现统一测试入口 `buddy_check()`。
- [ ] 测试入口已接入 PMM 管理器。
- [ ] 基本分配和释放测试完整。
- [ ] 非 2 的幂次方内存初始化测试完整。
- [ ] 块分裂测试完整。
- [ ] 伙伴定位测试完整。
- [ ] 单级合并和递归合并测试完整。
- [ ] 非伙伴不得合并的测试完整。
- [ ] 非 2 的幂次方分配测试完整。
- [ ] 内存不足和边界测试完整。
- [ ] 多次交错分配和释放测试完整。
- [ ] 链表、阶数和空闲页统计一致性得到验证。
- [ ] 测试未破坏内核其他物理页。
- [ ] 测试完成后没有资源泄漏。
- [ ] 未修改已有 First-Fit 和 Best-Fit 测试。
- [ ] 已尝试编译、运行并报告真实结果。

**最终目标：建立能够检验 Buddy System 分配、分裂、伙伴识别、合并及内部状态一致性的测试体系，并保证测试代码能够在现有 ucore 内核环境中正常编译、执行。**
````

## 六、SLUB 实现提示词

原始文件：[writing-block-2-1.md](writing-block-2-1.md)。

````markdown
# [PROMPT]

**任务**：参考现有 ucore 物理内存管理框架，从零创建并实现 `kern/mm/slub.c`、`kern/mm/slub.h`，完成简化版 **SLUB（内存对象分配）模块**，并将其接入内核，实现基于物理页分配器的任意大小内存对象分配和释放。

本模块采用两层内存管理架构：

- **第一层：物理页分配层。** 使用现有 `alloc_pages()` 和 `free_pages()` 接口，以物理页为基本单位申请和释放内存。
- **第二层：SLUB 对象分配层。** 在第一层分配的物理页中划分固定大小的对象槽位，使用不同大小类别的缓存管理对象，实现小于一页的内存分配。对于超出单页 Slab 容量的申请，使用多页分配路径。

本实验允许简化 SLUB 算法，不要求实现 Linux SLUB 的全部优化，但必须体现对象缓存、内存复用、页级资源管理和按需回收的核心思想。

**操作要求**：

1. 必须直接在项目中创建或修改真实文件，不得仅在对话中展示代码。
2. 首先阅读 `kern/mm/pmm.c`、`kern/mm/pmm.h`、`kern/mm/default_pmm.c`、`kern/mm/memlayout.h` 及相关头文件，确定现有物理页分配接口、物理页结构体和内核地址转换机制。
3. 检查工程是否已有 `kmalloc`、`kfree`、SLAB 或其他动态内存分配接口，避免重复定义符号。
4. 新建 `kern/mm/slub.c` 和 `kern/mm/slub.h`，实现独立的 SLUB 对象分配器。
5. 根据实际工程构建规则，将新模块加入内核编译。
6. 在物理内存管理初始化完成、相关物理页已经可以通过内核地址访问之后，执行 `slub_init()`。
7. 不得替换或修改现有 `pmm_manager` 的接口。SLUB 必须作为现有 PMM 的上层模块运行。
8. 不得修改已有 First-Fit、Best-Fit、Buddy System 的算法逻辑。
9. 允许增加必要的静态辅助函数、管理结构、宏定义和初始化代码。
10. 优先保证正确性，暂不考虑多处理器、NUMA、复杂并发优化和实际 Linux SLUB 的高级功能。

**输出要求**：

直接完成文件创建和修改。

- 保留工程中已有的公共接口和无关代码。
- 只修改 SLUB 实现、必要的初始化接入和构建配置。
- 完成后列出创建和修改的文件。
- 尝试编译并启动内核，检查 SLUB 初始化是否正常。
- 简要说明大小类别、Slab 元数据、对象分配、释放及空闲 Slab 回收方式。
- 不得声称尚未实际运行的测试已经通过。

# [RELY]

## 1. 现有 ucore 物理内存管理框架

ucore 已提供基于物理页的内存分配接口：

```c
struct Page *alloc_pages(size_t n);

void free_pages(struct Page *base, size_t n);

size_t nr_free_pages(void);
```

以及单页操作接口：

```c
struct Page *alloc_page(void);

void free_page(struct Page *page);
```

其中：

- `alloc_pages(n)` 申请连续的 n 个物理页。
- `free_pages(base, n)` 释放对应物理页。
- `nr_free_pages()` 返回当前空闲物理页数量。
- `struct Page` 描述一个物理页。

必须以工程实际定义为准，不能自行修改这些公共接口。

## 2. 内核地址转换

物理页分配器返回的是 `struct Page *`，不是可以直接当作对象内存使用的字节指针。

必须阅读工程中：

```c
page2pa()
KADDR()
PADDR()
page2kva()
```

等实际存在的接口，确认如何从 `struct Page *` 获取内核可访问地址。

以上接口并不保证在所有 ucore 版本中同时存在，必须根据实际头文件选择。

特别要求：

- 不得直接将 `struct Page *` 强制转换为对象存储地址。
- 不得将物理地址不经映射直接当成虚拟地址访问。
- 不得在页映射尚不可用时访问 Slab 中的内存。
- 分配和释放过程中使用的地址转换必须保持一致。

## 3. SLUB 分配模型

推荐实现按大小分类的对象缓存。

例如：

```text
Cache 0：  16 B
Cache 1：  32 B
Cache 2：  64 B
Cache 3： 128 B
Cache 4： 256 B
Cache 5： 512 B
Cache 6：1024 B
Cache 7：2048 B
```

具体大小类别可根据工程页大小及对象对齐需求调整。

例如：

```text
slub_alloc(20)  → 32 B 对象槽位
slub_alloc(60)  → 64 B 对象槽位
slub_alloc(100) → 128 B 对象槽位
```

同一个 Cache 可以包含多个 Slab，每个 Slab 对应底层 PMM 分配的一个物理页。

同一 Slab 中的对象槽位大小相同。

推荐为每个 Cache 维护：

- 至少有一个空闲对象的 Slab。
- 所有对象已经分配完毕的 Slab。

可以额外区分完全空闲的 Slab，也可以在变成完全空闲时立即将其归还 PMM。

不得为每个小对象独立申请一个物理页。

## 4. Slab 内存布局

推荐每个小对象 Slab 占用一个 4 KB 物理页。

可采用以下布局：

```text
┌────────────────────────────┐
│ Slab 管理信息              │
├────────────────────────────┤
│ 对齐填充                   │
├────────────────────────────┤
│ Object 0                   │
├────────────────────────────┤
│ Object 1                   │
├────────────────────────────┤
│ Object 2                   │
├────────────────────────────┤
│ ...                        │
├────────────────────────────┤
│ Object N                   │
└────────────────────────────┘
```

其中：

- Slab 管理信息记录所属 Cache、空闲对象、对象数量等。
- Object 区域保存实际分配给调用者的内存。
- 内部元数据不得与对象可写区域重叠。
- 对象起始地址必须满足规定的字节对齐要求。

可以将 Slab 元数据放在页首，也可以使用其他可靠方案。

为避免循环依赖，SLUB 自身的关键元数据不能依赖尚未初始化的 `slub_alloc()` 分配。

# [GUARANTEE]

必须创建或实现以下主要接口：

```c
void slub_init(void);

void *slub_alloc(size_t size);

void slub_free(void *ptr);

size_t slub_usable_size(const void *ptr);

void slub_check(void);
```

其中：

- `slub_init()`：初始化对象分配器。
- `slub_alloc()`：分配指定字节大小的对象。
- `slub_free()`：释放对象。
- `slub_usable_size()`：返回当前分配对象可安全使用的字节数。
- `slub_check()`：分配器检查入口，供第二阶段测试使用。

如果现有工程没有同名或等价接口，可根据需要进一步提供：

```c
void *kmalloc(size_t size);

void kfree(void *ptr);
```

其实现可直接调用 SLUB 接口。

如果已有同名符号，禁止重复定义，应保留独立的 `slub_alloc()` 和 `slub_free()`，必要时采用工程原有的接口接入机制。

建议设计内部结构：

```c
struct slub_cache;

struct slub_slab;
```

结构体应至少能够表示：

**slub_cache：**

- 对象槽位大小。
- Slab 链表。
- 必要的统计信息。

**slub_slab：**

- 所属 Cache。
- 对应物理页。
- 对象总数。
- 已分配对象数量。
- 空闲对象链表或位图。
- Slab 链表节点。

可根据需要添加：

```c
static struct slub_slab *
slub_new_slab(struct slub_cache *cache);

static void *
slub_alloc_from_slab(struct slub_slab *slab);

static void
slub_release_slab(struct slub_slab *slab);

static size_t
slub_select_size_class(size_t size);
```

还可添加对象归属识别、空闲链表管理、对齐计算、大对象分配和释放等辅助函数。

# [SPECIFICATION]

## 1. slub_init()

**功能**：初始化 SLUB 模块。

要求：

1. 初始化全部大小类别的 Cache。
2. 设置每个 Cache 的对象槽位大小。
3. 初始化各 Cache 的 Slab 链表。
4. 将相关计数器清零。
5. 初始化状态必须与现有 PMM 的初始化顺序兼容。
6. 不得在底层物理页分配器尚未准备完成时申请内存。

**Case 1：首次初始化**

全部 Cache 和链表均处于合法初始状态。

**Case 2：内核随后进行对象分配**

可以正确找到对应 Cache，必要时创建新 Slab。

**Case 3：初始化顺序**

必须选择安全的内核初始化位置，不得破坏已有分页和物理页管理过程。

## 2. slub_select_size_class(size_t size)

**功能**：根据请求大小选择合适的对象缓存。

例如：

| 请求大小 | 分配槽位大小 |
|---|---|
| 1 B | 16 B |
| 16 B | 16 B |
| 17 B | 32 B |
| 24 B | 32 B |
| 64 B | 64 B |
| 100 B | 128 B |
| 300 B | 512 B |
| 1000 B | 1024 B |
| 1800 B | 2048 B |

要求：

1. 选择能够容纳请求的最小大小类别。
2. 不得返回容量小于请求大小的对象。
3. 对象大小必须满足内存对齐要求。
4. 推荐保证对象起始地址至少 16 字节对齐；如果实际平台或类型要求更严格，应按工程规定调整。
5. 不允许因大小取整发生整数溢出。
6. 超出单页 Slab 对象容量的请求必须进入大对象分配路径。

## 3. slub_new_slab()

**功能**：为指定 Cache 创建新的 Slab。

要求：

1. 调用底层 `alloc_page()` 取得一个物理页。
2. 获取该物理页对应的内核可访问地址。
3. 在该页中建立 Slab 管理信息及对象区域。
4. 计算对象槽位数量。
5. 初始化空闲对象链表或位图。
6. 将 Slab 加入对应 Cache 的可分配 Slab 链表。
7. 确保页面能够容纳至少一个该 Cache 的对象。
8. 如果物理页分配失败，返回失败状态，不得访问空指针。

若页大小为 `PGSIZE`，管理信息和对齐开销合计占 `H` 字节，对象槽位大小为 `S`，则：

\[
N=\left\lfloor\frac{PGSIZE-H}{S}\right\rfloor
\]

其中 `H` 必须包含全部真实元数据及对齐开销。

**Case 1：创建 16 B Cache 的 Slab**

一页中应包含多个 16 B 对象槽位。

**Case 2：创建较大对象的 Slab**

应正确计算有限的对象槽位数量。

**Case 3：底层 PMM 分配失败**

返回失败，原有 Cache 和链表状态不得被破坏。

## 4. slub_alloc(size_t size)

**功能**：申请至少 `size` 字节的可访问内核内存。

### 4.1 基本规则

- `size == 0`：约定返回 `NULL`。
- `size > 0`：尝试分配至少 `size` 字节。
- 成功返回符合对齐要求的指针。
- 内存不足返回 `NULL`。
- 不要求默认将对象内容清零。
- 不允许覆盖其他对象或分配器元数据。

### 4.2 小对象分配

**Case 1：指定大小类别存在可用 Slab**

从其中一个 Slab 的空闲对象集合取出对象，更新相关状态并返回指针。

**Case 2：指定大小类别没有可用 Slab**

调用 `slub_new_slab()`，从新创建的 Slab 中分配对象。

**Case 3：某个 Slab 的所有对象均被分配**

将其状态更新为 Full，后续分配应选择其他可用 Slab，不能重复返回已经分配的槽位。

**Case 4：一次申请多个相同大小对象**

允许多个对象共享同一物理页，只要各自的对象区域不重叠。

例如连续申请 8 个 16 B 对象，初始情况下应能够由一个 4 KB 物理页提供，不需要分别申请 8 个物理页。

**Case 5：某类对象超过一页的容纳量**

应创建额外 Slab，而不能越过原 Slab 页边界继续写入。

### 4.3 大对象分配

当请求超过单页 Slab 能够容纳的最大对象时，允许直接通过底层 PMM 申请连续多个物理页。

必须设计可靠的元数据记录方案，以支持后续 `slub_free()`。

例如请求 5000 B：

1. 计算对象存储及管理信息需要的实际字节数。
2. 向上取整为所需物理页数。
3. 调用 `alloc_pages(n)`。
4. 记录对应的首页、实际申请页数或底层释放所需的信息。
5. 返回不与元数据重叠、至少可访问 5000 B 的指针。

不得直接假设分配 2 页一定能够在扣除元数据后容纳任意 8192 B 请求。

必须验证所申请页面在当前内核地址空间中具有可连续访问的映射。

如果底层 PMM 自身采用 Buddy System 等需要特殊释放记账的算法，应遵守其实际 `alloc_pages/free_pages` 契约。

### 4.4 大小溢出

当 `size + metadata_size` 或页数向上取整可能发生溢出时，应直接返回 `NULL`，不得形成越界申请。

## 5. slub_free(void *ptr)

**功能**：释放先前由 SLUB 成功分配的对象。

### 5.1 基本要求

1. `ptr == NULL` 时直接返回。
2. 根据实际实现的元数据确定对象所属的 Slab 或大对象分配记录。
3. 不要求调用者另外传入原始申请大小。
4. 不得错误释放其他对象。
5. 不得将 SLUB 对象地址直接作为 `struct Page *` 传给 PMM。

### 5.2 小对象释放

**Case 1：对象所在 Slab 仍有其他已分配对象**

只将该对象槽位标记为空闲，不释放底层物理页。

**Case 2：原先已满的 Slab 释放一个对象**

应重新成为可用 Slab，后续申请能够利用这个空闲槽位。

**Case 3：释放对象后 Slab 完全空闲**

应将 Slab 从 Cache 链表中移除，清理必要的元数据，并调用底层 `free_page()` 归还整页。

本实验采用立即归还完全空闲 Slab 的简化策略，以保证测试结束后物理内存能够恢复。

**Case 4：对象跨多个 Slab 分配**

释放过程应正确识别各自所属的 Slab，不得发生链表混乱。

### 5.3 大对象释放

对于通过多页分配路径取得的对象：

1. 正确识别大对象分配记录。
2. 找到对应的 `struct Page *base`。
3. 获取底层释放所需的页数。
4. 调用对应的 `free_pages()`。
5. 不得将大对象错误地加入小对象 Cache。

接口只要求对 SLUB 返回的合法指针进行释放，不要求安全处理任意伪造地址；测试中不得使用非法释放制造无意义的内核崩溃。

## 6. slub_usable_size(const void *ptr)

**功能**：返回一个有效 SLUB 分配对象的可使用容量。

要求：

- `ptr == NULL`：返回 0。
- 小对象：返回所属大小类别的槽位大小。
- 大对象：返回实际保证给调用者使用的容量，可以采用请求大小或真实可用空间，但必须与分配时的元数据一致。
- 不得将 Slab 管理信息占用的空间算入对象可用容量。

## 7. 对象管理与状态一致性

对于每个 Slab，应维持以下关系：

```text
对象总数 = 已分配对象数 + 空闲对象数
```

并保证：

- Full Slab 没有可分配对象。
- Partial Slab 同时包含已分配和空闲对象。
- Empty Slab 没有已分配对象。
- 同一个对象槽位不能同时处于已分配与空闲状态。
- 同一物理页不能同时作为多个独立 Slab 使用。
- 两个已分配对象的有效存储区不能重叠。

允许使用单链表、位图或其他简单方式管理空闲对象。

若使用对象本身存储空闲链表指针，必须保证对象槽位大小至少能够容纳该指针，且仅在对象处于空闲状态时使用其存储区作为链表元数据。

## 8. 与内核集成

要求：

1. 在 SLUB 所需的 PMM 和地址映射初始化完成后调用 `slub_init()`。
2. 确保 `slub.c` 被编译并链接进内核。
3. 保证 `slub_alloc()`、`slub_free()` 能被其他内核模块调用。
4. 保留 `pmm_manager` 的原有注册和选择逻辑。
5. 不得造成 `kmalloc`、`kfree` 等同名符号冲突。
6. 暂不强制替换现有其他内核模块的内存分配方式，避免扩大修改范围。
7. 为后续测试保留 `slub_check()` 入口。

## 9. slub_check()

本阶段只要求提供可调用的检查入口，并实现基本初始化检查。

完整的测试函数由第二份 Prompt 负责。

不得为了避免测试失败而隐藏初始化错误，或者输出虚假的测试成功信息。

## 10. 设计说明

除代码外，在工程合适的位置新增简要设计文档 `slub_design.md`。

说明：

- 两层内存分配架构。
- Cache 和 Slab 的数据结构。
- 大小类别选择策略。
- Slab 内存布局。
- 小对象分配和释放流程。
- 大对象处理方式。
- 空闲对象复用和空闲 Slab 回收机制。
- 与底层 PMM 的关系。
- 已简化或未实现的 Linux SLUB 特性。

## 11. 最终检查

必须确认：

- [ ] 已创建 SLUB 模块和头文件。
- [ ] 主要接口完整实现。
- [ ] 能够按字节大小申请对象。
- [ ] 多个小对象能够共享一个物理页。
- [ ] 对象槽位满足对齐要求。
- [ ] 已满 Slab 不会重复分配同一对象。
- [ ] 释放对象后槽位能够重新使用。
- [ ] 完全空闲的 Slab 能归还物理页。
- [ ] 大对象能够通过底层 PMM 分配和释放。
- [ ] 处理了地址转换及大小计算溢出。
- [ ] 没有破坏原有 PMM 接口。
- [ ] SLUB 初始化已接入内核。
- [ ] 新模块能够参与编译。
- [ ] 已尝试实际编译和运行。
- [ ] 已生成设计说明。

**最终目标：实现基于现有 PMM 的简化 SLUB 对象分配器，使内核不仅可以按页分配内存，还能按任意字节大小分配和释放内存对象。**
````

## 七、SLUB 测试提示词

原始文件：[writing-block-2-2.md](writing-block-2-2.md)。

````markdown
# [PROMPT]

**任务**：针对第一阶段生成的 `kern/mm/slub.c` 和 `kern/mm/slub.h`，设计并实现一套完整的 **SLUB 内存对象分配器测试函数**，验证不同大小内存对象的分配、访问、复用、释放及物理页回收是否正确。

主要目标文件：

- `kern/mm/slub.c`：添加测试函数及必要的测试辅助代码。
- `kern/mm/slub.h`：仅在需要增加测试入口声明时修改。
- `slub_design.md`：补充测试方案及结果说明。

**操作要求**：

1. 必须直接修改实际工程文件，不能只输出测试代码。
2. 首先阅读第一阶段生成的 SLUB 实现，确认其大小类别、Slab 布局、空闲对象组织、元数据位置和大对象分配方式。
3. 阅读现有 PMM 的接口定义和初始化流程，确认测试期间能够安全调用 `alloc_pages()`、`free_pages()` 和 `nr_free_pages()`。
4. 在 `slub.c` 中添加测试函数，并通过 `slub_check()` 统一调用。
5. 测试必须包含成功分配、数据读写、对象复用、跨 Slab 分配、全部释放和边界条件。
6. 不得修改已有 SLUB 核心算法以适应错误测试，更不得删除断言或硬编码测试结果。
7. 测试所需内存必须通过合法分配接口取得，不能直接使用未知状态的物理页。
8. 不得访问对象有效容量以外的地址。
9. 所有测试对象应在测试结束前正确释放。
10. 测试完成后，SLUB 的对象状态和底层 PMM 的空闲页数量应恢复到预期状态。

**输出要求**：

直接在工程中编写测试代码。

- 必须有具体测试函数，而不是仅输出测试思路。
- 每个测试函数应包含明确的 `assert()` 断言。
- 将测试函数组织进 `slub_check()`。
- 实际运行时应能够定位失败的测试场景。
- 尝试编译运行并报告真实结果。
- 如果发现分配器本身存在错误，应指出错误位置和原因，不得通过放宽测试条件掩盖问题。

# [RELY]

## 1. 已实现的 SLUB 模块

第一阶段已经提供：

```c
void slub_init(void);

void *slub_alloc(size_t size);

void slub_free(void *ptr);

size_t slub_usable_size(const void *ptr);
```

以及：

```c
void slub_check(void);
```

测试应调用这些真实接口。

必须阅读实际代码，不得假设所有内部结构均与推荐方案完全相同。

## 2. 底层物理页分配

现有 PMM 提供：

```c
struct Page *alloc_pages(size_t n);

void free_pages(struct Page *base, size_t n);

size_t nr_free_pages(void);
```

SLUB 测试必须验证对象层与 PMM 层的关系。

例如：

- 一个 Slab 可以容纳多个小对象。
- Slab 用完后才需要额外申请底层物理页。
- 释放单个对象通常不直接释放整页。
- 整个 Slab 变为空闲时，应按第一阶段的策略归还页面。

## 3. SLUB 大小类别

依据第一阶段实际使用的大小类别进行测试。

如果采用：

```text
16 / 32 / 64 / 128 / 256 / 512 / 1024 / 2048
```

则应覆盖大小类别边界，以及跨越相邻大小类别的请求。

例如：

```text
15 B、16 B、17 B
31 B、32 B、33 B
63 B、64 B、65 B
127 B、128 B、129 B
```

并包含超过单页 Slab 容量的大对象请求。

## 4. 测试约束

测试应在 SLUB 初始化完成后运行。

如果测试需要检查底层空闲页数量，应在没有其他内核任务同时进行内存分配的受控阶段执行。

不得把 SLUB 自身的元数据占用误判为内存泄漏。

第一阶段规定完全空闲的 Slab 立即归还底层 PMM，因此在全部测试分配对象释放后，底层空闲页数量应当恢复。

大对象的实际占用页数应包括必要的元数据开销，不能未经检查就假设：

```c
actual_pages = ceil(request_size / PGSIZE);
```

# [GUARANTEE]

必须实现或完善统一测试入口：

```c
void slub_check(void);
```

建议增加以下测试函数：

```c
static void slub_check_basic(void);

static void slub_check_size_classes(void);

static void slub_check_alignment(void);

static void slub_check_data_integrity(void);

static void slub_check_reuse(void);

static void slub_check_multi_slab(void);

static void slub_check_large_alloc(void);

static void slub_check_page_reclaim(void);

static void slub_check_boundary(void);

static void slub_check_stress(void);

static void slub_check_invariants(void);
```

可根据实际代码组织适当调整函数名称。

允许添加：

- 保存测试对象指针的静态数组。
- 对象大小记录数组。
- 对象数据填充与校验函数。
- 内部一致性检查辅助函数。
- Slab 状态检查辅助函数。
- 可重复执行的固定测试序列。

禁止修改：

- `slub_alloc()` 和 `slub_free()` 的对外接口。
- PMM 公共接口。
- First-Fit、Best-Fit、Buddy System 的实现。
- 与测试无关的内核模块。

# [SPECIFICATION]

## 1. slub_check_basic()

**功能**：验证基本对象分配和释放。

**Case 1：申请 16 B**

```c
void *p = slub_alloc(16);
assert(p != NULL);
```

检查指针有效，随后释放。

**Case 2：申请 100 B**

检查：

- 分配成功。
- 可用大小不小于 100 B。
- 能够正常访问申请的对象空间。

**Case 3：连续申请多个对象**

例如：

```c
void *p1 = slub_alloc(16);
void *p2 = slub_alloc(32);
void *p3 = slub_alloc(64);
```

检查：

- 所有成功分配的对象指针均非空。
- 三个对象地址不同。
- 各自的可访问内存区域不重叠。

**Case 4：释放对象**

释放上述对象，保证 SLUB 状态正确。

**Case 5：重复分配与释放**

多轮执行相同大小对象的合法申请和释放，确认分配器能够持续工作。

## 2. slub_check_size_classes()

**功能**：检查大小类别的选择是否正确。

采用与第一阶段实际实现一致的 Cache 大小。

至少测试：

```text
1 B
8 B
15 B
16 B
17 B
24 B
31 B
32 B
33 B
64 B
65 B
100 B
127 B
128 B
129 B
255 B
256 B
257 B
511 B
512 B
513 B
1023 B
1024 B
1025 B
2048 B
2049 B
```

对每次成功分配检查：

1. 返回指针非空。
2. 可用大小不小于请求大小。
3. 返回的槽位容量符合第一阶段定义的大小类别。
4. 不同对象间不存在存储空间重叠。
5. 对象释放后能够恢复相关资源。

对于超过小对象容量的请求，应验证其正确进入大对象分配路径，而不是强制使用空间不足的 Slab。

## 3. slub_check_alignment()

**功能**：验证分配对象的内存对齐。

测试不同对象大小：

```text
1 B、7 B、16 B、24 B、64 B、100 B、512 B、2048 B
```

若第一阶段规定最小对齐为 16 字节，则检查：

```c
assert(((uintptr_t)p & 15UL) == 0);
```

如果实际实现依据平台采用其他合法对齐方式，应以第一阶段明确的对齐契约为准。

还应验证：

- 同一 Slab 中所有对象均正确对齐。
- 跨 Slab 的对象仍然正确对齐。
- 大对象分配返回值满足规定的对齐要求。

## 4. slub_check_data_integrity()

**功能**：验证不同分配对象的存储互不干扰。

例如，连续分配三个不同大小的对象：

```c
unsigned char *a = slub_alloc(32);
unsigned char *b = slub_alloc(64);
unsigned char *c = slub_alloc(128);
```

如果全部成功，则：

1. 向 `a` 的 32 B 区域写入固定模式。
2. 向 `b` 的 64 B 区域写入另一模式。
3. 向 `c` 的 128 B 区域写入第三种模式。
4. 读取并检查三个对象的内容。

可使用如下数据模式：

```text
对象 A：0xAA
对象 B：0x55
对象 C：0xCC
```

检查：

- 三个对象中的数据保持正确。
- 向其中一个对象写入不会改变其他对象。
- 释放对象 B 后，对象 A 和 C 的数据仍然正确。
- 再次分配对象时，仍然不会破坏其他活动对象。

不得读取已经释放的对象，也不得要求新分配对象保留旧对象的数据。

## 5. slub_check_reuse()

**功能**：验证同一 Slab 中释放的对象槽位能够重新使用。

建议过程：

1. 连续申请多个相同大小的对象。
2. 确认这些对象属于同一个 Slab。
3. 释放其中一个对象。
4. 再次申请相同大小的对象。
5. 验证分配器能够使用已有的空闲槽位。

例如：

```text
Slab：

[A][B][C][D][空闲] ...

释放 B：

[A][空闲][C][D][空闲] ...

再次分配：

[A][E][C][D][空闲] ...
```

检查：

- 不需要为本次复用额外申请物理页。
- 新对象与其他活动对象不重叠。
- 新对象具有合法的可写空间。
- 其余对象数据没有被破坏。

如果第一阶段采用 LIFO 空闲链表，可以进一步检查新对象复用了刚刚释放的位置。

若实现允许不同的合法复用顺序，不应无依据地强制某个特定返回地址。

## 6. slub_check_multi_slab()

**功能**：验证一个 Cache 能够管理多个 Slab。

测试步骤：

1. 选择一个小对象大小，例如 32 B。
2. 根据实际单页 Slab 布局计算一页可以容纳的对象数量 `N`。
3. 连续分配 `N + 1` 个对象。
4. 检查分配器至少使用了两个 Slab。
5. 检查所有对象的存储区域互不重叠。
6. 释放部分对象。
7. 再次分配，验证能够使用已有 Slab 的空闲槽位。
8. 释放全部对象。

需要覆盖：

**Case 1：单个 Slab 未满。**

**Case 2：单个 Slab 恰好满。**

**Case 3：超过单个 Slab 的容量。**

**Case 4：Full Slab 释放一个对象后转为可用状态。**

**Case 5：多个 Slab 全部释放后正确回收。**

不允许直接假设一页可以容纳 `PGSIZE / object_size` 个对象，因为还需要扣除 Slab 管理信息和对齐开销。

## 7. slub_check_large_alloc()

**功能**：验证超过单页 Slab 容量的大对象分配。

根据第一阶段实际阈值选择测试值。

建议测试：

```text
2049 B
3000 B
4096 B
4097 B
5000 B
8192 B
```

对于每次成功分配：

1. 返回指针非空。
2. 可访问容量不小于请求大小。
3. 对象区域满足对齐要求。
4. 可以向整个请求范围写入数据。
5. 读取数据时内容保持正确。
6. 大对象与其他活动对象不存在重叠。
7. 释放后底层物理页得到正确归还。

尤其需要检查跨页访问：

例如，申请 5000 B 后，向对象第 0、4095、4096 和 4999 字节写入不同值，确认都能正确读取。

这些下标均在本次申请的有效范围内。

不得在返回指针之外额外访问元数据空间。

如果当前可用物理内存不足以满足某个大对象请求，应明确报告该测试因资源不足无法执行，而不是无条件判定分配器错误。

## 8. slub_check_page_reclaim()

**功能**：验证对象层释放能够正确恢复底层 PMM 的物理页。

测试前记录：

```c
size_t before = nr_free_pages();
```

### Case 1：多个小对象共享一页

连续分配 8 个 16 B 对象。

在初始化状态清晰且对应 Cache 尚无活动 Slab 时，检查这 8 次小对象分配可以使用同一页，不应消耗 8 个物理页。

### Case 2：只释放一个对象

对于同一 Slab 中仍有其他活动对象的情况，释放一个对象不应归还整张物理页。

### Case 3：释放全部对象

释放所有对象后，完全空闲的 Slab 应被回收。

检查：

```c
assert(nr_free_pages() == before);
```

上述断言必须在没有其他分配活动、且测试创建的 Slab 已按第一阶段策略完全回收的前提下执行。

### Case 4：多个 Slab 回收

创建两个以上 Slab，并依次释放所有对象，检查底层物理页全部归还。

### Case 5：大对象回收

分配跨页对象，再释放，检查相关物理页恢复。

不得通过手动修正 PMM 空闲页计数器使断言通过。

## 9. slub_check_boundary()

**功能**：检查边界条件和分配失败行为。

**Case 1：零字节申请**

根据第一阶段约定：

```c
assert(slub_alloc(0) == NULL);
```

**Case 2：释放空指针**

```c
slub_free(NULL);
```

应安全返回，不得造成异常。

**Case 3：请求大小恰好等于 Cache 容量**

应使用对应类别，不需要进入下一类别。

**Case 4：请求大小比 Cache 容量大 1 B**

应选择更大的类别或进入大对象分配路径。

**Case 5：内存不足**

在受控内存范围内测试分配失败返回行为。

不得无限申请直至耗尽整个内核物理内存，使内核无法继续运行。

**Case 6：大小计算溢出**

检查极大请求是否能够在执行非法页数计算之前被拒绝。

**Case 7：初始化前操作**

应在不破坏系统的前提下，根据模块约定检查或静态确认不会在初始化前错误访问未初始化的链表。

不得故意执行会导致内核崩溃的非法调用来完成此类测试。

测试不要求支持重复释放、释放对象内部地址等未定义操作。

## 10. slub_check_stress()

**功能**：验证多种大小对象交错分配和释放的正确性。

设计确定性的测试序列，例如：

```text
申请 16 B
申请 32 B
申请 100 B
申请 64 B
申请 5000 B
释放 32 B
申请 24 B
释放 100 B
申请 128 B
释放 16 B
释放 5000 B
释放 64 B
释放 24 B
释放 128 B
```

要求：

1. 使用数组记录各个活动对象的指针、请求大小和数据模式。
2. 分配成功后写入测试数据。
3. 在交错分配和释放后，重新检查所有仍然活动的对象。
4. 验证已分配对象之间没有重叠。
5. 对不同大小类别分别检查内部状态。
6. 测试结束时释放全部活动对象。
7. 验证内存没有泄漏。

还可以使用固定种子的伪随机测试序列，但必须保证结果可重复。

测试规模应根据当前空闲物理页数量设置上限，避免把内核正常运行所需的内存全部占用。

## 11. slub_check_invariants()

**功能**：检查 SLUB 内部元数据和链表状态的一致性。

遍历第一阶段实现中的全部 Cache 和 Slab，检查：

1. 每个 Slab 只属于一个 Cache。
2. 每个 Slab 的对象槽位大小与 Cache 一致。
3. 每个对象地址满足对齐要求。
4. 每个 Slab 的对象区域位于合法物理页对应的内核映射范围内。
5. 对象区域不与 Slab 元数据重叠。
6. 已分配对象和空闲对象互不重叠。
7. 空闲对象链表没有重复节点或异常循环。
8. Slab 的对象总数等于已使用数量与空闲数量之和。
9. Full Slab 没有空闲槽位。
10. Partial Slab 同时存在已使用和空闲槽位。
11. 被回收的 Slab 不再出现在任何活动 Cache 链表中。
12. 大对象元数据记录的底层页数与释放方式一致。

对于仍处于活动状态的 Slab，应满足：

\[
0\le inuse\le total
\]

以及：

\[
free=total-inuse
\]

若第一阶段采用不同的内部字段名，应根据真实代码读取对应信息，不能硬编码不存在的字段。

## 12. slub_check()

**功能**：统一执行 SLUB 测试。

推荐组织如下：

```c
void slub_check(void) {
    slub_check_invariants();
    slub_check_basic();
    slub_check_size_classes();
    slub_check_alignment();
    slub_check_data_integrity();
    slub_check_reuse();
    slub_check_multi_slab();
    slub_check_large_alloc();
    slub_check_page_reclaim();
    slub_check_boundary();
    slub_check_stress();
    slub_check_invariants();
}
```

可以根据各测试对初始状态的要求调整执行顺序。

必须保证：

- 测试只在 SLUB 已经初始化后运行。
- 所有测试函数真正执行，而非空实现。
- 每个函数有有效断言。
- 测试之间不会遗留活动对象。
- 测试后能够继续正常进行对象分配。

必要时可以增加测试日志，以便区分不同 Case。

## 13. 内存安全与测试状态恢复

测试中必须遵守以下要求：

1. 只访问成功申请的对象内存。
2. 写入长度不得超过该对象允许访问的范围。
3. 不得访问已经释放的对象。
4. 不得重复释放同一指针。
5. 不得直接修改 PMM 的内部空闲页计数。
6. 不得直接将已经属于其他 Slab 的物理页重新登记。
7. 不得通过重新初始化整个 PMM 恢复测试状态。
8. 测试所用的对象必须全部合法释放。
9. 若测试失败，应保留断言并分析具体原因。
10. 正常完成后，应验证 SLUB 和底层 PMM 均可继续正常运行。

## 14. 编译与运行

完成测试实现后：

1. 检查所有新增函数的定义、声明和调用关系。
2. 确认测试函数没有依赖用户态标准库。
3. 使用内核已有的 `assert()` 和日志输出接口。
4. 运行项目实际支持的编译命令。
5. 启动 QEMU 或工程对应运行环境。
6. 确保 `slub_check()` 在正确的初始化阶段被实际执行。
7. 检查测试是否全部通过。
8. 对测试失败给出具体 Case、断言位置和错误原因。
9. 不得通过屏蔽断言、跳过失败用例或修改 PMM 计数来获得虚假成功结果。
10. 确认测试结束后内核能够继续运行。

## 15. 测试设计说明

在 `slub_design.md` 中补充测试章节，包括：

- 测试环境。
- 各测试函数的目标。
- 测试数据和大小类别。
- 测试前置条件。
- 预期结果。
- 实际运行结果。
- 发现的问题及修复情况。
- 尚未覆盖的高级 SLUB 特性。

## 16. 最终检查

必须确认：

- [ ] 已实现 SLUB 统一测试入口。
- [ ] 测试函数全部接入。
- [ ] 基本对象分配和释放正确。
- [ ] 不同大小类别的测试完整。
- [ ] 对象地址对齐正确。
- [ ] 不同对象间无内存覆盖。
- [ ] 释放对象后槽位可以复用。
- [ ] 一个 Slab 能管理多个对象。
- [ ] 一个 Cache 能管理多个 Slab。
- [ ] 跨页大对象能够正确分配和释放。
- [ ] Slab 完全空闲后能够归还物理页。
- [ ] 边界输入得到正确处理。
- [ ] 交错分配和释放不会破坏数据。
- [ ] 内部对象计数和链表状态一致。
- [ ] 所有测试分配均已清理。
- [ ] 测试结束后底层 PMM 状态正确。
- [ ] 测试代码能够编译。
- [ ] 已尝试运行并记录真实结果。
- [ ] 已补充测试设计说明。

**最终目标：为第一阶段实现的 SLUB 分配器建立覆盖对象大小、对象复用、Slab 管理、大对象分配、物理页回收和数据完整性的完整测试体系，验证其能够作为 ucore 内核的第二层内存分配器正常工作。**
````

## 八、GDB 题目一的操作指导与答疑提示

以下是本次实操对话中实际提出的主要要求和问题，具体命令及原始输出完整保存在 [gdb_test_1.md](gdb_test_1.md)。

> 根据这个调试过程说明帮我总结一下这个实验应该怎么调试，调试哪些部分

> 终端二和终端三是什么关系，我没理解

> 你光说我听不懂，来实操一下，你一步一步告诉我第一题应该怎么做

> 你从操作终端二开始，操作终端三前需要先操作终端二吗

> 我有问题，gdb2和gdb到底哪个控制程序进行？两个都执行continue，到底哪个控制程序进行？程序不会一直循环进行吗

> 刚才一直没有执行终端3，为什么终端二可以一直读取数据，这个时候数据已经被装载完毕了吗

> 为什么这里用next不用si

> 先结束，然后把我们刚才关于题目一对话的内容和流程保存在report中，命名为gdb_test_1

## 九、报告整理提示

> 请阅读完lab2指导书的内容，然后按照实验报告要求补全report中的实验报告

本条对原请求进行了链接文字的整理；具体依据为报告中列出的课程页面。没有将本文件的事后汇总当作最初的一条生成提示词，也没有补造未记录的对话。
