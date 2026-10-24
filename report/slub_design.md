# 简化 SLUB 对象分配器设计与测试

更新日期：2026-10-24。

## 1. 目标与修改范围

本模块在现有 PMM 之上提供按字节分配的内核对象接口，完成 Lab2 的 SLUB 扩展任务。实现与测试分别依据 `writing-block-2-1.md`、`writing-block-2-2.md`。

新增文件：

- `../code/kern/mm/slub.c`：对象分配器、元数据检查与专项测试。
- `../code/kern/mm/slub.h`：公开接口。
- 本设计文档。

修改 `../code/kern/init/init.c`：在 `pmm_init()` 返回后依次调用 `slub_init()`、`slub_check()`。现有构建规则自动收集 `kern/mm` 中的 C 文件，无需修改 Makefile。未修改 First-Fit、Best-Fit、Buddy、PMM 公共接口或项目启动汇编，也未改变当前 Buddy 管理器的选择。

## 2. 两层架构与接口

```text
调用者
  ├─ slub_alloc(size) / slub_free(ptr)
  └─ slub_usable_size(ptr)
          ↓
SLUB 对象层：大小类别、对象槽位、Partial / Full Slab
          ↓
PMM 页层：alloc_pages(n) / free_pages(base, n)
          ↓
物理页以及现有内核直接映射
```

公开接口如下：

```c
void slub_init(void);
void *slub_alloc(size_t size);
void slub_free(void *ptr);
size_t slub_usable_size(const void *ptr);
void slub_check(void);
```

约定：

- 成功分配至少满足请求大小，并保证 16 字节对齐。
- 零字节申请返回 `NULL`，`slub_free(NULL)` 安全返回。
- 初始化前申请返回 `NULL`；`slub_usable_size(NULL)` 返回 0。
- 初始化后再次调用 `slub_init()` 为无操作，不会清除已有对象。
- 不保证新对象内容为零。
- 只对本模块返回且尚未释放的完整对象指针提供释放和容量查询；任意地址、对象内部地址及重复释放不属于受支持接口。

## 3. Cache、Slab 与内存布局

静态创建 8 个 Cache，大小类别为 16、32、64、128、256、512、1024、2048 字节。选择第一个不小于请求大小的类别。每个 Cache 保存对象大小、Partial 链表、Full 链表、Slab 数量和活动对象数量。

每个小对象 Slab 占一个物理页，页首 `struct slub_slab` 保存：

- 标识和类型，所属 Cache，对应 `struct Page *`。
- Cache 或大对象链表节点。
- 底层申请页数、大对象请求大小。
- 槽位总数、活动对象数、空闲槽位链表头。
- 槽位分配位图，用于识别活动对象并检查状态一致性。

关键元数据不依赖 `slub_alloc()` 本身分配，避免循环依赖。

```text
一个小对象 Slab 页
[Slab 头部][16 字节对齐填充][槽位 0][槽位 1] ... [未使用尾部]
```

定义：

```text
H = align_up(sizeof(struct slub_slab), 16)
N = floor((PGSIZE - H) / object_size)
```

本次 RV64 布局中，结构体大小为 120 字节，`H = 128`。因此各类别的单页槽位数量为：

| 槽位大小（字节） | 单页对象数量 |
| --- | --- |
| 16 | 248 |
| 32 | 124 |
| 64 | 62 |
| 128 | 31 |
| 256 | 15 |
| 512 | 7 |
| 1024 | 3 |
| 2048 | 1 |

代码按实际 `sizeof` 计算，不硬编码上述数量。位图支持最多 256 个槽位，覆盖最小类别的容量。

空闲槽位的前几个字节用作下一空闲槽位的指针，只在槽位空闲时使用。分配后整个槽位归调用者使用，活动对象的存储不会被拿来保存空闲链表信息。

## 4. 地址转换与对象归属

`alloc_pages()` 返回描述符指针，不能将其直接强制转换为对象存储地址。实际访问地址通过以下关系取得：

