# uCore Lab2：物理内存和页表

本分支为 `lab2`，按课程要求在根目录保存 `code/` 和 `report/`。

- [正式实验报告](report/report.md)
- [提示词汇总](report/prompt.md)
- [GDB 题目一实操记录](report/gdb_test_1.md)
- [SLUB 设计说明](report/slub_design.md)
- [验证日志及复现说明](report/evidence/README.md)
- [测试截图目录](report/images/README.md)：真实截图仍待补充。

## 分支与本地工作目录

两个实验共用同一个小组远程仓库，通过 Git worktree 分别打开：

```text
/home/viewfinder/OS/ucore-lab1/   lab1 分支
/home/viewfinder/OS/ucore-lab2/   lab2 分支
```

每个目录内部都是 `code/` 和 `report/`。VS Code 应打开对应实验的整个工作目录；在该目录提交时，只会提交到它所对应的分支，不需要在两个实验之间反复切换分支。

原 `/home/viewfinder/OS/ucore-labs/` 保留为主仓库，位于 `main` 分支。该主仓库及 `.git` 目录需要保留，两个 worktree 共用其中的 Git 数据。

## 编译与运行

在 Lab2 工作目录中：

```bash
make -C code GCCPREFIX=/home/viewfinder/toolchains/os-freedom-tools/bin/riscv64-unknown-elf-
make -C code qemu QEMU=/home/viewfinder/qemu-4.1.1/riscv64-softmmu/qemu-system-riscv64
```

使用各自机器的实际工具路径。当前上述 QEMU 路径为真正的 4.1.1；`/opt/qemu-4.1.1/` 中的程序曾核实实际为 7.0.0，不能依据目录名判断版本。

编译产物 `code/bin/`、`code/obj/` 被忽略。迁移后需要重新构建，让调试信息使用新的源码目录。

## 调试

先在一个终端运行：

```bash
make -C code debug
```

在另一个终端运行：

```bash
cd code
/home/viewfinder/toolchains/os-freedom-tools/bin/riscv64-unknown-elf-gdb \
  -ex 'file bin/kernel' \
  -ex 'set arch riscv:rv64' \
  -ex 'target remote localhost:1234'
```

QEMU 源码调试另用宿主机 GDB；完整过程见题目一记录。两个实验默认都使用 1234 端口，调试时只启动一个实验的 QEMU。

VS Code 原有四个任务的路径已指向 `code/`，没有设置新的默认构建任务。F5 调试配置连接已启动的 QEMU，不自动启动模拟器。

## 历史版本

目录调整前的完整版本保存在标签 `lab2-before-layout-20261024`，对应提交 `fbd7876`，其中包含原来的 `lab1/` 和 `lab2/`。

可以只读查看旧 Lab1 报告：

```bash
git show lab2-before-layout-20261024:lab1/实验报告.md
```

原实验记录、源文件和截图没有因目录迁移丢失。个人分工、源码学号标记和真实 Lab2 测试截图仍需完成最终核对。

## 提交

远程仓库保持为 `https://github.com/lingyuanxy/ucore-labs`。在本 Lab2 工作目录审查后推送对应分支：

```bash
git status
git push -u origin lab2
```

本次目录整理只创建本地提交和 worktree，不自动推送远程。
