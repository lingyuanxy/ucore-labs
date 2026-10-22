# uCore RISC-V 实验

本项目来自配套材料 `lab1(1).zip`，使用 Windows VS Code + WSL2 Ubuntu 编译运行。

2026-10-09 已按老师要求将操作系统实验固定为 QEMU **4.1.1**，使用自带 OpenSBI v0.4，实际启动输出 `(THU.CST) os is loading ...`。现有 QEMU 10.2.1 和 `/opt/qemu` 中的 7.0.0 均保留，系统默认版本不变。Cline 的 Plus 订阅调用已成功读取源码、执行终端命令并生成解释。

## 实验二：物理内存和页表

- [实验二报告](lab2/实验报告.md)、[学习路线](lab2/学习路线.md)、[SPEC 与提示词](lab2/SPEC与提示词.md)。
- 已完成物理内存初始化、Best Fit、Buddy System、SLUB 选做和 QEMU/MMU 的 GDB 调试。
- 课程评分 20/20；两种 PMM 各在 64/128/256 MiB RAM 上通过启动和 SLUB 检查，真实日志见 `lab2/evidence`。
- WSL 终端进入 `lab2` 后运行 `make qemu`；Buddy 用 `make PMM=buddy qemu`；评分用 `make grade`。
- 详细复现及其他电脑配置见 [Lab2 使用说明](lab2/README.md)。

## 实验一报告

- [最新实验报告](lab1/实验报告.md)
- [原始报告模板](lab1/实验报告模板.md)

报告截图保存在 `lab1/images`。后续直接在上述报告上修改、保存并同步仓库，保持一份正式报告。

## 打开项目

李孟德在自己的 Windows PowerShell 中运行（这是李孟德的项目路径）：

```powershell
code --new-window --folder-uri 'vscode-remote://wsl+Ubuntu/mnt/c/Users/李孟德/Documents/Codex/2026-10-08/vscode/outputs/ucore-labs'
```

确认 VS Code 左下角显示 `WSL: Ubuntu`。若出现工作区信任提示，确认路径是自己的实验项目后信任。新建终端应是 Ubuntu 的 bash。

朱钟铭的项目目录没有在提交中提供，需在 VS Code 中打开他自己的仓库目录，不使用上面的李孟德目录。

## 两人的路径与本地配置

共享 `lab1/Makefile` 管理编译、运行和调试规则；每台电脑的工具路径放在 `lab1/Makefile.local`。后者已被 Git 忽略，推送和拉取不会把一人的配置覆盖给另一人。

| 项目 | 2413170－李孟德 | 2412075－朱钟铭 |
| --- | --- | --- |
| Ubuntu 用户目录 | `/home/lingyuan` | `/home/viewfinder` |
| 编译器路径前缀 GCCPREFIX | `/home/lingyuan/riscv-elf-toolchains/bin/riscv64-unknown-elf-` | `/home/viewfinder/toolchains/os-freedom-tools/bin/riscv64-unknown-elf-` |
| 调试器 GDB | `/home/lingyuan/riscv-elf-toolchains/bin/riscv64-unknown-elf-gdb` | `/home/viewfinder/toolchains/os-freedom-tools/bin/riscv64-unknown-elf-gdb` |
| QEMU 4.1.1 | `/opt/qemu-4.1.1/bin/qemu-system-riscv64` | 提交中使用相同路径 `/opt/qemu-4.1.1/bin/qemu-system-riscv64` |
| 配置示例 | [Makefile.local.limengde.example](lab1/Makefile.local.limengde.example) | [Makefile.local.zhuzhongming.example](lab1/Makefile.local.zhuzhongming.example) |
| 默认加载方式 | `QEMU_LOAD=loader`，对应李孟德报告截图 | `QEMU_LOAD=elf`，保留朱钟铭提交中的方式 |

李孟德的工具路径已在本机核对；朱钟铭的路径来自提交 `c73a1b9`，尚未在他的电脑上核验。两人的工具链版本可能不同，重新编译后的指令地址和展开形式也可能不同。报告中的实测地址来自李孟德当时的构建。

首次配置时，在各自的 WSL 终端进入仓库的 `lab1`，选择自己的命令。已有 `Makefile.local` 时先查看内容，按需编辑，避免覆盖自己的配置。

李孟德：

```bash
cp Makefile.local.limengde.example Makefile.local
```

朱钟铭：

```bash
cp Makefile.local.zhuzhongming.example Makefile.local
```

`GCCPREFIX` 是工具名称前缀，Makefile 会在末尾加上 `gcc`、`ld`、`objcopy` 等名称。它不是项目目录。命令行赋值优先于本地配置，例如 `make QEMU_LOAD=loader qemu`。

## Makefile 的区别

