# K05 · 双谱转移分析

[English](README.md) | [模块入口](../../docs/source/rst_files/K_Diagnostics/K05_bispectral_transfer.rst)

以Brown与Jorns（2023）的研究为线索，从波动方程走到同步双探针记录的分析。
文献：[doi:10.1103/PhysRevLett.130.115101](https://doi.org/10.1103/PhysRevLett.130.115101)。
九篇正文同级，按以下顺序阅读：

01. [波增长与耦合](../../docs/source/rst_files/K_Diagnostics/K05_wave_growth.rst)
02. [包络方程与系数来源](../../docs/source/rst_files/K_Diagnostics/K05_envelope_coefficients.rst)
03. [从波到探针记录](../../docs/source/rst_files/K_Diagnostics/K05_probe_signals.rst)
04. [谱统计量](../../docs/source/rst_files/K_Diagnostics/K05_spectral_statistics.rst)
05. [由统计量估计系数](../../docs/source/rst_files/K_Diagnostics/K05_coefficient_inference.rst)
06. [实测记录到统计量](../../docs/source/rst_files/K_Diagnostics/K05_experimental_signals.rst)
07. [实测统计量到L与Q](../../docs/source/rst_files/K_Diagnostics/K05_experimental_coefficients.rst)
08. [增长与转移的文献对照](../../docs/source/rst_files/K_Diagnostics/K05_growth_transfer.rst)
09. [脚本与复现指南](../../docs/source/rst_files/K_Diagnostics/K05_scripts.rst)

## 复现与约定

完整依赖顺序和命令见[EXPERIMENT.md](EXPERIMENT.md)。原始记录和完整数值数组需要另行取得；
06–08页使用可追溯的保存图，打开HTML不会运行分析。

| 脚本 | 用途 |
| --- | --- |
| `analyze_spectral_walkthrough.py` | 第06页：波形与复统计量 |
| `analyze_coefficient_walkthrough.py` | 第07页：实测矩阵、系数与留出预测 |
| `analyze_extended_comparison.py` | 第08页：统一20 MHz输入与四轮整组留出 |
| `analyze_physical_scenario.py` | 选定的流动冷离子情景及条件性群速度 |
| `plot_physical_comparison.py` | 文献近似重绘与本实验逐项对照 |

读取器、验证与功率收支脚本提供后续计算所需的输入；依赖顺序见复现说明。
第07页用5 MHz输入，第08页重新拟合20 MHz输入，不能拼接两套系数。
K05使用正指数／除以N的Fourier系数与`<Y conj(X)>`互谱，使用K01输出时需明确对齐约定。

给定输入波对且矩阵可辨识时，统计模型闭合。物理速率还依赖测量响应标定、传播方向、
波变量归一化和有依据的色散分支。1 cm有效加速长度与15°倾斜均为选定假设。
文献面板是注明来源的图像近似重绘，不是作者原始数据，见[来源说明](reference_digitization/README.md)。

## 运行与测试

这些程序是针对当前数据的命令行示例，包含可复用的数值函数；并非已安装的Python包。
请保留整个模块目录。第09页说明读取器支持范围、数组接口与可选工具。在仓库根目录运行：

```bash
python -m pip install -r K_Diagnostics/K05_bispectral_transfer/requirements.txt
python K_Diagnostics/K05_bispectral_transfer/analyze_spectral_walkthrough.py --help
python -m unittest discover -s K_Diagnostics/K05_bispectral_transfer -p 'test_*.py' -v
```

同目录的`test_*.py`是独立于未公开记录的确定性测试，覆盖读取器、Fourier/PSD归一化、
系数恢复、训练／测试隔离、Kim统计矩、功率收支和动理学导数。walkthrough脚本是面向使用者的示例；
保存数组的依赖见EXPERIMENT.md。已检查环境为Python3.12.3、NumPy2.3.4、SciPy1.16.3、
Matplotlib3.10.7；并不表示已验证所有版本与操作系统组合。

## 构建与维护

在合适的环境安装仓库`docs/requirements.txt`；文档配置还会调用Doxygen。从仓库根目录运行：

```bash
python K_Diagnostics/K05_bispectral_transfer/renumber_equations.py --check
python -m sphinx -b html -E -a -W --keep-going docs/source docs/build/html
python -m http.server 8055 --bind 127.0.0.1 --directory docs/build/html
```

编辑`docs/source/rst_files/K_Diagnostics/K05_*.rst`，不直接修改生成的HTML。
英文视图保持纯英文，中文可括注英文术语。连续双语编号和稳定语义ID见[EQUATIONS.md](EQUATIONS.md)。
互动图资源保存在`docs/source/_static/K_Diagnostics`；波包、邻近波带和双探针示意使用示意参数。

保留的JSON及用途见[数据文件说明](DATA_FILES.md)。
