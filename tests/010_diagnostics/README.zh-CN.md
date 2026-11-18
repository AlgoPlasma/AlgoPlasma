# 010_diagnostics

[English](README.md)

这里收录 `K_Diagnostics` 中 K01–K03 的基础数值测试和宽带诊断链测试。

这些算例覆盖[探针波动诊断专题](../../docs/source/rst_files/K_Diagnostics/probe_wave_diagnostics.rst)。基础检查直接提供数值输入。宽带算例从合成的探针时间序列出发，检验频谱、相位统计和波矢反演。数值例程本身不读写文件，由测试驱动程序提供输入并组织计算。

- `case_basic_checks` 是**基础数值测试**。三组验证的参考值、测量值、误差、验收规则和状态由同次运行生成。附图可展开查看，六面板谱泄漏图的解释见知识页。完整报告保留底层的 16 项回归检查。运行 `bash case_basic_checks/run.sh`，加 `--publish-docs` 可更新文档快照。
- `case_broadband_dispersion` 在同一组合成宽带数据上串联 K01、K02 和 K03，并将各单元的输出与数据生成器给定的结果对照。

宽带算例只用 Python，因此 `make.sh` 负责生成合成记录，`run.sh` 依次调用三个单元处理记录。每次运行都会根据 `source_py/config.py` 的常量重建较大的波形记录，`clean.sh` 会删除这些记录。各算例独立清理自己的运行产物。基础检查的小型文档快照单独存放在 `docs/source/tests/010_diagnostics/_generated/case_basic_checks`，纳入版本控制。

验收标准将测量结果与生成器给定的谱指数、折叠波数峰值和离子声速进行比较。K02 的单探针对检查不要求恢复混叠丢失的折叠阶数。

K04 有[独立测试算例](../011_K04_breathing_waveform/README.zh-CN.md)，其中包含测试、示例、绘图和清理说明。
