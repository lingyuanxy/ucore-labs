# Lab3 往年参考实现审查

审查日期：2026-11-05。

本次审查对象为 July-h5kf3/2025FallNKUOS 的提交 `9b879a4fa4dbef755105a76fe59f40d52c8e67e5`，对应本仓库历史提交 `98c0fc8` 中的 `lab3/`。当前 `lab3/` 已替换为用户提供的课程原始压缩包，下面的问题均指旧参考版本，不是对当前空白框架的缺陷判定。

结论：Trap 汇编恢复和时钟处理的主体思路可以参考；原提交存在实际编译阻塞，异常处理不能直接用于今年框架，报告部分原理解释有错误。不宜把它视为已经验证、可以直接提交的完整答案。

## 1. 已完成的替换

- 来源：用户提供的桌面 `lab3.zip`，压缩包内目录为 `lab3_new/`。
- 本地目录统一为 `lab3/`，共 56 个文件，替换后逐文件校验与 ZIP 内字节一致。
- 未填入 Lab2 或 Lab3 实现，未修改测试、Makefile 或框架内容。
- 旧报告、演示图、额外 Buddy/SLUB 源码等不属于压缩包的文件已从当前 `lab3/` 移除。
- 替换提交：`47d8db2`。旧内容仍可在 Git 历史 `98c0fc8` 查看。

## 2. 问题，按影响排序

### P1：原提交无法直接编译

