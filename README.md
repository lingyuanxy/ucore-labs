# uCore RISC-V 实验

运行环境：VS Code + WSL Ubuntu、RISC-V 交叉工具链、QEMU 4.1.1。

| 实验 | 入口 |
| --- | --- |
| Lab1 | [实验报告](lab1/实验报告.md) |
| Lab2 | [运行说明](lab2/README.md) · [实验报告](lab2/实验报告.md) |

在仓库根目录的 WSL 终端执行：

```bash
make -C lab2
make -C lab2 qemu
```

QEMU 退出：按 Ctrl+A，松开后按小写 x。实验一将上述 `lab2` 换成 `lab1`。

个人工具路径保存在对应实验的 `Makefile.local`，不提交 Git。Lab2 默认使用 Buddy，搭档原版源码保持不变。
