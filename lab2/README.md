# Lab2：物理内存和页表

- [正式报告](report/report.md)：实现、思考题、Challenge、GDB 和分工表。
- [任务审查](report/requirements-audit.md)：手册逐项对照与保留问题。
- [提示词索引](report/prompt.md) · [GDB 实操](report/gdb_test_1.md) · [SLUB 设计](report/slub_design.md)。
- [验证证据](validation/2026-10-25/README.md)。

## 运行

在仓库根目录的 WSL 终端执行：

```bash
cd lab2
make
make qemu
```

QEMU 退出：Ctrl+A，松开后按小写 x。也可在根目录使用 `make -C lab2 qemu`。

工具路径由个人 `Makefile.local` 提供；其他电脑首次配置可参考 `Makefile.local.example`。VS Code 打开整个仓库并连接 WSL，使用根目录的调试配置。

## 验证与调试

以下命令在 `lab2/` 执行：

| 命令 | 作用 |
| --- | --- |
| `make verify` | 三种 RAM 启动、三分配器专项及两种评分 |
| `make grade` | 独立 Best Fit 调试配置评分，实测 20/20 |
| `make grade-original` | 原版默认 Buddy 评分，实测 10/20 |
| `make trace` | 采集页表及 TLB 调试记录 |
| `make audit-page-init` | 六种初始化输入验证 |
| `make audit-allocators` | 复现 First Fit 两处已知尾插错误；Best Fit/Buddy 同例通过 |
| `make check-preservation` | 校验搭档源码和原测试未变 |

手动调试时，两个 WSL 终端分别执行 `make debug`、`make gdb`。

## 当前状态

源码位于 `code/`，与搭档 `lab2` 分支 `1444f66` 的 43 个文件完全一致，默认 Buddy。报告及运行入口更新在 `main`，分工表留空。

已知边界：Best Fit 独立运行不等于源码选择器切换；原课程 First Fit 存在两处尾插缺陷，保留原码；尚缺独立“实验报告要求”页供格式核对。详情集中在任务审查表。`audit-allocators` 零退出表示预期缺陷复现成功，不能解释为实现没有缺陷。