旧 [pmm.c:39](https://github.com/lingyuanxy/ucore-labs/blob/98c0fc8/lab3/kern/mm/pmm.c#L39) 使用 `best_fit__pmm_manager`，实际声明的符号是 `best_fit_pmm_manager`。多出的下划线会触发未声明标识符错误；下一行再赋正确值也无法消除编译错误。

旧 [slub_pmm.c:208](https://github.com/lingyuanxy/ucore-labs/blob/98c0fc8/lab3/kern/mm/slub_pmm.c#L208) 和第 223 行调用 `page2kva()`，该版本没有提供此接口。当前工具链报告隐式函数声明及整数到指针转换错误。Makefile 会编译 `kern/mm` 下的源码，因此即使运行时选择 Best Fit，也会受此问题影响。

这两项均已通过实际构建复现，不是仅根据代码推测。

### P1：固定加 4 会错误处理压缩断点

旧 [trap.c:194](https://github.com/lingyuanxy/ucore-labs/blob/98c0fc8/lab3/kern/trap/trap.c#L194) 对断点固定执行 `tf->epc += 4`。RISC-V 支持 2 字节压缩断点，跳过 4 字节会跳进后续指令或漏执行指令。

对今年 `tools/test_lab3_context.S` 实际汇编并反汇编后，断点编码为 `9002`，长度是 2 字节；下一条 `li a0,261` 为 4 字节。旧处理会返回到这条 `li` 的中间。因此这是与今年上下文测试直接相关的功能问题。

非法指令分支同样固定加 4：对往年用于测试的 `mret` 和今年的 `.word 0x0000007b` 这两种 4 字节指令适用，但不能据此声称支持所有指令长度。今年实现应按规定考虑相应编码和长度。

### P2：旧输出不符合今年测试的匹配条件

旧异常输出为 `Breakpoint caught at ...` 和 `Illegal instruction caught at ...`；今年 [grade.sh](../lab3/tools/grade.sh) 分别检查 `Breakpoint at` 和 `Illegal instruction at`，二者并不匹配。

今年还检查 `Unknown interrupt: cause 15`。旧中断默认分支只打印 Trap frame，没有这条提示。

这些属于对今年要求的兼容问题，不能用今年的格式反推往年格式本身违反了当时要求。即便算法修好，也需要按今年框架的输出约定重新实现。

### P2：将主动制造异常的测试代码留在日常时钟路径

旧 [clock.c:13](https://github.com/lingyuanxy/ucore-labs/blob/98c0fc8/lab3/kern/driver/clock.c#L13) 在读取时间前无条件执行 `mret`。内核处于 S 态时，这会触发非法指令异常。

作为单独验证异常处理的手段，这个思路可用；但保留在 `get_cycles()` 中，会让首次设置时钟以及每次重新设置时钟都额外触发异常。时钟中断处理期间还会进入嵌套异常，增加开销并污染日志。更好的组织方式是独立测试函数或明确的测试开关，普通计时路径只读时间。

### P2：部分异常被静默忽略，返回后可能重复触发

旧 [exception_handler()](https://github.com/lingyuanxy/ucore-labs/blob/98c0fc8/lab3/kern/trap/trap.c#L168) 对取指错误、访存错误等多个已列出的异常只执行 `break`，既不打印现场，也不恢复或改变执行位置。持续存在的故障会在返回后再次出现，且缺少诊断输出。

今年指导书要求未要求具体处理的异常通过 `print_trapframe(tf)` 兜底。旧版本只有 `default` 分支会打印；落入这些空 `case` 的异常不会走到 `default`。

### P2：内存范围上限比较混用了物理地址和虚拟地址

旧 [pmm.c:102](https://github.com/lingyuanxy/ucore-labs/blob/98c0fc8/lab3/kern/mm/pmm.c#L102) 将物理地址 `maxpa` 与高位内核虚拟地址 `KERNTOP` 比较，不能有效约束物理内存范围。即便触发上限逻辑，后面传入 `init_memmap()` 的 `mem_end` 也没有同步截断。

默认较小 RAM 可能掩盖这个问题；RAM 超过内核已建立的映射范围时，分配器可能纳入不可访问的页。应在同一地址空间内计算并一致使用有效内存上限。本次未做多 RAM 启动验证，此项为源码分析结论。

### P2：报告中的部分原理解释错误

旧 [report.md:166](https://github.com/lingyuanxy/ucore-labs/blob/98c0fc8/lab3/report.md#L166) 称 Trap 时 CPU 自动切换到内核栈。RISC-V 通用寄存器和栈切换需要软件处理；这个简化实验主要处理内核执行期间的 Trap，不能据此声称已完成完整的用户栈到内核栈切换。

旧 [report.md:177](https://github.com/lingyuanxy/ucore-labs/blob/98c0fc8/lab3/report.md#L177) 称恢复 `sepc` 会造成错误、`sstatus` 不需要软件恢复，与它自己的 `RESTORE_ALL` 代码矛盾。正确流程是从 Trap frame 恢复相应的 `sepc`、`sstatus`，然后执行 `sret`；`scause`、`stval` 的记录用于处理和诊断，通常不必在返回前恢复，但不能称它们为架构上只读的 CSR。

相关状态和返回机制可核对 [RISC-V Supervisor 规范](https://docs.riscv.org/reference/isa/v20260120/priv/supervisor.html)。

## 3. 做得合理、可以借鉴的部分

### RESTORE_ALL 的布局和恢复顺序

旧 [trapentry.S:58](https://github.com/lingyuanxy/ucore-labs/blob/98c0fc8/lab3/kern/trap/trapentry.S#L58) 与 `SAVE_ALL` 的固定偏移对应，恢复 `sstatus` 和 `sepc`，随后恢复通用寄存器，最后恢复 `sp`。先恢复其他寄存器再恢复 `sp`，避免过早失去 Trap frame 基址；临时使用的 `s1`、`s2` 最后也从现场恢复。这个结构符合当前简化实验的需要。

### __alltraps 的汇编与 C 接口清晰

旧 [trapentry.S:103](https://github.com/lingyuanxy/ucore-labs/blob/98c0fc8/lab3/kern/trap/trapentry.S#L103) 在保存上下文后，将 `sp` 放入 `a0`，调用 `trap()`，返回后顺序进入 `__trapret`。它正确表达了 C 函数参数是 Trap frame 指针这一约定。

### 时钟处理的主体逻辑正确

旧 [trap.c:134](https://github.com/lingyuanxy/ucore-labs/blob/98c0fc8/lab3/kern/trap/trap.c#L134) 每次中断都设置下一次事件、将 `ticks` 加一、每 100 次打印一次、达到 10 次打印后通过 SBI 关机。它没有遗漏重新设定下一次时钟事件，也没有对时钟中断错误地推进 `epc`。计时主体可参考，但应移除上面提到的无条件异常注入，并适配今年的接口和约束。

### 报告有流程和验证意识

报告按 Trap 进入、保存、分发、恢复组织说明，也提供了运行演示。这样的结构有助于理解。但演示不能证明当前仓库提交可编译或覆盖全部边界，报告中的原理仍需要核对。

以上一些设计也可能来自课程已有框架；这里只评价代码本身，不把它们全部认定为原作者独立设计。

## 4. 验证记录与边界

- 环境：现有 WSL Ubuntu，RISC-V GCC 15.1.0。
- 在旧参考目录的本地备份中执行 `make -k -j2 GCCPREFIX=/home/lingyuan/riscv-elf-toolchains/bin/riscv64-unknown-elf-`，构建失败，确认前述两个编译阻塞。
- 构建日志保存在本地 `tmp/lab3-reference-build.log`，未作为课程源码提交。
- 单独汇编今年的 `test_lab3_context.S` 并反汇编，确认断点是 2 字节编码 `9002`。
- 未修补旧版本来运行完整 QEMU 评分，未声称其通过今年测试，也未对附带 Buddy、SLUB 算法做完整正确性审计。
- 当前 `lab3/` 仍是未经实现的纯净框架；它需要补代码才能编译和运行，不能把其当前不可编译归为本次替换失败。

## 5. 对后续实现的建议

保留今年框架和测试，从自己的 Lab2 接入 `page_init()` 及 Best Fit 所需实现，再完成 `RESTORE_ALL`、`__alltraps`、`interrupt_handler()`、`exception_handler()`。参考旧版本的汇编布局和时钟处理思路，但重新核对指令长度、精确输出、异常兜底和测试隔离。

当前纯净包中，Lab2 待填位置是 `kern/mm/pmm.c:84` 与 `kern/mm/best_fit_pmm.c:7`；Lab3 待填位置是 `trapentry.S` 的两个 `function1` 标记和 `trap.c` 的 `function2` 标记。默认分配器目前是 First Fit，Best Fit 文件依然会参与构建，因此其空缺也必须补齐。是否改用自己的 Buddy 是后续实现选择，不是本次还原纯净版的必要操作。