| 项目 | 李孟德原配置及报告操作 | 朱钟铭的提交 c73a1b9 | 当前共享规则 |
| --- | --- | --- | --- |
| 编译工具 | 从 PATH 查找工具，报告实测 GCC 15.1.0 | 固定 `/home/viewfinder/...` 前缀 | 从各自的 `Makefile.local` 读取路径 |
| 内核加载 | `-device loader,file=bin/ucore.img,addr=0x80200000` | `-kernel bin/kernel` | 由 `QEMU_LOAD` 选择，默认 `loader` |
| GDB 启动 | 使用 Makefile 的 GDB 变量 | gdb 目标直接写 `riscv64-unknown-elf-gdb`，没有使用配置的 GDB 变量 | 使用各自配置的 GDB 变量 |
| 调试连接 | TCP，端口 1234 | TCP，端口 1234 | TCP `127.0.0.1:1234`；可设置 GDB_PORT |

`bin/kernel` 是带入口、段布局、符号和调试信息的 ELF 文件；`bin/ucore.img` 是由它转换得到的原始二进制。`loader` 方式显式把原始镜像放在 `0x80200000`；`elf` 方式通过 QEMU 的 `-kernel` 参数提供 ELF，由 QEMU 的内核加载逻辑处理。两者是加载同一内核的不同方法，报告仍保留当时实际使用的 loader 记录。

本次修正使 `Makefile.local` 真正生效；当前没有实现 README 旧描述中的默认 Unix 套接字或 `GDB_TRANSPORT` 切换。

## 编译与运行

```bash
cd lab1
# 首次先按上文选好自己的 Makefile.local
make print-gccprefix print-gdb print-qemu print-qemu_load
/opt/qemu-4.1.1/bin/qemu-system-riscv64 --version
make
make qemu
```

QEMU 退出：按 `Ctrl+A`，松开后按小写 `x`。不要将这些 Linux 编译命令放在 Windows PowerShell 中运行。

也可以按 `Ctrl+Shift+B` 编译；在“终端 → 运行任务”中选择 QEMU 或 GDB 任务。

李孟德本机还装有 `/usr/bin` 下的 Ubuntu 软件包编译器；本实验的本地配置明确选择 `/home/lingyuan/riscv-elf-toolchains/bin/` 中的 GCC 15.1.0，以对应报告实测版本。`RISCV=/usr` 不会覆盖这里配置的 GCCPREFIX。Node.js 与 npm 安装在 WSL 中，版本分别为 22.22.1 和 9.2.0。

源码搜索工具 `ripgrep`（`rg`）已安装，版本 15.1.0。

没有本地配置时，共享 Makefile 默认从 PATH 查找交叉编译工具及 GDB（缺失时查找 `gdb-multiarch`），QEMU 默认固定为 `/opt/qemu-4.1.1/bin/qemu-system-riscv64`。其他电脑可使用通用配置示例 `lab1/Makefile.local.example`。未修改实验 C/汇编源代码。

VS Code 任务和终端里的 `make` 都读取同一份本地配置。李孟德本机已配置自己的工具路径；朱钟铭更新后按上文配置自己的电脑。已有新版 QEMU 保留，系统默认命令不变；本实验实际版本应通过 `make print-qemu` 输出的路径及该程序的 `--version` 核对。

