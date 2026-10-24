
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000c297          	auipc	t0,0xc
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020c000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000c297          	auipc	t0,0xc
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020c008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020b2b7          	lui	t0,0xc020b
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00006517          	auipc	a0,0x6
ffffffffc0200050:	cdc50513          	addi	a0,a0,-804 # ffffffffc0205d28 <etext>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0fe000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00006517          	auipc	a0,0x6
ffffffffc0200066:	ce650513          	addi	a0,a0,-794 # ffffffffc0205d48 <etext+0x20>
ffffffffc020006a:	0ea000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00006597          	auipc	a1,0x6
ffffffffc0200072:	cba58593          	addi	a1,a1,-838 # ffffffffc0205d28 <etext>
ffffffffc0200076:	00006517          	auipc	a0,0x6
ffffffffc020007a:	cf250513          	addi	a0,a0,-782 # ffffffffc0205d68 <etext+0x40>
ffffffffc020007e:	0d6000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	0000c597          	auipc	a1,0xc
ffffffffc0200086:	f9e58593          	addi	a1,a1,-98 # ffffffffc020c020 <check_free>
ffffffffc020008a:	00006517          	auipc	a0,0x6
ffffffffc020008e:	cfe50513          	addi	a0,a0,-770 # ffffffffc0205d88 <etext+0x60>
ffffffffc0200092:	0c2000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00196597          	auipc	a1,0x196
ffffffffc020009a:	9fa58593          	addi	a1,a1,-1542 # ffffffffc0395a90 <end>
ffffffffc020009e:	00006517          	auipc	a0,0x6
ffffffffc02000a2:	d0a50513          	addi	a0,a0,-758 # ffffffffc0205da8 <etext+0x80>
ffffffffc02000a6:	0ae000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00196597          	auipc	a1,0x196
ffffffffc02000ae:	de558593          	addi	a1,a1,-539 # ffffffffc0395e8f <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00006517          	auipc	a0,0x6
ffffffffc02000d0:	cfc50513          	addi	a0,a0,-772 # ffffffffc0205dc8 <etext+0xa0>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a8bd                	j	ffffffffc0200154 <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	0000c517          	auipc	a0,0xc
ffffffffc02000dc:	f4850513          	addi	a0,a0,-184 # ffffffffc020c020 <check_free>
ffffffffc02000e0:	00196617          	auipc	a2,0x196
ffffffffc02000e4:	9b060613          	addi	a2,a2,-1616 # ffffffffc0395a90 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	427050ef          	jal	ra,ffffffffc0205d16 <memset>
    dtb_init();
ffffffffc02000f4:	134000ef          	jal	ra,ffffffffc0200228 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	126000ef          	jal	ra,ffffffffc020021e <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00006517          	auipc	a0,0x6
ffffffffc0200100:	cfc50513          	addi	a0,a0,-772 # ffffffffc0205df8 <etext+0xd0>
ffffffffc0200104:	086000ef          	jal	ra,ffffffffc020018a <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	3a9020ef          	jal	ra,ffffffffc0202cb4 <pmm_init>
    slub_init();
ffffffffc0200110:	1c8040ef          	jal	ra,ffffffffc02042d8 <slub_init>
    slub_check();
ffffffffc0200114:	2a2040ef          	jal	ra,ffffffffc02043b6 <slub_check>

    /* do nothing */
    while (1)
ffffffffc0200118:	a001                	j	ffffffffc0200118 <kern_init+0x40>

ffffffffc020011a <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020011a:	1141                	addi	sp,sp,-16
ffffffffc020011c:	e022                	sd	s0,0(sp)
ffffffffc020011e:	e406                	sd	ra,8(sp)
ffffffffc0200120:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200122:	0fe000ef          	jal	ra,ffffffffc0200220 <cons_putc>
    (*cnt) ++;
ffffffffc0200126:	401c                	lw	a5,0(s0)
}
ffffffffc0200128:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc020012a:	2785                	addiw	a5,a5,1
ffffffffc020012c:	c01c                	sw	a5,0(s0)
}
ffffffffc020012e:	6402                	ld	s0,0(sp)
ffffffffc0200130:	0141                	addi	sp,sp,16
ffffffffc0200132:	8082                	ret

ffffffffc0200134 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200134:	1101                	addi	sp,sp,-32
ffffffffc0200136:	862a                	mv	a2,a0
ffffffffc0200138:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013a:	00000517          	auipc	a0,0x0
ffffffffc020013e:	fe050513          	addi	a0,a0,-32 # ffffffffc020011a <cputch>
ffffffffc0200142:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200144:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200146:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200148:	7b8050ef          	jal	ra,ffffffffc0205900 <vprintfmt>
    return cnt;
}
ffffffffc020014c:	60e2                	ld	ra,24(sp)
ffffffffc020014e:	4532                	lw	a0,12(sp)
ffffffffc0200150:	6105                	addi	sp,sp,32
ffffffffc0200152:	8082                	ret

ffffffffc0200154 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200154:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200156:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc020015a:	8e2a                	mv	t3,a0
ffffffffc020015c:	f42e                	sd	a1,40(sp)
ffffffffc020015e:	f832                	sd	a2,48(sp)
ffffffffc0200160:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200162:	00000517          	auipc	a0,0x0
ffffffffc0200166:	fb850513          	addi	a0,a0,-72 # ffffffffc020011a <cputch>
ffffffffc020016a:	004c                	addi	a1,sp,4
ffffffffc020016c:	869a                	mv	a3,t1
ffffffffc020016e:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200170:	ec06                	sd	ra,24(sp)
ffffffffc0200172:	e0ba                	sd	a4,64(sp)
ffffffffc0200174:	e4be                	sd	a5,72(sp)
ffffffffc0200176:	e8c2                	sd	a6,80(sp)
ffffffffc0200178:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc020017a:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc020017c:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020017e:	782050ef          	jal	ra,ffffffffc0205900 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200182:	60e2                	ld	ra,24(sp)
ffffffffc0200184:	4512                	lw	a0,4(sp)
ffffffffc0200186:	6125                	addi	sp,sp,96
ffffffffc0200188:	8082                	ret

ffffffffc020018a <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020018a:	1101                	addi	sp,sp,-32
ffffffffc020018c:	e822                	sd	s0,16(sp)
ffffffffc020018e:	ec06                	sd	ra,24(sp)
ffffffffc0200190:	e426                	sd	s1,8(sp)
ffffffffc0200192:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200194:	00054503          	lbu	a0,0(a0)
ffffffffc0200198:	c51d                	beqz	a0,ffffffffc02001c6 <cputs+0x3c>
ffffffffc020019a:	0405                	addi	s0,s0,1
ffffffffc020019c:	4485                	li	s1,1
ffffffffc020019e:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001a0:	080000ef          	jal	ra,ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001a4:	00044503          	lbu	a0,0(s0)
ffffffffc02001a8:	008487bb          	addw	a5,s1,s0
ffffffffc02001ac:	0405                	addi	s0,s0,1
ffffffffc02001ae:	f96d                	bnez	a0,ffffffffc02001a0 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001b0:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001b4:	4529                	li	a0,10
ffffffffc02001b6:	06a000ef          	jal	ra,ffffffffc0200220 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001ba:	60e2                	ld	ra,24(sp)
ffffffffc02001bc:	8522                	mv	a0,s0
ffffffffc02001be:	6442                	ld	s0,16(sp)
ffffffffc02001c0:	64a2                	ld	s1,8(sp)
ffffffffc02001c2:	6105                	addi	sp,sp,32
ffffffffc02001c4:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001c6:	4405                	li	s0,1
ffffffffc02001c8:	b7f5                	j	ffffffffc02001b4 <cputs+0x2a>

ffffffffc02001ca <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001ca:	00196317          	auipc	t1,0x196
ffffffffc02001ce:	86e30313          	addi	t1,t1,-1938 # ffffffffc0395a38 <is_panic>
ffffffffc02001d2:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d6:	715d                	addi	sp,sp,-80
ffffffffc02001d8:	ec06                	sd	ra,24(sp)
ffffffffc02001da:	e822                	sd	s0,16(sp)
ffffffffc02001dc:	f436                	sd	a3,40(sp)
ffffffffc02001de:	f83a                	sd	a4,48(sp)
ffffffffc02001e0:	fc3e                	sd	a5,56(sp)
ffffffffc02001e2:	e0c2                	sd	a6,64(sp)
ffffffffc02001e4:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e6:	000e0363          	beqz	t3,ffffffffc02001ec <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001ea:	a001                	j	ffffffffc02001ea <__panic+0x20>
    is_panic = 1;
ffffffffc02001ec:	4785                	li	a5,1
ffffffffc02001ee:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001f2:	8432                	mv	s0,a2
ffffffffc02001f4:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f6:	862e                	mv	a2,a1
ffffffffc02001f8:	85aa                	mv	a1,a0
ffffffffc02001fa:	00006517          	auipc	a0,0x6
ffffffffc02001fe:	c1e50513          	addi	a0,a0,-994 # ffffffffc0205e18 <etext+0xf0>
    va_start(ap, fmt);
ffffffffc0200202:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200204:	f51ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200208:	65a2                	ld	a1,8(sp)
ffffffffc020020a:	8522                	mv	a0,s0
ffffffffc020020c:	f29ff0ef          	jal	ra,ffffffffc0200134 <vcprintf>
    cprintf("\n");
ffffffffc0200210:	00006517          	auipc	a0,0x6
ffffffffc0200214:	be050513          	addi	a0,a0,-1056 # ffffffffc0205df0 <etext+0xc8>
ffffffffc0200218:	f3dff0ef          	jal	ra,ffffffffc0200154 <cprintf>
ffffffffc020021c:	b7f9                	j	ffffffffc02001ea <__panic+0x20>

ffffffffc020021e <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200220:	0ff57513          	zext.b	a0,a0
ffffffffc0200224:	25f0506f          	j	ffffffffc0205c82 <sbi_console_putchar>

ffffffffc0200228 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200228:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc020022a:	00006517          	auipc	a0,0x6
ffffffffc020022e:	c0e50513          	addi	a0,a0,-1010 # ffffffffc0205e38 <etext+0x110>
void dtb_init(void) {
ffffffffc0200232:	fc86                	sd	ra,120(sp)
ffffffffc0200234:	f8a2                	sd	s0,112(sp)
ffffffffc0200236:	e8d2                	sd	s4,80(sp)
ffffffffc0200238:	f4a6                	sd	s1,104(sp)
ffffffffc020023a:	f0ca                	sd	s2,96(sp)
ffffffffc020023c:	ecce                	sd	s3,88(sp)
ffffffffc020023e:	e4d6                	sd	s5,72(sp)
ffffffffc0200240:	e0da                	sd	s6,64(sp)
ffffffffc0200242:	fc5e                	sd	s7,56(sp)
ffffffffc0200244:	f862                	sd	s8,48(sp)
ffffffffc0200246:	f466                	sd	s9,40(sp)
ffffffffc0200248:	f06a                	sd	s10,32(sp)
ffffffffc020024a:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020024c:	f09ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200250:	0000c597          	auipc	a1,0xc
ffffffffc0200254:	db05b583          	ld	a1,-592(a1) # ffffffffc020c000 <boot_hartid>
ffffffffc0200258:	00006517          	auipc	a0,0x6
ffffffffc020025c:	bf050513          	addi	a0,a0,-1040 # ffffffffc0205e48 <etext+0x120>
ffffffffc0200260:	ef5ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200264:	0000c417          	auipc	s0,0xc
ffffffffc0200268:	da440413          	addi	s0,s0,-604 # ffffffffc020c008 <boot_dtb>
ffffffffc020026c:	600c                	ld	a1,0(s0)
ffffffffc020026e:	00006517          	auipc	a0,0x6
ffffffffc0200272:	bea50513          	addi	a0,a0,-1046 # ffffffffc0205e58 <etext+0x130>
ffffffffc0200276:	edfff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020027a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020027e:	00006517          	auipc	a0,0x6
ffffffffc0200282:	bf250513          	addi	a0,a0,-1038 # ffffffffc0205e70 <etext+0x148>
    if (boot_dtb == 0) {
ffffffffc0200286:	120a0463          	beqz	s4,ffffffffc02003ae <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020028a:	57f5                	li	a5,-3
ffffffffc020028c:	07fa                	slli	a5,a5,0x1e
ffffffffc020028e:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200292:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200294:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200298:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020029e:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002aa:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ae:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002b0:	8ec9                	or	a3,a3,a0
ffffffffc02002b2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002b6:	1b7d                	addi	s6,s6,-1
ffffffffc02002b8:	0167f7b3          	and	a5,a5,s6
ffffffffc02002bc:	8dd5                	or	a1,a1,a3
ffffffffc02002be:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002c0:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002c4:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002c6:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfd4a45d>
ffffffffc02002ca:	10f59163          	bne	a1,a5,ffffffffc02003cc <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002ce:	471c                	lw	a5,8(a4)
ffffffffc02002d0:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002d2:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d4:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d8:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002dc:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f8:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002fc:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002fe:	01146433          	or	s0,s0,a7
ffffffffc0200302:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200306:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020030a:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020030c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200310:	8c49                	or	s0,s0,a0
ffffffffc0200312:	0166f6b3          	and	a3,a3,s6
ffffffffc0200316:	00ca6a33          	or	s4,s4,a2
ffffffffc020031a:	0167f7b3          	and	a5,a5,s6
ffffffffc020031e:	8c55                	or	s0,s0,a3
ffffffffc0200320:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200324:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200326:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200328:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020032a:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020032e:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200330:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200332:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200336:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200338:	00006917          	auipc	s2,0x6
ffffffffc020033c:	b8890913          	addi	s2,s2,-1144 # ffffffffc0205ec0 <etext+0x198>
ffffffffc0200340:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200342:	4d91                	li	s11,4
ffffffffc0200344:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200346:	00006497          	auipc	s1,0x6
ffffffffc020034a:	b7248493          	addi	s1,s1,-1166 # ffffffffc0205eb8 <etext+0x190>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020034e:	000a2703          	lw	a4,0(s4)
ffffffffc0200352:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200356:	0087569b          	srliw	a3,a4,0x8
ffffffffc020035a:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200362:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200366:	0107571b          	srliw	a4,a4,0x10
ffffffffc020036a:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020036c:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200370:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200374:	8fd5                	or	a5,a5,a3
ffffffffc0200376:	00eb7733          	and	a4,s6,a4
ffffffffc020037a:	8fd9                	or	a5,a5,a4
ffffffffc020037c:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020037e:	09778c63          	beq	a5,s7,ffffffffc0200416 <dtb_init+0x1ee>
ffffffffc0200382:	00fbea63          	bltu	s7,a5,ffffffffc0200396 <dtb_init+0x16e>
ffffffffc0200386:	07a78663          	beq	a5,s10,ffffffffc02003f2 <dtb_init+0x1ca>
ffffffffc020038a:	4709                	li	a4,2
ffffffffc020038c:	00e79763          	bne	a5,a4,ffffffffc020039a <dtb_init+0x172>
ffffffffc0200390:	4c81                	li	s9,0
ffffffffc0200392:	8a56                	mv	s4,s5
ffffffffc0200394:	bf6d                	j	ffffffffc020034e <dtb_init+0x126>
ffffffffc0200396:	ffb78ee3          	beq	a5,s11,ffffffffc0200392 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020039a:	00006517          	auipc	a0,0x6
ffffffffc020039e:	b9e50513          	addi	a0,a0,-1122 # ffffffffc0205f38 <etext+0x210>
ffffffffc02003a2:	db3ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02003a6:	00006517          	auipc	a0,0x6
ffffffffc02003aa:	bca50513          	addi	a0,a0,-1078 # ffffffffc0205f70 <etext+0x248>
}
ffffffffc02003ae:	7446                	ld	s0,112(sp)
ffffffffc02003b0:	70e6                	ld	ra,120(sp)
ffffffffc02003b2:	74a6                	ld	s1,104(sp)
ffffffffc02003b4:	7906                	ld	s2,96(sp)
ffffffffc02003b6:	69e6                	ld	s3,88(sp)
ffffffffc02003b8:	6a46                	ld	s4,80(sp)
ffffffffc02003ba:	6aa6                	ld	s5,72(sp)
ffffffffc02003bc:	6b06                	ld	s6,64(sp)
ffffffffc02003be:	7be2                	ld	s7,56(sp)
ffffffffc02003c0:	7c42                	ld	s8,48(sp)
ffffffffc02003c2:	7ca2                	ld	s9,40(sp)
ffffffffc02003c4:	7d02                	ld	s10,32(sp)
ffffffffc02003c6:	6de2                	ld	s11,24(sp)
ffffffffc02003c8:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003ca:	b369                	j	ffffffffc0200154 <cprintf>
}
ffffffffc02003cc:	7446                	ld	s0,112(sp)
ffffffffc02003ce:	70e6                	ld	ra,120(sp)
ffffffffc02003d0:	74a6                	ld	s1,104(sp)
ffffffffc02003d2:	7906                	ld	s2,96(sp)
ffffffffc02003d4:	69e6                	ld	s3,88(sp)
ffffffffc02003d6:	6a46                	ld	s4,80(sp)
ffffffffc02003d8:	6aa6                	ld	s5,72(sp)
ffffffffc02003da:	6b06                	ld	s6,64(sp)
ffffffffc02003dc:	7be2                	ld	s7,56(sp)
ffffffffc02003de:	7c42                	ld	s8,48(sp)
ffffffffc02003e0:	7ca2                	ld	s9,40(sp)
ffffffffc02003e2:	7d02                	ld	s10,32(sp)
ffffffffc02003e4:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e6:	00006517          	auipc	a0,0x6
ffffffffc02003ea:	aaa50513          	addi	a0,a0,-1366 # ffffffffc0205e90 <etext+0x168>
}
ffffffffc02003ee:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003f0:	b395                	j	ffffffffc0200154 <cprintf>
                int name_len = strlen(name);
ffffffffc02003f2:	8556                	mv	a0,s5
ffffffffc02003f4:	0a9050ef          	jal	ra,ffffffffc0205c9c <strlen>
ffffffffc02003f8:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	4619                	li	a2,6
ffffffffc02003fc:	85a6                	mv	a1,s1
ffffffffc02003fe:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200400:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200402:	0ef050ef          	jal	ra,ffffffffc0205cf0 <strncmp>
ffffffffc0200406:	e111                	bnez	a0,ffffffffc020040a <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200408:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020040a:	0a91                	addi	s5,s5,4
ffffffffc020040c:	9ad2                	add	s5,s5,s4
ffffffffc020040e:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200412:	8a56                	mv	s4,s5
ffffffffc0200414:	bf2d                	j	ffffffffc020034e <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200416:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020041a:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020041e:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200422:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042a:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020042e:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200432:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200436:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020043a:	0087979b          	slliw	a5,a5,0x8
ffffffffc020043e:	00eaeab3          	or	s5,s5,a4
ffffffffc0200442:	00fb77b3          	and	a5,s6,a5
ffffffffc0200446:	00faeab3          	or	s5,s5,a5
ffffffffc020044a:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020044c:	000c9c63          	bnez	s9,ffffffffc0200464 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200450:	1a82                	slli	s5,s5,0x20
ffffffffc0200452:	00368793          	addi	a5,a3,3
ffffffffc0200456:	020ada93          	srli	s5,s5,0x20
ffffffffc020045a:	9abe                	add	s5,s5,a5
ffffffffc020045c:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200460:	8a56                	mv	s4,s5
ffffffffc0200462:	b5f5                	j	ffffffffc020034e <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200464:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200468:	85ca                	mv	a1,s2
ffffffffc020046a:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200470:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200474:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200478:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200480:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200482:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200486:	0087979b          	slliw	a5,a5,0x8
ffffffffc020048a:	8d59                	or	a0,a0,a4
ffffffffc020048c:	00fb77b3          	and	a5,s6,a5
ffffffffc0200490:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200492:	1502                	slli	a0,a0,0x20
ffffffffc0200494:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200496:	9522                	add	a0,a0,s0
ffffffffc0200498:	03b050ef          	jal	ra,ffffffffc0205cd2 <strcmp>
ffffffffc020049c:	66a2                	ld	a3,8(sp)
ffffffffc020049e:	f94d                	bnez	a0,ffffffffc0200450 <dtb_init+0x228>
ffffffffc02004a0:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200450 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02004a4:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a8:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004ac:	00006517          	auipc	a0,0x6
ffffffffc02004b0:	a1c50513          	addi	a0,a0,-1508 # ffffffffc0205ec8 <etext+0x1a0>
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b8:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004bc:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c0:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004c4:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004cc:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d0:	0187d693          	srli	a3,a5,0x18
ffffffffc02004d4:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d8:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004dc:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e0:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004e4:	010f6f33          	or	t5,t5,a6
ffffffffc02004e8:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004ec:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f4:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f8:	0186f6b3          	and	a3,a3,s8
ffffffffc02004fc:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200500:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200504:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200508:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020050c:	8361                	srli	a4,a4,0x18
ffffffffc020050e:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200512:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200516:	01e6e6b3          	or	a3,a3,t5
ffffffffc020051a:	00cb7633          	and	a2,s6,a2
ffffffffc020051e:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200522:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200526:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200532:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200536:	0088989b          	slliw	a7,a7,0x8
ffffffffc020053a:	011b78b3          	and	a7,s6,a7
ffffffffc020053e:	005eeeb3          	or	t4,t4,t0
ffffffffc0200542:	00c6e733          	or	a4,a3,a2
ffffffffc0200546:	006c6c33          	or	s8,s8,t1
ffffffffc020054a:	010b76b3          	and	a3,s6,a6
ffffffffc020054e:	00bb7b33          	and	s6,s6,a1
ffffffffc0200552:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200556:	016c6b33          	or	s6,s8,s6
ffffffffc020055a:	01146433          	or	s0,s0,a7
ffffffffc020055e:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200560:	1702                	slli	a4,a4,0x20
ffffffffc0200562:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200564:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200566:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200568:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020056a:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020056e:	0167eb33          	or	s6,a5,s6
ffffffffc0200572:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200574:	be1ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200578:	85a2                	mv	a1,s0
ffffffffc020057a:	00006517          	auipc	a0,0x6
ffffffffc020057e:	96e50513          	addi	a0,a0,-1682 # ffffffffc0205ee8 <etext+0x1c0>
ffffffffc0200582:	bd3ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200586:	014b5613          	srli	a2,s6,0x14
ffffffffc020058a:	85da                	mv	a1,s6
ffffffffc020058c:	00006517          	auipc	a0,0x6
ffffffffc0200590:	97450513          	addi	a0,a0,-1676 # ffffffffc0205f00 <etext+0x1d8>
ffffffffc0200594:	bc1ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200598:	008b05b3          	add	a1,s6,s0
ffffffffc020059c:	15fd                	addi	a1,a1,-1
ffffffffc020059e:	00006517          	auipc	a0,0x6
ffffffffc02005a2:	98250513          	addi	a0,a0,-1662 # ffffffffc0205f20 <etext+0x1f8>
ffffffffc02005a6:	bafff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005aa:	00006517          	auipc	a0,0x6
ffffffffc02005ae:	9c650513          	addi	a0,a0,-1594 # ffffffffc0205f70 <etext+0x248>
        memory_base = mem_base;
ffffffffc02005b2:	00195797          	auipc	a5,0x195
ffffffffc02005b6:	4887b723          	sd	s0,1166(a5) # ffffffffc0395a40 <memory_base>
        memory_size = mem_size;
ffffffffc02005ba:	00195797          	auipc	a5,0x195
ffffffffc02005be:	4967b723          	sd	s6,1166(a5) # ffffffffc0395a48 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005c2:	b3f5                	j	ffffffffc02003ae <dtb_init+0x186>

ffffffffc02005c4 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005c4:	00195517          	auipc	a0,0x195
ffffffffc02005c8:	47c53503          	ld	a0,1148(a0) # ffffffffc0395a40 <memory_base>
ffffffffc02005cc:	8082                	ret

ffffffffc02005ce <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005ce:	00195517          	auipc	a0,0x195
ffffffffc02005d2:	47a53503          	ld	a0,1146(a0) # ffffffffc0395a48 <memory_size>
ffffffffc02005d6:	8082                	ret

ffffffffc02005d8 <buddy_init>:
}

static void
buddy_init(void) {
    for (size_t order = 0; order < BUDDY_ORDERS; order++) {
        list_init(&buddy->free_list[order]);
ffffffffc02005d8:	0000c597          	auipc	a1,0xc
ffffffffc02005dc:	a385b583          	ld	a1,-1480(a1) # ffffffffc020c010 <buddy>
ffffffffc02005e0:	87ae                	mv	a5,a1
ffffffffc02005e2:	40058713          	addi	a4,a1,1024
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005e6:	e79c                	sd	a5,8(a5)
ffffffffc02005e8:	e39c                	sd	a5,0(a5)
    for (size_t order = 0; order < BUDDY_ORDERS; order++) {
ffffffffc02005ea:	07c1                	addi	a5,a5,16
ffffffffc02005ec:	fee79de3          	bne	a5,a4,ffffffffc02005e6 <buddy_init+0xe>
    }
    buddy->nr_free = buddy->nr_managed = 0;
ffffffffc02005f0:	4005b423          	sd	zero,1032(a1)
ffffffffc02005f4:	4005b023          	sd	zero,1024(a1)
    buddy->max_order = 0;
    while (buddy->max_order + 1 < BUDDY_ORDERS &&
ffffffffc02005f8:	4785                	li	a5,1
ffffffffc02005fa:	04000613          	li	a2,64
           ((size_t)1 << (buddy->max_order + 1)) <= BUDDY_PAGE_CAPACITY) {
ffffffffc02005fe:	4685                	li	a3,1
    while (buddy->max_order + 1 < BUDDY_ORDERS &&
ffffffffc0200600:	6521                	lui	a0,0x8
ffffffffc0200602:	883e                	mv	a6,a5
ffffffffc0200604:	0785                	addi	a5,a5,1
           ((size_t)1 << (buddy->max_order + 1)) <= BUDDY_PAGE_CAPACITY) {
ffffffffc0200606:	00f69733          	sll	a4,a3,a5
    while (buddy->max_order + 1 < BUDDY_ORDERS &&
ffffffffc020060a:	06c78663          	beq	a5,a2,ffffffffc0200676 <buddy_init+0x9e>
ffffffffc020060e:	fee57ae3          	bgeu	a0,a4,ffffffffc0200602 <buddy_init+0x2a>
ffffffffc0200612:	4105b823          	sd	a6,1040(a1)
        buddy->max_order++;
    }
    buddy->first_record = 0;
    for (size_t i = 0; i < BUDDY_PAGE_CAPACITY; i++) {
        buddy->owner[i] = buddy->managed[i] = 0;
ffffffffc0200616:	000a0537          	lui	a0,0xa0
ffffffffc020061a:	00a58733          	add	a4,a1,a0
    buddy->first_record = 0;
ffffffffc020061e:	4005ac23          	sw	zero,1048(a1)
        buddy->owner[i] = buddy->managed[i] = 0;
ffffffffc0200622:	000807b7          	lui	a5,0x80
ffffffffc0200626:	40070e23          	sb	zero,1052(a4)
ffffffffc020062a:	00f58733          	add	a4,a1,a5
ffffffffc020062e:	40072e23          	sw	zero,1052(a4)
        buddy->allocation[i].live = 0;
ffffffffc0200632:	42078793          	addi	a5,a5,1056 # 80420 <kern_entry-0xffffffffc017fbe0>
ffffffffc0200636:	00f58633          	add	a2,a1,a5
ffffffffc020063a:	4205a223          	sw	zero,1060(a1)
        buddy->allocation[i].next = i + 1 < BUDDY_PAGE_CAPACITY
ffffffffc020063e:	42858713          	addi	a4,a1,1064
        buddy->allocation[i].live = 0;
ffffffffc0200642:	4785                	li	a5,1
        buddy->owner[i] = buddy->managed[i] = 0;
ffffffffc0200644:	41c50513          	addi	a0,a0,1052 # a041c <kern_entry-0xffffffffc015fbe4>
        buddy->allocation[i].next = i + 1 < BUDDY_PAGE_CAPACITY
ffffffffc0200648:	6821                	lui	a6,0x8
        buddy->owner[i] = buddy->managed[i] = 0;
ffffffffc020064a:	00a786b3          	add	a3,a5,a0
        buddy->allocation[i].next = i + 1 < BUDDY_PAGE_CAPACITY
ffffffffc020064e:	c31c                	sw	a5,0(a4)
        buddy->owner[i] = buddy->managed[i] = 0;
ffffffffc0200650:	96ae                	add	a3,a3,a1
ffffffffc0200652:	00068023          	sb	zero,0(a3)
ffffffffc0200656:	00062023          	sw	zero,0(a2) # ff0000 <kern_entry-0xffffffffbf210000>
        buddy->allocation[i].live = 0;
ffffffffc020065a:	00072623          	sw	zero,12(a4)
        buddy->allocation[i].next = i + 1 < BUDDY_PAGE_CAPACITY
ffffffffc020065e:	0785                	addi	a5,a5,1
ffffffffc0200660:	0741                	addi	a4,a4,16
ffffffffc0200662:	0611                	addi	a2,a2,4
ffffffffc0200664:	ff0793e3          	bne	a5,a6,ffffffffc020064a <buddy_init+0x72>
ffffffffc0200668:	000807b7          	lui	a5,0x80
ffffffffc020066c:	95be                	add	a1,a1,a5
ffffffffc020066e:	57fd                	li	a5,-1
ffffffffc0200670:	40f5ac23          	sw	a5,1048(a1)
                                      ? i + 1 : BUDDY_NO_RECORD;
    }
}
ffffffffc0200674:	8082                	ret
ffffffffc0200676:	03f00793          	li	a5,63
ffffffffc020067a:	40f5b823          	sd	a5,1040(a1)
ffffffffc020067e:	bf61                	j	ffffffffc0200616 <buddy_init+0x3e>

ffffffffc0200680 <buddy_nr_free_pages>:
    }
}

static size_t
buddy_nr_free_pages(void) {
    return buddy->nr_free;
ffffffffc0200680:	0000c797          	auipc	a5,0xc
ffffffffc0200684:	9907b783          	ld	a5,-1648(a5) # ffffffffc020c010 <buddy>
}
ffffffffc0200688:	4007b503          	ld	a0,1024(a5)
ffffffffc020068c:	8082                	ret

ffffffffc020068e <buddy_insert_block>:
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020068e:	00195797          	auipc	a5,0x195
ffffffffc0200692:	3ca7b783          	ld	a5,970(a5) # ffffffffc0395a58 <pages>
ffffffffc0200696:	40f507b3          	sub	a5,a0,a5
ffffffffc020069a:	00008717          	auipc	a4,0x8
ffffffffc020069e:	34673703          	ld	a4,838(a4) # ffffffffc02089e0 <error_string+0x38>
ffffffffc02006a2:	878d                	srai	a5,a5,0x3
ffffffffc02006a4:	02e787b3          	mul	a5,a5,a4
    size_t size = (size_t)1 << order;
ffffffffc02006a8:	4705                	li	a4,1
ffffffffc02006aa:	00b71733          	sll	a4,a4,a1
ffffffffc02006ae:	00008617          	auipc	a2,0x8
ffffffffc02006b2:	34263603          	ld	a2,834(a2) # ffffffffc02089f0 <nbase>
    assert((page2ppn(base) & (size - 1)) == 0);
ffffffffc02006b6:	fff70693          	addi	a3,a4,-1
ffffffffc02006ba:	97b2                	add	a5,a5,a2
ffffffffc02006bc:	8ff5                	and	a5,a5,a3
ffffffffc02006be:	ef9d                	bnez	a5,ffffffffc02006fc <buddy_insert_block+0x6e>
    SetPageProperty(base);
ffffffffc02006c0:	6510                	ld	a2,8(a0)
    list_entry_t *head = &buddy->free_list[order];
ffffffffc02006c2:	0592                	slli	a1,a1,0x4
ffffffffc02006c4:	0000c697          	auipc	a3,0xc
ffffffffc02006c8:	94c6b683          	ld	a3,-1716(a3) # ffffffffc020c010 <buddy>
ffffffffc02006cc:	96ae                	add	a3,a3,a1
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02006ce:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc02006d0:	00266613          	ori	a2,a2,2
    base->property = size;
ffffffffc02006d4:	c918                	sw	a4,16(a0)
    SetPageProperty(base);
ffffffffc02006d6:	e510                	sd	a2,8(a0)
    for (; le != head; le = list_next(le)) {
ffffffffc02006d8:	00f69663          	bne	a3,a5,ffffffffc02006e4 <buddy_insert_block+0x56>
ffffffffc02006dc:	a801                	j	ffffffffc02006ec <buddy_insert_block+0x5e>
ffffffffc02006de:	679c                	ld	a5,8(a5)
ffffffffc02006e0:	00f68663          	beq	a3,a5,ffffffffc02006ec <buddy_insert_block+0x5e>
        if (base < le2page(le, page_link)) {
ffffffffc02006e4:	fe878713          	addi	a4,a5,-24
ffffffffc02006e8:	fee57be3          	bgeu	a0,a4,ffffffffc02006de <buddy_insert_block+0x50>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02006ec:	6398                	ld	a4,0(a5)
    list_add_before(le, &base->page_link);
ffffffffc02006ee:	01850693          	addi	a3,a0,24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02006f2:	e394                	sd	a3,0(a5)
ffffffffc02006f4:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc02006f6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02006f8:	ed18                	sd	a4,24(a0)
ffffffffc02006fa:	8082                	ret
buddy_insert_block(struct Page *base, size_t order) {
ffffffffc02006fc:	1141                	addi	sp,sp,-16
    assert((page2ppn(base) & (size - 1)) == 0);
ffffffffc02006fe:	00006697          	auipc	a3,0x6
ffffffffc0200702:	88a68693          	addi	a3,a3,-1910 # ffffffffc0205f88 <etext+0x260>
ffffffffc0200706:	00006617          	auipc	a2,0x6
ffffffffc020070a:	8aa60613          	addi	a2,a2,-1878 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020070e:	05700593          	li	a1,87
ffffffffc0200712:	00006517          	auipc	a0,0x6
ffffffffc0200716:	8b650513          	addi	a0,a0,-1866 # ffffffffc0205fc8 <etext+0x2a0>
buddy_insert_block(struct Page *base, size_t order) {
ffffffffc020071a:	e406                	sd	ra,8(sp)
    assert((page2ppn(base) & (size - 1)) == 0);
ffffffffc020071c:	aafff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0200720 <buddy_test_reset>:
}

// The arena is held by a live kernel allocation throughout these tests.
// Switch to a separate state object; never copy circular list sentinels.
static void
buddy_test_reset(struct Page *arena) {
ffffffffc0200720:	1141                	addi	sp,sp,-16
ffffffffc0200722:	e406                	sd	ra,8(sp)
ffffffffc0200724:	e022                	sd	s0,0(sp)
    assert(buddy == &test_state);
ffffffffc0200726:	0000c717          	auipc	a4,0xc
ffffffffc020072a:	8ea73703          	ld	a4,-1814(a4) # ffffffffc020c010 <buddy>
ffffffffc020072e:	000e4797          	auipc	a5,0xe4
ffffffffc0200732:	d1278793          	addi	a5,a5,-750 # ffffffffc02e4440 <test_state>
ffffffffc0200736:	02f71c63          	bne	a4,a5,ffffffffc020076e <buddy_test_reset+0x4e>
ffffffffc020073a:	842a                	mv	s0,a0
    buddy_init();
ffffffffc020073c:	e9dff0ef          	jal	ra,ffffffffc02005d8 <buddy_init>
    for (size_t i = 0; i < BUDDY_TEST_PAGES; i++) {
ffffffffc0200740:	6705                	lui	a4,0x1
ffffffffc0200742:	a1870713          	addi	a4,a4,-1512 # a18 <kern_entry-0xffffffffc01ff5e8>
ffffffffc0200746:	01840793          	addi	a5,s0,24
ffffffffc020074a:	9722                	add	a4,a4,s0
        arena[i].flags = arena[i].property = 0;
        set_page_ref(arena + i, 0);
        list_init(&arena[i].page_link);
        SetPageReserved(arena + i);
ffffffffc020074c:	4685                	li	a3,1
        arena[i].flags = arena[i].property = 0;
ffffffffc020074e:	fe07ac23          	sw	zero,-8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200752:	fe07a423          	sw	zero,-24(a5)
    elm->prev = elm->next = elm;
ffffffffc0200756:	e79c                	sd	a5,8(a5)
ffffffffc0200758:	e39c                	sd	a5,0(a5)
        SetPageReserved(arena + i);
ffffffffc020075a:	fed7b823          	sd	a3,-16(a5)
    for (size_t i = 0; i < BUDDY_TEST_PAGES; i++) {
ffffffffc020075e:	02878793          	addi	a5,a5,40
ffffffffc0200762:	fee796e3          	bne	a5,a4,ffffffffc020074e <buddy_test_reset+0x2e>
    }
}
ffffffffc0200766:	60a2                	ld	ra,8(sp)
ffffffffc0200768:	6402                	ld	s0,0(sp)
ffffffffc020076a:	0141                	addi	sp,sp,16
ffffffffc020076c:	8082                	ret
    assert(buddy == &test_state);
ffffffffc020076e:	00006697          	auipc	a3,0x6
ffffffffc0200772:	87268693          	addi	a3,a3,-1934 # ffffffffc0205fe0 <etext+0x2b8>
ffffffffc0200776:	00006617          	auipc	a2,0x6
ffffffffc020077a:	83a60613          	addi	a2,a2,-1990 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020077e:	18b00593          	li	a1,395
ffffffffc0200782:	00006517          	auipc	a0,0x6
ffffffffc0200786:	84650513          	addi	a0,a0,-1978 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020078a:	a41ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc020078e <buddy_page_count>:
buddy_page_count(void) {
ffffffffc020078e:	1141                	addi	sp,sp,-16
ffffffffc0200790:	e406                	sd	ra,8(sp)
    assert(npage >= nbase);
ffffffffc0200792:	00195517          	auipc	a0,0x195
ffffffffc0200796:	2be53503          	ld	a0,702(a0) # ffffffffc0395a50 <npage>
ffffffffc020079a:	00008797          	auipc	a5,0x8
ffffffffc020079e:	2567b783          	ld	a5,598(a5) # ffffffffc02089f0 <nbase>
ffffffffc02007a2:	00f56963          	bltu	a0,a5,ffffffffc02007b4 <buddy_page_count+0x26>
    assert(npage - nbase <= BUDDY_PAGE_CAPACITY);
ffffffffc02007a6:	8d1d                	sub	a0,a0,a5
ffffffffc02007a8:	67a1                	lui	a5,0x8
ffffffffc02007aa:	02a7e563          	bltu	a5,a0,ffffffffc02007d4 <buddy_page_count+0x46>
}
ffffffffc02007ae:	60a2                	ld	ra,8(sp)
ffffffffc02007b0:	0141                	addi	sp,sp,16
ffffffffc02007b2:	8082                	ret
    assert(npage >= nbase);
ffffffffc02007b4:	00006697          	auipc	a3,0x6
ffffffffc02007b8:	84468693          	addi	a3,a3,-1980 # ffffffffc0205ff8 <etext+0x2d0>
ffffffffc02007bc:	00005617          	auipc	a2,0x5
ffffffffc02007c0:	7f460613          	addi	a2,a2,2036 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02007c4:	02800593          	li	a1,40
ffffffffc02007c8:	00006517          	auipc	a0,0x6
ffffffffc02007cc:	80050513          	addi	a0,a0,-2048 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02007d0:	9fbff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(npage - nbase <= BUDDY_PAGE_CAPACITY);
ffffffffc02007d4:	00006697          	auipc	a3,0x6
ffffffffc02007d8:	83468693          	addi	a3,a3,-1996 # ffffffffc0206008 <etext+0x2e0>
ffffffffc02007dc:	00005617          	auipc	a2,0x5
ffffffffc02007e0:	7d460613          	addi	a2,a2,2004 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02007e4:	02900593          	li	a1,41
ffffffffc02007e8:	00005517          	auipc	a0,0x5
ffffffffc02007ec:	7e050513          	addi	a0,a0,2016 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02007f0:	9dbff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02007f4 <buddy_find_partner>:
buddy_find_partner(struct Page *base, size_t order) {
ffffffffc02007f4:	7179                	addi	sp,sp,-48
ffffffffc02007f6:	e44e                	sd	s3,8(sp)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02007f8:	00195997          	auipc	s3,0x195
ffffffffc02007fc:	2609b983          	ld	s3,608(s3) # ffffffffc0395a58 <pages>
ffffffffc0200800:	f022                	sd	s0,32(sp)
ffffffffc0200802:	41350433          	sub	s0,a0,s3
ffffffffc0200806:	840d                	srai	s0,s0,0x3
ffffffffc0200808:	00008517          	auipc	a0,0x8
ffffffffc020080c:	1d853503          	ld	a0,472(a0) # ffffffffc02089e0 <error_string+0x38>
ffffffffc0200810:	02a40433          	mul	s0,s0,a0
ffffffffc0200814:	e84a                	sd	s2,16(sp)
    size_t size = (size_t)1 << order;
ffffffffc0200816:	4905                	li	s2,1
buddy_find_partner(struct Page *base, size_t order) {
ffffffffc0200818:	ec26                	sd	s1,24(sp)
    size_t size = (size_t)1 << order;
ffffffffc020081a:	00b91933          	sll	s2,s2,a1
ffffffffc020081e:	00008497          	auipc	s1,0x8
ffffffffc0200822:	1d24b483          	ld	s1,466(s1) # ffffffffc02089f0 <nbase>
    assert((ppn & (size - 1)) == 0);
ffffffffc0200826:	fff90793          	addi	a5,s2,-1
buddy_find_partner(struct Page *base, size_t order) {
ffffffffc020082a:	f406                	sd	ra,40(sp)
ffffffffc020082c:	9426                	add	s0,s0,s1
    assert((ppn & (size - 1)) == 0);
ffffffffc020082e:	8fe1                	and	a5,a5,s0
ffffffffc0200830:	ebb5                	bnez	a5,ffffffffc02008a4 <buddy_find_partner+0xb0>
    size_t partner_ppn = ppn ^ size;
ffffffffc0200832:	00894433          	xor	s0,s2,s0
    size_t count = buddy_page_count();
ffffffffc0200836:	f59ff0ef          	jal	ra,ffffffffc020078e <buddy_page_count>
    if (partner_ppn < nbase || partner_ppn - nbase >= count) {
ffffffffc020083a:	04946d63          	bltu	s0,s1,ffffffffc0200894 <buddy_find_partner+0xa0>
ffffffffc020083e:	40940733          	sub	a4,s0,s1
ffffffffc0200842:	04a77963          	bgeu	a4,a0,ffffffffc0200894 <buddy_find_partner+0xa0>
    if (size > count - index || !buddy->managed[index] ||
ffffffffc0200846:	8c81                	sub	s1,s1,s0
ffffffffc0200848:	94aa                	add	s1,s1,a0
ffffffffc020084a:	0524e563          	bltu	s1,s2,ffffffffc0200894 <buddy_find_partner+0xa0>
ffffffffc020084e:	0000b697          	auipc	a3,0xb
ffffffffc0200852:	7c26b683          	ld	a3,1986(a3) # ffffffffc020c010 <buddy>
ffffffffc0200856:	00e68633          	add	a2,a3,a4
ffffffffc020085a:	000a07b7          	lui	a5,0xa0
ffffffffc020085e:	97b2                	add	a5,a5,a2
ffffffffc0200860:	41c7c783          	lbu	a5,1052(a5) # a041c <kern_entry-0xffffffffc015fbe4>
ffffffffc0200864:	cb85                	beqz	a5,ffffffffc0200894 <buddy_find_partner+0xa0>
        buddy->owner[index] != 0) {
ffffffffc0200866:	000207b7          	lui	a5,0x20
ffffffffc020086a:	10478793          	addi	a5,a5,260 # 20104 <kern_entry-0xffffffffc01dfefc>
ffffffffc020086e:	97ba                	add	a5,a5,a4
ffffffffc0200870:	078a                	slli	a5,a5,0x2
ffffffffc0200872:	97b6                	add	a5,a5,a3
    if (size > count - index || !buddy->managed[index] ||
ffffffffc0200874:	47dc                	lw	a5,12(a5)
ffffffffc0200876:	ef99                	bnez	a5,ffffffffc0200894 <buddy_find_partner+0xa0>
    struct Page *partner = pages + index;
ffffffffc0200878:	00271513          	slli	a0,a4,0x2
ffffffffc020087c:	953a                	add	a0,a0,a4
ffffffffc020087e:	050e                	slli	a0,a0,0x3
ffffffffc0200880:	954e                	add	a0,a0,s3
    if (PageReserved(partner) || !PageProperty(partner) ||
ffffffffc0200882:	651c                	ld	a5,8(a0)
ffffffffc0200884:	4709                	li	a4,2
ffffffffc0200886:	8b8d                	andi	a5,a5,3
ffffffffc0200888:	00e79663          	bne	a5,a4,ffffffffc0200894 <buddy_find_partner+0xa0>
        partner->property != size) {
ffffffffc020088c:	01056783          	lwu	a5,16(a0)
    if (PageReserved(partner) || !PageProperty(partner) ||
ffffffffc0200890:	01278363          	beq	a5,s2,ffffffffc0200896 <buddy_find_partner+0xa2>
        return NULL;
ffffffffc0200894:	4501                	li	a0,0
}
ffffffffc0200896:	70a2                	ld	ra,40(sp)
ffffffffc0200898:	7402                	ld	s0,32(sp)
ffffffffc020089a:	64e2                	ld	s1,24(sp)
ffffffffc020089c:	6942                	ld	s2,16(sp)
ffffffffc020089e:	69a2                	ld	s3,8(sp)
ffffffffc02008a0:	6145                	addi	sp,sp,48
ffffffffc02008a2:	8082                	ret
    assert((ppn & (size - 1)) == 0);
ffffffffc02008a4:	00005697          	auipc	a3,0x5
ffffffffc02008a8:	78c68693          	addi	a3,a3,1932 # ffffffffc0206030 <etext+0x308>
ffffffffc02008ac:	00005617          	auipc	a2,0x5
ffffffffc02008b0:	70460613          	addi	a2,a2,1796 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02008b4:	07100593          	li	a1,113
ffffffffc02008b8:	00005517          	auipc	a0,0x5
ffffffffc02008bc:	71050513          	addi	a0,a0,1808 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02008c0:	90bff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02008c4 <buddy_release_block>:
buddy_release_block(struct Page *base, size_t order) {
ffffffffc02008c4:	1101                	addi	sp,sp,-32
    while (order < buddy->max_order) {
ffffffffc02008c6:	0000b797          	auipc	a5,0xb
ffffffffc02008ca:	74a7b783          	ld	a5,1866(a5) # ffffffffc020c010 <buddy>
buddy_release_block(struct Page *base, size_t order) {
ffffffffc02008ce:	e04a                	sd	s2,0(sp)
    while (order < buddy->max_order) {
ffffffffc02008d0:	4107b903          	ld	s2,1040(a5)
buddy_release_block(struct Page *base, size_t order) {
ffffffffc02008d4:	e822                	sd	s0,16(sp)
ffffffffc02008d6:	e426                	sd	s1,8(sp)
ffffffffc02008d8:	ec06                	sd	ra,24(sp)
ffffffffc02008da:	842e                	mv	s0,a1
ffffffffc02008dc:	84aa                	mv	s1,a0
    while (order < buddy->max_order) {
ffffffffc02008de:	0325e963          	bltu	a1,s2,ffffffffc0200910 <buddy_release_block+0x4c>
ffffffffc02008e2:	a825                	j	ffffffffc020091a <buddy_release_block+0x56>
    assert(PageProperty(base));
ffffffffc02008e4:	651c                	ld	a5,8(a0)
ffffffffc02008e6:	0027f713          	andi	a4,a5,2
ffffffffc02008ea:	c321                	beqz	a4,ffffffffc020092a <buddy_release_block+0x66>
    __list_del(listelm->prev, listelm->next);
ffffffffc02008ec:	6d10                	ld	a2,24(a0)
ffffffffc02008ee:	7114                	ld	a3,32(a0)
    list_init(&base->page_link);
ffffffffc02008f0:	01850713          	addi	a4,a0,24
    ClearPageProperty(base);
ffffffffc02008f4:	9bf5                	andi	a5,a5,-3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02008f6:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02008f8:	e290                	sd	a2,0(a3)
    elm->prev = elm->next = elm;
ffffffffc02008fa:	f118                	sd	a4,32(a0)
ffffffffc02008fc:	ed18                	sd	a4,24(a0)
ffffffffc02008fe:	e51c                	sd	a5,8(a0)
    base->property = 0;
ffffffffc0200900:	00052823          	sw	zero,16(a0)
        if (partner < base) {
ffffffffc0200904:	00957363          	bgeu	a0,s1,ffffffffc020090a <buddy_release_block+0x46>
ffffffffc0200908:	84aa                	mv	s1,a0
        order++;
ffffffffc020090a:	0405                	addi	s0,s0,1
    while (order < buddy->max_order) {
ffffffffc020090c:	01240763          	beq	s0,s2,ffffffffc020091a <buddy_release_block+0x56>
        struct Page *partner = buddy_find_partner(base, order);
ffffffffc0200910:	85a2                	mv	a1,s0
ffffffffc0200912:	8526                	mv	a0,s1
ffffffffc0200914:	ee1ff0ef          	jal	ra,ffffffffc02007f4 <buddy_find_partner>
        if (partner == NULL) {
ffffffffc0200918:	f571                	bnez	a0,ffffffffc02008e4 <buddy_release_block+0x20>
    buddy_insert_block(base, order);
ffffffffc020091a:	85a2                	mv	a1,s0
}
ffffffffc020091c:	6442                	ld	s0,16(sp)
ffffffffc020091e:	60e2                	ld	ra,24(sp)
ffffffffc0200920:	6902                	ld	s2,0(sp)
    buddy_insert_block(base, order);
ffffffffc0200922:	8526                	mv	a0,s1
}
ffffffffc0200924:	64a2                	ld	s1,8(sp)
ffffffffc0200926:	6105                	addi	sp,sp,32
    buddy_insert_block(base, order);
ffffffffc0200928:	b39d                	j	ffffffffc020068e <buddy_insert_block>
    assert(PageProperty(base));
ffffffffc020092a:	00005697          	auipc	a3,0x5
ffffffffc020092e:	71e68693          	addi	a3,a3,1822 # ffffffffc0206048 <etext+0x320>
ffffffffc0200932:	00005617          	auipc	a2,0x5
ffffffffc0200936:	67e60613          	addi	a2,a2,1662 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020093a:	06600593          	li	a1,102
ffffffffc020093e:	00005517          	auipc	a0,0x5
ffffffffc0200942:	68a50513          	addi	a0,a0,1674 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200946:	885ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc020094a <buddy_range_index>:
buddy_range_index(struct Page *base, size_t n) {
ffffffffc020094a:	1141                	addi	sp,sp,-16
ffffffffc020094c:	e406                	sd	ra,8(sp)
    assert(npage >= nbase);
ffffffffc020094e:	00195797          	auipc	a5,0x195
ffffffffc0200952:	1027b783          	ld	a5,258(a5) # ffffffffc0395a50 <npage>
ffffffffc0200956:	00008717          	auipc	a4,0x8
ffffffffc020095a:	09a73703          	ld	a4,154(a4) # ffffffffc02089f0 <nbase>
ffffffffc020095e:	0ae7e263          	bltu	a5,a4,ffffffffc0200a02 <buddy_range_index+0xb8>
    assert(npage - nbase <= BUDDY_PAGE_CAPACITY);
ffffffffc0200962:	8f99                	sub	a5,a5,a4
ffffffffc0200964:	6721                	lui	a4,0x8
ffffffffc0200966:	06f76e63          	bltu	a4,a5,ffffffffc02009e2 <buddy_range_index+0x98>
    assert(base >= pages && base < pages + count);
ffffffffc020096a:	00195697          	auipc	a3,0x195
ffffffffc020096e:	0ee6b683          	ld	a3,238(a3) # ffffffffc0395a58 <pages>
ffffffffc0200972:	02d56863          	bltu	a0,a3,ffffffffc02009a2 <buddy_range_index+0x58>
ffffffffc0200976:	00279713          	slli	a4,a5,0x2
ffffffffc020097a:	973e                	add	a4,a4,a5
ffffffffc020097c:	070e                	slli	a4,a4,0x3
ffffffffc020097e:	9736                	add	a4,a4,a3
ffffffffc0200980:	02e57163          	bgeu	a0,a4,ffffffffc02009a2 <buddy_range_index+0x58>
    size_t index = base - pages;
ffffffffc0200984:	8d15                	sub	a0,a0,a3
ffffffffc0200986:	850d                	srai	a0,a0,0x3
ffffffffc0200988:	00008717          	auipc	a4,0x8
ffffffffc020098c:	05873703          	ld	a4,88(a4) # ffffffffc02089e0 <error_string+0x38>
ffffffffc0200990:	02e50533          	mul	a0,a0,a4
    assert(n > 0 && n <= count - index);
ffffffffc0200994:	c59d                	beqz	a1,ffffffffc02009c2 <buddy_range_index+0x78>
ffffffffc0200996:	8f89                	sub	a5,a5,a0
ffffffffc0200998:	02b7e563          	bltu	a5,a1,ffffffffc02009c2 <buddy_range_index+0x78>
}
ffffffffc020099c:	60a2                	ld	ra,8(sp)
ffffffffc020099e:	0141                	addi	sp,sp,16
ffffffffc02009a0:	8082                	ret
    assert(base >= pages && base < pages + count);
ffffffffc02009a2:	00005697          	auipc	a3,0x5
ffffffffc02009a6:	6be68693          	addi	a3,a3,1726 # ffffffffc0206060 <etext+0x338>
ffffffffc02009aa:	00005617          	auipc	a2,0x5
ffffffffc02009ae:	60660613          	addi	a2,a2,1542 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02009b2:	03000593          	li	a1,48
ffffffffc02009b6:	00005517          	auipc	a0,0x5
ffffffffc02009ba:	61250513          	addi	a0,a0,1554 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02009be:	80dff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(n > 0 && n <= count - index);
ffffffffc02009c2:	00005697          	auipc	a3,0x5
ffffffffc02009c6:	6c668693          	addi	a3,a3,1734 # ffffffffc0206088 <etext+0x360>
ffffffffc02009ca:	00005617          	auipc	a2,0x5
ffffffffc02009ce:	5e660613          	addi	a2,a2,1510 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02009d2:	03200593          	li	a1,50
ffffffffc02009d6:	00005517          	auipc	a0,0x5
ffffffffc02009da:	5f250513          	addi	a0,a0,1522 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02009de:	fecff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(npage - nbase <= BUDDY_PAGE_CAPACITY);
ffffffffc02009e2:	00005697          	auipc	a3,0x5
ffffffffc02009e6:	62668693          	addi	a3,a3,1574 # ffffffffc0206008 <etext+0x2e0>
ffffffffc02009ea:	00005617          	auipc	a2,0x5
ffffffffc02009ee:	5c660613          	addi	a2,a2,1478 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02009f2:	02900593          	li	a1,41
ffffffffc02009f6:	00005517          	auipc	a0,0x5
ffffffffc02009fa:	5d250513          	addi	a0,a0,1490 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02009fe:	fccff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(npage >= nbase);
ffffffffc0200a02:	00005697          	auipc	a3,0x5
ffffffffc0200a06:	5f668693          	addi	a3,a3,1526 # ffffffffc0205ff8 <etext+0x2d0>
ffffffffc0200a0a:	00005617          	auipc	a2,0x5
ffffffffc0200a0e:	5a660613          	addi	a2,a2,1446 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200a12:	02800593          	li	a1,40
ffffffffc0200a16:	00005517          	auipc	a0,0x5
ffffffffc0200a1a:	5b250513          	addi	a0,a0,1458 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200a1e:	facff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0200a22 <buddy_check_invariants>:
buddy_check_invariants(void) {
ffffffffc0200a22:	7131                	addi	sp,sp,-192
ffffffffc0200a24:	fd06                	sd	ra,184(sp)
ffffffffc0200a26:	f922                	sd	s0,176(sp)
ffffffffc0200a28:	f526                	sd	s1,168(sp)
ffffffffc0200a2a:	f14a                	sd	s2,160(sp)
ffffffffc0200a2c:	ed4e                	sd	s3,152(sp)
ffffffffc0200a2e:	e952                	sd	s4,144(sp)
ffffffffc0200a30:	e556                	sd	s5,136(sp)
ffffffffc0200a32:	e15a                	sd	s6,128(sp)
ffffffffc0200a34:	fcde                	sd	s7,120(sp)
ffffffffc0200a36:	f8e2                	sd	s8,112(sp)
ffffffffc0200a38:	f4e6                	sd	s9,104(sp)
ffffffffc0200a3a:	f0ea                	sd	s10,96(sp)
ffffffffc0200a3c:	ecee                	sd	s11,88(sp)
    size_t count = buddy_page_count();
ffffffffc0200a3e:	d51ff0ef          	jal	ra,ffffffffc020078e <buddy_page_count>
ffffffffc0200a42:	0000b717          	auipc	a4,0xb
ffffffffc0200a46:	5de70713          	addi	a4,a4,1502 # ffffffffc020c020 <check_free>
ffffffffc0200a4a:	00013697          	auipc	a3,0x13
ffffffffc0200a4e:	5d668693          	addi	a3,a3,1494 # ffffffffc0214020 <check_live>
ffffffffc0200a52:	e4ba                	sd	a4,72(sp)
ffffffffc0200a54:	e0b6                	sd	a3,64(sp)
ffffffffc0200a56:	e82a                	sd	a0,16(sp)
    for (size_t i = 0; i < BUDDY_PAGE_CAPACITY; i++) {
ffffffffc0200a58:	00033797          	auipc	a5,0x33
ffffffffc0200a5c:	5c878793          	addi	a5,a5,1480 # ffffffffc0234020 <check_records>
ffffffffc0200a60:	0003b617          	auipc	a2,0x3b
ffffffffc0200a64:	5c060613          	addi	a2,a2,1472 # ffffffffc023c020 <kernel_state>
        check_free[i] = check_records[i] = 0;
ffffffffc0200a68:	00078023          	sb	zero,0(a5)
ffffffffc0200a6c:	00070023          	sb	zero,0(a4)
        check_live[i] = 0;
ffffffffc0200a70:	0006a023          	sw	zero,0(a3)
    for (size_t i = 0; i < BUDDY_PAGE_CAPACITY; i++) {
ffffffffc0200a74:	0785                	addi	a5,a5,1
ffffffffc0200a76:	0705                	addi	a4,a4,1
ffffffffc0200a78:	0691                	addi	a3,a3,4
ffffffffc0200a7a:	fec797e3          	bne	a5,a2,ffffffffc0200a68 <buddy_check_invariants+0x46>
ffffffffc0200a7e:	00008797          	auipc	a5,0x8
ffffffffc0200a82:	f727b783          	ld	a5,-142(a5) # ffffffffc02089f0 <nbase>
ffffffffc0200a86:	00020ab7          	lui	s5,0x20
        list_entry_t *head = &buddy->free_list[order];
ffffffffc0200a8a:	0000bd97          	auipc	s11,0xb
ffffffffc0200a8e:	586dbd83          	ld	s11,1414(s11) # ffffffffc020c010 <buddy>
ffffffffc0200a92:	ec3e                	sd	a5,24(sp)
    for (size_t order = 0; order < BUDDY_ORDERS; order++) {
ffffffffc0200a94:	4b81                	li	s7,0
ffffffffc0200a96:	107a8793          	addi	a5,s5,263 # 20107 <kern_entry-0xffffffffc01dfef9>
    size_t free_count = 0, nodes = 0;
ffffffffc0200a9a:	4c81                	li	s9,0
                assert(buddy->managed[i] && buddy->owner[i] == 0);
ffffffffc0200a9c:	000a08b7          	lui	a7,0xa0
ffffffffc0200aa0:	00195417          	auipc	s0,0x195
ffffffffc0200aa4:	fb843403          	ld	s0,-72(s0) # ffffffffc0395a58 <pages>
ffffffffc0200aa8:	fc6e                	sd	s11,56(sp)
    size_t free_count = 0, nodes = 0;
ffffffffc0200aaa:	e402                	sd	zero,8(sp)
ffffffffc0200aac:	f43e                	sd	a5,40(sp)
                assert(buddy->managed[i] && buddy->owner[i] == 0);
ffffffffc0200aae:	41c88d13          	addi	s10,a7,1052 # a041c <kern_entry-0xffffffffc015fbe4>
ffffffffc0200ab2:	8c66                	mv	s8,s9
ffffffffc0200ab4:	8ade                	mv	s5,s7
    return listelm->next;
ffffffffc0200ab6:	7762                	ld	a4,56(sp)
ffffffffc0200ab8:	631c                	ld	a5,0(a4)
        assert(list_next(list_prev(head)) == head);
ffffffffc0200aba:	679c                	ld	a5,8(a5)
ffffffffc0200abc:	3ce79363          	bne	a5,a4,ffffffffc0200e82 <buddy_check_invariants+0x460>
ffffffffc0200ac0:	77e2                	ld	a5,56(sp)
ffffffffc0200ac2:	0087b983          	ld	s3,8(a5)
        assert(list_prev(list_next(head)) == head);
ffffffffc0200ac6:	0009b703          	ld	a4,0(s3)
ffffffffc0200aca:	70f71463          	bne	a4,a5,ffffffffc02011d2 <buddy_check_invariants+0x7b0>
        while (le != head) {
ffffffffc0200ace:	18f98163          	beq	s3,a5,ffffffffc0200c50 <buddy_check_invariants+0x22e>
            size_t size = (size_t)1 << order;
ffffffffc0200ad2:	4805                	li	a6,1
ffffffffc0200ad4:	01581a33          	sll	s4,a6,s5
ffffffffc0200ad8:	004a9793          	slli	a5,s5,0x4
            assert(order <= buddy->max_order && ++nodes <= count);
ffffffffc0200adc:	410db483          	ld	s1,1040(s11)
            assert((page2ppn(base) & (size - 1)) == 0);
ffffffffc0200ae0:	fffa0713          	addi	a4,s4,-1
        struct Page *previous = NULL;
ffffffffc0200ae4:	4b01                	li	s6,0
ffffffffc0200ae6:	97ee                	add	a5,a5,s11
ffffffffc0200ae8:	8cd2                	mv	s9,s4
            assert((page2ppn(base) & (size - 1)) == 0);
ffffffffc0200aea:	f03a                	sd	a4,32(sp)
ffffffffc0200aec:	8a4e                	mv	s4,s3
ffffffffc0200aee:	f83e                	sd	a5,48(sp)
ffffffffc0200af0:	89da                	mv	s3,s6
                check_free[i] = 1;
ffffffffc0200af2:	4b85                	li	s7,1
ffffffffc0200af4:	8b62                	mv	s6,s8
            assert(order <= buddy->max_order && ++nodes <= count);
ffffffffc0200af6:	6b54ee63          	bltu	s1,s5,ffffffffc02011b2 <buddy_check_invariants+0x790>
ffffffffc0200afa:	67c2                	ld	a5,16(sp)
ffffffffc0200afc:	0b05                	addi	s6,s6,1
ffffffffc0200afe:	6b67ea63          	bltu	a5,s6,ffffffffc02011b2 <buddy_check_invariants+0x790>
ffffffffc0200b02:	000a3683          	ld	a3,0(s4)
            assert(list_next(list_prev(le)) == le);
ffffffffc0200b06:	6694                	ld	a3,8(a3)
ffffffffc0200b08:	68da1563          	bne	s4,a3,ffffffffc0201192 <buddy_check_invariants+0x770>
ffffffffc0200b0c:	008a3903          	ld	s2,8(s4)
            assert(list_prev(list_next(le)) == le);
ffffffffc0200b10:	00093683          	ld	a3,0(s2)
ffffffffc0200b14:	64da1f63          	bne	s4,a3,ffffffffc0201172 <buddy_check_invariants+0x750>
            struct Page *base = le2page(le, page_link);
ffffffffc0200b18:	fe8a0c13          	addi	s8,s4,-24
            size_t index = buddy_range_index(base, size);
ffffffffc0200b1c:	85e6                	mv	a1,s9
ffffffffc0200b1e:	8562                	mv	a0,s8
ffffffffc0200b20:	e2bff0ef          	jal	ra,ffffffffc020094a <buddy_range_index>
            assert(previous == NULL || previous < base);
ffffffffc0200b24:	00098463          	beqz	s3,ffffffffc0200b2c <buddy_check_invariants+0x10a>
ffffffffc0200b28:	6389f563          	bgeu	s3,s8,ffffffffc0201152 <buddy_check_invariants+0x730>
            assert(PageProperty(base) && base->property == size);
ffffffffc0200b2c:	ff0a3703          	ld	a4,-16(s4)
ffffffffc0200b30:	8b09                	andi	a4,a4,2
ffffffffc0200b32:	60070063          	beqz	a4,ffffffffc0201132 <buddy_check_invariants+0x710>
ffffffffc0200b36:	ff8a6783          	lwu	a5,-8(s4)
ffffffffc0200b3a:	5f979c63          	bne	a5,s9,ffffffffc0201132 <buddy_check_invariants+0x710>
ffffffffc0200b3e:	00008717          	auipc	a4,0x8
ffffffffc0200b42:	ea270713          	addi	a4,a4,-350 # ffffffffc02089e0 <error_string+0x38>
ffffffffc0200b46:	6318                	ld	a4,0(a4)
ffffffffc0200b48:	408c07b3          	sub	a5,s8,s0
ffffffffc0200b4c:	878d                	srai	a5,a5,0x3
ffffffffc0200b4e:	02e787b3          	mul	a5,a5,a4
ffffffffc0200b52:	6762                	ld	a4,24(sp)
ffffffffc0200b54:	97ba                	add	a5,a5,a4
            assert((page2ppn(base) & (size - 1)) == 0);
ffffffffc0200b56:	7702                	ld	a4,32(sp)
ffffffffc0200b58:	8ff9                	and	a5,a5,a4
ffffffffc0200b5a:	5a079c63          	bnez	a5,ffffffffc0201112 <buddy_check_invariants+0x6f0>
            for (size_t i = index; i < index + size; i++) {
ffffffffc0200b5e:	00ac8eb3          	add	t4,s9,a0
ffffffffc0200b62:	07d57663          	bgeu	a0,t4,ffffffffc0200bce <buddy_check_invariants+0x1ac>
ffffffffc0200b66:	77a2                	ld	a5,40(sp)
ffffffffc0200b68:	00251713          	slli	a4,a0,0x2
ffffffffc0200b6c:	972a                	add	a4,a4,a0
ffffffffc0200b6e:	00f505b3          	add	a1,a0,a5
ffffffffc0200b72:	070e                	slli	a4,a4,0x3
ffffffffc0200b74:	0000b797          	auipc	a5,0xb
ffffffffc0200b78:	4ac78793          	addi	a5,a5,1196 # ffffffffc020c020 <check_free>
ffffffffc0200b7c:	058a                	slli	a1,a1,0x2
ffffffffc0200b7e:	00a786b3          	add	a3,a5,a0
ffffffffc0200b82:	9722                	add	a4,a4,s0
ffffffffc0200b84:	95ee                	add	a1,a1,s11
ffffffffc0200b86:	87aa                	mv	a5,a0
                assert(buddy->managed[i] && buddy->owner[i] == 0);
ffffffffc0200b88:	01a78633          	add	a2,a5,s10
ffffffffc0200b8c:	966e                	add	a2,a2,s11
ffffffffc0200b8e:	00064603          	lbu	a2,0(a2)
ffffffffc0200b92:	ce35                	beqz	a2,ffffffffc0200c0e <buddy_check_invariants+0x1ec>
ffffffffc0200b94:	4190                	lw	a2,0(a1)
ffffffffc0200b96:	ee25                	bnez	a2,ffffffffc0200c0e <buddy_check_invariants+0x1ec>
                assert(!PageReserved(pages + i) && page_ref(pages + i) == 0);
ffffffffc0200b98:	6710                	ld	a2,8(a4)
ffffffffc0200b9a:	00167813          	andi	a6,a2,1
ffffffffc0200b9e:	08081863          	bnez	a6,ffffffffc0200c2e <buddy_check_invariants+0x20c>
ffffffffc0200ba2:	00072803          	lw	a6,0(a4)
ffffffffc0200ba6:	08081463          	bnez	a6,ffffffffc0200c2e <buddy_check_invariants+0x20c>
                assert(!check_free[i]);
ffffffffc0200baa:	0006c803          	lbu	a6,0(a3)
ffffffffc0200bae:	14081163          	bnez	a6,ffffffffc0200cf0 <buddy_check_invariants+0x2ce>
                assert(i == index || !PageProperty(pages + i));
ffffffffc0200bb2:	00a78563          	beq	a5,a0,ffffffffc0200bbc <buddy_check_invariants+0x19a>
ffffffffc0200bb6:	8a09                	andi	a2,a2,2
ffffffffc0200bb8:	14061c63          	bnez	a2,ffffffffc0200d10 <buddy_check_invariants+0x2ee>
                check_free[i] = 1;
ffffffffc0200bbc:	01768023          	sb	s7,0(a3)
            for (size_t i = index; i < index + size; i++) {
ffffffffc0200bc0:	0785                	addi	a5,a5,1
ffffffffc0200bc2:	0685                	addi	a3,a3,1
ffffffffc0200bc4:	02870713          	addi	a4,a4,40
ffffffffc0200bc8:	0591                	addi	a1,a1,4
ffffffffc0200bca:	fbd79fe3          	bne	a5,t4,ffffffffc0200b88 <buddy_check_invariants+0x166>
            if (order < buddy->max_order) {
ffffffffc0200bce:	009aeb63          	bltu	s5,s1,ffffffffc0200be4 <buddy_check_invariants+0x1c2>
            free_count += size;
ffffffffc0200bd2:	67a2                	ld	a5,8(sp)
ffffffffc0200bd4:	97e6                	add	a5,a5,s9
ffffffffc0200bd6:	e43e                	sd	a5,8(sp)
        while (le != head) {
ffffffffc0200bd8:	77c2                	ld	a5,48(sp)
ffffffffc0200bda:	06f90a63          	beq	s2,a5,ffffffffc0200c4e <buddy_check_invariants+0x22c>
            struct Page *base = le2page(le, page_link);
ffffffffc0200bde:	89e2                	mv	s3,s8
ffffffffc0200be0:	8a4a                	mv	s4,s2
ffffffffc0200be2:	bf11                	j	ffffffffc0200af6 <buddy_check_invariants+0xd4>
                assert(buddy_find_partner(base, order) == NULL);
ffffffffc0200be4:	85d6                	mv	a1,s5
ffffffffc0200be6:	8562                	mv	a0,s8
ffffffffc0200be8:	c0dff0ef          	jal	ra,ffffffffc02007f4 <buddy_find_partner>
ffffffffc0200bec:	d17d                	beqz	a0,ffffffffc0200bd2 <buddy_check_invariants+0x1b0>
ffffffffc0200bee:	00005697          	auipc	a3,0x5
ffffffffc0200bf2:	66268693          	addi	a3,a3,1634 # ffffffffc0206250 <etext+0x528>
ffffffffc0200bf6:	00005617          	auipc	a2,0x5
ffffffffc0200bfa:	3ba60613          	addi	a2,a2,954 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200bfe:	13600593          	li	a1,310
ffffffffc0200c02:	00005517          	auipc	a0,0x5
ffffffffc0200c06:	3c650513          	addi	a0,a0,966 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200c0a:	dc0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
                assert(buddy->managed[i] && buddy->owner[i] == 0);
ffffffffc0200c0e:	00005697          	auipc	a3,0x5
ffffffffc0200c12:	5b268693          	addi	a3,a3,1458 # ffffffffc02061c0 <etext+0x498>
ffffffffc0200c16:	00005617          	auipc	a2,0x5
ffffffffc0200c1a:	39a60613          	addi	a2,a2,922 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200c1e:	12f00593          	li	a1,303
ffffffffc0200c22:	00005517          	auipc	a0,0x5
ffffffffc0200c26:	3a650513          	addi	a0,a0,934 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200c2a:	da0ff0ef          	jal	ra,ffffffffc02001ca <__panic>
                assert(!PageReserved(pages + i) && page_ref(pages + i) == 0);
ffffffffc0200c2e:	00005697          	auipc	a3,0x5
ffffffffc0200c32:	5c268693          	addi	a3,a3,1474 # ffffffffc02061f0 <etext+0x4c8>
ffffffffc0200c36:	00005617          	auipc	a2,0x5
ffffffffc0200c3a:	37a60613          	addi	a2,a2,890 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200c3e:	13000593          	li	a1,304
ffffffffc0200c42:	00005517          	auipc	a0,0x5
ffffffffc0200c46:	38650513          	addi	a0,a0,902 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200c4a:	d80ff0ef          	jal	ra,ffffffffc02001ca <__panic>
ffffffffc0200c4e:	8c5a                	mv	s8,s6
    for (size_t order = 0; order < BUDDY_ORDERS; order++) {
ffffffffc0200c50:	7762                	ld	a4,56(sp)
ffffffffc0200c52:	0a85                	addi	s5,s5,1
ffffffffc0200c54:	04000793          	li	a5,64
ffffffffc0200c58:	0741                	addi	a4,a4,16
ffffffffc0200c5a:	fc3a                	sd	a4,56(sp)
ffffffffc0200c5c:	e4fa9de3          	bne	s5,a5,ffffffffc0200ab6 <buddy_check_invariants+0x94>
    assert(free_count == buddy->nr_free);
ffffffffc0200c60:	400db783          	ld	a5,1024(s11)
ffffffffc0200c64:	6722                	ld	a4,8(sp)
ffffffffc0200c66:	1ee79e63          	bne	a5,a4,ffffffffc0200e62 <buddy_check_invariants+0x440>
ffffffffc0200c6a:	000806b7          	lui	a3,0x80
ffffffffc0200c6e:	41c68693          	addi	a3,a3,1052 # 8041c <kern_entry-0xffffffffc017fbe4>
        if (!buddy->managed[i]) {
ffffffffc0200c72:	000a0537          	lui	a0,0xa0
        assert(id < BUDDY_PAGE_CAPACITY);
ffffffffc0200c76:	6626                	ld	a2,72(sp)
ffffffffc0200c78:	96ee                	add	a3,a3,s11
ffffffffc0200c7a:	0421                	addi	s0,s0,8
    for (size_t i = 0; i < BUDDY_PAGE_CAPACITY; i++) {
ffffffffc0200c7c:	4781                	li	a5,0
    size_t managed = 0, owned = 0;
ffffffffc0200c7e:	4581                	li	a1,0
ffffffffc0200c80:	4881                	li	a7,0
        if (!buddy->managed[i]) {
ffffffffc0200c82:	41c50513          	addi	a0,a0,1052 # a041c <kern_entry-0xffffffffc015fbe4>
        assert(id < BUDDY_PAGE_CAPACITY);
ffffffffc0200c86:	6321                	lui	t1,0x8
ffffffffc0200c88:	a839                	j	ffffffffc0200ca6 <buddy_check_invariants+0x284>
            assert(buddy->owner[i] == 0 && !check_free[i]);
ffffffffc0200c8a:	4298                	lw	a4,0(a3)
ffffffffc0200c8c:	32071463          	bnez	a4,ffffffffc0200fb4 <buddy_check_invariants+0x592>
ffffffffc0200c90:	00064703          	lbu	a4,0(a2)
ffffffffc0200c94:	32071063          	bnez	a4,ffffffffc0200fb4 <buddy_check_invariants+0x592>
    for (size_t i = 0; i < BUDDY_PAGE_CAPACITY; i++) {
ffffffffc0200c98:	0785                	addi	a5,a5,1
ffffffffc0200c9a:	0691                	addi	a3,a3,4
ffffffffc0200c9c:	0605                	addi	a2,a2,1
ffffffffc0200c9e:	02840413          	addi	s0,s0,40
ffffffffc0200ca2:	20678063          	beq	a5,t1,ffffffffc0200ea2 <buddy_check_invariants+0x480>
        if (!buddy->managed[i]) {
ffffffffc0200ca6:	00a78733          	add	a4,a5,a0
ffffffffc0200caa:	976e                	add	a4,a4,s11
ffffffffc0200cac:	00074703          	lbu	a4,0(a4)
ffffffffc0200cb0:	df69                	beqz	a4,ffffffffc0200c8a <buddy_check_invariants+0x268>
        assert(i < count && !PageReserved(pages + i));
ffffffffc0200cb2:	6742                	ld	a4,16(sp)
ffffffffc0200cb4:	0ee7f763          	bgeu	a5,a4,ffffffffc0200da2 <buddy_check_invariants+0x380>
ffffffffc0200cb8:	00043803          	ld	a6,0(s0)
ffffffffc0200cbc:	00187713          	andi	a4,a6,1
ffffffffc0200cc0:	e36d                	bnez	a4,ffffffffc0200da2 <buddy_check_invariants+0x380>
        if (buddy->owner[i] == 0) {
ffffffffc0200cc2:	4298                	lw	a4,0(a3)
            assert(buddy->owner[i] == 0 && !check_free[i]);
ffffffffc0200cc4:	00064e03          	lbu	t3,0(a2)
        managed++;
ffffffffc0200cc8:	0885                	addi	a7,a7,1
        if (buddy->owner[i] == 0) {
ffffffffc0200cca:	e33d                	bnez	a4,ffffffffc0200d30 <buddy_check_invariants+0x30e>
            assert(check_free[i]);
ffffffffc0200ccc:	fc0e16e3          	bnez	t3,ffffffffc0200c98 <buddy_check_invariants+0x276>
ffffffffc0200cd0:	00005697          	auipc	a3,0x5
ffffffffc0200cd4:	61868693          	addi	a3,a3,1560 # ffffffffc02062e8 <etext+0x5c0>
ffffffffc0200cd8:	00005617          	auipc	a2,0x5
ffffffffc0200cdc:	2d860613          	addi	a2,a2,728 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200ce0:	14600593          	li	a1,326
ffffffffc0200ce4:	00005517          	auipc	a0,0x5
ffffffffc0200ce8:	2e450513          	addi	a0,a0,740 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200cec:	cdeff0ef          	jal	ra,ffffffffc02001ca <__panic>
                assert(!check_free[i]);
ffffffffc0200cf0:	00005697          	auipc	a3,0x5
ffffffffc0200cf4:	5c068693          	addi	a3,a3,1472 # ffffffffc02062b0 <etext+0x588>
ffffffffc0200cf8:	00005617          	auipc	a2,0x5
ffffffffc0200cfc:	2b860613          	addi	a2,a2,696 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200d00:	13100593          	li	a1,305
ffffffffc0200d04:	00005517          	auipc	a0,0x5
ffffffffc0200d08:	2c450513          	addi	a0,a0,708 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200d0c:	cbeff0ef          	jal	ra,ffffffffc02001ca <__panic>
                assert(i == index || !PageProperty(pages + i));
ffffffffc0200d10:	00005697          	auipc	a3,0x5
ffffffffc0200d14:	51868693          	addi	a3,a3,1304 # ffffffffc0206228 <etext+0x500>
ffffffffc0200d18:	00005617          	auipc	a2,0x5
ffffffffc0200d1c:	29860613          	addi	a2,a2,664 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200d20:	13200593          	li	a1,306
ffffffffc0200d24:	00005517          	auipc	a0,0x5
ffffffffc0200d28:	2a450513          	addi	a0,a0,676 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200d2c:	c9eff0ef          	jal	ra,ffffffffc02001ca <__panic>
        owned++;
ffffffffc0200d30:	0585                	addi	a1,a1,1
        assert(!check_free[i] && !PageProperty(pages + i));
ffffffffc0200d32:	100e1863          	bnez	t3,ffffffffc0200e42 <buddy_check_invariants+0x420>
ffffffffc0200d36:	00287813          	andi	a6,a6,2
ffffffffc0200d3a:	10081463          	bnez	a6,ffffffffc0200e42 <buddy_check_invariants+0x420>
        uint32_t id = buddy->owner[i] - 1;
ffffffffc0200d3e:	377d                	addiw	a4,a4,-1
ffffffffc0200d40:	0007081b          	sext.w	a6,a4
        assert(id < BUDDY_PAGE_CAPACITY);
ffffffffc0200d44:	0c687f63          	bgeu	a6,t1,ffffffffc0200e22 <buddy_check_invariants+0x400>
        assert(allocation->live > 0 && allocation->requested > 0);
ffffffffc0200d48:	1702                	slli	a4,a4,0x20
ffffffffc0200d4a:	9301                	srli	a4,a4,0x20
ffffffffc0200d4c:	00471813          	slli	a6,a4,0x4
ffffffffc0200d50:	986e                	add	a6,a6,s11
ffffffffc0200d52:	42482e03          	lw	t3,1060(a6) # 8424 <kern_entry-0xffffffffc01f7bdc>
ffffffffc0200d56:	0a0e0663          	beqz	t3,ffffffffc0200e02 <buddy_check_invariants+0x3e0>
ffffffffc0200d5a:	42882e03          	lw	t3,1064(a6)
ffffffffc0200d5e:	0a0e0263          	beqz	t3,ffffffffc0200e02 <buddy_check_invariants+0x3e0>
        assert(allocation->requested <= allocation->span);
ffffffffc0200d62:	42082e83          	lw	t4,1056(a6)
ffffffffc0200d66:	07ceee63          	bltu	t4,t3,ffffffffc0200de2 <buddy_check_invariants+0x3c0>
        assert(i >= allocation->start && i - allocation->start < allocation->span);
ffffffffc0200d6a:	41c86803          	lwu	a6,1052(a6)
ffffffffc0200d6e:	0507ea63          	bltu	a5,a6,ffffffffc0200dc2 <buddy_check_invariants+0x3a0>
ffffffffc0200d72:	1e82                	slli	t4,t4,0x20
ffffffffc0200d74:	41078833          	sub	a6,a5,a6
ffffffffc0200d78:	020ede93          	srli	t4,t4,0x20
ffffffffc0200d7c:	05d87363          	bgeu	a6,t4,ffffffffc0200dc2 <buddy_check_invariants+0x3a0>
        if (i - allocation->start < allocation->requested) {
ffffffffc0200d80:	1e02                	slli	t3,t3,0x20
ffffffffc0200d82:	020e5e13          	srli	t3,t3,0x20
ffffffffc0200d86:	f1c879e3          	bgeu	a6,t3,ffffffffc0200c98 <buddy_check_invariants+0x276>
            check_live[id]++;
ffffffffc0200d8a:	070a                	slli	a4,a4,0x2
ffffffffc0200d8c:	00013497          	auipc	s1,0x13
ffffffffc0200d90:	29448493          	addi	s1,s1,660 # ffffffffc0214020 <check_live>
ffffffffc0200d94:	9726                	add	a4,a4,s1
ffffffffc0200d96:	00072803          	lw	a6,0(a4)
ffffffffc0200d9a:	2805                	addiw	a6,a6,1
ffffffffc0200d9c:	01072023          	sw	a6,0(a4)
ffffffffc0200da0:	bde5                	j	ffffffffc0200c98 <buddy_check_invariants+0x276>
        assert(i < count && !PageReserved(pages + i));
ffffffffc0200da2:	00005697          	auipc	a3,0x5
ffffffffc0200da6:	51e68693          	addi	a3,a3,1310 # ffffffffc02062c0 <etext+0x598>
ffffffffc0200daa:	00005617          	auipc	a2,0x5
ffffffffc0200dae:	20660613          	addi	a2,a2,518 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200db2:	14300593          	li	a1,323
ffffffffc0200db6:	00005517          	auipc	a0,0x5
ffffffffc0200dba:	21250513          	addi	a0,a0,530 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200dbe:	c0cff0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(i >= allocation->start && i - allocation->start < allocation->span);
ffffffffc0200dc2:	00005697          	auipc	a3,0x5
ffffffffc0200dc6:	5ee68693          	addi	a3,a3,1518 # ffffffffc02063b0 <etext+0x688>
ffffffffc0200dca:	00005617          	auipc	a2,0x5
ffffffffc0200dce:	1e660613          	addi	a2,a2,486 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200dd2:	15000593          	li	a1,336
ffffffffc0200dd6:	00005517          	auipc	a0,0x5
ffffffffc0200dda:	1f250513          	addi	a0,a0,498 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200dde:	becff0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(allocation->requested <= allocation->span);
ffffffffc0200de2:	00005697          	auipc	a3,0x5
ffffffffc0200de6:	59e68693          	addi	a3,a3,1438 # ffffffffc0206380 <etext+0x658>
ffffffffc0200dea:	00005617          	auipc	a2,0x5
ffffffffc0200dee:	1c660613          	addi	a2,a2,454 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200df2:	14f00593          	li	a1,335
ffffffffc0200df6:	00005517          	auipc	a0,0x5
ffffffffc0200dfa:	1d250513          	addi	a0,a0,466 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200dfe:	bccff0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(allocation->live > 0 && allocation->requested > 0);
ffffffffc0200e02:	00005697          	auipc	a3,0x5
ffffffffc0200e06:	54668693          	addi	a3,a3,1350 # ffffffffc0206348 <etext+0x620>
ffffffffc0200e0a:	00005617          	auipc	a2,0x5
ffffffffc0200e0e:	1a660613          	addi	a2,a2,422 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200e12:	14e00593          	li	a1,334
ffffffffc0200e16:	00005517          	auipc	a0,0x5
ffffffffc0200e1a:	1b250513          	addi	a0,a0,434 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200e1e:	bacff0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(id < BUDDY_PAGE_CAPACITY);
ffffffffc0200e22:	00005697          	auipc	a3,0x5
ffffffffc0200e26:	50668693          	addi	a3,a3,1286 # ffffffffc0206328 <etext+0x600>
ffffffffc0200e2a:	00005617          	auipc	a2,0x5
ffffffffc0200e2e:	18660613          	addi	a2,a2,390 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200e32:	14c00593          	li	a1,332
ffffffffc0200e36:	00005517          	auipc	a0,0x5
ffffffffc0200e3a:	19250513          	addi	a0,a0,402 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200e3e:	b8cff0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(!check_free[i] && !PageProperty(pages + i));
ffffffffc0200e42:	00005697          	auipc	a3,0x5
ffffffffc0200e46:	4b668693          	addi	a3,a3,1206 # ffffffffc02062f8 <etext+0x5d0>
ffffffffc0200e4a:	00005617          	auipc	a2,0x5
ffffffffc0200e4e:	16660613          	addi	a2,a2,358 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200e52:	14a00593          	li	a1,330
ffffffffc0200e56:	00005517          	auipc	a0,0x5
ffffffffc0200e5a:	17250513          	addi	a0,a0,370 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200e5e:	b6cff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(free_count == buddy->nr_free);
ffffffffc0200e62:	00005697          	auipc	a3,0x5
ffffffffc0200e66:	41668693          	addi	a3,a3,1046 # ffffffffc0206278 <etext+0x550>
ffffffffc0200e6a:	00005617          	auipc	a2,0x5
ffffffffc0200e6e:	14660613          	addi	a2,a2,326 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200e72:	13c00593          	li	a1,316
ffffffffc0200e76:	00005517          	auipc	a0,0x5
ffffffffc0200e7a:	15250513          	addi	a0,a0,338 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200e7e:	b4cff0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(list_next(list_prev(head)) == head);
ffffffffc0200e82:	00005697          	auipc	a3,0x5
ffffffffc0200e86:	22668693          	addi	a3,a3,550 # ffffffffc02060a8 <etext+0x380>
ffffffffc0200e8a:	00005617          	auipc	a2,0x5
ffffffffc0200e8e:	12660613          	addi	a2,a2,294 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200e92:	11f00593          	li	a1,287
ffffffffc0200e96:	00005517          	auipc	a0,0x5
ffffffffc0200e9a:	13250513          	addi	a0,a0,306 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200e9e:	b2cff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(managed == buddy->nr_managed && free_count + owned == managed);
ffffffffc0200ea2:	408db703          	ld	a4,1032(s11)
ffffffffc0200ea6:	1d171663          	bne	a4,a7,ffffffffc0201072 <buddy_check_invariants+0x650>
ffffffffc0200eaa:	6722                	ld	a4,8(sp)
ffffffffc0200eac:	95ba                	add	a1,a1,a4
ffffffffc0200eae:	1d159263          	bne	a1,a7,ffffffffc0201072 <buddy_check_invariants+0x650>
    uint32_t id = buddy->first_record;
ffffffffc0200eb2:	418da703          	lw	a4,1048(s11)
    while (id != BUDDY_NO_RECORD) {
ffffffffc0200eb6:	56fd                	li	a3,-1
ffffffffc0200eb8:	04d70463          	beq	a4,a3,ffffffffc0200f00 <buddy_check_invariants+0x4de>
        assert(id < BUDDY_PAGE_CAPACITY && ++free_records <= BUDDY_PAGE_CAPACITY);
ffffffffc0200ebc:	12f77c63          	bgeu	a4,a5,ffffffffc0200ff4 <buddy_check_invariants+0x5d2>
        check_records[id] = 1;
ffffffffc0200ec0:	4505                	li	a0,1
    while (id != BUDDY_NO_RECORD) {
ffffffffc0200ec2:	55fd                	li	a1,-1
        assert(id < BUDDY_PAGE_CAPACITY && ++free_records <= BUDDY_PAGE_CAPACITY);
ffffffffc0200ec4:	6621                	lui	a2,0x8
ffffffffc0200ec6:	a031                	j	ffffffffc0200ed2 <buddy_check_invariants+0x4b0>
ffffffffc0200ec8:	12c77663          	bgeu	a4,a2,ffffffffc0200ff4 <buddy_check_invariants+0x5d2>
ffffffffc0200ecc:	17fd                	addi	a5,a5,-1
ffffffffc0200ece:	12078363          	beqz	a5,ffffffffc0200ff4 <buddy_check_invariants+0x5d2>
        assert(!check_records[id] && buddy->allocation[id].live == 0);
ffffffffc0200ed2:	1702                	slli	a4,a4,0x20
ffffffffc0200ed4:	9301                	srli	a4,a4,0x20
ffffffffc0200ed6:	00033697          	auipc	a3,0x33
ffffffffc0200eda:	14a68693          	addi	a3,a3,330 # ffffffffc0234020 <check_records>
ffffffffc0200ede:	96ba                	add	a3,a3,a4
ffffffffc0200ee0:	0006c803          	lbu	a6,0(a3)
ffffffffc0200ee4:	0e081863          	bnez	a6,ffffffffc0200fd4 <buddy_check_invariants+0x5b2>
ffffffffc0200ee8:	0712                	slli	a4,a4,0x4
ffffffffc0200eea:	976e                	add	a4,a4,s11
ffffffffc0200eec:	42472803          	lw	a6,1060(a4)
ffffffffc0200ef0:	0e081263          	bnez	a6,ffffffffc0200fd4 <buddy_check_invariants+0x5b2>
        check_records[id] = 1;
ffffffffc0200ef4:	00a68023          	sb	a0,0(a3)
        id = buddy->allocation[id].next;
ffffffffc0200ef8:	42872703          	lw	a4,1064(a4)
    while (id != BUDDY_NO_RECORD) {
ffffffffc0200efc:	fcb716e3          	bne	a4,a1,ffffffffc0200ec8 <buddy_check_invariants+0x4a6>
ffffffffc0200f00:	000208b7          	lui	a7,0x20
    for (size_t i = 0; i < BUDDY_PAGE_CAPACITY; i++) {
ffffffffc0200f04:	6821                	lui	a6,0x8
ffffffffc0200f06:	6e42                	ld	t3,16(sp)
ffffffffc0200f08:	6306                	ld	t1,64(sp)
ffffffffc0200f0a:	41cd8513          	addi	a0,s11,1052
    size_t managed = 0, owned = 0;
ffffffffc0200f0e:	4585                	li	a1,1
ffffffffc0200f10:	10788893          	addi	a7,a7,263 # 20107 <kern_entry-0xffffffffc01dfef9>
    for (size_t i = 0; i < BUDDY_PAGE_CAPACITY; i++) {
ffffffffc0200f14:	0805                	addi	a6,a6,1
ffffffffc0200f16:	a801                	j	ffffffffc0200f26 <buddy_check_invariants+0x504>
            assert(check_records[i]);
ffffffffc0200f18:	12078d63          	beqz	a5,ffffffffc0201052 <buddy_check_invariants+0x630>
    for (size_t i = 0; i < BUDDY_PAGE_CAPACITY; i++) {
ffffffffc0200f1c:	0585                	addi	a1,a1,1
ffffffffc0200f1e:	0541                	addi	a0,a0,16
ffffffffc0200f20:	0311                	addi	t1,t1,4
ffffffffc0200f22:	11058963          	beq	a1,a6,ffffffffc0201034 <buddy_check_invariants+0x612>
        assert(allocation->live == check_live[i]);
ffffffffc0200f26:	451c                	lw	a5,8(a0)
ffffffffc0200f28:	00032703          	lw	a4,0(t1) # 8000 <kern_entry-0xffffffffc01f8000>
ffffffffc0200f2c:	0ef71463          	bne	a4,a5,ffffffffc0201014 <buddy_check_invariants+0x5f2>
            assert(check_records[i]);
ffffffffc0200f30:	00033797          	auipc	a5,0x33
ffffffffc0200f34:	0f078793          	addi	a5,a5,240 # ffffffffc0234020 <check_records>
ffffffffc0200f38:	97ae                	add	a5,a5,a1
ffffffffc0200f3a:	fff7c783          	lbu	a5,-1(a5)
        if (allocation->live == 0) {
ffffffffc0200f3e:	df69                	beqz	a4,ffffffffc0200f18 <buddy_check_invariants+0x4f6>
        assert(!check_records[i]);
ffffffffc0200f40:	1a079963          	bnez	a5,ffffffffc02010f2 <buddy_check_invariants+0x6d0>
        size_t size = allocation->span;
ffffffffc0200f44:	00456603          	lwu	a2,4(a0)
        assert(size > 0 && (size & (size - 1)) == 0);
ffffffffc0200f48:	18060563          	beqz	a2,ffffffffc02010d2 <buddy_check_invariants+0x6b0>
ffffffffc0200f4c:	fff60693          	addi	a3,a2,-1 # 7fff <kern_entry-0xffffffffc01f8001>
ffffffffc0200f50:	00c6f7b3          	and	a5,a3,a2
ffffffffc0200f54:	16079f63          	bnez	a5,ffffffffc02010d2 <buddy_check_invariants+0x6b0>
        assert(size <= count && allocation->start <= count - size);
ffffffffc0200f58:	14ce6d63          	bltu	t3,a2,ffffffffc02010b2 <buddy_check_invariants+0x690>
ffffffffc0200f5c:	00056783          	lwu	a5,0(a0)
ffffffffc0200f60:	40ce0733          	sub	a4,t3,a2
ffffffffc0200f64:	14f76763          	bltu	a4,a5,ffffffffc02010b2 <buddy_check_invariants+0x690>
        assert(((nbase + allocation->start) & (size - 1)) == 0);
ffffffffc0200f68:	6762                	ld	a4,24(sp)
ffffffffc0200f6a:	973e                	add	a4,a4,a5
ffffffffc0200f6c:	8f75                	and	a4,a4,a3
ffffffffc0200f6e:	12071263          	bnez	a4,ffffffffc0201092 <buddy_check_invariants+0x670>
        for (size_t tail = allocation->requested; tail < size; tail++) {
ffffffffc0200f72:	00c56703          	lwu	a4,12(a0)
ffffffffc0200f76:	fac773e3          	bgeu	a4,a2,ffffffffc0200f1c <buddy_check_invariants+0x4fa>
ffffffffc0200f7a:	97ba                	add	a5,a5,a4
ffffffffc0200f7c:	97c6                	add	a5,a5,a7
ffffffffc0200f7e:	078a                	slli	a5,a5,0x2
ffffffffc0200f80:	97ee                	add	a5,a5,s11
ffffffffc0200f82:	a029                	j	ffffffffc0200f8c <buddy_check_invariants+0x56a>
ffffffffc0200f84:	0705                	addi	a4,a4,1
ffffffffc0200f86:	0791                	addi	a5,a5,4
ffffffffc0200f88:	f8c77ae3          	bgeu	a4,a2,ffffffffc0200f1c <buddy_check_invariants+0x4fa>
            assert(buddy->owner[allocation->start + tail] == i + 1);
ffffffffc0200f8c:	0007e683          	lwu	a3,0(a5)
ffffffffc0200f90:	feb68ae3          	beq	a3,a1,ffffffffc0200f84 <buddy_check_invariants+0x562>
ffffffffc0200f94:	00005697          	auipc	a3,0x5
ffffffffc0200f98:	60c68693          	addi	a3,a3,1548 # ffffffffc02065a0 <etext+0x878>
ffffffffc0200f9c:	00005617          	auipc	a2,0x5
ffffffffc0200fa0:	01460613          	addi	a2,a2,20 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200fa4:	16b00593          	li	a1,363
ffffffffc0200fa8:	00005517          	auipc	a0,0x5
ffffffffc0200fac:	02050513          	addi	a0,a0,32 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200fb0:	a1aff0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(buddy->owner[i] == 0 && !check_free[i]);
ffffffffc0200fb4:	00005697          	auipc	a3,0x5
ffffffffc0200fb8:	2e468693          	addi	a3,a3,740 # ffffffffc0206298 <etext+0x570>
ffffffffc0200fbc:	00005617          	auipc	a2,0x5
ffffffffc0200fc0:	ff460613          	addi	a2,a2,-12 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200fc4:	14000593          	li	a1,320
ffffffffc0200fc8:	00005517          	auipc	a0,0x5
ffffffffc0200fcc:	00050513          	mv	a0,a0
ffffffffc0200fd0:	9faff0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(!check_records[id] && buddy->allocation[id].live == 0);
ffffffffc0200fd4:	00005697          	auipc	a3,0x5
ffffffffc0200fd8:	4ac68693          	addi	a3,a3,1196 # ffffffffc0206480 <etext+0x758>
ffffffffc0200fdc:	00005617          	auipc	a2,0x5
ffffffffc0200fe0:	fd460613          	addi	a2,a2,-44 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0200fe4:	15a00593          	li	a1,346
ffffffffc0200fe8:	00005517          	auipc	a0,0x5
ffffffffc0200fec:	fe050513          	addi	a0,a0,-32 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0200ff0:	9daff0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(id < BUDDY_PAGE_CAPACITY && ++free_records <= BUDDY_PAGE_CAPACITY);
ffffffffc0200ff4:	00005697          	auipc	a3,0x5
ffffffffc0200ff8:	44468693          	addi	a3,a3,1092 # ffffffffc0206438 <etext+0x710>
ffffffffc0200ffc:	00005617          	auipc	a2,0x5
ffffffffc0201000:	fb460613          	addi	a2,a2,-76 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0201004:	15900593          	li	a1,345
ffffffffc0201008:	00005517          	auipc	a0,0x5
ffffffffc020100c:	fc050513          	addi	a0,a0,-64 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0201010:	9baff0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(allocation->live == check_live[i]);
ffffffffc0201014:	00005697          	auipc	a3,0x5
ffffffffc0201018:	4a468693          	addi	a3,a3,1188 # ffffffffc02064b8 <etext+0x790>
ffffffffc020101c:	00005617          	auipc	a2,0x5
ffffffffc0201020:	f9460613          	addi	a2,a2,-108 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0201024:	16000593          	li	a1,352
ffffffffc0201028:	00005517          	auipc	a0,0x5
ffffffffc020102c:	fa050513          	addi	a0,a0,-96 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0201030:	99aff0ef          	jal	ra,ffffffffc02001ca <__panic>
}
ffffffffc0201034:	70ea                	ld	ra,184(sp)
ffffffffc0201036:	744a                	ld	s0,176(sp)
ffffffffc0201038:	74aa                	ld	s1,168(sp)
ffffffffc020103a:	790a                	ld	s2,160(sp)
ffffffffc020103c:	69ea                	ld	s3,152(sp)
ffffffffc020103e:	6a4a                	ld	s4,144(sp)
ffffffffc0201040:	6aaa                	ld	s5,136(sp)
ffffffffc0201042:	6b0a                	ld	s6,128(sp)
ffffffffc0201044:	7be6                	ld	s7,120(sp)
ffffffffc0201046:	7c46                	ld	s8,112(sp)
ffffffffc0201048:	7ca6                	ld	s9,104(sp)
ffffffffc020104a:	7d06                	ld	s10,96(sp)
ffffffffc020104c:	6de6                	ld	s11,88(sp)
ffffffffc020104e:	6129                	addi	sp,sp,192
ffffffffc0201050:	8082                	ret
            assert(check_records[i]);
ffffffffc0201052:	00005697          	auipc	a3,0x5
ffffffffc0201056:	48e68693          	addi	a3,a3,1166 # ffffffffc02064e0 <etext+0x7b8>
ffffffffc020105a:	00005617          	auipc	a2,0x5
ffffffffc020105e:	f5660613          	addi	a2,a2,-170 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0201062:	16200593          	li	a1,354
ffffffffc0201066:	00005517          	auipc	a0,0x5
ffffffffc020106a:	f6250513          	addi	a0,a0,-158 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020106e:	95cff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(managed == buddy->nr_managed && free_count + owned == managed);
ffffffffc0201072:	00005697          	auipc	a3,0x5
ffffffffc0201076:	38668693          	addi	a3,a3,902 # ffffffffc02063f8 <etext+0x6d0>
ffffffffc020107a:	00005617          	auipc	a2,0x5
ffffffffc020107e:	f3660613          	addi	a2,a2,-202 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0201082:	15500593          	li	a1,341
ffffffffc0201086:	00005517          	auipc	a0,0x5
ffffffffc020108a:	f4250513          	addi	a0,a0,-190 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020108e:	93cff0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(((nbase + allocation->start) & (size - 1)) == 0);
ffffffffc0201092:	00005697          	auipc	a3,0x5
ffffffffc0201096:	4de68693          	addi	a3,a3,1246 # ffffffffc0206570 <etext+0x848>
ffffffffc020109a:	00005617          	auipc	a2,0x5
ffffffffc020109e:	f1660613          	addi	a2,a2,-234 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02010a2:	16900593          	li	a1,361
ffffffffc02010a6:	00005517          	auipc	a0,0x5
ffffffffc02010aa:	f2250513          	addi	a0,a0,-222 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02010ae:	91cff0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(size <= count && allocation->start <= count - size);
ffffffffc02010b2:	00005697          	auipc	a3,0x5
ffffffffc02010b6:	48668693          	addi	a3,a3,1158 # ffffffffc0206538 <etext+0x810>
ffffffffc02010ba:	00005617          	auipc	a2,0x5
ffffffffc02010be:	ef660613          	addi	a2,a2,-266 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02010c2:	16800593          	li	a1,360
ffffffffc02010c6:	00005517          	auipc	a0,0x5
ffffffffc02010ca:	f0250513          	addi	a0,a0,-254 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02010ce:	8fcff0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(size > 0 && (size & (size - 1)) == 0);
ffffffffc02010d2:	00005697          	auipc	a3,0x5
ffffffffc02010d6:	43e68693          	addi	a3,a3,1086 # ffffffffc0206510 <etext+0x7e8>
ffffffffc02010da:	00005617          	auipc	a2,0x5
ffffffffc02010de:	ed660613          	addi	a2,a2,-298 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02010e2:	16700593          	li	a1,359
ffffffffc02010e6:	00005517          	auipc	a0,0x5
ffffffffc02010ea:	ee250513          	addi	a0,a0,-286 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02010ee:	8dcff0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(!check_records[i]);
ffffffffc02010f2:	00005697          	auipc	a3,0x5
ffffffffc02010f6:	40668693          	addi	a3,a3,1030 # ffffffffc02064f8 <etext+0x7d0>
ffffffffc02010fa:	00005617          	auipc	a2,0x5
ffffffffc02010fe:	eb660613          	addi	a2,a2,-330 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0201102:	16500593          	li	a1,357
ffffffffc0201106:	00005517          	auipc	a0,0x5
ffffffffc020110a:	ec250513          	addi	a0,a0,-318 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020110e:	8bcff0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert((page2ppn(base) & (size - 1)) == 0);
ffffffffc0201112:	00005697          	auipc	a3,0x5
ffffffffc0201116:	e7668693          	addi	a3,a3,-394 # ffffffffc0205f88 <etext+0x260>
ffffffffc020111a:	00005617          	auipc	a2,0x5
ffffffffc020111e:	e9660613          	addi	a2,a2,-362 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0201122:	12d00593          	li	a1,301
ffffffffc0201126:	00005517          	auipc	a0,0x5
ffffffffc020112a:	ea250513          	addi	a0,a0,-350 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020112e:	89cff0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(PageProperty(base) && base->property == size);
ffffffffc0201132:	00005697          	auipc	a3,0x5
ffffffffc0201136:	05e68693          	addi	a3,a3,94 # ffffffffc0206190 <etext+0x468>
ffffffffc020113a:	00005617          	auipc	a2,0x5
ffffffffc020113e:	e7660613          	addi	a2,a2,-394 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0201142:	12c00593          	li	a1,300
ffffffffc0201146:	00005517          	auipc	a0,0x5
ffffffffc020114a:	e8250513          	addi	a0,a0,-382 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020114e:	87cff0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(previous == NULL || previous < base);
ffffffffc0201152:	00005697          	auipc	a3,0x5
ffffffffc0201156:	01668693          	addi	a3,a3,22 # ffffffffc0206168 <etext+0x440>
ffffffffc020115a:	00005617          	auipc	a2,0x5
ffffffffc020115e:	e5660613          	addi	a2,a2,-426 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0201162:	12a00593          	li	a1,298
ffffffffc0201166:	00005517          	auipc	a0,0x5
ffffffffc020116a:	e6250513          	addi	a0,a0,-414 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020116e:	85cff0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(list_prev(list_next(le)) == le);
ffffffffc0201172:	00005697          	auipc	a3,0x5
ffffffffc0201176:	fd668693          	addi	a3,a3,-42 # ffffffffc0206148 <etext+0x420>
ffffffffc020117a:	00005617          	auipc	a2,0x5
ffffffffc020117e:	e3660613          	addi	a2,a2,-458 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0201182:	12600593          	li	a1,294
ffffffffc0201186:	00005517          	auipc	a0,0x5
ffffffffc020118a:	e4250513          	addi	a0,a0,-446 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020118e:	83cff0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(list_next(list_prev(le)) == le);
ffffffffc0201192:	00005697          	auipc	a3,0x5
ffffffffc0201196:	f9668693          	addi	a3,a3,-106 # ffffffffc0206128 <etext+0x400>
ffffffffc020119a:	00005617          	auipc	a2,0x5
ffffffffc020119e:	e1660613          	addi	a2,a2,-490 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02011a2:	12500593          	li	a1,293
ffffffffc02011a6:	00005517          	auipc	a0,0x5
ffffffffc02011aa:	e2250513          	addi	a0,a0,-478 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02011ae:	81cff0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(order <= buddy->max_order && ++nodes <= count);
ffffffffc02011b2:	00005697          	auipc	a3,0x5
ffffffffc02011b6:	f4668693          	addi	a3,a3,-186 # ffffffffc02060f8 <etext+0x3d0>
ffffffffc02011ba:	00005617          	auipc	a2,0x5
ffffffffc02011be:	df660613          	addi	a2,a2,-522 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02011c2:	12400593          	li	a1,292
ffffffffc02011c6:	00005517          	auipc	a0,0x5
ffffffffc02011ca:	e0250513          	addi	a0,a0,-510 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02011ce:	ffdfe0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(list_prev(list_next(head)) == head);
ffffffffc02011d2:	00005697          	auipc	a3,0x5
ffffffffc02011d6:	efe68693          	addi	a3,a3,-258 # ffffffffc02060d0 <etext+0x3a8>
ffffffffc02011da:	00005617          	auipc	a2,0x5
ffffffffc02011de:	dd660613          	addi	a2,a2,-554 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02011e2:	12000593          	li	a1,288
ffffffffc02011e6:	00005517          	auipc	a0,0x5
ffffffffc02011ea:	de250513          	addi	a0,a0,-542 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02011ee:	fddfe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02011f2 <buddy_free_pages>:
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc02011f2:	711d                	addi	sp,sp,-96
ffffffffc02011f4:	ec86                	sd	ra,88(sp)
ffffffffc02011f6:	e8a2                	sd	s0,80(sp)
ffffffffc02011f8:	e4a6                	sd	s1,72(sp)
ffffffffc02011fa:	e0ca                	sd	s2,64(sp)
ffffffffc02011fc:	fc4e                	sd	s3,56(sp)
ffffffffc02011fe:	f852                	sd	s4,48(sp)
ffffffffc0201200:	f456                	sd	s5,40(sp)
ffffffffc0201202:	f05a                	sd	s6,32(sp)
ffffffffc0201204:	ec5e                	sd	s7,24(sp)
ffffffffc0201206:	e862                	sd	s8,16(sp)
ffffffffc0201208:	e466                	sd	s9,8(sp)
ffffffffc020120a:	e06a                	sd	s10,0(sp)
    assert(n > 0);
ffffffffc020120c:	20058f63          	beqz	a1,ffffffffc020142a <buddy_free_pages+0x238>
ffffffffc0201210:	892e                	mv	s2,a1
    size_t index = buddy_range_index(base, n);
ffffffffc0201212:	f38ff0ef          	jal	ra,ffffffffc020094a <buddy_range_index>
    for (size_t i = index; i < index + n; i++) {
ffffffffc0201216:	992a                	add	s2,s2,a0
    size_t index = buddy_range_index(base, n);
ffffffffc0201218:	89aa                	mv	s3,a0
    for (size_t i = index; i < index + n; i++) {
ffffffffc020121a:	15257a63          	bgeu	a0,s2,ffffffffc020136e <buddy_free_pages+0x17c>
ffffffffc020121e:	000204b7          	lui	s1,0x20
        assert(!PageReserved(pages + i) && !PageProperty(pages + i));
ffffffffc0201222:	00195417          	auipc	s0,0x195
ffffffffc0201226:	83640413          	addi	s0,s0,-1994 # ffffffffc0395a58 <pages>
ffffffffc020122a:	10748493          	addi	s1,s1,263 # 20107 <kern_entry-0xffffffffc01dfef9>
ffffffffc020122e:	6008                	ld	a0,0(s0)
ffffffffc0201230:	00299a13          	slli	s4,s3,0x2
ffffffffc0201234:	94ce                	add	s1,s1,s3
        assert(buddy->managed[i] && buddy->owner[i] != 0);
ffffffffc0201236:	0000bc17          	auipc	s8,0xb
ffffffffc020123a:	ddac3c03          	ld	s8,-550(s8) # ffffffffc020c010 <buddy>
ffffffffc020123e:	9a4e                	add	s4,s4,s3
ffffffffc0201240:	048a                	slli	s1,s1,0x2
ffffffffc0201242:	0a0e                	slli	s4,s4,0x3
ffffffffc0201244:	94e2                	add	s1,s1,s8
ffffffffc0201246:	000a0837          	lui	a6,0xa0
ffffffffc020124a:	014505b3          	add	a1,a0,s4
        assert(!PageReserved(pages + i) && !PageProperty(pages + i));
ffffffffc020124e:	8626                	mv	a2,s1
ffffffffc0201250:	874e                	mv	a4,s3
        assert(buddy->managed[i] && buddy->owner[i] != 0);
ffffffffc0201252:	41c80813          	addi	a6,a6,1052 # a041c <kern_entry-0xffffffffc015fbe4>
ffffffffc0201256:	010707b3          	add	a5,a4,a6
ffffffffc020125a:	97e2                	add	a5,a5,s8
ffffffffc020125c:	0007c783          	lbu	a5,0(a5)
ffffffffc0201260:	12078563          	beqz	a5,ffffffffc020138a <buddy_free_pages+0x198>
ffffffffc0201264:	421c                	lw	a5,0(a2)
ffffffffc0201266:	12078263          	beqz	a5,ffffffffc020138a <buddy_free_pages+0x198>
        assert(!PageReserved(pages + i) && !PageProperty(pages + i));
ffffffffc020126a:	6594                	ld	a3,8(a1)
ffffffffc020126c:	8a8d                	andi	a3,a3,3
ffffffffc020126e:	18069e63          	bnez	a3,ffffffffc020140a <buddy_free_pages+0x218>
        struct buddy_allocation *allocation = &buddy->allocation[buddy->owner[i] - 1];
ffffffffc0201272:	37fd                	addiw	a5,a5,-1
ffffffffc0201274:	02079693          	slli	a3,a5,0x20
ffffffffc0201278:	01c6d793          	srli	a5,a3,0x1c
ffffffffc020127c:	97e2                	add	a5,a5,s8
        assert(allocation->live > 0 && i >= allocation->start);
ffffffffc020127e:	4247a683          	lw	a3,1060(a5)
ffffffffc0201282:	12068463          	beqz	a3,ffffffffc02013aa <buddy_free_pages+0x1b8>
ffffffffc0201286:	41c7e683          	lwu	a3,1052(a5)
ffffffffc020128a:	12d76063          	bltu	a4,a3,ffffffffc02013aa <buddy_free_pages+0x1b8>
        assert(i - allocation->start < allocation->requested);
ffffffffc020128e:	4287e783          	lwu	a5,1064(a5)
ffffffffc0201292:	40d706b3          	sub	a3,a4,a3
ffffffffc0201296:	14f6fa63          	bgeu	a3,a5,ffffffffc02013ea <buddy_free_pages+0x1f8>
    for (size_t i = index; i < index + n; i++) {
ffffffffc020129a:	0705                	addi	a4,a4,1
ffffffffc020129c:	02858593          	addi	a1,a1,40
ffffffffc02012a0:	0611                	addi	a2,a2,4
ffffffffc02012a2:	fae91ae3          	bne	s2,a4,ffffffffc0201256 <buddy_free_pages+0x64>
                assert(buddy->owner[padding] == id + 1);
ffffffffc02012a6:	00080b37          	lui	s6,0x80
ffffffffc02012aa:	a801                	j	ffffffffc02012ba <buddy_free_pages+0xc8>
    for (size_t i = index; i < index + n; i++) {
ffffffffc02012ac:	0985                	addi	s3,s3,1
ffffffffc02012ae:	0491                	addi	s1,s1,4
ffffffffc02012b0:	028a0a13          	addi	s4,s4,40
ffffffffc02012b4:	0b390d63          	beq	s2,s3,ffffffffc020136e <buddy_free_pages+0x17c>
    struct Page *page = pages + index;
ffffffffc02012b8:	6008                	ld	a0,0(s0)
    buddy->nr_free++;
ffffffffc02012ba:	400c3783          	ld	a5,1024(s8)
        uint32_t id = buddy->owner[i] - 1;
ffffffffc02012be:	0004aa83          	lw	s5,0(s1)
    struct Page *page = pages + index;
ffffffffc02012c2:	9552                	add	a0,a0,s4
    buddy->owner[index] = 0;
ffffffffc02012c4:	0004a023          	sw	zero,0(s1)
    buddy->nr_free++;
ffffffffc02012c8:	0785                	addi	a5,a5,1
    page->flags = page->property = 0;
ffffffffc02012ca:	00052823          	sw	zero,16(a0)
ffffffffc02012ce:	00053423          	sd	zero,8(a0)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02012d2:	00052023          	sw	zero,0(a0)
    buddy->nr_free++;
ffffffffc02012d6:	40fc3023          	sd	a5,1024(s8)
    buddy_release_block(page, 0);
ffffffffc02012da:	4581                	li	a1,0
ffffffffc02012dc:	de8ff0ef          	jal	ra,ffffffffc02008c4 <buddy_release_block>
        uint32_t id = buddy->owner[i] - 1;
ffffffffc02012e0:	fffa8b9b          	addiw	s7,s5,-1
        allocation->live--;
ffffffffc02012e4:	020b9793          	slli	a5,s7,0x20
ffffffffc02012e8:	01c7dd13          	srli	s10,a5,0x1c
ffffffffc02012ec:	9d62                	add	s10,s10,s8
ffffffffc02012ee:	424d2783          	lw	a5,1060(s10)
ffffffffc02012f2:	fff7871b          	addiw	a4,a5,-1
ffffffffc02012f6:	42ed2223          	sw	a4,1060(s10)
        if (allocation->live == 0) {
ffffffffc02012fa:	fb4d                	bnez	a4,ffffffffc02012ac <buddy_free_pages+0xba>
            for (size_t tail = allocation->requested; tail < allocation->span; tail++) {
ffffffffc02012fc:	428d6c83          	lwu	s9,1064(s10)
ffffffffc0201300:	420d6783          	lwu	a5,1056(s10)
ffffffffc0201304:	04fcf963          	bgeu	s9,a5,ffffffffc0201356 <buddy_free_pages+0x164>
                size_t padding = allocation->start + tail;
ffffffffc0201308:	41cd6783          	lwu	a5,1052(s10)
ffffffffc020130c:	01978733          	add	a4,a5,s9
                assert(buddy->owner[padding] == id + 1);
ffffffffc0201310:	00271793          	slli	a5,a4,0x2
ffffffffc0201314:	00fc06b3          	add	a3,s8,a5
ffffffffc0201318:	96da                	add	a3,a3,s6
ffffffffc020131a:	41c6a603          	lw	a2,1052(a3)
ffffffffc020131e:	0b561663          	bne	a2,s5,ffffffffc02013ca <buddy_free_pages+0x1d8>
    buddy->owner[index] = 0;
ffffffffc0201322:	4006ae23          	sw	zero,1052(a3)
    struct Page *page = pages + index;
ffffffffc0201326:	6008                	ld	a0,0(s0)
    buddy->nr_free++;
ffffffffc0201328:	400c3683          	ld	a3,1024(s8)
    struct Page *page = pages + index;
ffffffffc020132c:	97ba                	add	a5,a5,a4
ffffffffc020132e:	078e                	slli	a5,a5,0x3
ffffffffc0201330:	953e                	add	a0,a0,a5
    page->flags = page->property = 0;
ffffffffc0201332:	00052823          	sw	zero,16(a0)
    buddy->nr_free++;
ffffffffc0201336:	00168793          	addi	a5,a3,1
    page->flags = page->property = 0;
ffffffffc020133a:	00053423          	sd	zero,8(a0)
ffffffffc020133e:	00052023          	sw	zero,0(a0)
    buddy->nr_free++;
ffffffffc0201342:	40fc3023          	sd	a5,1024(s8)
    buddy_release_block(page, 0);
ffffffffc0201346:	4581                	li	a1,0
ffffffffc0201348:	d7cff0ef          	jal	ra,ffffffffc02008c4 <buddy_release_block>
            for (size_t tail = allocation->requested; tail < allocation->span; tail++) {
ffffffffc020134c:	420d6783          	lwu	a5,1056(s10)
ffffffffc0201350:	0c85                	addi	s9,s9,1
ffffffffc0201352:	fafcebe3          	bltu	s9,a5,ffffffffc0201308 <buddy_free_pages+0x116>
            allocation->next = buddy->first_record;
ffffffffc0201356:	418c2783          	lw	a5,1048(s8)
    for (size_t i = index; i < index + n; i++) {
ffffffffc020135a:	0985                	addi	s3,s3,1
ffffffffc020135c:	0491                	addi	s1,s1,4
            allocation->next = buddy->first_record;
ffffffffc020135e:	42fd2423          	sw	a5,1064(s10)
            buddy->first_record = id;
ffffffffc0201362:	417c2c23          	sw	s7,1048(s8)
    for (size_t i = index; i < index + n; i++) {
ffffffffc0201366:	028a0a13          	addi	s4,s4,40
ffffffffc020136a:	f53917e3          	bne	s2,s3,ffffffffc02012b8 <buddy_free_pages+0xc6>
}
ffffffffc020136e:	60e6                	ld	ra,88(sp)
ffffffffc0201370:	6446                	ld	s0,80(sp)
ffffffffc0201372:	64a6                	ld	s1,72(sp)
ffffffffc0201374:	6906                	ld	s2,64(sp)
ffffffffc0201376:	79e2                	ld	s3,56(sp)
ffffffffc0201378:	7a42                	ld	s4,48(sp)
ffffffffc020137a:	7aa2                	ld	s5,40(sp)
ffffffffc020137c:	7b02                	ld	s6,32(sp)
ffffffffc020137e:	6be2                	ld	s7,24(sp)
ffffffffc0201380:	6c42                	ld	s8,16(sp)
ffffffffc0201382:	6ca2                	ld	s9,8(sp)
ffffffffc0201384:	6d02                	ld	s10,0(sp)
ffffffffc0201386:	6125                	addi	sp,sp,96
ffffffffc0201388:	8082                	ret
        assert(buddy->managed[i] && buddy->owner[i] != 0);
ffffffffc020138a:	00005697          	auipc	a3,0x5
ffffffffc020138e:	24e68693          	addi	a3,a3,590 # ffffffffc02065d8 <etext+0x8b0>
ffffffffc0201392:	00005617          	auipc	a2,0x5
ffffffffc0201396:	c1e60613          	addi	a2,a2,-994 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020139a:	0f200593          	li	a1,242
ffffffffc020139e:	00005517          	auipc	a0,0x5
ffffffffc02013a2:	c2a50513          	addi	a0,a0,-982 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02013a6:	e25fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(allocation->live > 0 && i >= allocation->start);
ffffffffc02013aa:	00005697          	auipc	a3,0x5
ffffffffc02013ae:	29668693          	addi	a3,a3,662 # ffffffffc0206640 <etext+0x918>
ffffffffc02013b2:	00005617          	auipc	a2,0x5
ffffffffc02013b6:	bfe60613          	addi	a2,a2,-1026 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02013ba:	0f500593          	li	a1,245
ffffffffc02013be:	00005517          	auipc	a0,0x5
ffffffffc02013c2:	c0a50513          	addi	a0,a0,-1014 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02013c6:	e05fe0ef          	jal	ra,ffffffffc02001ca <__panic>
                assert(buddy->owner[padding] == id + 1);
ffffffffc02013ca:	00005697          	auipc	a3,0x5
ffffffffc02013ce:	2d668693          	addi	a3,a3,726 # ffffffffc02066a0 <etext+0x978>
ffffffffc02013d2:	00005617          	auipc	a2,0x5
ffffffffc02013d6:	bde60613          	addi	a2,a2,-1058 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02013da:	10200593          	li	a1,258
ffffffffc02013de:	00005517          	auipc	a0,0x5
ffffffffc02013e2:	bea50513          	addi	a0,a0,-1046 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02013e6:	de5fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(i - allocation->start < allocation->requested);
ffffffffc02013ea:	00005697          	auipc	a3,0x5
ffffffffc02013ee:	28668693          	addi	a3,a3,646 # ffffffffc0206670 <etext+0x948>
ffffffffc02013f2:	00005617          	auipc	a2,0x5
ffffffffc02013f6:	bbe60613          	addi	a2,a2,-1090 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02013fa:	0f600593          	li	a1,246
ffffffffc02013fe:	00005517          	auipc	a0,0x5
ffffffffc0201402:	bca50513          	addi	a0,a0,-1078 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0201406:	dc5fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(!PageReserved(pages + i) && !PageProperty(pages + i));
ffffffffc020140a:	00005697          	auipc	a3,0x5
ffffffffc020140e:	1fe68693          	addi	a3,a3,510 # ffffffffc0206608 <etext+0x8e0>
ffffffffc0201412:	00005617          	auipc	a2,0x5
ffffffffc0201416:	b9e60613          	addi	a2,a2,-1122 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020141a:	0f300593          	li	a1,243
ffffffffc020141e:	00005517          	auipc	a0,0x5
ffffffffc0201422:	baa50513          	addi	a0,a0,-1110 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0201426:	da5fe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(n > 0);
ffffffffc020142a:	00005697          	auipc	a3,0x5
ffffffffc020142e:	1a668693          	addi	a3,a3,422 # ffffffffc02065d0 <etext+0x8a8>
ffffffffc0201432:	00005617          	auipc	a2,0x5
ffffffffc0201436:	b7e60613          	addi	a2,a2,-1154 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020143a:	0ed00593          	li	a1,237
ffffffffc020143e:	00005517          	auipc	a0,0x5
ffffffffc0201442:	b8a50513          	addi	a0,a0,-1142 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0201446:	d85fe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc020144a <buddy_alloc_pages>:
buddy_alloc_pages(size_t n) {
ffffffffc020144a:	7139                	addi	sp,sp,-64
ffffffffc020144c:	fc06                	sd	ra,56(sp)
ffffffffc020144e:	f822                	sd	s0,48(sp)
ffffffffc0201450:	f426                	sd	s1,40(sp)
ffffffffc0201452:	f04a                	sd	s2,32(sp)
ffffffffc0201454:	ec4e                	sd	s3,24(sp)
ffffffffc0201456:	e852                	sd	s4,16(sp)
ffffffffc0201458:	e456                	sd	s5,8(sp)
ffffffffc020145a:	e05a                	sd	s6,0(sp)
    assert(n > 0);
ffffffffc020145c:	18050c63          	beqz	a0,ffffffffc02015f4 <buddy_alloc_pages+0x1aa>
    while (size < n && order < buddy->max_order) {
ffffffffc0201460:	4785                	li	a5,1
ffffffffc0201462:	8aaa                	mv	s5,a0
    if (size > buddy->nr_free) {
ffffffffc0201464:	0000b497          	auipc	s1,0xb
ffffffffc0201468:	bac4b483          	ld	s1,-1108(s1) # ffffffffc020c010 <buddy>
    while (size < n && order < buddy->max_order) {
ffffffffc020146c:	12f50663          	beq	a0,a5,ffffffffc0201598 <buddy_alloc_pages+0x14e>
ffffffffc0201470:	4104b703          	ld	a4,1040(s1)
    size_t order = 0, size = 1;
ffffffffc0201474:	4a01                	li	s4,0
    while (size < n && order < buddy->max_order) {
ffffffffc0201476:	13470663          	beq	a4,s4,ffffffffc02015a2 <buddy_alloc_pages+0x158>
        size <<= 1;
ffffffffc020147a:	0786                	slli	a5,a5,0x1
        order++;
ffffffffc020147c:	0a05                	addi	s4,s4,1
    while (size < n && order < buddy->max_order) {
ffffffffc020147e:	ff57ece3          	bltu	a5,s5,ffffffffc0201476 <buddy_alloc_pages+0x2c>
    if (order == BUDDY_ORDERS) {
ffffffffc0201482:	04000793          	li	a5,64
ffffffffc0201486:	10fa0c63          	beq	s4,a5,ffffffffc020159e <buddy_alloc_pages+0x154>
    if (size > buddy->nr_free) {
ffffffffc020148a:	4004b783          	ld	a5,1024(s1)
    size_t size = (size_t)1 << order;
ffffffffc020148e:	4905                	li	s2,1
ffffffffc0201490:	01491933          	sll	s2,s2,s4
    if (size > buddy->nr_free) {
ffffffffc0201494:	1127e563          	bltu	a5,s2,ffffffffc020159e <buddy_alloc_pages+0x154>
    while (found <= buddy->max_order && list_empty(&buddy->free_list[found])) {
ffffffffc0201498:	86ba                	mv	a3,a4
ffffffffc020149a:	11476263          	bltu	a4,s4,ffffffffc020159e <buddy_alloc_pages+0x154>
ffffffffc020149e:	004a1793          	slli	a5,s4,0x4
ffffffffc02014a2:	97a6                	add	a5,a5,s1
    size_t order = 0, size = 1;
ffffffffc02014a4:	89d2                	mv	s3,s4
ffffffffc02014a6:	a029                	j	ffffffffc02014b0 <buddy_alloc_pages+0x66>
        found++;
ffffffffc02014a8:	0985                	addi	s3,s3,1
    while (found <= buddy->max_order && list_empty(&buddy->free_list[found])) {
ffffffffc02014aa:	07c1                	addi	a5,a5,16
ffffffffc02014ac:	0f36e963          	bltu	a3,s3,ffffffffc020159e <buddy_alloc_pages+0x154>
    return list->next == list;
ffffffffc02014b0:	6798                	ld	a4,8(a5)
ffffffffc02014b2:	fef70be3          	beq	a4,a5,ffffffffc02014a8 <buddy_alloc_pages+0x5e>
    assert(PageProperty(base));
ffffffffc02014b6:	ff073783          	ld	a5,-16(a4)
    struct Page *base = le2page(list_next(&buddy->free_list[found]), page_link);
ffffffffc02014ba:	fe870413          	addi	s0,a4,-24
    assert(PageProperty(base));
ffffffffc02014be:	0027f693          	andi	a3,a5,2
ffffffffc02014c2:	16068963          	beqz	a3,ffffffffc0201634 <buddy_alloc_pages+0x1ea>
    __list_del(listelm->prev, listelm->next);
ffffffffc02014c6:	6310                	ld	a2,0(a4)
ffffffffc02014c8:	6714                	ld	a3,8(a4)
    ClearPageProperty(base);
ffffffffc02014ca:	9bf5                	andi	a5,a5,-3
        buddy_insert_block(base + ((size_t)1 << found), found);
ffffffffc02014cc:	02800b13          	li	s6,40
    prev->next = next;
ffffffffc02014d0:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02014d2:	e290                	sd	a2,0(a3)
    elm->prev = elm->next = elm;
ffffffffc02014d4:	e718                	sd	a4,8(a4)
ffffffffc02014d6:	e318                	sd	a4,0(a4)
    ClearPageProperty(base);
ffffffffc02014d8:	fef73823          	sd	a5,-16(a4)
    base->property = 0;
ffffffffc02014dc:	fe072c23          	sw	zero,-8(a4)
    while (found > order) {
ffffffffc02014e0:	013a7b63          	bgeu	s4,s3,ffffffffc02014f6 <buddy_alloc_pages+0xac>
        found--;
ffffffffc02014e4:	19fd                	addi	s3,s3,-1
        buddy_insert_block(base + ((size_t)1 << found), found);
ffffffffc02014e6:	013b1533          	sll	a0,s6,s3
ffffffffc02014ea:	85ce                	mv	a1,s3
ffffffffc02014ec:	9522                	add	a0,a0,s0
ffffffffc02014ee:	9a0ff0ef          	jal	ra,ffffffffc020068e <buddy_insert_block>
    while (found > order) {
ffffffffc02014f2:	ff4999e3          	bne	s3,s4,ffffffffc02014e4 <buddy_alloc_pages+0x9a>
    uint32_t id = buddy->first_record;
ffffffffc02014f6:	4184a983          	lw	s3,1048(s1)
    assert(id != BUDDY_NO_RECORD);
ffffffffc02014fa:	57fd                	li	a5,-1
ffffffffc02014fc:	10f98c63          	beq	s3,a5,ffffffffc0201614 <buddy_alloc_pages+0x1ca>
    buddy->first_record = allocation->next;
ffffffffc0201500:	02099793          	slli	a5,s3,0x20
ffffffffc0201504:	01c7da13          	srli	s4,a5,0x1c
ffffffffc0201508:	9a26                	add	s4,s4,s1
ffffffffc020150a:	428a2783          	lw	a5,1064(s4)
    size_t index = buddy_range_index(base, size);
ffffffffc020150e:	85ca                	mv	a1,s2
ffffffffc0201510:	8522                	mv	a0,s0
    buddy->first_record = allocation->next;
ffffffffc0201512:	40f4ac23          	sw	a5,1048(s1)
    size_t index = buddy_range_index(base, size);
ffffffffc0201516:	c34ff0ef          	jal	ra,ffffffffc020094a <buddy_range_index>
    allocation->requested = n;
ffffffffc020151a:	2a81                	sext.w	s5,s5
    allocation->start = index;
ffffffffc020151c:	40aa2e23          	sw	a0,1052(s4)
    allocation->span = size;
ffffffffc0201520:	432a2023          	sw	s2,1056(s4)
    allocation->requested = n;
ffffffffc0201524:	435a2423          	sw	s5,1064(s4)
    allocation->live = n;
ffffffffc0201528:	435a2223          	sw	s5,1060(s4)
    for (size_t i = 0; i < size; i++) {
ffffffffc020152c:	04090563          	beqz	s2,ffffffffc0201576 <buddy_alloc_pages+0x12c>
ffffffffc0201530:	000a0737          	lui	a4,0xa0
ffffffffc0201534:	000207b7          	lui	a5,0x20
ffffffffc0201538:	41c70713          	addi	a4,a4,1052 # a041c <kern_entry-0xffffffffc015fbe4>
ffffffffc020153c:	10778793          	addi	a5,a5,263 # 20107 <kern_entry-0xffffffffc01dfef9>
ffffffffc0201540:	97aa                	add	a5,a5,a0
ffffffffc0201542:	00e486b3          	add	a3,s1,a4
ffffffffc0201546:	078a                	slli	a5,a5,0x2
ffffffffc0201548:	972a                	add	a4,a4,a0
ffffffffc020154a:	96ca                	add	a3,a3,s2
ffffffffc020154c:	9726                	add	a4,a4,s1
ffffffffc020154e:	97a6                	add	a5,a5,s1
ffffffffc0201550:	8622                	mv	a2,s0
ffffffffc0201552:	9536                	add	a0,a0,a3
        buddy->owner[index + i] = id + 1;
ffffffffc0201554:	0019859b          	addiw	a1,s3,1
        assert(buddy->managed[index + i] && buddy->owner[index + i] == 0);
ffffffffc0201558:	00074683          	lbu	a3,0(a4)
ffffffffc020155c:	cea1                	beqz	a3,ffffffffc02015b4 <buddy_alloc_pages+0x16a>
ffffffffc020155e:	4394                	lw	a3,0(a5)
ffffffffc0201560:	eab1                	bnez	a3,ffffffffc02015b4 <buddy_alloc_pages+0x16a>
        assert(!PageReserved(base + i) && !PageProperty(base + i));
ffffffffc0201562:	6614                	ld	a3,8(a2)
ffffffffc0201564:	8a8d                	andi	a3,a3,3
ffffffffc0201566:	e6bd                	bnez	a3,ffffffffc02015d4 <buddy_alloc_pages+0x18a>
        buddy->owner[index + i] = id + 1;
ffffffffc0201568:	c38c                	sw	a1,0(a5)
    for (size_t i = 0; i < size; i++) {
ffffffffc020156a:	0705                	addi	a4,a4,1
ffffffffc020156c:	0791                	addi	a5,a5,4
ffffffffc020156e:	02860613          	addi	a2,a2,40
ffffffffc0201572:	fea713e3          	bne	a4,a0,ffffffffc0201558 <buddy_alloc_pages+0x10e>
    buddy->nr_free -= size;
ffffffffc0201576:	4004b783          	ld	a5,1024(s1)
ffffffffc020157a:	41278933          	sub	s2,a5,s2
ffffffffc020157e:	4124b023          	sd	s2,1024(s1)
}
ffffffffc0201582:	70e2                	ld	ra,56(sp)
ffffffffc0201584:	8522                	mv	a0,s0
ffffffffc0201586:	7442                	ld	s0,48(sp)
ffffffffc0201588:	74a2                	ld	s1,40(sp)
ffffffffc020158a:	7902                	ld	s2,32(sp)
ffffffffc020158c:	69e2                	ld	s3,24(sp)
ffffffffc020158e:	6a42                	ld	s4,16(sp)
ffffffffc0201590:	6aa2                	ld	s5,8(sp)
ffffffffc0201592:	6b02                	ld	s6,0(sp)
ffffffffc0201594:	6121                	addi	sp,sp,64
ffffffffc0201596:	8082                	ret
    if (size > buddy->nr_free) {
ffffffffc0201598:	4004b783          	ld	a5,1024(s1)
ffffffffc020159c:	e799                	bnez	a5,ffffffffc02015aa <buddy_alloc_pages+0x160>
        return NULL;
ffffffffc020159e:	4401                	li	s0,0
ffffffffc02015a0:	b7cd                	j	ffffffffc0201582 <buddy_alloc_pages+0x138>
ffffffffc02015a2:	4401                	li	s0,0
    return size >= n ? order : BUDDY_ORDERS;
ffffffffc02015a4:	fd57efe3          	bltu	a5,s5,ffffffffc0201582 <buddy_alloc_pages+0x138>
ffffffffc02015a8:	bde9                	j	ffffffffc0201482 <buddy_alloc_pages+0x38>
    while (found <= buddy->max_order && list_empty(&buddy->free_list[found])) {
ffffffffc02015aa:	4104b683          	ld	a3,1040(s1)
ffffffffc02015ae:	4905                	li	s2,1
    size_t order = 0, size = 1;
ffffffffc02015b0:	4a01                	li	s4,0
ffffffffc02015b2:	b5f5                	j	ffffffffc020149e <buddy_alloc_pages+0x54>
        assert(buddy->managed[index + i] && buddy->owner[index + i] == 0);
ffffffffc02015b4:	00005697          	auipc	a3,0x5
ffffffffc02015b8:	12468693          	addi	a3,a3,292 # ffffffffc02066d8 <etext+0x9b0>
ffffffffc02015bc:	00005617          	auipc	a2,0x5
ffffffffc02015c0:	9f460613          	addi	a2,a2,-1548 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02015c4:	0d900593          	li	a1,217
ffffffffc02015c8:	00005517          	auipc	a0,0x5
ffffffffc02015cc:	a0050513          	addi	a0,a0,-1536 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02015d0:	bfbfe0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(!PageReserved(base + i) && !PageProperty(base + i));
ffffffffc02015d4:	00005697          	auipc	a3,0x5
ffffffffc02015d8:	14468693          	addi	a3,a3,324 # ffffffffc0206718 <etext+0x9f0>
ffffffffc02015dc:	00005617          	auipc	a2,0x5
ffffffffc02015e0:	9d460613          	addi	a2,a2,-1580 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02015e4:	0da00593          	li	a1,218
ffffffffc02015e8:	00005517          	auipc	a0,0x5
ffffffffc02015ec:	9e050513          	addi	a0,a0,-1568 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02015f0:	bdbfe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(n > 0);
ffffffffc02015f4:	00005697          	auipc	a3,0x5
ffffffffc02015f8:	fdc68693          	addi	a3,a3,-36 # ffffffffc02065d0 <etext+0x8a8>
ffffffffc02015fc:	00005617          	auipc	a2,0x5
ffffffffc0201600:	9b460613          	addi	a2,a2,-1612 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0201604:	0b900593          	li	a1,185
ffffffffc0201608:	00005517          	auipc	a0,0x5
ffffffffc020160c:	9c050513          	addi	a0,a0,-1600 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0201610:	bbbfe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(id != BUDDY_NO_RECORD);
ffffffffc0201614:	00005697          	auipc	a3,0x5
ffffffffc0201618:	0ac68693          	addi	a3,a3,172 # ffffffffc02066c0 <etext+0x998>
ffffffffc020161c:	00005617          	auipc	a2,0x5
ffffffffc0201620:	99460613          	addi	a2,a2,-1644 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0201624:	0d000593          	li	a1,208
ffffffffc0201628:	00005517          	auipc	a0,0x5
ffffffffc020162c:	9a050513          	addi	a0,a0,-1632 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0201630:	b9bfe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(PageProperty(base));
ffffffffc0201634:	00005697          	auipc	a3,0x5
ffffffffc0201638:	a1468693          	addi	a3,a3,-1516 # ffffffffc0206048 <etext+0x320>
ffffffffc020163c:	00005617          	auipc	a2,0x5
ffffffffc0201640:	97460613          	addi	a2,a2,-1676 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0201644:	06600593          	li	a1,102
ffffffffc0201648:	00005517          	auipc	a0,0x5
ffffffffc020164c:	98050513          	addi	a0,a0,-1664 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0201650:	b7bfe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0201654 <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0201654:	711d                	addi	sp,sp,-96
ffffffffc0201656:	ec86                	sd	ra,88(sp)
ffffffffc0201658:	e8a2                	sd	s0,80(sp)
ffffffffc020165a:	e4a6                	sd	s1,72(sp)
ffffffffc020165c:	e0ca                	sd	s2,64(sp)
ffffffffc020165e:	fc4e                	sd	s3,56(sp)
ffffffffc0201660:	f852                	sd	s4,48(sp)
ffffffffc0201662:	f456                	sd	s5,40(sp)
ffffffffc0201664:	f05a                	sd	s6,32(sp)
ffffffffc0201666:	ec5e                	sd	s7,24(sp)
ffffffffc0201668:	e862                	sd	s8,16(sp)
ffffffffc020166a:	e466                	sd	s9,8(sp)
ffffffffc020166c:	e06a                	sd	s10,0(sp)
    assert(n > 0);
ffffffffc020166e:	18058e63          	beqz	a1,ffffffffc020180a <buddy_init_memmap+0x1b6>
    size_t index = buddy_range_index(base, n);
ffffffffc0201672:	8b2e                	mv	s6,a1
ffffffffc0201674:	8baa                	mv	s7,a0
ffffffffc0201676:	ad4ff0ef          	jal	ra,ffffffffc020094a <buddy_range_index>
    for (size_t i = 0; i < n; i++) {
ffffffffc020167a:	000a07b7          	lui	a5,0xa0
ffffffffc020167e:	41c78793          	addi	a5,a5,1052 # a041c <kern_entry-0xffffffffc015fbe4>
        assert(!buddy->managed[index + i]);
ffffffffc0201682:	0000bc97          	auipc	s9,0xb
ffffffffc0201686:	98ecbc83          	ld	s9,-1650(s9) # ffffffffc020c010 <buddy>
ffffffffc020168a:	00f505b3          	add	a1,a0,a5
ffffffffc020168e:	00fc8633          	add	a2,s9,a5
ffffffffc0201692:	95e6                	add	a1,a1,s9
ffffffffc0201694:	965a                	add	a2,a2,s6
ffffffffc0201696:	008b8713          	addi	a4,s7,8
ffffffffc020169a:	962a                	add	a2,a2,a0
ffffffffc020169c:	87ae                	mv	a5,a1
        assert(PageReserved(base + i));
ffffffffc020169e:	00073a83          	ld	s5,0(a4)
ffffffffc02016a2:	001afa93          	andi	s5,s5,1
ffffffffc02016a6:	140a8263          	beqz	s5,ffffffffc02017ea <buddy_init_memmap+0x196>
        assert(!buddy->managed[index + i]);
ffffffffc02016aa:	0007c683          	lbu	a3,0(a5)
ffffffffc02016ae:	10069e63          	bnez	a3,ffffffffc02017ca <buddy_init_memmap+0x176>
    for (size_t i = 0; i < n; i++) {
ffffffffc02016b2:	0785                	addi	a5,a5,1
ffffffffc02016b4:	02870713          	addi	a4,a4,40
ffffffffc02016b8:	fec793e3          	bne	a5,a2,ffffffffc020169e <buddy_init_memmap+0x4a>
ffffffffc02016bc:	00020737          	lui	a4,0x20
ffffffffc02016c0:	10770713          	addi	a4,a4,263 # 20107 <kern_entry-0xffffffffc01dfef9>
ffffffffc02016c4:	972a                	add	a4,a4,a0
ffffffffc02016c6:	070a                	slli	a4,a4,0x2
ffffffffc02016c8:	018b8793          	addi	a5,s7,24
ffffffffc02016cc:	9766                	add	a4,a4,s9
        buddy->managed[index + i] = 1;
ffffffffc02016ce:	4685                	li	a3,1
        page->flags = page->property = 0;
ffffffffc02016d0:	fe07ac23          	sw	zero,-8(a5)
ffffffffc02016d4:	fe07b823          	sd	zero,-16(a5)
ffffffffc02016d8:	fe07a423          	sw	zero,-24(a5)
ffffffffc02016dc:	e79c                	sd	a5,8(a5)
ffffffffc02016de:	e39c                	sd	a5,0(a5)
        buddy->managed[index + i] = 1;
ffffffffc02016e0:	00d58023          	sb	a3,0(a1)
        buddy->owner[index + i] = 0;
ffffffffc02016e4:	00072023          	sw	zero,0(a4)
    for (size_t i = 0; i < n; i++) {
ffffffffc02016e8:	0585                	addi	a1,a1,1
ffffffffc02016ea:	02878793          	addi	a5,a5,40
ffffffffc02016ee:	0711                	addi	a4,a4,4
ffffffffc02016f0:	fec590e3          	bne	a1,a2,ffffffffc02016d0 <buddy_init_memmap+0x7c>
    buddy->nr_free += n;
ffffffffc02016f4:	400cb703          	ld	a4,1024(s9)
    buddy->nr_managed += n;
ffffffffc02016f8:	408cb783          	ld	a5,1032(s9)
            if (next_size > n || (page2ppn(base) & (next_size - 1)) != 0) {
ffffffffc02016fc:	4d05                	li	s10,1
    buddy->nr_free += n;
ffffffffc02016fe:	975a                	add	a4,a4,s6
    buddy->nr_managed += n;
ffffffffc0201700:	97da                	add	a5,a5,s6
    buddy->nr_free += n;
ffffffffc0201702:	40ecb023          	sd	a4,1024(s9)
    buddy->nr_managed += n;
ffffffffc0201706:	40fcb423          	sd	a5,1032(s9)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020170a:	00194917          	auipc	s2,0x194
ffffffffc020170e:	34e90913          	addi	s2,s2,846 # ffffffffc0395a58 <pages>
ffffffffc0201712:	00007497          	auipc	s1,0x7
ffffffffc0201716:	2ce4b483          	ld	s1,718(s1) # ffffffffc02089e0 <error_string+0x38>
ffffffffc020171a:	00007417          	auipc	s0,0x7
ffffffffc020171e:	2d640413          	addi	s0,s0,726 # ffffffffc02089f0 <nbase>
        base += size;
ffffffffc0201722:	02800993          	li	s3,40
            size_t next_size = (size_t)1 << (order + 1);
ffffffffc0201726:	4a05                	li	s4,1
        while (order < buddy->max_order) {
ffffffffc0201728:	410cb603          	ld	a2,1040(s9)
ffffffffc020172c:	ce2d                	beqz	a2,ffffffffc02017a6 <buddy_init_memmap+0x152>
            if (next_size > n || (page2ppn(base) & (next_size - 1)) != 0) {
ffffffffc020172e:	09ab0163          	beq	s6,s10,ffffffffc02017b0 <buddy_init_memmap+0x15c>
ffffffffc0201732:	00093683          	ld	a3,0(s2)
ffffffffc0201736:	601c                	ld	a5,0(s0)
ffffffffc0201738:	40db86b3          	sub	a3,s7,a3
ffffffffc020173c:	868d                	srai	a3,a3,0x3
ffffffffc020173e:	029686b3          	mul	a3,a3,s1
ffffffffc0201742:	96be                	add	a3,a3,a5
ffffffffc0201744:	0016f593          	andi	a1,a3,1
ffffffffc0201748:	c999                	beqz	a1,ffffffffc020175e <buddy_init_memmap+0x10a>
ffffffffc020174a:	a885                	j	ffffffffc02017ba <buddy_init_memmap+0x166>
            size_t next_size = (size_t)1 << (order + 1);
ffffffffc020174c:	0017079b          	addiw	a5,a4,1
ffffffffc0201750:	00fd17b3          	sll	a5,s10,a5
            if (next_size > n || (page2ppn(base) & (next_size - 1)) != 0) {
ffffffffc0201754:	04fb6463          	bltu	s6,a5,ffffffffc020179c <buddy_init_memmap+0x148>
ffffffffc0201758:	17fd                	addi	a5,a5,-1
ffffffffc020175a:	8ff5                	and	a5,a5,a3
ffffffffc020175c:	e3a1                	bnez	a5,ffffffffc020179c <buddy_init_memmap+0x148>
            order++;
ffffffffc020175e:	0585                	addi	a1,a1,1
        while (order < buddy->max_order) {
ffffffffc0201760:	0005871b          	sext.w	a4,a1
ffffffffc0201764:	fec594e3          	bne	a1,a2,ffffffffc020174c <buddy_init_memmap+0xf8>
        base += size;
ffffffffc0201768:	00e99c33          	sll	s8,s3,a4
        size_t size = (size_t)1 << order;
ffffffffc020176c:	00ed1733          	sll	a4,s10,a4
        buddy_release_block(base, order);
ffffffffc0201770:	855e                	mv	a0,s7
        n -= size;
ffffffffc0201772:	40eb0b33          	sub	s6,s6,a4
        base += size;
ffffffffc0201776:	9be2                	add	s7,s7,s8
        buddy_release_block(base, order);
ffffffffc0201778:	94cff0ef          	jal	ra,ffffffffc02008c4 <buddy_release_block>
    while (n != 0) {
ffffffffc020177c:	fa0b16e3          	bnez	s6,ffffffffc0201728 <buddy_init_memmap+0xd4>
}
ffffffffc0201780:	60e6                	ld	ra,88(sp)
ffffffffc0201782:	6446                	ld	s0,80(sp)
ffffffffc0201784:	64a6                	ld	s1,72(sp)
ffffffffc0201786:	6906                	ld	s2,64(sp)
ffffffffc0201788:	79e2                	ld	s3,56(sp)
ffffffffc020178a:	7a42                	ld	s4,48(sp)
ffffffffc020178c:	7aa2                	ld	s5,40(sp)
ffffffffc020178e:	7b02                	ld	s6,32(sp)
ffffffffc0201790:	6be2                	ld	s7,24(sp)
ffffffffc0201792:	6c42                	ld	s8,16(sp)
ffffffffc0201794:	6ca2                	ld	s9,8(sp)
ffffffffc0201796:	6d02                	ld	s10,0(sp)
ffffffffc0201798:	6125                	addi	sp,sp,96
ffffffffc020179a:	8082                	ret
        base += size;
ffffffffc020179c:	00e99c33          	sll	s8,s3,a4
        size_t size = (size_t)1 << order;
ffffffffc02017a0:	00ea1733          	sll	a4,s4,a4
ffffffffc02017a4:	b7f1                	j	ffffffffc0201770 <buddy_init_memmap+0x11c>
        while (order < buddy->max_order) {
ffffffffc02017a6:	8756                	mv	a4,s5
        size_t order = 0;
ffffffffc02017a8:	4581                	li	a1,0
        while (order < buddy->max_order) {
ffffffffc02017aa:	02800c13          	li	s8,40
ffffffffc02017ae:	b7c9                	j	ffffffffc0201770 <buddy_init_memmap+0x11c>
            if (next_size > n || (page2ppn(base) & (next_size - 1)) != 0) {
ffffffffc02017b0:	4705                	li	a4,1
ffffffffc02017b2:	02800c13          	li	s8,40
        size_t order = 0;
ffffffffc02017b6:	4581                	li	a1,0
ffffffffc02017b8:	bf65                	j	ffffffffc0201770 <buddy_init_memmap+0x11c>
        buddy_release_block(base, order);
ffffffffc02017ba:	855e                	mv	a0,s7
ffffffffc02017bc:	4581                	li	a1,0
ffffffffc02017be:	906ff0ef          	jal	ra,ffffffffc02008c4 <buddy_release_block>
        base += size;
ffffffffc02017c2:	028b8b93          	addi	s7,s7,40
        n -= size;
ffffffffc02017c6:	1b7d                	addi	s6,s6,-1
    while (n != 0) {
ffffffffc02017c8:	b785                	j	ffffffffc0201728 <buddy_init_memmap+0xd4>
        assert(!buddy->managed[index + i]);
ffffffffc02017ca:	00005697          	auipc	a3,0x5
ffffffffc02017ce:	f9e68693          	addi	a3,a3,-98 # ffffffffc0206768 <etext+0xa40>
ffffffffc02017d2:	00004617          	auipc	a2,0x4
ffffffffc02017d6:	7de60613          	addi	a2,a2,2014 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02017da:	09b00593          	li	a1,155
ffffffffc02017de:	00004517          	auipc	a0,0x4
ffffffffc02017e2:	7ea50513          	addi	a0,a0,2026 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02017e6:	9e5fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(PageReserved(base + i));
ffffffffc02017ea:	00005697          	auipc	a3,0x5
ffffffffc02017ee:	f6668693          	addi	a3,a3,-154 # ffffffffc0206750 <etext+0xa28>
ffffffffc02017f2:	00004617          	auipc	a2,0x4
ffffffffc02017f6:	7be60613          	addi	a2,a2,1982 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02017fa:	09a00593          	li	a1,154
ffffffffc02017fe:	00004517          	auipc	a0,0x4
ffffffffc0201802:	7ca50513          	addi	a0,a0,1994 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0201806:	9c5fe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(n > 0);
ffffffffc020180a:	00005697          	auipc	a3,0x5
ffffffffc020180e:	dc668693          	addi	a3,a3,-570 # ffffffffc02065d0 <etext+0x8a8>
ffffffffc0201812:	00004617          	auipc	a2,0x4
ffffffffc0201816:	79e60613          	addi	a2,a2,1950 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020181a:	09700593          	li	a1,151
ffffffffc020181e:	00004517          	auipc	a0,0x4
ffffffffc0201822:	7aa50513          	addi	a0,a0,1962 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0201826:	9a5fe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc020182a <buddy_check>:
    buddy_check_invariants();
}

static void
buddy_check(void) {
    assert(buddy == &kernel_state);
ffffffffc020182a:	0000a797          	auipc	a5,0xa
ffffffffc020182e:	7e678793          	addi	a5,a5,2022 # ffffffffc020c010 <buddy>
ffffffffc0201832:	639c                	ld	a5,0(a5)
buddy_check(void) {
ffffffffc0201834:	7125                	addi	sp,sp,-416
ffffffffc0201836:	ef06                	sd	ra,408(sp)
ffffffffc0201838:	eb22                	sd	s0,400(sp)
ffffffffc020183a:	e726                	sd	s1,392(sp)
ffffffffc020183c:	e34a                	sd	s2,384(sp)
ffffffffc020183e:	fece                	sd	s3,376(sp)
ffffffffc0201840:	fad2                	sd	s4,368(sp)
ffffffffc0201842:	f6d6                	sd	s5,360(sp)
ffffffffc0201844:	f2da                	sd	s6,352(sp)
ffffffffc0201846:	eede                	sd	s7,344(sp)
ffffffffc0201848:	eae2                	sd	s8,336(sp)
ffffffffc020184a:	e6e6                	sd	s9,328(sp)
ffffffffc020184c:	e2ea                	sd	s10,320(sp)
ffffffffc020184e:	fe6e                	sd	s11,312(sp)
    assert(buddy == &kernel_state);
ffffffffc0201850:	0003a717          	auipc	a4,0x3a
ffffffffc0201854:	7d070713          	addi	a4,a4,2000 # ffffffffc023c020 <kernel_state>
ffffffffc0201858:	3ee79ce3          	bne	a5,a4,ffffffffc0202450 <buddy_check+0xc26>
    cprintf("buddy_check: begin\n");
ffffffffc020185c:	00005517          	auipc	a0,0x5
ffffffffc0201860:	f4450513          	addi	a0,a0,-188 # ffffffffc02067a0 <etext+0xa78>
ffffffffc0201864:	8f1fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    buddy_check_invariants();
ffffffffc0201868:	9baff0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    size_t before = nr_free_pages();
ffffffffc020186c:	43c010ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201870:	842a                	mv	s0,a0
ffffffffc0201872:	4491                	li	s1,4
ffffffffc0201874:	00194b97          	auipc	s7,0x194
ffffffffc0201878:	1e4b8b93          	addi	s7,s7,484 # ffffffffc0395a58 <pages>
ffffffffc020187c:	00007c17          	auipc	s8,0x7
ffffffffc0201880:	174c0c13          	addi	s8,s8,372 # ffffffffc02089f0 <nbase>
ffffffffc0201884:	00007a97          	auipc	s5,0x7
ffffffffc0201888:	15caba83          	ld	s5,348(s5) # ffffffffc02089e0 <error_string+0x38>
        assert(page2ppn(a) >= nbase && page2ppn(a) < npage);
ffffffffc020188c:	00194b17          	auipc	s6,0x194
ffffffffc0201890:	1c4b0b13          	addi	s6,s6,452 # ffffffffc0395a50 <npage>
        assert(nr_free_pages() == before - 3);
ffffffffc0201894:	ffd50a13          	addi	s4,a0,-3
        struct Page *a = alloc_pages(1);
ffffffffc0201898:	4505                	li	a0,1
ffffffffc020189a:	3f6010ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc020189e:	8d2a                	mv	s10,a0
        struct Page *b = alloc_pages(1);
ffffffffc02018a0:	4505                	li	a0,1
ffffffffc02018a2:	3ee010ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc02018a6:	8daa                	mv	s11,a0
        struct Page *c = alloc_pages(1);
ffffffffc02018a8:	4505                	li	a0,1
ffffffffc02018aa:	3e6010ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc02018ae:	8caa                	mv	s9,a0
        assert(a != NULL && b != NULL && c != NULL);
ffffffffc02018b0:	000d1463          	bnez	s10,ffffffffc02018b8 <buddy_check+0x8e>
ffffffffc02018b4:	3bc0106f          	j	ffffffffc0202c70 <buddy_check+0x1446>
ffffffffc02018b8:	000d9463          	bnez	s11,ffffffffc02018c0 <buddy_check+0x96>
ffffffffc02018bc:	3b40106f          	j	ffffffffc0202c70 <buddy_check+0x1446>
ffffffffc02018c0:	e119                	bnez	a0,ffffffffc02018c6 <buddy_check+0x9c>
ffffffffc02018c2:	3ae0106f          	j	ffffffffc0202c70 <buddy_check+0x1446>
        assert(a != b && a != c && b != c);
ffffffffc02018c6:	01bd1463          	bne	s10,s11,ffffffffc02018ce <buddy_check+0xa4>
ffffffffc02018ca:	3860106f          	j	ffffffffc0202c50 <buddy_check+0x1426>
ffffffffc02018ce:	00ad1463          	bne	s10,a0,ffffffffc02018d6 <buddy_check+0xac>
ffffffffc02018d2:	37e0106f          	j	ffffffffc0202c50 <buddy_check+0x1426>
ffffffffc02018d6:	00ad9463          	bne	s11,a0,ffffffffc02018de <buddy_check+0xb4>
ffffffffc02018da:	3760106f          	j	ffffffffc0202c50 <buddy_check+0x1426>
ffffffffc02018de:	000bb783          	ld	a5,0(s7)
ffffffffc02018e2:	000c3983          	ld	s3,0(s8)
ffffffffc02018e6:	40fd0733          	sub	a4,s10,a5
ffffffffc02018ea:	870d                	srai	a4,a4,0x3
ffffffffc02018ec:	03570733          	mul	a4,a4,s5
ffffffffc02018f0:	974e                	add	a4,a4,s3
        assert(page2ppn(a) >= nbase && page2ppn(a) < npage);
ffffffffc02018f2:	01377463          	bgeu	a4,s3,ffffffffc02018fa <buddy_check+0xd0>
ffffffffc02018f6:	33a0106f          	j	ffffffffc0202c30 <buddy_check+0x1406>
ffffffffc02018fa:	000b3683          	ld	a3,0(s6)
ffffffffc02018fe:	00d76463          	bltu	a4,a3,ffffffffc0201906 <buddy_check+0xdc>
ffffffffc0201902:	32e0106f          	j	ffffffffc0202c30 <buddy_check+0x1406>
ffffffffc0201906:	40fd8733          	sub	a4,s11,a5
ffffffffc020190a:	870d                	srai	a4,a4,0x3
ffffffffc020190c:	03570733          	mul	a4,a4,s5
ffffffffc0201910:	974e                	add	a4,a4,s3
        assert(page2ppn(b) >= nbase && page2ppn(b) < npage);
ffffffffc0201912:	01377463          	bgeu	a4,s3,ffffffffc020191a <buddy_check+0xf0>
ffffffffc0201916:	2fa0106f          	j	ffffffffc0202c10 <buddy_check+0x13e6>
ffffffffc020191a:	00d76463          	bltu	a4,a3,ffffffffc0201922 <buddy_check+0xf8>
ffffffffc020191e:	2f20106f          	j	ffffffffc0202c10 <buddy_check+0x13e6>
ffffffffc0201922:	40f507b3          	sub	a5,a0,a5
ffffffffc0201926:	878d                	srai	a5,a5,0x3
ffffffffc0201928:	035787b3          	mul	a5,a5,s5
ffffffffc020192c:	97ce                	add	a5,a5,s3
        assert(page2ppn(c) >= nbase && page2ppn(c) < npage);
ffffffffc020192e:	0137f463          	bgeu	a5,s3,ffffffffc0201936 <buddy_check+0x10c>
ffffffffc0201932:	2be0106f          	j	ffffffffc0202bf0 <buddy_check+0x13c6>
ffffffffc0201936:	00d7e463          	bltu	a5,a3,ffffffffc020193e <buddy_check+0x114>
ffffffffc020193a:	2b60106f          	j	ffffffffc0202bf0 <buddy_check+0x13c6>
        assert(page_ref(a) == 0 && page_ref(b) == 0 && page_ref(c) == 0);
ffffffffc020193e:	000d2783          	lw	a5,0(s10)
ffffffffc0201942:	c399                	beqz	a5,ffffffffc0201948 <buddy_check+0x11e>
ffffffffc0201944:	28c0106f          	j	ffffffffc0202bd0 <buddy_check+0x13a6>
ffffffffc0201948:	000da783          	lw	a5,0(s11)
ffffffffc020194c:	c399                	beqz	a5,ffffffffc0201952 <buddy_check+0x128>
ffffffffc020194e:	2820106f          	j	ffffffffc0202bd0 <buddy_check+0x13a6>
ffffffffc0201952:	411c                	lw	a5,0(a0)
ffffffffc0201954:	c399                	beqz	a5,ffffffffc020195a <buddy_check+0x130>
ffffffffc0201956:	27a0106f          	j	ffffffffc0202bd0 <buddy_check+0x13a6>
        assert(!PageProperty(a) && !PageProperty(b) && !PageProperty(c));
ffffffffc020195a:	008d3783          	ld	a5,8(s10)
ffffffffc020195e:	8b89                	andi	a5,a5,2
ffffffffc0201960:	c399                	beqz	a5,ffffffffc0201966 <buddy_check+0x13c>
ffffffffc0201962:	24e0106f          	j	ffffffffc0202bb0 <buddy_check+0x1386>
ffffffffc0201966:	008db783          	ld	a5,8(s11)
ffffffffc020196a:	8b89                	andi	a5,a5,2
ffffffffc020196c:	c399                	beqz	a5,ffffffffc0201972 <buddy_check+0x148>
ffffffffc020196e:	2420106f          	j	ffffffffc0202bb0 <buddy_check+0x1386>
ffffffffc0201972:	651c                	ld	a5,8(a0)
ffffffffc0201974:	8b89                	andi	a5,a5,2
ffffffffc0201976:	c399                	beqz	a5,ffffffffc020197c <buddy_check+0x152>
ffffffffc0201978:	2380106f          	j	ffffffffc0202bb0 <buddy_check+0x1386>
        assert(nr_free_pages() == before - 3);
ffffffffc020197c:	32c010ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201980:	01450463          	beq	a0,s4,ffffffffc0201988 <buddy_check+0x15e>
ffffffffc0201984:	20c0106f          	j	ffffffffc0202b90 <buddy_check+0x1366>
        free_pages(b, 1);
ffffffffc0201988:	4585                	li	a1,1
ffffffffc020198a:	856e                	mv	a0,s11
ffffffffc020198c:	310010ef          	jal	ra,ffffffffc0202c9c <free_pages>
        free_pages(a, 1);
ffffffffc0201990:	4585                	li	a1,1
ffffffffc0201992:	856a                	mv	a0,s10
ffffffffc0201994:	308010ef          	jal	ra,ffffffffc0202c9c <free_pages>
        free_pages(c, 1);
ffffffffc0201998:	4585                	li	a1,1
ffffffffc020199a:	8566                	mv	a0,s9
ffffffffc020199c:	300010ef          	jal	ra,ffffffffc0202c9c <free_pages>
        assert(nr_free_pages() == before);
ffffffffc02019a0:	308010ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc02019a4:	00a40463          	beq	s0,a0,ffffffffc02019ac <buddy_check+0x182>
ffffffffc02019a8:	1c80106f          	j	ffffffffc0202b70 <buddy_check+0x1346>
    for (size_t round = 0; round < 4; round++) {
ffffffffc02019ac:	14fd                	addi	s1,s1,-1
        buddy_check_invariants();
ffffffffc02019ae:	874ff0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    for (size_t round = 0; round < 4; round++) {
ffffffffc02019b2:	ee0493e3          	bnez	s1,ffffffffc0201898 <buddy_check+0x6e>
    buddy_check_basic();
    cprintf("buddy_check: basic passed\n");
ffffffffc02019b6:	00005517          	auipc	a0,0x5
ffffffffc02019ba:	f9a50513          	addi	a0,a0,-102 # ffffffffc0206950 <etext+0xc28>
ffffffffc02019be:	f96fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    size_t before = nr_free_pages();
ffffffffc02019c2:	2e6010ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc02019c6:	87aa                	mv	a5,a0
    struct Page *arena = alloc_pages(BUDDY_TEST_PAGES);
ffffffffc02019c8:	04000513          	li	a0,64
    size_t before = nr_free_pages();
ffffffffc02019cc:	e83e                	sd	a5,16(sp)
    struct Page *arena = alloc_pages(BUDDY_TEST_PAGES);
ffffffffc02019ce:	2c2010ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc02019d2:	842a                	mv	s0,a0
    assert(arena != NULL);
ffffffffc02019d4:	e119                	bnez	a0,ffffffffc02019da <buddy_check+0x1b0>
ffffffffc02019d6:	17a0106f          	j	ffffffffc0202b50 <buddy_check+0x1326>
    const size_t sizes[] = {1, 2, 4, 8, 3, 13};
ffffffffc02019da:	00006497          	auipc	s1,0x6
ffffffffc02019de:	8de48493          	addi	s1,s1,-1826 # ffffffffc02072b8 <etext+0x1590>
ffffffffc02019e2:	6088                	ld	a0,0(s1)
ffffffffc02019e4:	648c                	ld	a1,8(s1)
ffffffffc02019e6:	6890                	ld	a2,16(s1)
ffffffffc02019e8:	6c94                	ld	a3,24(s1)
ffffffffc02019ea:	7098                	ld	a4,32(s1)
ffffffffc02019ec:	749c                	ld	a5,40(s1)
ffffffffc02019ee:	0b010913          	addi	s2,sp,176
    buddy = &test_state;
ffffffffc02019f2:	000e3897          	auipc	a7,0xe3
ffffffffc02019f6:	a4e88893          	addi	a7,a7,-1458 # ffffffffc02e4440 <test_state>
ffffffffc02019fa:	0000a817          	auipc	a6,0xa
ffffffffc02019fe:	61680813          	addi	a6,a6,1558 # ffffffffc020c010 <buddy>
ffffffffc0201a02:	01183023          	sd	a7,0(a6)
    const size_t sizes[] = {1, 2, 4, 8, 3, 13};
ffffffffc0201a06:	f92a                	sd	a0,176(sp)
ffffffffc0201a08:	fd2e                	sd	a1,184(sp)
ffffffffc0201a0a:	e1b2                	sd	a2,192(sp)
ffffffffc0201a0c:	e5b6                	sd	a3,200(sp)
ffffffffc0201a0e:	e9ba                	sd	a4,208(sp)
ffffffffc0201a10:	edbe                	sd	a5,216(sp)
    for (size_t i = 0; i < sizeof(sizes) / sizeof(sizes[0]); i++) {
ffffffffc0201a12:	8b4a                	mv	s6,s2
ffffffffc0201a14:	0e010c13          	addi	s8,sp,224
        buddy_test_reset(arena);
ffffffffc0201a18:	8522                	mv	a0,s0
ffffffffc0201a1a:	d07fe0ef          	jal	ra,ffffffffc0200720 <buddy_test_reset>
        buddy_init_memmap(arena, sizes[i]);
ffffffffc0201a1e:	000b3a03          	ld	s4,0(s6)
ffffffffc0201a22:	8522                	mv	a0,s0
ffffffffc0201a24:	85d2                	mv	a1,s4
ffffffffc0201a26:	c2fff0ef          	jal	ra,ffffffffc0201654 <buddy_init_memmap>
        assert(nr_free_pages() == sizes[i]);
ffffffffc0201a2a:	27e010ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201a2e:	00aa0463          	beq	s4,a0,ffffffffc0201a36 <buddy_check+0x20c>
ffffffffc0201a32:	0fe0106f          	j	ffffffffc0202b30 <buddy_check+0x1306>
        if ((sizes[i] & (sizes[i] - 1)) == 0) {
ffffffffc0201a36:	fffa0793          	addi	a5,s4,-1
ffffffffc0201a3a:	0147f7b3          	and	a5,a5,s4
ffffffffc0201a3e:	ef81                	bnez	a5,ffffffffc0201a56 <buddy_check+0x22c>
            assert(PageProperty(arena) && arena->property == sizes[i]);
ffffffffc0201a40:	641c                	ld	a5,8(s0)
ffffffffc0201a42:	8b89                	andi	a5,a5,2
ffffffffc0201a44:	e399                	bnez	a5,ffffffffc0201a4a <buddy_check+0x220>
ffffffffc0201a46:	0ca0106f          	j	ffffffffc0202b10 <buddy_check+0x12e6>
ffffffffc0201a4a:	01046783          	lwu	a5,16(s0)
ffffffffc0201a4e:	00fa0463          	beq	s4,a5,ffffffffc0201a56 <buddy_check+0x22c>
ffffffffc0201a52:	0be0106f          	j	ffffffffc0202b10 <buddy_check+0x12e6>
    for (size_t i = 0; i < sizeof(sizes) / sizeof(sizes[0]); i++) {
ffffffffc0201a56:	0b21                	addi	s6,s6,8
        buddy_check_invariants();
ffffffffc0201a58:	fcbfe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    for (size_t i = 0; i < sizeof(sizes) / sizeof(sizes[0]); i++) {
ffffffffc0201a5c:	fb6c1ee3          	bne	s8,s6,ffffffffc0201a18 <buddy_check+0x1ee>
    buddy_test_reset(arena);
ffffffffc0201a60:	8522                	mv	a0,s0
ffffffffc0201a62:	cbffe0ef          	jal	ra,ffffffffc0200720 <buddy_test_reset>
    buddy_init_memmap(arena + 1, 13);
ffffffffc0201a66:	02840a13          	addi	s4,s0,40
ffffffffc0201a6a:	45b5                	li	a1,13
ffffffffc0201a6c:	8552                	mv	a0,s4
ffffffffc0201a6e:	be7ff0ef          	jal	ra,ffffffffc0201654 <buddy_init_memmap>
    assert(nr_free_pages() == 13 && PageReserved(arena));
ffffffffc0201a72:	236010ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201a76:	47b5                	li	a5,13
ffffffffc0201a78:	00f50463          	beq	a0,a5,ffffffffc0201a80 <buddy_check+0x256>
ffffffffc0201a7c:	0740106f          	j	ffffffffc0202af0 <buddy_check+0x12c6>
ffffffffc0201a80:	641c                	ld	a5,8(s0)
ffffffffc0201a82:	8b85                	andi	a5,a5,1
ffffffffc0201a84:	e399                	bnez	a5,ffffffffc0201a8a <buddy_check+0x260>
ffffffffc0201a86:	06a0106f          	j	ffffffffc0202af0 <buddy_check+0x12c6>
    buddy_check_invariants();
ffffffffc0201a8a:	f99fe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    buddy_test_reset(arena);
ffffffffc0201a8e:	8522                	mv	a0,s0
ffffffffc0201a90:	c91fe0ef          	jal	ra,ffffffffc0200720 <buddy_test_reset>
    buddy_init_memmap(arena + 1, 3);
ffffffffc0201a94:	458d                	li	a1,3
ffffffffc0201a96:	8552                	mv	a0,s4
ffffffffc0201a98:	bbdff0ef          	jal	ra,ffffffffc0201654 <buddy_init_memmap>
    buddy_init_memmap(arena + 8, 5);
ffffffffc0201a9c:	14040d93          	addi	s11,s0,320
ffffffffc0201aa0:	4595                	li	a1,5
ffffffffc0201aa2:	856e                	mv	a0,s11
ffffffffc0201aa4:	bb1ff0ef          	jal	ra,ffffffffc0201654 <buddy_init_memmap>
    assert(nr_free_pages() == 8);
ffffffffc0201aa8:	200010ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201aac:	4721                	li	a4,8
ffffffffc0201aae:	0a840793          	addi	a5,s0,168
ffffffffc0201ab2:	14840693          	addi	a3,s0,328
ffffffffc0201ab6:	00e50463          	beq	a0,a4,ffffffffc0201abe <buddy_check+0x294>
ffffffffc0201aba:	0160106f          	j	ffffffffc0202ad0 <buddy_check+0x12a6>
        assert(PageReserved(arena + i));
ffffffffc0201abe:	6398                	ld	a4,0(a5)
ffffffffc0201ac0:	8b05                	andi	a4,a4,1
ffffffffc0201ac2:	ec3a                	sd	a4,24(sp)
ffffffffc0201ac4:	e319                	bnez	a4,ffffffffc0201aca <buddy_check+0x2a0>
ffffffffc0201ac6:	7eb0006f          	j	ffffffffc0202ab0 <buddy_check+0x1286>
    for (size_t i = 4; i < 8; i++) {
ffffffffc0201aca:	02878793          	addi	a5,a5,40
ffffffffc0201ace:	fef698e3          	bne	a3,a5,ffffffffc0201abe <buddy_check+0x294>
    buddy_check_invariants();
ffffffffc0201ad2:	f51fe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    struct Page *p = alloc_pages(4);
ffffffffc0201ad6:	4511                	li	a0,4
ffffffffc0201ad8:	1b8010ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
    assert(p == arena + 8);
ffffffffc0201adc:	00ad8463          	beq	s11,a0,ffffffffc0201ae4 <buddy_check+0x2ba>
ffffffffc0201ae0:	7b10006f          	j	ffffffffc0202a90 <buddy_check+0x1266>
    free_pages(p, 4);
ffffffffc0201ae4:	4591                	li	a1,4
ffffffffc0201ae6:	1b6010ef          	jal	ra,ffffffffc0202c9c <free_pages>
    assert(nr_free_pages() == 8);
ffffffffc0201aea:	1be010ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201aee:	47a1                	li	a5,8
ffffffffc0201af0:	8c2a                	mv	s8,a0
ffffffffc0201af2:	00f50463          	beq	a0,a5,ffffffffc0201afa <buddy_check+0x2d0>
ffffffffc0201af6:	77b0006f          	j	ffffffffc0202a70 <buddy_check+0x1246>
    buddy_check_invariants();
ffffffffc0201afa:	f29fe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    buddy_test_reset(arena);
ffffffffc0201afe:	8522                	mv	a0,s0
ffffffffc0201b00:	c21fe0ef          	jal	ra,ffffffffc0200720 <buddy_test_reset>
    buddy_init_memmap(arena, 3);
ffffffffc0201b04:	458d                	li	a1,3
ffffffffc0201b06:	8522                	mv	a0,s0
ffffffffc0201b08:	b4dff0ef          	jal	ra,ffffffffc0201654 <buddy_init_memmap>
    buddy_init_memmap(arena + 3, 5);
ffffffffc0201b0c:	07840793          	addi	a5,s0,120
ffffffffc0201b10:	4595                	li	a1,5
ffffffffc0201b12:	853e                	mv	a0,a5
ffffffffc0201b14:	f03e                	sd	a5,32(sp)
ffffffffc0201b16:	b3fff0ef          	jal	ra,ffffffffc0201654 <buddy_init_memmap>
    assert(nr_free_pages() == 8 && arena->property == 8);
ffffffffc0201b1a:	18e010ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201b1e:	01850463          	beq	a0,s8,ffffffffc0201b26 <buddy_check+0x2fc>
ffffffffc0201b22:	72f0006f          	j	ffffffffc0202a50 <buddy_check+0x1226>
ffffffffc0201b26:	01042c03          	lw	s8,16(s0)
ffffffffc0201b2a:	00ac0463          	beq	s8,a0,ffffffffc0201b32 <buddy_check+0x308>
ffffffffc0201b2e:	7230006f          	j	ffffffffc0202a50 <buddy_check+0x1226>
    buddy_check_invariants();
ffffffffc0201b32:	ef1fe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    buddy_check_init_memmap(arena);
    cprintf("buddy_check: init_memmap passed\n");
ffffffffc0201b36:	00005517          	auipc	a0,0x5
ffffffffc0201b3a:	f2a50513          	addi	a0,a0,-214 # ffffffffc0206a60 <etext+0xd38>
ffffffffc0201b3e:	e16fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    const size_t requests[] = {4, 2, 1, 8};
ffffffffc0201b42:	4791                	li	a5,4
ffffffffc0201b44:	f93e                	sd	a5,176(sp)
ffffffffc0201b46:	4789                	li	a5,2
ffffffffc0201b48:	fd3e                	sd	a5,184(sp)
ffffffffc0201b4a:	4785                	li	a5,1
ffffffffc0201b4c:	e5e2                	sd	s8,200(sp)
ffffffffc0201b4e:	e1be                	sd	a5,192(sp)
ffffffffc0201b50:	8cca                	mv	s9,s2
        for (size_t size = request; size < 8; size <<= 1) {
ffffffffc0201b52:	4c1d                	li	s8,7
        buddy_test_reset(arena);
ffffffffc0201b54:	8522                	mv	a0,s0
ffffffffc0201b56:	bcbfe0ef          	jal	ra,ffffffffc0200720 <buddy_test_reset>
        buddy_init_memmap(arena, 8);
ffffffffc0201b5a:	45a1                	li	a1,8
ffffffffc0201b5c:	8522                	mv	a0,s0
ffffffffc0201b5e:	af7ff0ef          	jal	ra,ffffffffc0201654 <buddy_init_memmap>
        size_t request = requests[i];
ffffffffc0201b62:	000cbb03          	ld	s6,0(s9)
        struct Page *p = alloc_pages(request);
ffffffffc0201b66:	855a                	mv	a0,s6
ffffffffc0201b68:	128010ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc0201b6c:	8d2a                	mv	s10,a0
        assert(p == arena && !PageProperty(p));
ffffffffc0201b6e:	00a40463          	beq	s0,a0,ffffffffc0201b76 <buddy_check+0x34c>
ffffffffc0201b72:	6bf0006f          	j	ffffffffc0202a30 <buddy_check+0x1206>
ffffffffc0201b76:	641c                	ld	a5,8(s0)
ffffffffc0201b78:	8b89                	andi	a5,a5,2
ffffffffc0201b7a:	c399                	beqz	a5,ffffffffc0201b80 <buddy_check+0x356>
ffffffffc0201b7c:	6b50006f          	j	ffffffffc0202a30 <buddy_check+0x1206>
        assert(nr_free_pages() == 8 - request);
ffffffffc0201b80:	128010ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201b84:	47a1                	li	a5,8
ffffffffc0201b86:	416787b3          	sub	a5,a5,s6
ffffffffc0201b8a:	00f50463          	beq	a0,a5,ffffffffc0201b92 <buddy_check+0x368>
ffffffffc0201b8e:	6830006f          	j	ffffffffc0202a10 <buddy_check+0x11e6>
        for (size_t size = request; size < 8; size <<= 1) {
ffffffffc0201b92:	875a                	mv	a4,s6
ffffffffc0201b94:	036c6563          	bltu	s8,s6,ffffffffc0201bbe <buddy_check+0x394>
            assert(PageProperty(arena + size));
ffffffffc0201b98:	00271793          	slli	a5,a4,0x2
ffffffffc0201b9c:	97ba                	add	a5,a5,a4
ffffffffc0201b9e:	078e                	slli	a5,a5,0x3
ffffffffc0201ba0:	97a2                	add	a5,a5,s0
ffffffffc0201ba2:	6794                	ld	a3,8(a5)
ffffffffc0201ba4:	8a89                	andi	a3,a3,2
ffffffffc0201ba6:	e299                	bnez	a3,ffffffffc0201bac <buddy_check+0x382>
ffffffffc0201ba8:	6490006f          	j	ffffffffc02029f0 <buddy_check+0x11c6>
            assert(arena[size].property == size);
ffffffffc0201bac:	0107e783          	lwu	a5,16(a5)
ffffffffc0201bb0:	00e78463          	beq	a5,a4,ffffffffc0201bb8 <buddy_check+0x38e>
ffffffffc0201bb4:	61d0006f          	j	ffffffffc02029d0 <buddy_check+0x11a6>
        for (size_t size = request; size < 8; size <<= 1) {
ffffffffc0201bb8:	0706                	slli	a4,a4,0x1
ffffffffc0201bba:	fcec7fe3          	bgeu	s8,a4,ffffffffc0201b98 <buddy_check+0x36e>
        buddy_check_invariants();
ffffffffc0201bbe:	e65fe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
        free_pages(p, request);
ffffffffc0201bc2:	85da                	mv	a1,s6
ffffffffc0201bc4:	856a                	mv	a0,s10
ffffffffc0201bc6:	0d6010ef          	jal	ra,ffffffffc0202c9c <free_pages>
        assert(nr_free_pages() == 8 && arena->property == 8);
ffffffffc0201bca:	0de010ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201bce:	4721                	li	a4,8
ffffffffc0201bd0:	00e50463          	beq	a0,a4,ffffffffc0201bd8 <buddy_check+0x3ae>
ffffffffc0201bd4:	5dd0006f          	j	ffffffffc02029b0 <buddy_check+0x1186>
ffffffffc0201bd8:	4818                	lw	a4,16(s0)
ffffffffc0201bda:	00a70463          	beq	a4,a0,ffffffffc0201be2 <buddy_check+0x3b8>
ffffffffc0201bde:	5d30006f          	j	ffffffffc02029b0 <buddy_check+0x1186>
        buddy_check_invariants();
ffffffffc0201be2:	e41fe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
ffffffffc0201be6:	0ca1                	addi	s9,s9,8
ffffffffc0201be8:	099c                	addi	a5,sp,208
ffffffffc0201bea:	f79795e3          	bne	a5,s9,ffffffffc0201b54 <buddy_check+0x32a>
    buddy_check_split(arena);
    cprintf("buddy_check: split passed\n");
ffffffffc0201bee:	00005517          	auipc	a0,0x5
ffffffffc0201bf2:	f1a50513          	addi	a0,a0,-230 # ffffffffc0206b08 <etext+0xde0>
ffffffffc0201bf6:	d5efe0ef          	jal	ra,ffffffffc0200154 <cprintf>
        buddy_init_memmap(arena, 8);
ffffffffc0201bfa:	4b21                	li	s6,8
    for (size_t reverse = 0; reverse < 2; reverse++) {
ffffffffc0201bfc:	e402                	sd	zero,8(sp)
        buddy_test_reset(arena);
ffffffffc0201bfe:	8522                	mv	a0,s0
ffffffffc0201c00:	b21fe0ef          	jal	ra,ffffffffc0200720 <buddy_test_reset>
        buddy_init_memmap(arena, 8);
ffffffffc0201c04:	45a1                	li	a1,8
ffffffffc0201c06:	8522                	mv	a0,s0
ffffffffc0201c08:	a4dff0ef          	jal	ra,ffffffffc0201654 <buddy_init_memmap>
        for (size_t i = 0; i < 8; i++) {
ffffffffc0201c0c:	8d4a                	mv	s10,s2
        buddy_init_memmap(arena, 8);
ffffffffc0201c0e:	8c22                	mv	s8,s0
ffffffffc0201c10:	8cca                	mv	s9,s2
            allocated[i] = alloc_pages(1);
ffffffffc0201c12:	4505                	li	a0,1
ffffffffc0201c14:	07c010ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc0201c18:	00acb023          	sd	a0,0(s9)
            assert(allocated[i] == arena + i);
ffffffffc0201c1c:	57851ae3          	bne	a0,s8,ffffffffc0202990 <buddy_check+0x1166>
        for (size_t i = 0; i < 8; i++) {
ffffffffc0201c20:	028c0c13          	addi	s8,s8,40
ffffffffc0201c24:	0ca1                	addi	s9,s9,8
ffffffffc0201c26:	ff8d96e3          	bne	s11,s8,ffffffffc0201c12 <buddy_check+0x3e8>
ffffffffc0201c2a:	8cca                	mv	s9,s2
        for (size_t i = 0; i < 8; i++) {
ffffffffc0201c2c:	4781                	li	a5,0
ffffffffc0201c2e:	a00d                	j	ffffffffc0201c50 <buddy_check+0x426>
            free_pages(allocated[reverse ? 7 - i : i], 1);
ffffffffc0201c30:	038d3503          	ld	a0,56(s10)
ffffffffc0201c34:	4585                	li	a1,1
ffffffffc0201c36:	066010ef          	jal	ra,ffffffffc0202c9c <free_pages>
            assert(nr_free_pages() == i + 1);
ffffffffc0201c3a:	06e010ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201c3e:	5f851f63          	bne	a0,s8,ffffffffc020223c <buddy_check+0xa12>
            buddy_check_invariants();
ffffffffc0201c42:	de1fe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
        for (size_t i = 0; i < 8; i++) {
ffffffffc0201c46:	056c0163          	beq	s8,s6,ffffffffc0201c88 <buddy_check+0x45e>
ffffffffc0201c4a:	1d61                	addi	s10,s10,-8
ffffffffc0201c4c:	0ca1                	addi	s9,s9,8
            assert(nr_free_pages() == i + 1);
ffffffffc0201c4e:	87e2                	mv	a5,s8
            free_pages(allocated[reverse ? 7 - i : i], 1);
ffffffffc0201c50:	6722                	ld	a4,8(sp)
            assert(nr_free_pages() == i + 1);
ffffffffc0201c52:	00178c13          	addi	s8,a5,1
            free_pages(allocated[reverse ? 7 - i : i], 1);
ffffffffc0201c56:	ff69                	bnez	a4,ffffffffc0201c30 <buddy_check+0x406>
ffffffffc0201c58:	000cb503          	ld	a0,0(s9)
ffffffffc0201c5c:	4585                	li	a1,1
ffffffffc0201c5e:	f43e                	sd	a5,40(sp)
ffffffffc0201c60:	03c010ef          	jal	ra,ffffffffc0202c9c <free_pages>
            assert(nr_free_pages() == i + 1);
ffffffffc0201c64:	044010ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201c68:	77a2                	ld	a5,40(sp)
ffffffffc0201c6a:	5d851963          	bne	a0,s8,ffffffffc020223c <buddy_check+0xa12>
            if (!reverse && (i == 1 || i == 3 || i == 7)) {
ffffffffc0201c6e:	ffd7f713          	andi	a4,a5,-3
ffffffffc0201c72:	4685                	li	a3,1
ffffffffc0201c74:	5ad70d63          	beq	a4,a3,ffffffffc020222e <buddy_check+0xa04>
ffffffffc0201c78:	471d                	li	a4,7
ffffffffc0201c7a:	fce794e3          	bne	a5,a4,ffffffffc0201c42 <buddy_check+0x418>
                assert(arena->property == i + 1);
ffffffffc0201c7e:	481c                	lw	a5,16(s0)
ffffffffc0201c80:	4f6798e3          	bne	a5,s6,ffffffffc0202970 <buddy_check+0x1146>
            buddy_check_invariants();
ffffffffc0201c84:	d9ffe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
        assert(PageProperty(arena) && arena->property == 8);
ffffffffc0201c88:	641c                	ld	a5,8(s0)
ffffffffc0201c8a:	8b89                	andi	a5,a5,2
ffffffffc0201c8c:	4c0782e3          	beqz	a5,ffffffffc0202950 <buddy_check+0x1126>
ffffffffc0201c90:	481c                	lw	a5,16(s0)
ffffffffc0201c92:	4b679fe3          	bne	a5,s6,ffffffffc0202950 <buddy_check+0x1126>
    for (size_t reverse = 0; reverse < 2; reverse++) {
ffffffffc0201c96:	67a2                	ld	a5,8(sp)
ffffffffc0201c98:	5c078263          	beqz	a5,ffffffffc020225c <buddy_check+0xa32>
    buddy_check_merge(arena);
    cprintf("buddy_check: merge passed\n");
ffffffffc0201c9c:	00005517          	auipc	a0,0x5
ffffffffc0201ca0:	f1c50513          	addi	a0,a0,-228 # ffffffffc0206bb8 <etext+0xe90>
ffffffffc0201ca4:	cb0fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    buddy_test_reset(arena);
ffffffffc0201ca8:	8522                	mv	a0,s0
ffffffffc0201caa:	a77fe0ef          	jal	ra,ffffffffc0200720 <buddy_test_reset>
    buddy_init_memmap(arena, 8);
ffffffffc0201cae:	45a1                	li	a1,8
ffffffffc0201cb0:	8522                	mv	a0,s0
ffffffffc0201cb2:	9a3ff0ef          	jal	ra,ffffffffc0201654 <buddy_init_memmap>
ffffffffc0201cb6:	8c22                	mv	s8,s0
ffffffffc0201cb8:	8cca                	mv	s9,s2
        allocated[i] = alloc_pages(1);
ffffffffc0201cba:	4505                	li	a0,1
ffffffffc0201cbc:	7d5000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc0201cc0:	00acb023          	sd	a0,0(s9)
        assert(allocated[i] == arena + i);
ffffffffc0201cc4:	478516e3          	bne	a0,s8,ffffffffc0202930 <buddy_check+0x1106>
    for (size_t i = 0; i < 8; i++) {
ffffffffc0201cc8:	028c0c13          	addi	s8,s8,40
ffffffffc0201ccc:	0ca1                	addi	s9,s9,8
ffffffffc0201cce:	ff8d96e3          	bne	s11,s8,ffffffffc0201cba <buddy_check+0x490>
    free_pages(allocated[1], 1);
ffffffffc0201cd2:	756a                	ld	a0,184(sp)
ffffffffc0201cd4:	4585                	li	a1,1
ffffffffc0201cd6:	7c7000ef          	jal	ra,ffffffffc0202c9c <free_pages>
    free_pages(allocated[2], 1);
ffffffffc0201cda:	650e                	ld	a0,192(sp)
ffffffffc0201cdc:	4585                	li	a1,1
ffffffffc0201cde:	7bf000ef          	jal	ra,ffffffffc0202c9c <free_pages>
    assert(arena[1].property == 1 && arena[2].property == 1);
ffffffffc0201ce2:	5c1c                	lw	a5,56(s0)
ffffffffc0201ce4:	4705                	li	a4,1
ffffffffc0201ce6:	42e795e3          	bne	a5,a4,ffffffffc0202910 <buddy_check+0x10e6>
ffffffffc0201cea:	06042c03          	lw	s8,96(s0)
ffffffffc0201cee:	42fc11e3          	bne	s8,a5,ffffffffc0202910 <buddy_check+0x10e6>
ffffffffc0201cf2:	000bb783          	ld	a5,0(s7)
ffffffffc0201cf6:	40fa0733          	sub	a4,s4,a5
ffffffffc0201cfa:	870d                	srai	a4,a4,0x3
ffffffffc0201cfc:	40f407b3          	sub	a5,s0,a5
ffffffffc0201d00:	03570733          	mul	a4,a4,s5
ffffffffc0201d04:	878d                	srai	a5,a5,0x3
ffffffffc0201d06:	035787b3          	mul	a5,a5,s5
ffffffffc0201d0a:	974e                	add	a4,a4,s3
    assert((page2ppn(arena + 1) ^ 1) == page2ppn(arena));
ffffffffc0201d0c:	00174713          	xori	a4,a4,1
ffffffffc0201d10:	97ce                	add	a5,a5,s3
ffffffffc0201d12:	3cf71fe3          	bne	a4,a5,ffffffffc02028f0 <buddy_check+0x10c6>
    assert(buddy_find_partner(arena + 1, 0) == NULL);
ffffffffc0201d16:	4581                	li	a1,0
ffffffffc0201d18:	8552                	mv	a0,s4
ffffffffc0201d1a:	adbfe0ef          	jal	ra,ffffffffc02007f4 <buddy_find_partner>
ffffffffc0201d1e:	3a0519e3          	bnez	a0,ffffffffc02028d0 <buddy_check+0x10a6>
    buddy_check_invariants();
ffffffffc0201d22:	d01fe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    free_pages(allocated[0], 1);
ffffffffc0201d26:	754a                	ld	a0,176(sp)
ffffffffc0201d28:	4585                	li	a1,1
ffffffffc0201d2a:	773000ef          	jal	ra,ffffffffc0202c9c <free_pages>
    assert(arena->property == 2 && arena[2].property == 1);
ffffffffc0201d2e:	4818                	lw	a4,16(s0)
ffffffffc0201d30:	4789                	li	a5,2
ffffffffc0201d32:	36f71fe3          	bne	a4,a5,ffffffffc02028b0 <buddy_check+0x1086>
ffffffffc0201d36:	503c                	lw	a5,96(s0)
ffffffffc0201d38:	37879ce3          	bne	a5,s8,ffffffffc02028b0 <buddy_check+0x1086>
    assert(buddy_find_partner(arena, 1) == NULL);
ffffffffc0201d3c:	4585                	li	a1,1
ffffffffc0201d3e:	8522                	mv	a0,s0
ffffffffc0201d40:	ab5fe0ef          	jal	ra,ffffffffc02007f4 <buddy_find_partner>
ffffffffc0201d44:	340516e3          	bnez	a0,ffffffffc0202890 <buddy_check+0x1066>
    assert(buddy_find_partner(arena + 5, 0) == NULL);
ffffffffc0201d48:	4581                	li	a1,0
ffffffffc0201d4a:	0c840513          	addi	a0,s0,200
ffffffffc0201d4e:	aa7fe0ef          	jal	ra,ffffffffc02007f4 <buddy_find_partner>
ffffffffc0201d52:	0c810c13          	addi	s8,sp,200
ffffffffc0201d56:	04090c93          	addi	s9,s2,64
ffffffffc0201d5a:	30051be3          	bnez	a0,ffffffffc0202870 <buddy_check+0x1046>
        free_pages(allocated[i], 1);
ffffffffc0201d5e:	000c3503          	ld	a0,0(s8)
ffffffffc0201d62:	4585                	li	a1,1
    for (size_t i = 3; i < 8; i++) {
ffffffffc0201d64:	0c21                	addi	s8,s8,8
        free_pages(allocated[i], 1);
ffffffffc0201d66:	737000ef          	jal	ra,ffffffffc0202c9c <free_pages>
    for (size_t i = 3; i < 8; i++) {
ffffffffc0201d6a:	ff8c9ae3          	bne	s9,s8,ffffffffc0201d5e <buddy_check+0x534>
    assert(arena->property == 8 && nr_free_pages() == 8);
ffffffffc0201d6e:	01042c03          	lw	s8,16(s0)
ffffffffc0201d72:	47a1                	li	a5,8
ffffffffc0201d74:	2cfc1ee3          	bne	s8,a5,ffffffffc0202850 <buddy_check+0x1026>
ffffffffc0201d78:	731000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201d7c:	2d851ae3          	bne	a0,s8,ffffffffc0202850 <buddy_check+0x1026>
    buddy_check_invariants();
ffffffffc0201d80:	ca3fe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    buddy_test_reset(arena);
ffffffffc0201d84:	8522                	mv	a0,s0
ffffffffc0201d86:	99bfe0ef          	jal	ra,ffffffffc0200720 <buddy_test_reset>
    buddy_init_memmap(arena + 1, 1);
ffffffffc0201d8a:	4585                	li	a1,1
ffffffffc0201d8c:	8552                	mv	a0,s4
ffffffffc0201d8e:	8c7ff0ef          	jal	ra,ffffffffc0201654 <buddy_init_memmap>
    assert(buddy_find_partner(arena + 1, 0) == NULL);
ffffffffc0201d92:	4581                	li	a1,0
ffffffffc0201d94:	8552                	mv	a0,s4
ffffffffc0201d96:	a5ffe0ef          	jal	ra,ffffffffc02007f4 <buddy_find_partner>
ffffffffc0201d9a:	28051be3          	bnez	a0,ffffffffc0202830 <buddy_check+0x1006>
    assert(PageReserved(arena));
ffffffffc0201d9e:	00843883          	ld	a7,8(s0)
ffffffffc0201da2:	0018fb13          	andi	s6,a7,1
ffffffffc0201da6:	260b05e3          	beqz	s6,ffffffffc0202810 <buddy_check+0xfe6>
    assert(buddy_find_partner(pages, buddy->max_order) == NULL);
ffffffffc0201daa:	0000a797          	auipc	a5,0xa
ffffffffc0201dae:	26678793          	addi	a5,a5,614 # ffffffffc020c010 <buddy>
ffffffffc0201db2:	639c                	ld	a5,0(a5)
ffffffffc0201db4:	000bb503          	ld	a0,0(s7)
ffffffffc0201db8:	4107b583          	ld	a1,1040(a5)
ffffffffc0201dbc:	a39fe0ef          	jal	ra,ffffffffc02007f4 <buddy_find_partner>
ffffffffc0201dc0:	220518e3          	bnez	a0,ffffffffc02027f0 <buddy_check+0xfc6>
    buddy_check_invariants();
ffffffffc0201dc4:	c5ffe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    buddy_check_partner(arena);
    cprintf("buddy_check: partner passed\n");
ffffffffc0201dc8:	00005517          	auipc	a0,0x5
ffffffffc0201dcc:	fb050513          	addi	a0,a0,-80 # ffffffffc0206d78 <etext+0x1050>
ffffffffc0201dd0:	b84fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    const size_t requests[] = {1, 2, 3, 5, 6, 7, 8, 9};
ffffffffc0201dd4:	0304be83          	ld	t4,48(s1)
ffffffffc0201dd8:	0384be03          	ld	t3,56(s1)
ffffffffc0201ddc:	0404b303          	ld	t1,64(s1)
ffffffffc0201de0:	64a8                	ld	a0,72(s1)
ffffffffc0201de2:	68ac                	ld	a1,80(s1)
ffffffffc0201de4:	6cb0                	ld	a2,88(s1)
ffffffffc0201de6:	70b4                	ld	a3,96(s1)
ffffffffc0201de8:	74b8                	ld	a4,104(s1)
        uint32_t owner = buddy->owner[p - pages];
ffffffffc0201dea:	000207b7          	lui	a5,0x20
ffffffffc0201dee:	10778793          	addi	a5,a5,263 # 20107 <kern_entry-0xffffffffc01dfef9>
    const size_t requests[] = {1, 2, 3, 5, 6, 7, 8, 9};
ffffffffc0201df2:	f976                	sd	t4,176(sp)
ffffffffc0201df4:	fd72                	sd	t3,184(sp)
ffffffffc0201df6:	e19a                	sd	t1,192(sp)
ffffffffc0201df8:	e5aa                	sd	a0,200(sp)
ffffffffc0201dfa:	e9ae                	sd	a1,208(sp)
ffffffffc0201dfc:	edb2                	sd	a2,216(sp)
ffffffffc0201dfe:	f1b6                	sd	a3,224(sp)
ffffffffc0201e00:	f5ba                	sd	a4,232(sp)
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
ffffffffc0201e02:	8d4a                	mv	s10,s2
ffffffffc0201e04:	e43e                	sd	a5,8(sp)
        buddy_test_reset(arena);
ffffffffc0201e06:	8522                	mv	a0,s0
ffffffffc0201e08:	919fe0ef          	jal	ra,ffffffffc0200720 <buddy_test_reset>
        buddy_init_memmap(arena, BUDDY_TEST_PAGES);
ffffffffc0201e0c:	04000593          	li	a1,64
ffffffffc0201e10:	8522                	mv	a0,s0
ffffffffc0201e12:	843ff0ef          	jal	ra,ffffffffc0201654 <buddy_init_memmap>
        size_t n = requests[i];
ffffffffc0201e16:	000d3c83          	ld	s9,0(s10)
    while (size < n && order < buddy->max_order) {
ffffffffc0201e1a:	4785                	li	a5,1
ffffffffc0201e1c:	5f97fe63          	bgeu	a5,s9,ffffffffc0202418 <buddy_check+0xbee>
ffffffffc0201e20:	0000a797          	auipc	a5,0xa
ffffffffc0201e24:	1f078793          	addi	a5,a5,496 # ffffffffc020c010 <buddy>
ffffffffc0201e28:	6398                	ld	a4,0(a5)
    size_t order = 0, size = 1;
ffffffffc0201e2a:	4681                	li	a3,0
ffffffffc0201e2c:	87da                	mv	a5,s6
    while (size < n && order < buddy->max_order) {
ffffffffc0201e2e:	41073703          	ld	a4,1040(a4)
ffffffffc0201e32:	42d70863          	beq	a4,a3,ffffffffc0202262 <buddy_check+0xa38>
        size <<= 1;
ffffffffc0201e36:	0786                	slli	a5,a5,0x1
        order++;
ffffffffc0201e38:	0685                	addi	a3,a3,1
    while (size < n && order < buddy->max_order) {
ffffffffc0201e3a:	ff97ece3          	bltu	a5,s9,ffffffffc0201e32 <buddy_check+0x608>
        size_t size = (size_t)1 << buddy_get_order(n);
ffffffffc0201e3e:	4785                	li	a5,1
ffffffffc0201e40:	0006849b          	sext.w	s1,a3
ffffffffc0201e44:	00d796b3          	sll	a3,a5,a3
ffffffffc0201e48:	ec36                	sd	a3,24(sp)
        size_t before = nr_free_pages();
ffffffffc0201e4a:	65f000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201e4e:	8c2a                	mv	s8,a0
        struct Page *p = alloc_pages(n);
ffffffffc0201e50:	8566                	mv	a0,s9
ffffffffc0201e52:	63f000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
        assert(p != NULL && (page2ppn(p) & (size - 1)) == 0);
ffffffffc0201e56:	66e2                	ld	a3,24(sp)
        struct Page *p = alloc_pages(n);
ffffffffc0201e58:	832a                	mv	t1,a0
        assert(p != NULL && (page2ppn(p) & (size - 1)) == 0);
ffffffffc0201e5a:	16050be3          	beqz	a0,ffffffffc02027d0 <buddy_check+0xfa6>
ffffffffc0201e5e:	000bb783          	ld	a5,0(s7)
ffffffffc0201e62:	fff68713          	addi	a4,a3,-1
ffffffffc0201e66:	40f507b3          	sub	a5,a0,a5
ffffffffc0201e6a:	878d                	srai	a5,a5,0x3
ffffffffc0201e6c:	035787b3          	mul	a5,a5,s5
ffffffffc0201e70:	97ce                	add	a5,a5,s3
ffffffffc0201e72:	8ff9                	and	a5,a5,a4
ffffffffc0201e74:	14079ee3          	bnez	a5,ffffffffc02027d0 <buddy_check+0xfa6>
        assert(before - nr_free_pages() == size);
ffffffffc0201e78:	f41a                	sd	t1,40(sp)
ffffffffc0201e7a:	ec36                	sd	a3,24(sp)
ffffffffc0201e7c:	62d000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201e80:	66e2                	ld	a3,24(sp)
ffffffffc0201e82:	40ac07b3          	sub	a5,s8,a0
ffffffffc0201e86:	7322                	ld	t1,40(sp)
ffffffffc0201e88:	12f694e3          	bne	a3,a5,ffffffffc02027b0 <buddy_check+0xf86>
        uint32_t owner = buddy->owner[p - pages];
ffffffffc0201e8c:	000bb783          	ld	a5,0(s7)
ffffffffc0201e90:	0000a717          	auipc	a4,0xa
ffffffffc0201e94:	18070713          	addi	a4,a4,384 # ffffffffc020c010 <buddy>
ffffffffc0201e98:	00020637          	lui	a2,0x20
ffffffffc0201e9c:	40f307b3          	sub	a5,t1,a5
ffffffffc0201ea0:	878d                	srai	a5,a5,0x3
ffffffffc0201ea2:	035787b3          	mul	a5,a5,s5
ffffffffc0201ea6:	6318                	ld	a4,0(a4)
ffffffffc0201ea8:	10460613          	addi	a2,a2,260 # 20104 <kern_entry-0xffffffffc01dfefc>
ffffffffc0201eac:	963e                	add	a2,a2,a5
ffffffffc0201eae:	060a                	slli	a2,a2,0x2
ffffffffc0201eb0:	963a                	add	a2,a2,a4
ffffffffc0201eb2:	4648                	lw	a0,12(a2)
        assert(buddy->allocation[owner - 1].span == size);
ffffffffc0201eb4:	fff5061b          	addiw	a2,a0,-1
ffffffffc0201eb8:	02061593          	slli	a1,a2,0x20
ffffffffc0201ebc:	01c5d613          	srli	a2,a1,0x1c
ffffffffc0201ec0:	963a                	add	a2,a2,a4
ffffffffc0201ec2:	42066603          	lwu	a2,1056(a2)
ffffffffc0201ec6:	0cc695e3          	bne	a3,a2,ffffffffc0202790 <buddy_check+0xf66>
        for (size_t j = 0; j < size; j++) {
ffffffffc0201eca:	c68d                	beqz	a3,ffffffffc0201ef4 <buddy_check+0x6ca>
ffffffffc0201ecc:	6622                	ld	a2,8(sp)
ffffffffc0201ece:	00830593          	addi	a1,t1,8
ffffffffc0201ed2:	97b2                	add	a5,a5,a2
ffffffffc0201ed4:	078a                	slli	a5,a5,0x2
ffffffffc0201ed6:	973e                	add	a4,a4,a5
ffffffffc0201ed8:	4601                	li	a2,0
            assert(!PageProperty(p + j) && buddy->owner[p - pages + j] == owner);
ffffffffc0201eda:	619c                	ld	a5,0(a1)
ffffffffc0201edc:	8b89                	andi	a5,a5,2
ffffffffc0201ede:	54079963          	bnez	a5,ffffffffc0202430 <buddy_check+0xc06>
ffffffffc0201ee2:	431c                	lw	a5,0(a4)
ffffffffc0201ee4:	54a79663          	bne	a5,a0,ffffffffc0202430 <buddy_check+0xc06>
        for (size_t j = 0; j < size; j++) {
ffffffffc0201ee8:	0605                	addi	a2,a2,1
ffffffffc0201eea:	02858593          	addi	a1,a1,40
ffffffffc0201eee:	0711                	addi	a4,a4,4
ffffffffc0201ef0:	fec695e3          	bne	a3,a2,ffffffffc0201eda <buddy_check+0x6b0>
        struct Page *other = alloc_pages(1);
ffffffffc0201ef4:	4505                	li	a0,1
ffffffffc0201ef6:	ec1a                	sd	t1,24(sp)
ffffffffc0201ef8:	599000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc0201efc:	87aa                	mv	a5,a0
        assert(other != NULL && (other < p || other >= p + size));
ffffffffc0201efe:	060509e3          	beqz	a0,ffffffffc0202770 <buddy_check+0xf46>
ffffffffc0201f02:	6362                	ld	t1,24(sp)
ffffffffc0201f04:	00656963          	bltu	a0,t1,ffffffffc0201f16 <buddy_check+0x6ec>
ffffffffc0201f08:	02800713          	li	a4,40
ffffffffc0201f0c:	00971733          	sll	a4,a4,s1
ffffffffc0201f10:	971a                	add	a4,a4,t1
ffffffffc0201f12:	04e56fe3          	bltu	a0,a4,ffffffffc0202770 <buddy_check+0xf46>
        free_pages(p, n);
ffffffffc0201f16:	851a                	mv	a0,t1
ffffffffc0201f18:	85e6                	mv	a1,s9
ffffffffc0201f1a:	ec3e                	sd	a5,24(sp)
ffffffffc0201f1c:	581000ef          	jal	ra,ffffffffc0202c9c <free_pages>
        free_pages(other, 1);
ffffffffc0201f20:	67e2                	ld	a5,24(sp)
ffffffffc0201f22:	4585                	li	a1,1
ffffffffc0201f24:	853e                	mv	a0,a5
ffffffffc0201f26:	577000ef          	jal	ra,ffffffffc0202c9c <free_pages>
        assert(nr_free_pages() == before && arena->property == BUDDY_TEST_PAGES);
ffffffffc0201f2a:	57f000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201f2e:	038511e3          	bne	a0,s8,ffffffffc0202750 <buddy_check+0xf26>
ffffffffc0201f32:	4804                	lw	s1,16(s0)
ffffffffc0201f34:	04000793          	li	a5,64
ffffffffc0201f38:	00f49ce3          	bne	s1,a5,ffffffffc0202750 <buddy_check+0xf26>
        buddy_check_invariants();
ffffffffc0201f3c:	ae7fe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
ffffffffc0201f40:	0d21                	addi	s10,s10,8
ffffffffc0201f42:	199c                	addi	a5,sp,240
ffffffffc0201f44:	eda791e3          	bne	a5,s10,ffffffffc0201e06 <buddy_check+0x5dc>
    buddy_test_reset(arena);
ffffffffc0201f48:	8522                	mv	a0,s0
ffffffffc0201f4a:	fd6fe0ef          	jal	ra,ffffffffc0200720 <buddy_test_reset>
    buddy_init_memmap(arena, 16);
ffffffffc0201f4e:	8522                	mv	a0,s0
ffffffffc0201f50:	45c1                	li	a1,16
ffffffffc0201f52:	f02ff0ef          	jal	ra,ffffffffc0201654 <buddy_init_memmap>
    struct Page *p = alloc_pages(5);
ffffffffc0201f56:	4515                	li	a0,5
ffffffffc0201f58:	539000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
    assert(p == arena && nr_free_pages() == 8);
ffffffffc0201f5c:	7ca41a63          	bne	s0,a0,ffffffffc0202730 <buddy_check+0xf06>
ffffffffc0201f60:	549000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201f64:	47a1                	li	a5,8
ffffffffc0201f66:	7cf51563          	bne	a0,a5,ffffffffc0202730 <buddy_check+0xf06>
    free_pages(p + 1, 2);
ffffffffc0201f6a:	4589                	li	a1,2
ffffffffc0201f6c:	8552                	mv	a0,s4
ffffffffc0201f6e:	52f000ef          	jal	ra,ffffffffc0202c9c <free_pages>
    free_pages(p, 1);
ffffffffc0201f72:	4585                	li	a1,1
ffffffffc0201f74:	8522                	mv	a0,s0
ffffffffc0201f76:	527000ef          	jal	ra,ffffffffc0202c9c <free_pages>
    assert(nr_free_pages() == 11);
ffffffffc0201f7a:	52f000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201f7e:	47ad                	li	a5,11
ffffffffc0201f80:	78f51863          	bne	a0,a5,ffffffffc0202710 <buddy_check+0xee6>
    struct Page *replacement = alloc_pages(2);
ffffffffc0201f84:	4509                	li	a0,2
ffffffffc0201f86:	50b000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
    assert(replacement == p);
ffffffffc0201f8a:	76a41363          	bne	s0,a0,ffffffffc02026f0 <buddy_check+0xec6>
    buddy_check_invariants();
ffffffffc0201f8e:	a95fe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    free_pages(p + 3, 2);
ffffffffc0201f92:	7502                	ld	a0,32(sp)
ffffffffc0201f94:	4589                	li	a1,2
ffffffffc0201f96:	507000ef          	jal	ra,ffffffffc0202c9c <free_pages>
    assert(nr_free_pages() == 14);
ffffffffc0201f9a:	50f000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201f9e:	47b9                	li	a5,14
ffffffffc0201fa0:	72f51863          	bne	a0,a5,ffffffffc02026d0 <buddy_check+0xea6>
    buddy_check_invariants();
ffffffffc0201fa4:	a7ffe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    free_pages(replacement, 2);
ffffffffc0201fa8:	4589                	li	a1,2
ffffffffc0201faa:	8522                	mv	a0,s0
ffffffffc0201fac:	4f1000ef          	jal	ra,ffffffffc0202c9c <free_pages>
    assert(nr_free_pages() == 16 && arena->property == 16);
ffffffffc0201fb0:	4f9000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201fb4:	4741                	li	a4,16
ffffffffc0201fb6:	6ee51d63          	bne	a0,a4,ffffffffc02026b0 <buddy_check+0xe86>
ffffffffc0201fba:	4818                	lw	a4,16(s0)
ffffffffc0201fbc:	6ea71a63          	bne	a4,a0,ffffffffc02026b0 <buddy_check+0xe86>
    buddy_check_invariants();
ffffffffc0201fc0:	a63fe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    struct Page *a = alloc_pages(2);
ffffffffc0201fc4:	4509                	li	a0,2
ffffffffc0201fc6:	4cb000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc0201fca:	89aa                	mv	s3,a0
    struct Page *b = alloc_pages(2);
ffffffffc0201fcc:	4509                	li	a0,2
ffffffffc0201fce:	4c3000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
    assert(a == arena && b == a + 2);
ffffffffc0201fd2:	6b341f63          	bne	s0,s3,ffffffffc0202690 <buddy_check+0xe66>
ffffffffc0201fd6:	05040713          	addi	a4,s0,80
ffffffffc0201fda:	6ae51b63          	bne	a0,a4,ffffffffc0202690 <buddy_check+0xe66>
    free_pages(a, 4);
ffffffffc0201fde:	4591                	li	a1,4
ffffffffc0201fe0:	8522                	mv	a0,s0
ffffffffc0201fe2:	4bb000ef          	jal	ra,ffffffffc0202c9c <free_pages>
    assert(nr_free_pages() == 16 && arena->property == 16);
ffffffffc0201fe6:	4c3000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0201fea:	4741                	li	a4,16
ffffffffc0201fec:	68e51263          	bne	a0,a4,ffffffffc0202670 <buddy_check+0xe46>
ffffffffc0201ff0:	4818                	lw	a4,16(s0)
ffffffffc0201ff2:	66a71f63          	bne	a4,a0,ffffffffc0202670 <buddy_check+0xe46>
    buddy_check_invariants();
ffffffffc0201ff6:	a2dfe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    buddy_check_non_power_two(arena);
    cprintf("buddy_check: non_power_two and partial release passed\n");
ffffffffc0201ffa:	00005517          	auipc	a0,0x5
ffffffffc0201ffe:	fa650513          	addi	a0,a0,-90 # ffffffffc0206fa0 <etext+0x1278>
ffffffffc0202002:	952fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    buddy_test_reset(arena);
ffffffffc0202006:	8522                	mv	a0,s0
ffffffffc0202008:	f18fe0ef          	jal	ra,ffffffffc0200720 <buddy_test_reset>
    buddy_init_memmap(arena, 8);
ffffffffc020200c:	45a1                	li	a1,8
ffffffffc020200e:	8522                	mv	a0,s0
ffffffffc0202010:	e44ff0ef          	jal	ra,ffffffffc0201654 <buddy_init_memmap>
    for (size_t i = 0; i < 8; i++) {
ffffffffc0202014:	89ca                	mv	s3,s2
    buddy_init_memmap(arena, 8);
ffffffffc0202016:	8a22                	mv	s4,s0
ffffffffc0202018:	8aca                	mv	s5,s2
        allocated[i] = alloc_pages(1);
ffffffffc020201a:	4505                	li	a0,1
ffffffffc020201c:	475000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc0202020:	00aab023          	sd	a0,0(s5)
        assert(allocated[i] == arena + i);
ffffffffc0202024:	63451663          	bne	a0,s4,ffffffffc0202650 <buddy_check+0xe26>
    for (size_t i = 0; i < 8; i++) {
ffffffffc0202028:	028a0a13          	addi	s4,s4,40
ffffffffc020202c:	0aa1                	addi	s5,s5,8
ffffffffc020202e:	ff4d96e3          	bne	s11,s4,ffffffffc020201a <buddy_check+0x7f0>
    assert(nr_free_pages() == 0 && alloc_pages(1) == NULL);
ffffffffc0202032:	477000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0202036:	5e051d63          	bnez	a0,ffffffffc0202630 <buddy_check+0xe06>
ffffffffc020203a:	4505                	li	a0,1
ffffffffc020203c:	455000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc0202040:	5e051863          	bnez	a0,ffffffffc0202630 <buddy_check+0xe06>
    buddy_check_invariants();
ffffffffc0202044:	9dffe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    for (size_t i = 0; i < 8; i += 2) {
ffffffffc0202048:	04090a93          	addi	s5,s2,64
    buddy_check_invariants();
ffffffffc020204c:	8a4a                	mv	s4,s2
        free_pages(allocated[i], 1);
ffffffffc020204e:	000a3503          	ld	a0,0(s4)
ffffffffc0202052:	4585                	li	a1,1
    for (size_t i = 0; i < 8; i += 2) {
ffffffffc0202054:	0a41                	addi	s4,s4,16
        free_pages(allocated[i], 1);
ffffffffc0202056:	447000ef          	jal	ra,ffffffffc0202c9c <free_pages>
    for (size_t i = 0; i < 8; i += 2) {
ffffffffc020205a:	ff5a1ae3          	bne	s4,s5,ffffffffc020204e <buddy_check+0x824>
    assert(nr_free_pages() == 4 && alloc_pages(2) == NULL);
ffffffffc020205e:	44b000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0202062:	4791                	li	a5,4
ffffffffc0202064:	5af51663          	bne	a0,a5,ffffffffc0202610 <buddy_check+0xde6>
ffffffffc0202068:	4509                	li	a0,2
ffffffffc020206a:	427000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc020206e:	5a051163          	bnez	a0,ffffffffc0202610 <buddy_check+0xde6>
    buddy_check_invariants();
ffffffffc0202072:	9b1fe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
        free_pages(allocated[i], 1);
ffffffffc0202076:	0089b503          	ld	a0,8(s3)
ffffffffc020207a:	4585                	li	a1,1
    for (size_t i = 1; i < 8; i += 2) {
ffffffffc020207c:	09c1                	addi	s3,s3,16
        free_pages(allocated[i], 1);
ffffffffc020207e:	41f000ef          	jal	ra,ffffffffc0202c9c <free_pages>
    for (size_t i = 1; i < 8; i += 2) {
ffffffffc0202082:	ff599ae3          	bne	s3,s5,ffffffffc0202076 <buddy_check+0x84c>
    assert(nr_free_pages() == 8);
ffffffffc0202086:	423000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc020208a:	47a1                	li	a5,8
ffffffffc020208c:	89aa                	mv	s3,a0
ffffffffc020208e:	56f51163          	bne	a0,a5,ffffffffc02025f0 <buddy_check+0xdc6>
    assert(alloc_pages(9) == NULL);
ffffffffc0202092:	4525                	li	a0,9
ffffffffc0202094:	3fd000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc0202098:	52051c63          	bnez	a0,ffffffffc02025d0 <buddy_check+0xda6>
    assert(alloc_pages(BUDDY_PAGE_CAPACITY + 1) == NULL);
ffffffffc020209c:	6521                	lui	a0,0x8
ffffffffc020209e:	0505                	addi	a0,a0,1
ffffffffc02020a0:	3f1000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc02020a4:	50051663          	bnez	a0,ffffffffc02025b0 <buddy_check+0xd86>
    assert(alloc_pages(~(size_t)0) == NULL);
ffffffffc02020a8:	557d                	li	a0,-1
ffffffffc02020aa:	3e7000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc02020ae:	4e051163          	bnez	a0,ffffffffc0202590 <buddy_check+0xd66>
    assert(alloc_pages((size_t)1 << (BUDDY_ORDERS - 1)) == NULL);
ffffffffc02020b2:	557d                	li	a0,-1
ffffffffc02020b4:	157e                	slli	a0,a0,0x3f
ffffffffc02020b6:	3db000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc02020ba:	4a051b63          	bnez	a0,ffffffffc0202570 <buddy_check+0xd46>
    assert(nr_free_pages() == 8);
ffffffffc02020be:	3eb000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc02020c2:	49351763          	bne	a0,s3,ffffffffc0202550 <buddy_check+0xd26>
    struct Page *p = alloc_pages(8);
ffffffffc02020c6:	3cb000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
    assert(p == arena);
ffffffffc02020ca:	40a41363          	bne	s0,a0,ffffffffc02024d0 <buddy_check+0xca6>
    free_pages(p, 8);
ffffffffc02020ce:	45a1                	li	a1,8
ffffffffc02020d0:	3cd000ef          	jal	ra,ffffffffc0202c9c <free_pages>
    buddy_check_invariants();
ffffffffc02020d4:	94ffe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    buddy_check_exhaustion(arena);
    cprintf("buddy_check: exhaustion passed\n");
ffffffffc02020d8:	00005517          	auipc	a0,0x5
ffffffffc02020dc:	01050513          	addi	a0,a0,16 # ffffffffc02070e8 <etext+0x13c0>
ffffffffc02020e0:	874fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    buddy_test_reset(arena);
ffffffffc02020e4:	8522                	mv	a0,s0
ffffffffc02020e6:	e3afe0ef          	jal	ra,ffffffffc0200720 <buddy_test_reset>
    buddy_init_memmap(arena, BUDDY_TEST_PAGES);
ffffffffc02020ea:	04000593          	li	a1,64
ffffffffc02020ee:	8522                	mv	a0,s0
ffffffffc02020f0:	d64ff0ef          	jal	ra,ffffffffc0201654 <buddy_init_memmap>
    struct Page *allocated[16] = {0};
ffffffffc02020f4:	08000613          	li	a2,128
ffffffffc02020f8:	4581                	li	a1,0
ffffffffc02020fa:	1808                	addi	a0,sp,48
ffffffffc02020fc:	41b030ef          	jal	ra,ffffffffc0205d16 <memset>
    size_t requests[16] = {0};
ffffffffc0202100:	08000613          	li	a2,128
ffffffffc0202104:	4581                	li	a1,0
ffffffffc0202106:	854a                	mv	a0,s2
ffffffffc0202108:	40f030ef          	jal	ra,ffffffffc0205d16 <memset>
ffffffffc020210c:	10000793          	li	a5,256
        seed = seed * 1664525U + 1013904223U;
ffffffffc0202110:	3c6efa37          	lui	s4,0x3c6ef
    size_t requests[16] = {0};
ffffffffc0202114:	e43e                	sd	a5,8(sp)
    uint32_t seed = 0x20261024;
ffffffffc0202116:	202619b7          	lui	s3,0x20261
        seed = seed * 1664525U + 1013904223U;
ffffffffc020211a:	00196ab7          	lui	s5,0x196
ffffffffc020211e:	35fa079b          	addiw	a5,s4,863
    uint32_t seed = 0x20261024;
ffffffffc0202122:	02498993          	addi	s3,s3,36 # 20261024 <kern_entry-0xffffffff9ff9efdc>
        seed = seed * 1664525U + 1013904223U;
ffffffffc0202126:	60da8a9b          	addiw	s5,s5,1549
ffffffffc020212a:	cc3e                	sw	a5,24(sp)
    while (size < n && order < buddy->max_order) {
ffffffffc020212c:	4b85                	li	s7,1
                    assert(allocated[i] + size_i <= allocated[j] ||
ffffffffc020212e:	02800c93          	li	s9,40
        seed = seed * 1664525U + 1013904223U;
ffffffffc0202132:	035989bb          	mulw	s3,s3,s5
ffffffffc0202136:	47e2                	lw	a5,24(sp)
ffffffffc0202138:	00f989bb          	addw	s3,s3,a5
        size_t slot = (seed >> 16) % 16;
ffffffffc020213c:	0109dc1b          	srliw	s8,s3,0x10
ffffffffc0202140:	00fc7c13          	andi	s8,s8,15
        if (allocated[slot] != NULL) {
ffffffffc0202144:	1a1c                	addi	a5,sp,304
ffffffffc0202146:	0c0e                	slli	s8,s8,0x3
ffffffffc0202148:	01878a33          	add	s4,a5,s8
        size_t before = nr_free_pages();
ffffffffc020214c:	35d000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
        if (allocated[slot] != NULL) {
ffffffffc0202150:	f00a3603          	ld	a2,-256(s4) # 3c6eef00 <kern_entry-0xffffffff83b11100>
        size_t before = nr_free_pages();
ffffffffc0202154:	8d2a                	mv	s10,a0
        if (allocated[slot] != NULL) {
ffffffffc0202156:	20060463          	beqz	a2,ffffffffc020235e <buddy_check+0xb34>
            size_t size = (size_t)1 << buddy_get_order(requests[slot]);
ffffffffc020215a:	f80a3583          	ld	a1,-128(s4)
    while (size < n && order < buddy->max_order) {
ffffffffc020215e:	28bbf863          	bgeu	s7,a1,ffffffffc02023ee <buddy_check+0xbc4>
ffffffffc0202162:	0000a797          	auipc	a5,0xa
ffffffffc0202166:	eae78793          	addi	a5,a5,-338 # ffffffffc020c010 <buddy>
ffffffffc020216a:	6394                	ld	a3,0(a5)
    size_t order = 0, size = 1;
ffffffffc020216c:	875a                	mv	a4,s6
ffffffffc020216e:	4781                	li	a5,0
    while (size < n && order < buddy->max_order) {
ffffffffc0202170:	4106b683          	ld	a3,1040(a3)
ffffffffc0202174:	00f68963          	beq	a3,a5,ffffffffc0202186 <buddy_check+0x95c>
        size <<= 1;
ffffffffc0202178:	0706                	slli	a4,a4,0x1
        order++;
ffffffffc020217a:	0785                	addi	a5,a5,1
    while (size < n && order < buddy->max_order) {
ffffffffc020217c:	feb76ce3          	bltu	a4,a1,ffffffffc0202174 <buddy_check+0x94a>
            size_t size = (size_t)1 << buddy_get_order(requests[slot]);
ffffffffc0202180:	00fb97b3          	sll	a5,s7,a5
            assert(nr_free_pages() == before + size);
ffffffffc0202184:	9d3e                	add	s10,s10,a5
            free_pages(allocated[slot], requests[slot]);
ffffffffc0202186:	8532                	mv	a0,a2
ffffffffc0202188:	315000ef          	jal	ra,ffffffffc0202c9c <free_pages>
            allocated[slot] = NULL;
ffffffffc020218c:	1a1c                	addi	a5,sp,304
ffffffffc020218e:	9c3e                	add	s8,s8,a5
ffffffffc0202190:	f00c3023          	sd	zero,-256(s8)
            assert(nr_free_pages() == before + size);
ffffffffc0202194:	315000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0202198:	31a51c63          	bne	a0,s10,ffffffffc02024b0 <buddy_check+0xc86>
    while (size < n && order < buddy->max_order) {
ffffffffc020219c:	0000a797          	auipc	a5,0xa
ffffffffc02021a0:	e7478793          	addi	a5,a5,-396 # ffffffffc020c010 <buddy>
ffffffffc02021a4:	0007b303          	ld	t1,0(a5)
ffffffffc02021a8:	03810e13          	addi	t3,sp,56
ffffffffc02021ac:	0b810f13          	addi	t5,sp,184
ffffffffc02021b0:	8eda                	mv	t4,s6
        for (size_t i = 0; i < 16; i++) {
ffffffffc02021b2:	4fc1                	li	t6,16
ffffffffc02021b4:	a031                	j	ffffffffc02021c0 <buddy_check+0x996>
ffffffffc02021b6:	0dfe8163          	beq	t4,t6,ffffffffc0202278 <buddy_check+0xa4e>
ffffffffc02021ba:	0e85                	addi	t4,t4,1
ffffffffc02021bc:	0e21                	addi	t3,t3,8
ffffffffc02021be:	0f21                	addi	t5,t5,8
            if (allocated[i] == NULL) {
ffffffffc02021c0:	ff8e3503          	ld	a0,-8(t3)
ffffffffc02021c4:	d96d                	beqz	a0,ffffffffc02021b6 <buddy_check+0x98c>
            size_t size_i = (size_t)1 << buddy_get_order(requests[i]);
ffffffffc02021c6:	ff8f3683          	ld	a3,-8(t5)
    while (size < n && order < buddy->max_order) {
ffffffffc02021ca:	18dbf863          	bgeu	s7,a3,ffffffffc020235a <buddy_check+0xb30>
ffffffffc02021ce:	41033603          	ld	a2,1040(t1)
    size_t order = 0, size = 1;
ffffffffc02021d2:	875a                	mv	a4,s6
ffffffffc02021d4:	4781                	li	a5,0
    while (size < n && order < buddy->max_order) {
ffffffffc02021d6:	08f60e63          	beq	a2,a5,ffffffffc0202272 <buddy_check+0xa48>
        size <<= 1;
ffffffffc02021da:	0706                	slli	a4,a4,0x1
        order++;
ffffffffc02021dc:	0785                	addi	a5,a5,1
    while (size < n && order < buddy->max_order) {
ffffffffc02021de:	fed76ce3          	bltu	a4,a3,ffffffffc02021d6 <buddy_check+0x9ac>
            size_t size_i = (size_t)1 << buddy_get_order(requests[i]);
ffffffffc02021e2:	0007859b          	sext.w	a1,a5
            for (size_t j = i + 1; j < 16; j++) {
ffffffffc02021e6:	09fe8963          	beq	t4,t6,ffffffffc0202278 <buddy_check+0xa4e>
                    assert(allocated[i] + size_i <= allocated[j] ||
ffffffffc02021ea:	00bc95b3          	sll	a1,s9,a1
ffffffffc02021ee:	95aa                	add	a1,a1,a0
ffffffffc02021f0:	86fa                	mv	a3,t5
ffffffffc02021f2:	87f2                	mv	a5,t3
                if (allocated[j] != NULL) {
ffffffffc02021f4:	6398                	ld	a4,0(a5)
ffffffffc02021f6:	c71d                	beqz	a4,ffffffffc0202224 <buddy_check+0x9fa>
                    size_t size_j = (size_t)1 << buddy_get_order(requests[j]);
ffffffffc02021f8:	0006b283          	ld	t0,0(a3)
    while (size < n && order < buddy->max_order) {
ffffffffc02021fc:	065bf963          	bgeu	s7,t0,ffffffffc020226e <buddy_check+0xa44>
ffffffffc0202200:	41033383          	ld	t2,1040(t1)
    size_t order = 0, size = 1;
ffffffffc0202204:	8c5a                	mv	s8,s6
ffffffffc0202206:	4601                	li	a2,0
    while (size < n && order < buddy->max_order) {
ffffffffc0202208:	06c38163          	beq	t2,a2,ffffffffc020226a <buddy_check+0xa40>
        size <<= 1;
ffffffffc020220c:	0c06                	slli	s8,s8,0x1
        order++;
ffffffffc020220e:	0605                	addi	a2,a2,1
    while (size < n && order < buddy->max_order) {
ffffffffc0202210:	fe5c6ce3          	bltu	s8,t0,ffffffffc0202208 <buddy_check+0x9de>
                    size_t size_j = (size_t)1 << buddy_get_order(requests[j]);
ffffffffc0202214:	2601                	sext.w	a2,a2
                    assert(allocated[i] + size_i <= allocated[j] ||
ffffffffc0202216:	00b77763          	bgeu	a4,a1,ffffffffc0202224 <buddy_check+0x9fa>
ffffffffc020221a:	00cc9633          	sll	a2,s9,a2
ffffffffc020221e:	9732                	add	a4,a4,a2
ffffffffc0202220:	1ce56c63          	bltu	a0,a4,ffffffffc02023f8 <buddy_check+0xbce>
            for (size_t j = i + 1; j < 16; j++) {
ffffffffc0202224:	07a1                	addi	a5,a5,8
ffffffffc0202226:	06a1                	addi	a3,a3,8
ffffffffc0202228:	fcf916e3          	bne	s2,a5,ffffffffc02021f4 <buddy_check+0x9ca>
ffffffffc020222c:	b779                	j	ffffffffc02021ba <buddy_check+0x990>
                assert(arena->property == i + 1);
ffffffffc020222e:	01046783          	lwu	a5,16(s0)
ffffffffc0202232:	73879f63          	bne	a5,s8,ffffffffc0202970 <buddy_check+0x1146>
            buddy_check_invariants();
ffffffffc0202236:	fecfe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
        for (size_t i = 0; i < 8; i++) {
ffffffffc020223a:	bc01                	j	ffffffffc0201c4a <buddy_check+0x420>
            assert(nr_free_pages() == i + 1);
ffffffffc020223c:	00005697          	auipc	a3,0x5
ffffffffc0202240:	90c68693          	addi	a3,a3,-1780 # ffffffffc0206b48 <etext+0xe20>
ffffffffc0202244:	00004617          	auipc	a2,0x4
ffffffffc0202248:	d6c60613          	addi	a2,a2,-660 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020224c:	1dc00593          	li	a1,476
ffffffffc0202250:	00004517          	auipc	a0,0x4
ffffffffc0202254:	d7850513          	addi	a0,a0,-648 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202258:	f73fd0ef          	jal	ra,ffffffffc02001ca <__panic>
ffffffffc020225c:	67e2                	ld	a5,24(sp)
ffffffffc020225e:	e43e                	sd	a5,8(sp)
ffffffffc0202260:	ba79                	j	ffffffffc0201bfe <buddy_check+0x3d4>
ffffffffc0202262:	4681                	li	a3,0
ffffffffc0202264:	04000493          	li	s1,64
ffffffffc0202268:	b6c5                	j	ffffffffc0201e48 <buddy_check+0x61e>
ffffffffc020226a:	8626                	mv	a2,s1
ffffffffc020226c:	b76d                	j	ffffffffc0202216 <buddy_check+0x9ec>
    while (size < n && order < buddy->max_order) {
ffffffffc020226e:	4601                	li	a2,0
ffffffffc0202270:	b75d                	j	ffffffffc0202216 <buddy_check+0x9ec>
ffffffffc0202272:	85a6                	mv	a1,s1
            for (size_t j = i + 1; j < 16; j++) {
ffffffffc0202274:	f7fe9be3          	bne	t4,t6,ffffffffc02021ea <buddy_check+0x9c0>
    for (size_t step = 0; step < 256; step++) {
ffffffffc0202278:	67a2                	ld	a5,8(sp)
ffffffffc020227a:	17fd                	addi	a5,a5,-1
ffffffffc020227c:	8a3e                	mv	s4,a5
ffffffffc020227e:	e43e                	sd	a5,8(sp)
        buddy_check_invariants();
ffffffffc0202280:	fa2fe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    for (size_t step = 0; step < 256; step++) {
ffffffffc0202284:	ea0a17e3          	bnez	s4,ffffffffc0202132 <buddy_check+0x908>
ffffffffc0202288:	1804                	addi	s1,sp,48
ffffffffc020228a:	89ca                	mv	s3,s2
        if (allocated[i] != NULL) {
ffffffffc020228c:	6088                	ld	a0,0(s1)
ffffffffc020228e:	c509                	beqz	a0,ffffffffc0202298 <buddy_check+0xa6e>
            free_pages(allocated[i], requests[i]);
ffffffffc0202290:	0009b583          	ld	a1,0(s3)
ffffffffc0202294:	209000ef          	jal	ra,ffffffffc0202c9c <free_pages>
    for (size_t i = 0; i < 16; i++) {
ffffffffc0202298:	04a1                	addi	s1,s1,8
ffffffffc020229a:	09a1                	addi	s3,s3,8
ffffffffc020229c:	fe9918e3          	bne	s2,s1,ffffffffc020228c <buddy_check+0xa62>
    assert(nr_free_pages() == BUDDY_TEST_PAGES);
ffffffffc02022a0:	209000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc02022a4:	04000713          	li	a4,64
ffffffffc02022a8:	1ce51463          	bne	a0,a4,ffffffffc0202470 <buddy_check+0xc46>
    assert(PageProperty(arena) && arena->property == BUDDY_TEST_PAGES);
ffffffffc02022ac:	6418                	ld	a4,8(s0)
ffffffffc02022ae:	8b09                	andi	a4,a4,2
ffffffffc02022b0:	1e070063          	beqz	a4,ffffffffc0202490 <buddy_check+0xc66>
ffffffffc02022b4:	4818                	lw	a4,16(s0)
ffffffffc02022b6:	1ca71d63          	bne	a4,a0,ffffffffc0202490 <buddy_check+0xc66>
    buddy_check_invariants();
ffffffffc02022ba:	f68fe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    buddy_check_stress(arena);
    cprintf("buddy_check: stress passed\n");
ffffffffc02022be:	00005517          	auipc	a0,0x5
ffffffffc02022c2:	f7250513          	addi	a0,a0,-142 # ffffffffc0207230 <etext+0x1508>
ffffffffc02022c6:	e8ffd0ef          	jal	ra,ffffffffc0200154 <cprintf>

    // Restore only the held arena's descriptors to their allocated state.
    // The kernel state's lists and allocation records were never copied/reset.
    for (size_t i = 0; i < BUDDY_TEST_PAGES; i++) {
ffffffffc02022ca:	6705                	lui	a4,0x1
ffffffffc02022cc:	a1870713          	addi	a4,a4,-1512 # a18 <kern_entry-0xffffffffc01ff5e8>
ffffffffc02022d0:	01840793          	addi	a5,s0,24
ffffffffc02022d4:	9722                	add	a4,a4,s0
        arena[i].flags = arena[i].property = 0;
ffffffffc02022d6:	fe07ac23          	sw	zero,-8(a5)
ffffffffc02022da:	fe07b823          	sd	zero,-16(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02022de:	fe07a423          	sw	zero,-24(a5)
ffffffffc02022e2:	e79c                	sd	a5,8(a5)
ffffffffc02022e4:	e39c                	sd	a5,0(a5)
    for (size_t i = 0; i < BUDDY_TEST_PAGES; i++) {
ffffffffc02022e6:	02878793          	addi	a5,a5,40
ffffffffc02022ea:	fee796e3          	bne	a5,a4,ffffffffc02022d6 <buddy_check+0xaac>
        set_page_ref(arena + i, 0);
        list_init(&arena[i].page_link);
    }
    buddy = &kernel_state;
ffffffffc02022ee:	0000a797          	auipc	a5,0xa
ffffffffc02022f2:	d2278793          	addi	a5,a5,-734 # ffffffffc020c010 <buddy>
ffffffffc02022f6:	0003a717          	auipc	a4,0x3a
ffffffffc02022fa:	d2a70713          	addi	a4,a4,-726 # ffffffffc023c020 <kernel_state>
    free_pages(arena, BUDDY_TEST_PAGES);
ffffffffc02022fe:	04000593          	li	a1,64
ffffffffc0202302:	8522                	mv	a0,s0
    buddy = &kernel_state;
ffffffffc0202304:	e398                	sd	a4,0(a5)
    free_pages(arena, BUDDY_TEST_PAGES);
ffffffffc0202306:	197000ef          	jal	ra,ffffffffc0202c9c <free_pages>
    assert(nr_free_pages() == before);
ffffffffc020230a:	19f000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc020230e:	67c2                	ld	a5,16(sp)
ffffffffc0202310:	1ef51063          	bne	a0,a5,ffffffffc02024f0 <buddy_check+0xcc6>
    buddy_check_invariants();
ffffffffc0202314:	f0efe0ef          	jal	ra,ffffffffc0200a22 <buddy_check_invariants>
    struct Page *continuation = alloc_pages(1);
ffffffffc0202318:	4505                	li	a0,1
ffffffffc020231a:	177000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
    assert(continuation != NULL);
ffffffffc020231e:	1e050963          	beqz	a0,ffffffffc0202510 <buddy_check+0xce6>
    free_pages(continuation, 1);
ffffffffc0202322:	4585                	li	a1,1
ffffffffc0202324:	179000ef          	jal	ra,ffffffffc0202c9c <free_pages>
    assert(nr_free_pages() == before);
ffffffffc0202328:	181000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc020232c:	67c2                	ld	a5,16(sp)
ffffffffc020232e:	20f51163          	bne	a0,a5,ffffffffc0202530 <buddy_check+0xd06>
    cprintf("buddy_check: all tests passed; kernel state restored\n");
}
ffffffffc0202332:	645a                	ld	s0,400(sp)
ffffffffc0202334:	60fa                	ld	ra,408(sp)
ffffffffc0202336:	64ba                	ld	s1,392(sp)
ffffffffc0202338:	691a                	ld	s2,384(sp)
ffffffffc020233a:	79f6                	ld	s3,376(sp)
ffffffffc020233c:	7a56                	ld	s4,368(sp)
ffffffffc020233e:	7ab6                	ld	s5,360(sp)
ffffffffc0202340:	7b16                	ld	s6,352(sp)
ffffffffc0202342:	6bf6                	ld	s7,344(sp)
ffffffffc0202344:	6c56                	ld	s8,336(sp)
ffffffffc0202346:	6cb6                	ld	s9,328(sp)
ffffffffc0202348:	6d16                	ld	s10,320(sp)
ffffffffc020234a:	7df2                	ld	s11,312(sp)
    cprintf("buddy_check: all tests passed; kernel state restored\n");
ffffffffc020234c:	00005517          	auipc	a0,0x5
ffffffffc0202350:	f1c50513          	addi	a0,a0,-228 # ffffffffc0207268 <etext+0x1540>
}
ffffffffc0202354:	611d                	addi	sp,sp,416
    cprintf("buddy_check: all tests passed; kernel state restored\n");
ffffffffc0202356:	dfffd06f          	j	ffffffffc0200154 <cprintf>
    while (size < n && order < buddy->max_order) {
ffffffffc020235a:	4581                	li	a1,0
ffffffffc020235c:	b569                	j	ffffffffc02021e6 <buddy_check+0x9bc>
            seed = seed * 1664525U + 1013904223U;
ffffffffc020235e:	035989bb          	mulw	s3,s3,s5
ffffffffc0202362:	47e2                	lw	a5,24(sp)
            requests[slot] = 1 + (seed >> 16) % 9;
ffffffffc0202364:	46a5                	li	a3,9
            seed = seed * 1664525U + 1013904223U;
ffffffffc0202366:	00f989bb          	addw	s3,s3,a5
            requests[slot] = 1 + (seed >> 16) % 9;
ffffffffc020236a:	0109d79b          	srliw	a5,s3,0x10
ffffffffc020236e:	02d7f7bb          	remuw	a5,a5,a3
ffffffffc0202372:	2785                	addiw	a5,a5,1
ffffffffc0202374:	02079d93          	slli	s11,a5,0x20
ffffffffc0202378:	020ddd93          	srli	s11,s11,0x20
            allocated[slot] = alloc_pages(requests[slot]);
ffffffffc020237c:	856e                	mv	a0,s11
            requests[slot] = 1 + (seed >> 16) % 9;
ffffffffc020237e:	f9ba3023          	sd	s11,-128(s4)
ffffffffc0202382:	00078c1b          	sext.w	s8,a5
            allocated[slot] = alloc_pages(requests[slot]);
ffffffffc0202386:	10b000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc020238a:	f0aa3023          	sd	a0,-256(s4)
ffffffffc020238e:	86aa                	mv	a3,a0
    while (size < n && order < buddy->max_order) {
ffffffffc0202390:	077c0263          	beq	s8,s7,ffffffffc02023f4 <buddy_check+0xbca>
ffffffffc0202394:	0000a797          	auipc	a5,0xa
ffffffffc0202398:	c7c78793          	addi	a5,a5,-900 # ffffffffc020c010 <buddy>
ffffffffc020239c:	6390                	ld	a2,0(a5)
    size_t order = 0, size = 1;
ffffffffc020239e:	875a                	mv	a4,s6
ffffffffc02023a0:	4781                	li	a5,0
    while (size < n && order < buddy->max_order) {
ffffffffc02023a2:	41063603          	ld	a2,1040(a2)
ffffffffc02023a6:	04f60263          	beq	a2,a5,ffffffffc02023ea <buddy_check+0xbc0>
        size <<= 1;
ffffffffc02023aa:	0706                	slli	a4,a4,0x1
        order++;
ffffffffc02023ac:	0785                	addi	a5,a5,1
    while (size < n && order < buddy->max_order) {
ffffffffc02023ae:	ffb76ce3          	bltu	a4,s11,ffffffffc02023a6 <buddy_check+0xb7c>
            size_t size = (size_t)1 << buddy_get_order(requests[slot]);
ffffffffc02023b2:	00fb9c33          	sll	s8,s7,a5
ffffffffc02023b6:	f036                	sd	a3,32(sp)
            assert(nr_free_pages() == before - (allocated[slot] != NULL ? size : 0));
ffffffffc02023b8:	0f1000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc02023bc:	7682                	ld	a3,32(sp)
ffffffffc02023be:	87aa                	mv	a5,a0
ffffffffc02023c0:	c299                	beqz	a3,ffffffffc02023c6 <buddy_check+0xb9c>
ffffffffc02023c2:	418d0d33          	sub	s10,s10,s8
ffffffffc02023c6:	dda78be3          	beq	a5,s10,ffffffffc020219c <buddy_check+0x972>
ffffffffc02023ca:	00005697          	auipc	a3,0x5
ffffffffc02023ce:	d6668693          	addi	a3,a3,-666 # ffffffffc0207130 <etext+0x1408>
ffffffffc02023d2:	00004617          	auipc	a2,0x4
ffffffffc02023d6:	bde60613          	addi	a2,a2,-1058 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02023da:	26f00593          	li	a1,623
ffffffffc02023de:	00004517          	auipc	a0,0x4
ffffffffc02023e2:	bea50513          	addi	a0,a0,-1046 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02023e6:	de5fd0ef          	jal	ra,ffffffffc02001ca <__panic>
ffffffffc02023ea:	4c01                	li	s8,0
ffffffffc02023ec:	b7e9                	j	ffffffffc02023b6 <buddy_check+0xb8c>
            assert(nr_free_pages() == before + size);
ffffffffc02023ee:	00150d13          	addi	s10,a0,1
ffffffffc02023f2:	bb51                	j	ffffffffc0202186 <buddy_check+0x95c>
    while (size < n && order < buddy->max_order) {
ffffffffc02023f4:	8c5a                	mv	s8,s6
ffffffffc02023f6:	b7c1                	j	ffffffffc02023b6 <buddy_check+0xb8c>
                    assert(allocated[i] + size_i <= allocated[j] ||
ffffffffc02023f8:	00005697          	auipc	a3,0x5
ffffffffc02023fc:	d8068693          	addi	a3,a3,-640 # ffffffffc0207178 <etext+0x1450>
ffffffffc0202400:	00004617          	auipc	a2,0x4
ffffffffc0202404:	bb060613          	addi	a2,a2,-1104 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202408:	27900593          	li	a1,633
ffffffffc020240c:	00004517          	auipc	a0,0x4
ffffffffc0202410:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202414:	db7fd0ef          	jal	ra,ffffffffc02001ca <__panic>
        size_t before = nr_free_pages();
ffffffffc0202418:	091000ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc020241c:	8c2a                	mv	s8,a0
        struct Page *p = alloc_pages(n);
ffffffffc020241e:	8566                	mv	a0,s9
ffffffffc0202420:	071000ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc0202424:	832a                	mv	t1,a0
        assert(p != NULL && (page2ppn(p) & (size - 1)) == 0);
ffffffffc0202426:	3a050563          	beqz	a0,ffffffffc02027d0 <buddy_check+0xfa6>
        size_t size = (size_t)1 << buddy_get_order(n);
ffffffffc020242a:	86da                	mv	a3,s6
ffffffffc020242c:	4481                	li	s1,0
ffffffffc020242e:	b4a9                	j	ffffffffc0201e78 <buddy_check+0x64e>
            assert(!PageProperty(p + j) && buddy->owner[p - pages + j] == owner);
ffffffffc0202430:	00005697          	auipc	a3,0x5
ffffffffc0202434:	9f068693          	addi	a3,a3,-1552 # ffffffffc0206e20 <etext+0x10f8>
ffffffffc0202438:	00004617          	auipc	a2,0x4
ffffffffc020243c:	b7860613          	addi	a2,a2,-1160 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202440:	21700593          	li	a1,535
ffffffffc0202444:	00004517          	auipc	a0,0x4
ffffffffc0202448:	b8450513          	addi	a0,a0,-1148 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020244c:	d7ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(buddy == &kernel_state);
ffffffffc0202450:	00004697          	auipc	a3,0x4
ffffffffc0202454:	33868693          	addi	a3,a3,824 # ffffffffc0206788 <etext+0xa60>
ffffffffc0202458:	00004617          	auipc	a2,0x4
ffffffffc020245c:	b5860613          	addi	a2,a2,-1192 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202460:	28c00593          	li	a1,652
ffffffffc0202464:	00004517          	auipc	a0,0x4
ffffffffc0202468:	b6450513          	addi	a0,a0,-1180 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020246c:	d5ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == BUDDY_TEST_PAGES);
ffffffffc0202470:	00005697          	auipc	a3,0x5
ffffffffc0202474:	d5868693          	addi	a3,a3,-680 # ffffffffc02071c8 <etext+0x14a0>
ffffffffc0202478:	00004617          	auipc	a2,0x4
ffffffffc020247c:	b3860613          	addi	a2,a2,-1224 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202480:	28500593          	li	a1,645
ffffffffc0202484:	00004517          	auipc	a0,0x4
ffffffffc0202488:	b4450513          	addi	a0,a0,-1212 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020248c:	d3ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(PageProperty(arena) && arena->property == BUDDY_TEST_PAGES);
ffffffffc0202490:	00005697          	auipc	a3,0x5
ffffffffc0202494:	d6068693          	addi	a3,a3,-672 # ffffffffc02071f0 <etext+0x14c8>
ffffffffc0202498:	00004617          	auipc	a2,0x4
ffffffffc020249c:	b1860613          	addi	a2,a2,-1256 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02024a0:	28600593          	li	a1,646
ffffffffc02024a4:	00004517          	auipc	a0,0x4
ffffffffc02024a8:	b2450513          	addi	a0,a0,-1244 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02024ac:	d1ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(nr_free_pages() == before + size);
ffffffffc02024b0:	00005697          	auipc	a3,0x5
ffffffffc02024b4:	c5868693          	addi	a3,a3,-936 # ffffffffc0207108 <etext+0x13e0>
ffffffffc02024b8:	00004617          	auipc	a2,0x4
ffffffffc02024bc:	af860613          	addi	a2,a2,-1288 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02024c0:	26900593          	li	a1,617
ffffffffc02024c4:	00004517          	auipc	a0,0x4
ffffffffc02024c8:	b0450513          	addi	a0,a0,-1276 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02024cc:	cfffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(p == arena);
ffffffffc02024d0:	00005697          	auipc	a3,0x5
ffffffffc02024d4:	c0868693          	addi	a3,a3,-1016 # ffffffffc02070d8 <etext+0x13b0>
ffffffffc02024d8:	00004617          	auipc	a2,0x4
ffffffffc02024dc:	ad860613          	addi	a2,a2,-1320 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02024e0:	25500593          	li	a1,597
ffffffffc02024e4:	00004517          	auipc	a0,0x4
ffffffffc02024e8:	ae450513          	addi	a0,a0,-1308 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02024ec:	cdffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == before);
ffffffffc02024f0:	00004697          	auipc	a3,0x4
ffffffffc02024f4:	44068693          	addi	a3,a3,1088 # ffffffffc0206930 <etext+0xc08>
ffffffffc02024f8:	00004617          	auipc	a2,0x4
ffffffffc02024fc:	ab860613          	addi	a2,a2,-1352 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202500:	2ad00593          	li	a1,685
ffffffffc0202504:	00004517          	auipc	a0,0x4
ffffffffc0202508:	ac450513          	addi	a0,a0,-1340 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020250c:	cbffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(continuation != NULL);
ffffffffc0202510:	00005697          	auipc	a3,0x5
ffffffffc0202514:	d4068693          	addi	a3,a3,-704 # ffffffffc0207250 <etext+0x1528>
ffffffffc0202518:	00004617          	auipc	a2,0x4
ffffffffc020251c:	a9860613          	addi	a2,a2,-1384 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202520:	2b000593          	li	a1,688
ffffffffc0202524:	00004517          	auipc	a0,0x4
ffffffffc0202528:	aa450513          	addi	a0,a0,-1372 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020252c:	c9ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == before);
ffffffffc0202530:	00004697          	auipc	a3,0x4
ffffffffc0202534:	40068693          	addi	a3,a3,1024 # ffffffffc0206930 <etext+0xc08>
ffffffffc0202538:	00004617          	auipc	a2,0x4
ffffffffc020253c:	a7860613          	addi	a2,a2,-1416 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202540:	2b200593          	li	a1,690
ffffffffc0202544:	00004517          	auipc	a0,0x4
ffffffffc0202548:	a8450513          	addi	a0,a0,-1404 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020254c:	c7ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == 8);
ffffffffc0202550:	00004697          	auipc	a3,0x4
ffffffffc0202554:	7c068693          	addi	a3,a3,1984 # ffffffffc0206d10 <etext+0xfe8>
ffffffffc0202558:	00004617          	auipc	a2,0x4
ffffffffc020255c:	a5860613          	addi	a2,a2,-1448 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202560:	25300593          	li	a1,595
ffffffffc0202564:	00004517          	auipc	a0,0x4
ffffffffc0202568:	a6450513          	addi	a0,a0,-1436 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020256c:	c5ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_pages((size_t)1 << (BUDDY_ORDERS - 1)) == NULL);
ffffffffc0202570:	00005697          	auipc	a3,0x5
ffffffffc0202574:	b3068693          	addi	a3,a3,-1232 # ffffffffc02070a0 <etext+0x1378>
ffffffffc0202578:	00004617          	auipc	a2,0x4
ffffffffc020257c:	a3860613          	addi	a2,a2,-1480 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202580:	25200593          	li	a1,594
ffffffffc0202584:	00004517          	auipc	a0,0x4
ffffffffc0202588:	a4450513          	addi	a0,a0,-1468 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020258c:	c3ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_pages(~(size_t)0) == NULL);
ffffffffc0202590:	00005697          	auipc	a3,0x5
ffffffffc0202594:	af068693          	addi	a3,a3,-1296 # ffffffffc0207080 <etext+0x1358>
ffffffffc0202598:	00004617          	auipc	a2,0x4
ffffffffc020259c:	a1860613          	addi	a2,a2,-1512 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02025a0:	25100593          	li	a1,593
ffffffffc02025a4:	00004517          	auipc	a0,0x4
ffffffffc02025a8:	a2450513          	addi	a0,a0,-1500 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02025ac:	c1ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_pages(BUDDY_PAGE_CAPACITY + 1) == NULL);
ffffffffc02025b0:	00005697          	auipc	a3,0x5
ffffffffc02025b4:	aa068693          	addi	a3,a3,-1376 # ffffffffc0207050 <etext+0x1328>
ffffffffc02025b8:	00004617          	auipc	a2,0x4
ffffffffc02025bc:	9f860613          	addi	a2,a2,-1544 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02025c0:	25000593          	li	a1,592
ffffffffc02025c4:	00004517          	auipc	a0,0x4
ffffffffc02025c8:	a0450513          	addi	a0,a0,-1532 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02025cc:	bfffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(alloc_pages(9) == NULL);
ffffffffc02025d0:	00005697          	auipc	a3,0x5
ffffffffc02025d4:	a6868693          	addi	a3,a3,-1432 # ffffffffc0207038 <etext+0x1310>
ffffffffc02025d8:	00004617          	auipc	a2,0x4
ffffffffc02025dc:	9d860613          	addi	a2,a2,-1576 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02025e0:	24f00593          	li	a1,591
ffffffffc02025e4:	00004517          	auipc	a0,0x4
ffffffffc02025e8:	9e450513          	addi	a0,a0,-1564 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02025ec:	bdffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == 8);
ffffffffc02025f0:	00004697          	auipc	a3,0x4
ffffffffc02025f4:	72068693          	addi	a3,a3,1824 # ffffffffc0206d10 <etext+0xfe8>
ffffffffc02025f8:	00004617          	auipc	a2,0x4
ffffffffc02025fc:	9b860613          	addi	a2,a2,-1608 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202600:	24e00593          	li	a1,590
ffffffffc0202604:	00004517          	auipc	a0,0x4
ffffffffc0202608:	9c450513          	addi	a0,a0,-1596 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020260c:	bbffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == 4 && alloc_pages(2) == NULL);
ffffffffc0202610:	00005697          	auipc	a3,0x5
ffffffffc0202614:	9f868693          	addi	a3,a3,-1544 # ffffffffc0207008 <etext+0x12e0>
ffffffffc0202618:	00004617          	auipc	a2,0x4
ffffffffc020261c:	99860613          	addi	a2,a2,-1640 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202620:	24900593          	li	a1,585
ffffffffc0202624:	00004517          	auipc	a0,0x4
ffffffffc0202628:	9a450513          	addi	a0,a0,-1628 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020262c:	b9ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == 0 && alloc_pages(1) == NULL);
ffffffffc0202630:	00005697          	auipc	a3,0x5
ffffffffc0202634:	9a868693          	addi	a3,a3,-1624 # ffffffffc0206fd8 <etext+0x12b0>
ffffffffc0202638:	00004617          	auipc	a2,0x4
ffffffffc020263c:	97860613          	addi	a2,a2,-1672 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202640:	24400593          	li	a1,580
ffffffffc0202644:	00004517          	auipc	a0,0x4
ffffffffc0202648:	98450513          	addi	a0,a0,-1660 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020264c:	b7ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(allocated[i] == arena + i);
ffffffffc0202650:	00004697          	auipc	a3,0x4
ffffffffc0202654:	4d868693          	addi	a3,a3,1240 # ffffffffc0206b28 <etext+0xe00>
ffffffffc0202658:	00004617          	auipc	a2,0x4
ffffffffc020265c:	95860613          	addi	a2,a2,-1704 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202660:	24200593          	li	a1,578
ffffffffc0202664:	00004517          	auipc	a0,0x4
ffffffffc0202668:	96450513          	addi	a0,a0,-1692 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020266c:	b5ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == 16 && arena->property == 16);
ffffffffc0202670:	00005697          	auipc	a3,0x5
ffffffffc0202674:	8e068693          	addi	a3,a3,-1824 # ffffffffc0206f50 <etext+0x1228>
ffffffffc0202678:	00004617          	auipc	a2,0x4
ffffffffc020267c:	93860613          	addi	a2,a2,-1736 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202680:	23700593          	li	a1,567
ffffffffc0202684:	00004517          	auipc	a0,0x4
ffffffffc0202688:	94450513          	addi	a0,a0,-1724 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020268c:	b3ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(a == arena && b == a + 2);
ffffffffc0202690:	00005697          	auipc	a3,0x5
ffffffffc0202694:	8f068693          	addi	a3,a3,-1808 # ffffffffc0206f80 <etext+0x1258>
ffffffffc0202698:	00004617          	auipc	a2,0x4
ffffffffc020269c:	91860613          	addi	a2,a2,-1768 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02026a0:	23500593          	li	a1,565
ffffffffc02026a4:	00004517          	auipc	a0,0x4
ffffffffc02026a8:	92450513          	addi	a0,a0,-1756 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02026ac:	b1ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == 16 && arena->property == 16);
ffffffffc02026b0:	00005697          	auipc	a3,0x5
ffffffffc02026b4:	8a068693          	addi	a3,a3,-1888 # ffffffffc0206f50 <etext+0x1228>
ffffffffc02026b8:	00004617          	auipc	a2,0x4
ffffffffc02026bc:	8f860613          	addi	a2,a2,-1800 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02026c0:	23000593          	li	a1,560
ffffffffc02026c4:	00004517          	auipc	a0,0x4
ffffffffc02026c8:	90450513          	addi	a0,a0,-1788 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02026cc:	afffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == 14);
ffffffffc02026d0:	00005697          	auipc	a3,0x5
ffffffffc02026d4:	86868693          	addi	a3,a3,-1944 # ffffffffc0206f38 <etext+0x1210>
ffffffffc02026d8:	00004617          	auipc	a2,0x4
ffffffffc02026dc:	8d860613          	addi	a2,a2,-1832 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02026e0:	22d00593          	li	a1,557
ffffffffc02026e4:	00004517          	auipc	a0,0x4
ffffffffc02026e8:	8e450513          	addi	a0,a0,-1820 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02026ec:	adffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(replacement == p);
ffffffffc02026f0:	00005697          	auipc	a3,0x5
ffffffffc02026f4:	83068693          	addi	a3,a3,-2000 # ffffffffc0206f20 <etext+0x11f8>
ffffffffc02026f8:	00004617          	auipc	a2,0x4
ffffffffc02026fc:	8b860613          	addi	a2,a2,-1864 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202700:	22a00593          	li	a1,554
ffffffffc0202704:	00004517          	auipc	a0,0x4
ffffffffc0202708:	8c450513          	addi	a0,a0,-1852 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020270c:	abffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == 11);
ffffffffc0202710:	00004697          	auipc	a3,0x4
ffffffffc0202714:	7f868693          	addi	a3,a3,2040 # ffffffffc0206f08 <etext+0x11e0>
ffffffffc0202718:	00004617          	auipc	a2,0x4
ffffffffc020271c:	89860613          	addi	a2,a2,-1896 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202720:	22800593          	li	a1,552
ffffffffc0202724:	00004517          	auipc	a0,0x4
ffffffffc0202728:	8a450513          	addi	a0,a0,-1884 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020272c:	a9ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(p == arena && nr_free_pages() == 8);
ffffffffc0202730:	00004697          	auipc	a3,0x4
ffffffffc0202734:	7b068693          	addi	a3,a3,1968 # ffffffffc0206ee0 <etext+0x11b8>
ffffffffc0202738:	00004617          	auipc	a2,0x4
ffffffffc020273c:	87860613          	addi	a2,a2,-1928 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202740:	22500593          	li	a1,549
ffffffffc0202744:	00004517          	auipc	a0,0x4
ffffffffc0202748:	88450513          	addi	a0,a0,-1916 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020274c:	a7ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(nr_free_pages() == before && arena->property == BUDDY_TEST_PAGES);
ffffffffc0202750:	00004697          	auipc	a3,0x4
ffffffffc0202754:	74868693          	addi	a3,a3,1864 # ffffffffc0206e98 <etext+0x1170>
ffffffffc0202758:	00004617          	auipc	a2,0x4
ffffffffc020275c:	85860613          	addi	a2,a2,-1960 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202760:	21d00593          	li	a1,541
ffffffffc0202764:	00004517          	auipc	a0,0x4
ffffffffc0202768:	86450513          	addi	a0,a0,-1948 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020276c:	a5ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(other != NULL && (other < p || other >= p + size));
ffffffffc0202770:	00004697          	auipc	a3,0x4
ffffffffc0202774:	6f068693          	addi	a3,a3,1776 # ffffffffc0206e60 <etext+0x1138>
ffffffffc0202778:	00004617          	auipc	a2,0x4
ffffffffc020277c:	83860613          	addi	a2,a2,-1992 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202780:	21a00593          	li	a1,538
ffffffffc0202784:	00004517          	auipc	a0,0x4
ffffffffc0202788:	84450513          	addi	a0,a0,-1980 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020278c:	a3ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(buddy->allocation[owner - 1].span == size);
ffffffffc0202790:	00004697          	auipc	a3,0x4
ffffffffc0202794:	66068693          	addi	a3,a3,1632 # ffffffffc0206df0 <etext+0x10c8>
ffffffffc0202798:	00004617          	auipc	a2,0x4
ffffffffc020279c:	81860613          	addi	a2,a2,-2024 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02027a0:	21500593          	li	a1,533
ffffffffc02027a4:	00004517          	auipc	a0,0x4
ffffffffc02027a8:	82450513          	addi	a0,a0,-2012 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02027ac:	a1ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(before - nr_free_pages() == size);
ffffffffc02027b0:	00004697          	auipc	a3,0x4
ffffffffc02027b4:	61868693          	addi	a3,a3,1560 # ffffffffc0206dc8 <etext+0x10a0>
ffffffffc02027b8:	00003617          	auipc	a2,0x3
ffffffffc02027bc:	7f860613          	addi	a2,a2,2040 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02027c0:	21300593          	li	a1,531
ffffffffc02027c4:	00004517          	auipc	a0,0x4
ffffffffc02027c8:	80450513          	addi	a0,a0,-2044 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02027cc:	9fffd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(p != NULL && (page2ppn(p) & (size - 1)) == 0);
ffffffffc02027d0:	00004697          	auipc	a3,0x4
ffffffffc02027d4:	5c868693          	addi	a3,a3,1480 # ffffffffc0206d98 <etext+0x1070>
ffffffffc02027d8:	00003617          	auipc	a2,0x3
ffffffffc02027dc:	7d860613          	addi	a2,a2,2008 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02027e0:	21200593          	li	a1,530
ffffffffc02027e4:	00003517          	auipc	a0,0x3
ffffffffc02027e8:	7e450513          	addi	a0,a0,2020 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02027ec:	9dffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(buddy_find_partner(pages, buddy->max_order) == NULL);
ffffffffc02027f0:	00004697          	auipc	a3,0x4
ffffffffc02027f4:	55068693          	addi	a3,a3,1360 # ffffffffc0206d40 <etext+0x1018>
ffffffffc02027f8:	00003617          	auipc	a2,0x3
ffffffffc02027fc:	7b860613          	addi	a2,a2,1976 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202800:	20400593          	li	a1,516
ffffffffc0202804:	00003517          	auipc	a0,0x3
ffffffffc0202808:	7c450513          	addi	a0,a0,1988 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020280c:	9bffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(PageReserved(arena));
ffffffffc0202810:	00004697          	auipc	a3,0x4
ffffffffc0202814:	51868693          	addi	a3,a3,1304 # ffffffffc0206d28 <etext+0x1000>
ffffffffc0202818:	00003617          	auipc	a2,0x3
ffffffffc020281c:	79860613          	addi	a2,a2,1944 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202820:	20200593          	li	a1,514
ffffffffc0202824:	00003517          	auipc	a0,0x3
ffffffffc0202828:	7a450513          	addi	a0,a0,1956 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020282c:	99ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(buddy_find_partner(arena + 1, 0) == NULL);
ffffffffc0202830:	00004697          	auipc	a3,0x4
ffffffffc0202834:	41068693          	addi	a3,a3,1040 # ffffffffc0206c40 <etext+0xf18>
ffffffffc0202838:	00003617          	auipc	a2,0x3
ffffffffc020283c:	77860613          	addi	a2,a2,1912 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202840:	20100593          	li	a1,513
ffffffffc0202844:	00003517          	auipc	a0,0x3
ffffffffc0202848:	78450513          	addi	a0,a0,1924 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020284c:	97ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(arena->property == 8 && nr_free_pages() == 8);
ffffffffc0202850:	00004697          	auipc	a3,0x4
ffffffffc0202854:	4a868693          	addi	a3,a3,1192 # ffffffffc0206cf8 <etext+0xfd0>
ffffffffc0202858:	00003617          	auipc	a2,0x3
ffffffffc020285c:	75860613          	addi	a2,a2,1880 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202860:	1fc00593          	li	a1,508
ffffffffc0202864:	00003517          	auipc	a0,0x3
ffffffffc0202868:	76450513          	addi	a0,a0,1892 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020286c:	95ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(buddy_find_partner(arena + 5, 0) == NULL);
ffffffffc0202870:	00004697          	auipc	a3,0x4
ffffffffc0202874:	45868693          	addi	a3,a3,1112 # ffffffffc0206cc8 <etext+0xfa0>
ffffffffc0202878:	00003617          	auipc	a2,0x3
ffffffffc020287c:	73860613          	addi	a2,a2,1848 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202880:	1f800593          	li	a1,504
ffffffffc0202884:	00003517          	auipc	a0,0x3
ffffffffc0202888:	74450513          	addi	a0,a0,1860 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020288c:	93ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(buddy_find_partner(arena, 1) == NULL);
ffffffffc0202890:	00004697          	auipc	a3,0x4
ffffffffc0202894:	41068693          	addi	a3,a3,1040 # ffffffffc0206ca0 <etext+0xf78>
ffffffffc0202898:	00003617          	auipc	a2,0x3
ffffffffc020289c:	71860613          	addi	a2,a2,1816 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02028a0:	1f700593          	li	a1,503
ffffffffc02028a4:	00003517          	auipc	a0,0x3
ffffffffc02028a8:	72450513          	addi	a0,a0,1828 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02028ac:	91ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(arena->property == 2 && arena[2].property == 1);
ffffffffc02028b0:	00004697          	auipc	a3,0x4
ffffffffc02028b4:	3c068693          	addi	a3,a3,960 # ffffffffc0206c70 <etext+0xf48>
ffffffffc02028b8:	00003617          	auipc	a2,0x3
ffffffffc02028bc:	6f860613          	addi	a2,a2,1784 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02028c0:	1f600593          	li	a1,502
ffffffffc02028c4:	00003517          	auipc	a0,0x3
ffffffffc02028c8:	70450513          	addi	a0,a0,1796 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02028cc:	8fffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(buddy_find_partner(arena + 1, 0) == NULL);
ffffffffc02028d0:	00004697          	auipc	a3,0x4
ffffffffc02028d4:	37068693          	addi	a3,a3,880 # ffffffffc0206c40 <etext+0xf18>
ffffffffc02028d8:	00003617          	auipc	a2,0x3
ffffffffc02028dc:	6d860613          	addi	a2,a2,1752 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02028e0:	1f300593          	li	a1,499
ffffffffc02028e4:	00003517          	auipc	a0,0x3
ffffffffc02028e8:	6e450513          	addi	a0,a0,1764 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02028ec:	8dffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((page2ppn(arena + 1) ^ 1) == page2ppn(arena));
ffffffffc02028f0:	00004697          	auipc	a3,0x4
ffffffffc02028f4:	32068693          	addi	a3,a3,800 # ffffffffc0206c10 <etext+0xee8>
ffffffffc02028f8:	00003617          	auipc	a2,0x3
ffffffffc02028fc:	6b860613          	addi	a2,a2,1720 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202900:	1f200593          	li	a1,498
ffffffffc0202904:	00003517          	auipc	a0,0x3
ffffffffc0202908:	6c450513          	addi	a0,a0,1732 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020290c:	8bffd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(arena[1].property == 1 && arena[2].property == 1);
ffffffffc0202910:	00004697          	auipc	a3,0x4
ffffffffc0202914:	2c868693          	addi	a3,a3,712 # ffffffffc0206bd8 <etext+0xeb0>
ffffffffc0202918:	00003617          	auipc	a2,0x3
ffffffffc020291c:	69860613          	addi	a2,a2,1688 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202920:	1f100593          	li	a1,497
ffffffffc0202924:	00003517          	auipc	a0,0x3
ffffffffc0202928:	6a450513          	addi	a0,a0,1700 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020292c:	89ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(allocated[i] == arena + i);
ffffffffc0202930:	00004697          	auipc	a3,0x4
ffffffffc0202934:	1f868693          	addi	a3,a3,504 # ffffffffc0206b28 <etext+0xe00>
ffffffffc0202938:	00003617          	auipc	a2,0x3
ffffffffc020293c:	67860613          	addi	a2,a2,1656 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202940:	1ed00593          	li	a1,493
ffffffffc0202944:	00003517          	auipc	a0,0x3
ffffffffc0202948:	68450513          	addi	a0,a0,1668 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020294c:	87ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(PageProperty(arena) && arena->property == 8);
ffffffffc0202950:	00004697          	auipc	a3,0x4
ffffffffc0202954:	23868693          	addi	a3,a3,568 # ffffffffc0206b88 <etext+0xe60>
ffffffffc0202958:	00003617          	auipc	a2,0x3
ffffffffc020295c:	65860613          	addi	a2,a2,1624 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202960:	1e200593          	li	a1,482
ffffffffc0202964:	00003517          	auipc	a0,0x3
ffffffffc0202968:	66450513          	addi	a0,a0,1636 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020296c:	85ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
                assert(arena->property == i + 1);
ffffffffc0202970:	00004697          	auipc	a3,0x4
ffffffffc0202974:	1f868693          	addi	a3,a3,504 # ffffffffc0206b68 <etext+0xe40>
ffffffffc0202978:	00003617          	auipc	a2,0x3
ffffffffc020297c:	63860613          	addi	a2,a2,1592 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202980:	1de00593          	li	a1,478
ffffffffc0202984:	00003517          	auipc	a0,0x3
ffffffffc0202988:	64450513          	addi	a0,a0,1604 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc020298c:	83ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(allocated[i] == arena + i);
ffffffffc0202990:	00004697          	auipc	a3,0x4
ffffffffc0202994:	19868693          	addi	a3,a3,408 # ffffffffc0206b28 <etext+0xe00>
ffffffffc0202998:	00003617          	auipc	a2,0x3
ffffffffc020299c:	61860613          	addi	a2,a2,1560 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02029a0:	1d800593          	li	a1,472
ffffffffc02029a4:	00003517          	auipc	a0,0x3
ffffffffc02029a8:	62450513          	addi	a0,a0,1572 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02029ac:	81ffd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(nr_free_pages() == 8 && arena->property == 8);
ffffffffc02029b0:	00004697          	auipc	a3,0x4
ffffffffc02029b4:	08068693          	addi	a3,a3,128 # ffffffffc0206a30 <etext+0xd08>
ffffffffc02029b8:	00003617          	auipc	a2,0x3
ffffffffc02029bc:	5f860613          	addi	a2,a2,1528 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02029c0:	1cb00593          	li	a1,459
ffffffffc02029c4:	00003517          	auipc	a0,0x3
ffffffffc02029c8:	60450513          	addi	a0,a0,1540 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02029cc:	ffefd0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(arena[size].property == size);
ffffffffc02029d0:	00004697          	auipc	a3,0x4
ffffffffc02029d4:	11868693          	addi	a3,a3,280 # ffffffffc0206ae8 <etext+0xdc0>
ffffffffc02029d8:	00003617          	auipc	a2,0x3
ffffffffc02029dc:	5d860613          	addi	a2,a2,1496 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02029e0:	1c700593          	li	a1,455
ffffffffc02029e4:	00003517          	auipc	a0,0x3
ffffffffc02029e8:	5e450513          	addi	a0,a0,1508 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc02029ec:	fdefd0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(PageProperty(arena + size));
ffffffffc02029f0:	00004697          	auipc	a3,0x4
ffffffffc02029f4:	0d868693          	addi	a3,a3,216 # ffffffffc0206ac8 <etext+0xda0>
ffffffffc02029f8:	00003617          	auipc	a2,0x3
ffffffffc02029fc:	5b860613          	addi	a2,a2,1464 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202a00:	1c600593          	li	a1,454
ffffffffc0202a04:	00003517          	auipc	a0,0x3
ffffffffc0202a08:	5c450513          	addi	a0,a0,1476 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202a0c:	fbefd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(nr_free_pages() == 8 - request);
ffffffffc0202a10:	00004697          	auipc	a3,0x4
ffffffffc0202a14:	09868693          	addi	a3,a3,152 # ffffffffc0206aa8 <etext+0xd80>
ffffffffc0202a18:	00003617          	auipc	a2,0x3
ffffffffc0202a1c:	59860613          	addi	a2,a2,1432 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202a20:	1c400593          	li	a1,452
ffffffffc0202a24:	00003517          	auipc	a0,0x3
ffffffffc0202a28:	5a450513          	addi	a0,a0,1444 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202a2c:	f9efd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(p == arena && !PageProperty(p));
ffffffffc0202a30:	00004697          	auipc	a3,0x4
ffffffffc0202a34:	05868693          	addi	a3,a3,88 # ffffffffc0206a88 <etext+0xd60>
ffffffffc0202a38:	00003617          	auipc	a2,0x3
ffffffffc0202a3c:	57860613          	addi	a2,a2,1400 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202a40:	1c300593          	li	a1,451
ffffffffc0202a44:	00003517          	auipc	a0,0x3
ffffffffc0202a48:	58450513          	addi	a0,a0,1412 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202a4c:	f7efd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == 8 && arena->property == 8);
ffffffffc0202a50:	00004697          	auipc	a3,0x4
ffffffffc0202a54:	fe068693          	addi	a3,a3,-32 # ffffffffc0206a30 <etext+0xd08>
ffffffffc0202a58:	00003617          	auipc	a2,0x3
ffffffffc0202a5c:	55860613          	addi	a2,a2,1368 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202a60:	1b700593          	li	a1,439
ffffffffc0202a64:	00003517          	auipc	a0,0x3
ffffffffc0202a68:	56450513          	addi	a0,a0,1380 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202a6c:	f5efd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == 8);
ffffffffc0202a70:	00004697          	auipc	a3,0x4
ffffffffc0202a74:	2a068693          	addi	a3,a3,672 # ffffffffc0206d10 <etext+0xfe8>
ffffffffc0202a78:	00003617          	auipc	a2,0x3
ffffffffc0202a7c:	53860613          	addi	a2,a2,1336 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202a80:	1b100593          	li	a1,433
ffffffffc0202a84:	00003517          	auipc	a0,0x3
ffffffffc0202a88:	54450513          	addi	a0,a0,1348 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202a8c:	f3efd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(p == arena + 8);
ffffffffc0202a90:	00004697          	auipc	a3,0x4
ffffffffc0202a94:	f9068693          	addi	a3,a3,-112 # ffffffffc0206a20 <etext+0xcf8>
ffffffffc0202a98:	00003617          	auipc	a2,0x3
ffffffffc0202a9c:	51860613          	addi	a2,a2,1304 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202aa0:	1af00593          	li	a1,431
ffffffffc0202aa4:	00003517          	auipc	a0,0x3
ffffffffc0202aa8:	52450513          	addi	a0,a0,1316 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202aac:	f1efd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(PageReserved(arena + i));
ffffffffc0202ab0:	00004697          	auipc	a3,0x4
ffffffffc0202ab4:	f5868693          	addi	a3,a3,-168 # ffffffffc0206a08 <etext+0xce0>
ffffffffc0202ab8:	00003617          	auipc	a2,0x3
ffffffffc0202abc:	4f860613          	addi	a2,a2,1272 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202ac0:	1ab00593          	li	a1,427
ffffffffc0202ac4:	00003517          	auipc	a0,0x3
ffffffffc0202ac8:	50450513          	addi	a0,a0,1284 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202acc:	efefd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == 8);
ffffffffc0202ad0:	00004697          	auipc	a3,0x4
ffffffffc0202ad4:	24068693          	addi	a3,a3,576 # ffffffffc0206d10 <etext+0xfe8>
ffffffffc0202ad8:	00003617          	auipc	a2,0x3
ffffffffc0202adc:	4d860613          	addi	a2,a2,1240 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202ae0:	1a900593          	li	a1,425
ffffffffc0202ae4:	00003517          	auipc	a0,0x3
ffffffffc0202ae8:	4e450513          	addi	a0,a0,1252 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202aec:	edefd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == 13 && PageReserved(arena));
ffffffffc0202af0:	00004697          	auipc	a3,0x4
ffffffffc0202af4:	ee868693          	addi	a3,a3,-280 # ffffffffc02069d8 <etext+0xcb0>
ffffffffc0202af8:	00003617          	auipc	a2,0x3
ffffffffc0202afc:	4b860613          	addi	a2,a2,1208 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202b00:	1a300593          	li	a1,419
ffffffffc0202b04:	00003517          	auipc	a0,0x3
ffffffffc0202b08:	4c450513          	addi	a0,a0,1220 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202b0c:	ebefd0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(PageProperty(arena) && arena->property == sizes[i]);
ffffffffc0202b10:	00004697          	auipc	a3,0x4
ffffffffc0202b14:	e9068693          	addi	a3,a3,-368 # ffffffffc02069a0 <etext+0xc78>
ffffffffc0202b18:	00003617          	auipc	a2,0x3
ffffffffc0202b1c:	49860613          	addi	a2,a2,1176 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202b20:	19d00593          	li	a1,413
ffffffffc0202b24:	00003517          	auipc	a0,0x3
ffffffffc0202b28:	4a450513          	addi	a0,a0,1188 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202b2c:	e9efd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(nr_free_pages() == sizes[i]);
ffffffffc0202b30:	00004697          	auipc	a3,0x4
ffffffffc0202b34:	e5068693          	addi	a3,a3,-432 # ffffffffc0206980 <etext+0xc58>
ffffffffc0202b38:	00003617          	auipc	a2,0x3
ffffffffc0202b3c:	47860613          	addi	a2,a2,1144 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202b40:	19b00593          	li	a1,411
ffffffffc0202b44:	00003517          	auipc	a0,0x3
ffffffffc0202b48:	48450513          	addi	a0,a0,1156 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202b4c:	e7efd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(arena != NULL);
ffffffffc0202b50:	00004697          	auipc	a3,0x4
ffffffffc0202b54:	e2068693          	addi	a3,a3,-480 # ffffffffc0206970 <etext+0xc48>
ffffffffc0202b58:	00003617          	auipc	a2,0x3
ffffffffc0202b5c:	45860613          	addi	a2,a2,1112 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202b60:	29300593          	li	a1,659
ffffffffc0202b64:	00003517          	auipc	a0,0x3
ffffffffc0202b68:	46450513          	addi	a0,a0,1124 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202b6c:	e5efd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(nr_free_pages() == before);
ffffffffc0202b70:	00004697          	auipc	a3,0x4
ffffffffc0202b74:	dc068693          	addi	a3,a3,-576 # ffffffffc0206930 <etext+0xc08>
ffffffffc0202b78:	00003617          	auipc	a2,0x3
ffffffffc0202b7c:	43860613          	addi	a2,a2,1080 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202b80:	18200593          	li	a1,386
ffffffffc0202b84:	00003517          	auipc	a0,0x3
ffffffffc0202b88:	44450513          	addi	a0,a0,1092 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202b8c:	e3efd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(nr_free_pages() == before - 3);
ffffffffc0202b90:	00004697          	auipc	a3,0x4
ffffffffc0202b94:	d8068693          	addi	a3,a3,-640 # ffffffffc0206910 <etext+0xbe8>
ffffffffc0202b98:	00003617          	auipc	a2,0x3
ffffffffc0202b9c:	41860613          	addi	a2,a2,1048 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202ba0:	17e00593          	li	a1,382
ffffffffc0202ba4:	00003517          	auipc	a0,0x3
ffffffffc0202ba8:	42450513          	addi	a0,a0,1060 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202bac:	e1efd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(!PageProperty(a) && !PageProperty(b) && !PageProperty(c));
ffffffffc0202bb0:	00004697          	auipc	a3,0x4
ffffffffc0202bb4:	d2068693          	addi	a3,a3,-736 # ffffffffc02068d0 <etext+0xba8>
ffffffffc0202bb8:	00003617          	auipc	a2,0x3
ffffffffc0202bbc:	3f860613          	addi	a2,a2,1016 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202bc0:	17d00593          	li	a1,381
ffffffffc0202bc4:	00003517          	auipc	a0,0x3
ffffffffc0202bc8:	40450513          	addi	a0,a0,1028 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202bcc:	dfefd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(page_ref(a) == 0 && page_ref(b) == 0 && page_ref(c) == 0);
ffffffffc0202bd0:	00004697          	auipc	a3,0x4
ffffffffc0202bd4:	cc068693          	addi	a3,a3,-832 # ffffffffc0206890 <etext+0xb68>
ffffffffc0202bd8:	00003617          	auipc	a2,0x3
ffffffffc0202bdc:	3d860613          	addi	a2,a2,984 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202be0:	17c00593          	li	a1,380
ffffffffc0202be4:	00003517          	auipc	a0,0x3
ffffffffc0202be8:	3e450513          	addi	a0,a0,996 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202bec:	ddefd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(page2ppn(c) >= nbase && page2ppn(c) < npage);
ffffffffc0202bf0:	00004697          	auipc	a3,0x4
ffffffffc0202bf4:	c7068693          	addi	a3,a3,-912 # ffffffffc0206860 <etext+0xb38>
ffffffffc0202bf8:	00003617          	auipc	a2,0x3
ffffffffc0202bfc:	3b860613          	addi	a2,a2,952 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202c00:	17b00593          	li	a1,379
ffffffffc0202c04:	00003517          	auipc	a0,0x3
ffffffffc0202c08:	3c450513          	addi	a0,a0,964 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202c0c:	dbefd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(page2ppn(b) >= nbase && page2ppn(b) < npage);
ffffffffc0202c10:	00004697          	auipc	a3,0x4
ffffffffc0202c14:	c2068693          	addi	a3,a3,-992 # ffffffffc0206830 <etext+0xb08>
ffffffffc0202c18:	00003617          	auipc	a2,0x3
ffffffffc0202c1c:	39860613          	addi	a2,a2,920 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202c20:	17a00593          	li	a1,378
ffffffffc0202c24:	00003517          	auipc	a0,0x3
ffffffffc0202c28:	3a450513          	addi	a0,a0,932 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202c2c:	d9efd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(page2ppn(a) >= nbase && page2ppn(a) < npage);
ffffffffc0202c30:	00004697          	auipc	a3,0x4
ffffffffc0202c34:	bd068693          	addi	a3,a3,-1072 # ffffffffc0206800 <etext+0xad8>
ffffffffc0202c38:	00003617          	auipc	a2,0x3
ffffffffc0202c3c:	37860613          	addi	a2,a2,888 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202c40:	17900593          	li	a1,377
ffffffffc0202c44:	00003517          	auipc	a0,0x3
ffffffffc0202c48:	38450513          	addi	a0,a0,900 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202c4c:	d7efd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(a != b && a != c && b != c);
ffffffffc0202c50:	00004697          	auipc	a3,0x4
ffffffffc0202c54:	b9068693          	addi	a3,a3,-1136 # ffffffffc02067e0 <etext+0xab8>
ffffffffc0202c58:	00003617          	auipc	a2,0x3
ffffffffc0202c5c:	35860613          	addi	a2,a2,856 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202c60:	17800593          	li	a1,376
ffffffffc0202c64:	00003517          	auipc	a0,0x3
ffffffffc0202c68:	36450513          	addi	a0,a0,868 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202c6c:	d5efd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(a != NULL && b != NULL && c != NULL);
ffffffffc0202c70:	00004697          	auipc	a3,0x4
ffffffffc0202c74:	b4868693          	addi	a3,a3,-1208 # ffffffffc02067b8 <etext+0xa90>
ffffffffc0202c78:	00003617          	auipc	a2,0x3
ffffffffc0202c7c:	33860613          	addi	a2,a2,824 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202c80:	17700593          	li	a1,375
ffffffffc0202c84:	00003517          	auipc	a0,0x3
ffffffffc0202c88:	34450513          	addi	a0,a0,836 # ffffffffc0205fc8 <etext+0x2a0>
ffffffffc0202c8c:	d3efd0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0202c90 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0202c90:	00193797          	auipc	a5,0x193
ffffffffc0202c94:	dd07b783          	ld	a5,-560(a5) # ffffffffc0395a60 <pmm_manager>
ffffffffc0202c98:	6f9c                	ld	a5,24(a5)
ffffffffc0202c9a:	8782                	jr	a5

ffffffffc0202c9c <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0202c9c:	00193797          	auipc	a5,0x193
ffffffffc0202ca0:	dc47b783          	ld	a5,-572(a5) # ffffffffc0395a60 <pmm_manager>
ffffffffc0202ca4:	739c                	ld	a5,32(a5)
ffffffffc0202ca6:	8782                	jr	a5

ffffffffc0202ca8 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0202ca8:	00193797          	auipc	a5,0x193
ffffffffc0202cac:	db87b783          	ld	a5,-584(a5) # ffffffffc0395a60 <pmm_manager>
ffffffffc0202cb0:	779c                	ld	a5,40(a5)
ffffffffc0202cb2:	8782                	jr	a5

ffffffffc0202cb4 <pmm_init>:
    pmm_manager = &buddy_pmm_manager;
ffffffffc0202cb4:	00004797          	auipc	a5,0x4
ffffffffc0202cb8:	67478793          	addi	a5,a5,1652 # ffffffffc0207328 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202cbc:	638c                	ld	a1,0(a5)
    init_memmap(pa2page(free_start),(free_end - free_start) / PGSIZE);
}


/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0202cbe:	715d                	addi	sp,sp,-80
ffffffffc0202cc0:	f84a                	sd	s2,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202cc2:	00004517          	auipc	a0,0x4
ffffffffc0202cc6:	69e50513          	addi	a0,a0,1694 # ffffffffc0207360 <buddy_pmm_manager+0x38>
    pmm_manager = &buddy_pmm_manager;
ffffffffc0202cca:	00193917          	auipc	s2,0x193
ffffffffc0202cce:	d9690913          	addi	s2,s2,-618 # ffffffffc0395a60 <pmm_manager>
void pmm_init(void) {
ffffffffc0202cd2:	e486                	sd	ra,72(sp)
ffffffffc0202cd4:	e0a2                	sd	s0,64(sp)
ffffffffc0202cd6:	fc26                	sd	s1,56(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0202cd8:	00f93023          	sd	a5,0(s2)
void pmm_init(void) {
ffffffffc0202cdc:	f44e                	sd	s3,40(sp)
ffffffffc0202cde:	f052                	sd	s4,32(sp)
ffffffffc0202ce0:	ec56                	sd	s5,24(sp)
ffffffffc0202ce2:	e85a                	sd	s6,16(sp)
ffffffffc0202ce4:	e45e                	sd	s7,8(sp)
ffffffffc0202ce6:	e062                	sd	s8,0(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202ce8:	c6cfd0ef          	jal	ra,ffffffffc0200154 <cprintf>
    pmm_manager->init();
ffffffffc0202cec:	00093783          	ld	a5,0(s2)
ffffffffc0202cf0:	679c                	ld	a5,8(a5)
ffffffffc0202cf2:	9782                	jalr	a5
    uint64_t mem_base = get_memory_base();
ffffffffc0202cf4:	8d1fd0ef          	jal	ra,ffffffffc02005c4 <get_memory_base>
ffffffffc0202cf8:	84aa                	mv	s1,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202cfa:	8d5fd0ef          	jal	ra,ffffffffc02005ce <get_memory_size>
    uint64_t mem_end = mem_base + mem_size;
ffffffffc0202cfe:	00a48433          	add	s0,s1,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202d02:	862a                	mv	a2,a0
    cprintf("Original physical memory: base = 0x%016lx, size = 0x%016lx, end = 0x%016lx\n", mem_base, mem_size, mem_end);
ffffffffc0202d04:	86a2                	mv	a3,s0
ffffffffc0202d06:	85a6                	mv	a1,s1
ffffffffc0202d08:	00004517          	auipc	a0,0x4
ffffffffc0202d0c:	67050513          	addi	a0,a0,1648 # ffffffffc0207378 <buddy_pmm_manager+0x50>
ffffffffc0202d10:	c44fd0ef          	jal	ra,ffffffffc0200154 <cprintf>
    if(mem_base > KERNEL_BEGIN_PADDR) {
ffffffffc0202d14:	40100793          	li	a5,1025
ffffffffc0202d18:	07d6                	slli	a5,a5,0x15
ffffffffc0202d1a:	1a97e963          	bltu	a5,s1,ffffffffc0202ecc <pmm_init+0x218>
    if(mem_base < DRAM_BASE) {
ffffffffc0202d1e:	4785                	li	a5,1
ffffffffc0202d20:	07fe                	slli	a5,a5,0x1f
ffffffffc0202d22:	85a6                	mv	a1,s1
ffffffffc0202d24:	16f4e563          	bltu	s1,a5,ffffffffc0202e8e <pmm_init+0x1da>
    if(mem_end > PHYSICAL_MEMORY_END) {
ffffffffc0202d28:	47c5                	li	a5,17
ffffffffc0202d2a:	07ee                	slli	a5,a5,0x1b
ffffffffc0202d2c:	1487ef63          	bltu	a5,s0,ffffffffc0202e8a <pmm_init+0x1d6>
    mem_size = mem_end - mem_base;
ffffffffc0202d30:	40b40633          	sub	a2,s0,a1
    if(mem_size == 0 || mem_end <= mem_base) {
ffffffffc0202d34:	16b40363          	beq	s0,a1,ffffffffc0202e9a <pmm_init+0x1e6>
ffffffffc0202d38:	1685f163          	bgeu	a1,s0,ffffffffc0202e9a <pmm_init+0x1e6>
    cprintf("Available physical memory: base = 0x%016lx, size = 0x%016lx, end = 0x%016lx\n", mem_base, mem_size, mem_end);
ffffffffc0202d3c:	86a2                	mv	a3,s0
    npage = mem_end / PGSIZE;
ffffffffc0202d3e:	00c45b93          	srli	s7,s0,0xc
    cprintf("Available physical memory: base = 0x%016lx, size = 0x%016lx, end = 0x%016lx\n", mem_base, mem_size, mem_end);
ffffffffc0202d42:	00004517          	auipc	a0,0x4
ffffffffc0202d46:	6c650513          	addi	a0,a0,1734 # ffffffffc0207408 <buddy_pmm_manager+0xe0>
    size_t page_num = npage - nbase;
ffffffffc0202d4a:	fff80a37          	lui	s4,0xfff80
    cprintf("Available physical memory: base = 0x%016lx, size = 0x%016lx, end = 0x%016lx\n", mem_base, mem_size, mem_end);
ffffffffc0202d4e:	c06fd0ef          	jal	ra,ffffffffc0200154 <cprintf>
    size_t page_num = npage - nbase;
ffffffffc0202d52:	9a5e                	add	s4,s4,s7
    uint64_t page_array_size = ROUNDUP(page_num * sizeof(struct Page),PGSIZE);
ffffffffc0202d54:	002a1793          	slli	a5,s4,0x2
ffffffffc0202d58:	97d2                	add	a5,a5,s4
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc0202d5a:	6705                	lui	a4,0x1
ffffffffc0202d5c:	76fd                	lui	a3,0xfffff
ffffffffc0202d5e:	177d                	addi	a4,a4,-1
    uint64_t page_array_size = ROUNDUP(page_num * sizeof(struct Page),PGSIZE);
ffffffffc0202d60:	078e                	slli	a5,a5,0x3
ffffffffc0202d62:	00194617          	auipc	a2,0x194
ffffffffc0202d66:	d2d60613          	addi	a2,a2,-723 # ffffffffc0396a8f <end+0xfff>
ffffffffc0202d6a:	8e75                	and	a2,a2,a3
ffffffffc0202d6c:	97ba                	add	a5,a5,a4
    uintptr_t free_start = PADDR(ROUNDUP(desc_end, PGSIZE));   //虚拟地址转换为物理地址
ffffffffc0202d6e:	8ff5                	and	a5,a5,a3
ffffffffc0202d70:	9732                	add	a4,a4,a2
ffffffffc0202d72:	97ba                	add	a5,a5,a4
    va_pa_offset = KERNBASE - KERNEL_BEGIN_PADDR;
ffffffffc0202d74:	5775                	li	a4,-3
ffffffffc0202d76:	077a                	slli	a4,a4,0x1e
ffffffffc0202d78:	00193997          	auipc	s3,0x193
ffffffffc0202d7c:	d0098993          	addi	s3,s3,-768 # ffffffffc0395a78 <va_pa_offset>
    npage = mem_end / PGSIZE;
ffffffffc0202d80:	00193b17          	auipc	s6,0x193
ffffffffc0202d84:	cd0b0b13          	addi	s6,s6,-816 # ffffffffc0395a50 <npage>
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc0202d88:	00193a97          	auipc	s5,0x193
ffffffffc0202d8c:	cd0a8a93          	addi	s5,s5,-816 # ffffffffc0395a58 <pages>
    va_pa_offset = KERNBASE - KERNEL_BEGIN_PADDR;
ffffffffc0202d90:	00e9b023          	sd	a4,0(s3)
    npage = mem_end / PGSIZE;
ffffffffc0202d94:	017b3023          	sd	s7,0(s6)
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc0202d98:	00cab023          	sd	a2,0(s5)
    uintptr_t free_start = PADDR(ROUNDUP(desc_end, PGSIZE));   //虚拟地址转换为物理地址
ffffffffc0202d9c:	8ff5                	and	a5,a5,a3
ffffffffc0202d9e:	c0200737          	lui	a4,0xc0200
ffffffffc0202da2:	10e7e863          	bltu	a5,a4,ffffffffc0202eb2 <pmm_init+0x1fe>
ffffffffc0202da6:	448d                	li	s1,3
    uintptr_t free_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202da8:	8c75                	and	s0,s0,a3
    uintptr_t free_start = PADDR(ROUNDUP(desc_end, PGSIZE));   //虚拟地址转换为物理地址
ffffffffc0202daa:	04fa                	slli	s1,s1,0x1e
    cprintf("Free physical memory: start = 0x%016lx, end = 0x%016lx, size = 0x%016lx\n", free_start, free_end, free_end - free_start);
ffffffffc0202dac:	40940c33          	sub	s8,s0,s1
ffffffffc0202db0:	40fc0c33          	sub	s8,s8,a5
    uintptr_t free_start = PADDR(ROUNDUP(desc_end, PGSIZE));   //虚拟地址转换为物理地址
ffffffffc0202db4:	94be                	add	s1,s1,a5
    cprintf("Free physical memory: start = 0x%016lx, end = 0x%016lx, size = 0x%016lx\n", free_start, free_end, free_end - free_start);
ffffffffc0202db6:	86e2                	mv	a3,s8
ffffffffc0202db8:	8622                	mv	a2,s0
ffffffffc0202dba:	85a6                	mv	a1,s1
ffffffffc0202dbc:	00004517          	auipc	a0,0x4
ffffffffc0202dc0:	6c450513          	addi	a0,a0,1732 # ffffffffc0207480 <buddy_pmm_manager+0x158>
ffffffffc0202dc4:	b90fd0ef          	jal	ra,ffffffffc0200154 <cprintf>
    if(free_start >= free_end) {
ffffffffc0202dc8:	1484f763          	bgeu	s1,s0,ffffffffc0202f16 <pmm_init+0x262>
    for(size_t i = 0 ; i < page_num; i++){
ffffffffc0202dcc:	020a0b63          	beqz	s4,ffffffffc0202e02 <pmm_init+0x14e>
        pages[i].flags = 0;
ffffffffc0202dd0:	000ab783          	ld	a5,0(s5)
ffffffffc0202dd4:	002b9613          	slli	a2,s7,0x2
ffffffffc0202dd8:	fec00737          	lui	a4,0xfec00
ffffffffc0202ddc:	965e                	add	a2,a2,s7
ffffffffc0202dde:	0761                	addi	a4,a4,24
ffffffffc0202de0:	973e                	add	a4,a4,a5
ffffffffc0202de2:	060e                	slli	a2,a2,0x3
ffffffffc0202de4:	9732                	add	a4,a4,a2
ffffffffc0202de6:	07e1                	addi	a5,a5,24
        SetPageReserved(&pages[i]);
ffffffffc0202de8:	4605                	li	a2,1
        pages[i].property =0;
ffffffffc0202dea:	fe07ac23          	sw	zero,-8(a5)
ffffffffc0202dee:	fe07a423          	sw	zero,-24(a5)
ffffffffc0202df2:	e79c                	sd	a5,8(a5)
ffffffffc0202df4:	e39c                	sd	a5,0(a5)
        SetPageReserved(&pages[i]);
ffffffffc0202df6:	fec7b823          	sd	a2,-16(a5)
    for(size_t i = 0 ; i < page_num; i++){
ffffffffc0202dfa:	02878793          	addi	a5,a5,40
ffffffffc0202dfe:	fee796e3          	bne	a5,a4,ffffffffc0202dea <pmm_init+0x136>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0202e02:	000b3783          	ld	a5,0(s6)
ffffffffc0202e06:	80b1                	srli	s1,s1,0xc
ffffffffc0202e08:	0ef4fb63          	bgeu	s1,a5,ffffffffc0202efe <pmm_init+0x24a>
    pmm_manager->init_memmap(base, n);
ffffffffc0202e0c:	00093783          	ld	a5,0(s2)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0202e10:	fff805b7          	lui	a1,0xfff80
ffffffffc0202e14:	94ae                	add	s1,s1,a1
ffffffffc0202e16:	00249713          	slli	a4,s1,0x2
ffffffffc0202e1a:	000ab503          	ld	a0,0(s5)
ffffffffc0202e1e:	94ba                	add	s1,s1,a4
ffffffffc0202e20:	6b9c                	ld	a5,16(a5)
ffffffffc0202e22:	048e                	slli	s1,s1,0x3
ffffffffc0202e24:	00cc5593          	srli	a1,s8,0xc
ffffffffc0202e28:	9526                	add	a0,a0,s1
ffffffffc0202e2a:	9782                	jalr	a5
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0202e2c:	00093783          	ld	a5,0(s2)
ffffffffc0202e30:	7b9c                	ld	a5,48(a5)
ffffffffc0202e32:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202e34:	00004517          	auipc	a0,0x4
ffffffffc0202e38:	6ec50513          	addi	a0,a0,1772 # ffffffffc0207520 <buddy_pmm_manager+0x1f8>
ffffffffc0202e3c:	b18fd0ef          	jal	ra,ffffffffc0200154 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0202e40:	00008597          	auipc	a1,0x8
ffffffffc0202e44:	1c058593          	addi	a1,a1,448 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0202e48:	00193797          	auipc	a5,0x193
ffffffffc0202e4c:	c2b7b423          	sd	a1,-984(a5) # ffffffffc0395a70 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0202e50:	c02007b7          	lui	a5,0xc0200
ffffffffc0202e54:	08f5e863          	bltu	a1,a5,ffffffffc0202ee4 <pmm_init+0x230>
ffffffffc0202e58:	0009b603          	ld	a2,0(s3)
}
ffffffffc0202e5c:	6406                	ld	s0,64(sp)
ffffffffc0202e5e:	60a6                	ld	ra,72(sp)
ffffffffc0202e60:	74e2                	ld	s1,56(sp)
ffffffffc0202e62:	7942                	ld	s2,48(sp)
ffffffffc0202e64:	79a2                	ld	s3,40(sp)
ffffffffc0202e66:	7a02                	ld	s4,32(sp)
ffffffffc0202e68:	6ae2                	ld	s5,24(sp)
ffffffffc0202e6a:	6b42                	ld	s6,16(sp)
ffffffffc0202e6c:	6ba2                	ld	s7,8(sp)
ffffffffc0202e6e:	6c02                	ld	s8,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0202e70:	40c58633          	sub	a2,a1,a2
ffffffffc0202e74:	00193797          	auipc	a5,0x193
ffffffffc0202e78:	bec7ba23          	sd	a2,-1036(a5) # ffffffffc0395a68 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0202e7c:	00004517          	auipc	a0,0x4
ffffffffc0202e80:	6c450513          	addi	a0,a0,1732 # ffffffffc0207540 <buddy_pmm_manager+0x218>
}
ffffffffc0202e84:	6161                	addi	sp,sp,80
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0202e86:	acefd06f          	j	ffffffffc0200154 <cprintf>
ffffffffc0202e8a:	843e                	mv	s0,a5
ffffffffc0202e8c:	b555                	j	ffffffffc0202d30 <pmm_init+0x7c>
ffffffffc0202e8e:	85be                	mv	a1,a5
    if(mem_end > PHYSICAL_MEMORY_END) {
ffffffffc0202e90:	47c5                	li	a5,17
ffffffffc0202e92:	07ee                	slli	a5,a5,0x1b
ffffffffc0202e94:	e887fee3          	bgeu	a5,s0,ffffffffc0202d30 <pmm_init+0x7c>
ffffffffc0202e98:	bfcd                	j	ffffffffc0202e8a <pmm_init+0x1d6>
        panic("invalid memory size");
ffffffffc0202e9a:	00004617          	auipc	a2,0x4
ffffffffc0202e9e:	55660613          	addi	a2,a2,1366 # ffffffffc02073f0 <buddy_pmm_manager+0xc8>
ffffffffc0202ea2:	05400593          	li	a1,84
ffffffffc0202ea6:	00004517          	auipc	a0,0x4
ffffffffc0202eaa:	53a50513          	addi	a0,a0,1338 # ffffffffc02073e0 <buddy_pmm_manager+0xb8>
ffffffffc0202eae:	b1cfd0ef          	jal	ra,ffffffffc02001ca <__panic>
    uintptr_t free_start = PADDR(ROUNDUP(desc_end, PGSIZE));   //虚拟地址转换为物理地址
ffffffffc0202eb2:	86be                	mv	a3,a5
ffffffffc0202eb4:	00004617          	auipc	a2,0x4
ffffffffc0202eb8:	5a460613          	addi	a2,a2,1444 # ffffffffc0207458 <buddy_pmm_manager+0x130>
ffffffffc0202ebc:	06300593          	li	a1,99
ffffffffc0202ec0:	00004517          	auipc	a0,0x4
ffffffffc0202ec4:	52050513          	addi	a0,a0,1312 # ffffffffc02073e0 <buddy_pmm_manager+0xb8>
ffffffffc0202ec8:	b02fd0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("invalid memory base");
ffffffffc0202ecc:	00004617          	auipc	a2,0x4
ffffffffc0202ed0:	4fc60613          	addi	a2,a2,1276 # ffffffffc02073c8 <buddy_pmm_manager+0xa0>
ffffffffc0202ed4:	04a00593          	li	a1,74
ffffffffc0202ed8:	00004517          	auipc	a0,0x4
ffffffffc0202edc:	50850513          	addi	a0,a0,1288 # ffffffffc02073e0 <buddy_pmm_manager+0xb8>
ffffffffc0202ee0:	aeafd0ef          	jal	ra,ffffffffc02001ca <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0202ee4:	86ae                	mv	a3,a1
ffffffffc0202ee6:	00004617          	auipc	a2,0x4
ffffffffc0202eea:	57260613          	addi	a2,a2,1394 # ffffffffc0207458 <buddy_pmm_manager+0x130>
ffffffffc0202eee:	08b00593          	li	a1,139
ffffffffc0202ef2:	00004517          	auipc	a0,0x4
ffffffffc0202ef6:	4ee50513          	addi	a0,a0,1262 # ffffffffc02073e0 <buddy_pmm_manager+0xb8>
ffffffffc0202efa:	ad0fd0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202efe:	00004617          	auipc	a2,0x4
ffffffffc0202f02:	5f260613          	addi	a2,a2,1522 # ffffffffc02074f0 <buddy_pmm_manager+0x1c8>
ffffffffc0202f06:	06a00593          	li	a1,106
ffffffffc0202f0a:	00004517          	auipc	a0,0x4
ffffffffc0202f0e:	60650513          	addi	a0,a0,1542 # ffffffffc0207510 <buddy_pmm_manager+0x1e8>
ffffffffc0202f12:	ab8fd0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("no free memory available");
ffffffffc0202f16:	00004617          	auipc	a2,0x4
ffffffffc0202f1a:	5ba60613          	addi	a2,a2,1466 # ffffffffc02074d0 <buddy_pmm_manager+0x1a8>
ffffffffc0202f1e:	06a00593          	li	a1,106
ffffffffc0202f22:	00004517          	auipc	a0,0x4
ffffffffc0202f26:	4be50513          	addi	a0,a0,1214 # ffffffffc02073e0 <buddy_pmm_manager+0xb8>
ffffffffc0202f2a:	aa0fd0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0202f2e <slub_page_address>:
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202f2e:	00193797          	auipc	a5,0x193
ffffffffc0202f32:	b2a7b783          	ld	a5,-1238(a5) # ffffffffc0395a58 <pages>
ffffffffc0202f36:	8d1d                	sub	a0,a0,a5
ffffffffc0202f38:	850d                	srai	a0,a0,0x3
ffffffffc0202f3a:	00006797          	auipc	a5,0x6
ffffffffc0202f3e:	aa67b783          	ld	a5,-1370(a5) # ffffffffc02089e0 <error_string+0x38>
ffffffffc0202f42:	02f50533          	mul	a0,a0,a5
}

static uintptr_t
slub_physical_limit(void) {
    uintptr_t limit = npage * PGSIZE;
    return limit < PHYSICAL_MEMORY_END ? limit : PHYSICAL_MEMORY_END;
ffffffffc0202f46:	4745                	li	a4,17
    uintptr_t limit = npage * PGSIZE;
ffffffffc0202f48:	00193797          	auipc	a5,0x193
ffffffffc0202f4c:	b087b783          	ld	a5,-1272(a5) # ffffffffc0395a50 <npage>
ffffffffc0202f50:	00006697          	auipc	a3,0x6
ffffffffc0202f54:	aa06b683          	ld	a3,-1376(a3) # ffffffffc02089f0 <nbase>
ffffffffc0202f58:	07b2                	slli	a5,a5,0xc
    return limit < PHYSICAL_MEMORY_END ? limit : PHYSICAL_MEMORY_END;
ffffffffc0202f5a:	076e                	slli	a4,a4,0x1b
ffffffffc0202f5c:	9536                	add	a0,a0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202f5e:	0532                	slli	a0,a0,0xc
ffffffffc0202f60:	00f77363          	bgeu	a4,a5,ffffffffc0202f66 <slub_page_address+0x38>
ffffffffc0202f64:	87ba                	mv	a5,a4
// with explicit physical range checks, instead of casting a Page descriptor.
static void *
slub_page_address(struct Page *page, size_t npages) {
    uintptr_t pa = page2pa(page);
    uintptr_t limit = slub_physical_limit();
    if (pa < KERNEL_BEGIN_PADDR || pa >= limit ||
ffffffffc0202f66:	40100713          	li	a4,1025
ffffffffc0202f6a:	0756                	slli	a4,a4,0x15
ffffffffc0202f6c:	00e56f63          	bltu	a0,a4,ffffffffc0202f8a <slub_page_address+0x5c>
ffffffffc0202f70:	00f57d63          	bgeu	a0,a5,ffffffffc0202f8a <slub_page_address+0x5c>
ffffffffc0202f74:	c999                	beqz	a1,ffffffffc0202f8a <slub_page_address+0x5c>
        npages == 0 || npages > (limit - pa) / PGSIZE) {
ffffffffc0202f76:	8f89                	sub	a5,a5,a0
ffffffffc0202f78:	83b1                	srli	a5,a5,0xc
ffffffffc0202f7a:	00b7e863          	bltu	a5,a1,ffffffffc0202f8a <slub_page_address+0x5c>
        return NULL;
    }
    return (void *)(pa + va_pa_offset);
ffffffffc0202f7e:	00193797          	auipc	a5,0x193
ffffffffc0202f82:	afa7b783          	ld	a5,-1286(a5) # ffffffffc0395a78 <va_pa_offset>
ffffffffc0202f86:	953e                	add	a0,a0,a5
ffffffffc0202f88:	8082                	ret
        return NULL;
ffffffffc0202f8a:	4501                	li	a0,0
}
ffffffffc0202f8c:	8082                	ret

ffffffffc0202f8e <slub_object_index>:
    return (void *)((uintptr_t)slab + SLUB_DATA_OFFSET +
                   index * slab->cache->object_size);
}

static size_t
slub_object_index(struct slub_slab *slab, const void *ptr) {
ffffffffc0202f8e:	1141                	addi	sp,sp,-16
ffffffffc0202f90:	87aa                	mv	a5,a0
ffffffffc0202f92:	e406                	sd	ra,8(sp)
    uintptr_t start = (uintptr_t)slab + SLUB_DATA_OFFSET;
ffffffffc0202f94:	08050513          	addi	a0,a0,128
    uintptr_t address = (uintptr_t)ptr;
    assert(address >= start);
ffffffffc0202f98:	02a5e063          	bltu	a1,a0,ffffffffc0202fb8 <slub_object_index+0x2a>
    size_t offset = address - start;
    assert(offset % slab->cache->object_size == 0);
ffffffffc0202f9c:	6f98                	ld	a4,24(a5)
    size_t offset = address - start;
ffffffffc0202f9e:	8d89                	sub	a1,a1,a0
    assert(offset % slab->cache->object_size == 0);
ffffffffc0202fa0:	6308                	ld	a0,0(a4)
ffffffffc0202fa2:	02a5f733          	remu	a4,a1,a0
ffffffffc0202fa6:	eb29                	bnez	a4,ffffffffc0202ff8 <slub_object_index+0x6a>
    size_t index = offset / slab->cache->object_size;
ffffffffc0202fa8:	02a5d533          	divu	a0,a1,a0
    assert(index < slab->total);
ffffffffc0202fac:	63bc                	ld	a5,64(a5)
ffffffffc0202fae:	02f57563          	bgeu	a0,a5,ffffffffc0202fd8 <slub_object_index+0x4a>
    return index;
}
ffffffffc0202fb2:	60a2                	ld	ra,8(sp)
ffffffffc0202fb4:	0141                	addi	sp,sp,16
ffffffffc0202fb6:	8082                	ret
    assert(address >= start);
ffffffffc0202fb8:	00004697          	auipc	a3,0x4
ffffffffc0202fbc:	5c868693          	addi	a3,a3,1480 # ffffffffc0207580 <buddy_pmm_manager+0x258>
ffffffffc0202fc0:	00003617          	auipc	a2,0x3
ffffffffc0202fc4:	ff060613          	addi	a2,a2,-16 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202fc8:	05500593          	li	a1,85
ffffffffc0202fcc:	00004517          	auipc	a0,0x4
ffffffffc0202fd0:	5cc50513          	addi	a0,a0,1484 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0202fd4:	9f6fd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(index < slab->total);
ffffffffc0202fd8:	00004697          	auipc	a3,0x4
ffffffffc0202fdc:	5f868693          	addi	a3,a3,1528 # ffffffffc02075d0 <buddy_pmm_manager+0x2a8>
ffffffffc0202fe0:	00003617          	auipc	a2,0x3
ffffffffc0202fe4:	fd060613          	addi	a2,a2,-48 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0202fe8:	05900593          	li	a1,89
ffffffffc0202fec:	00004517          	auipc	a0,0x4
ffffffffc0202ff0:	5ac50513          	addi	a0,a0,1452 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0202ff4:	9d6fd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(offset % slab->cache->object_size == 0);
ffffffffc0202ff8:	00004697          	auipc	a3,0x4
ffffffffc0202ffc:	5b068693          	addi	a3,a3,1456 # ffffffffc02075a8 <buddy_pmm_manager+0x280>
ffffffffc0203000:	00003617          	auipc	a2,0x3
ffffffffc0203004:	fb060613          	addi	a2,a2,-80 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203008:	05700593          	li	a1,87
ffffffffc020300c:	00004517          	auipc	a0,0x4
ffffffffc0203010:	58c50513          	addi	a0,a0,1420 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203014:	9b6fd0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0203018 <slub_lookup>:
slub_slot_allocated(struct slub_slab *slab, size_t index) {
    return (slab->allocated[index / 64] >> (index % 64)) & 1;
}

static struct slub_slab *
slub_lookup(const void *ptr) {
ffffffffc0203018:	1141                	addi	sp,sp,-16
ffffffffc020301a:	e406                	sd	ra,8(sp)
ffffffffc020301c:	e022                	sd	s0,0(sp)
    assert(initialized);
ffffffffc020301e:	00193797          	auipc	a5,0x193
ffffffffc0203022:	a627a783          	lw	a5,-1438(a5) # ffffffffc0395a80 <initialized>
ffffffffc0203026:	12078563          	beqz	a5,ffffffffc0203150 <slub_lookup+0x138>
    uintptr_t address = ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc020302a:	747d                	lui	s0,0xfffff
ffffffffc020302c:	8c69                	and	s0,s0,a0
    uintptr_t pa = address - va_pa_offset;
ffffffffc020302e:	00193797          	auipc	a5,0x193
ffffffffc0203032:	a4a7b783          	ld	a5,-1462(a5) # ffffffffc0395a78 <va_pa_offset>
    assert(pa >= KERNEL_BEGIN_PADDR && pa < slub_physical_limit());
ffffffffc0203036:	40100713          	li	a4,1025
    uintptr_t pa = address - va_pa_offset;
ffffffffc020303a:	40f407b3          	sub	a5,s0,a5
    assert(pa >= KERNEL_BEGIN_PADDR && pa < slub_physical_limit());
ffffffffc020303e:	0756                	slli	a4,a4,0x15
ffffffffc0203040:	0ae7ec63          	bltu	a5,a4,ffffffffc02030f8 <slub_lookup+0xe0>
    uintptr_t limit = npage * PGSIZE;
ffffffffc0203044:	00193617          	auipc	a2,0x193
ffffffffc0203048:	a0c63603          	ld	a2,-1524(a2) # ffffffffc0395a50 <npage>
    return limit < PHYSICAL_MEMORY_END ? limit : PHYSICAL_MEMORY_END;
ffffffffc020304c:	4745                	li	a4,17
    uintptr_t limit = npage * PGSIZE;
ffffffffc020304e:	00c61693          	slli	a3,a2,0xc
    return limit < PHYSICAL_MEMORY_END ? limit : PHYSICAL_MEMORY_END;
ffffffffc0203052:	076e                	slli	a4,a4,0x1b
ffffffffc0203054:	04d76f63          	bltu	a4,a3,ffffffffc02030b2 <slub_lookup+0x9a>
    assert(pa >= KERNEL_BEGIN_PADDR && pa < slub_physical_limit());
ffffffffc0203058:	0ad7f063          	bgeu	a5,a3,ffffffffc02030f8 <slub_lookup+0xe0>
    struct slub_slab *slab = (struct slub_slab *)address;
    assert(slab->magic == SLUB_MAGIC && slab->page == pa2page(pa));
ffffffffc020305c:	6014                	ld	a3,0(s0)
ffffffffc020305e:	00006717          	auipc	a4,0x6
ffffffffc0203062:	98a73703          	ld	a4,-1654(a4) # ffffffffc02089e8 <error_string+0x40>
ffffffffc0203066:	0ae69963          	bne	a3,a4,ffffffffc0203118 <slub_lookup+0x100>
    if (PPN(pa) >= npage) {
ffffffffc020306a:	83b1                	srli	a5,a5,0xc
ffffffffc020306c:	6814                	ld	a3,16(s0)
ffffffffc020306e:	0cc7f563          	bgeu	a5,a2,ffffffffc0203138 <slub_lookup+0x120>
    return &pages[PPN(pa) - nbase];
ffffffffc0203072:	00006717          	auipc	a4,0x6
ffffffffc0203076:	97e73703          	ld	a4,-1666(a4) # ffffffffc02089f0 <nbase>
ffffffffc020307a:	8f99                	sub	a5,a5,a4
ffffffffc020307c:	00279713          	slli	a4,a5,0x2
ffffffffc0203080:	97ba                	add	a5,a5,a4
ffffffffc0203082:	078e                	slli	a5,a5,0x3
ffffffffc0203084:	00193717          	auipc	a4,0x193
ffffffffc0203088:	9d473703          	ld	a4,-1580(a4) # ffffffffc0395a58 <pages>
ffffffffc020308c:	97ba                	add	a5,a5,a4
ffffffffc020308e:	08f69563          	bne	a3,a5,ffffffffc0203118 <slub_lookup+0x100>
    if (slab->kind == SLUB_SMALL) {
ffffffffc0203092:	641c                	ld	a5,8(s0)
ffffffffc0203094:	4705                	li	a4,1
ffffffffc0203096:	02e78063          	beq	a5,a4,ffffffffc02030b6 <slub_lookup+0x9e>
        assert(slab->cache != NULL);
        size_t index = slub_object_index(slab, ptr);
        assert(slub_slot_allocated(slab, index));
    } else {
        assert(slab->kind == SLUB_LARGE);
ffffffffc020309a:	4709                	li	a4,2
ffffffffc020309c:	0ce79a63          	bne	a5,a4,ffffffffc0203170 <slub_lookup+0x158>
        assert((uintptr_t)ptr == address + SLUB_DATA_OFFSET);
ffffffffc02030a0:	08040793          	addi	a5,s0,128 # fffffffffffff080 <end+0x3fc695f0>
ffffffffc02030a4:	0ef51663          	bne	a0,a5,ffffffffc0203190 <slub_lookup+0x178>
    }
    return slab;
}
ffffffffc02030a8:	60a2                	ld	ra,8(sp)
ffffffffc02030aa:	8522                	mv	a0,s0
ffffffffc02030ac:	6402                	ld	s0,0(sp)
ffffffffc02030ae:	0141                	addi	sp,sp,16
ffffffffc02030b0:	8082                	ret
    return limit < PHYSICAL_MEMORY_END ? limit : PHYSICAL_MEMORY_END;
ffffffffc02030b2:	86ba                	mv	a3,a4
ffffffffc02030b4:	b755                	j	ffffffffc0203058 <slub_lookup+0x40>
        assert(slab->cache != NULL);
ffffffffc02030b6:	6c1c                	ld	a5,24(s0)
ffffffffc02030b8:	0e078c63          	beqz	a5,ffffffffc02031b0 <slub_lookup+0x198>
        size_t index = slub_object_index(slab, ptr);
ffffffffc02030bc:	85aa                	mv	a1,a0
ffffffffc02030be:	8522                	mv	a0,s0
ffffffffc02030c0:	ecfff0ef          	jal	ra,ffffffffc0202f8e <slub_object_index>
    return (slab->allocated[index / 64] >> (index % 64)) & 1;
ffffffffc02030c4:	00655793          	srli	a5,a0,0x6
ffffffffc02030c8:	07a9                	addi	a5,a5,10
ffffffffc02030ca:	078e                	slli	a5,a5,0x3
ffffffffc02030cc:	97a2                	add	a5,a5,s0
ffffffffc02030ce:	679c                	ld	a5,8(a5)
ffffffffc02030d0:	00a7d533          	srl	a0,a5,a0
        assert(slub_slot_allocated(slab, index));
ffffffffc02030d4:	8905                	andi	a0,a0,1
ffffffffc02030d6:	f969                	bnez	a0,ffffffffc02030a8 <slub_lookup+0x90>
ffffffffc02030d8:	00004697          	auipc	a3,0x4
ffffffffc02030dc:	5a868693          	addi	a3,a3,1448 # ffffffffc0207680 <buddy_pmm_manager+0x358>
ffffffffc02030e0:	00003617          	auipc	a2,0x3
ffffffffc02030e4:	ed060613          	addi	a2,a2,-304 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02030e8:	06d00593          	li	a1,109
ffffffffc02030ec:	00004517          	auipc	a0,0x4
ffffffffc02030f0:	4ac50513          	addi	a0,a0,1196 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02030f4:	8d6fd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(pa >= KERNEL_BEGIN_PADDR && pa < slub_physical_limit());
ffffffffc02030f8:	00004697          	auipc	a3,0x4
ffffffffc02030fc:	50068693          	addi	a3,a3,1280 # ffffffffc02075f8 <buddy_pmm_manager+0x2d0>
ffffffffc0203100:	00003617          	auipc	a2,0x3
ffffffffc0203104:	eb060613          	addi	a2,a2,-336 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203108:	06700593          	li	a1,103
ffffffffc020310c:	00004517          	auipc	a0,0x4
ffffffffc0203110:	48c50513          	addi	a0,a0,1164 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203114:	8b6fd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(slab->magic == SLUB_MAGIC && slab->page == pa2page(pa));
ffffffffc0203118:	00004697          	auipc	a3,0x4
ffffffffc020311c:	51868693          	addi	a3,a3,1304 # ffffffffc0207630 <buddy_pmm_manager+0x308>
ffffffffc0203120:	00003617          	auipc	a2,0x3
ffffffffc0203124:	e9060613          	addi	a2,a2,-368 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203128:	06900593          	li	a1,105
ffffffffc020312c:	00004517          	auipc	a0,0x4
ffffffffc0203130:	46c50513          	addi	a0,a0,1132 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203134:	896fd0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203138:	00004617          	auipc	a2,0x4
ffffffffc020313c:	3b860613          	addi	a2,a2,952 # ffffffffc02074f0 <buddy_pmm_manager+0x1c8>
ffffffffc0203140:	06a00593          	li	a1,106
ffffffffc0203144:	00004517          	auipc	a0,0x4
ffffffffc0203148:	3cc50513          	addi	a0,a0,972 # ffffffffc0207510 <buddy_pmm_manager+0x1e8>
ffffffffc020314c:	87efd0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(initialized);
ffffffffc0203150:	00004697          	auipc	a3,0x4
ffffffffc0203154:	49868693          	addi	a3,a3,1176 # ffffffffc02075e8 <buddy_pmm_manager+0x2c0>
ffffffffc0203158:	00003617          	auipc	a2,0x3
ffffffffc020315c:	e5860613          	addi	a2,a2,-424 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203160:	06400593          	li	a1,100
ffffffffc0203164:	00004517          	auipc	a0,0x4
ffffffffc0203168:	43450513          	addi	a0,a0,1076 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020316c:	85efd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(slab->kind == SLUB_LARGE);
ffffffffc0203170:	00004697          	auipc	a3,0x4
ffffffffc0203174:	53868693          	addi	a3,a3,1336 # ffffffffc02076a8 <buddy_pmm_manager+0x380>
ffffffffc0203178:	00003617          	auipc	a2,0x3
ffffffffc020317c:	e3860613          	addi	a2,a2,-456 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203180:	06f00593          	li	a1,111
ffffffffc0203184:	00004517          	auipc	a0,0x4
ffffffffc0203188:	41450513          	addi	a0,a0,1044 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020318c:	83efd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert((uintptr_t)ptr == address + SLUB_DATA_OFFSET);
ffffffffc0203190:	00004697          	auipc	a3,0x4
ffffffffc0203194:	53868693          	addi	a3,a3,1336 # ffffffffc02076c8 <buddy_pmm_manager+0x3a0>
ffffffffc0203198:	00003617          	auipc	a2,0x3
ffffffffc020319c:	e1860613          	addi	a2,a2,-488 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02031a0:	07000593          	li	a1,112
ffffffffc02031a4:	00004517          	auipc	a0,0x4
ffffffffc02031a8:	3f450513          	addi	a0,a0,1012 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02031ac:	81efd0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(slab->cache != NULL);
ffffffffc02031b0:	00004697          	auipc	a3,0x4
ffffffffc02031b4:	4b868693          	addi	a3,a3,1208 # ffffffffc0207668 <buddy_pmm_manager+0x340>
ffffffffc02031b8:	00003617          	auipc	a2,0x3
ffffffffc02031bc:	df860613          	addi	a2,a2,-520 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02031c0:	06b00593          	li	a1,107
ffffffffc02031c4:	00004517          	auipc	a0,0x4
ffffffffc02031c8:	3d450513          	addi	a0,a0,980 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02031cc:	ffffc0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02031d0 <slub_check_mark_pages>:
static unsigned char checked_frames[SLUB_FRAME_CAPACITY];
static void *test_objects[2 * SLUB_MAX_SLOTS + 1];

static void
slub_check_mark_pages(struct slub_slab *slab) {
    assert(slab->magic == SLUB_MAGIC);
ffffffffc02031d0:	6118                	ld	a4,0(a0)
slub_check_mark_pages(struct slub_slab *slab) {
ffffffffc02031d2:	1101                	addi	sp,sp,-32
ffffffffc02031d4:	ec06                	sd	ra,24(sp)
ffffffffc02031d6:	e822                	sd	s0,16(sp)
ffffffffc02031d8:	e426                	sd	s1,8(sp)
ffffffffc02031da:	e04a                	sd	s2,0(sp)
    assert(slab->magic == SLUB_MAGIC);
ffffffffc02031dc:	00006797          	auipc	a5,0x6
ffffffffc02031e0:	80c7b783          	ld	a5,-2036(a5) # ffffffffc02089e8 <error_string+0x40>
ffffffffc02031e4:	0cf71f63          	bne	a4,a5,ffffffffc02032c2 <slub_check_mark_pages+0xf2>
    assert(slub_page_address(slab->page, slab->npages) == (void *)slab);
ffffffffc02031e8:	03053903          	ld	s2,48(a0)
ffffffffc02031ec:	6900                	ld	s0,16(a0)
ffffffffc02031ee:	84aa                	mv	s1,a0
ffffffffc02031f0:	85ca                	mv	a1,s2
ffffffffc02031f2:	8522                	mv	a0,s0
ffffffffc02031f4:	d3bff0ef          	jal	ra,ffffffffc0202f2e <slub_page_address>
ffffffffc02031f8:	0ea49563          	bne	s1,a0,ffffffffc02032e2 <slub_check_mark_pages+0x112>
    size_t index = slab->page - pages;
ffffffffc02031fc:	00193817          	auipc	a6,0x193
ffffffffc0203200:	85c83803          	ld	a6,-1956(a6) # ffffffffc0395a58 <pages>
ffffffffc0203204:	41040833          	sub	a6,s0,a6
ffffffffc0203208:	40385813          	srai	a6,a6,0x3
ffffffffc020320c:	00005697          	auipc	a3,0x5
ffffffffc0203210:	7d46b683          	ld	a3,2004(a3) # ffffffffc02089e0 <error_string+0x38>
    assert(npage >= nbase && npage - nbase <= SLUB_FRAME_CAPACITY);
ffffffffc0203214:	00193797          	auipc	a5,0x193
ffffffffc0203218:	83c7b783          	ld	a5,-1988(a5) # ffffffffc0395a50 <npage>
ffffffffc020321c:	00005717          	auipc	a4,0x5
ffffffffc0203220:	7d473703          	ld	a4,2004(a4) # ffffffffc02089f0 <nbase>
    size_t index = slab->page - pages;
ffffffffc0203224:	02d80833          	mul	a6,a6,a3
    assert(npage >= nbase && npage - nbase <= SLUB_FRAME_CAPACITY);
ffffffffc0203228:	0ce7ed63          	bltu	a5,a4,ffffffffc0203302 <slub_check_mark_pages+0x132>
ffffffffc020322c:	8f99                	sub	a5,a5,a4
ffffffffc020322e:	6721                	lui	a4,0x8
ffffffffc0203230:	0cf76963          	bltu	a4,a5,ffffffffc0203302 <slub_check_mark_pages+0x132>
    assert(index < npage - nbase && slab->npages <= npage - nbase - index);
ffffffffc0203234:	0ef87763          	bgeu	a6,a5,ffffffffc0203322 <slub_check_mark_pages+0x152>
ffffffffc0203238:	410787b3          	sub	a5,a5,a6
ffffffffc020323c:	0f27e363          	bltu	a5,s2,ffffffffc0203322 <slub_check_mark_pages+0x152>
    for (size_t i = index; i < index + slab->npages; i++) {
ffffffffc0203240:	9942                	add	s2,s2,a6
ffffffffc0203242:	03287a63          	bgeu	a6,s2,ffffffffc0203276 <slub_check_mark_pages+0xa6>
ffffffffc0203246:	00189797          	auipc	a5,0x189
ffffffffc020324a:	7da78793          	addi	a5,a5,2010 # ffffffffc038ca20 <checked_frames>
ffffffffc020324e:	97c2                	add	a5,a5,a6
ffffffffc0203250:	86a2                	mv	a3,s0
ffffffffc0203252:	8642                	mv	a2,a6
        assert(!checked_frames[i]);
        assert(!PageReserved(pages + i) && !PageProperty(pages + i));
        checked_frames[i] = 1;
ffffffffc0203254:	4585                	li	a1,1
        assert(!checked_frames[i]);
ffffffffc0203256:	0007c703          	lbu	a4,0(a5)
ffffffffc020325a:	e705                	bnez	a4,ffffffffc0203282 <slub_check_mark_pages+0xb2>
        assert(!PageReserved(pages + i) && !PageProperty(pages + i));
ffffffffc020325c:	6698                	ld	a4,8(a3)
ffffffffc020325e:	8b0d                	andi	a4,a4,3
ffffffffc0203260:	e329                	bnez	a4,ffffffffc02032a2 <slub_check_mark_pages+0xd2>
        checked_frames[i] = 1;
ffffffffc0203262:	00b78023          	sb	a1,0(a5)
    for (size_t i = index; i < index + slab->npages; i++) {
ffffffffc0203266:	7898                	ld	a4,48(s1)
ffffffffc0203268:	0605                	addi	a2,a2,1
ffffffffc020326a:	0785                	addi	a5,a5,1
ffffffffc020326c:	9742                	add	a4,a4,a6
ffffffffc020326e:	02868693          	addi	a3,a3,40
ffffffffc0203272:	fee662e3          	bltu	a2,a4,ffffffffc0203256 <slub_check_mark_pages+0x86>
    }
}
ffffffffc0203276:	60e2                	ld	ra,24(sp)
ffffffffc0203278:	6442                	ld	s0,16(sp)
ffffffffc020327a:	64a2                	ld	s1,8(sp)
ffffffffc020327c:	6902                	ld	s2,0(sp)
ffffffffc020327e:	6105                	addi	sp,sp,32
ffffffffc0203280:	8082                	ret
        assert(!checked_frames[i]);
ffffffffc0203282:	00004697          	auipc	a3,0x4
ffffffffc0203286:	54e68693          	addi	a3,a3,1358 # ffffffffc02077d0 <buddy_pmm_manager+0x4a8>
ffffffffc020328a:	00003617          	auipc	a2,0x3
ffffffffc020328e:	d2660613          	addi	a2,a2,-730 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203292:	12100593          	li	a1,289
ffffffffc0203296:	00004517          	auipc	a0,0x4
ffffffffc020329a:	30250513          	addi	a0,a0,770 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020329e:	f2dfc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(!PageReserved(pages + i) && !PageProperty(pages + i));
ffffffffc02032a2:	00003697          	auipc	a3,0x3
ffffffffc02032a6:	36668693          	addi	a3,a3,870 # ffffffffc0206608 <etext+0x8e0>
ffffffffc02032aa:	00003617          	auipc	a2,0x3
ffffffffc02032ae:	d0660613          	addi	a2,a2,-762 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02032b2:	12200593          	li	a1,290
ffffffffc02032b6:	00004517          	auipc	a0,0x4
ffffffffc02032ba:	2e250513          	addi	a0,a0,738 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02032be:	f0dfc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(slab->magic == SLUB_MAGIC);
ffffffffc02032c2:	00004697          	auipc	a3,0x4
ffffffffc02032c6:	43668693          	addi	a3,a3,1078 # ffffffffc02076f8 <buddy_pmm_manager+0x3d0>
ffffffffc02032ca:	00003617          	auipc	a2,0x3
ffffffffc02032ce:	ce660613          	addi	a2,a2,-794 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02032d2:	11b00593          	li	a1,283
ffffffffc02032d6:	00004517          	auipc	a0,0x4
ffffffffc02032da:	2c250513          	addi	a0,a0,706 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02032de:	eedfc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(slub_page_address(slab->page, slab->npages) == (void *)slab);
ffffffffc02032e2:	00004697          	auipc	a3,0x4
ffffffffc02032e6:	43668693          	addi	a3,a3,1078 # ffffffffc0207718 <buddy_pmm_manager+0x3f0>
ffffffffc02032ea:	00003617          	auipc	a2,0x3
ffffffffc02032ee:	cc660613          	addi	a2,a2,-826 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02032f2:	11c00593          	li	a1,284
ffffffffc02032f6:	00004517          	auipc	a0,0x4
ffffffffc02032fa:	2a250513          	addi	a0,a0,674 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02032fe:	ecdfc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(npage >= nbase && npage - nbase <= SLUB_FRAME_CAPACITY);
ffffffffc0203302:	00004697          	auipc	a3,0x4
ffffffffc0203306:	45668693          	addi	a3,a3,1110 # ffffffffc0207758 <buddy_pmm_manager+0x430>
ffffffffc020330a:	00003617          	auipc	a2,0x3
ffffffffc020330e:	ca660613          	addi	a2,a2,-858 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203312:	11e00593          	li	a1,286
ffffffffc0203316:	00004517          	auipc	a0,0x4
ffffffffc020331a:	28250513          	addi	a0,a0,642 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020331e:	eadfc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(index < npage - nbase && slab->npages <= npage - nbase - index);
ffffffffc0203322:	00004697          	auipc	a3,0x4
ffffffffc0203326:	46e68693          	addi	a3,a3,1134 # ffffffffc0207790 <buddy_pmm_manager+0x468>
ffffffffc020332a:	00003617          	auipc	a2,0x3
ffffffffc020332e:	c8660613          	addi	a2,a2,-890 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203332:	11f00593          	li	a1,287
ffffffffc0203336:	00004517          	auipc	a0,0x4
ffffffffc020333a:	26250513          	addi	a0,a0,610 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020333e:	e8dfc0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0203342 <slub_check_empty>:
    return list->next == list;
ffffffffc0203342:	00191797          	auipc	a5,0x191
ffffffffc0203346:	6de78793          	addi	a5,a5,1758 # ffffffffc0394a20 <large_objects>
    assert(large == large_count);
}

static void
slub_check_empty(void) {
    assert(list_empty(&large_objects) && large_count == 0);
ffffffffc020334a:	6798                	ld	a4,8(a5)
slub_check_empty(void) {
ffffffffc020334c:	1141                	addi	sp,sp,-16
ffffffffc020334e:	e406                	sd	ra,8(sp)
    assert(list_empty(&large_objects) && large_count == 0);
ffffffffc0203350:	08f71363          	bne	a4,a5,ffffffffc02033d6 <slub_check_empty+0x94>
ffffffffc0203354:	00192717          	auipc	a4,0x192
ffffffffc0203358:	73473703          	ld	a4,1844(a4) # ffffffffc0395a88 <large_count>
ffffffffc020335c:	00189797          	auipc	a5,0x189
ffffffffc0203360:	51c78793          	addi	a5,a5,1308 # ffffffffc038c878 <caches+0x18>
ffffffffc0203364:	00189617          	auipc	a2,0x189
ffffffffc0203368:	6d460613          	addi	a2,a2,1748 # ffffffffc038ca38 <checked_frames+0x18>
ffffffffc020336c:	e72d                	bnez	a4,ffffffffc02033d6 <slub_check_empty+0x94>
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
        assert(caches[i].slabs == 0 && caches[i].inuse == 0);
ffffffffc020336e:	6b98                	ld	a4,16(a5)
ffffffffc0203370:	e31d                	bnez	a4,ffffffffc0203396 <slub_check_empty+0x54>
ffffffffc0203372:	6f98                	ld	a4,24(a5)
ffffffffc0203374:	e30d                	bnez	a4,ffffffffc0203396 <slub_check_empty+0x54>
        assert(list_empty(&caches[i].partial) && list_empty(&caches[i].full));
ffffffffc0203376:	ff87b683          	ld	a3,-8(a5)
ffffffffc020337a:	ff078713          	addi	a4,a5,-16
ffffffffc020337e:	02e69c63          	bne	a3,a4,ffffffffc02033b6 <slub_check_empty+0x74>
ffffffffc0203382:	6798                	ld	a4,8(a5)
ffffffffc0203384:	02f71963          	bne	a4,a5,ffffffffc02033b6 <slub_check_empty+0x74>
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
ffffffffc0203388:	03878793          	addi	a5,a5,56
ffffffffc020338c:	fec791e3          	bne	a5,a2,ffffffffc020336e <slub_check_empty+0x2c>
    }
}
ffffffffc0203390:	60a2                	ld	ra,8(sp)
ffffffffc0203392:	0141                	addi	sp,sp,16
ffffffffc0203394:	8082                	ret
        assert(caches[i].slabs == 0 && caches[i].inuse == 0);
ffffffffc0203396:	00004697          	auipc	a3,0x4
ffffffffc020339a:	48268693          	addi	a3,a3,1154 # ffffffffc0207818 <buddy_pmm_manager+0x4f0>
ffffffffc020339e:	00003617          	auipc	a2,0x3
ffffffffc02033a2:	c1260613          	addi	a2,a2,-1006 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02033a6:	17d00593          	li	a1,381
ffffffffc02033aa:	00004517          	auipc	a0,0x4
ffffffffc02033ae:	1ee50513          	addi	a0,a0,494 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02033b2:	e19fc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(list_empty(&caches[i].partial) && list_empty(&caches[i].full));
ffffffffc02033b6:	00004697          	auipc	a3,0x4
ffffffffc02033ba:	49268693          	addi	a3,a3,1170 # ffffffffc0207848 <buddy_pmm_manager+0x520>
ffffffffc02033be:	00003617          	auipc	a2,0x3
ffffffffc02033c2:	bf260613          	addi	a2,a2,-1038 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02033c6:	17e00593          	li	a1,382
ffffffffc02033ca:	00004517          	auipc	a0,0x4
ffffffffc02033ce:	1ce50513          	addi	a0,a0,462 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02033d2:	df9fc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(list_empty(&large_objects) && large_count == 0);
ffffffffc02033d6:	00004697          	auipc	a3,0x4
ffffffffc02033da:	41268693          	addi	a3,a3,1042 # ffffffffc02077e8 <buddy_pmm_manager+0x4c0>
ffffffffc02033de:	00003617          	auipc	a2,0x3
ffffffffc02033e2:	bd260613          	addi	a2,a2,-1070 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02033e6:	17b00593          	li	a1,379
ffffffffc02033ea:	00004517          	auipc	a0,0x4
ffffffffc02033ee:	1ae50513          	addi	a0,a0,430 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02033f2:	dd9fc0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02033f6 <slub_check_invariants.part.0>:
slub_check_invariants(void) {
ffffffffc02033f6:	7161                	addi	sp,sp,-432
ffffffffc02033f8:	00189797          	auipc	a5,0x189
ffffffffc02033fc:	48078793          	addi	a5,a5,1152 # ffffffffc038c878 <caches+0x18>
ffffffffc0203400:	ef26                	sd	s1,408(sp)
ffffffffc0203402:	f706                	sd	ra,424(sp)
ffffffffc0203404:	f322                	sd	s0,416(sp)
ffffffffc0203406:	eb4a                	sd	s2,400(sp)
ffffffffc0203408:	e74e                	sd	s3,392(sp)
ffffffffc020340a:	e352                	sd	s4,384(sp)
ffffffffc020340c:	fed6                	sd	s5,376(sp)
ffffffffc020340e:	fada                	sd	s6,368(sp)
ffffffffc0203410:	f6de                	sd	s7,360(sp)
ffffffffc0203412:	f2e2                	sd	s8,352(sp)
ffffffffc0203414:	eee6                	sd	s9,344(sp)
ffffffffc0203416:	eaea                	sd	s10,336(sp)
ffffffffc0203418:	e6ee                	sd	s11,328(sp)
ffffffffc020341a:	e83e                	sd	a5,16(sp)
    size_t visited = 0;
ffffffffc020341c:	4481                	li	s1,0
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
ffffffffc020341e:	f802                	sd	zero,48(sp)
        assert(cache->object_size == ((size_t)SLUB_ALIGNMENT << i));
ffffffffc0203420:	67c2                	ld	a5,16(sp)
ffffffffc0203422:	76c2                	ld	a3,48(sp)
ffffffffc0203424:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203428:	47c1                	li	a5,16
ffffffffc020342a:	00d797b3          	sll	a5,a5,a3
ffffffffc020342e:	58f71f63          	bne	a4,a5,ffffffffc02039cc <slub_check_invariants.part.0+0x5d6>
ffffffffc0203432:	7742                	ld	a4,48(sp)
ffffffffc0203434:	00189d97          	auipc	s11,0x189
ffffffffc0203438:	42cd8d93          	addi	s11,s11,1068 # ffffffffc038c860 <caches>
        size_t slabs = 0, inuse = 0;
ffffffffc020343c:	e402                	sd	zero,8(sp)
ffffffffc020343e:	00371793          	slli	a5,a4,0x3
ffffffffc0203442:	8f99                	sub	a5,a5,a4
ffffffffc0203444:	6742                	ld	a4,16(sp)
ffffffffc0203446:	078e                	slli	a5,a5,0x3
ffffffffc0203448:	97ee                	add	a5,a5,s11
ffffffffc020344a:	1741                	addi	a4,a4,-16
ffffffffc020344c:	f03e                	sd	a5,32(sp)
ffffffffc020344e:	fc3a                	sd	a4,56(sp)
ffffffffc0203450:	4781                	li	a5,0
        for (size_t full = 0; full < 2; full++) {
ffffffffc0203452:	e002                	sd	zero,0(sp)
            list_entry_t *head = full ? &cache->full : &cache->partial;
ffffffffc0203454:	6742                	ld	a4,16(sp)
ffffffffc0203456:	ec3a                	sd	a4,24(sp)
ffffffffc0203458:	6702                	ld	a4,0(sp)
ffffffffc020345a:	e319                	bnez	a4,ffffffffc0203460 <slub_check_invariants.part.0+0x6a>
ffffffffc020345c:	7762                	ld	a4,56(sp)
ffffffffc020345e:	ec3a                	sd	a4,24(sp)
    return listelm->next;
ffffffffc0203460:	66e2                	ld	a3,24(sp)
ffffffffc0203462:	6298                	ld	a4,0(a3)
            assert(list_next(list_prev(head)) == head);
ffffffffc0203464:	6718                	ld	a4,8(a4)
ffffffffc0203466:	4ae69063          	bne	a3,a4,ffffffffc0203906 <slub_check_invariants.part.0+0x510>
ffffffffc020346a:	66e2                	ld	a3,24(sp)
ffffffffc020346c:	0086bd03          	ld	s10,8(a3)
            assert(list_prev(list_next(head)) == head);
ffffffffc0203470:	000d3703          	ld	a4,0(s10)
ffffffffc0203474:	46e69963          	bne	a3,a4,ffffffffc02038e6 <slub_check_invariants.part.0+0x4f0>
            for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
ffffffffc0203478:	1da68c63          	beq	a3,s10,ffffffffc0203650 <slub_check_invariants.part.0+0x25a>
                assert(++visited <= SLUB_FRAME_CAPACITY);
ffffffffc020347c:	00148a13          	addi	s4,s1,1
ffffffffc0203480:	6721                	lui	a4,0x8
ffffffffc0203482:	45476263          	bltu	a4,s4,ffffffffc02038c6 <slub_check_invariants.part.0+0x4d0>
ffffffffc0203486:	8f85                	sub	a5,a5,s1
    assert(slab->kind == SLUB_SMALL && slab->cache == cache && slab->npages == 1);
ffffffffc0203488:	4905                	li	s2,1
ffffffffc020348a:	f43e                	sd	a5,40(sp)
    return listelm->prev;
ffffffffc020348c:	008d3783          	ld	a5,8(s10)
                assert(list_prev(list_next(le)) == le);
ffffffffc0203490:	639c                	ld	a5,0(a5)
ffffffffc0203492:	41a79a63          	bne	a5,s10,ffffffffc02038a6 <slub_check_invariants.part.0+0x4b0>
                struct slub_slab *slab = to_struct(le, struct slub_slab, link);
ffffffffc0203496:	fe0d0413          	addi	s0,s10,-32
    slub_check_mark_pages(slab);
ffffffffc020349a:	8522                	mv	a0,s0
ffffffffc020349c:	d35ff0ef          	jal	ra,ffffffffc02031d0 <slub_check_mark_pages>
    assert(slab->kind == SLUB_SMALL && slab->cache == cache && slab->npages == 1);
ffffffffc02034a0:	fe8d3783          	ld	a5,-24(s10)
ffffffffc02034a4:	3f279163          	bne	a5,s2,ffffffffc0203886 <slub_check_invariants.part.0+0x490>
ffffffffc02034a8:	ff8d3c03          	ld	s8,-8(s10)
ffffffffc02034ac:	7782                	ld	a5,32(sp)
ffffffffc02034ae:	3cfc1c63          	bne	s8,a5,ffffffffc0203886 <slub_check_invariants.part.0+0x490>
ffffffffc02034b2:	010d3783          	ld	a5,16(s10)
ffffffffc02034b6:	3d279863          	bne	a5,s2,ffffffffc0203886 <slub_check_invariants.part.0+0x490>
    assert(slab->total == (PGSIZE - SLUB_DATA_OFFSET) / cache->object_size);
ffffffffc02034ba:	67c2                	ld	a5,16(sp)
ffffffffc02034bc:	020d3c83          	ld	s9,32(s10)
ffffffffc02034c0:	fe87b483          	ld	s1,-24(a5)
ffffffffc02034c4:	6785                	lui	a5,0x1
ffffffffc02034c6:	f8078793          	addi	a5,a5,-128 # f80 <kern_entry-0xffffffffc01ff080>
ffffffffc02034ca:	0297d7b3          	divu	a5,a5,s1
ffffffffc02034ce:	38fc9c63          	bne	s9,a5,ffffffffc0203866 <slub_check_invariants.part.0+0x470>
    assert(slab->total > 0 && slab->total <= SLUB_MAX_SLOTS);
ffffffffc02034d2:	fffc8793          	addi	a5,s9,-1
ffffffffc02034d6:	0ff00713          	li	a4,255
ffffffffc02034da:	36f76663          	bltu	a4,a5,ffffffffc0203846 <slub_check_invariants.part.0+0x450>
    assert(slab->inuse > 0 && slab->inuse <= slab->total);
ffffffffc02034de:	028d3983          	ld	s3,40(s10)
ffffffffc02034e2:	34098263          	beqz	s3,ffffffffc0203826 <slub_check_invariants.part.0+0x430>
ffffffffc02034e6:	353ce063          	bltu	s9,s3,ffffffffc0203826 <slub_check_invariants.part.0+0x430>
    assert(full ? slab->inuse == slab->total : slab->inuse < slab->total);
ffffffffc02034ea:	6782                	ld	a5,0(sp)
ffffffffc02034ec:	14078c63          	beqz	a5,ffffffffc0203644 <slub_check_invariants.part.0+0x24e>
ffffffffc02034f0:	413c87b3          	sub	a5,s9,s3
ffffffffc02034f4:	00f037b3          	snez	a5,a5
ffffffffc02034f8:	44079a63          	bnez	a5,ffffffffc020394c <slub_check_invariants.part.0+0x556>
    unsigned char seen[SLUB_MAX_SLOTS] = {0};
ffffffffc02034fc:	0f800613          	li	a2,248
ffffffffc0203500:	4581                	li	a1,0
ffffffffc0203502:	00a8                	addi	a0,sp,72
ffffffffc0203504:	e082                	sd	zero,64(sp)
ffffffffc0203506:	011020ef          	jal	ra,ffffffffc0205d16 <memset>
    void *object = slab->free_head;
ffffffffc020350a:	030d3a83          	ld	s5,48(s10)
    while (object != NULL) {
ffffffffc020350e:	220a8a63          	beqz	s5,ffffffffc0203742 <slub_check_invariants.part.0+0x34c>
ffffffffc0203512:	8b56                	mv	s6,s5
    size_t free_count = 0;
ffffffffc0203514:	4b81                	li	s7,0
ffffffffc0203516:	a011                	j	ffffffffc020351a <slub_check_invariants.part.0+0x124>
ffffffffc0203518:	8bbe                	mv	s7,a5
        size_t index = slub_object_index(slab, object);
ffffffffc020351a:	85da                	mv	a1,s6
ffffffffc020351c:	8522                	mv	a0,s0
ffffffffc020351e:	a71ff0ef          	jal	ra,ffffffffc0202f8e <slub_object_index>
        assert(!seen[index] && !slub_slot_allocated(slab, index));
ffffffffc0203522:	029c                	addi	a5,sp,320
ffffffffc0203524:	00a78733          	add	a4,a5,a0
ffffffffc0203528:	f0074783          	lbu	a5,-256(a4) # 7f00 <kern_entry-0xffffffffc01f8100>
ffffffffc020352c:	20079d63          	bnez	a5,ffffffffc0203746 <slub_check_invariants.part.0+0x350>
    return (slab->allocated[index / 64] >> (index % 64)) & 1;
ffffffffc0203530:	00655793          	srli	a5,a0,0x6
ffffffffc0203534:	07a9                	addi	a5,a5,10
ffffffffc0203536:	078e                	slli	a5,a5,0x3
ffffffffc0203538:	97ea                	add	a5,a5,s10
ffffffffc020353a:	fe87b783          	ld	a5,-24(a5)
ffffffffc020353e:	00a7d533          	srl	a0,a5,a0
        assert(!seen[index] && !slub_slot_allocated(slab, index));
ffffffffc0203542:	8905                	andi	a0,a0,1
ffffffffc0203544:	20051163          	bnez	a0,ffffffffc0203746 <slub_check_invariants.part.0+0x350>
        assert(++free_count <= slab->total);
ffffffffc0203548:	001b8793          	addi	a5,s7,1
ffffffffc020354c:	297c8d63          	beq	s9,s7,ffffffffc02037e6 <slub_check_invariants.part.0+0x3f0>
        object = *(void **)object;
ffffffffc0203550:	000b3b03          	ld	s6,0(s6)
        seen[index] = 1;
ffffffffc0203554:	f1270023          	sb	s2,-256(a4)
    while (object != NULL) {
ffffffffc0203558:	fc0b10e3          	bnez	s6,ffffffffc0203518 <slub_check_invariants.part.0+0x122>
    assert(free_count + slab->inuse == slab->total);
ffffffffc020355c:	97ce                	add	a5,a5,s3
ffffffffc020355e:	41979763          	bne	a5,s9,ffffffffc020396c <slub_check_invariants.part.0+0x576>
    assert(!full || slab->free_head == NULL);
ffffffffc0203562:	6782                	ld	a5,0(sp)
ffffffffc0203564:	c399                	beqz	a5,ffffffffc020356a <slub_check_invariants.part.0+0x174>
ffffffffc0203566:	440a9363          	bnez	s5,ffffffffc02039ac <slub_check_invariants.part.0+0x5b6>
        assert(address + cache->object_size <= (uintptr_t)slab + PGSIZE);
ffffffffc020356a:	6785                	lui	a5,0x1
ffffffffc020356c:	08040593          	addi	a1,s0,128
ffffffffc0203570:	0094                	addi	a3,sp,64
    while (object != NULL) {
ffffffffc0203572:	4601                	li	a2,0
ffffffffc0203574:	4701                	li	a4,0
        assert(address + cache->object_size <= (uintptr_t)slab + PGSIZE);
ffffffffc0203576:	943e                	add	s0,s0,a5
    for (size_t i = 0; i < SLUB_MAX_SLOTS; i++) {
ffffffffc0203578:	10000513          	li	a0,256
ffffffffc020357c:	a039                	j	ffffffffc020358a <slub_check_invariants.part.0+0x194>
            assert(!used);
ffffffffc020357e:	1e079463          	bnez	a5,ffffffffc0203766 <slub_check_invariants.part.0+0x370>
    for (size_t i = 0; i < SLUB_MAX_SLOTS; i++) {
ffffffffc0203582:	0705                	addi	a4,a4,1
ffffffffc0203584:	0685                	addi	a3,a3,1
ffffffffc0203586:	04a70763          	beq	a4,a0,ffffffffc02035d4 <slub_check_invariants.part.0+0x1de>
    return (slab->allocated[index / 64] >> (index % 64)) & 1;
ffffffffc020358a:	00675793          	srli	a5,a4,0x6
ffffffffc020358e:	07a9                	addi	a5,a5,10
ffffffffc0203590:	078e                	slli	a5,a5,0x3
ffffffffc0203592:	97ea                	add	a5,a5,s10
ffffffffc0203594:	fe87b783          	ld	a5,-24(a5) # fe8 <kern_entry-0xffffffffc01ff018>
ffffffffc0203598:	00e7d7b3          	srl	a5,a5,a4
ffffffffc020359c:	8b85                	andi	a5,a5,1
        if (i >= slab->total) {
ffffffffc020359e:	ff9770e3          	bgeu	a4,s9,ffffffffc020357e <slub_check_invariants.part.0+0x188>
                   index * slab->cache->object_size);
ffffffffc02035a2:	000c3803          	ld	a6,0(s8)
ffffffffc02035a6:	03070833          	mul	a6,a4,a6
    return (void *)((uintptr_t)slab + SLUB_DATA_OFFSET +
ffffffffc02035aa:	982e                	add	a6,a6,a1
        assert(address >= (uintptr_t)slab + SLUB_DATA_OFFSET);
ffffffffc02035ac:	1cb86d63          	bltu	a6,a1,ffffffffc0203786 <slub_check_invariants.part.0+0x390>
        assert(address + cache->object_size <= (uintptr_t)slab + PGSIZE);
ffffffffc02035b0:	010488b3          	add	a7,s1,a6
ffffffffc02035b4:	1f146963          	bltu	s0,a7,ffffffffc02037a6 <slub_check_invariants.part.0+0x3b0>
        assert((address & (SLUB_ALIGNMENT - 1)) == 0);
ffffffffc02035b8:	00f87813          	andi	a6,a6,15
ffffffffc02035bc:	20081563          	bnez	a6,ffffffffc02037c6 <slub_check_invariants.part.0+0x3d0>
        assert(used ? !seen[i] : seen[i]);
ffffffffc02035c0:	0006c803          	lbu	a6,0(a3)
ffffffffc02035c4:	cfb1                	beqz	a5,ffffffffc0203620 <slub_check_invariants.part.0+0x22a>
ffffffffc02035c6:	04081f63          	bnez	a6,ffffffffc0203624 <slub_check_invariants.part.0+0x22e>
    for (size_t i = 0; i < SLUB_MAX_SLOTS; i++) {
ffffffffc02035ca:	0705                	addi	a4,a4,1
        allocated += used;
ffffffffc02035cc:	963e                	add	a2,a2,a5
    for (size_t i = 0; i < SLUB_MAX_SLOTS; i++) {
ffffffffc02035ce:	0685                	addi	a3,a3,1
ffffffffc02035d0:	faa71de3          	bne	a4,a0,ffffffffc020358a <slub_check_invariants.part.0+0x194>
    assert(allocated == slab->inuse);
ffffffffc02035d4:	3ac99c63          	bne	s3,a2,ffffffffc020398c <slub_check_invariants.part.0+0x596>
                inuse += slab->inuse;
ffffffffc02035d8:	6722                	ld	a4,8(sp)
ffffffffc02035da:	77a2                	ld	a5,40(sp)
    return listelm->next;
ffffffffc02035dc:	008d3d03          	ld	s10,8(s10)
ffffffffc02035e0:	974e                	add	a4,a4,s3
ffffffffc02035e2:	e43a                	sd	a4,8(sp)
            for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
ffffffffc02035e4:	6762                	ld	a4,24(sp)
ffffffffc02035e6:	97d2                	add	a5,a5,s4
ffffffffc02035e8:	07a70363          	beq	a4,s10,ffffffffc020364e <slub_check_invariants.part.0+0x258>
                assert(++visited <= SLUB_FRAME_CAPACITY);
ffffffffc02035ec:	67a1                	lui	a5,0x8
ffffffffc02035ee:	0a05                	addi	s4,s4,1
ffffffffc02035f0:	0785                	addi	a5,a5,1
ffffffffc02035f2:	2cfa0a63          	beq	s4,a5,ffffffffc02038c6 <slub_check_invariants.part.0+0x4d0>
ffffffffc02035f6:	000d3783          	ld	a5,0(s10)
                assert(list_next(list_prev(le)) == le);
ffffffffc02035fa:	679c                	ld	a5,8(a5)
ffffffffc02035fc:	e9a788e3          	beq	a5,s10,ffffffffc020348c <slub_check_invariants.part.0+0x96>
ffffffffc0203600:	00003697          	auipc	a3,0x3
ffffffffc0203604:	b2868693          	addi	a3,a3,-1240 # ffffffffc0206128 <etext+0x400>
ffffffffc0203608:	00003617          	auipc	a2,0x3
ffffffffc020360c:	9a860613          	addi	a2,a2,-1624 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203610:	15b00593          	li	a1,347
ffffffffc0203614:	00004517          	auipc	a0,0x4
ffffffffc0203618:	f8450513          	addi	a0,a0,-124 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020361c:	baffc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(used ? !seen[i] : seen[i]);
ffffffffc0203620:	fa0815e3          	bnez	a6,ffffffffc02035ca <slub_check_invariants.part.0+0x1d4>
ffffffffc0203624:	00004697          	auipc	a3,0x4
ffffffffc0203628:	53c68693          	addi	a3,a3,1340 # ffffffffc0207b60 <buddy_pmm_manager+0x838>
ffffffffc020362c:	00003617          	auipc	a2,0x3
ffffffffc0203630:	98460613          	addi	a2,a2,-1660 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203634:	14600593          	li	a1,326
ffffffffc0203638:	00004517          	auipc	a0,0x4
ffffffffc020363c:	f6050513          	addi	a0,a0,-160 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203640:	b8bfc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(full ? slab->inuse == slab->total : slab->inuse < slab->total);
ffffffffc0203644:	413c87b3          	sub	a5,s9,s3
ffffffffc0203648:	0017b793          	seqz	a5,a5
ffffffffc020364c:	b575                	j	ffffffffc02034f8 <slub_check_invariants.part.0+0x102>
ffffffffc020364e:	84d2                	mv	s1,s4
        for (size_t full = 0; full < 2; full++) {
ffffffffc0203650:	6702                	ld	a4,0(sp)
ffffffffc0203652:	2e070a63          	beqz	a4,ffffffffc0203946 <slub_check_invariants.part.0+0x550>
        assert(slabs == cache->slabs && inuse == cache->inuse);
ffffffffc0203656:	66c2                	ld	a3,16(sp)
ffffffffc0203658:	6a98                	ld	a4,16(a3)
ffffffffc020365a:	2cf71663          	bne	a4,a5,ffffffffc0203926 <slub_check_invariants.part.0+0x530>
ffffffffc020365e:	6e9c                	ld	a5,24(a3)
ffffffffc0203660:	6722                	ld	a4,8(sp)
ffffffffc0203662:	2cf71263          	bne	a4,a5,ffffffffc0203926 <slub_check_invariants.part.0+0x530>
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
ffffffffc0203666:	77c2                	ld	a5,48(sp)
ffffffffc0203668:	66c2                	ld	a3,16(sp)
ffffffffc020366a:	00178713          	addi	a4,a5,1 # 8001 <kern_entry-0xffffffffc01f7fff>
ffffffffc020366e:	03868693          	addi	a3,a3,56
ffffffffc0203672:	f83a                	sd	a4,48(sp)
ffffffffc0203674:	47a1                	li	a5,8
ffffffffc0203676:	e836                	sd	a3,16(sp)
ffffffffc0203678:	daf714e3          	bne	a4,a5,ffffffffc0203420 <slub_check_invariants.part.0+0x2a>
    return listelm->prev;
ffffffffc020367c:	00191917          	auipc	s2,0x191
ffffffffc0203680:	3a490913          	addi	s2,s2,932 # ffffffffc0394a20 <large_objects>
    return listelm->next;
ffffffffc0203684:	00093783          	ld	a5,0(s2)
    assert(list_next(list_prev(&large_objects)) == &large_objects);
ffffffffc0203688:	679c                	ld	a5,8(a5)
ffffffffc020368a:	17279e63          	bne	a5,s2,ffffffffc0203806 <slub_check_invariants.part.0+0x410>
ffffffffc020368e:	00893403          	ld	s0,8(s2)
    assert(list_prev(list_next(&large_objects)) == &large_objects);
ffffffffc0203692:	601c                	ld	a5,0(s0)
ffffffffc0203694:	47279e63          	bne	a5,s2,ffffffffc0203b10 <slub_check_invariants.part.0+0x71a>
    for (list_entry_t *le = list_next(&large_objects); le != &large_objects;
ffffffffc0203698:	47240a63          	beq	s0,s2,ffffffffc0203b0c <slub_check_invariants.part.0+0x716>
        assert(++visited <= SLUB_FRAME_CAPACITY);
ffffffffc020369c:	67a1                	lui	a5,0x8
ffffffffc020369e:	00148713          	addi	a4,s1,1
    size_t large = 0;
ffffffffc02036a2:	4b01                	li	s6,0
ffffffffc02036a4:	409784b3          	sub	s1,a5,s1
        assert(++visited <= SLUB_FRAME_CAPACITY);
ffffffffc02036a8:	44e7e263          	bltu	a5,a4,ffffffffc0203aec <slub_check_invariants.part.0+0x6f6>
        assert(slab->kind == SLUB_LARGE && slab->cache == NULL && slab->inuse == 1);
ffffffffc02036ac:	4a89                	li	s5,2
ffffffffc02036ae:	4a05                	li	s4,1
        assert(slab->requested <= ~(size_t)0 - SLUB_DATA_OFFSET);
ffffffffc02036b0:	f7f00993          	li	s3,-129
ffffffffc02036b4:	a039                	j	ffffffffc02036c2 <slub_check_invariants.part.0+0x2cc>
        assert(++visited <= SLUB_FRAME_CAPACITY);
ffffffffc02036b6:	429b0b63          	beq	s6,s1,ffffffffc0203aec <slub_check_invariants.part.0+0x6f6>
ffffffffc02036ba:	601c                	ld	a5,0(s0)
        assert(list_next(list_prev(le)) == le);
ffffffffc02036bc:	679c                	ld	a5,8(a5)
ffffffffc02036be:	34879763          	bne	a5,s0,ffffffffc0203a0c <slub_check_invariants.part.0+0x616>
    return listelm->prev;
ffffffffc02036c2:	641c                	ld	a5,8(s0)
        assert(list_prev(list_next(le)) == le);
ffffffffc02036c4:	639c                	ld	a5,0(a5)
ffffffffc02036c6:	40879363          	bne	a5,s0,ffffffffc0203acc <slub_check_invariants.part.0+0x6d6>
        slub_check_mark_pages(slab);
ffffffffc02036ca:	fe040513          	addi	a0,s0,-32
ffffffffc02036ce:	b03ff0ef          	jal	ra,ffffffffc02031d0 <slub_check_mark_pages>
        assert(slab->kind == SLUB_LARGE && slab->cache == NULL && slab->inuse == 1);
ffffffffc02036d2:	fe843783          	ld	a5,-24(s0)
ffffffffc02036d6:	3d579b63          	bne	a5,s5,ffffffffc0203aac <slub_check_invariants.part.0+0x6b6>
ffffffffc02036da:	ff843783          	ld	a5,-8(s0)
ffffffffc02036de:	3c079763          	bnez	a5,ffffffffc0203aac <slub_check_invariants.part.0+0x6b6>
ffffffffc02036e2:	741c                	ld	a5,40(s0)
ffffffffc02036e4:	3d479463          	bne	a5,s4,ffffffffc0203aac <slub_check_invariants.part.0+0x6b6>
        assert(slab->requested > caches[SLUB_CLASSES - 1].object_size);
ffffffffc02036e8:	6c14                	ld	a3,24(s0)
ffffffffc02036ea:	188db783          	ld	a5,392(s11)
ffffffffc02036ee:	38d7ff63          	bgeu	a5,a3,ffffffffc0203a8c <slub_check_invariants.part.0+0x696>
        assert(slab->requested <= ~(size_t)0 - SLUB_DATA_OFFSET);
ffffffffc02036f2:	36d9ed63          	bltu	s3,a3,ffffffffc0203a6c <slub_check_invariants.part.0+0x676>
        assert(slab->npages == (slab->requested + SLUB_DATA_OFFSET - 1) / PGSIZE + 1);
ffffffffc02036f6:	07f68793          	addi	a5,a3,127
ffffffffc02036fa:	6818                	ld	a4,16(s0)
ffffffffc02036fc:	83b1                	srli	a5,a5,0xc
ffffffffc02036fe:	0785                	addi	a5,a5,1
ffffffffc0203700:	34f71663          	bne	a4,a5,ffffffffc0203a4c <slub_check_invariants.part.0+0x656>
        assert(slab->requested <= slab->npages * PGSIZE - SLUB_DATA_OFFSET);
ffffffffc0203704:	00c71793          	slli	a5,a4,0xc
ffffffffc0203708:	f8078793          	addi	a5,a5,-128 # 7f80 <kern_entry-0xffffffffc01f8080>
ffffffffc020370c:	32d7e063          	bltu	a5,a3,ffffffffc0203a2c <slub_check_invariants.part.0+0x636>
    return listelm->next;
ffffffffc0203710:	6400                	ld	s0,8(s0)
        large++;
ffffffffc0203712:	0b05                	addi	s6,s6,1
    for (list_entry_t *le = list_next(&large_objects); le != &large_objects;
ffffffffc0203714:	fb2411e3          	bne	s0,s2,ffffffffc02036b6 <slub_check_invariants.part.0+0x2c0>
    assert(large == large_count);
ffffffffc0203718:	00192797          	auipc	a5,0x192
ffffffffc020371c:	3707b783          	ld	a5,880(a5) # ffffffffc0395a88 <large_count>
ffffffffc0203720:	2d679663          	bne	a5,s6,ffffffffc02039ec <slub_check_invariants.part.0+0x5f6>
}
ffffffffc0203724:	70ba                	ld	ra,424(sp)
ffffffffc0203726:	741a                	ld	s0,416(sp)
ffffffffc0203728:	64fa                	ld	s1,408(sp)
ffffffffc020372a:	695a                	ld	s2,400(sp)
ffffffffc020372c:	69ba                	ld	s3,392(sp)
ffffffffc020372e:	6a1a                	ld	s4,384(sp)
ffffffffc0203730:	7af6                	ld	s5,376(sp)
ffffffffc0203732:	7b56                	ld	s6,368(sp)
ffffffffc0203734:	7bb6                	ld	s7,360(sp)
ffffffffc0203736:	7c16                	ld	s8,352(sp)
ffffffffc0203738:	6cf6                	ld	s9,344(sp)
ffffffffc020373a:	6d56                	ld	s10,336(sp)
ffffffffc020373c:	6db6                	ld	s11,328(sp)
ffffffffc020373e:	615d                	addi	sp,sp,432
ffffffffc0203740:	8082                	ret
    while (object != NULL) {
ffffffffc0203742:	87ce                	mv	a5,s3
ffffffffc0203744:	bd29                	j	ffffffffc020355e <slub_check_invariants.part.0+0x168>
        assert(!seen[index] && !slub_slot_allocated(slab, index));
ffffffffc0203746:	00004697          	auipc	a3,0x4
ffffffffc020374a:	2d268693          	addi	a3,a3,722 # ffffffffc0207a18 <buddy_pmm_manager+0x6f0>
ffffffffc020374e:	00003617          	auipc	a2,0x3
ffffffffc0203752:	86260613          	addi	a2,a2,-1950 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203756:	13400593          	li	a1,308
ffffffffc020375a:	00004517          	auipc	a0,0x4
ffffffffc020375e:	e3e50513          	addi	a0,a0,-450 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203762:	a69fc0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(!used);
ffffffffc0203766:	00004697          	auipc	a3,0x4
ffffffffc020376a:	35a68693          	addi	a3,a3,858 # ffffffffc0207ac0 <buddy_pmm_manager+0x798>
ffffffffc020376e:	00003617          	auipc	a2,0x3
ffffffffc0203772:	84260613          	addi	a2,a2,-1982 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203776:	13f00593          	li	a1,319
ffffffffc020377a:	00004517          	auipc	a0,0x4
ffffffffc020377e:	e1e50513          	addi	a0,a0,-482 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203782:	a49fc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(address >= (uintptr_t)slab + SLUB_DATA_OFFSET);
ffffffffc0203786:	00004697          	auipc	a3,0x4
ffffffffc020378a:	34268693          	addi	a3,a3,834 # ffffffffc0207ac8 <buddy_pmm_manager+0x7a0>
ffffffffc020378e:	00003617          	auipc	a2,0x3
ffffffffc0203792:	82260613          	addi	a2,a2,-2014 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203796:	14300593          	li	a1,323
ffffffffc020379a:	00004517          	auipc	a0,0x4
ffffffffc020379e:	dfe50513          	addi	a0,a0,-514 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02037a2:	a29fc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(address + cache->object_size <= (uintptr_t)slab + PGSIZE);
ffffffffc02037a6:	00004697          	auipc	a3,0x4
ffffffffc02037aa:	35268693          	addi	a3,a3,850 # ffffffffc0207af8 <buddy_pmm_manager+0x7d0>
ffffffffc02037ae:	00003617          	auipc	a2,0x3
ffffffffc02037b2:	80260613          	addi	a2,a2,-2046 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02037b6:	14400593          	li	a1,324
ffffffffc02037ba:	00004517          	auipc	a0,0x4
ffffffffc02037be:	dde50513          	addi	a0,a0,-546 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02037c2:	a09fc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert((address & (SLUB_ALIGNMENT - 1)) == 0);
ffffffffc02037c6:	00004697          	auipc	a3,0x4
ffffffffc02037ca:	37268693          	addi	a3,a3,882 # ffffffffc0207b38 <buddy_pmm_manager+0x810>
ffffffffc02037ce:	00002617          	auipc	a2,0x2
ffffffffc02037d2:	7e260613          	addi	a2,a2,2018 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02037d6:	14500593          	li	a1,325
ffffffffc02037da:	00004517          	auipc	a0,0x4
ffffffffc02037de:	dbe50513          	addi	a0,a0,-578 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02037e2:	9e9fc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(++free_count <= slab->total);
ffffffffc02037e6:	00004697          	auipc	a3,0x4
ffffffffc02037ea:	26a68693          	addi	a3,a3,618 # ffffffffc0207a50 <buddy_pmm_manager+0x728>
ffffffffc02037ee:	00002617          	auipc	a2,0x2
ffffffffc02037f2:	7c260613          	addi	a2,a2,1986 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02037f6:	13500593          	li	a1,309
ffffffffc02037fa:	00004517          	auipc	a0,0x4
ffffffffc02037fe:	d9e50513          	addi	a0,a0,-610 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203802:	9c9fc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(list_next(list_prev(&large_objects)) == &large_objects);
ffffffffc0203806:	00004697          	auipc	a3,0x4
ffffffffc020380a:	3ca68693          	addi	a3,a3,970 # ffffffffc0207bd0 <buddy_pmm_manager+0x8a8>
ffffffffc020380e:	00002617          	auipc	a2,0x2
ffffffffc0203812:	7a260613          	addi	a2,a2,1954 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203816:	16600593          	li	a1,358
ffffffffc020381a:	00004517          	auipc	a0,0x4
ffffffffc020381e:	d7e50513          	addi	a0,a0,-642 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203822:	9a9fc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(slab->inuse > 0 && slab->inuse <= slab->total);
ffffffffc0203826:	00004697          	auipc	a3,0x4
ffffffffc020382a:	18268693          	addi	a3,a3,386 # ffffffffc02079a8 <buddy_pmm_manager+0x680>
ffffffffc020382e:	00002617          	auipc	a2,0x2
ffffffffc0203832:	78260613          	addi	a2,a2,1922 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203836:	12d00593          	li	a1,301
ffffffffc020383a:	00004517          	auipc	a0,0x4
ffffffffc020383e:	d5e50513          	addi	a0,a0,-674 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203842:	989fc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(slab->total > 0 && slab->total <= SLUB_MAX_SLOTS);
ffffffffc0203846:	00004697          	auipc	a3,0x4
ffffffffc020384a:	12a68693          	addi	a3,a3,298 # ffffffffc0207970 <buddy_pmm_manager+0x648>
ffffffffc020384e:	00002617          	auipc	a2,0x2
ffffffffc0203852:	76260613          	addi	a2,a2,1890 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203856:	12c00593          	li	a1,300
ffffffffc020385a:	00004517          	auipc	a0,0x4
ffffffffc020385e:	d3e50513          	addi	a0,a0,-706 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203862:	969fc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(slab->total == (PGSIZE - SLUB_DATA_OFFSET) / cache->object_size);
ffffffffc0203866:	00004697          	auipc	a3,0x4
ffffffffc020386a:	0ca68693          	addi	a3,a3,202 # ffffffffc0207930 <buddy_pmm_manager+0x608>
ffffffffc020386e:	00002617          	auipc	a2,0x2
ffffffffc0203872:	74260613          	addi	a2,a2,1858 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203876:	12b00593          	li	a1,299
ffffffffc020387a:	00004517          	auipc	a0,0x4
ffffffffc020387e:	d1e50513          	addi	a0,a0,-738 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203882:	949fc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(slab->kind == SLUB_SMALL && slab->cache == cache && slab->npages == 1);
ffffffffc0203886:	00004697          	auipc	a3,0x4
ffffffffc020388a:	06268693          	addi	a3,a3,98 # ffffffffc02078e8 <buddy_pmm_manager+0x5c0>
ffffffffc020388e:	00002617          	auipc	a2,0x2
ffffffffc0203892:	72260613          	addi	a2,a2,1826 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203896:	12a00593          	li	a1,298
ffffffffc020389a:	00004517          	auipc	a0,0x4
ffffffffc020389e:	cfe50513          	addi	a0,a0,-770 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02038a2:	929fc0ef          	jal	ra,ffffffffc02001ca <__panic>
                assert(list_prev(list_next(le)) == le);
ffffffffc02038a6:	00003697          	auipc	a3,0x3
ffffffffc02038aa:	8a268693          	addi	a3,a3,-1886 # ffffffffc0206148 <etext+0x420>
ffffffffc02038ae:	00002617          	auipc	a2,0x2
ffffffffc02038b2:	70260613          	addi	a2,a2,1794 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02038b6:	15c00593          	li	a1,348
ffffffffc02038ba:	00004517          	auipc	a0,0x4
ffffffffc02038be:	cde50513          	addi	a0,a0,-802 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02038c2:	909fc0ef          	jal	ra,ffffffffc02001ca <__panic>
                assert(++visited <= SLUB_FRAME_CAPACITY);
ffffffffc02038c6:	00004697          	auipc	a3,0x4
ffffffffc02038ca:	ffa68693          	addi	a3,a3,-6 # ffffffffc02078c0 <buddy_pmm_manager+0x598>
ffffffffc02038ce:	00002617          	auipc	a2,0x2
ffffffffc02038d2:	6e260613          	addi	a2,a2,1762 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02038d6:	15a00593          	li	a1,346
ffffffffc02038da:	00004517          	auipc	a0,0x4
ffffffffc02038de:	cbe50513          	addi	a0,a0,-834 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02038e2:	8e9fc0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(list_prev(list_next(head)) == head);
ffffffffc02038e6:	00002697          	auipc	a3,0x2
ffffffffc02038ea:	7ea68693          	addi	a3,a3,2026 # ffffffffc02060d0 <etext+0x3a8>
ffffffffc02038ee:	00002617          	auipc	a2,0x2
ffffffffc02038f2:	6c260613          	addi	a2,a2,1730 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02038f6:	15800593          	li	a1,344
ffffffffc02038fa:	00004517          	auipc	a0,0x4
ffffffffc02038fe:	c9e50513          	addi	a0,a0,-866 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203902:	8c9fc0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(list_next(list_prev(head)) == head);
ffffffffc0203906:	00002697          	auipc	a3,0x2
ffffffffc020390a:	7a268693          	addi	a3,a3,1954 # ffffffffc02060a8 <etext+0x380>
ffffffffc020390e:	00002617          	auipc	a2,0x2
ffffffffc0203912:	6a260613          	addi	a2,a2,1698 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203916:	15700593          	li	a1,343
ffffffffc020391a:	00004517          	auipc	a0,0x4
ffffffffc020391e:	c7e50513          	addi	a0,a0,-898 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203922:	8a9fc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(slabs == cache->slabs && inuse == cache->inuse);
ffffffffc0203926:	00004697          	auipc	a3,0x4
ffffffffc020392a:	27a68693          	addi	a3,a3,634 # ffffffffc0207ba0 <buddy_pmm_manager+0x878>
ffffffffc020392e:	00002617          	auipc	a2,0x2
ffffffffc0203932:	68260613          	addi	a2,a2,1666 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203936:	16300593          	li	a1,355
ffffffffc020393a:	00004517          	auipc	a0,0x4
ffffffffc020393e:	c5e50513          	addi	a0,a0,-930 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203942:	889fc0ef          	jal	ra,ffffffffc02001ca <__panic>
ffffffffc0203946:	4705                	li	a4,1
ffffffffc0203948:	e03a                	sd	a4,0(sp)
ffffffffc020394a:	b629                	j	ffffffffc0203454 <slub_check_invariants.part.0+0x5e>
    assert(full ? slab->inuse == slab->total : slab->inuse < slab->total);
ffffffffc020394c:	00004697          	auipc	a3,0x4
ffffffffc0203950:	08c68693          	addi	a3,a3,140 # ffffffffc02079d8 <buddy_pmm_manager+0x6b0>
ffffffffc0203954:	00002617          	auipc	a2,0x2
ffffffffc0203958:	65c60613          	addi	a2,a2,1628 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020395c:	12e00593          	li	a1,302
ffffffffc0203960:	00004517          	auipc	a0,0x4
ffffffffc0203964:	c3850513          	addi	a0,a0,-968 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203968:	863fc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(free_count + slab->inuse == slab->total);
ffffffffc020396c:	00004697          	auipc	a3,0x4
ffffffffc0203970:	10468693          	addi	a3,a3,260 # ffffffffc0207a70 <buddy_pmm_manager+0x748>
ffffffffc0203974:	00002617          	auipc	a2,0x2
ffffffffc0203978:	63c60613          	addi	a2,a2,1596 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020397c:	13900593          	li	a1,313
ffffffffc0203980:	00004517          	auipc	a0,0x4
ffffffffc0203984:	c1850513          	addi	a0,a0,-1000 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203988:	843fc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(allocated == slab->inuse);
ffffffffc020398c:	00004697          	auipc	a3,0x4
ffffffffc0203990:	1f468693          	addi	a3,a3,500 # ffffffffc0207b80 <buddy_pmm_manager+0x858>
ffffffffc0203994:	00002617          	auipc	a2,0x2
ffffffffc0203998:	61c60613          	addi	a2,a2,1564 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020399c:	14900593          	li	a1,329
ffffffffc02039a0:	00004517          	auipc	a0,0x4
ffffffffc02039a4:	bf850513          	addi	a0,a0,-1032 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02039a8:	823fc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(!full || slab->free_head == NULL);
ffffffffc02039ac:	00004697          	auipc	a3,0x4
ffffffffc02039b0:	0ec68693          	addi	a3,a3,236 # ffffffffc0207a98 <buddy_pmm_manager+0x770>
ffffffffc02039b4:	00002617          	auipc	a2,0x2
ffffffffc02039b8:	5fc60613          	addi	a2,a2,1532 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02039bc:	13a00593          	li	a1,314
ffffffffc02039c0:	00004517          	auipc	a0,0x4
ffffffffc02039c4:	bd850513          	addi	a0,a0,-1064 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02039c8:	803fc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(cache->object_size == ((size_t)SLUB_ALIGNMENT << i));
ffffffffc02039cc:	00004697          	auipc	a3,0x4
ffffffffc02039d0:	ebc68693          	addi	a3,a3,-324 # ffffffffc0207888 <buddy_pmm_manager+0x560>
ffffffffc02039d4:	00002617          	auipc	a2,0x2
ffffffffc02039d8:	5dc60613          	addi	a2,a2,1500 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02039dc:	15300593          	li	a1,339
ffffffffc02039e0:	00004517          	auipc	a0,0x4
ffffffffc02039e4:	bb850513          	addi	a0,a0,-1096 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02039e8:	fe2fc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(large == large_count);
ffffffffc02039ec:	00004697          	auipc	a3,0x4
ffffffffc02039f0:	39468693          	addi	a3,a3,916 # ffffffffc0207d80 <buddy_pmm_manager+0xa58>
ffffffffc02039f4:	00002617          	auipc	a2,0x2
ffffffffc02039f8:	5bc60613          	addi	a2,a2,1468 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02039fc:	17600593          	li	a1,374
ffffffffc0203a00:	00004517          	auipc	a0,0x4
ffffffffc0203a04:	b9850513          	addi	a0,a0,-1128 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203a08:	fc2fc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(list_next(list_prev(le)) == le);
ffffffffc0203a0c:	00002697          	auipc	a3,0x2
ffffffffc0203a10:	71c68693          	addi	a3,a3,1820 # ffffffffc0206128 <etext+0x400>
ffffffffc0203a14:	00002617          	auipc	a2,0x2
ffffffffc0203a18:	59c60613          	addi	a2,a2,1436 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203a1c:	16b00593          	li	a1,363
ffffffffc0203a20:	00004517          	auipc	a0,0x4
ffffffffc0203a24:	b7850513          	addi	a0,a0,-1160 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203a28:	fa2fc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(slab->requested <= slab->npages * PGSIZE - SLUB_DATA_OFFSET);
ffffffffc0203a2c:	00004697          	auipc	a3,0x4
ffffffffc0203a30:	31468693          	addi	a3,a3,788 # ffffffffc0207d40 <buddy_pmm_manager+0xa18>
ffffffffc0203a34:	00002617          	auipc	a2,0x2
ffffffffc0203a38:	57c60613          	addi	a2,a2,1404 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203a3c:	17300593          	li	a1,371
ffffffffc0203a40:	00004517          	auipc	a0,0x4
ffffffffc0203a44:	b5850513          	addi	a0,a0,-1192 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203a48:	f82fc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(slab->npages == (slab->requested + SLUB_DATA_OFFSET - 1) / PGSIZE + 1);
ffffffffc0203a4c:	00004697          	auipc	a3,0x4
ffffffffc0203a50:	2ac68693          	addi	a3,a3,684 # ffffffffc0207cf8 <buddy_pmm_manager+0x9d0>
ffffffffc0203a54:	00002617          	auipc	a2,0x2
ffffffffc0203a58:	55c60613          	addi	a2,a2,1372 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203a5c:	17200593          	li	a1,370
ffffffffc0203a60:	00004517          	auipc	a0,0x4
ffffffffc0203a64:	b3850513          	addi	a0,a0,-1224 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203a68:	f62fc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(slab->requested <= ~(size_t)0 - SLUB_DATA_OFFSET);
ffffffffc0203a6c:	00004697          	auipc	a3,0x4
ffffffffc0203a70:	25468693          	addi	a3,a3,596 # ffffffffc0207cc0 <buddy_pmm_manager+0x998>
ffffffffc0203a74:	00002617          	auipc	a2,0x2
ffffffffc0203a78:	53c60613          	addi	a2,a2,1340 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203a7c:	17100593          	li	a1,369
ffffffffc0203a80:	00004517          	auipc	a0,0x4
ffffffffc0203a84:	b1850513          	addi	a0,a0,-1256 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203a88:	f42fc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(slab->requested > caches[SLUB_CLASSES - 1].object_size);
ffffffffc0203a8c:	00004697          	auipc	a3,0x4
ffffffffc0203a90:	1fc68693          	addi	a3,a3,508 # ffffffffc0207c88 <buddy_pmm_manager+0x960>
ffffffffc0203a94:	00002617          	auipc	a2,0x2
ffffffffc0203a98:	51c60613          	addi	a2,a2,1308 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203a9c:	17000593          	li	a1,368
ffffffffc0203aa0:	00004517          	auipc	a0,0x4
ffffffffc0203aa4:	af850513          	addi	a0,a0,-1288 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203aa8:	f22fc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(slab->kind == SLUB_LARGE && slab->cache == NULL && slab->inuse == 1);
ffffffffc0203aac:	00004697          	auipc	a3,0x4
ffffffffc0203ab0:	19468693          	addi	a3,a3,404 # ffffffffc0207c40 <buddy_pmm_manager+0x918>
ffffffffc0203ab4:	00002617          	auipc	a2,0x2
ffffffffc0203ab8:	4fc60613          	addi	a2,a2,1276 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203abc:	16f00593          	li	a1,367
ffffffffc0203ac0:	00004517          	auipc	a0,0x4
ffffffffc0203ac4:	ad850513          	addi	a0,a0,-1320 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203ac8:	f02fc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(list_prev(list_next(le)) == le);
ffffffffc0203acc:	00002697          	auipc	a3,0x2
ffffffffc0203ad0:	67c68693          	addi	a3,a3,1660 # ffffffffc0206148 <etext+0x420>
ffffffffc0203ad4:	00002617          	auipc	a2,0x2
ffffffffc0203ad8:	4dc60613          	addi	a2,a2,1244 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203adc:	16c00593          	li	a1,364
ffffffffc0203ae0:	00004517          	auipc	a0,0x4
ffffffffc0203ae4:	ab850513          	addi	a0,a0,-1352 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203ae8:	ee2fc0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(++visited <= SLUB_FRAME_CAPACITY);
ffffffffc0203aec:	00004697          	auipc	a3,0x4
ffffffffc0203af0:	dd468693          	addi	a3,a3,-556 # ffffffffc02078c0 <buddy_pmm_manager+0x598>
ffffffffc0203af4:	00002617          	auipc	a2,0x2
ffffffffc0203af8:	4bc60613          	addi	a2,a2,1212 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203afc:	16a00593          	li	a1,362
ffffffffc0203b00:	00004517          	auipc	a0,0x4
ffffffffc0203b04:	a9850513          	addi	a0,a0,-1384 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203b08:	ec2fc0ef          	jal	ra,ffffffffc02001ca <__panic>
    size_t large = 0;
ffffffffc0203b0c:	4b01                	li	s6,0
ffffffffc0203b0e:	b129                	j	ffffffffc0203718 <slub_check_invariants.part.0+0x322>
    assert(list_prev(list_next(&large_objects)) == &large_objects);
ffffffffc0203b10:	00004697          	auipc	a3,0x4
ffffffffc0203b14:	0f868693          	addi	a3,a3,248 # ffffffffc0207c08 <buddy_pmm_manager+0x8e0>
ffffffffc0203b18:	00002617          	auipc	a2,0x2
ffffffffc0203b1c:	49860613          	addi	a2,a2,1176 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203b20:	16700593          	li	a1,359
ffffffffc0203b24:	00004517          	auipc	a0,0x4
ffffffffc0203b28:	a7450513          	addi	a0,a0,-1420 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203b2c:	e9efc0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0203b30 <slub_alloc.part.0>:
slub_alloc(size_t size) {
ffffffffc0203b30:	715d                	addi	sp,sp,-80
ffffffffc0203b32:	f44e                	sd	s3,40(sp)
ffffffffc0203b34:	00189997          	auipc	s3,0x189
ffffffffc0203b38:	d2c98993          	addi	s3,s3,-724 # ffffffffc038c860 <caches>
ffffffffc0203b3c:	e0a2                	sd	s0,64(sp)
ffffffffc0203b3e:	f84a                	sd	s2,48(sp)
ffffffffc0203b40:	e486                	sd	ra,72(sp)
ffffffffc0203b42:	fc26                	sd	s1,56(sp)
ffffffffc0203b44:	f052                	sd	s4,32(sp)
ffffffffc0203b46:	ec56                	sd	s5,24(sp)
ffffffffc0203b48:	e85a                	sd	s6,16(sp)
ffffffffc0203b4a:	e45e                	sd	s7,8(sp)
ffffffffc0203b4c:	892a                	mv	s2,a0
ffffffffc0203b4e:	87ce                	mv	a5,s3
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
ffffffffc0203b50:	4401                	li	s0,0
ffffffffc0203b52:	46a1                	li	a3,8
        if (size <= caches[i].object_size) {
ffffffffc0203b54:	6398                	ld	a4,0(a5)
ffffffffc0203b56:	0b277063          	bgeu	a4,s2,ffffffffc0203bf6 <slub_alloc.part.0+0xc6>
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
ffffffffc0203b5a:	0405                	addi	s0,s0,1
ffffffffc0203b5c:	03878793          	addi	a5,a5,56
ffffffffc0203b60:	fed41ae3          	bne	s0,a3,ffffffffc0203b54 <slub_alloc.part.0+0x24>
    if (size > ~(size_t)0 - SLUB_DATA_OFFSET) {
ffffffffc0203b64:	f7f00793          	li	a5,-129
ffffffffc0203b68:	1327e263          	bltu	a5,s2,ffffffffc0203c8c <slub_alloc.part.0+0x15c>
    size_t npages = (bytes - 1) / PGSIZE + 1;
ffffffffc0203b6c:	07f90413          	addi	s0,s2,127
ffffffffc0203b70:	8031                	srli	s0,s0,0xc
    if (npage < nbase || npages > npage - nbase) {
ffffffffc0203b72:	00192797          	auipc	a5,0x192
ffffffffc0203b76:	ede7b783          	ld	a5,-290(a5) # ffffffffc0395a50 <npage>
ffffffffc0203b7a:	00005717          	auipc	a4,0x5
ffffffffc0203b7e:	e7673703          	ld	a4,-394(a4) # ffffffffc02089f0 <nbase>
    size_t npages = (bytes - 1) / PGSIZE + 1;
ffffffffc0203b82:	0405                	addi	s0,s0,1
    if (npage < nbase || npages > npage - nbase) {
ffffffffc0203b84:	10e7e463          	bltu	a5,a4,ffffffffc0203c8c <slub_alloc.part.0+0x15c>
ffffffffc0203b88:	8f99                	sub	a5,a5,a4
ffffffffc0203b8a:	1087e163          	bltu	a5,s0,ffffffffc0203c8c <slub_alloc.part.0+0x15c>
    struct Page *page = alloc_pages(npages);
ffffffffc0203b8e:	8522                	mv	a0,s0
ffffffffc0203b90:	900ff0ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc0203b94:	89aa                	mv	s3,a0
    if (page == NULL) {
ffffffffc0203b96:	0e050b63          	beqz	a0,ffffffffc0203c8c <slub_alloc.part.0+0x15c>
    struct slub_slab *slab = slub_page_address(page, npages);
ffffffffc0203b9a:	85a2                	mv	a1,s0
ffffffffc0203b9c:	b92ff0ef          	jal	ra,ffffffffc0202f2e <slub_page_address>
ffffffffc0203ba0:	84aa                	mv	s1,a0
    if (slab == NULL) {
ffffffffc0203ba2:	1e050363          	beqz	a0,ffffffffc0203d88 <slub_alloc.part.0+0x258>
    memset(slab, 0, sizeof(*slab));
ffffffffc0203ba6:	07800613          	li	a2,120
ffffffffc0203baa:	4581                	li	a1,0
ffffffffc0203bac:	16a020ef          	jal	ra,ffffffffc0205d16 <memset>
    __list_add(elm, listelm, listelm->next);
ffffffffc0203bb0:	00191717          	auipc	a4,0x191
ffffffffc0203bb4:	e7070713          	addi	a4,a4,-400 # ffffffffc0394a20 <large_objects>
    large_count++;
ffffffffc0203bb8:	00192697          	auipc	a3,0x192
ffffffffc0203bbc:	ed068693          	addi	a3,a3,-304 # ffffffffc0395a88 <large_count>
ffffffffc0203bc0:	670c                	ld	a1,8(a4)
ffffffffc0203bc2:	629c                	ld	a5,0(a3)
    slab->magic = SLUB_MAGIC;
ffffffffc0203bc4:	00005617          	auipc	a2,0x5
ffffffffc0203bc8:	e2463603          	ld	a2,-476(a2) # ffffffffc02089e8 <error_string+0x40>
ffffffffc0203bcc:	e090                	sd	a2,0(s1)
    slab->inuse = 1;
ffffffffc0203bce:	4505                	li	a0,1
    slab->kind = SLUB_LARGE;
ffffffffc0203bd0:	4609                	li	a2,2
ffffffffc0203bd2:	e490                	sd	a2,8(s1)
    slab->page = page;
ffffffffc0203bd4:	0134b823          	sd	s3,16(s1)
    list_add(&large_objects, &slab->link);
ffffffffc0203bd8:	02048613          	addi	a2,s1,32
    slab->npages = npages;
ffffffffc0203bdc:	f880                	sd	s0,48(s1)
    slab->requested = size;
ffffffffc0203bde:	0324bc23          	sd	s2,56(s1)
    slab->inuse = 1;
ffffffffc0203be2:	e4a8                	sd	a0,72(s1)
    prev->next = next->prev = elm;
ffffffffc0203be4:	e190                	sd	a2,0(a1)
    large_count++;
ffffffffc0203be6:	0785                	addi	a5,a5,1
    elm->next = next;
ffffffffc0203be8:	f48c                	sd	a1,40(s1)
    elm->prev = prev;
ffffffffc0203bea:	f098                	sd	a4,32(s1)
    prev->next = next->prev = elm;
ffffffffc0203bec:	e710                	sd	a2,8(a4)
ffffffffc0203bee:	e29c                	sd	a5,0(a3)
    return (void *)((uintptr_t)slab + SLUB_DATA_OFFSET);
ffffffffc0203bf0:	08048493          	addi	s1,s1,128
ffffffffc0203bf4:	a8a5                	j	ffffffffc0203c6c <slub_alloc.part.0+0x13c>
        struct slub_cache *cache = &caches[index];
ffffffffc0203bf6:	00341b13          	slli	s6,s0,0x3
    return list->next == list;
ffffffffc0203bfa:	408b07b3          	sub	a5,s6,s0
ffffffffc0203bfe:	078e                	slli	a5,a5,0x3
ffffffffc0203c00:	00f98bb3          	add	s7,s3,a5
ffffffffc0203c04:	010bba03          	ld	s4,16(s7)
        if (list_empty(&cache->partial)) {
ffffffffc0203c08:	07a1                	addi	a5,a5,8
ffffffffc0203c0a:	97ce                	add	a5,a5,s3
ffffffffc0203c0c:	0afa0663          	beq	s4,a5,ffffffffc0203cb8 <slub_alloc.part.0+0x188>
    assert(slab->inuse < slab->total && slab->free_head != NULL);
ffffffffc0203c10:	028a3403          	ld	s0,40(s4) # fffffffffff80028 <end+0x3fbea598>
ffffffffc0203c14:	020a3a83          	ld	s5,32(s4)
            slab = to_struct(list_next(&cache->partial), struct slub_slab, link);
ffffffffc0203c18:	fe0a0913          	addi	s2,s4,-32
    assert(slab->inuse < slab->total && slab->free_head != NULL);
ffffffffc0203c1c:	15547663          	bgeu	s0,s5,ffffffffc0203d68 <slub_alloc.part.0+0x238>
ffffffffc0203c20:	030a3483          	ld	s1,48(s4)
ffffffffc0203c24:	14048263          	beqz	s1,ffffffffc0203d68 <slub_alloc.part.0+0x238>
    size_t index = slub_object_index(slab, object);
ffffffffc0203c28:	85a6                	mv	a1,s1
ffffffffc0203c2a:	854a                	mv	a0,s2
ffffffffc0203c2c:	b62ff0ef          	jal	ra,ffffffffc0202f8e <slub_object_index>
    return (slab->allocated[index / 64] >> (index % 64)) & 1;
ffffffffc0203c30:	00655793          	srli	a5,a0,0x6
ffffffffc0203c34:	078e                	slli	a5,a5,0x3
ffffffffc0203c36:	97ca                	add	a5,a5,s2
ffffffffc0203c38:	6fb4                	ld	a3,88(a5)
ffffffffc0203c3a:	03f57513          	andi	a0,a0,63
ffffffffc0203c3e:	00a6d733          	srl	a4,a3,a0
    assert(!slub_slot_allocated(slab, index));
ffffffffc0203c42:	8b05                	andi	a4,a4,1
ffffffffc0203c44:	16071763          	bnez	a4,ffffffffc0203db2 <slub_alloc.part.0+0x282>
    slab->free_head = *(void **)object;
ffffffffc0203c48:	6090                	ld	a2,0(s1)
    slab->allocated[index / 64] |= (uint64_t)1 << (index % 64);
ffffffffc0203c4a:	4705                	li	a4,1
ffffffffc0203c4c:	00a71533          	sll	a0,a4,a0
    slab->free_head = *(void **)object;
ffffffffc0203c50:	04c93823          	sd	a2,80(s2)
    slab->allocated[index / 64] |= (uint64_t)1 << (index % 64);
ffffffffc0203c54:	8d55                	or	a0,a0,a3
ffffffffc0203c56:	efa8                	sd	a0,88(a5)
    slab->cache->inuse++;
ffffffffc0203c58:	01893783          	ld	a5,24(s2)
    slab->inuse++;
ffffffffc0203c5c:	0405                	addi	s0,s0,1
ffffffffc0203c5e:	04893423          	sd	s0,72(s2)
    slab->cache->inuse++;
ffffffffc0203c62:	7b98                	ld	a4,48(a5)
ffffffffc0203c64:	0705                	addi	a4,a4,1
ffffffffc0203c66:	fb98                	sd	a4,48(a5)
    if (slab->inuse == slab->total) {
ffffffffc0203c68:	028a8463          	beq	s5,s0,ffffffffc0203c90 <slub_alloc.part.0+0x160>
}
ffffffffc0203c6c:	60a6                	ld	ra,72(sp)
ffffffffc0203c6e:	6406                	ld	s0,64(sp)
ffffffffc0203c70:	7942                	ld	s2,48(sp)
ffffffffc0203c72:	79a2                	ld	s3,40(sp)
ffffffffc0203c74:	7a02                	ld	s4,32(sp)
ffffffffc0203c76:	6ae2                	ld	s5,24(sp)
ffffffffc0203c78:	6b42                	ld	s6,16(sp)
ffffffffc0203c7a:	6ba2                	ld	s7,8(sp)
ffffffffc0203c7c:	8526                	mv	a0,s1
ffffffffc0203c7e:	74e2                	ld	s1,56(sp)
ffffffffc0203c80:	6161                	addi	sp,sp,80
ffffffffc0203c82:	8082                	ret
        free_page(page);
ffffffffc0203c84:	4585                	li	a1,1
ffffffffc0203c86:	8526                	mv	a0,s1
ffffffffc0203c88:	814ff0ef          	jal	ra,ffffffffc0202c9c <free_pages>
                return NULL;
ffffffffc0203c8c:	4481                	li	s1,0
ffffffffc0203c8e:	bff9                	j	ffffffffc0203c6c <slub_alloc.part.0+0x13c>
        assert(slab->free_head == NULL);
ffffffffc0203c90:	10061163          	bnez	a2,ffffffffc0203d92 <slub_alloc.part.0+0x262>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203c94:	02093583          	ld	a1,32(s2)
ffffffffc0203c98:	02893603          	ld	a2,40(s2)
        list_add(&slab->cache->full, &slab->link);
ffffffffc0203c9c:	02090693          	addi	a3,s2,32
ffffffffc0203ca0:	01878513          	addi	a0,a5,24
    prev->next = next;
ffffffffc0203ca4:	e590                	sd	a2,8(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0203ca6:	7398                	ld	a4,32(a5)
    next->prev = prev;
ffffffffc0203ca8:	e20c                	sd	a1,0(a2)
    prev->next = next->prev = elm;
ffffffffc0203caa:	e314                	sd	a3,0(a4)
ffffffffc0203cac:	f394                	sd	a3,32(a5)
    elm->next = next;
ffffffffc0203cae:	02e93423          	sd	a4,40(s2)
    elm->prev = prev;
ffffffffc0203cb2:	02a93023          	sd	a0,32(s2)
}
ffffffffc0203cb6:	bf5d                	j	ffffffffc0203c6c <slub_alloc.part.0+0x13c>
    struct Page *page = alloc_page();
ffffffffc0203cb8:	4505                	li	a0,1
ffffffffc0203cba:	fd7fe0ef          	jal	ra,ffffffffc0202c90 <alloc_pages>
ffffffffc0203cbe:	84aa                	mv	s1,a0
    if (page == NULL) {
ffffffffc0203cc0:	d571                	beqz	a0,ffffffffc0203c8c <slub_alloc.part.0+0x15c>
    struct slub_slab *slab = slub_page_address(page, 1);
ffffffffc0203cc2:	4585                	li	a1,1
ffffffffc0203cc4:	a6aff0ef          	jal	ra,ffffffffc0202f2e <slub_page_address>
ffffffffc0203cc8:	892a                	mv	s2,a0
    if (slab == NULL) {
ffffffffc0203cca:	dd4d                	beqz	a0,ffffffffc0203c84 <slub_alloc.part.0+0x154>
    memset(slab, 0, sizeof(*slab));
ffffffffc0203ccc:	07800613          	li	a2,120
ffffffffc0203cd0:	4581                	li	a1,0
ffffffffc0203cd2:	044020ef          	jal	ra,ffffffffc0205d16 <memset>
    slab->total = (PGSIZE - SLUB_DATA_OFFSET) / cache->object_size;
ffffffffc0203cd6:	000bb783          	ld	a5,0(s7)
ffffffffc0203cda:	6a85                	lui	s5,0x1
ffffffffc0203cdc:	f80a8a93          	addi	s5,s5,-128 # f80 <kern_entry-0xffffffffc01ff080>
ffffffffc0203ce0:	02fadab3          	divu	s5,s5,a5
    slab->magic = SLUB_MAGIC;
ffffffffc0203ce4:	00005717          	auipc	a4,0x5
ffffffffc0203ce8:	d0473703          	ld	a4,-764(a4) # ffffffffc02089e8 <error_string+0x40>
    slab->kind = SLUB_SMALL;
ffffffffc0203cec:	4785                	li	a5,1
    slab->magic = SLUB_MAGIC;
ffffffffc0203cee:	00e93023          	sd	a4,0(s2)
    slab->kind = SLUB_SMALL;
ffffffffc0203cf2:	00f93423          	sd	a5,8(s2)
    slab->npages = 1;
ffffffffc0203cf6:	02f93823          	sd	a5,48(s2)
    slab->page = page;
ffffffffc0203cfa:	00993823          	sd	s1,16(s2)
    slab->cache = cache;
ffffffffc0203cfe:	01793c23          	sd	s7,24(s2)
    assert(slab->total > 0 && slab->total <= SLUB_MAX_SLOTS);
ffffffffc0203d02:	0ff00793          	li	a5,255
    slab->total = (PGSIZE - SLUB_DATA_OFFSET) / cache->object_size;
ffffffffc0203d06:	05593023          	sd	s5,64(s2)
    assert(slab->total > 0 && slab->total <= SLUB_MAX_SLOTS);
ffffffffc0203d0a:	fffa8713          	addi	a4,s5,-1
ffffffffc0203d0e:	0ce7e263          	bltu	a5,a4,ffffffffc0203dd2 <slub_alloc.part.0+0x2a2>
        *(void **)object = slab->free_head;
ffffffffc0203d12:	05093683          	ld	a3,80(s2)
ffffffffc0203d16:	08090613          	addi	a2,s2,128
        struct slub_cache *cache = &caches[index];
ffffffffc0203d1a:	875e                	mv	a4,s7
        *(void **)object = slab->free_head;
ffffffffc0203d1c:	87d6                	mv	a5,s5
ffffffffc0203d1e:	a021                	j	ffffffffc0203d26 <slub_alloc.part.0+0x1f6>
                   index * slab->cache->object_size);
ffffffffc0203d20:	01893703          	ld	a4,24(s2)
ffffffffc0203d24:	86a6                	mv	a3,s1
ffffffffc0203d26:	6304                	ld	s1,0(a4)
        void *object = slub_object_at(slab, i - 1);
ffffffffc0203d28:	17fd                	addi	a5,a5,-1
                   index * slab->cache->object_size);
ffffffffc0203d2a:	029784b3          	mul	s1,a5,s1
    return (void *)((uintptr_t)slab + SLUB_DATA_OFFSET +
ffffffffc0203d2e:	94b2                	add	s1,s1,a2
        *(void **)object = slab->free_head;
ffffffffc0203d30:	e094                	sd	a3,0(s1)
        slab->free_head = object;
ffffffffc0203d32:	04993823          	sd	s1,80(s2)
    for (size_t i = slab->total; i > 0; i--) {
ffffffffc0203d36:	f7ed                	bnez	a5,ffffffffc0203d20 <slub_alloc.part.0+0x1f0>
    __list_add(elm, listelm, listelm->next);
ffffffffc0203d38:	010bb703          	ld	a4,16(s7)
    list_add(&cache->partial, &slab->link);
ffffffffc0203d3c:	02090793          	addi	a5,s2,32
    cache->slabs++;
ffffffffc0203d40:	408b0433          	sub	s0,s6,s0
    prev->next = next->prev = elm;
ffffffffc0203d44:	e31c                	sd	a5,0(a4)
ffffffffc0203d46:	00fbb823          	sd	a5,16(s7)
ffffffffc0203d4a:	040e                	slli	s0,s0,0x3
ffffffffc0203d4c:	99a2                	add	s3,s3,s0
    elm->next = next;
ffffffffc0203d4e:	02e93423          	sd	a4,40(s2)
    elm->prev = prev;
ffffffffc0203d52:	03493023          	sd	s4,32(s2)
ffffffffc0203d56:	0289b783          	ld	a5,40(s3)
    assert(slab->inuse < slab->total && slab->free_head != NULL);
ffffffffc0203d5a:	04893403          	ld	s0,72(s2)
    cache->slabs++;
ffffffffc0203d5e:	0785                	addi	a5,a5,1
ffffffffc0203d60:	02f9b423          	sd	a5,40(s3)
    assert(slab->inuse < slab->total && slab->free_head != NULL);
ffffffffc0203d64:	ed5462e3          	bltu	s0,s5,ffffffffc0203c28 <slub_alloc.part.0+0xf8>
ffffffffc0203d68:	00004697          	auipc	a3,0x4
ffffffffc0203d6c:	03068693          	addi	a3,a3,48 # ffffffffc0207d98 <buddy_pmm_manager+0xa70>
ffffffffc0203d70:	00002617          	auipc	a2,0x2
ffffffffc0203d74:	24060613          	addi	a2,a2,576 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203d78:	0a800593          	li	a1,168
ffffffffc0203d7c:	00004517          	auipc	a0,0x4
ffffffffc0203d80:	81c50513          	addi	a0,a0,-2020 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203d84:	c46fc0ef          	jal	ra,ffffffffc02001ca <__panic>
        free_pages(page, npages);
ffffffffc0203d88:	85a2                	mv	a1,s0
ffffffffc0203d8a:	854e                	mv	a0,s3
ffffffffc0203d8c:	f11fe0ef          	jal	ra,ffffffffc0202c9c <free_pages>
        return NULL;
ffffffffc0203d90:	bdf1                	j	ffffffffc0203c6c <slub_alloc.part.0+0x13c>
        assert(slab->free_head == NULL);
ffffffffc0203d92:	00004697          	auipc	a3,0x4
ffffffffc0203d96:	03e68693          	addi	a3,a3,62 # ffffffffc0207dd0 <buddy_pmm_manager+0xaa8>
ffffffffc0203d9a:	00002617          	auipc	a2,0x2
ffffffffc0203d9e:	21660613          	addi	a2,a2,534 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203da2:	0b100593          	li	a1,177
ffffffffc0203da6:	00003517          	auipc	a0,0x3
ffffffffc0203daa:	7f250513          	addi	a0,a0,2034 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203dae:	c1cfc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(!slub_slot_allocated(slab, index));
ffffffffc0203db2:	00004697          	auipc	a3,0x4
ffffffffc0203db6:	c7668693          	addi	a3,a3,-906 # ffffffffc0207a28 <buddy_pmm_manager+0x700>
ffffffffc0203dba:	00002617          	auipc	a2,0x2
ffffffffc0203dbe:	1f660613          	addi	a2,a2,502 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203dc2:	0ab00593          	li	a1,171
ffffffffc0203dc6:	00003517          	auipc	a0,0x3
ffffffffc0203dca:	7d250513          	addi	a0,a0,2002 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203dce:	bfcfc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(slab->total > 0 && slab->total <= SLUB_MAX_SLOTS);
ffffffffc0203dd2:	00004697          	auipc	a3,0x4
ffffffffc0203dd6:	b9e68693          	addi	a3,a3,-1122 # ffffffffc0207970 <buddy_pmm_manager+0x648>
ffffffffc0203dda:	00002617          	auipc	a2,0x2
ffffffffc0203dde:	1d660613          	addi	a2,a2,470 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203de2:	09b00593          	li	a1,155
ffffffffc0203de6:	00003517          	auipc	a0,0x3
ffffffffc0203dea:	7b250513          	addi	a0,a0,1970 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203dee:	bdcfc0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0203df2 <slub_free.part.0>:
slub_free(void *ptr) {
ffffffffc0203df2:	1101                	addi	sp,sp,-32
ffffffffc0203df4:	e822                	sd	s0,16(sp)
ffffffffc0203df6:	e426                	sd	s1,8(sp)
ffffffffc0203df8:	ec06                	sd	ra,24(sp)
ffffffffc0203dfa:	84aa                	mv	s1,a0
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0203dfc:	a1cff0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    if (slab->kind == SLUB_LARGE) {
ffffffffc0203e00:	6518                	ld	a4,8(a0)
ffffffffc0203e02:	4789                	li	a5,2
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0203e04:	842a                	mv	s0,a0
    if (slab->kind == SLUB_LARGE) {
ffffffffc0203e06:	08f70763          	beq	a4,a5,ffffffffc0203e94 <slub_free.part.0+0xa2>
    size_t index = slub_object_index(slab, ptr);
ffffffffc0203e0a:	85a6                	mv	a1,s1
ffffffffc0203e0c:	982ff0ef          	jal	ra,ffffffffc0202f8e <slub_object_index>
    slab->allocated[index / 64] &= ~((uint64_t)1 << (index % 64));
ffffffffc0203e10:	00655793          	srli	a5,a0,0x6
ffffffffc0203e14:	078e                	slli	a5,a5,0x3
ffffffffc0203e16:	97a2                	add	a5,a5,s0
ffffffffc0203e18:	6fb4                	ld	a3,88(a5)
ffffffffc0203e1a:	4705                	li	a4,1
ffffffffc0203e1c:	00a71533          	sll	a0,a4,a0
ffffffffc0203e20:	fff54513          	not	a0,a0
    struct slub_cache *cache = slab->cache;
ffffffffc0203e24:	6c18                	ld	a4,24(s0)
    slab->allocated[index / 64] &= ~((uint64_t)1 << (index % 64));
ffffffffc0203e26:	8d75                	and	a0,a0,a3
    bool was_full = slab->inuse == slab->total;
ffffffffc0203e28:	6430                	ld	a2,72(s0)
ffffffffc0203e2a:	602c                	ld	a1,64(s0)
    slab->allocated[index / 64] &= ~((uint64_t)1 << (index % 64));
ffffffffc0203e2c:	efa8                	sd	a0,88(a5)
    *(void **)ptr = slab->free_head;
ffffffffc0203e2e:	6828                	ld	a0,80(s0)
    cache->inuse--;
ffffffffc0203e30:	7b1c                	ld	a5,48(a4)
    slab->inuse--;
ffffffffc0203e32:	fff60693          	addi	a3,a2,-1
    *(void **)ptr = slab->free_head;
ffffffffc0203e36:	e088                	sd	a0,0(s1)
    slab->free_head = ptr;
ffffffffc0203e38:	e824                	sd	s1,80(s0)
    slab->inuse--;
ffffffffc0203e3a:	e434                	sd	a3,72(s0)
    cache->inuse--;
ffffffffc0203e3c:	17fd                	addi	a5,a5,-1
ffffffffc0203e3e:	fb1c                	sd	a5,48(a4)
    if (was_full) {
ffffffffc0203e40:	00b60863          	beq	a2,a1,ffffffffc0203e50 <slub_free.part.0+0x5e>
    if (slab->inuse == 0) {
ffffffffc0203e44:	c69d                	beqz	a3,ffffffffc0203e72 <slub_free.part.0+0x80>
}
ffffffffc0203e46:	60e2                	ld	ra,24(sp)
ffffffffc0203e48:	6442                	ld	s0,16(sp)
ffffffffc0203e4a:	64a2                	ld	s1,8(sp)
ffffffffc0203e4c:	6105                	addi	sp,sp,32
ffffffffc0203e4e:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0203e50:	02043803          	ld	a6,32(s0)
ffffffffc0203e54:	7408                	ld	a0,40(s0)
        list_add(&cache->partial, &slab->link);
ffffffffc0203e56:	02040793          	addi	a5,s0,32
ffffffffc0203e5a:	00870613          	addi	a2,a4,8
    prev->next = next;
ffffffffc0203e5e:	00a83423          	sd	a0,8(a6)
    __list_add(elm, listelm, listelm->next);
ffffffffc0203e62:	6b0c                	ld	a1,16(a4)
    next->prev = prev;
ffffffffc0203e64:	01053023          	sd	a6,0(a0)
    prev->next = next->prev = elm;
ffffffffc0203e68:	e19c                	sd	a5,0(a1)
ffffffffc0203e6a:	eb1c                	sd	a5,16(a4)
    elm->next = next;
ffffffffc0203e6c:	f40c                	sd	a1,40(s0)
    elm->prev = prev;
ffffffffc0203e6e:	f010                	sd	a2,32(s0)
    if (slab->inuse == 0) {
ffffffffc0203e70:	faf9                	bnez	a3,ffffffffc0203e46 <slub_free.part.0+0x54>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203e72:	7010                	ld	a2,32(s0)
ffffffffc0203e74:	7414                	ld	a3,40(s0)
        cache->slabs--;
ffffffffc0203e76:	771c                	ld	a5,40(a4)
        struct Page *page = slab->page;
ffffffffc0203e78:	6808                	ld	a0,16(s0)
    prev->next = next;
ffffffffc0203e7a:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0203e7c:	e290                	sd	a2,0(a3)
        cache->slabs--;
ffffffffc0203e7e:	17fd                	addi	a5,a5,-1
ffffffffc0203e80:	f71c                	sd	a5,40(a4)
        slab->magic = 0;
ffffffffc0203e82:	00043023          	sd	zero,0(s0)
}
ffffffffc0203e86:	6442                	ld	s0,16(sp)
ffffffffc0203e88:	60e2                	ld	ra,24(sp)
ffffffffc0203e8a:	64a2                	ld	s1,8(sp)
        free_page(page);
ffffffffc0203e8c:	4585                	li	a1,1
}
ffffffffc0203e8e:	6105                	addi	sp,sp,32
        free_page(page);
ffffffffc0203e90:	e0dfe06f          	j	ffffffffc0202c9c <free_pages>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203e94:	7110                	ld	a2,32(a0)
ffffffffc0203e96:	7514                	ld	a3,40(a0)
        large_count--;
ffffffffc0203e98:	00192717          	auipc	a4,0x192
ffffffffc0203e9c:	bf070713          	addi	a4,a4,-1040 # ffffffffc0395a88 <large_count>
        struct Page *page = slab->page;
ffffffffc0203ea0:	6908                	ld	a0,16(a0)
        size_t npages = slab->npages;
ffffffffc0203ea2:	780c                	ld	a1,48(s0)
        large_count--;
ffffffffc0203ea4:	631c                	ld	a5,0(a4)
    prev->next = next;
ffffffffc0203ea6:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0203ea8:	e290                	sd	a2,0(a3)
        slab->magic = 0;
ffffffffc0203eaa:	00043023          	sd	zero,0(s0)
}
ffffffffc0203eae:	6442                	ld	s0,16(sp)
ffffffffc0203eb0:	60e2                	ld	ra,24(sp)
ffffffffc0203eb2:	64a2                	ld	s1,8(sp)
        large_count--;
ffffffffc0203eb4:	17fd                	addi	a5,a5,-1
ffffffffc0203eb6:	e31c                	sd	a5,0(a4)
}
ffffffffc0203eb8:	6105                	addi	sp,sp,32
        free_page(page);
ffffffffc0203eba:	de3fe06f          	j	ffffffffc0202c9c <free_pages>

ffffffffc0203ebe <slub_test_fill>:
slub_test_pattern(size_t index, unsigned char seed) {
    return (unsigned char)(seed + index * 37);
}

static void
slub_test_fill(void *ptr, size_t size, unsigned char seed) {
ffffffffc0203ebe:	1101                	addi	sp,sp,-32
ffffffffc0203ec0:	ec06                	sd	ra,24(sp)
ffffffffc0203ec2:	e822                	sd	s0,16(sp)
ffffffffc0203ec4:	e426                	sd	s1,8(sp)
ffffffffc0203ec6:	e04a                	sd	s2,0(sp)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0203ec8:	c521                	beqz	a0,ffffffffc0203f10 <slub_test_fill+0x52>
ffffffffc0203eca:	84aa                	mv	s1,a0
ffffffffc0203ecc:	892e                	mv	s2,a1
ffffffffc0203ece:	8432                	mv	s0,a2
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0203ed0:	948ff0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0203ed4:	6518                	ld	a4,8(a0)
ffffffffc0203ed6:	4785                	li	a5,1
ffffffffc0203ed8:	02f70963          	beq	a4,a5,ffffffffc0203f0a <slub_test_fill+0x4c>
ffffffffc0203edc:	7d1c                	ld	a5,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0203ede:	0327e963          	bltu	a5,s2,ffffffffc0203f10 <slub_test_fill+0x52>
    unsigned char *bytes = ptr;
    for (size_t i = 0; i < size; i++) {
ffffffffc0203ee2:	8526                	mv	a0,s1
ffffffffc0203ee4:	012487b3          	add	a5,s1,s2
ffffffffc0203ee8:	00090b63          	beqz	s2,ffffffffc0203efe <slub_test_fill+0x40>
        bytes[i] = slub_test_pattern(i, seed);
ffffffffc0203eec:	00850023          	sb	s0,0(a0)
    for (size_t i = 0; i < size; i++) {
ffffffffc0203ef0:	0254041b          	addiw	s0,s0,37
ffffffffc0203ef4:	0505                	addi	a0,a0,1
ffffffffc0203ef6:	0ff47413          	zext.b	s0,s0
ffffffffc0203efa:	fea799e3          	bne	a5,a0,ffffffffc0203eec <slub_test_fill+0x2e>
    }
}
ffffffffc0203efe:	60e2                	ld	ra,24(sp)
ffffffffc0203f00:	6442                	ld	s0,16(sp)
ffffffffc0203f02:	64a2                	ld	s1,8(sp)
ffffffffc0203f04:	6902                	ld	s2,0(sp)
ffffffffc0203f06:	6105                	addi	sp,sp,32
ffffffffc0203f08:	8082                	ret
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0203f0a:	6d1c                	ld	a5,24(a0)
ffffffffc0203f0c:	639c                	ld	a5,0(a5)
ffffffffc0203f0e:	bfc1                	j	ffffffffc0203ede <slub_test_fill+0x20>
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0203f10:	00004697          	auipc	a3,0x4
ffffffffc0203f14:	ed868693          	addi	a3,a3,-296 # ffffffffc0207de8 <buddy_pmm_manager+0xac0>
ffffffffc0203f18:	00002617          	auipc	a2,0x2
ffffffffc0203f1c:	09860613          	addi	a2,a2,152 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203f20:	18900593          	li	a1,393
ffffffffc0203f24:	00003517          	auipc	a0,0x3
ffffffffc0203f28:	67450513          	addi	a0,a0,1652 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203f2c:	a9efc0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0203f30 <slub_test_disjoint>:
        assert(bytes[i] == slub_test_pattern(i, seed));
    }
}

static void
slub_test_disjoint(void *a, void *b) {
ffffffffc0203f30:	1101                	addi	sp,sp,-32
ffffffffc0203f32:	ec06                	sd	ra,24(sp)
ffffffffc0203f34:	e822                	sd	s0,16(sp)
ffffffffc0203f36:	e426                	sd	s1,8(sp)
    uintptr_t start_a = (uintptr_t)a, start_b = (uintptr_t)b;
    assert(a != NULL && b != NULL);
ffffffffc0203f38:	c535                	beqz	a0,ffffffffc0203fa4 <slub_test_disjoint+0x74>
ffffffffc0203f3a:	842e                	mv	s0,a1
ffffffffc0203f3c:	c5a5                	beqz	a1,ffffffffc0203fa4 <slub_test_disjoint+0x74>
ffffffffc0203f3e:	84aa                	mv	s1,a0
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0203f40:	8d8ff0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0203f44:	6518                	ld	a4,8(a0)
ffffffffc0203f46:	4785                	li	a5,1
ffffffffc0203f48:	00f70b63          	beq	a4,a5,ffffffffc0203f5e <slub_test_disjoint+0x2e>
ffffffffc0203f4c:	7d1c                	ld	a5,56(a0)
    assert(start_a + slub_usable_size(a) <= start_b ||
ffffffffc0203f4e:	97a6                	add	a5,a5,s1
ffffffffc0203f50:	00f46c63          	bltu	s0,a5,ffffffffc0203f68 <slub_test_disjoint+0x38>
           start_b + slub_usable_size(b) <= start_a);
}
ffffffffc0203f54:	60e2                	ld	ra,24(sp)
ffffffffc0203f56:	6442                	ld	s0,16(sp)
ffffffffc0203f58:	64a2                	ld	s1,8(sp)
ffffffffc0203f5a:	6105                	addi	sp,sp,32
ffffffffc0203f5c:	8082                	ret
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0203f5e:	6d1c                	ld	a5,24(a0)
ffffffffc0203f60:	639c                	ld	a5,0(a5)
    assert(start_a + slub_usable_size(a) <= start_b ||
ffffffffc0203f62:	97a6                	add	a5,a5,s1
ffffffffc0203f64:	fef478e3          	bgeu	s0,a5,ffffffffc0203f54 <slub_test_disjoint+0x24>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0203f68:	8522                	mv	a0,s0
ffffffffc0203f6a:	8aeff0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0203f6e:	6518                	ld	a4,8(a0)
ffffffffc0203f70:	4785                	li	a5,1
ffffffffc0203f72:	02f70663          	beq	a4,a5,ffffffffc0203f9e <slub_test_disjoint+0x6e>
ffffffffc0203f76:	7d0c                	ld	a1,56(a0)
    assert(start_a + slub_usable_size(a) <= start_b ||
ffffffffc0203f78:	942e                	add	s0,s0,a1
ffffffffc0203f7a:	fc84fde3          	bgeu	s1,s0,ffffffffc0203f54 <slub_test_disjoint+0x24>
ffffffffc0203f7e:	00004697          	auipc	a3,0x4
ffffffffc0203f82:	eb268693          	addi	a3,a3,-334 # ffffffffc0207e30 <buddy_pmm_manager+0xb08>
ffffffffc0203f86:	00002617          	auipc	a2,0x2
ffffffffc0203f8a:	02a60613          	addi	a2,a2,42 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203f8e:	19d00593          	li	a1,413
ffffffffc0203f92:	00003517          	auipc	a0,0x3
ffffffffc0203f96:	60650513          	addi	a0,a0,1542 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203f9a:	a30fc0ef          	jal	ra,ffffffffc02001ca <__panic>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0203f9e:	6d1c                	ld	a5,24(a0)
ffffffffc0203fa0:	638c                	ld	a1,0(a5)
ffffffffc0203fa2:	bfd9                	j	ffffffffc0203f78 <slub_test_disjoint+0x48>
    assert(a != NULL && b != NULL);
ffffffffc0203fa4:	00004697          	auipc	a3,0x4
ffffffffc0203fa8:	e7468693          	addi	a3,a3,-396 # ffffffffc0207e18 <buddy_pmm_manager+0xaf0>
ffffffffc0203fac:	00002617          	auipc	a2,0x2
ffffffffc0203fb0:	00460613          	addi	a2,a2,4 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0203fb4:	19c00593          	li	a1,412
ffffffffc0203fb8:	00003517          	auipc	a0,0x3
ffffffffc0203fbc:	5e050513          	addi	a0,a0,1504 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0203fc0:	a0afc0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0203fc4 <slub_test_verify>:
slub_test_verify(const void *ptr, size_t size, unsigned char seed) {
ffffffffc0203fc4:	1101                	addi	sp,sp,-32
ffffffffc0203fc6:	ec06                	sd	ra,24(sp)
ffffffffc0203fc8:	e822                	sd	s0,16(sp)
ffffffffc0203fca:	e426                	sd	s1,8(sp)
ffffffffc0203fcc:	e04a                	sd	s2,0(sp)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0203fce:	c535                	beqz	a0,ffffffffc020403a <slub_test_verify+0x76>
ffffffffc0203fd0:	84aa                	mv	s1,a0
ffffffffc0203fd2:	892e                	mv	s2,a1
ffffffffc0203fd4:	8432                	mv	s0,a2
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0203fd6:	842ff0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0203fda:	6518                	ld	a4,8(a0)
ffffffffc0203fdc:	4785                	li	a5,1
ffffffffc0203fde:	02f70b63          	beq	a4,a5,ffffffffc0204014 <slub_test_verify+0x50>
ffffffffc0203fe2:	7d1c                	ld	a5,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0203fe4:	0527eb63          	bltu	a5,s2,ffffffffc020403a <slub_test_verify+0x76>
    for (size_t i = 0; i < size; i++) {
ffffffffc0203fe8:	8526                	mv	a0,s1
ffffffffc0203fea:	01248733          	add	a4,s1,s2
ffffffffc0203fee:	00090d63          	beqz	s2,ffffffffc0204008 <slub_test_verify+0x44>
        assert(bytes[i] == slub_test_pattern(i, seed));
ffffffffc0203ff2:	00054783          	lbu	a5,0(a0)
ffffffffc0203ff6:	02879263          	bne	a5,s0,ffffffffc020401a <slub_test_verify+0x56>
    for (size_t i = 0; i < size; i++) {
ffffffffc0203ffa:	0254041b          	addiw	s0,s0,37
ffffffffc0203ffe:	0505                	addi	a0,a0,1
ffffffffc0204000:	0ff47413          	zext.b	s0,s0
ffffffffc0204004:	fee517e3          	bne	a0,a4,ffffffffc0203ff2 <slub_test_verify+0x2e>
}
ffffffffc0204008:	60e2                	ld	ra,24(sp)
ffffffffc020400a:	6442                	ld	s0,16(sp)
ffffffffc020400c:	64a2                	ld	s1,8(sp)
ffffffffc020400e:	6902                	ld	s2,0(sp)
ffffffffc0204010:	6105                	addi	sp,sp,32
ffffffffc0204012:	8082                	ret
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204014:	6d1c                	ld	a5,24(a0)
ffffffffc0204016:	639c                	ld	a5,0(a5)
ffffffffc0204018:	b7f1                	j	ffffffffc0203fe4 <slub_test_verify+0x20>
        assert(bytes[i] == slub_test_pattern(i, seed));
ffffffffc020401a:	00004697          	auipc	a3,0x4
ffffffffc020401e:	e6e68693          	addi	a3,a3,-402 # ffffffffc0207e88 <buddy_pmm_manager+0xb60>
ffffffffc0204022:	00002617          	auipc	a2,0x2
ffffffffc0204026:	f8e60613          	addi	a2,a2,-114 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020402a:	19500593          	li	a1,405
ffffffffc020402e:	00003517          	auipc	a0,0x3
ffffffffc0204032:	56a50513          	addi	a0,a0,1386 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0204036:	994fc0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc020403a:	00004697          	auipc	a3,0x4
ffffffffc020403e:	dae68693          	addi	a3,a3,-594 # ffffffffc0207de8 <buddy_pmm_manager+0xac0>
ffffffffc0204042:	00002617          	auipc	a2,0x2
ffffffffc0204046:	f6e60613          	addi	a2,a2,-146 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020404a:	19200593          	li	a1,402
ffffffffc020404e:	00003517          	auipc	a0,0x3
ffffffffc0204052:	54a50513          	addi	a0,a0,1354 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0204056:	974fc0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc020405a <slub_check_stress>:
    assert(nr_free_pages() == before);
    slub_check_invariants();
}

static void
slub_check_stress(void) {
ffffffffc020405a:	df010113          	addi	sp,sp,-528
ffffffffc020405e:	20113423          	sd	ra,520(sp)
ffffffffc0204062:	20813023          	sd	s0,512(sp)
ffffffffc0204066:	ffa6                	sd	s1,504(sp)
ffffffffc0204068:	fbca                	sd	s2,496(sp)
ffffffffc020406a:	f7ce                	sd	s3,488(sp)
ffffffffc020406c:	f3d2                	sd	s4,480(sp)
ffffffffc020406e:	efd6                	sd	s5,472(sp)
ffffffffc0204070:	ebda                	sd	s6,464(sp)
ffffffffc0204072:	e7de                	sd	s7,456(sp)
ffffffffc0204074:	e3e2                	sd	s8,448(sp)
ffffffffc0204076:	ff66                	sd	s9,440(sp)
ffffffffc0204078:	fb6a                	sd	s10,432(sp)
ffffffffc020407a:	f76e                	sd	s11,424(sp)
    const size_t sizes[] = {1, 16, 17, 32, 33, 64, 100, 128,
ffffffffc020407c:	00004797          	auipc	a5,0x4
ffffffffc0204080:	54c78793          	addi	a5,a5,1356 # ffffffffc02085c8 <buddy_pmm_manager+0x12a0>
ffffffffc0204084:	1018                	addi	a4,sp,32
ffffffffc0204086:	00004697          	auipc	a3,0x4
ffffffffc020408a:	5c268693          	addi	a3,a3,1474 # ffffffffc0208648 <buddy_pmm_manager+0x1320>
ffffffffc020408e:	0007b803          	ld	a6,0(a5)
ffffffffc0204092:	6788                	ld	a0,8(a5)
ffffffffc0204094:	6b8c                	ld	a1,16(a5)
ffffffffc0204096:	6f90                	ld	a2,24(a5)
ffffffffc0204098:	01073023          	sd	a6,0(a4)
ffffffffc020409c:	e708                	sd	a0,8(a4)
ffffffffc020409e:	eb0c                	sd	a1,16(a4)
ffffffffc02040a0:	ef10                	sd	a2,24(a4)
ffffffffc02040a2:	02078793          	addi	a5,a5,32
ffffffffc02040a6:	02070713          	addi	a4,a4,32
ffffffffc02040aa:	fed792e3          	bne	a5,a3,ffffffffc020408e <slub_check_stress+0x34>
        256, 513, 1024, 2048, 2049, 4096, 5000, 8192};
    void *objects[16] = {0};
ffffffffc02040ae:	08000613          	li	a2,128
ffffffffc02040b2:	4581                	li	a1,0
ffffffffc02040b4:	1108                	addi	a0,sp,160
ffffffffc02040b6:	461010ef          	jal	ra,ffffffffc0205d16 <memset>
    size_t requests[16] = {0};
ffffffffc02040ba:	1200                	addi	s0,sp,288
ffffffffc02040bc:	08000613          	li	a2,128
ffffffffc02040c0:	4581                	li	a1,0
ffffffffc02040c2:	8522                	mv	a0,s0
ffffffffc02040c4:	453010ef          	jal	ra,ffffffffc0205d16 <memset>
    unsigned char patterns[16] = {0};
    uint32_t seed = 0x20261024;
ffffffffc02040c8:	20261ab7          	lui	s5,0x20261
    size_t before = nr_free_pages();
    for (size_t step = 0; step < 256; step++) {
        seed = seed * 1664525U + 1013904223U;
ffffffffc02040cc:	00196c37          	lui	s8,0x196
    uint32_t seed = 0x20261024;
ffffffffc02040d0:	024a8a93          	addi	s5,s5,36 # 20261024 <kern_entry-0xffffffff9ff9efdc>
    unsigned char patterns[16] = {0};
ffffffffc02040d4:	e802                	sd	zero,16(sp)
ffffffffc02040d6:	ec02                	sd	zero,24(sp)
        seed = seed * 1664525U + 1013904223U;
ffffffffc02040d8:	60dc0c1b          	addiw	s8,s8,1549
    size_t before = nr_free_pages();
ffffffffc02040dc:	bcdfe0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
        seed = seed * 1664525U + 1013904223U;
ffffffffc02040e0:	038a87bb          	mulw	a5,s5,s8
ffffffffc02040e4:	3c6efbb7          	lui	s7,0x3c6ef
ffffffffc02040e8:	35fb8b9b          	addiw	s7,s7,863
    size_t before = nr_free_pages();
ffffffffc02040ec:	e42a                	sd	a0,8(sp)
ffffffffc02040ee:	4981                	li	s3,0
    for (size_t step = 0; step < 256; step++) {
ffffffffc02040f0:	4b01                	li	s6,0
            objects[slot] = slub_alloc(requests[slot]);
            assert(objects[slot] != NULL);
            patterns[slot] = step;
            slub_test_fill(objects[slot], requests[slot], patterns[slot]);
        }
        for (size_t i = 0; i < 16; i++) {
ffffffffc02040f2:	4a41                	li	s4,16
    memset(checked_frames, 0, sizeof(checked_frames));
ffffffffc02040f4:	00189d97          	auipc	s11,0x189
ffffffffc02040f8:	92cd8d93          	addi	s11,s11,-1748 # ffffffffc038ca20 <checked_frames>
        seed = seed * 1664525U + 1013904223U;
ffffffffc02040fc:	01778abb          	addw	s5,a5,s7
        size_t slot = (seed >> 16) % 16;
ffffffffc0204100:	010ad49b          	srliw	s1,s5,0x10
ffffffffc0204104:	88bd                	andi	s1,s1,15
        if (objects[slot] != NULL) {
ffffffffc0204106:	0c098063          	beqz	s3,ffffffffc02041c6 <slub_check_stress+0x16c>
            slub_test_verify(objects[slot], requests[slot], patterns[slot]);
ffffffffc020410a:	131c                	addi	a5,sp,416
ffffffffc020410c:	00349913          	slli	s2,s1,0x3
ffffffffc0204110:	993e                	add	s2,s2,a5
ffffffffc0204112:	94be                	add	s1,s1,a5
ffffffffc0204114:	e704c603          	lbu	a2,-400(s1)
ffffffffc0204118:	f8093583          	ld	a1,-128(s2)
ffffffffc020411c:	854e                	mv	a0,s3
ffffffffc020411e:	ea7ff0ef          	jal	ra,ffffffffc0203fc4 <slub_test_verify>
    if (ptr == NULL) {
ffffffffc0204122:	854e                	mv	a0,s3
ffffffffc0204124:	ccfff0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
            objects[slot] = NULL;
ffffffffc0204128:	f0093023          	sd	zero,-256(s2)
        for (size_t i = 0; i < 16; i++) {
ffffffffc020412c:	0a810913          	addi	s2,sp,168
ffffffffc0204130:	e022                	sd	s0,0(sp)
    uint32_t seed = 0x20261024;
ffffffffc0204132:	89a2                	mv	s3,s0
        for (size_t i = 0; i < 16; i++) {
ffffffffc0204134:	4481                	li	s1,0
ffffffffc0204136:	a029                	j	ffffffffc0204140 <slub_check_stress+0xe6>
ffffffffc0204138:	03448f63          	beq	s1,s4,ffffffffc0204176 <slub_check_stress+0x11c>
ffffffffc020413c:	0921                	addi	s2,s2,8
ffffffffc020413e:	09a1                	addi	s3,s3,8
            if (objects[i] == NULL) {
ffffffffc0204140:	ff893d03          	ld	s10,-8(s2)
                continue;
            }
            slub_test_verify(objects[i], requests[i], patterns[i]);
            for (size_t j = i + 1; j < 16; j++) {
ffffffffc0204144:	0485                	addi	s1,s1,1
            if (objects[i] == NULL) {
ffffffffc0204146:	fe0d09e3          	beqz	s10,ffffffffc0204138 <slub_check_stress+0xde>
            slub_test_verify(objects[i], requests[i], patterns[i]);
ffffffffc020414a:	081c                	addi	a5,sp,16
ffffffffc020414c:	97a6                	add	a5,a5,s1
ffffffffc020414e:	fff7c603          	lbu	a2,-1(a5)
ffffffffc0204152:	0009b583          	ld	a1,0(s3)
ffffffffc0204156:	856a                	mv	a0,s10
ffffffffc0204158:	e6dff0ef          	jal	ra,ffffffffc0203fc4 <slub_test_verify>
            for (size_t j = i + 1; j < 16; j++) {
ffffffffc020415c:	01448d63          	beq	s1,s4,ffffffffc0204176 <slub_check_stress+0x11c>
ffffffffc0204160:	8cca                	mv	s9,s2
                if (objects[j] != NULL) {
ffffffffc0204162:	000cb583          	ld	a1,0(s9)
ffffffffc0204166:	c581                	beqz	a1,ffffffffc020416e <slub_check_stress+0x114>
                    slub_test_disjoint(objects[i], objects[j]);
ffffffffc0204168:	856a                	mv	a0,s10
ffffffffc020416a:	dc7ff0ef          	jal	ra,ffffffffc0203f30 <slub_test_disjoint>
            for (size_t j = i + 1; j < 16; j++) {
ffffffffc020416e:	0ca1                	addi	s9,s9,8
ffffffffc0204170:	fe8c99e3          	bne	s9,s0,ffffffffc0204162 <slub_check_stress+0x108>
ffffffffc0204174:	b7e1                	j	ffffffffc020413c <slub_check_stress+0xe2>
    assert(initialized);
ffffffffc0204176:	00192797          	auipc	a5,0x192
ffffffffc020417a:	90a78793          	addi	a5,a5,-1782 # ffffffffc0395a80 <initialized>
ffffffffc020417e:	439c                	lw	a5,0(a5)
ffffffffc0204180:	10078c63          	beqz	a5,ffffffffc0204298 <slub_check_stress+0x23e>
    memset(checked_frames, 0, sizeof(checked_frames));
ffffffffc0204184:	6621                	lui	a2,0x8
ffffffffc0204186:	4581                	li	a1,0
ffffffffc0204188:	856e                	mv	a0,s11
ffffffffc020418a:	38d010ef          	jal	ra,ffffffffc0205d16 <memset>
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
ffffffffc020418e:	a68ff0ef          	jal	ra,ffffffffc02033f6 <slub_check_invariants.part.0>
    for (size_t step = 0; step < 256; step++) {
ffffffffc0204192:	0b05                	addi	s6,s6,1
ffffffffc0204194:	10000793          	li	a5,256
ffffffffc0204198:	0afb0163          	beq	s6,a5,ffffffffc020423a <slub_check_stress+0x1e0>
        seed = seed * 1664525U + 1013904223U;
ffffffffc020419c:	038a87bb          	mulw	a5,s5,s8
        if (objects[slot] != NULL) {
ffffffffc02041a0:	1318                	addi	a4,sp,416
        seed = seed * 1664525U + 1013904223U;
ffffffffc02041a2:	017787bb          	addw	a5,a5,s7
        size_t slot = (seed >> 16) % 16;
ffffffffc02041a6:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02041aa:	8bbd                	andi	a5,a5,15
        if (objects[slot] != NULL) {
ffffffffc02041ac:	078e                	slli	a5,a5,0x3
ffffffffc02041ae:	97ba                	add	a5,a5,a4
ffffffffc02041b0:	f007b983          	ld	s3,-256(a5)
        seed = seed * 1664525U + 1013904223U;
ffffffffc02041b4:	038a87bb          	mulw	a5,s5,s8
ffffffffc02041b8:	01778abb          	addw	s5,a5,s7
        size_t slot = (seed >> 16) % 16;
ffffffffc02041bc:	010ad49b          	srliw	s1,s5,0x10
ffffffffc02041c0:	88bd                	andi	s1,s1,15
        if (objects[slot] != NULL) {
ffffffffc02041c2:	f40994e3          	bnez	s3,ffffffffc020410a <slub_check_stress+0xb0>
            seed = seed * 1664525U + 1013904223U;
ffffffffc02041c6:	038a8abb          	mulw	s5,s5,s8
    if (!initialized || size == 0) {
ffffffffc02041ca:	00192797          	auipc	a5,0x192
ffffffffc02041ce:	8b678793          	addi	a5,a5,-1866 # ffffffffc0395a80 <initialized>
ffffffffc02041d2:	4398                	lw	a4,0(a5)
            requests[slot] = sizes[(seed >> 16) % (sizeof(sizes) / sizeof(sizes[0]))];
ffffffffc02041d4:	00349913          	slli	s2,s1,0x3
ffffffffc02041d8:	131c                	addi	a5,sp,416
ffffffffc02041da:	993e                	add	s2,s2,a5
ffffffffc02041dc:	1314                	addi	a3,sp,416
            seed = seed * 1664525U + 1013904223U;
ffffffffc02041de:	017a8abb          	addw	s5,s5,s7
            requests[slot] = sizes[(seed >> 16) % (sizeof(sizes) / sizeof(sizes[0]))];
ffffffffc02041e2:	010ad79b          	srliw	a5,s5,0x10
ffffffffc02041e6:	8bbd                	andi	a5,a5,15
ffffffffc02041e8:	078e                	slli	a5,a5,0x3
ffffffffc02041ea:	97b6                	add	a5,a5,a3
ffffffffc02041ec:	e807b983          	ld	s3,-384(a5)
ffffffffc02041f0:	f9393023          	sd	s3,-128(s2)
    if (!initialized || size == 0) {
ffffffffc02041f4:	c31d                	beqz	a4,ffffffffc020421a <slub_check_stress+0x1c0>
ffffffffc02041f6:	02098263          	beqz	s3,ffffffffc020421a <slub_check_stress+0x1c0>
ffffffffc02041fa:	854e                	mv	a0,s3
ffffffffc02041fc:	935ff0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
            objects[slot] = slub_alloc(requests[slot]);
ffffffffc0204200:	f0a93023          	sd	a0,-256(s2)
            assert(objects[slot] != NULL);
ffffffffc0204204:	c919                	beqz	a0,ffffffffc020421a <slub_check_stress+0x1c0>
            patterns[slot] = step;
ffffffffc0204206:	131c                	addi	a5,sp,416
ffffffffc0204208:	0ffb7613          	zext.b	a2,s6
ffffffffc020420c:	94be                	add	s1,s1,a5
            slub_test_fill(objects[slot], requests[slot], patterns[slot]);
ffffffffc020420e:	85ce                	mv	a1,s3
            patterns[slot] = step;
ffffffffc0204210:	e6c48823          	sb	a2,-400(s1)
            slub_test_fill(objects[slot], requests[slot], patterns[slot]);
ffffffffc0204214:	cabff0ef          	jal	ra,ffffffffc0203ebe <slub_test_fill>
ffffffffc0204218:	bf11                	j	ffffffffc020412c <slub_check_stress+0xd2>
            assert(objects[slot] != NULL);
ffffffffc020421a:	00004697          	auipc	a3,0x4
ffffffffc020421e:	c9668693          	addi	a3,a3,-874 # ffffffffc0207eb0 <buddy_pmm_manager+0xb88>
ffffffffc0204222:	00002617          	auipc	a2,0x2
ffffffffc0204226:	d8e60613          	addi	a2,a2,-626 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020422a:	29200593          	li	a1,658
ffffffffc020422e:	00003517          	auipc	a0,0x3
ffffffffc0204232:	36a50513          	addi	a0,a0,874 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0204236:	f95fb0ef          	jal	ra,ffffffffc02001ca <__panic>
ffffffffc020423a:	1104                	addi	s1,sp,160
ffffffffc020423c:	01010913          	addi	s2,sp,16
            }
        }
        slub_check_invariants();
    }
    for (size_t i = 0; i < 16; i++) {
        if (objects[i] != NULL) {
ffffffffc0204240:	0004b983          	ld	s3,0(s1)
ffffffffc0204244:	00098c63          	beqz	s3,ffffffffc020425c <slub_check_stress+0x202>
            slub_test_verify(objects[i], requests[i], patterns[i]);
ffffffffc0204248:	6782                	ld	a5,0(sp)
ffffffffc020424a:	00094603          	lbu	a2,0(s2)
ffffffffc020424e:	854e                	mv	a0,s3
ffffffffc0204250:	638c                	ld	a1,0(a5)
ffffffffc0204252:	d73ff0ef          	jal	ra,ffffffffc0203fc4 <slub_test_verify>
    if (ptr == NULL) {
ffffffffc0204256:	854e                	mv	a0,s3
ffffffffc0204258:	b9bff0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
    for (size_t i = 0; i < 16; i++) {
ffffffffc020425c:	6782                	ld	a5,0(sp)
ffffffffc020425e:	04a1                	addi	s1,s1,8
ffffffffc0204260:	0905                	addi	s2,s2,1
ffffffffc0204262:	07a1                	addi	a5,a5,8
ffffffffc0204264:	e03e                	sd	a5,0(sp)
ffffffffc0204266:	fc849de3          	bne	s1,s0,ffffffffc0204240 <slub_check_stress+0x1e6>
            slub_free(objects[i]);
        }
    }
    assert(nr_free_pages() == before);
ffffffffc020426a:	a3ffe0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc020426e:	67a2                	ld	a5,8(sp)
ffffffffc0204270:	04f51463          	bne	a0,a5,ffffffffc02042b8 <slub_check_stress+0x25e>
}
ffffffffc0204274:	20813083          	ld	ra,520(sp)
ffffffffc0204278:	20013403          	ld	s0,512(sp)
ffffffffc020427c:	74fe                	ld	s1,504(sp)
ffffffffc020427e:	795e                	ld	s2,496(sp)
ffffffffc0204280:	79be                	ld	s3,488(sp)
ffffffffc0204282:	7a1e                	ld	s4,480(sp)
ffffffffc0204284:	6afe                	ld	s5,472(sp)
ffffffffc0204286:	6b5e                	ld	s6,464(sp)
ffffffffc0204288:	6bbe                	ld	s7,456(sp)
ffffffffc020428a:	6c1e                	ld	s8,448(sp)
ffffffffc020428c:	7cfa                	ld	s9,440(sp)
ffffffffc020428e:	7d5a                	ld	s10,432(sp)
ffffffffc0204290:	7dba                	ld	s11,424(sp)
ffffffffc0204292:	21010113          	addi	sp,sp,528
ffffffffc0204296:	8082                	ret
    assert(initialized);
ffffffffc0204298:	00003697          	auipc	a3,0x3
ffffffffc020429c:	35068693          	addi	a3,a3,848 # ffffffffc02075e8 <buddy_pmm_manager+0x2c0>
ffffffffc02042a0:	00002617          	auipc	a2,0x2
ffffffffc02042a4:	d1060613          	addi	a2,a2,-752 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02042a8:	14e00593          	li	a1,334
ffffffffc02042ac:	00003517          	auipc	a0,0x3
ffffffffc02042b0:	2ec50513          	addi	a0,a0,748 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02042b4:	f17fb0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == before);
ffffffffc02042b8:	00002697          	auipc	a3,0x2
ffffffffc02042bc:	67868693          	addi	a3,a3,1656 # ffffffffc0206930 <etext+0xc08>
ffffffffc02042c0:	00002617          	auipc	a2,0x2
ffffffffc02042c4:	cf060613          	addi	a2,a2,-784 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02042c8:	2a900593          	li	a1,681
ffffffffc02042cc:	00003517          	auipc	a0,0x3
ffffffffc02042d0:	2cc50513          	addi	a0,a0,716 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02042d4:	ef7fb0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02042d8 <slub_init>:
    if (initialized) {
ffffffffc02042d8:	00191817          	auipc	a6,0x191
ffffffffc02042dc:	7a880813          	addi	a6,a6,1960 # ffffffffc0395a80 <initialized>
ffffffffc02042e0:	00082783          	lw	a5,0(a6)
ffffffffc02042e4:	ebc1                	bnez	a5,ffffffffc0204374 <slub_init+0x9c>
slub_init(void) {
ffffffffc02042e6:	1141                	addi	sp,sp,-16
ffffffffc02042e8:	e406                	sd	ra,8(sp)
    assert(pmm_manager != NULL && npage > nbase);
ffffffffc02042ea:	00191797          	auipc	a5,0x191
ffffffffc02042ee:	7767b783          	ld	a5,1910(a5) # ffffffffc0395a60 <pmm_manager>
ffffffffc02042f2:	c3d1                	beqz	a5,ffffffffc0204376 <slub_init+0x9e>
ffffffffc02042f4:	00191717          	auipc	a4,0x191
ffffffffc02042f8:	75c73703          	ld	a4,1884(a4) # ffffffffc0395a50 <npage>
ffffffffc02042fc:	00004797          	auipc	a5,0x4
ffffffffc0204300:	6f47b783          	ld	a5,1780(a5) # ffffffffc02089f0 <nbase>
ffffffffc0204304:	06e7f963          	bgeu	a5,a4,ffffffffc0204376 <slub_init+0x9e>
    assert((va_pa_offset & (PGSIZE - 1)) == 0);
ffffffffc0204308:	00191697          	auipc	a3,0x191
ffffffffc020430c:	7706b683          	ld	a3,1904(a3) # ffffffffc0395a78 <va_pa_offset>
ffffffffc0204310:	16d2                	slli	a3,a3,0x34
ffffffffc0204312:	0346d713          	srli	a4,a3,0x34
ffffffffc0204316:	00188797          	auipc	a5,0x188
ffffffffc020431a:	55278793          	addi	a5,a5,1362 # ffffffffc038c868 <caches+0x8>
        caches[i].object_size = (size_t)SLUB_ALIGNMENT << i;
ffffffffc020431e:	4541                	li	a0,16
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
ffffffffc0204320:	45a1                	li	a1,8
    assert((va_pa_offset & (PGSIZE - 1)) == 0);
ffffffffc0204322:	eab5                	bnez	a3,ffffffffc0204396 <slub_init+0xbe>
        caches[i].object_size = (size_t)SLUB_ALIGNMENT << i;
ffffffffc0204324:	01078693          	addi	a3,a5,16
ffffffffc0204328:	00e51633          	sll	a2,a0,a4
ffffffffc020432c:	fec7bc23          	sd	a2,-8(a5)
    elm->prev = elm->next = elm;
ffffffffc0204330:	e79c                	sd	a5,8(a5)
ffffffffc0204332:	e39c                	sd	a5,0(a5)
ffffffffc0204334:	ef94                	sd	a3,24(a5)
ffffffffc0204336:	eb94                	sd	a3,16(a5)
        caches[i].slabs = caches[i].inuse = 0;
ffffffffc0204338:	0207b423          	sd	zero,40(a5)
ffffffffc020433c:	0207b023          	sd	zero,32(a5)
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
ffffffffc0204340:	0705                	addi	a4,a4,1
ffffffffc0204342:	03878793          	addi	a5,a5,56
ffffffffc0204346:	fcb71fe3          	bne	a4,a1,ffffffffc0204324 <slub_init+0x4c>
ffffffffc020434a:	00190797          	auipc	a5,0x190
ffffffffc020434e:	6d678793          	addi	a5,a5,1750 # ffffffffc0394a20 <large_objects>
ffffffffc0204352:	e79c                	sd	a5,8(a5)
ffffffffc0204354:	e39c                	sd	a5,0(a5)
    large_count = 0;
ffffffffc0204356:	00191797          	auipc	a5,0x191
ffffffffc020435a:	7207b923          	sd	zero,1842(a5) # ffffffffc0395a88 <large_count>
}
ffffffffc020435e:	60a2                	ld	ra,8(sp)
    initialized = 1;
ffffffffc0204360:	4785                	li	a5,1
ffffffffc0204362:	00f82023          	sw	a5,0(a6)
    cprintf("slub_init: caches 16..2048 bytes, alignment 16\n");
ffffffffc0204366:	00004517          	auipc	a0,0x4
ffffffffc020436a:	bb250513          	addi	a0,a0,-1102 # ffffffffc0207f18 <buddy_pmm_manager+0xbf0>
}
ffffffffc020436e:	0141                	addi	sp,sp,16
    cprintf("slub_init: caches 16..2048 bytes, alignment 16\n");
ffffffffc0204370:	de5fb06f          	j	ffffffffc0200154 <cprintf>
ffffffffc0204374:	8082                	ret
    assert(pmm_manager != NULL && npage > nbase);
ffffffffc0204376:	00004697          	auipc	a3,0x4
ffffffffc020437a:	b5268693          	addi	a3,a3,-1198 # ffffffffc0207ec8 <buddy_pmm_manager+0xba0>
ffffffffc020437e:	00002617          	auipc	a2,0x2
ffffffffc0204382:	c3260613          	addi	a2,a2,-974 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0204386:	07a00593          	li	a1,122
ffffffffc020438a:	00003517          	auipc	a0,0x3
ffffffffc020438e:	20e50513          	addi	a0,a0,526 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0204392:	e39fb0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert((va_pa_offset & (PGSIZE - 1)) == 0);
ffffffffc0204396:	00004697          	auipc	a3,0x4
ffffffffc020439a:	b5a68693          	addi	a3,a3,-1190 # ffffffffc0207ef0 <buddy_pmm_manager+0xbc8>
ffffffffc020439e:	00002617          	auipc	a2,0x2
ffffffffc02043a2:	c1260613          	addi	a2,a2,-1006 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02043a6:	07b00593          	li	a1,123
ffffffffc02043aa:	00003517          	auipc	a0,0x3
ffffffffc02043ae:	1ee50513          	addi	a0,a0,494 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02043b2:	e19fb0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02043b6 <slub_check>:

void
slub_check(void) {
ffffffffc02043b6:	7161                	addi	sp,sp,-432
ffffffffc02043b8:	e352                	sd	s4,384(sp)
    assert(initialized);
ffffffffc02043ba:	00191a17          	auipc	s4,0x191
ffffffffc02043be:	6c6a0a13          	addi	s4,s4,1734 # ffffffffc0395a80 <initialized>
ffffffffc02043c2:	000a2783          	lw	a5,0(s4)
slub_check(void) {
ffffffffc02043c6:	f706                	sd	ra,424(sp)
ffffffffc02043c8:	f322                	sd	s0,416(sp)
ffffffffc02043ca:	ef26                	sd	s1,408(sp)
ffffffffc02043cc:	eb4a                	sd	s2,400(sp)
ffffffffc02043ce:	e74e                	sd	s3,392(sp)
ffffffffc02043d0:	fed6                	sd	s5,376(sp)
ffffffffc02043d2:	fada                	sd	s6,368(sp)
ffffffffc02043d4:	f6de                	sd	s7,360(sp)
ffffffffc02043d6:	f2e2                	sd	s8,352(sp)
ffffffffc02043d8:	eee6                	sd	s9,344(sp)
ffffffffc02043da:	eaea                	sd	s10,336(sp)
ffffffffc02043dc:	e6ee                	sd	s11,328(sp)
    assert(initialized);
ffffffffc02043de:	e399                	bnez	a5,ffffffffc02043e4 <slub_check+0x2e>
ffffffffc02043e0:	0660106f          	j	ffffffffc0205446 <slub_check+0x1090>
    slub_check_empty();
ffffffffc02043e4:	f5ffe0ef          	jal	ra,ffffffffc0203342 <slub_check_empty>
    assert(nr_free_pages() >= 64);
ffffffffc02043e8:	8c1fe0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc02043ec:	03f00793          	li	a5,63
ffffffffc02043f0:	00a7e463          	bltu	a5,a0,ffffffffc02043f8 <slub_check+0x42>
ffffffffc02043f4:	0320106f          	j	ffffffffc0205426 <slub_check+0x1070>
    size_t before = nr_free_pages();
ffffffffc02043f8:	8b1fe0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc02043fc:	87aa                	mv	a5,a0
    cprintf("slub_check: begin\n");
ffffffffc02043fe:	00004517          	auipc	a0,0x4
ffffffffc0204402:	b6250513          	addi	a0,a0,-1182 # ffffffffc0207f60 <buddy_pmm_manager+0xc38>
    size_t before = nr_free_pages();
ffffffffc0204406:	e43e                	sd	a5,8(sp)
    cprintf("slub_check: begin\n");
ffffffffc0204408:	d4dfb0ef          	jal	ra,ffffffffc0200154 <cprintf>
    assert(initialized);
ffffffffc020440c:	000a2783          	lw	a5,0(s4)
ffffffffc0204410:	e399                	bnez	a5,ffffffffc0204416 <slub_check+0x60>
ffffffffc0204412:	2fc0106f          	j	ffffffffc020570e <slub_check+0x1358>
    memset(checked_frames, 0, sizeof(checked_frames));
ffffffffc0204416:	6621                	lui	a2,0x8
ffffffffc0204418:	4581                	li	a1,0
ffffffffc020441a:	00188517          	auipc	a0,0x188
ffffffffc020441e:	60650513          	addi	a0,a0,1542 # ffffffffc038ca20 <checked_frames>
ffffffffc0204422:	0f5010ef          	jal	ra,ffffffffc0205d16 <memset>
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
ffffffffc0204426:	fd1fe0ef          	jal	ra,ffffffffc02033f6 <slub_check_invariants.part.0>
    size_t before = nr_free_pages();
ffffffffc020442a:	87ffe0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc020442e:	8baa                	mv	s7,a0
ffffffffc0204430:	4991                	li	s3,4
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204432:	4b05                	li	s6,1
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204434:	06300a93          	li	s5,99
    for (size_t i = 0; i < size; i++) {
ffffffffc0204438:	0a500c93          	li	s9,165
    memset(checked_frames, 0, sizeof(checked_frames));
ffffffffc020443c:	00188c17          	auipc	s8,0x188
ffffffffc0204440:	5e4c0c13          	addi	s8,s8,1508 # ffffffffc038ca20 <checked_frames>
    if (!initialized || size == 0) {
ffffffffc0204444:	000a2783          	lw	a5,0(s4)
ffffffffc0204448:	22078863          	beqz	a5,ffffffffc0204678 <slub_check+0x2c2>
ffffffffc020444c:	4541                	li	a0,16
ffffffffc020444e:	ee2ff0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
ffffffffc0204452:	000a2783          	lw	a5,0(s4)
ffffffffc0204456:	84aa                	mv	s1,a0
ffffffffc0204458:	22078063          	beqz	a5,ffffffffc0204678 <slub_check+0x2c2>
ffffffffc020445c:	06400513          	li	a0,100
ffffffffc0204460:	ed0ff0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
ffffffffc0204464:	000a2783          	lw	a5,0(s4)
ffffffffc0204468:	8d2a                	mv	s10,a0
ffffffffc020446a:	20078763          	beqz	a5,ffffffffc0204678 <slub_check+0x2c2>
ffffffffc020446e:	04000513          	li	a0,64
ffffffffc0204472:	ebeff0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
ffffffffc0204476:	892a                	mv	s2,a0
        assert(a != NULL && b != NULL && c != NULL);
ffffffffc0204478:	20048063          	beqz	s1,ffffffffc0204678 <slub_check+0x2c2>
ffffffffc020447c:	1e0d0e63          	beqz	s10,ffffffffc0204678 <slub_check+0x2c2>
ffffffffc0204480:	1e050c63          	beqz	a0,ffffffffc0204678 <slub_check+0x2c2>
        slub_test_disjoint(a, b);
ffffffffc0204484:	85ea                	mv	a1,s10
ffffffffc0204486:	8526                	mv	a0,s1
ffffffffc0204488:	aa9ff0ef          	jal	ra,ffffffffc0203f30 <slub_test_disjoint>
        slub_test_disjoint(a, c);
ffffffffc020448c:	85ca                	mv	a1,s2
ffffffffc020448e:	8526                	mv	a0,s1
ffffffffc0204490:	aa1ff0ef          	jal	ra,ffffffffc0203f30 <slub_test_disjoint>
        slub_test_disjoint(b, c);
ffffffffc0204494:	85ca                	mv	a1,s2
ffffffffc0204496:	856a                	mv	a0,s10
ffffffffc0204498:	a99ff0ef          	jal	ra,ffffffffc0203f30 <slub_test_disjoint>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc020449c:	856a                	mv	a0,s10
ffffffffc020449e:	b7bfe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc02044a2:	651c                	ld	a5,8(a0)
ffffffffc02044a4:	1d678763          	beq	a5,s6,ffffffffc0204672 <slub_check+0x2bc>
ffffffffc02044a8:	7d1c                	ld	a5,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc02044aa:	00fae463          	bltu	s5,a5,ffffffffc02044b2 <slub_check+0xfc>
ffffffffc02044ae:	6350006f          	j	ffffffffc02052e2 <slub_check+0xf2c>
ffffffffc02044b2:	846a                	mv	s0,s10
ffffffffc02044b4:	876a                	mv	a4,s10
ffffffffc02044b6:	03100793          	li	a5,49
    for (size_t i = 0; i < size; i++) {
ffffffffc02044ba:	0257869b          	addiw	a3,a5,37
        bytes[i] = slub_test_pattern(i, seed);
ffffffffc02044be:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc02044c2:	0ff6f793          	zext.b	a5,a3
ffffffffc02044c6:	0705                	addi	a4,a4,1
ffffffffc02044c8:	ff9799e3          	bne	a5,s9,ffffffffc02044ba <slub_check+0x104>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc02044cc:	856a                	mv	a0,s10
ffffffffc02044ce:	b4bfe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc02044d2:	651c                	ld	a5,8(a0)
ffffffffc02044d4:	19678c63          	beq	a5,s6,ffffffffc020466c <slub_check+0x2b6>
ffffffffc02044d8:	7d1c                	ld	a5,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc02044da:	00fae463          	bltu	s5,a5,ffffffffc02044e2 <slub_check+0x12c>
ffffffffc02044de:	1900106f          	j	ffffffffc020566e <slub_check+0x12b8>
ffffffffc02044e2:	03100793          	li	a5,49
        assert(bytes[i] == slub_test_pattern(i, seed));
ffffffffc02044e6:	00044703          	lbu	a4,0(s0)
ffffffffc02044ea:	00f70463          	beq	a4,a5,ffffffffc02044f2 <slub_check+0x13c>
ffffffffc02044ee:	6af0006f          	j	ffffffffc020539c <slub_check+0xfe6>
    for (size_t i = 0; i < size; i++) {
ffffffffc02044f2:	0257879b          	addiw	a5,a5,37
ffffffffc02044f6:	0ff7f793          	zext.b	a5,a5
ffffffffc02044fa:	0405                	addi	s0,s0,1
ffffffffc02044fc:	ff9795e3          	bne	a5,s9,ffffffffc02044e6 <slub_check+0x130>
    assert(initialized);
ffffffffc0204500:	000a2783          	lw	a5,0(s4)
ffffffffc0204504:	e399                	bnez	a5,ffffffffc020450a <slub_check+0x154>
ffffffffc0204506:	2080106f          	j	ffffffffc020570e <slub_check+0x1358>
    memset(checked_frames, 0, sizeof(checked_frames));
ffffffffc020450a:	6621                	lui	a2,0x8
ffffffffc020450c:	4581                	li	a1,0
ffffffffc020450e:	8562                	mv	a0,s8
ffffffffc0204510:	007010ef          	jal	ra,ffffffffc0205d16 <memset>
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
ffffffffc0204514:	ee3fe0ef          	jal	ra,ffffffffc02033f6 <slub_check_invariants.part.0>
    if (ptr == NULL) {
ffffffffc0204518:	856a                	mv	a0,s10
ffffffffc020451a:	8d9ff0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
ffffffffc020451e:	8526                	mv	a0,s1
ffffffffc0204520:	8d3ff0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
ffffffffc0204524:	854a                	mv	a0,s2
ffffffffc0204526:	8cdff0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
        assert(nr_free_pages() == before);
ffffffffc020452a:	f7efe0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc020452e:	00ab8463          	beq	s7,a0,ffffffffc0204536 <slub_check+0x180>
ffffffffc0204532:	17c0106f          	j	ffffffffc02056ae <slub_check+0x12f8>
    for (size_t round = 0; round < 4; round++) {
ffffffffc0204536:	19fd                	addi	s3,s3,-1
ffffffffc0204538:	f00996e3          	bnez	s3,ffffffffc0204444 <slub_check+0x8e>
    slub_check_invariants();
    slub_check_basic();
    cprintf("slub_check: basic passed\n");
ffffffffc020453c:	00004517          	auipc	a0,0x4
ffffffffc0204540:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0207f78 <buddy_pmm_manager+0xc50>
ffffffffc0204544:	c11fb0ef          	jal	ra,ffffffffc0200154 <cprintf>
    const size_t requests[] = {1, 8, 15, 16, 17, 24, 31, 32, 33, 63, 64, 65,
ffffffffc0204548:	00004797          	auipc	a5,0x4
ffffffffc020454c:	10078793          	addi	a5,a5,256 # ffffffffc0208648 <buddy_pmm_manager+0x1320>
ffffffffc0204550:	10b8                	addi	a4,sp,104
ffffffffc0204552:	00004897          	auipc	a7,0x4
ffffffffc0204556:	1be88893          	addi	a7,a7,446 # ffffffffc0208710 <buddy_pmm_manager+0x13e8>
ffffffffc020455a:	0007b803          	ld	a6,0(a5)
ffffffffc020455e:	6788                	ld	a0,8(a5)
ffffffffc0204560:	6b8c                	ld	a1,16(a5)
ffffffffc0204562:	6f90                	ld	a2,24(a5)
ffffffffc0204564:	7394                	ld	a3,32(a5)
ffffffffc0204566:	01073023          	sd	a6,0(a4)
ffffffffc020456a:	e708                	sd	a0,8(a4)
ffffffffc020456c:	eb0c                	sd	a1,16(a4)
ffffffffc020456e:	ef10                	sd	a2,24(a4)
ffffffffc0204570:	f314                	sd	a3,32(a4)
ffffffffc0204572:	02878793          	addi	a5,a5,40
ffffffffc0204576:	02870713          	addi	a4,a4,40
ffffffffc020457a:	ff1790e3          	bne	a5,a7,ffffffffc020455a <slub_check+0x1a4>
ffffffffc020457e:	6394                	ld	a3,0(a5)
ffffffffc0204580:	679c                	ld	a5,8(a5)
ffffffffc0204582:	00190b97          	auipc	s7,0x190
ffffffffc0204586:	4aeb8b93          	addi	s7,s7,1198 # ffffffffc0394a30 <test_objects>
ffffffffc020458a:	e314                	sd	a3,0(a4)
ffffffffc020458c:	e71c                	sd	a5,8(a4)
    size_t before = nr_free_pages();
ffffffffc020458e:	f1afe0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
    if (!initialized || size == 0) {
ffffffffc0204592:	000a2783          	lw	a5,0(s4)
        if (requests[i] > 2048) {
ffffffffc0204596:	6c85                	lui	s9,0x1
    size_t before = nr_free_pages();
ffffffffc0204598:	e02a                	sd	a0,0(sp)
    for (size_t i = 0; i < count; i++) {
ffffffffc020459a:	06810a93          	addi	s5,sp,104
    size_t before = nr_free_pages();
ffffffffc020459e:	8c5e                	mv	s8,s7
ffffffffc02045a0:	84de                	mv	s1,s7
    for (size_t i = 0; i < count; i++) {
ffffffffc02045a2:	4901                	li	s2,0
        if (requests[i] > 2048) {
ffffffffc02045a4:	800c8c93          	addi	s9,s9,-2048 # 800 <kern_entry-0xffffffffc01ff800>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc02045a8:	4d05                	li	s10,1
        test_objects[i] = slub_alloc(requests[i]);
ffffffffc02045aa:	000abb03          	ld	s6,0(s5)
    if (!initialized || size == 0) {
ffffffffc02045ae:	cbc1                	beqz	a5,ffffffffc020463e <slub_check+0x288>
ffffffffc02045b0:	080b0763          	beqz	s6,ffffffffc020463e <slub_check+0x288>
ffffffffc02045b4:	855a                	mv	a0,s6
ffffffffc02045b6:	d7aff0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
        test_objects[i] = slub_alloc(requests[i]);
ffffffffc02045ba:	e088                	sd	a0,0(s1)
ffffffffc02045bc:	842a                	mv	s0,a0
        assert(test_objects[i] != NULL);
ffffffffc02045be:	c541                	beqz	a0,ffffffffc0204646 <slub_check+0x290>
        while (expected < requests[i] && expected < 2048) {
ffffffffc02045c0:	4741                	li	a4,16
ffffffffc02045c2:	479d                	li	a5,7
        size_t expected = SLUB_ALIGNMENT;
ffffffffc02045c4:	4dc1                	li	s11,16
        while (expected < requests[i] && expected < 2048) {
ffffffffc02045c6:	01677763          	bgeu	a4,s6,ffffffffc02045d4 <slub_check+0x21e>
            expected <<= 1;
ffffffffc02045ca:	0d86                	slli	s11,s11,0x1
        while (expected < requests[i] && expected < 2048) {
ffffffffc02045cc:	016df463          	bgeu	s11,s6,ffffffffc02045d4 <slub_check+0x21e>
ffffffffc02045d0:	37fd                	addiw	a5,a5,-1
ffffffffc02045d2:	ffe5                	bnez	a5,ffffffffc02045ca <slub_check+0x214>
        if (requests[i] > 2048) {
ffffffffc02045d4:	016cfc63          	bgeu	s9,s6,ffffffffc02045ec <slub_check+0x236>
            assert(slub_lookup(test_objects[i])->kind == SLUB_LARGE);
ffffffffc02045d8:	8522                	mv	a0,s0
ffffffffc02045da:	a3ffe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
ffffffffc02045de:	651c                	ld	a5,8(a0)
ffffffffc02045e0:	4709                	li	a4,2
ffffffffc02045e2:	00e78463          	beq	a5,a4,ffffffffc02045ea <slub_check+0x234>
ffffffffc02045e6:	6a10006f          	j	ffffffffc0205486 <slub_check+0x10d0>
ffffffffc02045ea:	8dda                	mv	s11,s6
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc02045ec:	8522                	mv	a0,s0
ffffffffc02045ee:	a2bfe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc02045f2:	651c                	ld	a5,8(a0)
ffffffffc02045f4:	07a78963          	beq	a5,s10,ffffffffc0204666 <slub_check+0x2b0>
ffffffffc02045f8:	7d1c                	ld	a5,56(a0)
        assert(slub_usable_size(test_objects[i]) == expected);
ffffffffc02045fa:	00fd8463          	beq	s11,a5,ffffffffc0204602 <slub_check+0x24c>
ffffffffc02045fe:	6690006f          	j	ffffffffc0205466 <slub_check+0x10b0>
        slub_test_fill(test_objects[i], expected, i);
ffffffffc0204602:	0ff97613          	zext.b	a2,s2
ffffffffc0204606:	85ee                	mv	a1,s11
ffffffffc0204608:	8522                	mv	a0,s0
ffffffffc020460a:	8b5ff0ef          	jal	ra,ffffffffc0203ebe <slub_test_fill>
    for (size_t i = 0; i < count; i++) {
ffffffffc020460e:	00190b13          	addi	s6,s2,1
        for (size_t j = 0; j < i; j++) {
ffffffffc0204612:	00090e63          	beqz	s2,ffffffffc020462e <slub_check+0x278>
ffffffffc0204616:	895e                	mv	s2,s7
            slub_test_disjoint(test_objects[i], test_objects[j]);
ffffffffc0204618:	00093583          	ld	a1,0(s2)
ffffffffc020461c:	8522                	mv	a0,s0
        for (size_t j = 0; j < i; j++) {
ffffffffc020461e:	0921                	addi	s2,s2,8
            slub_test_disjoint(test_objects[i], test_objects[j]);
ffffffffc0204620:	911ff0ef          	jal	ra,ffffffffc0203f30 <slub_test_disjoint>
        for (size_t j = 0; j < i; j++) {
ffffffffc0204624:	ff249ae3          	bne	s1,s2,ffffffffc0204618 <slub_check+0x262>
    for (size_t i = 0; i < count; i++) {
ffffffffc0204628:	47ed                	li	a5,27
ffffffffc020462a:	06fb0763          	beq	s6,a5,ffffffffc0204698 <slub_check+0x2e2>
    if (!initialized || size == 0) {
ffffffffc020462e:	000a2783          	lw	a5,0(s4)
ffffffffc0204632:	0aa1                	addi	s5,s5,8
    for (size_t i = 0; i < count; i++) {
ffffffffc0204634:	895a                	mv	s2,s6
ffffffffc0204636:	04a1                	addi	s1,s1,8
        test_objects[i] = slub_alloc(requests[i]);
ffffffffc0204638:	000abb03          	ld	s6,0(s5)
    if (!initialized || size == 0) {
ffffffffc020463c:	fbb5                	bnez	a5,ffffffffc02045b0 <slub_check+0x1fa>
        test_objects[i] = slub_alloc(requests[i]);
ffffffffc020463e:	090e                	slli	s2,s2,0x3
ffffffffc0204640:	9c4a                	add	s8,s8,s2
ffffffffc0204642:	000c3023          	sd	zero,0(s8)
        assert(test_objects[i] != NULL);
ffffffffc0204646:	00004697          	auipc	a3,0x4
ffffffffc020464a:	95268693          	addi	a3,a3,-1710 # ffffffffc0207f98 <buddy_pmm_manager+0xc70>
ffffffffc020464e:	00002617          	auipc	a2,0x2
ffffffffc0204652:	96260613          	addi	a2,a2,-1694 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0204656:	1be00593          	li	a1,446
ffffffffc020465a:	00003517          	auipc	a0,0x3
ffffffffc020465e:	f3e50513          	addi	a0,a0,-194 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0204662:	b69fb0ef          	jal	ra,ffffffffc02001ca <__panic>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204666:	6d1c                	ld	a5,24(a0)
ffffffffc0204668:	639c                	ld	a5,0(a5)
ffffffffc020466a:	bf41                	j	ffffffffc02045fa <slub_check+0x244>
ffffffffc020466c:	6d1c                	ld	a5,24(a0)
ffffffffc020466e:	639c                	ld	a5,0(a5)
ffffffffc0204670:	b5ad                	j	ffffffffc02044da <slub_check+0x124>
ffffffffc0204672:	6d1c                	ld	a5,24(a0)
ffffffffc0204674:	639c                	ld	a5,0(a5)
ffffffffc0204676:	bd15                	j	ffffffffc02044aa <slub_check+0xf4>
        assert(a != NULL && b != NULL && c != NULL);
ffffffffc0204678:	00002697          	auipc	a3,0x2
ffffffffc020467c:	14068693          	addi	a3,a3,320 # ffffffffc02067b8 <etext+0xa90>
ffffffffc0204680:	00002617          	auipc	a2,0x2
ffffffffc0204684:	93060613          	addi	a2,a2,-1744 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0204688:	1a800593          	li	a1,424
ffffffffc020468c:	00003517          	auipc	a0,0x3
ffffffffc0204690:	f0c50513          	addi	a0,a0,-244 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0204694:	b37fb0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(initialized);
ffffffffc0204698:	000a2783          	lw	a5,0(s4)
ffffffffc020469c:	e399                	bnez	a5,ffffffffc02046a2 <slub_check+0x2ec>
ffffffffc020469e:	0700106f          	j	ffffffffc020570e <slub_check+0x1358>
    memset(checked_frames, 0, sizeof(checked_frames));
ffffffffc02046a2:	6621                	lui	a2,0x8
ffffffffc02046a4:	4581                	li	a1,0
ffffffffc02046a6:	00188517          	auipc	a0,0x188
ffffffffc02046aa:	37a50513          	addi	a0,a0,890 # ffffffffc038ca20 <checked_frames>
ffffffffc02046ae:	668010ef          	jal	ra,ffffffffc0205d16 <memset>
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
ffffffffc02046b2:	d45fe0ef          	jal	ra,ffffffffc02033f6 <slub_check_invariants.part.0>
    for (size_t i = 0; i < count; i++) {
ffffffffc02046b6:	00190497          	auipc	s1,0x190
ffffffffc02046ba:	37a48493          	addi	s1,s1,890 # ffffffffc0394a30 <test_objects>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc02046be:	4a85                	li	s5,1
    for (size_t i = 0; i < count; i++) {
ffffffffc02046c0:	496d                	li	s2,27
ffffffffc02046c2:	a01d                	j	ffffffffc02046e8 <slub_check+0x332>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc02046c4:	8522                	mv	a0,s0
ffffffffc02046c6:	953fe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc02046ca:	651c                	ld	a5,8(a0)
ffffffffc02046cc:	0f578f63          	beq	a5,s5,ffffffffc02047ca <slub_check+0x414>
ffffffffc02046d0:	7d0c                	ld	a1,56(a0)
        slub_test_verify(test_objects[i], slub_usable_size(test_objects[i]), i);
ffffffffc02046d2:	865a                	mv	a2,s6
ffffffffc02046d4:	8522                	mv	a0,s0
ffffffffc02046d6:	8efff0ef          	jal	ra,ffffffffc0203fc4 <slub_test_verify>
    if (ptr == NULL) {
ffffffffc02046da:	8522                	mv	a0,s0
    for (size_t i = 0; i < count; i++) {
ffffffffc02046dc:	0985                	addi	s3,s3,1
ffffffffc02046de:	f14ff0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
ffffffffc02046e2:	04a1                	addi	s1,s1,8
ffffffffc02046e4:	01298f63          	beq	s3,s2,ffffffffc0204702 <slub_check+0x34c>
        slub_test_verify(test_objects[i], slub_usable_size(test_objects[i]), i);
ffffffffc02046e8:	6080                	ld	s0,0(s1)
    if (ptr == NULL) {
ffffffffc02046ea:	0ff9fb13          	zext.b	s6,s3
ffffffffc02046ee:	f879                	bnez	s0,ffffffffc02046c4 <slub_check+0x30e>
        slub_test_verify(test_objects[i], slub_usable_size(test_objects[i]), i);
ffffffffc02046f0:	865a                	mv	a2,s6
ffffffffc02046f2:	4581                	li	a1,0
ffffffffc02046f4:	4501                	li	a0,0
    for (size_t i = 0; i < count; i++) {
ffffffffc02046f6:	0985                	addi	s3,s3,1
        slub_test_verify(test_objects[i], slub_usable_size(test_objects[i]), i);
ffffffffc02046f8:	8cdff0ef          	jal	ra,ffffffffc0203fc4 <slub_test_verify>
    for (size_t i = 0; i < count; i++) {
ffffffffc02046fc:	04a1                	addi	s1,s1,8
ffffffffc02046fe:	ff2995e3          	bne	s3,s2,ffffffffc02046e8 <slub_check+0x332>
    assert(nr_free_pages() == before);
ffffffffc0204702:	da6fe0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0204706:	6782                	ld	a5,0(sp)
ffffffffc0204708:	00a78463          	beq	a5,a0,ffffffffc0204710 <slub_check+0x35a>
ffffffffc020470c:	7830006f          	j	ffffffffc020568e <slub_check+0x12d8>
    slub_check_size_classes();
    cprintf("slub_check: size_classes passed\n");
ffffffffc0204710:	00004517          	auipc	a0,0x4
ffffffffc0204714:	90850513          	addi	a0,a0,-1784 # ffffffffc0208018 <buddy_pmm_manager+0xcf0>
ffffffffc0204718:	a3dfb0ef          	jal	ra,ffffffffc0200154 <cprintf>
    const size_t requests[] = {1, 7, 16, 24, 64, 100, 512, 2048, 5000};
ffffffffc020471c:	00004797          	auipc	a5,0x4
ffffffffc0204720:	eac78793          	addi	a5,a5,-340 # ffffffffc02085c8 <buddy_pmm_manager+0x12a0>
ffffffffc0204724:	1587b303          	ld	t1,344(a5)
ffffffffc0204728:	1607b883          	ld	a7,352(a5)
ffffffffc020472c:	1687b803          	ld	a6,360(a5)
ffffffffc0204730:	1707b503          	ld	a0,368(a5)
ffffffffc0204734:	1787b583          	ld	a1,376(a5)
ffffffffc0204738:	1807b603          	ld	a2,384(a5)
ffffffffc020473c:	1887b683          	ld	a3,392(a5)
ffffffffc0204740:	1907b703          	ld	a4,400(a5)
ffffffffc0204744:	1987b783          	ld	a5,408(a5)
ffffffffc0204748:	f49a                	sd	t1,104(sp)
ffffffffc020474a:	f8c6                	sd	a7,112(sp)
ffffffffc020474c:	fcc2                	sd	a6,120(sp)
ffffffffc020474e:	e12a                	sd	a0,128(sp)
ffffffffc0204750:	e52e                	sd	a1,136(sp)
ffffffffc0204752:	e932                	sd	a2,144(sp)
ffffffffc0204754:	ed36                	sd	a3,152(sp)
ffffffffc0204756:	f13a                	sd	a4,160(sp)
ffffffffc0204758:	f53e                	sd	a5,168(sp)
    size_t before = nr_free_pages();
ffffffffc020475a:	d4efe0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc020475e:	8b2a                	mv	s6,a0
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
ffffffffc0204760:	06810993          	addi	s3,sp,104
ffffffffc0204764:	0b010a93          	addi	s5,sp,176
ffffffffc0204768:	a825                	j	ffffffffc02047a0 <slub_check+0x3ea>
    if (!initialized || size == 0) {
ffffffffc020476a:	04090063          	beqz	s2,ffffffffc02047aa <slub_check+0x3f4>
ffffffffc020476e:	854a                	mv	a0,s2
ffffffffc0204770:	bc0ff0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
ffffffffc0204774:	84aa                	mv	s1,a0
        assert(p != NULL && ((uintptr_t)p & (SLUB_ALIGNMENT - 1)) == 0);
ffffffffc0204776:	c915                	beqz	a0,ffffffffc02047aa <slub_check+0x3f4>
ffffffffc0204778:	00f57413          	andi	s0,a0,15
ffffffffc020477c:	e41d                	bnez	s0,ffffffffc02047aa <slub_check+0x3f4>
        slub_test_fill(p, requests[i], 0x55);
ffffffffc020477e:	05500613          	li	a2,85
ffffffffc0204782:	85ca                	mv	a1,s2
ffffffffc0204784:	f3aff0ef          	jal	ra,ffffffffc0203ebe <slub_test_fill>
        slub_test_verify(p, requests[i], 0x55);
ffffffffc0204788:	8526                	mv	a0,s1
ffffffffc020478a:	05500613          	li	a2,85
ffffffffc020478e:	85ca                	mv	a1,s2
ffffffffc0204790:	835ff0ef          	jal	ra,ffffffffc0203fc4 <slub_test_verify>
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
ffffffffc0204794:	09a1                	addi	s3,s3,8
ffffffffc0204796:	8526                	mv	a0,s1
ffffffffc0204798:	e5aff0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
ffffffffc020479c:	03598a63          	beq	s3,s5,ffffffffc02047d0 <slub_check+0x41a>
    if (!initialized || size == 0) {
ffffffffc02047a0:	000a2783          	lw	a5,0(s4)
        void *p = slub_alloc(requests[i]);
ffffffffc02047a4:	0009b903          	ld	s2,0(s3)
    if (!initialized || size == 0) {
ffffffffc02047a8:	f3e9                	bnez	a5,ffffffffc020476a <slub_check+0x3b4>
        assert(p != NULL && ((uintptr_t)p & (SLUB_ALIGNMENT - 1)) == 0);
ffffffffc02047aa:	00004697          	auipc	a3,0x4
ffffffffc02047ae:	89668693          	addi	a3,a3,-1898 # ffffffffc0208040 <buddy_pmm_manager+0xd18>
ffffffffc02047b2:	00001617          	auipc	a2,0x1
ffffffffc02047b6:	7fe60613          	addi	a2,a2,2046 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02047ba:	1db00593          	li	a1,475
ffffffffc02047be:	00003517          	auipc	a0,0x3
ffffffffc02047c2:	dda50513          	addi	a0,a0,-550 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02047c6:	a05fb0ef          	jal	ra,ffffffffc02001ca <__panic>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc02047ca:	6d1c                	ld	a5,24(a0)
ffffffffc02047cc:	638c                	ld	a1,0(a5)
ffffffffc02047ce:	b711                	j	ffffffffc02046d2 <slub_check+0x31c>
    assert(nr_free_pages() == before);
ffffffffc02047d0:	cd8fe0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc02047d4:	5cab1de3          	bne	s6,a0,ffffffffc02055ae <slub_check+0x11f8>
    slub_check_alignment();
    cprintf("slub_check: alignment passed\n");
ffffffffc02047d8:	00004517          	auipc	a0,0x4
ffffffffc02047dc:	8a050513          	addi	a0,a0,-1888 # ffffffffc0208078 <buddy_pmm_manager+0xd50>
ffffffffc02047e0:	975fb0ef          	jal	ra,ffffffffc0200154 <cprintf>
    if (!initialized || size == 0) {
ffffffffc02047e4:	000a2783          	lw	a5,0(s4)
ffffffffc02047e8:	2e078de3          	beqz	a5,ffffffffc02052e2 <slub_check+0xf2c>
ffffffffc02047ec:	02000513          	li	a0,32
ffffffffc02047f0:	b40ff0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
ffffffffc02047f4:	000a2783          	lw	a5,0(s4)
ffffffffc02047f8:	892a                	mv	s2,a0
ffffffffc02047fa:	5a0786e3          	beqz	a5,ffffffffc02055a6 <slub_check+0x11f0>
ffffffffc02047fe:	04000513          	li	a0,64
ffffffffc0204802:	b2eff0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
ffffffffc0204806:	000a2783          	lw	a5,0(s4)
ffffffffc020480a:	89aa                	mv	s3,a0
ffffffffc020480c:	e399                	bnez	a5,ffffffffc0204812 <slub_check+0x45c>
ffffffffc020480e:	7e10006f          	j	ffffffffc02057ee <slub_check+0x1438>
ffffffffc0204812:	08000513          	li	a0,128
ffffffffc0204816:	b1aff0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
ffffffffc020481a:	84aa                	mv	s1,a0
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc020481c:	2c0903e3          	beqz	s2,ffffffffc02052e2 <slub_check+0xf2c>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0204820:	854a                	mv	a0,s2
ffffffffc0204822:	ff6fe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204826:	6518                	ld	a4,8(a0)
ffffffffc0204828:	4785                	li	a5,1
ffffffffc020482a:	32f708e3          	beq	a4,a5,ffffffffc020535a <slub_check+0xfa4>
ffffffffc020482e:	7d18                	ld	a4,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204830:	47fd                	li	a5,31
ffffffffc0204832:	2ae7f8e3          	bgeu	a5,a4,ffffffffc02052e2 <slub_check+0xf2c>
ffffffffc0204836:	8cca                	mv	s9,s2
ffffffffc0204838:	874a                	mv	a4,s2
ffffffffc020483a:	0aa00793          	li	a5,170
    for (size_t i = 0; i < size; i++) {
ffffffffc020483e:	04a00613          	li	a2,74
ffffffffc0204842:	0257869b          	addiw	a3,a5,37
        bytes[i] = slub_test_pattern(i, seed);
ffffffffc0204846:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc020484a:	0ff6f793          	zext.b	a5,a3
ffffffffc020484e:	0705                	addi	a4,a4,1
ffffffffc0204850:	fec799e3          	bne	a5,a2,ffffffffc0204842 <slub_check+0x48c>
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204854:	280987e3          	beqz	s3,ffffffffc02052e2 <slub_check+0xf2c>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0204858:	854e                	mv	a0,s3
ffffffffc020485a:	fbefe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc020485e:	6518                	ld	a4,8(a0)
ffffffffc0204860:	4785                	li	a5,1
ffffffffc0204862:	2ef708e3          	beq	a4,a5,ffffffffc0205352 <slub_check+0xf9c>
ffffffffc0204866:	7d18                	ld	a4,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204868:	03f00793          	li	a5,63
ffffffffc020486c:	26e7fbe3          	bgeu	a5,a4,ffffffffc02052e2 <slub_check+0xf2c>
ffffffffc0204870:	8b4e                	mv	s6,s3
ffffffffc0204872:	874e                	mv	a4,s3
ffffffffc0204874:	05500793          	li	a5,85
    for (size_t i = 0; i < size; i++) {
ffffffffc0204878:	09500613          	li	a2,149
ffffffffc020487c:	0257869b          	addiw	a3,a5,37
        bytes[i] = slub_test_pattern(i, seed);
ffffffffc0204880:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0204884:	0ff6f793          	zext.b	a5,a3
ffffffffc0204888:	0705                	addi	a4,a4,1
ffffffffc020488a:	fec799e3          	bne	a5,a2,ffffffffc020487c <slub_check+0x4c6>
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc020488e:	24048ae3          	beqz	s1,ffffffffc02052e2 <slub_check+0xf2c>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0204892:	8526                	mv	a0,s1
ffffffffc0204894:	f84fe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204898:	6518                	ld	a4,8(a0)
ffffffffc020489a:	4785                	li	a5,1
ffffffffc020489c:	2af707e3          	beq	a4,a5,ffffffffc020534a <slub_check+0xf94>
ffffffffc02048a0:	7d18                	ld	a4,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc02048a2:	07f00793          	li	a5,127
ffffffffc02048a6:	22e7fee3          	bgeu	a5,a4,ffffffffc02052e2 <slub_check+0xf2c>
ffffffffc02048aa:	8aa6                	mv	s5,s1
ffffffffc02048ac:	8726                	mv	a4,s1
ffffffffc02048ae:	0cc00793          	li	a5,204
    for (size_t i = 0; i < size; i++) {
ffffffffc02048b2:	04c00613          	li	a2,76
ffffffffc02048b6:	0257869b          	addiw	a3,a5,37
        bytes[i] = slub_test_pattern(i, seed);
ffffffffc02048ba:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc02048be:	0ff6f793          	zext.b	a5,a3
ffffffffc02048c2:	0705                	addi	a4,a4,1
ffffffffc02048c4:	fec799e3          	bne	a5,a2,ffffffffc02048b6 <slub_check+0x500>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc02048c8:	854a                	mv	a0,s2
ffffffffc02048ca:	f4efe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc02048ce:	6518                	ld	a4,8(a0)
ffffffffc02048d0:	4785                	li	a5,1
ffffffffc02048d2:	26f708e3          	beq	a4,a5,ffffffffc0205342 <slub_check+0xf8c>
ffffffffc02048d6:	7d18                	ld	a4,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc02048d8:	47fd                	li	a5,31
ffffffffc02048da:	58e7fae3          	bgeu	a5,a4,ffffffffc020566e <slub_check+0x12b8>
ffffffffc02048de:	874a                	mv	a4,s2
ffffffffc02048e0:	0aa00793          	li	a5,170
    for (size_t i = 0; i < size; i++) {
ffffffffc02048e4:	04a00613          	li	a2,74
        assert(bytes[i] == slub_test_pattern(i, seed));
ffffffffc02048e8:	00074683          	lbu	a3,0(a4)
ffffffffc02048ec:	2af698e3          	bne	a3,a5,ffffffffc020539c <slub_check+0xfe6>
    for (size_t i = 0; i < size; i++) {
ffffffffc02048f0:	0257879b          	addiw	a5,a5,37
ffffffffc02048f4:	0ff7f793          	zext.b	a5,a5
ffffffffc02048f8:	0705                	addi	a4,a4,1
ffffffffc02048fa:	fec797e3          	bne	a5,a2,ffffffffc02048e8 <slub_check+0x532>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc02048fe:	854e                	mv	a0,s3
ffffffffc0204900:	f18fe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204904:	6518                	ld	a4,8(a0)
ffffffffc0204906:	4785                	li	a5,1
ffffffffc0204908:	22f709e3          	beq	a4,a5,ffffffffc020533a <slub_check+0xf84>
ffffffffc020490c:	7d18                	ld	a4,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc020490e:	03f00793          	li	a5,63
ffffffffc0204912:	54e7fee3          	bgeu	a5,a4,ffffffffc020566e <slub_check+0x12b8>
ffffffffc0204916:	05500793          	li	a5,85
    for (size_t i = 0; i < size; i++) {
ffffffffc020491a:	09500693          	li	a3,149
        assert(bytes[i] == slub_test_pattern(i, seed));
ffffffffc020491e:	000b4703          	lbu	a4,0(s6)
ffffffffc0204922:	26f71de3          	bne	a4,a5,ffffffffc020539c <slub_check+0xfe6>
    for (size_t i = 0; i < size; i++) {
ffffffffc0204926:	0257879b          	addiw	a5,a5,37
ffffffffc020492a:	0ff7f793          	zext.b	a5,a5
ffffffffc020492e:	0b05                	addi	s6,s6,1
ffffffffc0204930:	fed797e3          	bne	a5,a3,ffffffffc020491e <slub_check+0x568>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0204934:	8526                	mv	a0,s1
ffffffffc0204936:	ee2fe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc020493a:	6518                	ld	a4,8(a0)
ffffffffc020493c:	4785                	li	a5,1
ffffffffc020493e:	1ef70ae3          	beq	a4,a5,ffffffffc0205332 <slub_check+0xf7c>
ffffffffc0204942:	7d18                	ld	a4,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204944:	07f00793          	li	a5,127
ffffffffc0204948:	52e7f3e3          	bgeu	a5,a4,ffffffffc020566e <slub_check+0x12b8>
ffffffffc020494c:	8726                	mv	a4,s1
ffffffffc020494e:	0cc00793          	li	a5,204
    for (size_t i = 0; i < size; i++) {
ffffffffc0204952:	04c00613          	li	a2,76
        assert(bytes[i] == slub_test_pattern(i, seed));
ffffffffc0204956:	00074683          	lbu	a3,0(a4)
ffffffffc020495a:	24f691e3          	bne	a3,a5,ffffffffc020539c <slub_check+0xfe6>
    for (size_t i = 0; i < size; i++) {
ffffffffc020495e:	0257879b          	addiw	a5,a5,37
ffffffffc0204962:	0ff7f793          	zext.b	a5,a5
ffffffffc0204966:	0705                	addi	a4,a4,1
ffffffffc0204968:	fec797e3          	bne	a5,a2,ffffffffc0204956 <slub_check+0x5a0>
    if (ptr == NULL) {
ffffffffc020496c:	854e                	mv	a0,s3
ffffffffc020496e:	c84ff0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0204972:	854a                	mv	a0,s2
ffffffffc0204974:	ea4fe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204978:	6518                	ld	a4,8(a0)
ffffffffc020497a:	4785                	li	a5,1
ffffffffc020497c:	1af707e3          	beq	a4,a5,ffffffffc020532a <slub_check+0xf74>
ffffffffc0204980:	7d18                	ld	a4,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204982:	47fd                	li	a5,31
ffffffffc0204984:	4ee7f5e3          	bgeu	a5,a4,ffffffffc020566e <slub_check+0x12b8>
ffffffffc0204988:	874a                	mv	a4,s2
ffffffffc020498a:	0aa00793          	li	a5,170
    for (size_t i = 0; i < size; i++) {
ffffffffc020498e:	04a00613          	li	a2,74
        assert(bytes[i] == slub_test_pattern(i, seed));
ffffffffc0204992:	00074683          	lbu	a3,0(a4)
ffffffffc0204996:	20f693e3          	bne	a3,a5,ffffffffc020539c <slub_check+0xfe6>
    for (size_t i = 0; i < size; i++) {
ffffffffc020499a:	0257879b          	addiw	a5,a5,37
ffffffffc020499e:	0ff7f793          	zext.b	a5,a5
ffffffffc02049a2:	0705                	addi	a4,a4,1
ffffffffc02049a4:	fec797e3          	bne	a5,a2,ffffffffc0204992 <slub_check+0x5dc>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc02049a8:	8526                	mv	a0,s1
ffffffffc02049aa:	e6efe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc02049ae:	6518                	ld	a4,8(a0)
ffffffffc02049b0:	4785                	li	a5,1
ffffffffc02049b2:	16f708e3          	beq	a4,a5,ffffffffc0205322 <slub_check+0xf6c>
ffffffffc02049b6:	7d18                	ld	a4,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc02049b8:	07f00793          	li	a5,127
ffffffffc02049bc:	4ae7f9e3          	bgeu	a5,a4,ffffffffc020566e <slub_check+0x12b8>
ffffffffc02049c0:	8726                	mv	a4,s1
ffffffffc02049c2:	0cc00793          	li	a5,204
    for (size_t i = 0; i < size; i++) {
ffffffffc02049c6:	04c00613          	li	a2,76
        assert(bytes[i] == slub_test_pattern(i, seed));
ffffffffc02049ca:	00074683          	lbu	a3,0(a4)
ffffffffc02049ce:	1cf697e3          	bne	a3,a5,ffffffffc020539c <slub_check+0xfe6>
    for (size_t i = 0; i < size; i++) {
ffffffffc02049d2:	0257879b          	addiw	a5,a5,37
ffffffffc02049d6:	0ff7f793          	zext.b	a5,a5
ffffffffc02049da:	0705                	addi	a4,a4,1
ffffffffc02049dc:	fec797e3          	bne	a5,a2,ffffffffc02049ca <slub_check+0x614>
    if (!initialized || size == 0) {
ffffffffc02049e0:	000a2783          	lw	a5,0(s4)
ffffffffc02049e4:	0e078fe3          	beqz	a5,ffffffffc02052e2 <slub_check+0xf2c>
ffffffffc02049e8:	04000513          	li	a0,64
ffffffffc02049ec:	944ff0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
ffffffffc02049f0:	89aa                	mv	s3,a0
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc02049f2:	0e0508e3          	beqz	a0,ffffffffc02052e2 <slub_check+0xf2c>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc02049f6:	e22fe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc02049fa:	6518                	ld	a4,8(a0)
ffffffffc02049fc:	4785                	li	a5,1
ffffffffc02049fe:	10f70ee3          	beq	a4,a5,ffffffffc020531a <slub_check+0xf64>
ffffffffc0204a02:	7d18                	ld	a4,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204a04:	03f00793          	li	a5,63
ffffffffc0204a08:	0ce7fde3          	bgeu	a5,a4,ffffffffc02052e2 <slub_check+0xf2c>
ffffffffc0204a0c:	874e                	mv	a4,s3
ffffffffc0204a0e:	07700793          	li	a5,119
    for (size_t i = 0; i < size; i++) {
ffffffffc0204a12:	0b700613          	li	a2,183
ffffffffc0204a16:	0257869b          	addiw	a3,a5,37
        bytes[i] = slub_test_pattern(i, seed);
ffffffffc0204a1a:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0204a1e:	0ff6f793          	zext.b	a5,a3
ffffffffc0204a22:	0705                	addi	a4,a4,1
ffffffffc0204a24:	fec799e3          	bne	a5,a2,ffffffffc0204a16 <slub_check+0x660>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0204a28:	854a                	mv	a0,s2
ffffffffc0204a2a:	deefe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204a2e:	6518                	ld	a4,8(a0)
ffffffffc0204a30:	4785                	li	a5,1
ffffffffc0204a32:	0ef700e3          	beq	a4,a5,ffffffffc0205312 <slub_check+0xf5c>
ffffffffc0204a36:	7d18                	ld	a4,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204a38:	47fd                	li	a5,31
ffffffffc0204a3a:	42e7fae3          	bgeu	a5,a4,ffffffffc020566e <slub_check+0x12b8>
ffffffffc0204a3e:	0aa00793          	li	a5,170
    for (size_t i = 0; i < size; i++) {
ffffffffc0204a42:	04a00693          	li	a3,74
        assert(bytes[i] == slub_test_pattern(i, seed));
ffffffffc0204a46:	000cc703          	lbu	a4,0(s9)
ffffffffc0204a4a:	14f719e3          	bne	a4,a5,ffffffffc020539c <slub_check+0xfe6>
    for (size_t i = 0; i < size; i++) {
ffffffffc0204a4e:	0257879b          	addiw	a5,a5,37
ffffffffc0204a52:	0ff7f793          	zext.b	a5,a5
ffffffffc0204a56:	0c85                	addi	s9,s9,1
ffffffffc0204a58:	fed797e3          	bne	a5,a3,ffffffffc0204a46 <slub_check+0x690>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0204a5c:	8526                	mv	a0,s1
ffffffffc0204a5e:	dbafe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204a62:	6518                	ld	a4,8(a0)
ffffffffc0204a64:	4785                	li	a5,1
ffffffffc0204a66:	0af702e3          	beq	a4,a5,ffffffffc020530a <slub_check+0xf54>
ffffffffc0204a6a:	7d18                	ld	a4,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204a6c:	07f00793          	li	a5,127
ffffffffc0204a70:	3ee7ffe3          	bgeu	a5,a4,ffffffffc020566e <slub_check+0x12b8>
ffffffffc0204a74:	0cc00793          	li	a5,204
    for (size_t i = 0; i < size; i++) {
ffffffffc0204a78:	04c00693          	li	a3,76
        assert(bytes[i] == slub_test_pattern(i, seed));
ffffffffc0204a7c:	000ac703          	lbu	a4,0(s5)
ffffffffc0204a80:	10f71ee3          	bne	a4,a5,ffffffffc020539c <slub_check+0xfe6>
    for (size_t i = 0; i < size; i++) {
ffffffffc0204a84:	0257879b          	addiw	a5,a5,37
ffffffffc0204a88:	0ff7f793          	zext.b	a5,a5
ffffffffc0204a8c:	0a85                	addi	s5,s5,1
ffffffffc0204a8e:	fed797e3          	bne	a5,a3,ffffffffc0204a7c <slub_check+0x6c6>
    if (ptr == NULL) {
ffffffffc0204a92:	8526                	mv	a0,s1
ffffffffc0204a94:	b5eff0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
ffffffffc0204a98:	854a                	mv	a0,s2
ffffffffc0204a9a:	b58ff0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
ffffffffc0204a9e:	854e                	mv	a0,s3
ffffffffc0204aa0:	b52ff0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
    slub_check_data_integrity();
    cprintf("slub_check: data_integrity passed\n");
ffffffffc0204aa4:	00003517          	auipc	a0,0x3
ffffffffc0204aa8:	5f450513          	addi	a0,a0,1524 # ffffffffc0208098 <buddy_pmm_manager+0xd70>
ffffffffc0204aac:	ea8fb0ef          	jal	ra,ffffffffc0200154 <cprintf>
    size_t before = nr_free_pages();
ffffffffc0204ab0:	9f8fe0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0204ab4:	e02a                	sd	a0,0(sp)
ffffffffc0204ab6:	00190497          	auipc	s1,0x190
ffffffffc0204aba:	f7a48493          	addi	s1,s1,-134 # ffffffffc0394a30 <test_objects>
    for (size_t i = 0; i < 4; i++) {
ffffffffc0204abe:	4c81                	li	s9,0
    size_t before = nr_free_pages();
ffffffffc0204ac0:	0a100d13          	li	s10,161
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204ac4:	4b05                	li	s6,1
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204ac6:	4afd                	li	s5,31
        assert(ROUNDDOWN((uintptr_t)test_objects[i], PGSIZE) ==
ffffffffc0204ac8:	797d                	lui	s2,0xfffff
    for (size_t i = 0; i < 4; i++) {
ffffffffc0204aca:	4991                	li	s3,4
    if (!initialized || size == 0) {
ffffffffc0204acc:	000a2783          	lw	a5,0(s4)
ffffffffc0204ad0:	000784e3          	beqz	a5,ffffffffc02052d8 <slub_check+0xf22>
ffffffffc0204ad4:	02000513          	li	a0,32
ffffffffc0204ad8:	858ff0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
        test_objects[i] = slub_alloc(32);
ffffffffc0204adc:	e088                	sd	a0,0(s1)
ffffffffc0204ade:	8daa                	mv	s11,a0
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204ae0:	000501e3          	beqz	a0,ffffffffc02052e2 <slub_check+0xf2c>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0204ae4:	d34fe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204ae8:	651c                	ld	a5,8(a0)
ffffffffc0204aea:	25678863          	beq	a5,s6,ffffffffc0204d3a <slub_check+0x984>
ffffffffc0204aee:	7d1c                	ld	a5,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204af0:	7efaf963          	bgeu	s5,a5,ffffffffc02052e2 <slub_check+0xf2c>
ffffffffc0204af4:	001c879b          	addiw	a5,s9,1
ffffffffc0204af8:	0ff7f793          	zext.b	a5,a5
ffffffffc0204afc:	876e                	mv	a4,s11
    for (size_t i = 0; i < size; i++) {
ffffffffc0204afe:	0257869b          	addiw	a3,a5,37
        bytes[i] = slub_test_pattern(i, seed);
ffffffffc0204b02:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0204b06:	0ff6f793          	zext.b	a5,a3
ffffffffc0204b0a:	0705                	addi	a4,a4,1
ffffffffc0204b0c:	fefd19e3          	bne	s10,a5,ffffffffc0204afe <slub_check+0x748>
        assert(ROUNDDOWN((uintptr_t)test_objects[i], PGSIZE) ==
ffffffffc0204b10:	000c3703          	ld	a4,0(s8)
ffffffffc0204b14:	012df633          	and	a2,s11,s2
ffffffffc0204b18:	01277733          	and	a4,a4,s2
ffffffffc0204b1c:	42e619e3          	bne	a2,a4,ffffffffc020574e <slub_check+0x1398>
    for (size_t i = 0; i < 4; i++) {
ffffffffc0204b20:	2d05                	addiw	s10,s10,1
ffffffffc0204b22:	0c85                	addi	s9,s9,1
ffffffffc0204b24:	0ffd7d13          	zext.b	s10,s10
ffffffffc0204b28:	04a1                	addi	s1,s1,8
ffffffffc0204b2a:	fb3c91e3          	bne	s9,s3,ffffffffc0204acc <slub_check+0x716>
    size_t occupied = nr_free_pages();
ffffffffc0204b2e:	97afe0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
    void *released = test_objects[1];
ffffffffc0204b32:	008c3903          	ld	s2,8(s8)
    size_t occupied = nr_free_pages();
ffffffffc0204b36:	84aa                	mv	s1,a0
    if (ptr == NULL) {
ffffffffc0204b38:	00090563          	beqz	s2,ffffffffc0204b42 <slub_check+0x78c>
ffffffffc0204b3c:	854a                	mv	a0,s2
ffffffffc0204b3e:	ab4ff0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
    assert(nr_free_pages() == occupied);
ffffffffc0204b42:	966fe0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0204b46:	3ea494e3          	bne	s1,a0,ffffffffc020572e <slub_check+0x1378>
    if (!initialized || size == 0) {
ffffffffc0204b4a:	000a2783          	lw	a5,0(s4)
ffffffffc0204b4e:	060787e3          	beqz	a5,ffffffffc02053bc <slub_check+0x1006>
ffffffffc0204b52:	02000513          	li	a0,32
ffffffffc0204b56:	fdbfe0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
    test_objects[1] = slub_alloc(32);
ffffffffc0204b5a:	00ac3423          	sd	a0,8(s8)
    assert(test_objects[1] == released && nr_free_pages() == occupied);
ffffffffc0204b5e:	2ea918e3          	bne	s2,a0,ffffffffc020564e <slub_check+0x1298>
ffffffffc0204b62:	946fe0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0204b66:	2ea494e3          	bne	s1,a0,ffffffffc020564e <slub_check+0x1298>
    slub_test_fill(test_objects[1], 32, 2);
ffffffffc0204b6a:	008c3483          	ld	s1,8(s8)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204b6e:	76048a63          	beqz	s1,ffffffffc02052e2 <slub_check+0xf2c>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0204b72:	8526                	mv	a0,s1
ffffffffc0204b74:	ca4fe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204b78:	6518                	ld	a4,8(a0)
ffffffffc0204b7a:	4785                	li	a5,1
ffffffffc0204b7c:	78f70363          	beq	a4,a5,ffffffffc0205302 <slub_check+0xf4c>
ffffffffc0204b80:	7d18                	ld	a4,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204b82:	47fd                	li	a5,31
ffffffffc0204b84:	74e7ff63          	bgeu	a5,a4,ffffffffc02052e2 <slub_check+0xf2c>
ffffffffc0204b88:	8726                	mv	a4,s1
ffffffffc0204b8a:	4789                	li	a5,2
    for (size_t i = 0; i < size; i++) {
ffffffffc0204b8c:	0a200613          	li	a2,162
ffffffffc0204b90:	0257869b          	addiw	a3,a5,37
        bytes[i] = slub_test_pattern(i, seed);
ffffffffc0204b94:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0204b98:	0ff6f793          	zext.b	a5,a3
ffffffffc0204b9c:	0705                	addi	a4,a4,1
ffffffffc0204b9e:	fec799e3          	bne	a5,a2,ffffffffc0204b90 <slub_check+0x7da>
ffffffffc0204ba2:	00190917          	auipc	s2,0x190
ffffffffc0204ba6:	e8e90913          	addi	s2,s2,-370 # ffffffffc0394a30 <test_objects>
ffffffffc0204baa:	0a100d13          	li	s10,161
ffffffffc0204bae:	4c85                	li	s9,1
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204bb0:	4b05                	li	s6,1
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204bb2:	4afd                	li	s5,31
    for (size_t i = 0; i < 4; i++) {
ffffffffc0204bb4:	4995                	li	s3,5
        slub_test_verify(test_objects[i], 32, i + 1);
ffffffffc0204bb6:	00093d83          	ld	s11,0(s2)
ffffffffc0204bba:	0ffcf493          	zext.b	s1,s9
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204bbe:	2a0d88e3          	beqz	s11,ffffffffc020566e <slub_check+0x12b8>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0204bc2:	856e                	mv	a0,s11
ffffffffc0204bc4:	c54fe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204bc8:	651c                	ld	a5,8(a0)
ffffffffc0204bca:	17678b63          	beq	a5,s6,ffffffffc0204d40 <slub_check+0x98a>
ffffffffc0204bce:	7d1c                	ld	a5,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204bd0:	28faffe3          	bgeu	s5,a5,ffffffffc020566e <slub_check+0x12b8>
ffffffffc0204bd4:	87ee                	mv	a5,s11
        assert(bytes[i] == slub_test_pattern(i, seed));
ffffffffc0204bd6:	0007c703          	lbu	a4,0(a5)
ffffffffc0204bda:	7c971163          	bne	a4,s1,ffffffffc020539c <slub_check+0xfe6>
    for (size_t i = 0; i < size; i++) {
ffffffffc0204bde:	0254849b          	addiw	s1,s1,37
ffffffffc0204be2:	0ff4f493          	zext.b	s1,s1
ffffffffc0204be6:	0785                	addi	a5,a5,1
ffffffffc0204be8:	fe9d17e3          	bne	s10,s1,ffffffffc0204bd6 <slub_check+0x820>
    if (ptr == NULL) {
ffffffffc0204bec:	856e                	mv	a0,s11
    for (size_t i = 0; i < 4; i++) {
ffffffffc0204bee:	2d05                	addiw	s10,s10,1
ffffffffc0204bf0:	0c85                	addi	s9,s9,1
ffffffffc0204bf2:	a00ff0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
ffffffffc0204bf6:	0921                	addi	s2,s2,8
ffffffffc0204bf8:	0ffd7d13          	zext.b	s10,s10
ffffffffc0204bfc:	fb3c9de3          	bne	s9,s3,ffffffffc0204bb6 <slub_check+0x800>
    assert(nr_free_pages() == before);
ffffffffc0204c00:	8a8fe0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0204c04:	6782                	ld	a5,0(sp)
ffffffffc0204c06:	22a794e3          	bne	a5,a0,ffffffffc020562e <slub_check+0x1278>
    slub_check_reuse();
    cprintf("slub_check: reuse passed\n");
ffffffffc0204c0a:	00003517          	auipc	a0,0x3
ffffffffc0204c0e:	57650513          	addi	a0,a0,1398 # ffffffffc0208180 <buddy_pmm_manager+0xe58>
ffffffffc0204c12:	d42fb0ef          	jal	ra,ffffffffc0200154 <cprintf>
    size_t total = (PGSIZE - SLUB_DATA_OFFSET) / cache->object_size;
ffffffffc0204c16:	00188d17          	auipc	s10,0x188
ffffffffc0204c1a:	c4ad0d13          	addi	s10,s10,-950 # ffffffffc038c860 <caches>
ffffffffc0204c1e:	038d3783          	ld	a5,56(s10)
ffffffffc0204c22:	6985                	lui	s3,0x1
ffffffffc0204c24:	f8098993          	addi	s3,s3,-128 # f80 <kern_entry-0xffffffffc01ff080>
ffffffffc0204c28:	02f9d9b3          	divu	s3,s3,a5
    assert(count <= sizeof(test_objects) / sizeof(test_objects[0]));
ffffffffc0204c2c:	20100793          	li	a5,513
    size_t count = 2 * total + 1;
ffffffffc0204c30:	00199b13          	slli	s6,s3,0x1
ffffffffc0204c34:	001b0713          	addi	a4,s6,1
    assert(count <= sizeof(test_objects) / sizeof(test_objects[0]));
ffffffffc0204c38:	0ee7e7e3          	bltu	a5,a4,ffffffffc0205526 <slub_check+0x1170>
    size_t before = nr_free_pages();
ffffffffc0204c3c:	86cfe0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
    if (!initialized || size == 0) {
ffffffffc0204c40:	000a2783          	lw	a5,0(s4)
    size_t before = nr_free_pages();
ffffffffc0204c44:	e02a                	sd	a0,0(sp)
ffffffffc0204c46:	00190497          	auipc	s1,0x190
ffffffffc0204c4a:	dea48493          	addi	s1,s1,-534 # ffffffffc0394a30 <test_objects>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204c4e:	4a85                	li	s5,1
    if (!initialized || size == 0) {
ffffffffc0204c50:	cbb5                	beqz	a5,ffffffffc0204cc4 <slub_check+0x90e>
ffffffffc0204c52:	02000513          	li	a0,32
ffffffffc0204c56:	edbfe0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
        test_objects[i] = slub_alloc(32);
ffffffffc0204c5a:	e088                	sd	a0,0(s1)
ffffffffc0204c5c:	8caa                	mv	s9,a0
        assert(test_objects[i] != NULL && ((uintptr_t)test_objects[i] & 15) == 0);
ffffffffc0204c5e:	c53d                	beqz	a0,ffffffffc0204ccc <slub_check+0x916>
ffffffffc0204c60:	00f57913          	andi	s2,a0,15
ffffffffc0204c64:	8daa                	mv	s11,a0
ffffffffc0204c66:	06091363          	bnez	s2,ffffffffc0204ccc <slub_check+0x916>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0204c6a:	baefe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204c6e:	6518                	ld	a4,8(a0)
ffffffffc0204c70:	07570e63          	beq	a4,s5,ffffffffc0204cec <slub_check+0x936>
ffffffffc0204c74:	7d18                	ld	a4,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204c76:	47fd                	li	a5,31
ffffffffc0204c78:	66e7f563          	bgeu	a5,a4,ffffffffc02052e2 <slub_check+0xf2c>
ffffffffc0204c7c:	0ff47713          	zext.b	a4,s0
ffffffffc0204c80:	fa07061b          	addiw	a2,a4,-96
    for (size_t i = 0; i < size; i++) {
ffffffffc0204c84:	0ff67613          	zext.b	a2,a2
ffffffffc0204c88:	0257059b          	addiw	a1,a4,37
        bytes[i] = slub_test_pattern(i, seed);
ffffffffc0204c8c:	00ed8023          	sb	a4,0(s11)
    for (size_t i = 0; i < size; i++) {
ffffffffc0204c90:	0ff5f713          	zext.b	a4,a1
ffffffffc0204c94:	0d85                	addi	s11,s11,1
ffffffffc0204c96:	fee619e3          	bne	a2,a4,ffffffffc0204c88 <slub_check+0x8d2>
        for (size_t j = 0; j < i; j++) {
ffffffffc0204c9a:	c811                	beqz	s0,ffffffffc0204cae <slub_check+0x8f8>
ffffffffc0204c9c:	8dde                	mv	s11,s7
            slub_test_disjoint(test_objects[i], test_objects[j]);
ffffffffc0204c9e:	000db583          	ld	a1,0(s11)
ffffffffc0204ca2:	8566                	mv	a0,s9
        for (size_t j = 0; j < i; j++) {
ffffffffc0204ca4:	0da1                	addi	s11,s11,8
            slub_test_disjoint(test_objects[i], test_objects[j]);
ffffffffc0204ca6:	a8aff0ef          	jal	ra,ffffffffc0203f30 <slub_test_disjoint>
        for (size_t j = 0; j < i; j++) {
ffffffffc0204caa:	ffb49ae3          	bne	s1,s11,ffffffffc0204c9e <slub_check+0x8e8>
        if (i + 1 == total) {
ffffffffc0204cae:	00140793          	addi	a5,s0,1
ffffffffc0204cb2:	04f98063          	beq	s3,a5,ffffffffc0204cf2 <slub_check+0x93c>
    for (size_t i = 0; i < count; i++) {
ffffffffc0204cb6:	04a1                	addi	s1,s1,8
ffffffffc0204cb8:	088b0763          	beq	s6,s0,ffffffffc0204d46 <slub_check+0x990>
ffffffffc0204cbc:	843e                	mv	s0,a5
    if (!initialized || size == 0) {
ffffffffc0204cbe:	000a2783          	lw	a5,0(s4)
ffffffffc0204cc2:	fbc1                	bnez	a5,ffffffffc0204c52 <slub_check+0x89c>
        test_objects[i] = slub_alloc(32);
ffffffffc0204cc4:	040e                	slli	s0,s0,0x3
ffffffffc0204cc6:	9c22                	add	s8,s8,s0
ffffffffc0204cc8:	000c3023          	sd	zero,0(s8)
        assert(test_objects[i] != NULL && ((uintptr_t)test_objects[i] & 15) == 0);
ffffffffc0204ccc:	00003697          	auipc	a3,0x3
ffffffffc0204cd0:	50c68693          	addi	a3,a3,1292 # ffffffffc02081d8 <buddy_pmm_manager+0xeb0>
ffffffffc0204cd4:	00001617          	auipc	a2,0x1
ffffffffc0204cd8:	2dc60613          	addi	a2,a2,732 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0204cdc:	21800593          	li	a1,536
ffffffffc0204ce0:	00003517          	auipc	a0,0x3
ffffffffc0204ce4:	8b850513          	addi	a0,a0,-1864 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0204ce8:	ce2fb0ef          	jal	ra,ffffffffc02001ca <__panic>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204cec:	6d18                	ld	a4,24(a0)
ffffffffc0204cee:	6318                	ld	a4,0(a4)
ffffffffc0204cf0:	b759                	j	ffffffffc0204c76 <slub_check+0x8c0>
            assert(cache->slabs == 1 && list_empty(&cache->partial));
ffffffffc0204cf2:	060d3703          	ld	a4,96(s10)
ffffffffc0204cf6:	1d571ce3          	bne	a4,s5,ffffffffc02056ce <slub_check+0x1318>
ffffffffc0204cfa:	048d3703          	ld	a4,72(s10)
ffffffffc0204cfe:	00188697          	auipc	a3,0x188
ffffffffc0204d02:	ba268693          	addi	a3,a3,-1118 # ffffffffc038c8a0 <caches+0x40>
ffffffffc0204d06:	1cd714e3          	bne	a4,a3,ffffffffc02056ce <slub_check+0x1318>
            assert(!list_empty(&cache->full));
ffffffffc0204d0a:	058d3703          	ld	a4,88(s10)
ffffffffc0204d0e:	00188697          	auipc	a3,0x188
ffffffffc0204d12:	ba268693          	addi	a3,a3,-1118 # ffffffffc038c8b0 <caches+0x50>
ffffffffc0204d16:	fad710e3          	bne	a4,a3,ffffffffc0204cb6 <slub_check+0x900>
ffffffffc0204d1a:	00003697          	auipc	a3,0x3
ffffffffc0204d1e:	53e68693          	addi	a3,a3,1342 # ffffffffc0208258 <buddy_pmm_manager+0xf30>
ffffffffc0204d22:	00001617          	auipc	a2,0x1
ffffffffc0204d26:	28e60613          	addi	a2,a2,654 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0204d2a:	21f00593          	li	a1,543
ffffffffc0204d2e:	00003517          	auipc	a0,0x3
ffffffffc0204d32:	86a50513          	addi	a0,a0,-1942 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0204d36:	c94fb0ef          	jal	ra,ffffffffc02001ca <__panic>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204d3a:	6d1c                	ld	a5,24(a0)
ffffffffc0204d3c:	639c                	ld	a5,0(a5)
ffffffffc0204d3e:	bb4d                	j	ffffffffc0204af0 <slub_check+0x73a>
ffffffffc0204d40:	6d1c                	ld	a5,24(a0)
ffffffffc0204d42:	639c                	ld	a5,0(a5)
ffffffffc0204d44:	b571                	j	ffffffffc0204bd0 <slub_check+0x81a>
    assert(cache->slabs == 3 && nr_free_pages() == before - 3);
ffffffffc0204d46:	060d3703          	ld	a4,96(s10)
ffffffffc0204d4a:	478d                	li	a5,3
ffffffffc0204d4c:	7af71d63          	bne	a4,a5,ffffffffc0205506 <slub_check+0x1150>
ffffffffc0204d50:	f59fd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0204d54:	6782                	ld	a5,0(sp)
ffffffffc0204d56:	ffd78493          	addi	s1,a5,-3
ffffffffc0204d5a:	7a951663          	bne	a0,s1,ffffffffc0205506 <slub_check+0x1150>
    size_t index = total / 2;
ffffffffc0204d5e:	0019d993          	srli	s3,s3,0x1
    void *released = test_objects[index];
ffffffffc0204d62:	00399413          	slli	s0,s3,0x3
ffffffffc0204d66:	008c07b3          	add	a5,s8,s0
ffffffffc0204d6a:	0007ba83          	ld	s5,0(a5)
    if (ptr == NULL) {
ffffffffc0204d6e:	000a8563          	beqz	s5,ffffffffc0204d78 <slub_check+0x9c2>
ffffffffc0204d72:	8556                	mv	a0,s5
ffffffffc0204d74:	87eff0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
    assert(cache->slabs == 3 && nr_free_pages() == before - 3);
ffffffffc0204d78:	060d3703          	ld	a4,96(s10)
ffffffffc0204d7c:	478d                	li	a5,3
ffffffffc0204d7e:	76f71463          	bne	a4,a5,ffffffffc02054e6 <slub_check+0x1130>
ffffffffc0204d82:	f27fd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0204d86:	76a49063          	bne	s1,a0,ffffffffc02054e6 <slub_check+0x1130>
    if (!initialized || size == 0) {
ffffffffc0204d8a:	000a2783          	lw	a5,0(s4)
ffffffffc0204d8e:	62078a63          	beqz	a5,ffffffffc02053c2 <slub_check+0x100c>
ffffffffc0204d92:	02000513          	li	a0,32
ffffffffc0204d96:	d9bfe0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
ffffffffc0204d9a:	87aa                	mv	a5,a0
    test_objects[index] = slub_alloc(32);
ffffffffc0204d9c:	9462                	add	s0,s0,s8
ffffffffc0204d9e:	e01c                	sd	a5,0(s0)
    assert(test_objects[index] == released && nr_free_pages() == before - 3);
ffffffffc0204da0:	72fa9363          	bne	s5,a5,ffffffffc02054c6 <slub_check+0x1110>
ffffffffc0204da4:	f05fd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0204da8:	70a49f63          	bne	s1,a0,ffffffffc02054c6 <slub_check+0x1110>
    slub_test_fill(test_objects[index], 32, index);
ffffffffc0204dac:	6000                	ld	s0,0(s0)
ffffffffc0204dae:	0ff9f993          	zext.b	s3,s3
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204db2:	52040863          	beqz	s0,ffffffffc02052e2 <slub_check+0xf2c>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0204db6:	8522                	mv	a0,s0
ffffffffc0204db8:	a60fe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204dbc:	6518                	ld	a4,8(a0)
ffffffffc0204dbe:	4785                	li	a5,1
ffffffffc0204dc0:	5af70163          	beq	a4,a5,ffffffffc0205362 <slub_check+0xfac>
ffffffffc0204dc4:	7d18                	ld	a4,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204dc6:	47fd                	li	a5,31
ffffffffc0204dc8:	50e7fd63          	bgeu	a5,a4,ffffffffc02052e2 <slub_check+0xf2c>
ffffffffc0204dcc:	fa09869b          	addiw	a3,s3,-96
ffffffffc0204dd0:	87a2                	mv	a5,s0
ffffffffc0204dd2:	0ff6f693          	zext.b	a3,a3
    for (size_t i = 0; i < size; i++) {
ffffffffc0204dd6:	0259871b          	addiw	a4,s3,37
        bytes[i] = slub_test_pattern(i, seed);
ffffffffc0204dda:	01378023          	sb	s3,0(a5)
    for (size_t i = 0; i < size; i++) {
ffffffffc0204dde:	0ff77993          	zext.b	s3,a4
ffffffffc0204de2:	0785                	addi	a5,a5,1
ffffffffc0204de4:	ff3699e3          	bne	a3,s3,ffffffffc0204dd6 <slub_check+0xa20>
    assert(initialized);
ffffffffc0204de8:	000a2783          	lw	a5,0(s4)
ffffffffc0204dec:	120781e3          	beqz	a5,ffffffffc020570e <slub_check+0x1358>
    memset(checked_frames, 0, sizeof(checked_frames));
ffffffffc0204df0:	6621                	lui	a2,0x8
ffffffffc0204df2:	4581                	li	a1,0
ffffffffc0204df4:	00188517          	auipc	a0,0x188
ffffffffc0204df8:	c2c50513          	addi	a0,a0,-980 # ffffffffc038ca20 <checked_frames>
ffffffffc0204dfc:	71b000ef          	jal	ra,ffffffffc0205d16 <memset>
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
ffffffffc0204e00:	df6fe0ef          	jal	ra,ffffffffc02033f6 <slub_check_invariants.part.0>
    for (size_t i = 0; i < count; i++) {
ffffffffc0204e04:	00190417          	auipc	s0,0x190
ffffffffc0204e08:	c2c40413          	addi	s0,s0,-980 # ffffffffc0394a30 <test_objects>
ffffffffc0204e0c:	0a000c93          	li	s9,160
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204e10:	4985                	li	s3,1
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204e12:	4dfd                	li	s11,31
        slub_test_verify(test_objects[i], 32, i);
ffffffffc0204e14:	6004                	ld	s1,0(s0)
ffffffffc0204e16:	0ff97a93          	zext.b	s5,s2
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204e1a:	04048ae3          	beqz	s1,ffffffffc020566e <slub_check+0x12b8>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc0204e1e:	8526                	mv	a0,s1
ffffffffc0204e20:	9f8fe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204e24:	651c                	ld	a5,8(a0)
ffffffffc0204e26:	03378e63          	beq	a5,s3,ffffffffc0204e62 <slub_check+0xaac>
ffffffffc0204e2a:	7d1c                	ld	a5,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc0204e2c:	04fdf1e3          	bgeu	s11,a5,ffffffffc020566e <slub_check+0x12b8>
ffffffffc0204e30:	87a6                	mv	a5,s1
        assert(bytes[i] == slub_test_pattern(i, seed));
ffffffffc0204e32:	0007c703          	lbu	a4,0(a5)
ffffffffc0204e36:	57571363          	bne	a4,s5,ffffffffc020539c <slub_check+0xfe6>
    for (size_t i = 0; i < size; i++) {
ffffffffc0204e3a:	025a8a9b          	addiw	s5,s5,37
ffffffffc0204e3e:	0ffafa93          	zext.b	s5,s5
ffffffffc0204e42:	0785                	addi	a5,a5,1
ffffffffc0204e44:	ff5c97e3          	bne	s9,s5,ffffffffc0204e32 <slub_check+0xa7c>
    if (ptr == NULL) {
ffffffffc0204e48:	8526                	mv	a0,s1
ffffffffc0204e4a:	fa9fe0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
    for (size_t i = 0; i < count; i++) {
ffffffffc0204e4e:	2c85                	addiw	s9,s9,1
ffffffffc0204e50:	00190793          	addi	a5,s2,1
ffffffffc0204e54:	0421                	addi	s0,s0,8
ffffffffc0204e56:	0ffcfc93          	zext.b	s9,s9
ffffffffc0204e5a:	012b0763          	beq	s6,s2,ffffffffc0204e68 <slub_check+0xab2>
ffffffffc0204e5e:	893e                	mv	s2,a5
ffffffffc0204e60:	bf55                	j	ffffffffc0204e14 <slub_check+0xa5e>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0204e62:	6d1c                	ld	a5,24(a0)
ffffffffc0204e64:	639c                	ld	a5,0(a5)
ffffffffc0204e66:	b7d9                	j	ffffffffc0204e2c <slub_check+0xa76>
    assert(cache->slabs == 0 && nr_free_pages() == before);
ffffffffc0204e68:	060d3983          	ld	s3,96(s10)
ffffffffc0204e6c:	180994e3          	bnez	s3,ffffffffc02057f4 <slub_check+0x143e>
ffffffffc0204e70:	e39fd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0204e74:	6782                	ld	a5,0(sp)
ffffffffc0204e76:	16a79fe3          	bne	a5,a0,ffffffffc02057f4 <slub_check+0x143e>
    slub_check_multi_slab();
    cprintf("slub_check: multi_slab passed\n");
ffffffffc0204e7a:	00003517          	auipc	a0,0x3
ffffffffc0204e7e:	4ae50513          	addi	a0,a0,1198 # ffffffffc0208328 <buddy_pmm_manager+0x1000>
ffffffffc0204e82:	ad2fb0ef          	jal	ra,ffffffffc0200154 <cprintf>
    const size_t requests[] = {2049, 3000, 4096, 4097, 5000, 8192};
ffffffffc0204e86:	00003797          	auipc	a5,0x3
ffffffffc0204e8a:	74278793          	addi	a5,a5,1858 # ffffffffc02085c8 <buddy_pmm_manager+0x12a0>
ffffffffc0204e8e:	1a07b503          	ld	a0,416(a5)
ffffffffc0204e92:	1a87b583          	ld	a1,424(a5)
ffffffffc0204e96:	1b07b603          	ld	a2,432(a5)
ffffffffc0204e9a:	1b87b683          	ld	a3,440(a5)
ffffffffc0204e9e:	1c07b703          	ld	a4,448(a5)
ffffffffc0204ea2:	1c87b783          	ld	a5,456(a5)
ffffffffc0204ea6:	fc2a                	sd	a0,56(sp)
ffffffffc0204ea8:	e0ae                	sd	a1,64(sp)
ffffffffc0204eaa:	f0be                	sd	a5,96(sp)
ffffffffc0204eac:	e4b2                	sd	a2,72(sp)
ffffffffc0204eae:	e8b6                	sd	a3,80(sp)
ffffffffc0204eb0:	ecba                	sd	a4,88(sp)
    size_t before = nr_free_pages();
ffffffffc0204eb2:	df7fd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
    if (!initialized || size == 0) {
ffffffffc0204eb6:	000a2783          	lw	a5,0(s4)
ffffffffc0204eba:	03810a93          	addi	s5,sp,56
    size_t before = nr_free_pages();
ffffffffc0204ebe:	8b56                	mv	s6,s5
ffffffffc0204ec0:	e02a                	sd	a0,0(sp)
        test_objects[i] = slub_alloc(requests[i]);
ffffffffc0204ec2:	000b3c83          	ld	s9,0(s6)
    size_t before = nr_free_pages();
ffffffffc0204ec6:	00190497          	auipc	s1,0x190
ffffffffc0204eca:	b6a48493          	addi	s1,s1,-1174 # ffffffffc0394a30 <test_objects>
        assert(slab->kind == SLUB_LARGE);
ffffffffc0204ece:	4d09                	li	s10,2
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
ffffffffc0204ed0:	4d99                	li	s11,6
    if (!initialized || size == 0) {
ffffffffc0204ed2:	cbbd                	beqz	a5,ffffffffc0204f48 <slub_check+0xb92>
ffffffffc0204ed4:	060c8a63          	beqz	s9,ffffffffc0204f48 <slub_check+0xb92>
ffffffffc0204ed8:	8566                	mv	a0,s9
ffffffffc0204eda:	c57fe0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
        test_objects[i] = slub_alloc(requests[i]);
ffffffffc0204ede:	e088                	sd	a0,0(s1)
ffffffffc0204ee0:	842a                	mv	s0,a0
        assert(test_objects[i] != NULL && ((uintptr_t)test_objects[i] & 15) == 0);
ffffffffc0204ee2:	c53d                	beqz	a0,ffffffffc0204f50 <slub_check+0xb9a>
ffffffffc0204ee4:	00f57913          	andi	s2,a0,15
ffffffffc0204ee8:	06091463          	bnez	s2,ffffffffc0204f50 <slub_check+0xb9a>
        struct slub_slab *slab = slub_lookup(test_objects[i]);
ffffffffc0204eec:	92cfe0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
        assert(slab->kind == SLUB_LARGE);
ffffffffc0204ef0:	651c                	ld	a5,8(a0)
ffffffffc0204ef2:	69a79a63          	bne	a5,s10,ffffffffc0205586 <slub_check+0x11d0>
        assert(slab->npages == (requests[i] + SLUB_DATA_OFFSET - 1) / PGSIZE + 1);
ffffffffc0204ef6:	07fc8793          	addi	a5,s9,127
ffffffffc0204efa:	7918                	ld	a4,48(a0)
ffffffffc0204efc:	83b1                	srli	a5,a5,0xc
ffffffffc0204efe:	0785                	addi	a5,a5,1
ffffffffc0204f00:	66f71363          	bne	a4,a5,ffffffffc0205566 <slub_check+0x11b0>
        assert(slub_usable_size(test_objects[i]) >= requests[i]);
ffffffffc0204f04:	7d1c                	ld	a5,56(a0)
ffffffffc0204f06:	6597e063          	bltu	a5,s9,ffffffffc0205546 <slub_check+0x1190>
        slub_test_fill(test_objects[i], requests[i], i + 10);
ffffffffc0204f0a:	00a9861b          	addiw	a2,s3,10
ffffffffc0204f0e:	85e6                	mv	a1,s9
ffffffffc0204f10:	0ff67613          	zext.b	a2,a2
ffffffffc0204f14:	8522                	mv	a0,s0
ffffffffc0204f16:	fa9fe0ef          	jal	ra,ffffffffc0203ebe <slub_test_fill>
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
ffffffffc0204f1a:	00198c93          	addi	s9,s3,1
        for (size_t j = 0; j < i; j++) {
ffffffffc0204f1e:	00098d63          	beqz	s3,ffffffffc0204f38 <slub_check+0xb82>
ffffffffc0204f22:	89de                	mv	s3,s7
            slub_test_disjoint(test_objects[i], test_objects[j]);
ffffffffc0204f24:	0009b583          	ld	a1,0(s3)
ffffffffc0204f28:	8522                	mv	a0,s0
        for (size_t j = 0; j < i; j++) {
ffffffffc0204f2a:	09a1                	addi	s3,s3,8
            slub_test_disjoint(test_objects[i], test_objects[j]);
ffffffffc0204f2c:	804ff0ef          	jal	ra,ffffffffc0203f30 <slub_test_disjoint>
        for (size_t j = 0; j < i; j++) {
ffffffffc0204f30:	ff349ae3          	bne	s1,s3,ffffffffc0204f24 <slub_check+0xb6e>
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
ffffffffc0204f34:	03bc8e63          	beq	s9,s11,ffffffffc0204f70 <slub_check+0xbba>
    if (!initialized || size == 0) {
ffffffffc0204f38:	000a2783          	lw	a5,0(s4)
ffffffffc0204f3c:	0b21                	addi	s6,s6,8
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
ffffffffc0204f3e:	89e6                	mv	s3,s9
ffffffffc0204f40:	04a1                	addi	s1,s1,8
        test_objects[i] = slub_alloc(requests[i]);
ffffffffc0204f42:	000b3c83          	ld	s9,0(s6)
    if (!initialized || size == 0) {
ffffffffc0204f46:	f7d9                	bnez	a5,ffffffffc0204ed4 <slub_check+0xb1e>
        test_objects[i] = slub_alloc(requests[i]);
ffffffffc0204f48:	098e                	slli	s3,s3,0x3
ffffffffc0204f4a:	9c4e                	add	s8,s8,s3
ffffffffc0204f4c:	000c3023          	sd	zero,0(s8)
        assert(test_objects[i] != NULL && ((uintptr_t)test_objects[i] & 15) == 0);
ffffffffc0204f50:	00003697          	auipc	a3,0x3
ffffffffc0204f54:	28868693          	addi	a3,a3,648 # ffffffffc02081d8 <buddy_pmm_manager+0xeb0>
ffffffffc0204f58:	00001617          	auipc	a2,0x1
ffffffffc0204f5c:	05860613          	addi	a2,a2,88 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0204f60:	23800593          	li	a1,568
ffffffffc0204f64:	00002517          	auipc	a0,0x2
ffffffffc0204f68:	63450513          	addi	a0,a0,1588 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0204f6c:	a5efb0ef          	jal	ra,ffffffffc02001ca <__panic>
    unsigned char *cross = test_objects[4];
ffffffffc0204f70:	020c3503          	ld	a0,32(s8)
    const size_t positions[] = {0, 4095, 4096, 4999};
ffffffffc0204f74:	6785                	lui	a5,0x1
        cross[positions[i]] = 0xE0 + i;
ffffffffc0204f76:	5701                	li	a4,-32
ffffffffc0204f78:	00e50023          	sb	a4,0(a0)
    const size_t positions[] = {0, 4095, 4096, 4999};
ffffffffc0204f7c:	fff78613          	addi	a2,a5,-1 # fff <kern_entry-0xffffffffc01ff001>
        cross[positions[i]] = 0xE0 + i;
ffffffffc0204f80:	00f50733          	add	a4,a0,a5
    const size_t positions[] = {0, 4095, 4096, 4999};
ffffffffc0204f84:	38778693          	addi	a3,a5,903
ffffffffc0204f88:	f43e                	sd	a5,40(sp)
        cross[positions[i]] = 0xE0 + i;
ffffffffc0204f8a:	5785                	li	a5,-31
ffffffffc0204f8c:	fef70fa3          	sb	a5,-1(a4)
ffffffffc0204f90:	5789                	li	a5,-30
ffffffffc0204f92:	00f70023          	sb	a5,0(a4)
ffffffffc0204f96:	578d                	li	a5,-29
ffffffffc0204f98:	38f703a3          	sb	a5,903(a4)
ffffffffc0204f9c:	4701                	li	a4,0
        assert(cross[positions[i]] == 0xE0 + i);
ffffffffc0204f9e:	00e505b3          	add	a1,a0,a4
ffffffffc0204fa2:	0005c783          	lbu	a5,0(a1)
    const size_t positions[] = {0, 4095, 4096, 4999};
ffffffffc0204fa6:	f032                	sd	a2,32(sp)
ffffffffc0204fa8:	f836                	sd	a3,48(sp)
        cross[positions[i]] = 0xE0 + i;
ffffffffc0204faa:	0e000693          	li	a3,224
ffffffffc0204fae:	0830                	addi	a2,sp,24
    for (size_t i = 0; i < sizeof(positions) / sizeof(positions[0]); i++) {
ffffffffc0204fb0:	0e300813          	li	a6,227
        assert(cross[positions[i]] == 0xE0 + i);
ffffffffc0204fb4:	02d79663          	bne	a5,a3,ffffffffc0204fe0 <slub_check+0xc2a>
    return (unsigned char)(seed + index * 37);
ffffffffc0204fb8:	0037179b          	slliw	a5,a4,0x3
ffffffffc0204fbc:	9fb9                	addw	a5,a5,a4
ffffffffc0204fbe:	0027979b          	slliw	a5,a5,0x2
ffffffffc0204fc2:	9fb9                	addw	a5,a5,a4
ffffffffc0204fc4:	27b9                	addiw	a5,a5,14
        cross[positions[i]] = slub_test_pattern(positions[i], 14);
ffffffffc0204fc6:	00f58023          	sb	a5,0(a1)
    for (size_t i = 0; i < sizeof(positions) / sizeof(positions[0]); i++) {
ffffffffc0204fca:	0621                	addi	a2,a2,8
ffffffffc0204fcc:	03068a63          	beq	a3,a6,ffffffffc0205000 <slub_check+0xc4a>
        assert(cross[positions[i]] == 0xE0 + i);
ffffffffc0204fd0:	6218                	ld	a4,0(a2)
ffffffffc0204fd2:	0685                	addi	a3,a3,1
ffffffffc0204fd4:	00e505b3          	add	a1,a0,a4
ffffffffc0204fd8:	0005c783          	lbu	a5,0(a1)
ffffffffc0204fdc:	fcd78ee3          	beq	a5,a3,ffffffffc0204fb8 <slub_check+0xc02>
ffffffffc0204fe0:	00003697          	auipc	a3,0x3
ffffffffc0204fe4:	3e868693          	addi	a3,a3,1000 # ffffffffc02083c8 <buddy_pmm_manager+0x10a0>
ffffffffc0204fe8:	00001617          	auipc	a2,0x1
ffffffffc0204fec:	fc860613          	addi	a2,a2,-56 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0204ff0:	24800593          	li	a1,584
ffffffffc0204ff4:	00002517          	auipc	a0,0x2
ffffffffc0204ff8:	5a450513          	addi	a0,a0,1444 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0204ffc:	9cefb0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(initialized);
ffffffffc0205000:	000a2783          	lw	a5,0(s4)
ffffffffc0205004:	70078563          	beqz	a5,ffffffffc020570e <slub_check+0x1358>
    memset(checked_frames, 0, sizeof(checked_frames));
ffffffffc0205008:	6621                	lui	a2,0x8
ffffffffc020500a:	4581                	li	a1,0
ffffffffc020500c:	00188517          	auipc	a0,0x188
ffffffffc0205010:	a1450513          	addi	a0,a0,-1516 # ffffffffc038ca20 <checked_frames>
ffffffffc0205014:	503000ef          	jal	ra,ffffffffc0205d16 <memset>
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
ffffffffc0205018:	bdefe0ef          	jal	ra,ffffffffc02033f6 <slub_check_invariants.part.0>
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
ffffffffc020501c:	00190997          	auipc	s3,0x190
ffffffffc0205020:	a1498993          	addi	s3,s3,-1516 # ffffffffc0394a30 <test_objects>
ffffffffc0205024:	4429                	li	s0,10
ffffffffc0205026:	4b41                	li	s6,16
        slub_test_verify(test_objects[i], requests[i], i + 10);
ffffffffc0205028:	0009b483          	ld	s1,0(s3)
ffffffffc020502c:	000ab583          	ld	a1,0(s5)
ffffffffc0205030:	8622                	mv	a2,s0
ffffffffc0205032:	8526                	mv	a0,s1
ffffffffc0205034:	f91fe0ef          	jal	ra,ffffffffc0203fc4 <slub_test_verify>
    if (ptr == NULL) {
ffffffffc0205038:	c481                	beqz	s1,ffffffffc0205040 <slub_check+0xc8a>
ffffffffc020503a:	8526                	mv	a0,s1
ffffffffc020503c:	db7fe0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
    for (size_t i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
ffffffffc0205040:	2405                	addiw	s0,s0,1
ffffffffc0205042:	0ff47413          	zext.b	s0,s0
ffffffffc0205046:	09a1                	addi	s3,s3,8
ffffffffc0205048:	0aa1                	addi	s5,s5,8
ffffffffc020504a:	fd641fe3          	bne	s0,s6,ffffffffc0205028 <slub_check+0xc72>
    assert(nr_free_pages() == before);
ffffffffc020504e:	c5bfd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0205052:	6782                	ld	a5,0(sp)
ffffffffc0205054:	68a79d63          	bne	a5,a0,ffffffffc02056ee <slub_check+0x1338>
    slub_check_large_alloc();
    cprintf("slub_check: large_alloc passed\n");
ffffffffc0205058:	00003517          	auipc	a0,0x3
ffffffffc020505c:	39050513          	addi	a0,a0,912 # ffffffffc02083e8 <buddy_pmm_manager+0x10c0>
ffffffffc0205060:	8f4fb0ef          	jal	ra,ffffffffc0200154 <cprintf>
    size_t before = nr_free_pages();
ffffffffc0205064:	c45fd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0205068:	84aa                	mv	s1,a0
ffffffffc020506a:	00190997          	auipc	s3,0x190
ffffffffc020506e:	9c698993          	addi	s3,s3,-1594 # ffffffffc0394a30 <test_objects>
        assert(ROUNDDOWN((uintptr_t)test_objects[i], PGSIZE) ==
ffffffffc0205072:	7afd                	lui	s5,0xfffff
    for (size_t i = 0; i < 8; i++) {
ffffffffc0205074:	4421                	li	s0,8
ffffffffc0205076:	a01d                	j	ffffffffc020509c <slub_check+0xce6>
ffffffffc0205078:	4541                	li	a0,16
ffffffffc020507a:	ab7fe0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
        test_objects[i] = slub_alloc(16);
ffffffffc020507e:	00a9b023          	sd	a0,0(s3)
        assert(test_objects[i] != NULL);
ffffffffc0205082:	c505                	beqz	a0,ffffffffc02050aa <slub_check+0xcf4>
        assert(ROUNDDOWN((uintptr_t)test_objects[i], PGSIZE) ==
ffffffffc0205084:	000c3783          	ld	a5,0(s8)
ffffffffc0205088:	01557533          	and	a0,a0,s5
ffffffffc020508c:	0157f7b3          	and	a5,a5,s5
ffffffffc0205090:	78f51263          	bne	a0,a5,ffffffffc0205814 <slub_check+0x145e>
    for (size_t i = 0; i < 8; i++) {
ffffffffc0205094:	0905                	addi	s2,s2,1
ffffffffc0205096:	09a1                	addi	s3,s3,8
ffffffffc0205098:	02890963          	beq	s2,s0,ffffffffc02050ca <slub_check+0xd14>
    if (!initialized || size == 0) {
ffffffffc020509c:	000a2783          	lw	a5,0(s4)
ffffffffc02050a0:	ffe1                	bnez	a5,ffffffffc0205078 <slub_check+0xcc2>
        test_objects[i] = slub_alloc(16);
ffffffffc02050a2:	090e                	slli	s2,s2,0x3
ffffffffc02050a4:	9c4a                	add	s8,s8,s2
ffffffffc02050a6:	000c3023          	sd	zero,0(s8)
        assert(test_objects[i] != NULL);
ffffffffc02050aa:	00003697          	auipc	a3,0x3
ffffffffc02050ae:	eee68693          	addi	a3,a3,-274 # ffffffffc0207f98 <buddy_pmm_manager+0xc70>
ffffffffc02050b2:	00001617          	auipc	a2,0x1
ffffffffc02050b6:	efe60613          	addi	a2,a2,-258 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02050ba:	25800593          	li	a1,600
ffffffffc02050be:	00002517          	auipc	a0,0x2
ffffffffc02050c2:	4da50513          	addi	a0,a0,1242 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02050c6:	904fb0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc02050ca:	bdffd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc02050ce:	fff48913          	addi	s2,s1,-1
ffffffffc02050d2:	53251e63          	bne	a0,s2,ffffffffc020560e <slub_check+0x1258>
    slub_free(test_objects[0]);
ffffffffc02050d6:	000c3503          	ld	a0,0(s8)
    if (ptr == NULL) {
ffffffffc02050da:	c119                	beqz	a0,ffffffffc02050e0 <slub_check+0xd2a>
ffffffffc02050dc:	d17fe0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
    assert(nr_free_pages() == before - 1);
ffffffffc02050e0:	bc9fd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc02050e4:	00190417          	auipc	s0,0x190
ffffffffc02050e8:	98440413          	addi	s0,s0,-1660 # ffffffffc0394a68 <test_objects+0x38>
ffffffffc02050ec:	50a91163          	bne	s2,a0,ffffffffc02055ee <slub_check+0x1238>
        slub_free(test_objects[i]);
ffffffffc02050f0:	008bb503          	ld	a0,8(s7)
    if (ptr == NULL) {
ffffffffc02050f4:	c119                	beqz	a0,ffffffffc02050fa <slub_check+0xd44>
ffffffffc02050f6:	cfdfe0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
    for (size_t i = 1; i < 8; i++) {
ffffffffc02050fa:	0ba1                	addi	s7,s7,8
ffffffffc02050fc:	fe8b9ae3          	bne	s7,s0,ffffffffc02050f0 <slub_check+0xd3a>
    assert(nr_free_pages() == before);
ffffffffc0205100:	ba9fd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0205104:	4ca49563          	bne	s1,a0,ffffffffc02055ce <slub_check+0x1218>
    if (!initialized || size == 0) {
ffffffffc0205108:	000a2783          	lw	a5,0(s4)
ffffffffc020510c:	2a078d63          	beqz	a5,ffffffffc02053c6 <slub_check+0x1010>
ffffffffc0205110:	6509                	lui	a0,0x2
ffffffffc0205112:	a1ffe0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
ffffffffc0205116:	842a                	mv	s0,a0
    assert(p != NULL && nr_free_pages() < before);
ffffffffc0205118:	2a050763          	beqz	a0,ffffffffc02053c6 <slub_check+0x1010>
ffffffffc020511c:	b8dfd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc0205120:	2a957363          	bgeu	a0,s1,ffffffffc02053c6 <slub_check+0x1010>
    if (ptr == NULL) {
ffffffffc0205124:	8522                	mv	a0,s0
ffffffffc0205126:	ccdfe0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
    assert(nr_free_pages() == before);
ffffffffc020512a:	b7ffd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc020512e:	36a49c63          	bne	s1,a0,ffffffffc02054a6 <slub_check+0x10f0>
    slub_check_page_reclaim();
    cprintf("slub_check: page_reclaim passed\n");
ffffffffc0205132:	00003517          	auipc	a0,0x3
ffffffffc0205136:	31e50513          	addi	a0,a0,798 # ffffffffc0208450 <buddy_pmm_manager+0x1128>
ffffffffc020513a:	81afb0ef          	jal	ra,ffffffffc0200154 <cprintf>
    size_t before = nr_free_pages();
ffffffffc020513e:	b6bfd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
    if (!initialized || size == 0) {
ffffffffc0205142:	000a2783          	lw	a5,0(s4)
    size_t before = nr_free_pages();
ffffffffc0205146:	84aa                	mv	s1,a0
    if (!initialized || size == 0) {
ffffffffc0205148:	22078063          	beqz	a5,ffffffffc0205368 <slub_check+0xfb2>
ffffffffc020514c:	557d                	li	a0,-1
ffffffffc020514e:	9e3fe0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
    assert(slub_alloc(~(size_t)0) == NULL);
ffffffffc0205152:	6e051163          	bnez	a0,ffffffffc0205834 <slub_check+0x147e>
    if (!initialized || size == 0) {
ffffffffc0205156:	000a2783          	lw	a5,0(s4)
ffffffffc020515a:	20078763          	beqz	a5,ffffffffc0205368 <slub_check+0xfb2>
ffffffffc020515e:	f8000513          	li	a0,-128
ffffffffc0205162:	9cffe0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
    assert(slub_alloc(~(size_t)0 - SLUB_DATA_OFFSET + 1) == NULL);
ffffffffc0205166:	6e051763          	bnez	a0,ffffffffc0205854 <slub_check+0x149e>
    if (!initialized || size == 0) {
ffffffffc020516a:	000a2783          	lw	a5,0(s4)
ffffffffc020516e:	1e078d63          	beqz	a5,ffffffffc0205368 <slub_check+0xfb2>
ffffffffc0205172:	f7f00513          	li	a0,-129
ffffffffc0205176:	9bbfe0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
    assert(slub_alloc(~(size_t)0 - SLUB_DATA_OFFSET) == NULL);
ffffffffc020517a:	6e051d63          	bnez	a0,ffffffffc0205874 <slub_check+0x14be>
    assert(before <= ~(size_t)0 / PGSIZE);
ffffffffc020517e:	57fd                	li	a5,-1
ffffffffc0205180:	83b1                	srli	a5,a5,0xc
ffffffffc0205182:	1e97e763          	bltu	a5,s1,ffffffffc0205370 <slub_check+0xfba>
    if (!initialized || size == 0) {
ffffffffc0205186:	000a2783          	lw	a5,0(s4)
    assert(slub_alloc(before * PGSIZE) == NULL);
ffffffffc020518a:	00c49513          	slli	a0,s1,0xc
    if (!initialized || size == 0) {
ffffffffc020518e:	c791                	beqz	a5,ffffffffc020519a <slub_check+0xde4>
ffffffffc0205190:	c509                	beqz	a0,ffffffffc020519a <slub_check+0xde4>
ffffffffc0205192:	99ffe0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
    assert(slub_alloc(before * PGSIZE) == NULL);
ffffffffc0205196:	60051c63          	bnez	a0,ffffffffc02057ae <slub_check+0x13f8>
    assert(nr_free_pages() == before);
ffffffffc020519a:	b0ffd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc020519e:	62a49863          	bne	s1,a0,ffffffffc02057ce <slub_check+0x1418>
    if (!initialized || size == 0) {
ffffffffc02051a2:	000a2783          	lw	a5,0(s4)
ffffffffc02051a6:	12078e63          	beqz	a5,ffffffffc02052e2 <slub_check+0xf2c>
ffffffffc02051aa:	4541                	li	a0,16
ffffffffc02051ac:	985fe0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
ffffffffc02051b0:	892a                	mv	s2,a0
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc02051b2:	12050863          	beqz	a0,ffffffffc02052e2 <slub_check+0xf2c>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc02051b6:	e63fd0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc02051ba:	6514                	ld	a3,8(a0)
ffffffffc02051bc:	4705                	li	a4,1
ffffffffc02051be:	1ce68c63          	beq	a3,a4,ffffffffc0205396 <slub_check+0xfe0>
ffffffffc02051c2:	7d1c                	ld	a5,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc02051c4:	473d                	li	a4,15
ffffffffc02051c6:	10f77e63          	bgeu	a4,a5,ffffffffc02052e2 <slub_check+0xf2c>
ffffffffc02051ca:	844a                	mv	s0,s2
ffffffffc02051cc:	874a                	mv	a4,s2
ffffffffc02051ce:	06100793          	li	a5,97
    for (size_t i = 0; i < size; i++) {
ffffffffc02051d2:	0b100613          	li	a2,177
ffffffffc02051d6:	0257869b          	addiw	a3,a5,37
        bytes[i] = slub_test_pattern(i, seed);
ffffffffc02051da:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc02051de:	0ff6f793          	zext.b	a5,a3
ffffffffc02051e2:	0705                	addi	a4,a4,1
ffffffffc02051e4:	fec799e3          	bne	a5,a2,ffffffffc02051d6 <slub_check+0xe20>
    slub_init(); // Idempotent initialization must not discard a live object.
ffffffffc02051e8:	8f0ff0ef          	jal	ra,ffffffffc02042d8 <slub_init>
    struct slub_slab *slab = slub_lookup(ptr);
ffffffffc02051ec:	854a                	mv	a0,s2
ffffffffc02051ee:	e2bfd0ef          	jal	ra,ffffffffc0203018 <slub_lookup>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc02051f2:	6514                	ld	a3,8(a0)
ffffffffc02051f4:	4705                	li	a4,1
ffffffffc02051f6:	18e68d63          	beq	a3,a4,ffffffffc0205390 <slub_check+0xfda>
ffffffffc02051fa:	7d1c                	ld	a5,56(a0)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc02051fc:	473d                	li	a4,15
ffffffffc02051fe:	46f77863          	bgeu	a4,a5,ffffffffc020566e <slub_check+0x12b8>
ffffffffc0205202:	06100793          	li	a5,97
    for (size_t i = 0; i < size; i++) {
ffffffffc0205206:	0b100693          	li	a3,177
        assert(bytes[i] == slub_test_pattern(i, seed));
ffffffffc020520a:	00044703          	lbu	a4,0(s0)
ffffffffc020520e:	18f71763          	bne	a4,a5,ffffffffc020539c <slub_check+0xfe6>
    for (size_t i = 0; i < size; i++) {
ffffffffc0205212:	0257879b          	addiw	a5,a5,37
ffffffffc0205216:	0ff7f793          	zext.b	a5,a5
ffffffffc020521a:	0405                	addi	s0,s0,1
ffffffffc020521c:	fed797e3          	bne	a5,a3,ffffffffc020520a <slub_check+0xe54>
    if (ptr == NULL) {
ffffffffc0205220:	854a                	mv	a0,s2
ffffffffc0205222:	bd1fe0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
    assert(nr_free_pages() == before);
ffffffffc0205226:	a83fd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc020522a:	54a49263          	bne	s1,a0,ffffffffc020576e <slub_check+0x13b8>
    assert(initialized);
ffffffffc020522e:	000a2783          	lw	a5,0(s4)
ffffffffc0205232:	4c078e63          	beqz	a5,ffffffffc020570e <slub_check+0x1358>
    memset(checked_frames, 0, sizeof(checked_frames));
ffffffffc0205236:	6621                	lui	a2,0x8
ffffffffc0205238:	4581                	li	a1,0
ffffffffc020523a:	00187517          	auipc	a0,0x187
ffffffffc020523e:	7e650513          	addi	a0,a0,2022 # ffffffffc038ca20 <checked_frames>
ffffffffc0205242:	2d5000ef          	jal	ra,ffffffffc0205d16 <memset>
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
ffffffffc0205246:	9b0fe0ef          	jal	ra,ffffffffc02033f6 <slub_check_invariants.part.0>
    slub_check_boundary();
    cprintf("slub_check: boundary passed\n");
ffffffffc020524a:	00003517          	auipc	a0,0x3
ffffffffc020524e:	30650513          	addi	a0,a0,774 # ffffffffc0208550 <buddy_pmm_manager+0x1228>
ffffffffc0205252:	f03fa0ef          	jal	ra,ffffffffc0200154 <cprintf>
    slub_check_stress();
ffffffffc0205256:	e05fe0ef          	jal	ra,ffffffffc020405a <slub_check_stress>
    cprintf("slub_check: stress passed\n");
ffffffffc020525a:	00003517          	auipc	a0,0x3
ffffffffc020525e:	31650513          	addi	a0,a0,790 # ffffffffc0208570 <buddy_pmm_manager+0x1248>
ffffffffc0205262:	ef3fa0ef          	jal	ra,ffffffffc0200154 <cprintf>
    assert(initialized);
ffffffffc0205266:	000a2783          	lw	a5,0(s4)
ffffffffc020526a:	4a078263          	beqz	a5,ffffffffc020570e <slub_check+0x1358>
    memset(checked_frames, 0, sizeof(checked_frames));
ffffffffc020526e:	6621                	lui	a2,0x8
ffffffffc0205270:	4581                	li	a1,0
ffffffffc0205272:	00187517          	auipc	a0,0x187
ffffffffc0205276:	7ae50513          	addi	a0,a0,1966 # ffffffffc038ca20 <checked_frames>
ffffffffc020527a:	29d000ef          	jal	ra,ffffffffc0205d16 <memset>
    for (size_t i = 0; i < SLUB_CLASSES; i++) {
ffffffffc020527e:	978fe0ef          	jal	ra,ffffffffc02033f6 <slub_check_invariants.part.0>
    slub_check_invariants();
    slub_check_empty();
ffffffffc0205282:	8c0fe0ef          	jal	ra,ffffffffc0203342 <slub_check_empty>
    assert(nr_free_pages() == before);
ffffffffc0205286:	a23fd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc020528a:	67a2                	ld	a5,8(sp)
ffffffffc020528c:	50f51163          	bne	a0,a5,ffffffffc020578e <slub_check+0x13d8>
    if (!initialized || size == 0) {
ffffffffc0205290:	000a2783          	lw	a5,0(s4)
ffffffffc0205294:	14078963          	beqz	a5,ffffffffc02053e6 <slub_check+0x1030>
ffffffffc0205298:	4561                	li	a0,24
ffffffffc020529a:	897fe0ef          	jal	ra,ffffffffc0203b30 <slub_alloc.part.0>
    void *continuation = slub_alloc(24);
    assert(continuation != NULL);
ffffffffc020529e:	14050463          	beqz	a0,ffffffffc02053e6 <slub_check+0x1030>
    if (ptr == NULL) {
ffffffffc02052a2:	b51fe0ef          	jal	ra,ffffffffc0203df2 <slub_free.part.0>
    slub_free(continuation);
    assert(nr_free_pages() == before);
ffffffffc02052a6:	a03fd0ef          	jal	ra,ffffffffc0202ca8 <nr_free_pages>
ffffffffc02052aa:	67a2                	ld	a5,8(sp)
ffffffffc02052ac:	14f51d63          	bne	a0,a5,ffffffffc0205406 <slub_check+0x1050>
    cprintf("slub_check: all tests passed; PMM pages restored\n");
}
ffffffffc02052b0:	741a                	ld	s0,416(sp)
ffffffffc02052b2:	70ba                	ld	ra,424(sp)
ffffffffc02052b4:	64fa                	ld	s1,408(sp)
ffffffffc02052b6:	695a                	ld	s2,400(sp)
ffffffffc02052b8:	69ba                	ld	s3,392(sp)
ffffffffc02052ba:	6a1a                	ld	s4,384(sp)
ffffffffc02052bc:	7af6                	ld	s5,376(sp)
ffffffffc02052be:	7b56                	ld	s6,368(sp)
ffffffffc02052c0:	7bb6                	ld	s7,360(sp)
ffffffffc02052c2:	7c16                	ld	s8,352(sp)
ffffffffc02052c4:	6cf6                	ld	s9,344(sp)
ffffffffc02052c6:	6d56                	ld	s10,336(sp)
ffffffffc02052c8:	6db6                	ld	s11,328(sp)
    cprintf("slub_check: all tests passed; PMM pages restored\n");
ffffffffc02052ca:	00003517          	auipc	a0,0x3
ffffffffc02052ce:	2c650513          	addi	a0,a0,710 # ffffffffc0208590 <buddy_pmm_manager+0x1268>
}
ffffffffc02052d2:	615d                	addi	sp,sp,432
    cprintf("slub_check: all tests passed; PMM pages restored\n");
ffffffffc02052d4:	e81fa06f          	j	ffffffffc0200154 <cprintf>
        test_objects[i] = slub_alloc(32);
ffffffffc02052d8:	003c9793          	slli	a5,s9,0x3
ffffffffc02052dc:	9c3e                	add	s8,s8,a5
ffffffffc02052de:	000c3023          	sd	zero,0(s8)
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc02052e2:	00003697          	auipc	a3,0x3
ffffffffc02052e6:	b0668693          	addi	a3,a3,-1274 # ffffffffc0207de8 <buddy_pmm_manager+0xac0>
ffffffffc02052ea:	00001617          	auipc	a2,0x1
ffffffffc02052ee:	cc660613          	addi	a2,a2,-826 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02052f2:	18900593          	li	a1,393
ffffffffc02052f6:	00002517          	auipc	a0,0x2
ffffffffc02052fa:	2a250513          	addi	a0,a0,674 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02052fe:	ecdfa0ef          	jal	ra,ffffffffc02001ca <__panic>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0205302:	6d1c                	ld	a5,24(a0)
ffffffffc0205304:	6398                	ld	a4,0(a5)
ffffffffc0205306:	87dff06f          	j	ffffffffc0204b82 <slub_check+0x7cc>
ffffffffc020530a:	6d1c                	ld	a5,24(a0)
ffffffffc020530c:	6398                	ld	a4,0(a5)
ffffffffc020530e:	f5eff06f          	j	ffffffffc0204a6c <slub_check+0x6b6>
ffffffffc0205312:	6d1c                	ld	a5,24(a0)
ffffffffc0205314:	6398                	ld	a4,0(a5)
ffffffffc0205316:	f22ff06f          	j	ffffffffc0204a38 <slub_check+0x682>
ffffffffc020531a:	6d1c                	ld	a5,24(a0)
ffffffffc020531c:	6398                	ld	a4,0(a5)
ffffffffc020531e:	ee6ff06f          	j	ffffffffc0204a04 <slub_check+0x64e>
ffffffffc0205322:	6d1c                	ld	a5,24(a0)
ffffffffc0205324:	6398                	ld	a4,0(a5)
ffffffffc0205326:	e92ff06f          	j	ffffffffc02049b8 <slub_check+0x602>
ffffffffc020532a:	6d1c                	ld	a5,24(a0)
ffffffffc020532c:	6398                	ld	a4,0(a5)
ffffffffc020532e:	e54ff06f          	j	ffffffffc0204982 <slub_check+0x5cc>
ffffffffc0205332:	6d1c                	ld	a5,24(a0)
ffffffffc0205334:	6398                	ld	a4,0(a5)
ffffffffc0205336:	e0eff06f          	j	ffffffffc0204944 <slub_check+0x58e>
ffffffffc020533a:	6d1c                	ld	a5,24(a0)
ffffffffc020533c:	6398                	ld	a4,0(a5)
ffffffffc020533e:	dd0ff06f          	j	ffffffffc020490e <slub_check+0x558>
ffffffffc0205342:	6d1c                	ld	a5,24(a0)
ffffffffc0205344:	6398                	ld	a4,0(a5)
ffffffffc0205346:	d92ff06f          	j	ffffffffc02048d8 <slub_check+0x522>
ffffffffc020534a:	6d1c                	ld	a5,24(a0)
ffffffffc020534c:	6398                	ld	a4,0(a5)
ffffffffc020534e:	d54ff06f          	j	ffffffffc02048a2 <slub_check+0x4ec>
ffffffffc0205352:	6d1c                	ld	a5,24(a0)
ffffffffc0205354:	6398                	ld	a4,0(a5)
ffffffffc0205356:	d12ff06f          	j	ffffffffc0204868 <slub_check+0x4b2>
ffffffffc020535a:	6d1c                	ld	a5,24(a0)
ffffffffc020535c:	6398                	ld	a4,0(a5)
ffffffffc020535e:	cd2ff06f          	j	ffffffffc0204830 <slub_check+0x47a>
ffffffffc0205362:	6d1c                	ld	a5,24(a0)
ffffffffc0205364:	6398                	ld	a4,0(a5)
ffffffffc0205366:	b485                	j	ffffffffc0204dc6 <slub_check+0xa10>
    assert(before <= ~(size_t)0 / PGSIZE);
ffffffffc0205368:	57fd                	li	a5,-1
ffffffffc020536a:	83b1                	srli	a5,a5,0xc
ffffffffc020536c:	e297f7e3          	bgeu	a5,s1,ffffffffc020519a <slub_check+0xde4>
ffffffffc0205370:	00003697          	auipc	a3,0x3
ffffffffc0205374:	19868693          	addi	a3,a3,408 # ffffffffc0208508 <buddy_pmm_manager+0x11e0>
ffffffffc0205378:	00001617          	auipc	a2,0x1
ffffffffc020537c:	c3860613          	addi	a2,a2,-968 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0205380:	27100593          	li	a1,625
ffffffffc0205384:	00002517          	auipc	a0,0x2
ffffffffc0205388:	21450513          	addi	a0,a0,532 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020538c:	e3ffa0ef          	jal	ra,ffffffffc02001ca <__panic>
    return slab->kind == SLUB_SMALL ? slab->cache->object_size : slab->requested;
ffffffffc0205390:	6d1c                	ld	a5,24(a0)
ffffffffc0205392:	639c                	ld	a5,0(a5)
ffffffffc0205394:	b5a5                	j	ffffffffc02051fc <slub_check+0xe46>
ffffffffc0205396:	6d1c                	ld	a5,24(a0)
ffffffffc0205398:	639c                	ld	a5,0(a5)
ffffffffc020539a:	b52d                	j	ffffffffc02051c4 <slub_check+0xe0e>
        assert(bytes[i] == slub_test_pattern(i, seed));
ffffffffc020539c:	00003697          	auipc	a3,0x3
ffffffffc02053a0:	aec68693          	addi	a3,a3,-1300 # ffffffffc0207e88 <buddy_pmm_manager+0xb60>
ffffffffc02053a4:	00001617          	auipc	a2,0x1
ffffffffc02053a8:	c0c60613          	addi	a2,a2,-1012 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02053ac:	19500593          	li	a1,405
ffffffffc02053b0:	00002517          	auipc	a0,0x2
ffffffffc02053b4:	1e850513          	addi	a0,a0,488 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02053b8:	e13fa0ef          	jal	ra,ffffffffc02001ca <__panic>
        return NULL;
ffffffffc02053bc:	4501                	li	a0,0
ffffffffc02053be:	f9cff06f          	j	ffffffffc0204b5a <slub_check+0x7a4>
ffffffffc02053c2:	4781                	li	a5,0
ffffffffc02053c4:	bae1                	j	ffffffffc0204d9c <slub_check+0x9e6>
    assert(p != NULL && nr_free_pages() < before);
ffffffffc02053c6:	00003697          	auipc	a3,0x3
ffffffffc02053ca:	06268693          	addi	a3,a3,98 # ffffffffc0208428 <buddy_pmm_manager+0x1100>
ffffffffc02053ce:	00001617          	auipc	a2,0x1
ffffffffc02053d2:	be260613          	addi	a2,a2,-1054 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02053d6:	26400593          	li	a1,612
ffffffffc02053da:	00002517          	auipc	a0,0x2
ffffffffc02053de:	1be50513          	addi	a0,a0,446 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02053e2:	de9fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(continuation != NULL);
ffffffffc02053e6:	00002697          	auipc	a3,0x2
ffffffffc02053ea:	e6a68693          	addi	a3,a3,-406 # ffffffffc0207250 <etext+0x1528>
ffffffffc02053ee:	00001617          	auipc	a2,0x1
ffffffffc02053f2:	bc260613          	addi	a2,a2,-1086 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02053f6:	2cc00593          	li	a1,716
ffffffffc02053fa:	00002517          	auipc	a0,0x2
ffffffffc02053fe:	19e50513          	addi	a0,a0,414 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0205402:	dc9fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == before);
ffffffffc0205406:	00001697          	auipc	a3,0x1
ffffffffc020540a:	52a68693          	addi	a3,a3,1322 # ffffffffc0206930 <etext+0xc08>
ffffffffc020540e:	00001617          	auipc	a2,0x1
ffffffffc0205412:	ba260613          	addi	a2,a2,-1118 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0205416:	2ce00593          	li	a1,718
ffffffffc020541a:	00002517          	auipc	a0,0x2
ffffffffc020541e:	17e50513          	addi	a0,a0,382 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0205422:	da9fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() >= 64);
ffffffffc0205426:	00003697          	auipc	a3,0x3
ffffffffc020542a:	b2268693          	addi	a3,a3,-1246 # ffffffffc0207f48 <buddy_pmm_manager+0xc20>
ffffffffc020542e:	00001617          	auipc	a2,0x1
ffffffffc0205432:	b8260613          	addi	a2,a2,-1150 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0205436:	2b000593          	li	a1,688
ffffffffc020543a:	00002517          	auipc	a0,0x2
ffffffffc020543e:	15e50513          	addi	a0,a0,350 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0205442:	d89fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(initialized);
ffffffffc0205446:	00002697          	auipc	a3,0x2
ffffffffc020544a:	1a268693          	addi	a3,a3,418 # ffffffffc02075e8 <buddy_pmm_manager+0x2c0>
ffffffffc020544e:	00001617          	auipc	a2,0x1
ffffffffc0205452:	b6260613          	addi	a2,a2,-1182 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0205456:	2ae00593          	li	a1,686
ffffffffc020545a:	00002517          	auipc	a0,0x2
ffffffffc020545e:	13e50513          	addi	a0,a0,318 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0205462:	d69fa0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(slub_usable_size(test_objects[i]) == expected);
ffffffffc0205466:	00003697          	auipc	a3,0x3
ffffffffc020546a:	b8268693          	addi	a3,a3,-1150 # ffffffffc0207fe8 <buddy_pmm_manager+0xcc0>
ffffffffc020546e:	00001617          	auipc	a2,0x1
ffffffffc0205472:	b4260613          	addi	a2,a2,-1214 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0205476:	1c700593          	li	a1,455
ffffffffc020547a:	00002517          	auipc	a0,0x2
ffffffffc020547e:	11e50513          	addi	a0,a0,286 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0205482:	d49fa0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(slub_lookup(test_objects[i])->kind == SLUB_LARGE);
ffffffffc0205486:	00003697          	auipc	a3,0x3
ffffffffc020548a:	b2a68693          	addi	a3,a3,-1238 # ffffffffc0207fb0 <buddy_pmm_manager+0xc88>
ffffffffc020548e:	00001617          	auipc	a2,0x1
ffffffffc0205492:	b2260613          	addi	a2,a2,-1246 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0205496:	1c500593          	li	a1,453
ffffffffc020549a:	00002517          	auipc	a0,0x2
ffffffffc020549e:	0fe50513          	addi	a0,a0,254 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02054a2:	d29fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == before);
ffffffffc02054a6:	00001697          	auipc	a3,0x1
ffffffffc02054aa:	48a68693          	addi	a3,a3,1162 # ffffffffc0206930 <etext+0xc08>
ffffffffc02054ae:	00001617          	auipc	a2,0x1
ffffffffc02054b2:	b0260613          	addi	a2,a2,-1278 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02054b6:	26600593          	li	a1,614
ffffffffc02054ba:	00002517          	auipc	a0,0x2
ffffffffc02054be:	0de50513          	addi	a0,a0,222 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02054c2:	d09fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(test_objects[index] == released && nr_free_pages() == before - 3);
ffffffffc02054c6:	00003697          	auipc	a3,0x3
ffffffffc02054ca:	dea68693          	addi	a3,a3,-534 # ffffffffc02082b0 <buddy_pmm_manager+0xf88>
ffffffffc02054ce:	00001617          	auipc	a2,0x1
ffffffffc02054d2:	ae260613          	addi	a2,a2,-1310 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02054d6:	22800593          	li	a1,552
ffffffffc02054da:	00002517          	auipc	a0,0x2
ffffffffc02054de:	0be50513          	addi	a0,a0,190 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02054e2:	ce9fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(cache->slabs == 3 && nr_free_pages() == before - 3);
ffffffffc02054e6:	00003697          	auipc	a3,0x3
ffffffffc02054ea:	d9268693          	addi	a3,a3,-622 # ffffffffc0208278 <buddy_pmm_manager+0xf50>
ffffffffc02054ee:	00001617          	auipc	a2,0x1
ffffffffc02054f2:	ac260613          	addi	a2,a2,-1342 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02054f6:	22600593          	li	a1,550
ffffffffc02054fa:	00002517          	auipc	a0,0x2
ffffffffc02054fe:	09e50513          	addi	a0,a0,158 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0205502:	cc9fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(cache->slabs == 3 && nr_free_pages() == before - 3);
ffffffffc0205506:	00003697          	auipc	a3,0x3
ffffffffc020550a:	d7268693          	addi	a3,a3,-654 # ffffffffc0208278 <buddy_pmm_manager+0xf50>
ffffffffc020550e:	00001617          	auipc	a2,0x1
ffffffffc0205512:	aa260613          	addi	a2,a2,-1374 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0205516:	22200593          	li	a1,546
ffffffffc020551a:	00002517          	auipc	a0,0x2
ffffffffc020551e:	07e50513          	addi	a0,a0,126 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0205522:	ca9fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(count <= sizeof(test_objects) / sizeof(test_objects[0]));
ffffffffc0205526:	00003697          	auipc	a3,0x3
ffffffffc020552a:	c7a68693          	addi	a3,a3,-902 # ffffffffc02081a0 <buddy_pmm_manager+0xe78>
ffffffffc020552e:	00001617          	auipc	a2,0x1
ffffffffc0205532:	a8260613          	addi	a2,a2,-1406 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0205536:	21400593          	li	a1,532
ffffffffc020553a:	00002517          	auipc	a0,0x2
ffffffffc020553e:	05e50513          	addi	a0,a0,94 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0205542:	c89fa0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(slub_usable_size(test_objects[i]) >= requests[i]);
ffffffffc0205546:	00003697          	auipc	a3,0x3
ffffffffc020554a:	e4a68693          	addi	a3,a3,-438 # ffffffffc0208390 <buddy_pmm_manager+0x1068>
ffffffffc020554e:	00001617          	auipc	a2,0x1
ffffffffc0205552:	a6260613          	addi	a2,a2,-1438 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0205556:	23c00593          	li	a1,572
ffffffffc020555a:	00002517          	auipc	a0,0x2
ffffffffc020555e:	03e50513          	addi	a0,a0,62 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0205562:	c69fa0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(slab->npages == (requests[i] + SLUB_DATA_OFFSET - 1) / PGSIZE + 1);
ffffffffc0205566:	00003697          	auipc	a3,0x3
ffffffffc020556a:	de268693          	addi	a3,a3,-542 # ffffffffc0208348 <buddy_pmm_manager+0x1020>
ffffffffc020556e:	00001617          	auipc	a2,0x1
ffffffffc0205572:	a4260613          	addi	a2,a2,-1470 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0205576:	23b00593          	li	a1,571
ffffffffc020557a:	00002517          	auipc	a0,0x2
ffffffffc020557e:	01e50513          	addi	a0,a0,30 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0205582:	c49fa0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(slab->kind == SLUB_LARGE);
ffffffffc0205586:	00002697          	auipc	a3,0x2
ffffffffc020558a:	12268693          	addi	a3,a3,290 # ffffffffc02076a8 <buddy_pmm_manager+0x380>
ffffffffc020558e:	00001617          	auipc	a2,0x1
ffffffffc0205592:	a2260613          	addi	a2,a2,-1502 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0205596:	23a00593          	li	a1,570
ffffffffc020559a:	00002517          	auipc	a0,0x2
ffffffffc020559e:	ffe50513          	addi	a0,a0,-2 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02055a2:	c29fa0ef          	jal	ra,ffffffffc02001ca <__panic>
ffffffffc02055a6:	4981                	li	s3,0
        return NULL;
ffffffffc02055a8:	4481                	li	s1,0
ffffffffc02055aa:	a72ff06f          	j	ffffffffc020481c <slub_check+0x466>
    assert(nr_free_pages() == before);
ffffffffc02055ae:	00001697          	auipc	a3,0x1
ffffffffc02055b2:	38268693          	addi	a3,a3,898 # ffffffffc0206930 <etext+0xc08>
ffffffffc02055b6:	00001617          	auipc	a2,0x1
ffffffffc02055ba:	9fa60613          	addi	a2,a2,-1542 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02055be:	1e000593          	li	a1,480
ffffffffc02055c2:	00002517          	auipc	a0,0x2
ffffffffc02055c6:	fd650513          	addi	a0,a0,-42 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02055ca:	c01fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == before);
ffffffffc02055ce:	00001697          	auipc	a3,0x1
ffffffffc02055d2:	36268693          	addi	a3,a3,866 # ffffffffc0206930 <etext+0xc08>
ffffffffc02055d6:	00001617          	auipc	a2,0x1
ffffffffc02055da:	9da60613          	addi	a2,a2,-1574 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02055de:	26200593          	li	a1,610
ffffffffc02055e2:	00002517          	auipc	a0,0x2
ffffffffc02055e6:	fb650513          	addi	a0,a0,-74 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02055ea:	be1fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc02055ee:	00003697          	auipc	a3,0x3
ffffffffc02055f2:	e1a68693          	addi	a3,a3,-486 # ffffffffc0208408 <buddy_pmm_manager+0x10e0>
ffffffffc02055f6:	00001617          	auipc	a2,0x1
ffffffffc02055fa:	9ba60613          	addi	a2,a2,-1606 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02055fe:	25e00593          	li	a1,606
ffffffffc0205602:	00002517          	auipc	a0,0x2
ffffffffc0205606:	f9650513          	addi	a0,a0,-106 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020560a:	bc1fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc020560e:	00003697          	auipc	a3,0x3
ffffffffc0205612:	dfa68693          	addi	a3,a3,-518 # ffffffffc0208408 <buddy_pmm_manager+0x10e0>
ffffffffc0205616:	00001617          	auipc	a2,0x1
ffffffffc020561a:	99a60613          	addi	a2,a2,-1638 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020561e:	25c00593          	li	a1,604
ffffffffc0205622:	00002517          	auipc	a0,0x2
ffffffffc0205626:	f7650513          	addi	a0,a0,-138 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020562a:	ba1fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == before);
ffffffffc020562e:	00001697          	auipc	a3,0x1
ffffffffc0205632:	30268693          	addi	a3,a3,770 # ffffffffc0206930 <etext+0xc08>
ffffffffc0205636:	00001617          	auipc	a2,0x1
ffffffffc020563a:	97a60613          	addi	a2,a2,-1670 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020563e:	20c00593          	li	a1,524
ffffffffc0205642:	00002517          	auipc	a0,0x2
ffffffffc0205646:	f5650513          	addi	a0,a0,-170 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020564a:	b81fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(test_objects[1] == released && nr_free_pages() == occupied);
ffffffffc020564e:	00003697          	auipc	a3,0x3
ffffffffc0205652:	af268693          	addi	a3,a3,-1294 # ffffffffc0208140 <buddy_pmm_manager+0xe18>
ffffffffc0205656:	00001617          	auipc	a2,0x1
ffffffffc020565a:	95a60613          	addi	a2,a2,-1702 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020565e:	20600593          	li	a1,518
ffffffffc0205662:	00002517          	auipc	a0,0x2
ffffffffc0205666:	f3650513          	addi	a0,a0,-202 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020566a:	b61fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(ptr != NULL && slub_usable_size(ptr) >= size);
ffffffffc020566e:	00002697          	auipc	a3,0x2
ffffffffc0205672:	77a68693          	addi	a3,a3,1914 # ffffffffc0207de8 <buddy_pmm_manager+0xac0>
ffffffffc0205676:	00001617          	auipc	a2,0x1
ffffffffc020567a:	93a60613          	addi	a2,a2,-1734 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020567e:	19200593          	li	a1,402
ffffffffc0205682:	00002517          	auipc	a0,0x2
ffffffffc0205686:	f1650513          	addi	a0,a0,-234 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020568a:	b41fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == before);
ffffffffc020568e:	00001697          	auipc	a3,0x1
ffffffffc0205692:	2a268693          	addi	a3,a3,674 # ffffffffc0206930 <etext+0xc08>
ffffffffc0205696:	00001617          	auipc	a2,0x1
ffffffffc020569a:	91a60613          	addi	a2,a2,-1766 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020569e:	1d200593          	li	a1,466
ffffffffc02056a2:	00002517          	auipc	a0,0x2
ffffffffc02056a6:	ef650513          	addi	a0,a0,-266 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02056aa:	b21fa0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(nr_free_pages() == before);
ffffffffc02056ae:	00001697          	auipc	a3,0x1
ffffffffc02056b2:	28268693          	addi	a3,a3,642 # ffffffffc0206930 <etext+0xc08>
ffffffffc02056b6:	00001617          	auipc	a2,0x1
ffffffffc02056ba:	8fa60613          	addi	a2,a2,-1798 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02056be:	1b200593          	li	a1,434
ffffffffc02056c2:	00002517          	auipc	a0,0x2
ffffffffc02056c6:	ed650513          	addi	a0,a0,-298 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02056ca:	b01fa0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(cache->slabs == 1 && list_empty(&cache->partial));
ffffffffc02056ce:	00003697          	auipc	a3,0x3
ffffffffc02056d2:	b5268693          	addi	a3,a3,-1198 # ffffffffc0208220 <buddy_pmm_manager+0xef8>
ffffffffc02056d6:	00001617          	auipc	a2,0x1
ffffffffc02056da:	8da60613          	addi	a2,a2,-1830 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02056de:	21e00593          	li	a1,542
ffffffffc02056e2:	00002517          	auipc	a0,0x2
ffffffffc02056e6:	eb650513          	addi	a0,a0,-330 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02056ea:	ae1fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == before);
ffffffffc02056ee:	00001697          	auipc	a3,0x1
ffffffffc02056f2:	24268693          	addi	a3,a3,578 # ffffffffc0206930 <etext+0xc08>
ffffffffc02056f6:	00001617          	auipc	a2,0x1
ffffffffc02056fa:	8ba60613          	addi	a2,a2,-1862 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02056fe:	25000593          	li	a1,592
ffffffffc0205702:	00002517          	auipc	a0,0x2
ffffffffc0205706:	e9650513          	addi	a0,a0,-362 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020570a:	ac1fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(initialized);
ffffffffc020570e:	00002697          	auipc	a3,0x2
ffffffffc0205712:	eda68693          	addi	a3,a3,-294 # ffffffffc02075e8 <buddy_pmm_manager+0x2c0>
ffffffffc0205716:	00001617          	auipc	a2,0x1
ffffffffc020571a:	89a60613          	addi	a2,a2,-1894 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020571e:	14e00593          	li	a1,334
ffffffffc0205722:	00002517          	auipc	a0,0x2
ffffffffc0205726:	e7650513          	addi	a0,a0,-394 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020572a:	aa1fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == occupied);
ffffffffc020572e:	00003697          	auipc	a3,0x3
ffffffffc0205732:	9f268693          	addi	a3,a3,-1550 # ffffffffc0208120 <buddy_pmm_manager+0xdf8>
ffffffffc0205736:	00001617          	auipc	a2,0x1
ffffffffc020573a:	87a60613          	addi	a2,a2,-1926 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020573e:	20400593          	li	a1,516
ffffffffc0205742:	00002517          	auipc	a0,0x2
ffffffffc0205746:	e5650513          	addi	a0,a0,-426 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020574a:	a81fa0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(ROUNDDOWN((uintptr_t)test_objects[i], PGSIZE) ==
ffffffffc020574e:	00003697          	auipc	a3,0x3
ffffffffc0205752:	97268693          	addi	a3,a3,-1678 # ffffffffc02080c0 <buddy_pmm_manager+0xd98>
ffffffffc0205756:	00001617          	auipc	a2,0x1
ffffffffc020575a:	85a60613          	addi	a2,a2,-1958 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020575e:	1fe00593          	li	a1,510
ffffffffc0205762:	00002517          	auipc	a0,0x2
ffffffffc0205766:	e3650513          	addi	a0,a0,-458 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020576a:	a61fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == before);
ffffffffc020576e:	00001697          	auipc	a3,0x1
ffffffffc0205772:	1c268693          	addi	a3,a3,450 # ffffffffc0206930 <etext+0xc08>
ffffffffc0205776:	00001617          	auipc	a2,0x1
ffffffffc020577a:	83a60613          	addi	a2,a2,-1990 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020577e:	27a00593          	li	a1,634
ffffffffc0205782:	00002517          	auipc	a0,0x2
ffffffffc0205786:	e1650513          	addi	a0,a0,-490 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc020578a:	a41fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == before);
ffffffffc020578e:	00001697          	auipc	a3,0x1
ffffffffc0205792:	1a268693          	addi	a3,a3,418 # ffffffffc0206930 <etext+0xc08>
ffffffffc0205796:	00001617          	auipc	a2,0x1
ffffffffc020579a:	81a60613          	addi	a2,a2,-2022 # ffffffffc0205fb0 <etext+0x288>
ffffffffc020579e:	2ca00593          	li	a1,714
ffffffffc02057a2:	00002517          	auipc	a0,0x2
ffffffffc02057a6:	df650513          	addi	a0,a0,-522 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02057aa:	a21fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(slub_alloc(before * PGSIZE) == NULL);
ffffffffc02057ae:	00003697          	auipc	a3,0x3
ffffffffc02057b2:	d7a68693          	addi	a3,a3,-646 # ffffffffc0208528 <buddy_pmm_manager+0x1200>
ffffffffc02057b6:	00000617          	auipc	a2,0x0
ffffffffc02057ba:	7fa60613          	addi	a2,a2,2042 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02057be:	27300593          	li	a1,627
ffffffffc02057c2:	00002517          	auipc	a0,0x2
ffffffffc02057c6:	dd650513          	addi	a0,a0,-554 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02057ca:	a01fa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == before);
ffffffffc02057ce:	00001697          	auipc	a3,0x1
ffffffffc02057d2:	16268693          	addi	a3,a3,354 # ffffffffc0206930 <etext+0xc08>
ffffffffc02057d6:	00000617          	auipc	a2,0x0
ffffffffc02057da:	7da60613          	addi	a2,a2,2010 # ffffffffc0205fb0 <etext+0x288>
ffffffffc02057de:	27400593          	li	a1,628
ffffffffc02057e2:	00002517          	auipc	a0,0x2
ffffffffc02057e6:	db650513          	addi	a0,a0,-586 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc02057ea:	9e1fa0ef          	jal	ra,ffffffffc02001ca <__panic>
        return NULL;
ffffffffc02057ee:	4481                	li	s1,0
ffffffffc02057f0:	82cff06f          	j	ffffffffc020481c <slub_check+0x466>
    assert(cache->slabs == 0 && nr_free_pages() == before);
ffffffffc02057f4:	00003697          	auipc	a3,0x3
ffffffffc02057f8:	b0468693          	addi	a3,a3,-1276 # ffffffffc02082f8 <buddy_pmm_manager+0xfd0>
ffffffffc02057fc:	00000617          	auipc	a2,0x0
ffffffffc0205800:	7b460613          	addi	a2,a2,1972 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0205804:	22f00593          	li	a1,559
ffffffffc0205808:	00002517          	auipc	a0,0x2
ffffffffc020580c:	d9050513          	addi	a0,a0,-624 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0205810:	9bbfa0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(ROUNDDOWN((uintptr_t)test_objects[i], PGSIZE) ==
ffffffffc0205814:	00003697          	auipc	a3,0x3
ffffffffc0205818:	8ac68693          	addi	a3,a3,-1876 # ffffffffc02080c0 <buddy_pmm_manager+0xd98>
ffffffffc020581c:	00000617          	auipc	a2,0x0
ffffffffc0205820:	79460613          	addi	a2,a2,1940 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0205824:	25900593          	li	a1,601
ffffffffc0205828:	00002517          	auipc	a0,0x2
ffffffffc020582c:	d7050513          	addi	a0,a0,-656 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0205830:	99bfa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(slub_alloc(~(size_t)0) == NULL);
ffffffffc0205834:	00003697          	auipc	a3,0x3
ffffffffc0205838:	c4468693          	addi	a3,a3,-956 # ffffffffc0208478 <buddy_pmm_manager+0x1150>
ffffffffc020583c:	00000617          	auipc	a2,0x0
ffffffffc0205840:	77460613          	addi	a2,a2,1908 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0205844:	26e00593          	li	a1,622
ffffffffc0205848:	00002517          	auipc	a0,0x2
ffffffffc020584c:	d5050513          	addi	a0,a0,-688 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0205850:	97bfa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(slub_alloc(~(size_t)0 - SLUB_DATA_OFFSET + 1) == NULL);
ffffffffc0205854:	00003697          	auipc	a3,0x3
ffffffffc0205858:	c4468693          	addi	a3,a3,-956 # ffffffffc0208498 <buddy_pmm_manager+0x1170>
ffffffffc020585c:	00000617          	auipc	a2,0x0
ffffffffc0205860:	75460613          	addi	a2,a2,1876 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0205864:	26f00593          	li	a1,623
ffffffffc0205868:	00002517          	auipc	a0,0x2
ffffffffc020586c:	d3050513          	addi	a0,a0,-720 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0205870:	95bfa0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(slub_alloc(~(size_t)0 - SLUB_DATA_OFFSET) == NULL);
ffffffffc0205874:	00003697          	auipc	a3,0x3
ffffffffc0205878:	c5c68693          	addi	a3,a3,-932 # ffffffffc02084d0 <buddy_pmm_manager+0x11a8>
ffffffffc020587c:	00000617          	auipc	a2,0x0
ffffffffc0205880:	73460613          	addi	a2,a2,1844 # ffffffffc0205fb0 <etext+0x288>
ffffffffc0205884:	27000593          	li	a1,624
ffffffffc0205888:	00002517          	auipc	a0,0x2
ffffffffc020588c:	d1050513          	addi	a0,a0,-752 # ffffffffc0207598 <buddy_pmm_manager+0x270>
ffffffffc0205890:	93bfa0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0205894 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205894:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205898:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020589a:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020589e:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02058a0:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02058a4:	f022                	sd	s0,32(sp)
ffffffffc02058a6:	ec26                	sd	s1,24(sp)
ffffffffc02058a8:	e84a                	sd	s2,16(sp)
ffffffffc02058aa:	f406                	sd	ra,40(sp)
ffffffffc02058ac:	e44e                	sd	s3,8(sp)
ffffffffc02058ae:	84aa                	mv	s1,a0
ffffffffc02058b0:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02058b2:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02058b6:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02058b8:	03067e63          	bgeu	a2,a6,ffffffffc02058f4 <printnum+0x60>
ffffffffc02058bc:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02058be:	00805763          	blez	s0,ffffffffc02058cc <printnum+0x38>
ffffffffc02058c2:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02058c4:	85ca                	mv	a1,s2
ffffffffc02058c6:	854e                	mv	a0,s3
ffffffffc02058c8:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02058ca:	fc65                	bnez	s0,ffffffffc02058c2 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02058cc:	1a02                	slli	s4,s4,0x20
ffffffffc02058ce:	00003797          	auipc	a5,0x3
ffffffffc02058d2:	eca78793          	addi	a5,a5,-310 # ffffffffc0208798 <buddy_pmm_manager+0x1470>
ffffffffc02058d6:	020a5a13          	srli	s4,s4,0x20
ffffffffc02058da:	9a3e                	add	s4,s4,a5
}
ffffffffc02058dc:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02058de:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02058e2:	70a2                	ld	ra,40(sp)
ffffffffc02058e4:	69a2                	ld	s3,8(sp)
ffffffffc02058e6:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02058e8:	85ca                	mv	a1,s2
ffffffffc02058ea:	87a6                	mv	a5,s1
}
ffffffffc02058ec:	6942                	ld	s2,16(sp)
ffffffffc02058ee:	64e2                	ld	s1,24(sp)
ffffffffc02058f0:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02058f2:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02058f4:	03065633          	divu	a2,a2,a6
ffffffffc02058f8:	8722                	mv	a4,s0
ffffffffc02058fa:	f9bff0ef          	jal	ra,ffffffffc0205894 <printnum>
ffffffffc02058fe:	b7f9                	j	ffffffffc02058cc <printnum+0x38>

ffffffffc0205900 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205900:	7119                	addi	sp,sp,-128
ffffffffc0205902:	f4a6                	sd	s1,104(sp)
ffffffffc0205904:	f0ca                	sd	s2,96(sp)
ffffffffc0205906:	ecce                	sd	s3,88(sp)
ffffffffc0205908:	e8d2                	sd	s4,80(sp)
ffffffffc020590a:	e4d6                	sd	s5,72(sp)
ffffffffc020590c:	e0da                	sd	s6,64(sp)
ffffffffc020590e:	fc5e                	sd	s7,56(sp)
ffffffffc0205910:	f06a                	sd	s10,32(sp)
ffffffffc0205912:	fc86                	sd	ra,120(sp)
ffffffffc0205914:	f8a2                	sd	s0,112(sp)
ffffffffc0205916:	f862                	sd	s8,48(sp)
ffffffffc0205918:	f466                	sd	s9,40(sp)
ffffffffc020591a:	ec6e                	sd	s11,24(sp)
ffffffffc020591c:	892a                	mv	s2,a0
ffffffffc020591e:	84ae                	mv	s1,a1
ffffffffc0205920:	8d32                	mv	s10,a2
ffffffffc0205922:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205924:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205928:	5b7d                	li	s6,-1
ffffffffc020592a:	00003a97          	auipc	s5,0x3
ffffffffc020592e:	ea2a8a93          	addi	s5,s5,-350 # ffffffffc02087cc <buddy_pmm_manager+0x14a4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205932:	00003b97          	auipc	s7,0x3
ffffffffc0205936:	076b8b93          	addi	s7,s7,118 # ffffffffc02089a8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020593a:	000d4503          	lbu	a0,0(s10)
ffffffffc020593e:	001d0413          	addi	s0,s10,1
ffffffffc0205942:	01350a63          	beq	a0,s3,ffffffffc0205956 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0205946:	c121                	beqz	a0,ffffffffc0205986 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0205948:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020594a:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020594c:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020594e:	fff44503          	lbu	a0,-1(s0)
ffffffffc0205952:	ff351ae3          	bne	a0,s3,ffffffffc0205946 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205956:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020595a:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020595e:	4c81                	li	s9,0
ffffffffc0205960:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0205962:	5c7d                	li	s8,-1
ffffffffc0205964:	5dfd                	li	s11,-1
ffffffffc0205966:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc020596a:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020596c:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205970:	0ff5f593          	zext.b	a1,a1
ffffffffc0205974:	00140d13          	addi	s10,s0,1
ffffffffc0205978:	04b56263          	bltu	a0,a1,ffffffffc02059bc <vprintfmt+0xbc>
ffffffffc020597c:	058a                	slli	a1,a1,0x2
ffffffffc020597e:	95d6                	add	a1,a1,s5
ffffffffc0205980:	4194                	lw	a3,0(a1)
ffffffffc0205982:	96d6                	add	a3,a3,s5
ffffffffc0205984:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0205986:	70e6                	ld	ra,120(sp)
ffffffffc0205988:	7446                	ld	s0,112(sp)
ffffffffc020598a:	74a6                	ld	s1,104(sp)
ffffffffc020598c:	7906                	ld	s2,96(sp)
ffffffffc020598e:	69e6                	ld	s3,88(sp)
ffffffffc0205990:	6a46                	ld	s4,80(sp)
ffffffffc0205992:	6aa6                	ld	s5,72(sp)
ffffffffc0205994:	6b06                	ld	s6,64(sp)
ffffffffc0205996:	7be2                	ld	s7,56(sp)
ffffffffc0205998:	7c42                	ld	s8,48(sp)
ffffffffc020599a:	7ca2                	ld	s9,40(sp)
ffffffffc020599c:	7d02                	ld	s10,32(sp)
ffffffffc020599e:	6de2                	ld	s11,24(sp)
ffffffffc02059a0:	6109                	addi	sp,sp,128
ffffffffc02059a2:	8082                	ret
            padc = '0';
ffffffffc02059a4:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02059a6:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02059aa:	846a                	mv	s0,s10
ffffffffc02059ac:	00140d13          	addi	s10,s0,1
ffffffffc02059b0:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02059b4:	0ff5f593          	zext.b	a1,a1
ffffffffc02059b8:	fcb572e3          	bgeu	a0,a1,ffffffffc020597c <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02059bc:	85a6                	mv	a1,s1
ffffffffc02059be:	02500513          	li	a0,37
ffffffffc02059c2:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02059c4:	fff44783          	lbu	a5,-1(s0)
ffffffffc02059c8:	8d22                	mv	s10,s0
ffffffffc02059ca:	f73788e3          	beq	a5,s3,ffffffffc020593a <vprintfmt+0x3a>
ffffffffc02059ce:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02059d2:	1d7d                	addi	s10,s10,-1
ffffffffc02059d4:	ff379de3          	bne	a5,s3,ffffffffc02059ce <vprintfmt+0xce>
ffffffffc02059d8:	b78d                	j	ffffffffc020593a <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02059da:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02059de:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02059e2:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02059e4:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02059e8:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02059ec:	02d86463          	bltu	a6,a3,ffffffffc0205a14 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02059f0:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02059f4:	002c169b          	slliw	a3,s8,0x2
ffffffffc02059f8:	0186873b          	addw	a4,a3,s8
ffffffffc02059fc:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205a00:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0205a02:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205a06:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205a08:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205a0c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205a10:	fed870e3          	bgeu	a6,a3,ffffffffc02059f0 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205a14:	f40ddce3          	bgez	s11,ffffffffc020596c <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205a18:	8de2                	mv	s11,s8
ffffffffc0205a1a:	5c7d                	li	s8,-1
ffffffffc0205a1c:	bf81                	j	ffffffffc020596c <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0205a1e:	fffdc693          	not	a3,s11
ffffffffc0205a22:	96fd                	srai	a3,a3,0x3f
ffffffffc0205a24:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205a28:	00144603          	lbu	a2,1(s0)
ffffffffc0205a2c:	2d81                	sext.w	s11,s11
ffffffffc0205a2e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205a30:	bf35                	j	ffffffffc020596c <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0205a32:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205a36:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205a3a:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205a3c:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0205a3e:	bfd9                	j	ffffffffc0205a14 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0205a40:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205a42:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205a46:	01174463          	blt	a4,a7,ffffffffc0205a4e <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0205a4a:	1a088e63          	beqz	a7,ffffffffc0205c06 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0205a4e:	000a3603          	ld	a2,0(s4)
ffffffffc0205a52:	46c1                	li	a3,16
ffffffffc0205a54:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205a56:	2781                	sext.w	a5,a5
ffffffffc0205a58:	876e                	mv	a4,s11
ffffffffc0205a5a:	85a6                	mv	a1,s1
ffffffffc0205a5c:	854a                	mv	a0,s2
ffffffffc0205a5e:	e37ff0ef          	jal	ra,ffffffffc0205894 <printnum>
            break;
ffffffffc0205a62:	bde1                	j	ffffffffc020593a <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0205a64:	000a2503          	lw	a0,0(s4)
ffffffffc0205a68:	85a6                	mv	a1,s1
ffffffffc0205a6a:	0a21                	addi	s4,s4,8
ffffffffc0205a6c:	9902                	jalr	s2
            break;
ffffffffc0205a6e:	b5f1                	j	ffffffffc020593a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205a70:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205a72:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205a76:	01174463          	blt	a4,a7,ffffffffc0205a7e <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0205a7a:	18088163          	beqz	a7,ffffffffc0205bfc <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0205a7e:	000a3603          	ld	a2,0(s4)
ffffffffc0205a82:	46a9                	li	a3,10
ffffffffc0205a84:	8a2e                	mv	s4,a1
ffffffffc0205a86:	bfc1                	j	ffffffffc0205a56 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205a88:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0205a8c:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205a8e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205a90:	bdf1                	j	ffffffffc020596c <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0205a92:	85a6                	mv	a1,s1
ffffffffc0205a94:	02500513          	li	a0,37
ffffffffc0205a98:	9902                	jalr	s2
            break;
ffffffffc0205a9a:	b545                	j	ffffffffc020593a <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205a9c:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0205aa0:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205aa2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205aa4:	b5e1                	j	ffffffffc020596c <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0205aa6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205aa8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205aac:	01174463          	blt	a4,a7,ffffffffc0205ab4 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0205ab0:	14088163          	beqz	a7,ffffffffc0205bf2 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0205ab4:	000a3603          	ld	a2,0(s4)
ffffffffc0205ab8:	46a1                	li	a3,8
ffffffffc0205aba:	8a2e                	mv	s4,a1
ffffffffc0205abc:	bf69                	j	ffffffffc0205a56 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0205abe:	03000513          	li	a0,48
ffffffffc0205ac2:	85a6                	mv	a1,s1
ffffffffc0205ac4:	e03e                	sd	a5,0(sp)
ffffffffc0205ac6:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0205ac8:	85a6                	mv	a1,s1
ffffffffc0205aca:	07800513          	li	a0,120
ffffffffc0205ace:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205ad0:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205ad2:	6782                	ld	a5,0(sp)
ffffffffc0205ad4:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205ad6:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205ada:	bfb5                	j	ffffffffc0205a56 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205adc:	000a3403          	ld	s0,0(s4)
ffffffffc0205ae0:	008a0713          	addi	a4,s4,8
ffffffffc0205ae4:	e03a                	sd	a4,0(sp)
ffffffffc0205ae6:	14040263          	beqz	s0,ffffffffc0205c2a <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205aea:	0fb05763          	blez	s11,ffffffffc0205bd8 <vprintfmt+0x2d8>
ffffffffc0205aee:	02d00693          	li	a3,45
ffffffffc0205af2:	0cd79163          	bne	a5,a3,ffffffffc0205bb4 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205af6:	00044783          	lbu	a5,0(s0)
ffffffffc0205afa:	0007851b          	sext.w	a0,a5
ffffffffc0205afe:	cf85                	beqz	a5,ffffffffc0205b36 <vprintfmt+0x236>
ffffffffc0205b00:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205b04:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205b08:	000c4563          	bltz	s8,ffffffffc0205b12 <vprintfmt+0x212>
ffffffffc0205b0c:	3c7d                	addiw	s8,s8,-1
ffffffffc0205b0e:	036c0263          	beq	s8,s6,ffffffffc0205b32 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205b12:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205b14:	0e0c8e63          	beqz	s9,ffffffffc0205c10 <vprintfmt+0x310>
ffffffffc0205b18:	3781                	addiw	a5,a5,-32
ffffffffc0205b1a:	0ef47b63          	bgeu	s0,a5,ffffffffc0205c10 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205b1e:	03f00513          	li	a0,63
ffffffffc0205b22:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205b24:	000a4783          	lbu	a5,0(s4)
ffffffffc0205b28:	3dfd                	addiw	s11,s11,-1
ffffffffc0205b2a:	0a05                	addi	s4,s4,1
ffffffffc0205b2c:	0007851b          	sext.w	a0,a5
ffffffffc0205b30:	ffe1                	bnez	a5,ffffffffc0205b08 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205b32:	01b05963          	blez	s11,ffffffffc0205b44 <vprintfmt+0x244>
ffffffffc0205b36:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205b38:	85a6                	mv	a1,s1
ffffffffc0205b3a:	02000513          	li	a0,32
ffffffffc0205b3e:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0205b40:	fe0d9be3          	bnez	s11,ffffffffc0205b36 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205b44:	6a02                	ld	s4,0(sp)
ffffffffc0205b46:	bbd5                	j	ffffffffc020593a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205b48:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205b4a:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0205b4e:	01174463          	blt	a4,a7,ffffffffc0205b56 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0205b52:	08088d63          	beqz	a7,ffffffffc0205bec <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205b56:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205b5a:	0a044d63          	bltz	s0,ffffffffc0205c14 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0205b5e:	8622                	mv	a2,s0
ffffffffc0205b60:	8a66                	mv	s4,s9
ffffffffc0205b62:	46a9                	li	a3,10
ffffffffc0205b64:	bdcd                	j	ffffffffc0205a56 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205b66:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205b6a:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0205b6c:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205b6e:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0205b72:	8fb5                	xor	a5,a5,a3
ffffffffc0205b74:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205b78:	02d74163          	blt	a4,a3,ffffffffc0205b9a <vprintfmt+0x29a>
ffffffffc0205b7c:	00369793          	slli	a5,a3,0x3
ffffffffc0205b80:	97de                	add	a5,a5,s7
ffffffffc0205b82:	639c                	ld	a5,0(a5)
ffffffffc0205b84:	cb99                	beqz	a5,ffffffffc0205b9a <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205b86:	86be                	mv	a3,a5
ffffffffc0205b88:	00003617          	auipc	a2,0x3
ffffffffc0205b8c:	c4060613          	addi	a2,a2,-960 # ffffffffc02087c8 <buddy_pmm_manager+0x14a0>
ffffffffc0205b90:	85a6                	mv	a1,s1
ffffffffc0205b92:	854a                	mv	a0,s2
ffffffffc0205b94:	0ce000ef          	jal	ra,ffffffffc0205c62 <printfmt>
ffffffffc0205b98:	b34d                	j	ffffffffc020593a <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205b9a:	00003617          	auipc	a2,0x3
ffffffffc0205b9e:	c1e60613          	addi	a2,a2,-994 # ffffffffc02087b8 <buddy_pmm_manager+0x1490>
ffffffffc0205ba2:	85a6                	mv	a1,s1
ffffffffc0205ba4:	854a                	mv	a0,s2
ffffffffc0205ba6:	0bc000ef          	jal	ra,ffffffffc0205c62 <printfmt>
ffffffffc0205baa:	bb41                	j	ffffffffc020593a <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205bac:	00003417          	auipc	s0,0x3
ffffffffc0205bb0:	c0440413          	addi	s0,s0,-1020 # ffffffffc02087b0 <buddy_pmm_manager+0x1488>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205bb4:	85e2                	mv	a1,s8
ffffffffc0205bb6:	8522                	mv	a0,s0
ffffffffc0205bb8:	e43e                	sd	a5,8(sp)
ffffffffc0205bba:	0fc000ef          	jal	ra,ffffffffc0205cb6 <strnlen>
ffffffffc0205bbe:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0205bc2:	01b05b63          	blez	s11,ffffffffc0205bd8 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205bc6:	67a2                	ld	a5,8(sp)
ffffffffc0205bc8:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205bcc:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205bce:	85a6                	mv	a1,s1
ffffffffc0205bd0:	8552                	mv	a0,s4
ffffffffc0205bd2:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205bd4:	fe0d9ce3          	bnez	s11,ffffffffc0205bcc <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205bd8:	00044783          	lbu	a5,0(s0)
ffffffffc0205bdc:	00140a13          	addi	s4,s0,1
ffffffffc0205be0:	0007851b          	sext.w	a0,a5
ffffffffc0205be4:	d3a5                	beqz	a5,ffffffffc0205b44 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205be6:	05e00413          	li	s0,94
ffffffffc0205bea:	bf39                	j	ffffffffc0205b08 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205bec:	000a2403          	lw	s0,0(s4)
ffffffffc0205bf0:	b7ad                	j	ffffffffc0205b5a <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0205bf2:	000a6603          	lwu	a2,0(s4)
ffffffffc0205bf6:	46a1                	li	a3,8
ffffffffc0205bf8:	8a2e                	mv	s4,a1
ffffffffc0205bfa:	bdb1                	j	ffffffffc0205a56 <vprintfmt+0x156>
ffffffffc0205bfc:	000a6603          	lwu	a2,0(s4)
ffffffffc0205c00:	46a9                	li	a3,10
ffffffffc0205c02:	8a2e                	mv	s4,a1
ffffffffc0205c04:	bd89                	j	ffffffffc0205a56 <vprintfmt+0x156>
ffffffffc0205c06:	000a6603          	lwu	a2,0(s4)
ffffffffc0205c0a:	46c1                	li	a3,16
ffffffffc0205c0c:	8a2e                	mv	s4,a1
ffffffffc0205c0e:	b5a1                	j	ffffffffc0205a56 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0205c10:	9902                	jalr	s2
ffffffffc0205c12:	bf09                	j	ffffffffc0205b24 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205c14:	85a6                	mv	a1,s1
ffffffffc0205c16:	02d00513          	li	a0,45
ffffffffc0205c1a:	e03e                	sd	a5,0(sp)
ffffffffc0205c1c:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205c1e:	6782                	ld	a5,0(sp)
ffffffffc0205c20:	8a66                	mv	s4,s9
ffffffffc0205c22:	40800633          	neg	a2,s0
ffffffffc0205c26:	46a9                	li	a3,10
ffffffffc0205c28:	b53d                	j	ffffffffc0205a56 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205c2a:	03b05163          	blez	s11,ffffffffc0205c4c <vprintfmt+0x34c>
ffffffffc0205c2e:	02d00693          	li	a3,45
ffffffffc0205c32:	f6d79de3          	bne	a5,a3,ffffffffc0205bac <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205c36:	00003417          	auipc	s0,0x3
ffffffffc0205c3a:	b7a40413          	addi	s0,s0,-1158 # ffffffffc02087b0 <buddy_pmm_manager+0x1488>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205c3e:	02800793          	li	a5,40
ffffffffc0205c42:	02800513          	li	a0,40
ffffffffc0205c46:	00140a13          	addi	s4,s0,1
ffffffffc0205c4a:	bd6d                	j	ffffffffc0205b04 <vprintfmt+0x204>
ffffffffc0205c4c:	00003a17          	auipc	s4,0x3
ffffffffc0205c50:	b65a0a13          	addi	s4,s4,-1179 # ffffffffc02087b1 <buddy_pmm_manager+0x1489>
ffffffffc0205c54:	02800513          	li	a0,40
ffffffffc0205c58:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205c5c:	05e00413          	li	s0,94
ffffffffc0205c60:	b565                	j	ffffffffc0205b08 <vprintfmt+0x208>

ffffffffc0205c62 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205c62:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205c64:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205c68:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205c6a:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205c6c:	ec06                	sd	ra,24(sp)
ffffffffc0205c6e:	f83a                	sd	a4,48(sp)
ffffffffc0205c70:	fc3e                	sd	a5,56(sp)
ffffffffc0205c72:	e0c2                	sd	a6,64(sp)
ffffffffc0205c74:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205c76:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205c78:	c89ff0ef          	jal	ra,ffffffffc0205900 <vprintfmt>
}
ffffffffc0205c7c:	60e2                	ld	ra,24(sp)
ffffffffc0205c7e:	6161                	addi	sp,sp,80
ffffffffc0205c80:	8082                	ret

ffffffffc0205c82 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0205c82:	4781                	li	a5,0
ffffffffc0205c84:	00006717          	auipc	a4,0x6
ffffffffc0205c88:	39473703          	ld	a4,916(a4) # ffffffffc020c018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0205c8c:	88ba                	mv	a7,a4
ffffffffc0205c8e:	852a                	mv	a0,a0
ffffffffc0205c90:	85be                	mv	a1,a5
ffffffffc0205c92:	863e                	mv	a2,a5
ffffffffc0205c94:	00000073          	ecall
ffffffffc0205c98:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0205c9a:	8082                	ret

ffffffffc0205c9c <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205c9c:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205ca0:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205ca2:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0205ca4:	cb81                	beqz	a5,ffffffffc0205cb4 <strlen+0x18>
        cnt ++;
ffffffffc0205ca6:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0205ca8:	00a707b3          	add	a5,a4,a0
ffffffffc0205cac:	0007c783          	lbu	a5,0(a5)
ffffffffc0205cb0:	fbfd                	bnez	a5,ffffffffc0205ca6 <strlen+0xa>
ffffffffc0205cb2:	8082                	ret
    }
    return cnt;
}
ffffffffc0205cb4:	8082                	ret

ffffffffc0205cb6 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205cb6:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205cb8:	e589                	bnez	a1,ffffffffc0205cc2 <strnlen+0xc>
ffffffffc0205cba:	a811                	j	ffffffffc0205cce <strnlen+0x18>
        cnt ++;
ffffffffc0205cbc:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205cbe:	00f58863          	beq	a1,a5,ffffffffc0205cce <strnlen+0x18>
ffffffffc0205cc2:	00f50733          	add	a4,a0,a5
ffffffffc0205cc6:	00074703          	lbu	a4,0(a4)
ffffffffc0205cca:	fb6d                	bnez	a4,ffffffffc0205cbc <strnlen+0x6>
ffffffffc0205ccc:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205cce:	852e                	mv	a0,a1
ffffffffc0205cd0:	8082                	ret

ffffffffc0205cd2 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205cd2:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205cd6:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205cda:	cb89                	beqz	a5,ffffffffc0205cec <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205cdc:	0505                	addi	a0,a0,1
ffffffffc0205cde:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205ce0:	fee789e3          	beq	a5,a4,ffffffffc0205cd2 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205ce4:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205ce8:	9d19                	subw	a0,a0,a4
ffffffffc0205cea:	8082                	ret
ffffffffc0205cec:	4501                	li	a0,0
ffffffffc0205cee:	bfed                	j	ffffffffc0205ce8 <strcmp+0x16>

ffffffffc0205cf0 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205cf0:	c20d                	beqz	a2,ffffffffc0205d12 <strncmp+0x22>
ffffffffc0205cf2:	962e                	add	a2,a2,a1
ffffffffc0205cf4:	a031                	j	ffffffffc0205d00 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205cf6:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205cf8:	00e79a63          	bne	a5,a4,ffffffffc0205d0c <strncmp+0x1c>
ffffffffc0205cfc:	00b60b63          	beq	a2,a1,ffffffffc0205d12 <strncmp+0x22>
ffffffffc0205d00:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205d04:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205d06:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205d0a:	f7f5                	bnez	a5,ffffffffc0205cf6 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205d0c:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205d10:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205d12:	4501                	li	a0,0
ffffffffc0205d14:	8082                	ret

ffffffffc0205d16 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205d16:	ca01                	beqz	a2,ffffffffc0205d26 <memset+0x10>
ffffffffc0205d18:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205d1a:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205d1c:	0785                	addi	a5,a5,1
ffffffffc0205d1e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205d22:	fec79de3          	bne	a5,a2,ffffffffc0205d1c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205d26:	8082                	ret
