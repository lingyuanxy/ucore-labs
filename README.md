# uCore RISC-V 实验

本项目来自配套材料 `lab1(1).zip`，使用 Windows VS Code + WSL2 Ubuntu 编译运行。

2026-10-09 已按老师要求将操作系统实验固定为 QEMU **4.1.1**，使用自带 OpenSBI v0.4，实际启动输出 `(THU.CST) os is loading ...`。现有 QEMU 10.2.1 和 `/opt/qemu` 中的 7.0.0 均保留，系统默认版本不变。Cline 的 Plus 订阅调用已成功读取源码、执行终端命令并生成解释。

## 打开项目

在 Windows PowerShell 中运行：

```powershell
code --new-window --folder-uri 'vscode-remote://wsl+Ubuntu/mnt/c/Users/李孟德/Documents/Codex/2026-10-08/vscode/outputs/ucore-labs'
```

确认 VS Code 左下角显示 `WSL: Ubuntu`。若出现工作区信任提示，确认路径是自己的实验项目后信任。新建终端应是 Ubuntu 的 bash。

## 编译与运行

```bash
cd lab1
riscv64-unknown-elf-gcc --version
/opt/qemu-4.1.1/bin/qemu-system-riscv64 --version
make print-qemu
make
make qemu
```

QEMU 退出：按 `Ctrl+A`，松开后按 `X`。不要将这些 Linux 编译命令放在 Windows PowerShell 中运行。

也可以按 `Ctrl+Shift+B` 编译；在“终端 → 运行任务”中选择 QEMU 或 GDB 任务。

编译器来自 Ubuntu 官方软件包，位于 `/usr/bin`，已经处于 PATH 中；本工作区的新终端设有 `RISCV=/usr`，无需再添加下载工具链的路径。Node.js 与 npm 安装在 WSL 中，版本分别为 22.22.1 和 9.2.0。

源码搜索工具 `ripgrep`（`rg`）已安装，版本 15.1.0。

本实验 Makefile 的默认 `QEMU` 为 `/opt/qemu-4.1.1/bin/qemu-system-riscv64`，运行、调试目标恢复课程原来的 `-device loader,file=bin/ucore.img,addr=0x80200000` 参数。调试器优先使用工具链 GDB，缺失时使用 `gdb-multiarch`。未修改实验 C/汇编源代码。

仅此工作区的 VS Code 新终端设置了 `QEMU` 环境变量，方便后续实验中采用 `ifndef QEMU` 的 Makefile 使用同一版本；全局 PATH 没有添加旧版路径。修改配置前已打开的终端需要关闭后新建。直接运行 `qemu-system-riscv64 --version` 仍可能显示 10.2.1，这是系统默认版本；本实验实际版本应通过上面的完整路径和 `make print-qemu` 检查。其他项目按原来的命令使用已有新版。

4.1.1 来自 [QEMU 官方源码包](https://download.qemu.org/qemu-4.1.1.tar.xz)，独立安装到 `/opt/qemu-4.1.1`，包括 riscv32、riscv64 系统模拟器及其配套固件。未替换 `/usr/bin` 或 `/opt/qemu` 中的现有程序。

调试时先启动 `uCore: debug server lab1`，然后在另一个终端运行 `uCore: GDB lab1`。默认 GDB 服务监听本机端口 1234。

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
