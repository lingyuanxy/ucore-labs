# uCore RISC-V 实验

本项目来自配套材料 `lab1(1).zip`，使用 Windows VS Code + WSL2 Ubuntu 编译运行。

2026-10-08 已验证：编译成功，QEMU 能输出 `(THU.CST) os is loading ...`，GDB 能命中 `kern_init` 硬件断点。代码已推送到 GitHub。AI 的完整验证需要先在 Cline 中登录 ChatGPT Plus 或配置模型 API。

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
qemu-system-riscv64 --version
make
make qemu
```

QEMU 退出：按 `Ctrl+A`，松开后按 `X`。不要将这些 Linux 编译命令放在 Windows PowerShell 中运行。

也可以按 `Ctrl+Shift+B` 编译；在“终端 → 运行任务”中选择 QEMU 或 GDB 任务。

编译器来自 Ubuntu 官方软件包，位于 `/usr/bin`，已经处于 PATH 中；本工作区的新终端设有 `RISCV=/usr`，无需再添加下载工具链的路径。Node.js 与 npm 安装在 WSL 中，版本分别为 22.22.1 和 9.2.0。

为适配 QEMU 10.2.1 与当前 OpenSBI，Makefile 的运行、调试目标改用 `-kernel` 装载内核并提供启动入口；调试器优先使用工具链 GDB，缺失时使用 `gdb-multiarch`。未修改实验 C/汇编源代码。

调试时先启动 `uCore: debug server lab1`，然后在另一个终端运行 `uCore: GDB lab1`。默认 GDB 服务监听本机端口 1234。

## Cline + ChatGPT Plus（当前选用）

本机安装的 Cline 4.1.23 包含 ChatGPT 订阅登录功能。

1. 打开 WSL 工作区的 Cline 面板，进入设置。
2. API Provider 选择 `OpenAI ChatGPT Subscription`（内部提供方为 `openai-codex`）。
3. 点击 `Sign in to OpenAI Codex`，按插件提示完成浏览器登录或设备码授权，登录已有 Plus 账号。
4. 从提供方支持的模型列表中选择模型；若 Plan 和 Act 分别设置，分别确认使用相同提供方。
5. 发送下方验证提示词，实际确认它能读取当前项目。

这条路径不需要填写 OpenAI API Key。使用的额度受 ChatGPT 套餐限制；如果选择 API Key 路径，API 调用按用量单独计费，不抵扣 Plus 套餐。

若插件的订阅登录遇到兼容问题，可使用 VS Code 中已有的官方 Codex 扩展，选择 `Sign in with ChatGPT`。官方说明：[登录方式](https://learn.chatgpt.com/docs/auth)、[套餐](https://learn.chatgpt.com/docs/pricing)、[Codex IDE](https://learn.chatgpt.com/docs/codex/ide)。

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

原始压缩包包含 Makefile 的 `grade` 目标，但不包含它调用的 `tools/grade.sh`。因此当前材料无法完成 `make grade`，需要老师提供完整评分脚本。不要将此错误当作工具安装失败，也不要用自制测试冒充课程评分。

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
