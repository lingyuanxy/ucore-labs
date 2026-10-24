# uCore Lab1：最小可执行内核

本工作目录对应 `lab1` 分支，根目录为 `code/` 和 `report/`。

- [实验报告](report/report.md)
- [提示词汇总](report/prompt.md)
- [原始报告模板](report/实验报告模板.md)
- 原有 17 张测试截图保存在 `report/images/`，报告中的相对链接继续有效。

## 打开与编译

在 VS Code 中打开 `/home/viewfinder/OS/ucore-lab1/`；Lab2 则打开旁边的 `/home/viewfinder/OS/ucore-lab2/`。两个目录由 Git worktree 管理，共用同一个小组仓库，分别提交到 `lab1`、`lab2` 分支。

原 `/home/viewfinder/OS/ucore-labs/` 是保留在 `main` 分支的主仓库，不能删除其 `.git` 数据。

```bash
make -C code GCCPREFIX=/home/viewfinder/toolchains/os-freedom-tools/bin/riscv64-unknown-elf-
make -C code qemu QEMU=/home/viewfinder/qemu-4.1.1/riscv64-softmmu/qemu-system-riscv64
```

工具路径按本机实际位置填写。当前给出的 QEMU 是核对过的 4.1.1；报告中的原始环境及截图保留实验当时的记录。

## 调试

一个终端启动 QEMU：

```bash
make -C code debug QEMU=/home/viewfinder/qemu-4.1.1/riscv64-softmmu/qemu-system-riscv64
```

另一个终端启动 GDB：

```bash
cd code
/home/viewfinder/toolchains/os-freedom-tools/bin/riscv64-unknown-elf-gdb \
  -ex 'file bin/kernel' \
  -ex 'set arch riscv:rv64' \
  -ex 'target remote localhost:1234'
```

两个实验默认均使用端口 1234，调试时只启动一个实验的 QEMU。VS Code 原有任务已适应根目录 `code/`；F5 配置连接已启动的 QEMU，不自动启动模拟器。

## 历史与提交

目录调整前的原始布局可以从 `main` 或标签 `lab2-before-layout-20261024` 查看。源代码内容未因本次迁移改动，报告与截图已移动到规定位置。

远程仓库仍为 `https://github.com/lingyuanxy/ucore-labs`。本工作目录审查并提交后，推送本分支：

```bash
git status
git push -u origin lab1
```

本次整理不自动推送。编译产物与本地配置不会进入提交。
