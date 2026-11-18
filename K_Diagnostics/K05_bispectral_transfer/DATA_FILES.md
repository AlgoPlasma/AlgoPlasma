<!-- K05 contribution history (Git author dates; edit times include timezone).
2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)
-->

# K05 tracked data files / 保留数据文件说明

JSON is a storage format, not a reason to keep or remove a file. These files are
required inputs or compact scientific provenance for maintained examples.
JSON只是格式；下面保留的是运行输入、公式索引和当前图形的精简来源记录。

Paths below are relative to this module unless beginning with `docs/` (repository root).
除以`docs/`开头的仓库相对路径外，下面路径均相对本模块。

| File | Purpose / 用途 |
| --- | --- |
| `experiment_z5p5_a3p7.json` | Acquisition facts and explicit unknown calibrations / 采集事实及未知标定；多个分析脚本的默认输入 |
| `paper_comparison_config.json` | Reproduce the spectrum parent and earlier kinetic comparison / 复现谱父结果及较早动理学情景 |
| `physical_scenario_config.json` | Selected moving-ion scenario used on page08 / 第08页当前物理情景参数 |
| `probe_response_config.json` | Optional response/sweep settings / 可选探针响应及慢扫描设置 |
| `probe_sweep_config.json` | Optional mean I–V analysis settings / 可选平均I–V分析设置 |
| `reference_digitization/provenance.json` | Source and hashes of approximate reference redraws / 文献近似重绘的来源与哈希 |
| `docs/source/_data/k05_equations.json` | Required by the Sphinx equation extension / 构建公式编号和跨页链接所必需 |
| `docs/source/_static/K_Diagnostics/k05-walkthrough-summary.json` | Settings, hashes and checks for page06 / 第06页结果的配置、哈希与数值检查 |
| `docs/source/_static/K_Diagnostics/k05-fit-summary.json` | Parent provenance and worked-fit checks for page07 / 第07页父结果与实测拟合检查 |
| `docs/source/_data/k05_extended_comparison_summary.json` | Four-fold 20 MHz fit provenance for page08 / 第08页扩展拟合的配置与检查 |
| `docs/source/_data/k05_physical_scenario_summary.json` | Scenario, root and conversion checks for page08 / 第08页物理情景、求根与换算检查 |

Full raw captures, full numerical NPZ results, console logs, personal AI-agent
instructions, handoffs and historical revision snapshots do not belong in this
module's published data. Run producers into a separate local result folder.
原始记录、大型数值结果、控制台日志、个人代理指令／交接和历史修订快照应放在仓库外的本地结果目录。

Keep scientific provenance with its corresponding figure; do not relabel an old
result as a new run. Changing a configuration requires rerunning the affected
analysis before updating published outputs.
科学来源记录应与对应图形配套；修改配置后须重算受影响结果，不将旧输出冒充新运行。
