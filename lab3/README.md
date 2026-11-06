# Lab3：Lab2 内存迁移与 Trap 实现

基于桌面 `lab3.zip` 的 2026 年课程框架，迁移来源为本仓库自己的 `lab2/code/`。未使用此前误导入的他人实现。

## 已迁入的内容

| 内容 | 迁移方式 |
| --- | --- |
| `pmm.c` 的 `page_init()` | 迁入 Lab2 实现，建立 Page 数组、标记保留页、初始化可用内存 |
| First Fit | 核对并沿用 Lab2 实现；其函数主体与课程框架已有实现一致，未替换 Lab3 自检 |
| Best Fit | 迁入空闲链表、顺序插入辅助函数、初始化、分配、释放、空闲页统计及 manager 定义；保留 Lab3 原自检 |
| Buddy | 原样复制 `buddy_pmm.c/.h`，包括原实现自检；设为默认 PMM，与自己的 Lab2 一致 |
| SLUB | 原样复制 `slub.c/.h`，在 `pmm_init()` 后、开启时钟中断前执行初始化与原自检 |
| 地址宏 | 在 Lab3 的 `memlayout.h` 增加 Lab2 使用的三个常量，保留 Lab3 原子位操作 |

`alloc_pages()`、`free_pages()`、`nr_free_pages()` 的中断状态保存与恢复仍使用 Lab3 实现。启动流程保留 Lab3 的精确栈地址设置、DTB 初始化、中断初始化及后续时钟调用，未整体覆盖为 Lab2。

Lab2 原目录未修改。文档、旧评分脚本和个人工具链配置没有覆盖今年 Lab3 对应文件。First Fit 在 Lab2 已记录的尾插缺陷仍按原实现保留；本次没有将其修复或声称其边界测试全部通过。

## 已完成验证

- 在现有 WSL Ubuntu、RISC-V GCC 15.1.0 下，`pmm/default_pmm/best_fit_pmm/buddy_pmm/slub` 五个内存管理编译单元均编译通过。
- 临时的内存验证副本使用 QEMU 4.1.1：Buddy 在 64、128、256 MiB 下通过 PMM 和 SLUB 自检，Best Fit 在 128 MiB 下通过 PMM 和 SLUB 自检，均输出结束标记并关机。
- 256 MiB 配置仍遵循 Lab2 的 `PHYSICAL_MEMORY_END=0x88000000` 上限，没有声称管理了全部 256 MiB。
- 原始输出与源文件校验见 [验证记录](validation/lab2-migration/summary.json)；各次运行输出位于同目录。

验证副本位于本地未提交的 `tmp/lab3-migration-smoke/`：仅在副本中去掉 Trap 源目录的构建、`idt_init/clock_init/intr_enable` 调用，并为调试监视器提供 `print_trapframe` 占位函数，运行内存自检后打印 `LAB2_MIGRATION_BOOT_PASS` 并调用 SBI 关机。Best Fit 用例仅在该副本中切换 PMM。它验证内存迁移，**不验证 Trap、中断返回或 Lab3 评分**。

## Trap 实现（2026-11-06）

- `RESTORE_ALL` 按现有 Trap frame 偏移恢复 `sstatus`、`sepc` 与通用寄存器，最后恢复原 `sp`。
- `__alltraps` 通过 `a0` 将 Trap frame 指针传给 `trap()`，返回后进入 `__trapret`。
- `interrupt_handler()` 分类处理中断，时钟每 100 次打印一次，打印 10 次后通过 SBI 关机。下一次定时事件在计数和打印结束后重新设置，避免串口打印期间下一次截止时间已到而返回后立即再次触发。
- `exception_handler()` 处理非法指令与断点，识别 16/32 位编码长度并推进 `epc`，其他异常输出 Trap frame；对不支持的更长编码输出现场并 panic。取指逻辑针对本实验可读取的内核代码区，不提供通用用户地址安全取指。
- 将 `SAVE_ALL` 的旧 CSR 名 `sbadaddr` 改为 `stval`，保存位置与结构体布局不变。
- 课程 `tools/` 测试和评分脚本保持原样，没有更改匹配规则或分值。

构建和验证在仓库根目录的 WSL 终端执行，工具路径按本机安装位置调整：

```bash
export PATH="/home/lingyuan/riscv-elf-toolchains/bin:/opt/qemu-4.1.1/bin:$PATH"
make -C lab3
make -C lab3 qemu
make -C lab3 grade
```

本次通过课程注入器和 `tools/grade.sh` 在隔离的源码副本中执行评分，等价于 `make grade` 的注入及评分步骤；没有把注入代码写入正式源码。运行证据和初次时序问题记录见 [Trap 验证记录](validation/trap/README.md)。实验报告仍需另行整理 spec、prompt、原理分析与排错过程。
