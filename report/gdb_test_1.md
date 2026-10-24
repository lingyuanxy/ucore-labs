# GDB 调试题目一：实操对话与流程记录

日期：2026 年 10 月 24 日。

> 目录迁移说明：本记录中的工作路径是实操当时的路径；当前文件为 `report/gdb_test_1.md`，源码位于工作目录根部的 `code/`。历史命令和原始输出保留原样。

对应指导书：[Lab2：GDB 调试页表查询过程](http://oslab.mobisys.top/lab2026/_book/lab2/lab2_4_qemu_mmu_debug.html)。

本文保存本次题目一的实际操作流程、用户贴出的 GDB 输出和关键问答。对话中的操作说明按步骤整理，用户输出单独保留；没有贴出结果的命令不补造输出。地址、断点编号和源码行号属于本次构建，不应直接套用到其他构建。

## 一、题目一要完成什么

理解 QEMU 中与地址翻译有关的源码，记录关键调用路径和分支，并实际观察一条访存指令访问的虚拟地址如何被翻译为物理地址。

本次选择 `memset()` 清理 BSS 时的一条存储指令：

```asm
sb a1,-1(a5)
```

观察过程为：选定写入指令 → 计算目标虚拟地址 → 在 QEMU 中捕获该访问 → 查询页表 → 得到物理地址 → 保存 TLB 映射 → 完成写入并读回。

## 二、三个终端及本次环境

| 终端 | 程序 | 本次作用 |
| --- | --- | --- |
| 终端一 | QEMU | 运行模拟的 RISC-V 系统，显示内核输出 |
| 终端二 | 宿主机 GDB，启动命令为 `sudo gdb` | 调试 QEMU 的 C 代码 |
| 终端三 | RISC-V GDB，通过 `make gdb` 连接 | 调试 ucore，执行和查看 RISC-V 指令 |

本次调试已经启动三个终端，后续没有重新编译内核。

```text
工作目录：/home/viewfinder/OS/ucore-labs/lab2/code
QEMU：/home/viewfinder/qemu-4.1.1/riscv64-softmmu/qemu-system-riscv64
QEMU 源码：/home/viewfinder/qemu-4.1.1/
内核 ELF：bin/kernel
内核镜像：bin/ucore.img
客户机 GDB 连接端口：1234
```

当前 Makefile 的 `debug` 目标使用以下形式启动：

```bash
qemu-system-riscv64 \
  -machine virt \
  -nographic \
  -bios default \
  -device loader,file=bin/ucore.img,addr=0x80200000 \
  -s -S
```

`-s` 开启默认 1234 端口的 GDB 接口，`-S` 让客户机等待调试器。这里只说明已有会话的启动方式，不表示本次记录中重新执行了一遍启动命令。

## 三、开始实操前的对话：先操作哪个终端

用户要求：

> 你光说我听不懂，来实操一下，你一步一步告诉我第一题应该怎么做

随后用户强调：

> 你从操作终端二开始，操作终端三前需要先操作终端二吗

操作说明：先保证终端二已允许 QEMU 继续工作。如果终端二停在 `(gdb)`，输入：

```gdb
continue
```

终端二显示 `Continuing.` 后保持原样，再操作终端三。如果终端二本来就在运行，不需要重复输入。

终端二显示 `Continuing.`，终端三同时显示 `(gdb)`，可以是正常状态：QEMU 程序可以工作，但内核仍停在客户机断点处，等待终端三命令。

## 四、第一次等待断点失败：内核已经经过入口

### 4.1 在终端三设置入口断点

指导操作：

```gdb
hbreak *kern_init
continue
```

用户反馈：

> 停不下来

这里不能直接认为断点或 GDB 出错。检查发现 QEMU 仍在运行，没有被终端二暂停，于是先让用户查看内核当前位置。

### 4.2 终端三暂停并查看当前指令

操作：在终端三按一次 `Ctrl+C`，出现 `(gdb)` 后输入：

```gdb
x/i $pc
```

用户实际输出：

```text
(gdb) x/i $pc
=> 0xffffffffc0200118 <kern_init+64>:
    j   0xffffffffc0200118 <kern_init+64>
```

解释：这条指令一直跳回自己，内核已经进入初始化结束后的等待循环。此时再等待 `kern_init` 开头的断点，不会重新遇到它。

这一步暴露了操作顺序的问题：设置入口断点之前，应先确认内核是否已经执行过入口。`continue` 从当前位置继续，不会从头重跑。

### 4.3 保留调试连接，重置客户机

终端二保持运行，终端三操作：

```gdb
monitor system_reset
continue
```

`monitor system_reset` 让模拟的机器重新启动；保留此前设置的入口断点。该命令没有单独贴出输出，随后实际命中 `kern_init` 的记录如下。

用户实际输出：

```text
(gdb) c
Continuing.

Breakpoint 1, kern_init () at kern/init/init.c:31
31          memset(edata, 0, end - edata);
(gdb) x/12i $pc
=> 0xffffffffc02000d8 <kern_init>:      auipc   a0,0xc
   0xffffffffc02000dc <kern_init+4>:
    addi        a0,a0,-184
   0xffffffffc02000e0 <kern_init+8>:    auipc   a2,0x196
   0xffffffffc02000e4 <kern_init+12>:
    addi        a2,a2,-1616
   0xffffffffc02000e8 <kern_init+16>:
    addi        sp,sp,-16
   0xffffffffc02000ea <kern_init+18>:   sub     a2,a2,a0
   0xffffffffc02000ec <kern_init+20>:   li      a1,0
```

用户随后贴出反汇编的后半部分：

```text
   0xffffffffc02000ee <kern_init+22>:   sd      ra,8(sp)
   0xffffffffc02000f0 <kern_init+24>:   jal     ra,0xffffffffc0205d16 <memset>
   0xffffffffc02000f4 <kern_init+28>:   jal     ra,0xffffffffc0200228 <dtb_init>
   0xffffffffc02000f8 <kern_init+32>:   jal     ra,0xffffffffc020021e <cons_init>
   0xffffffffc02000fc <kern_init+36>:   auipc   a0,0x6
```

输出过程曾出现分页提示。提示中的 `c` 表示继续显示剩余文本，不是让内核继续执行。后面使用 `set pagination off` 关闭分页。

## 五、关于两个 `continue` 的关键问答

用户提问：

> 我有问题，gdb2和gdb到底哪个控制程序进行？两个都执行continue，到底哪个控制程序进行？程序不会一直循环进行吗

答复整理：两个 GDB 都能造成暂停。只有两个都允许继续，内核才能向下执行。

1. 终端三把内核停住后，终端二输入 `continue`，只是允许 QEMU 程序工作，内核仍等待终端三放行。
2. 终端三再输入 `continue` 或 `si`，QEMU 开始完成对应的客户机执行。
3. 如果遇到终端二的断点，QEMU 被暂停，终端三正在等待的执行也就暂时无法完成。
4. 此时在终端二继续即可，不需要再向终端三重复发一次执行命令。
5. 如果遇到终端三的断点，则在终端三继续，终端二保持运行。

实际操作规则是：哪一个 GDB 因断点停住，就在哪一个里面继续，另一个保持原样。

没有遇到断点时，`continue` 会让程序持续执行。本次内核最后进入了自己的等待循环，所以入口断点设置晚了就等不到。两个 `continue` 都不是重新从头启动程序的命令。

## 六、终端三：进入 `memset`，选择写入指令

在终端三设置临时断点并继续：

```gdb
tbreak memset
continue
x/10i $pc
info registers a0 a1 a2
```

用户实际输出：

```text
(gdb) tbreak memset

    Temporary breakpoint 2 at 0xffffffffc0205d16: file libs/string.c, line 276.
(gdb) c
Continuing.

Temporary breakpoint 2, memset (
    s=0xffffffffc020c020 <check_free>,
    c=c@entry=0 '\000', n=1612400) at libs/string.c:276
276         while (n -- > 0) {
(gdb) x/10i $pc
=> 0xffffffffc0205d16 <memset>:
    beqz        a2,0xffffffffc0205d26 <memset+16>
   0xffffffffc0205d18 <memset+2>:       add     a2,a2,a0
   0xffffffffc0205d1a <memset+4>:       mv      a5,a0
   0xffffffffc0205d1c <memset+6>:       addi    a5,a5,1
   0xffffffffc0205d1e <memset+8>:
    sb  a1,-1(a5)
   0xffffffffc0205d22 <memset+12>:
    bne a5,a2,0xffffffffc0205d1c <memset+6>
   0xffffffffc0205d26 <memset+16>:      ret
   0xffffffffc0205d28:  0x63657053
   0xffffffffc0205d2c:  addi    sp,sp,208
   0xffffffffc0205d2e:  fld     fa1,192(s0)
(gdb) info registers a0 a1 a2
a0             0xffffffffc020c020       -1071595488
a1             0x0      0
a2             0x189a70 1612400
```

`ret` 后面列出的内容不属于需要继续分析的 `memset` 指令序列。本次选择的是函数内部的 `sb`。

参数含义：从 `a0 = 0xffffffffc020c020` 开始，把 `a2 = 1612400` 字节填为 `a1 = 0`。

指导终端三执行：

```gdb
si 4
x/i $pc
p/x $a5 - 1
```

目的：执行前四条准备指令，停在 `0xffffffffc0205d1e` 的 `sb` 前。此时 `a5` 已递增为 `0xffffffffc020c021`，写入地址为 `a5 - 1 = 0xffffffffc020c020`。

这三条没有单独贴出输出；随后终端二实际捕获到了完全相同地址的一字节写访问。

## 七、终端二：捕获这次写入

### 7.1 设置条件断点，再交回终端三执行

在终端二按 `Ctrl+C`，出现 `(gdb)` 后设置：

```gdb
break get_physical_address if addr == 0xffffffffc020c020 && access_type == 1
continue
```

这里 `access_type == 1` 对应写访问，条件用于排除其他地址或访问类型。

然后回到终端三，只输入一次：

```gdb
si
```

终端三开始执行 `sb`；QEMU 在处理这次写入时命中终端二的条件断点。用户贴出的终端二输出：

```text
(gdb) c
Continuing.
[Switching to Thread 0x7bfeb5ffe6c0 (LWP 70377)]

Thread 2 "qemu-system-ris" hit Breakpoint 1, get_physical_address (env=0x5e5a29827d20, physical=0x7bfeb5ffd2a0,
    prot=0x7bfeb5ffd294, addr=18446744072637956128,
    access_type=1, mmu_idx=1)
    at /home/viewfinder/qemu-4.1.1/target/riscv/cpu_helper.c:158
158     {
```

这时终端三的 `si` 尚未完成，等待终端二继续推进 QEMU。

### 7.2 核对输入地址、页表设置和调用路径

终端二操作：

```gdb
p/x addr
p/x env->satp
bt 6
```

用户实际输出：

```text
(gdb) p/x addr
$1 = 0xffffffffc020c020
(gdb) p/x env->satp
$2 = 0x800000000008020b
(gdb) bt 6
#0  get_physical_address (env=0x5e5a29827d20,
    physical=0x7bfeb5ffd2a0, prot=0x7bfeb5ffd294,
    addr=18446744072637956128, access_type=1, mmu_idx=1)
    at /home/viewfinder/qemu-4.1.1/target/riscv/cpu_helper.c:158
#1  0x00005e59f5389f4f in riscv_cpu_tlb_fill (
    cs=0x5e5a2981f310, address=18446744072637956128,
    size=1, access_type=MMU_DATA_STORE, mmu_idx=1,
    probe=false, retaddr=136333905359171)
    at /home/viewfinder/qemu-4.1.1/target/riscv/cpu_helper.c:451
#2  0x00005e59f52d01df in tlb_fill (cpu=0x5e5a2981f310,
    addr=18446744072637956128, size=1,
    access_type=MMU_DATA_STORE, mmu_idx=1,
    retaddr=136333905359171)
    at /home/viewfinder/qemu-4.1.1/accel/tcg/cputlb.c:878
#3  0x00005e59f52d431d in store_helper (
    big_endian=false, size=1, retaddr=136333905359171,
    oi=1, val=0, addr=18446744072637956128,
    env=0x5e5a29827d20)
    at /home/viewfinder/qemu-4.1.1/accel/tcg/cputlb.c:1522
#4  helper_ret_stb_mmu (env=0x5e5a29827d20,
    addr=18446744072637956128, val=0 '\000', oi=1,
    retaddr=136333905359171)
    at /home/viewfinder/qemu-4.1.1/accel/tcg/cputlb.c:1642
#5  0x00007bfeb5fff143 in code_gen_buffer ()
(More stack frames follow...)
```

调用栈中 `#0` 是当前函数，调用方向由较大的编号向较小的编号读取：

```text
code_gen_buffer
  → helper_ret_stb_mmu / store_helper
  → tlb_fill
  → riscv_cpu_tlb_fill
  → get_physical_address
```

本次调用栈显示进入了写访问的 TLB 未命中处理和地址翻译路径。`size=1`、`val=0` 与选中的单字节写零指令相符。

## 八、终端二：找到根页表

关闭分页，执行到读取完 `satp` 并准备选择分页模式的位置：

```gdb
set pagination off
until 187
p/x base
p/x (env->satp >> 60)
```

`until` 让中间代码正常执行，直到指定位置，并不是直接修改 PC 跳过代码。

用户实际输出：

```text
(gdb) until 187
get_physical_address (env=0x5e5a29827d20,
    physical=0x7bfeb5ffd2a0, prot=0x7bfeb5ffd294,
    addr=18446744072637956128, access_type=1, mmu_idx=1)
    at /home/viewfinder/qemu-4.1.1/target/riscv/cpu_helper.c:187
187             switch (vm) {
(gdb) p/x base
$3 = 0x8020b000
(gdb) p/x (env->satp >> 60)
$4 = 0x8
```

关键代码：

```c
base = get_field(env->satp, SATP_PPN) << PGSHIFT;
vm = get_field(env->satp, SATP_MODE);
```

本次 `satp = 0x800000000008020b`，MODE 为 8，即 Sv39；根页表页号为 `0x8020b`，乘以 4096 后得到根页表物理地址 `0x8020b000`。

## 九、终端二：选中并读取第 511 项

操作：

```gdb
until 256
p idx
p/x pte_addr
p/x pte
```

`until 256` 停在检查 PTE 有效性的代码处，此时该项已被读入变量。

用户实际输出：

```text
(gdb) p idx
$5 = 511
(gdb) p/x pte_addr
$6 = 0x8020bff8
(gdb) p/x pte
$7 = 0x200000cf
```

计算过程：

```text
根层索引 = (VA >> 30) & 0x1ff = 511
每个页表项大小 = 8 字节
表项物理地址 = 0x8020b000 + 511 × 8 = 0x8020bff8
实际读出的 PTE = 0x200000cf
```

对应源码先计算 `idx`、`pte_addr`，再通过 `ldq_phys()` 从客户机物理内存读取 8 字节表项，并计算 `ppn = pte >> PTE_PPN_SHIFT`。

## 十、终端二：检查表项类型和写入权限

指导操作：

```gdb
p/x (pte & 0x1)
p/x (pte & 0xe)
until 291
p/x ppn
```

第一条检查 V 位；用户没有单独贴出其输出。第二条检查读、写、执行位，实际输出如下：

```text
(gdb) p/x (pte & 0xe)
$9 = 0xe
(gdb) until 291
get_physical_address (env=0x5e5a29827d20,
    physical=0x7bfeb5ffd2a0, prot=0x7bfeb5ffd294,
    addr=18446744072637956128, access_type=1, mmu_idx=1)
    at /home/viewfinder/qemu-4.1.1/target/riscv/cpu_helper.c:291
291                 target_ulong updated_pte = pte | PTE_A |
(gdb) p/x ppn
$10 = 0x80000
```

本次 PTE 的 V、R、W、X、A、D 均为 1，U 为 0。这一项是合法叶项，已经直接描述物理内存映射，不需要再进入下一层页表。

能执行到第 291 行，也表明实际路径通过了此前的有效性、叶项合法性、特权级、大页对齐和本次写入权限检查。

需要理解的关键分支为：

```c
if (!(pte & PTE_V)) {
    return TRANSLATE_FAIL;
} else if (!(pte & (PTE_R | PTE_W | PTE_X))) {
    base = ppn << PGSHIFT;  // 指向下级页表
}
```

当前 PTE 有读写执行位，所以没有进入“取下级页表地址”的分支。后面还会拒绝非法标志组合、不允许的访问或未对齐大页；这些失败分支在本次成功访问中没有被触发。

## 十一、中途问答：为什么不操作终端三，终端二还可以继续

用户提问：

> 我还有个问题，刚才一直没有执行终端3，为什么终端二可以一直读取数据，这个时候数据已经被装载完毕了吗

答复整理：终端三之前输入的 `si` 尚未执行完。QEMU 正在处理这一次写入，而终端二控制的是处理过程中的 QEMU 代码。

- `p/x ppn` 只查看已经存在的变量，不推进程序。
- `until 256`、`until 291` 会让 QEMU 执行中间的代码，因此会读取内存、计算并更新变量。
- 终端三不需要再发一次命令；它一直在等待同一次 `si` 完成。

当前几类内容的状态不同：

| 内容 | 此时的状态 |
| --- | --- |
| 启动页表 | 启动时已经位于内存中 |
| `pte` | QEMU 已从页表中读取，值为 `0x200000cf` |
| `ppn` | 已根据 PTE 计算，值为 `0x80000` |
| 目标字节写入 | 当前仍处于处理中，尚未完成这次 `sb` |

因此不能把“已经能查看变量”理解为“整个写入已经执行完”。我们观察的是一条指令执行过程的中间状态。

## 十二、终端二：算出最终物理地址

操作：

```gdb
until 334
next
p/x *physical
p/x (addr & 0xfff)
p/x (*physical | (addr & 0xfff))
```

第 334 行是：

```c
*physical = (ppn | (vpn & ((1L << ptshift) - 1))) << PGSHIFT;
```

这里需要合入大页内的低位虚拟页号；不能仅把 `ppn << 12` 当成本次访问的最终地址。

用户实际输出：

```text
(gdb) next
337                 if ((pte & PTE_R) || ((pte & PTE_X) && mxr)) {
(gdb) p/x *physical
$11 = 0x8020c000
(gdb) p/x (addr & 0xfff)
$12 = 0x20
(gdb) p/x (*physical | (addr & 0xfff))
$13 = 0x8020c020
```

`*physical` 是此次访问所在的 4 KiB 物理页起点 `0x8020c000`；页内偏移为 `0x20`，最终字节物理地址为 `0x8020c020`。

这一结果也能用当前直接映射偏移独立核对：

```text
0xffffffffc020c020 - 0xffffffff40000000 = 0x8020c020
```

### 问答：这里为什么用 `next`，不用 `si`

用户提问：

> 另外回答一下，为什么这里用next不用si

答复整理：当前观察的是 QEMU 的 C 代码，目的是执行完一行地址计算后检查结果，所以使用 `next`。它按源代码行推进，并通常越过被调用函数内部。

`si` 每次推进一条机器指令。一行 C 代码可能对应多条机器指令，用 `si` 也可以观察，但会拆成更多步。

| 命令所在位置 | 观察到的执行单位 |
| --- | --- |
| 终端二的 `next` | QEMU 的 C 源码行 |
| 终端二的 `si` | QEMU 在宿主机上执行的机器指令 |
| 终端三的 `si` | 模拟的 RISC-V CPU 执行的指令，例如 `sb` |

## 十三、终端二：地址翻译函数返回成功

操作：

```gdb
finish
```

作用：执行完当前 `get_physical_address()`，返回到调用者。

用户实际输出：

```text
(gdb) finish
Run till exit from #0  get_physical_address (
    env=0x5e5a29827d20, physical=0x7bfeb5ffd2a0,
    prot=0x7bfeb5ffd294, addr=18446744072637956128,
    access_type=1, mmu_idx=1)
    at /home/viewfinder/qemu-4.1.1/target/riscv/cpu_helper.c:337
0x00005e59f5389f4f in riscv_cpu_tlb_fill (
    cs=0x5e5a2981f310, address=18446744072637956128,
    size=1, access_type=MMU_DATA_STORE, mmu_idx=1,
    probe=false, retaddr=136333905359171)
    at /home/viewfinder/qemu-4.1.1/target/riscv/cpu_helper.c:451
451         ret = get_physical_address(env, &pa, &prot, address, access_type, mmu_idx);
Value returned is $14 = 0
```

返回值 `0` 对应翻译成功。随后在调用者中核对结果：

```text
(gdb) p/x pa
$15 = 0x8020c000
(gdb) p prot
$16 = 7
```

`prot = 7` 表示本次生成的权限允许读、写、执行。此时地址翻译已经完成，整条存储指令仍没有全部完成。

## 十四、终端二：观察 TLB 回填

操作：

```gdb
tbreak tlb_set_page if vaddr == 0xffffffffc020c000
continue
info args
```

用户实际输出：

```text
(gdb) tbreak tlb_set_page if vaddr == 0xffffffffc020c000
Temporary breakpoint 2 at 0x5e59f52d00d4: file /home/viewfinder/qemu-4.1.1/accel/tcg/cputlb.c, line 847.
(gdb) c
Continuing.

Thread 2 "qemu-system-ris" hit Temporary breakpoint 2, tlb_set_page (cpu=0x5e5a2981f310,
    vaddr=18446744072637956096, paddr=2149629952,
    prot=7, mmu_idx=1, size=4096)
    at /home/viewfinder/qemu-4.1.1/accel/tcg/cputlb.c:847
847         tlb_set_page_with_attrs(cpu, vaddr, paddr, MEMTXATTRS_UNSPECIFIED,
(gdb) info args
cpu = 0x5e5a2981f310
vaddr = 18446744072637956096
paddr = 2149629952
prot = 7
mmu_idx = 1
size = 4096
```

将地址转换成十六进制后：

| 参数 | 实际含义 |
| --- | --- |
| `vaddr = 0xffffffffc020c000` | 本次缓存的虚拟页起点 |
| `paddr = 0x8020c000` | 对应物理页起点 |
| `prot = 7` | 读、写、执行权限 |
| `mmu_idx = 1` | 本次 S 模式访问使用的上下文 |
| `size = 4096` | 本次软件 TLB 回填的页大小 |

启动页表使用根层 1 GiB 叶项，本次 QEMU 软件 TLB 回填参数仍为 4 KiB。映射叶项的大小与这里的软件缓存处理单位不应混淆。

## 十五、回到终端三：确认写入完成

指导先在终端二执行：

```gdb
finish
continue
```

先完成 TLB 保存，再允许 QEMU 继续处理剩下的写入过程。上述两条的输出没有单独贴出；随后终端三已经结束此前等待的 `si`，实际观察如下。

终端三操作：

```gdb
x/i $pc
x/1bx 0xffffffffc020c020
```

用户实际输出：

```text
(gdb) x/i $pc
=> 0xffffffffc0205d22 <memset+12>:
    bne a5,a2,0xffffffffc0205d1c <memset+6>
(gdb) x/1bx 0xffffffffc020c020
0xffffffffc020c020 <check_free>:        0x00
```

PC 从 `sb` 移到了下一条 `bne`，表明该存储指令已经执行完；目标位置读回 `0x00`，符合写零预期。本次未记录写入前的非零旧值，不将读回零解释为已经演示了从非零到零的变化。

这时一次完整的客户机单步完成。本轮对话到此停止单步观察，没有记录后续剩余 `memset()` 循环的执行。

## 十六、第一题的完整路径与关键分支

### 16.1 一次写入的时间顺序

```text
终端三：si，执行 sb a1,-1(a5)
  ↓
QEMU：store_helper 处理一字节写零
  ↓
TLB 未命中路径：tlb_fill → riscv_cpu_tlb_fill
  ↓
get_physical_address
  ├─ 从 satp 得到 Sv39 模式和根页表地址
  ├─ 取根层索引 511，读取 PTE 0x200000cf
  ├─ 判断为合法叶项，通过权限与对齐检查
  └─ 算出物理页起点 0x8020c000，返回成功
  ↓
riscv_cpu_tlb_fill 调用 tlb_set_page
  ↓
保存虚拟页和物理页的对应关系
  ↓
QEMU 完成物理地址 0x8020c020 的字节写入
  ↓
终端三的 si 结束，PC 位于下一条 bne
```

`get_physical_address()` 和 `tlb_set_page()` 是本次先后经过的两个阶段，后者由返回后的调用者调用，不是前者内部直接调用。

### 16.2 源码分支与本次路径

| 判断 | 源码中的作用 | 本次情况 |
| --- | --- | --- |
| 有效模式是否需要页表翻译 | M 模式普通路径等情况可直接使用地址 | 本次为 S 模式，进入分页处理 |
| `satp.MODE` | 选择 Bare、Sv39 等模式 | 值为 8，使用 Sv39 |
| 虚拟地址是否规范 | 检查 Sv39 高位符号扩展 | 本次通过 |
| PTE 的 V 位 | 无效项不能继续访问 | 本次有效 |
| PTE 的 R/W/X 是否全零 | 全零表示继续访问下级页表 | 本次为 `0xe`，是叶项，不进入下级 |
| 标志组合、特权级、大页对齐 | 拒绝不合法映射 | 本次通过 |
| 写权限 | 写访问必须被允许 | 本次 W 位为 1，通过 |
| A/D 状态 | 需要时更新访问和脏标记 | 本次 PTE 已设置 A/D |
| 翻译返回结果 | 成功则继续处理权限和 TLB 回填 | 返回 0，随后到达 `tlb_set_page` |

本次实测的是一条合法写访问的成功路径。其他失败分支依据对应源码解释，未声称已逐个触发。

### 16.3 最终结果

| 观察内容 | 实测值 |
| --- | --- |
| 写入指令地址 | `0xffffffffc0205d1e` |
| 写入指令 | `sb a1,-1(a5)` |
| 写入内容 | 单字节 `0` |
| 访问的虚拟地址 | `0xffffffffc020c020` |
| `satp` | `0x800000000008020b` |
| 根页表物理地址 | `0x8020b000` |
| 根层索引 | 511 |
| PTE 物理地址 | `0x8020bff8` |
| PTE 内容 | `0x200000cf` |
| 物理页起点 | `0x8020c000` |
| 页内偏移 | `0x20` |
| 最终物理地址 | `0x8020c020` |
| 翻译结果 | 返回 0，成功 |
| TLB 回填 | 虚拟页对应物理页，权限 7，大小 4096 字节 |
| 存储后 PC | `0xffffffffc0205d22` |
| 目标位置读回 | `0x00` |

## 十七、这次实操对两个 GDB 关系的验证

用户起初不理解两个 GDB 如何配合。通过本次操作，可以对应到具体事实：

1. 终端三只发起了一次要观察的 `si`。
2. 终端二在这条指令的地址翻译过程中停住 QEMU。
3. 之后一直在终端二执行 `until`、`next`、`finish`，逐段推进同一次访问。
4. 终端三没有重复执行 `si`，始终等待。
5. 最后终端二放行，终端三才显示下一条指令。

所以两个 GDB 没有分别发起两次同样的内存写入。一个控制客户机执行请求，另一个检查并推进 QEMU 完成该请求的内部过程。

## 十八、结束记录

用户要求：

> 先结束，然后把我们刚才关于题目一对话的内容和流程保存在report中，命名为gdb_test_1

结束前只读检查发现：两个 GDB 已退出，剩余本次 `make debug` 启动的 QEMU 仍在运行。核对工作目录和镜像参数后，向该 QEMU 进程（PID 70375）发送正常退出信号，并确认它已经结束。

本次调试会话已结束，记录保存为 `lab2/report/gdb_test_1.md`。未修改实验源码或主报告。