```text
pa = page2pa(page)
kva = pa + va_pa_offset
```

项目中的 `KADDR` 处于注释状态，因此 SLUB 内部提供范围检查和对应转换。转换前检查物理起点不低于内核直接映射起点，且全部申请页都在可管理末端及 `PHYSICAL_MEMORY_END` 之内。转换失败会归还刚申请的页面并返回失败。

由合法对象指针寻找元数据时，先将其地址向下按页对齐，得到所在 Slab 的头部。大对象返回值同样位于首页头部之后，因此可用同一方式识别其头部。随后检查类型、对应描述符、对象槽位边界和活动位图。

初始化接入在 `pmm_init()` 之后，此时物理页分配和现有内核直接映射已经可用。

## 5. 小对象分配、复用与回收

1. 根据请求大小选择 Cache。
2. 优先使用 Partial 链表中的 Slab。
3. 没有可用 Slab 时，通过 `alloc_page()` 申请一页，初始化头部、位图和空闲槽位链表。
4. 取出一个空闲槽位，设置分配位，增加 Slab 和 Cache 的活动对象数。
5. Slab 用满后，从 Partial 移到 Full。

释放时清除对应分配位，将槽位放回空闲链表头，减少活动对象数。Full Slab 释放一个对象后重新进入 Partial。采用 LIFO 复用，因此同一 Slab 中刚释放的槽位优先复用。

当 Slab 的活动对象数变为零时，立即将其从 Cache 链表移除、使头部标识失效，并通过 `free_page()` 归还整页。只释放一个仍有其他活动对象的槽位，不会提前归还整页。

## 6. 大对象路径与溢出处理

大于 2048 字节的请求进入直接页分配路径。该路径可能使用一页或多页，页数包含真实头部开销：

```text
bytes = request_size + H
npages = (bytes - 1) / PGSIZE + 1
```

先检查 `request_size + H` 是否溢出，再计算页数并检查管理范围。页数取整不使用可能再次溢出的 `bytes + PGSIZE - 1`。

头部保存底层原始申请页数 `npages` 和调用者请求大小。大对象的 `slub_usable_size()` 返回请求大小，小对象则返回所属类别大小，不把元数据算作对象容量。

在本次布局中：

| 请求字节数 | 传给 PMM 的页数 | Buddy 实际占用页数 |
| --- | --- | --- |
| 2049 | 1 | 1 |
| 4096 | 2 | 2 |
| 5000 | 2 | 2 |
| 8192 | 3 | 4 |

释放时传回原始 `npages`，而不是自行推测 Buddy 的实际占用量。例如 8192 字节对象向 PMM 申请 3 页，释放时仍调用 `free_pages(base, 3)`，由 Buddy 的记账机制恢复整个 4 页块。SLUB 不依赖任何具体 PMM 的私有元数据。

大对象通过独立链表管理，不进入小对象 Cache。

## 7. 内部一致性检查

`slub_check_invariants()` 检查：

- Cache 类别、Slab 所属关系、链表双向连接及统计计数。
- 一个物理页不会重复作为多个 Slab 使用，大对象与 Slab 的页区间不会重叠。
- 元数据和对象区不重叠，槽位不跨越 Slab 页边界，所有对象满足对齐。
- 活动位图与空闲链表互补，空闲链表无重复节点和异常循环。
- `total == inuse + free_count`。
- Full Slab 无空闲槽位，Partial Slab 具有活动和空闲槽位，完全空闲 Slab 不留在链表中。
- 大对象的页数包含头部，容量与记录一致。

检查使用静态辅助存储，避免在内核较小的启动栈上创建大型数组。

## 8. 专项测试方案

测试在初始化后的受控单核阶段运行，要求开始时没有活动 SLUB 对象，并至少有 64 个空闲物理页。测试不会重新初始化 PMM、修改其计数或耗尽整机内存。

