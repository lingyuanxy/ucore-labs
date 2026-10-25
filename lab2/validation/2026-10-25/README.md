# 2026-10-25 李孟德机器重新验证

本目录记录对搭档 1444f66 原样代码的验证。搭档当时的记录保留在 ../../report/evidence/，原始代码与附件日志保持不变；正式报告和截图目录说明已更新。

- partner-source-manifest.json：全部 77 个原文件路径、Git blob 与 SHA-256。
- build.txt、build-after-grade.txt：交叉编译输出；课程 grade 清理构建后重新生成可运行镜像。
- boot-buddy-64M/128M/256M.txt：默认 Buddy 与 SLUB 启动自检。
- three-backend-build.txt、three-backend-tests.txt：直接编译搭档独立驱动与原版分配器，三 PMM 后端通过。
- course-grade.txt：课程脚本实际 10/20 与非零退出，未改写结果。
- host-mmu.gdb/txt、host-tlb.gdb/txt、guest-kernel.gdb/txt：本机重新采集的 GDB 命令和输出。
- local-environment.json：真实工具版本及本轮 ELF/镜像摘要。
- summary.json：自动验证结果摘要；其中 partner_code_unchanged 代表原实现和测试驱动受保护，不能解释成所有非代码报告文本也不允许更新。

在 lab2 目录运行 make verify、make trace、make check-preservation。环境改变后可运行 python3 support/record_environment.py 更新对应版本与镜像摘要。源码之外的本机脚本使用个人 Makefile.local 选择工具路径。

新增 Best Fit 独立验证：course-grade-best-fit.txt 是原评分脚本在该配置下的 20/20；best-fit-grade-boot.txt 为真实启动输出；best-fit-selection.txt/gdb 记录在初始化前选中 Best Fit 并实际进入 init/check。它使用 O0 调试构建，日常 Buddy 仍是原版 O2 构建。

新增 screenshot-provenance.json 保存真实 IDE 截图的来源工作目录、ELF 摘要和原 JPEG 摘要；图片在 report/images。两份允许更新的非代码文档为 report/report.md 与 report/images/README.md，其他原文件仍受 SHA-256 保护。
