# Lab2

入口材料：

- [实验报告](实验报告.md)：全部任务、实现分析和真实验证结果。
- [学习路线](学习路线.md)：约 4–5 小时，从运行到答辩。
- [SPEC 与提示词](SPEC与提示词.md)：七份四段式实现/测试规格。
- [evidence](evidence/)：课程评分、六种启动组合和三组 GDB 原始记录。

在 WSL Ubuntu 中进入本目录：

```bash
# 其他电脑首次使用：cp Makefile.local.example Makefile.local，再修改自己的工具路径
make
make qemu
make grade
make PMM=buddy qemu
python3 tools/run_checks.py
python3 tools/trace_mmu.py
```

默认 Best Fit，Buddy 使用独立的 `bin/buddy` 与 `obj/buddy`。两种模式均运行 SLUB 检查。QEMU 退出用 Ctrl+A 后按 x。

`trace_mmu.py` 默认使用本机实验一保留的带符号 QEMU 4.1.1；其他机器可传 `--qemu-debug /path/to/qemu-system-riscv64 --source /path/to/qemu-4.1.1`。个人工具路径放在 `Makefile.local`，不提交 Git。

本次课程脚本 20/20，Buddy 与 SLUB 的额外检查和真实 GDB 取证也已通过。分数仅代表课程脚本的两项检查，完整学习仍需沿学习路线亲自复现。
