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