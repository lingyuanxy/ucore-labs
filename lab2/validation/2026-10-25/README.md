# 2026-10-25 李孟德机器重新验证

本目录记录对搭档 1444f66 原样代码的验证。搭档当时的记录保留在 ../../report/evidence/，本轮没有覆盖它们。

- partner-source-manifest.json：全部 77 个原文件路径、Git blob 与 SHA-256。
- build.txt、build-after-grade.txt：交叉编译输出；课程 grade 清理构建后重新生成可运行镜像。
- boot-buddy-64M/128M/256M.txt：默认 Buddy 与 SLUB 启动自检。
- three-backend-build.txt、three-backend-tests.txt：直接编译搭档独立驱动与原版分配器，三 PMM 后端通过。
- course-grade.txt：课程脚本实际 10/20 与非零退出，未改写结果。
- host-mmu.gdb/txt、host-tlb.gdb/txt、guest-kernel.gdb/txt：本机重新采集的 GDB 命令和输出。
- local-environment.json：真实工具版本及本轮 ELF/镜像摘要。
- summary.json：自动验证结果摘要；其中 partner_files_unchanged 只代表原文件哈希一致，不能解释成课程评分满分。

在 lab2 目录运行 make verify、make trace、make check-preservation。环境改变后可运行 python3 support/record_environment.py 更新对应版本与镜像摘要。源码之外的本机脚本使用个人 Makefile.local 选择工具路径。
