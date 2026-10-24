# Lab2 验证附件

记录日期：2026 年 10 月 24 日。附件保存实际输出、调试脚本和独立验证入口源码，不包含内核二进制。主报告见 [report.md](../report.md)。

目录迁移说明：原始日志、调试脚本和 `source_hashes.json` 保留当时的路径，不改写历史现场。其中 `lab2/code/` 对应当前工作目录中的 `code/`；下面的复现命令已更新为当前路径。

## 记录对应关系

| 文件 | 用途及限制 |
| --- | --- |
| [versions.txt](versions.txt) | 实际工具版本；`/opt/qemu-4.1.1/` 内的程序实际为 7.0.0 |
| [build.log](build.log) | 当前完整项目交叉编译和链接成功记录 |
| [build_artifacts.sha256](build_artifacts.sha256) | 本轮使用的 ELF 和原始镜像 SHA-256；调试地址与这一构建对应 |
| [source_hashes.json](source_hashes.json) | 本轮补全报告前的 `lab2/code` 文件摘要，用于确认报告工作未改实现 |
| [kernel_qemu_4_1_1.log](kernel_qemu_4_1_1.log) | 真正 QEMU 4.1.1、OpenSBI v0.4、原 loader 参数的完整内核启动 |
| [kernel_qemu_4_1_1.command.json](kernel_qemu_4_1_1.command.json) | 上述启动的原始 argv；镜像当时位于临时构建目录 |
| [slub_test.log](slub_test.log) | QEMU 7.0.0 下三种真实 PMM 的独立 Sv39/S 模式验证，含失败注入和页数恢复 |
| [slub_test.c](slub_test.c)、[test_entry.S](test_entry.S)、[test.ld](test.ld) | 三后端验证驱动；直接链接项目分配器，并非正式内核启动文件 |
| [kernel_store_debug.gdb](kernel_store_debug.gdb)、[kernel_store_debug.log](kernel_store_debug.log) | RISC-V GDB 的实际存储指令、寄存器和单步结果 |
| [qemu_mmu_debug.gdb](qemu_mmu_debug.gdb)、[qemu_mmu_debug.log](qemu_mmu_debug.log) | 宿主机 GDB 捕获 M 模式对照、Sv39 存储查表、TLB 查询栈帧及回填 |

独立驱动的 `alloc_pages()` 包装器通过开关注入 `NULL`，用于验证失败恢复。实现代码仍使用 `code/kern/mm` 中真实源文件；不能把包装器中的行为当成正式 PMM 的修改。

## 构建与启动

在仓库根目录：

```bash
make -C code \
  GCCPREFIX=/home/viewfinder/toolchains/os-freedom-tools/bin/riscv64-unknown-elf- \
  OBJDIR=/tmp/ucore-lab2-report/obj \
  BINDIR=/tmp/ucore-lab2-report/bin

/home/viewfinder/qemu-4.1.1/riscv64-softmmu/qemu-system-riscv64 \
  -machine virt -nographic -bios default \
  -device loader,file=/tmp/ucore-lab2-report/bin/ucore.img,addr=0x80200000
```

将工具路径替换为本机实际安装位置，先确认版本。日志对应的实际构建路径为 `/tmp/ucore-slub-c33jba6m/build/bin/`，与上述复现示例不同。内核测试完成后停留在空闲循环，需要结束模拟器；以完整成功标志为判断依据。

## 内核 GDB

先启动 QEMU，并增加 `-S -gdb tcp:127.0.0.1:44687`。另开 RISC-V GDB，执行保存的 `kernel_store_debug.gdb`；应先将其中 ELF 路径更新为当前构建路径，并确保端口一致。保存脚本中的端口是本轮实际使用值，并非固定课程配置。

脚本的 `0xffffffffc0205d1e` 等地址属于本轮 ELF。如果源码、编译选项或链接布局改变，应重新用反汇编定位 `memset` 内的存储指令，检查寄存器计算出的目标地址，再更新断点。

## 宿主机 GDB

使用与源码一致、带符号的 QEMU 4.1.1，可直接由宿主机 GDB 启动进程，不要求另行 attach：

```bash
gdb -q -batch \
  -x report/evidence/qemu_mmu_debug.gdb \
  --args /home/viewfinder/qemu-4.1.1/riscv64-softmmu/qemu-system-riscv64 \
  -machine virt -nographic -bios default \
  -device loader,file=/tmp/ucore-lab2-report/bin/ucore.img,addr=0x80200000
```

该脚本中的 `run` 直接推进客户机，因此此命令不加 `-S`。先核对脚本中的 QEMU 源码路径、当前 `satp`、目标 VA 和源码行号；这些是本轮现场记录，不能无条件用于另一个版本或构建。脚本最后结束自己启动的 QEMU 进程。

条件断点选择了已在客户机 GDB 中确认的目标虚拟页和存储类型。两份日志来自针对同一内核构建的独立运行；并非必须同时控制两个 GDB 才能得到该结果。

`qemu_mmu_debug.log` 末尾的源码行断点因内联进入了 `tlb_n_used_entries_inc`，显示 `No locals`。实际 TLB 回填入参此前已经记录；不可将不可见的局部变量解释成已观测到的具体 TLB 内容。
