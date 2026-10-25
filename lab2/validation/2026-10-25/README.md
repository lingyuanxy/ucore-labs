# Lab2 验证证据

正式结论见 [实验报告第五节](../../实验报告.md#五测试与验证)。本目录为李孟德本机记录；搭档原现场保留在 [report/evidence](../../report/evidence/README.md)。

| 文件 | 用途 |
| --- | --- |
| `partner-source-manifest.json` | 搭档原始 77 文件清单；代码、测试和五份完整提示词逐项校验 |
| `local-environment.json`、`build*.txt` | 工具版本、ELF 摘要与构建记录 |
| `boot-buddy-*M.txt`、`three-backend-*.txt` | 三 RAM 启动及三分配器原专项 |
| `course-grade.txt` | 默认 Buddy 原评分 10/20 |
| `course-grade-best-fit.txt`、`best-fit-*` | 独立 Best Fit 20/20、启动和 GDB 选择证据 |
| `host-mmu.*`、`host-tlb.*`、`guest-kernel.*` | S Bare/Sv39、根项、TLB miss/refill/hit 与客户机单步 |
| `page-init-*` | 六种解析后 RAM 输入验证，不是完整畸形 DTB 测试 |
| `allocator-edge-*` | First Fit 两处已知尾插错误；同例 Best Fit/Buddy 通过 |
| `course-source-comparison.json` | 与桌面 ZIP 的参考代码和原测试核对 |
| `manual-source-manifest.json` | 14 页手册与实验一同款模板来源 |
| `screenshot-provenance.json` | 真实截图来源与 JPEG 摘要 |
| `summary.json` | 原综合验证结果；不包含新增缺陷用例的全通过承诺 |

在 `lab2/` 使用 `make verify`、`make trace`、`make audit-page-init`、`make audit-allocators`、`make check-preservation`。最后一个审查用例命令零退出表示成功复现预期缺陷，不表示 First Fit 无错误。
