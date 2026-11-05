# uCore RISC-V 实验

运行环境：VS Code + WSL Ubuntu、RISC-V 交叉工具链、QEMU 4.1.1。

| 实验 | 入口 |
| --- | --- |
| Lab1 | [实验报告](lab1/实验报告.md) |
| Lab2 | [运行说明](lab2/README.md) · [实验报告](lab2/实验报告.md) |
| Lab3 | [课程原始框架](lab3/)（待实现） |

在仓库根目录的 WSL 终端执行：

```bash
make -C lab2
make -C lab2 qemu
```

QEMU 退出：按 Ctrl+A，松开后按小写 x。实验一将上述 `lab2` 换成 `lab1`。

个人工具路径保存在对应实验的 `Makefile.local`，不提交 Git。Lab2 默认使用 Buddy，搭档原版源码保持不变。

## Lab3 课程原始框架

`lab3/` 来自本人提供的课程压缩包 `lab3.zip`（包内目录为 `lab3_new/`），仅将目录名调整为 `lab3/`，文件内容保持原样。当前为尚未实现的课程框架，Lab2 衔接和 Lab3 功能均待完成，尚未通过编译或评分。

此前误导入的他人实现已从当前目录移除，可在历史提交 `98c0fc8` 中查看。实验范围以 2026 年课程指导书及助教最新通知为准，旧版 Challenge 无需完成。