| 函数 | 测试内容与预期 |
| --- | --- |
| `slub_check_basic` | 16、100、64 字节对象的分配、访问、互不重叠及重复释放回收 |
| `slub_check_size_classes` | 覆盖 1～2049 字节的类别边界；容量符合最小合适类别，完整可用容量可写且互不干扰 |
| `slub_check_alignment` | 小对象及 5000 字节对象均满足 16 字节对齐 |
| `slub_check_data_integrity` | 不同对象使用不同数据模式；释放和重分配其中一个不破坏其他活动对象 |
| `slub_check_reuse` | 同页槽位释放后复用，不额外消耗物理页 |
| `slub_check_multi_slab` | 32 字节类别分配 `2N + 1` 个对象形成 3 个 Slab；验证 Full 转 Partial、复用、互不重叠和全部回收 |
| `slub_check_large_alloc` | 2049、3000、4096、4097、5000、8192 字节；验证页数、数据及跨页访问 |
| `slub_check_page_reclaim` | 8 个 16 字节对象共享一页；最后一个对象释放后才归还页面；大对象释放恢复页数 |
| `slub_check_boundary` | 零申请、空指针、极大请求、溢出、受控申请失败及重复初始化不丢弃活动对象 |
| `slub_check_stress` | 固定种子、16 个活动槽位、256 次交错操作；每轮核对数据、对象区间和内部状态 |
| `slub_check_invariants` | 全部 Cache、Slab 和大对象的结构及计数检查 |

所有测试接入 `slub_check()`。测试末尾要求全部链表为空、所有测试对象已释放，PMM 空闲页数恢复；再进行一次正常对象分配和释放，确认测试后接口仍可使用。

5000 字节测试显式写入并读取第 0、4095、4096、4999 字节，全部下标均位于有效对象范围内。不会读取已释放对象，也不要求新分配对象保留原数据。

受控失败测试申请超过当前空闲页数的一个大对象，预期立即返回 `NULL`，无需通过循环申请来耗尽内核。

## 9. 实际验证结果

### 9.1 完整项目交叉编译

使用本机 `riscv64-unknown-elf-gcc` 和项目 Makefile，指定临时 `OBJDIR`、`BINDIR` 完整编译并链接内核，成功生成 RISC-V ELF 和原始内核镜像。没有为了构建而修改 Makefile。

```bash
make -C code \
  GCCPREFIX=/home/viewfinder/toolchains/os-freedom-tools/bin/riscv64-unknown-elf- \
  OBJDIR=/tmp/ucore-slub-c33jba6m/build/obj \
  BINDIR=/tmp/ucore-slub-c33jba6m/build/bin
```

### 9.2 独立 Sv39 / Supervisor 运行验证（QEMU 7.0.0）

本次专项测试使用 `/opt/qemu-4.1.1/bin/qemu-system-riscv64`，后经 `--version` 核实其实际版本为 **7.0.0**，目录名不能作为版本依据。通过临时测试入口建立 Sv39 映射，进入 Supervisor 模式，在与项目一致的高地址直接映射下执行真实源文件。对象访问地址位于 `KERNBASE` 以上，使用真实物理内存，不是仅检查地址数值或使用假的对象存储。

测试分别选择 Buddy、Best-Fit 和 First-Fit 三种真实 PMM。每种后端初始登记 28672 页可用物理内存，先运行原有管理器检查，再运行全部 SLUB 测试。

临时驱动还在 PMM 调用边界注入返回 `NULL` 的故障，验证新 Slab 和大对象创建失败不破坏原有状态；仍有 Partial Slab 时，即使 PMM 暂时不能分配新页，也可正常复用已有槽位。该故障注入仅存在于临时测试驱动，没有改变项目 PMM 或 SLUB 的实现。

结果：三种后端全部通过专项测试、初始化前守卫检查和故障恢复检查，全部对象释放后物理页数恢复，之后仍可分配并读写 5000 字节对象。结束标志为：

```text
PASS backend buddy_pmm_manager: SLUB complete and pages restored
PASS backend best_fit_pmm_manager: SLUB complete and pages restored
PASS backend default_pmm_manager: SLUB complete and pages restored
ALL SLUB SV39 TESTS PASSED
```

