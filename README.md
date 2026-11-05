# uCore RISC-V 实验

运行环境：VS Code + WSL Ubuntu、RISC-V 交叉工具链、QEMU 4.1.1。

| 实验 | 入口 |
| --- | --- |
| Lab1 | [实验报告](lab1/实验报告.md) |
| Lab2 | [运行说明](lab2/README.md) · [实验报告](lab2/实验报告.md) |
| Lab3 | [参考说明](lab3/README.md) · [原仓库报告](lab3/report.md) |

在仓库根目录的 WSL 终端执行：

```bash
make -C lab2
make -C lab2 qemu
```

QEMU 退出：按 Ctrl+A，松开后按小写 x。实验一将上述 `lab2` 换成 `lab1`。

个人工具路径保存在对应实验的 `Makefile.local`，不提交 Git。Lab2 默认使用 Buddy，搭档原版源码保持不变。

## Lab3 参考来源

`lab3/` 完整导入自 [July-h5kf3/2025FallNKUOS 的 lab03](https://github.com/July-h5kf3/2025FallNKUOS/tree/9b879a4fa4dbef755105a76fe59f40d52c8e67e5/lab03)，来源提交为 `9b879a4fa4dbef755105a76fe59f40d52c8e67e5`。目录内源码、报告与演示图保持原样，报告及其中的分工、截止日期属于原仓库作者的往年内容。

本次仅导入参考资料，尚未按 2026 年指导书适配或验证。本年度实验范围以课程指导书及助教最新通知为准，旧版 Challenge 无需完成。