4.1.1 来自 [QEMU 官方源码包](https://download.qemu.org/qemu-4.1.1.tar.xz)，独立安装到 `/opt/qemu-4.1.1`，包括 riscv32、riscv64 系统模拟器及其配套固件。未替换 `/usr/bin` 或 `/opt/qemu` 中的现有程序。

调试时在 `lab1` 目录的两个 WSL 终端中分别运行 `make debug` 和 `make gdb`，也可以依次启动 VS Code 的 `uCore: debug server lab1` 和 `uCore: GDB lab1` 任务。默认通过 TCP `127.0.0.1:1234` 连接。

`make gdb` 会自动连接。出现 `(gdb)` 后直接执行 `info registers pc`、`x/8i $pc` 或 `si`。首次连接应看到 PC 为 `0x1000`。在 QEMU 终端按 `Ctrl+A`，松开后按小写 `x` 退出。

更换端口时，两条命令都加上相同的 `GDB_PORT=1235`。历史实验截图保持为当时的操作记录。

## Cline + ChatGPT Plus（当前选用）

本机安装的 Cline 4.1.23 包含 ChatGPT 订阅登录功能。

1. 打开 WSL 工作区的 Cline 面板。首次看到 `How will you use Cline?` 时，选择 `Bring my own API key`，点击 `Continue`，进入 `Configure your provider`。这个入口也支持订阅授权，不要求必须有 API Key；配置过之后可以直接进入设置。
2. API Provider 选择 `OpenAI ChatGPT Subscription`（内部提供方为 `openai-codex`）。
3. 点击 `Sign in to OpenAI Codex`，按插件提示完成浏览器登录或设备码授权，登录已有 Plus 账号。
4. 从提供方支持的模型列表中选择模型；若 Plan 和 Act 分别设置，分别确认使用相同提供方。
5. 发送下方验证提示词，实际确认它能读取当前项目。

这条路径不需要填写 OpenAI API Key。使用的额度受 ChatGPT 套餐限制；如果选择 API Key 路径，API 调用按用量单独计费，不抵扣 Plus 套餐。

若插件的订阅登录遇到兼容问题，可使用 VS Code 中已有的官方 Codex 扩展，选择 `Sign in with ChatGPT`。官方说明：[登录方式](https://learn.chatgpt.com/docs/auth)、[套餐](https://learn.chatgpt.com/docs/pricing)、[Codex IDE](https://learn.chatgpt.com/docs/codex/ide)。

本机曾出现浏览器登录成功、Cline 请求仍报缺少 API Key：WSL 直接访问 OpenAI 认证服务返回 403，通过现有 Windows 代理则返回 200。已为 VS Code 的 WSL 服务设置启动代理环境，并验证 Node 的 fetch 返回 200。OpenAI 调用时需要保持现有代理运行。服务重启后，在 Cline 中退出并重新完成一次订阅登录，再发起新对话验证。相关配置方式见 [VS Code WSL 环境与代理说明](https://code.visualstudio.com/docs/remote/wsl) 和 [Node 环境代理说明](https://nodejs.org/learn/http/enterprise-network-configuration)。

## Cline + DeepSeek（可选）

1. 在 WSL 窗口的扩展中确认 Cline 已安装到 `WSL: Ubuntu`；必要时点击“在 WSL: Ubuntu 中安装”。
2. 打开 Cline 面板，进入设置，API Provider 选择 `DeepSeek`。
3. 在 <https://platform.deepseek.com/> 的 API Keys 页面创建密钥，在 Cline 中填写。不要写到项目文件里。
4. 模型选择以官方当前可用模型和 Cline 支持情况为准。若内置提供方只显示旧模型，可选择 `OpenAI Compatible`，Base URL 填 `https://api.deepseek.com`，Model ID 按官方文档填写（2026-10-08 官方示例为 `deepseek-flash`）。
5. Plan 和 Act 若分别配置，需要分别确认服务商与模型。先保留对文件修改和终端命令的审批。

## AI 环境验证

验证提示词（登录任意提供方后使用）：

```text
读取 lab1/kern/init/init.c，解释 kern_init 的作用，暂时不要修改代码。
```

```text
在 notes/ai-test.md 中创建三行环境验证文字，展示改动，然后等待我检查。
```

```text
在 lab1 目录运行 make，再运行 make qemu；看到内核启动文字后退出 QEMU。说明实际输出。
```

确认测试文件后可自行删除。新的未跟踪文件不会显示在普通 `git diff` 中，可以用 `git status --short` 和编辑器查看。

## 评分脚本缺失

原始压缩包包含 Makefile 的 `grade` 目标，但不包含它调用的 `tools/grade.sh`，实际运行 make grade 会因文件不存在而失败。这是本地文件和命令检查的结果，不能据此确定老师必须要求 make grade，也不能断定压缩包不完整：该目标可能来自通用 Makefile 模板，具体以实验一任务书为准。若老师明确要求 make grade，再确认该实验适用的评分脚本及其实际依赖。当前编译与 QEMU 启动已经验证成功；不要把脚本不存在说成评分通过。

## GitHub

远程地址：`https://github.com/lingyuanxy/ucore-labs.git`。

本仓库的提交姓名设为 `lingyuanxy`，邮箱设为 `lingyuanxy@users.noreply.github.com`，只影响此仓库。若需要 GitHub 自动关联提交，使用 GitHub “Settings → Emails” 中显示的准确 noreply 邮箱。

在 VS Code 源代码管理面板审查改动、提交，再“推送”；首次访问私有仓库时按 GitHub 登录提示完成认证。GitHub HTTPS 推送使用登录授权或访问令牌，不使用账户密码。

```bash
git status
git diff
git add .
git commit -m "Set up uCore lab environment"
git push -u origin main
```

`bin/`、`obj/`、`.env` 等已通过 `.gitignore` 排除。

参考：[VS Code WSL](https://code.visualstudio.com/docs/remote/wsl)、[Cline DeepSeek 配置](https://github.com/cline/cline/blob/main/docs/provider-config/deepseek.mdx)、[DeepSeek API](https://api-docs.deepseek.com/en/)、[GitHub 上传本地代码](https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github)。
