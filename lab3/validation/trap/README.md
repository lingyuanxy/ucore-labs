# Lab3 Trap 验证（2026-11-06）

环境：WSL Ubuntu，RISC-V GCC 15.1.0，QEMU 4.1.1。

| 检查 | 结果 |
| --- | --- |
| 完整编译 | 通过 |
| 上下文恢复、压缩断点 EPC 返回 | 35/35 |
| 非法指令返回、中断分类及异常兜底 | 25/25 |
| 持续时钟中断及重复 Trap 返回 | 40/40 |
| 原课程评分合计 | 100/100 |
| 普通 QEMU 启动 | 恰好输出 10 行 `100 ticks`，SBI 关机，退出码 0 |

## 执行方式

在正式源码中构建并运行普通镜像。在隔离的源码副本中，使用课程原始 `tools/inject.py` 注入测试，再运行原始 `tools/grade.sh`，没有改动测试或匹配条件。两个步骤与 `make grade` 的核心步骤一致。工具路径通过 PATH 提供：

```bash
export PATH="/home/lingyuan/riscv-elf-toolchains/bin:/opt/qemu-4.1.1/bin:$PATH"
make -C lab3
# 对隔离副本执行：
python3 lab3/tools/inject.py tmp/lab3-grade-validation
(cd tmp/lab3-grade-validation && sh tools/grade.sh)
```

现有验证副本已注入，不应对其重复注入。需要重新验证时使用新的源码副本，或在 Lab3 目录执行课程提供的 `make grade`。

## 排错记录

初版把 `clock_set_next_event()` 放在计数和串口输出之前。时钟测试自身报告 PASS，但输出 `ticks=201`；原评分脚本还匹配 `ticks=200`，所以初次评分为 60/100。串口输出耗时可能使已设定的下一次事件在处理结束前到期，返回后立即再次进入中断。

将重新设定定时事件移动到当前中断处理末尾后，重新完整评分为 100/100，时钟用例输出 `ticks=200`。未增加用于凑匹配条件的额外输出，也未修改评分规则。此方式从本次处理结束重新计算周期，串口开销会使实际周期略大于理想 10ms；这是教学实验的相对定时策略，不代表精密实时计时。

## 证据

- `build.txt`：最终正式源码构建输出。
- `normal.txt`：最终普通启动输出。
- `grade.txt`：最终原课程评分输出。
- `context.txt`、`illegal.txt`、`timer.txt`：最终三个用例的串口输出。
- `initial-grade.txt`、`initial-timer.txt`：初次计数时序问题的原始证据。
- `summary.json`：结果、实现源文件及未改动课程工具的 SHA-256。

当前异常处理限定于本实验可读取的内核代码区域及 16/32 位指令。更长的非法编码会保留现场并 panic；其他未支持异常只打印现场，不提供通用恢复机制。这里的测试通过不意味着实现了完整用户态异常管理。
