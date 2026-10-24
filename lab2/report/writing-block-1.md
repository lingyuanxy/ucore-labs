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