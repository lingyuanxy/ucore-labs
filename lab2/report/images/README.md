# Lab2 真实调试截图

- [01-buddy-breakpoint.jpg](01-buddy-breakpoint.jpg)：真实 QEMU 运行到 Buddy 检查入口的 VS Code 调试界面，含源码、调用栈和调试控制台。
- [02-slub-breakpoint.jpg](02-slub-breakpoint.jpg)：Buddy 检查返回后到达 SLUB 检查入口的真实界面。

由 computer-use 的窗口捕获工具采集，保存原始 JPEG，未用日志绘图或 AI 生成截图。本目录截图已在 ../report.md 的第 13.4 节引用。

截图记录的是断点现场，完整测试通过以原始运行日志为依据。IDE 的 Hit breakpoint/暂停原因标签不是内核 panic；O2 下的 optimized out 也按原貌保留。

截图来自原有受信任的 ucore-labs 工作目录，其 code/ 原文件与当前工作目录逐字一致。源码哈希依据见 ../../validation/2026-10-25/partner-source-manifest.json。