### 9.3 先前 QEMU 7.0.0 的启动验证

先前使用 `/opt/qemu-4.1.1/bin/qemu-system-riscv64`，实际版本为 QEMU 7.0.0，其默认固件显示 OpenSBI v1.0。按项目现有 `-device loader,...` 参数启动时，固件显示 `Next Address = 0`，未进入内核，也未执行 SLUB 初始化。不能把这种启动结果记为标准启动成功。

为进一步验证完整内核，在临时目录中建立了启动适配 ELF：OpenSBI 跳转到它后，先建立临时直接映射，保留 `a0/a1`，再跳入原有 `kern_entry`。项目的启动汇编及固件均未修改。

使用该适配程序启动本次完整内核镜像，实际执行了设备树解析、`page_init()`、Buddy 专项检查、SLUB 初始化和全部 SLUB 测试，关键输出为：

```text
memory management: buddy_pmm_manager
Free physical memory: start = 0x00000000804d6000, end = 0x0000000088000000, size = 0x0000000007b2a000
buddy_check: all tests passed; kernel state restored
check_alloc_page() succeeded!
slub_init: caches 16..2048 bytes, alignment 16
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

随后内核进入现有空闲循环，由测试驱动按时间上限结束 QEMU。该超时是内核没有主动退出导致的，不是专项测试断言失败。

先前验证的临时产物和日志位于 `/tmp/ucore-slub-c33jba6m/`。三后端专项日志及驱动已持久保存到 [evidence](evidence/README.md)。以上适配启动结果属于 QEMU 7.0.0，不作为原参数启动 QEMU 4.1.1 的证据。后续已使用真正的 4.1.1 验证标准启动成功，见下一节。

本阶段未观察到 SLUB 专项断言失败，没有通过删除断言、调整 PMM 计数或放宽测试预期获得通过结果。

### 9.4 真正 QEMU 4.1.1 的原参数启动验证

2026 年 10 月 24 日补全实验报告时，核对版本并选择了与指导书一致的、带调试信息的可执行文件：

```bash
/home/viewfinder/qemu-4.1.1/riscv64-softmmu/qemu-system-riscv64 --version
# QEMU emulator version 4.1.1

/home/viewfinder/qemu-4.1.1/riscv64-softmmu/qemu-system-riscv64 \
  -machine virt -nographic -bios default \
  -device loader,file=/tmp/ucore-slub-c33jba6m/build/bin/ucore.img,addr=0x80200000
```

其默认 OpenSBI v0.4 正常进入内核。未使用启动适配程序，未修改 `entry.S` 或 Makefile，实际运行了 DTB 解析、页面初始化、Buddy 全部检查、SLUB 全部检查，输出 `buddy_check: all tests passed; kernel state restored` 和 `slub_check: all tests passed; PMM pages restored`。

完整原始输出见 [kernel_qemu_4_1_1.log](evidence/kernel_qemu_4_1_1.log)，参数见 [command.json](evidence/kernel_qemu_4_1_1.command.json)。因此，当前应通过明确选择真正的 QEMU 4.1.1 来复现课程启动，不能继续将先前 QEMU 7.0.0 的启动现象归因于本项目在 4.1.1 上存在同样问题。

## 10. 简化内容与限制

这是单核教学实现，不是完整 Linux SLUB。尚未实现 per-CPU 缓存、NUMA 策略、并发锁和无锁快路径、构造析构回调、红区和毒化检查、复杂调试统计等机制。

完全空闲 Slab 立即回收，便于验证无泄漏，但频繁申请释放可能反复创建 Slab；没有保留空闲 Slab 的性能优化。大对象不复用对象缓存，由底层 PMM 直接管理，Buddy 的内部碎片仍然可能存在。

`slub_check()` 用于启动时的受控验证，不应在其他模块正持有 SLUB 对象时调用。测试只证明所列场景及当前平台上的行为，不替代多核、压力长期运行和其他平台的验证。
