# uCore RISC-V 实验

运行环境：VS Code + WSL Ubuntu、RISC-V 交叉工具链、QEMU 4.1.1。

| 实验 | 入口 |
| --- | --- |
| Lab1 | [实验报告](lab1/实验报告.md) |
| Lab2 | [运行说明](lab2/README.md) · [实验报告](lab2/实验报告.md) |
| Lab3 | [迁移与运行状态](lab3/README.md)（Lab2 已迁入，Trap 待实现） |

在仓库根目录的 WSL 终端执行：

```bash
make -C lab2
make -C lab2 qemu
```

QEMU 退出：按 Ctrl+A，松开后按小写 x。实验一将上述 `lab2` 换成 `lab1`。

个人工具路径保存在对应实验的 `Makefile.local`，不提交 Git。Lab2 默认使用 Buddy，搭档原版源码保持不变。

## Lab3 课程框架与 Lab2 迁移

`lab3/` 基于本人提供的课程压缩包 `lab3.zip`（包内目录为 `lab3_new/`），现已迁入自己 Lab2 的内存初始化、First Fit、Best Fit、Buddy 与 SLUB，默认使用 Buddy。Lab3 的 Trap 练习与评分文件保持课程原样，尚未实现；迁移验证及剩余问题见 [Lab3 说明](lab3/README.md)。

此前误导入的他人实现已从当前目录移除，可在历史提交 `98c0fc8` 中查看。实验范围以 2026 年课程指导书及助教最新通知为准，旧版 Challenge 无需完成。

往年实现的优点、问题及验证记录见 [Lab3 参考实现审查](reviews/lab3-reference-review.md)。
