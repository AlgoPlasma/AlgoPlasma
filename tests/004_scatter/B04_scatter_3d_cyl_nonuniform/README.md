# B04 nonuniform cylindrical scatter tests

[双语 Sphinx 测试页 / Bilingual Sphinx test page](../../../docs/source/tests/004_scatter/B04_scatter_3d_cyl_nonuniform.rst) · [本地编译网页 / Local HTML](../../../docs/build/html/tests/004_scatter/B04_scatter_3d_cyl_nonuniform.html)

测试页提供算例说明、双语结果图和误差判据。The page includes case descriptions, bilingual figures and error criteria.

## 中文：验证什么

测试入口 [source_f90/main.f90](source_f90/main.f90) 直接调用
`mod_B04_scatter_3d_cyl_nonuniform` 的四个公开子程序。均匀网格对照直接编译、调用
`mod_B02_deposit_charge_3d_cyl` 的公开电荷沉积例程。测试中的手算数值、Gauss 积分、
物理单元体积和解析场积分用于独立构造期望结果。

| 算例 | 输入与参考 | 检查内容 |
|---|---|---|
| 八节点手算 | `r=[1,2,4]`、`phi=[0,1,3]`、`z=[0,2,3]`；位置 `[1.25,0.5,0.5]`，贡献量 8 | 节点体积、八项增量、总量、正负抵消、零增量、不同实参数组下界、共享面两种单元表示 |
| 物理边界角点 | 单元两个对角顶点分别放贡献量 2 和 3 | 仅对应端点有贡献，保留总量 5 |
| 线性场投影 | 节点场 `2+3*r-0.7*phi+0.4*z` | 对照该物理场在每个圆柱单元内的解析体积平均 |
| 四组网格积分 | 含轴非均匀全周、环形非均匀全周、环形角向物理端面、单个周期角单元 | 总体积、角度积分、均匀物理密度恢复、带符号总量、单元平均总量、周期接缝或物理端面体积 |
| 非均匀轴点 | 角单元宽度 `[0.2,0.9,1.9,2*pi-3]`，轴点密度 `[1,2,4,8]` 及其相反数 | 加权参考值约 `4.6432394487827064`、正负密度的角向加权量保持 |
| 公开 B02 对照 | 从轴起算的均匀全周网格，71 个确定性粒子，正负电荷、可变权重 | B04 与 B02 的节点密度数组一致性，比较在轴点处理之前进行 |
| 参数错误 | 非递增／非有限坐标、形状不匹配、越界单元、单元外位置、非有限贡献量或密度、无效体积／轴点权重 | 对应非零状态码，目标数组保持原值 |
| 浮点范围 | 倒数临界体积及相邻可用体积；正负密度加法、临界加法、最大有限值抵消、周期重复目标、单元平均的大幅值输入与零场 | 非法累加在溢出前拒绝并保留整数组；合法累加和平均符合参考结果；重复目标保留两份贡献及原累加顺序 |

每种配置执行 **79 项断言**，其中 19 项针对浮点范围；每次公开例程调用还检查状态码。含轴的周期积分算例同时检查轴点平均前后总量，以及处理后同一轴向位置各角向索引的密度一致性。
单个周期角单元用于检查一个粒子的两个角端点映射到同一节点时的累加。

## 中文：如何运行与判读

在本目录或仓库根目录执行以下命令（后者使用完整相对路径）：

```bash
bash run.sh double debug
bash run.sh double release
bash run.sh single debug
```

- 依赖：Bash、GNU Fortran；`FC` 可指定编译器路径，脚本选项按 GNU Fortran 编写。
- `double` 使用 `-fdefault-real-8`；`single` 使用默认实数精度。全部依赖源码按同一选项重编译。
- `debug` 使用 `-O0 -g -fcheck=all -ffpe-trap=invalid,zero,overflow -fbacktrace`。
- `release` 使用 `-O2`。共同使用 `-cpp -std=f2008 -Wall -Wextra -Wno-compare-reals -fimplicit-none`。
- 可执行文件和模块文件保存在 `build/<precision>-<mode>/`，已由本目录 `.gitignore` 排除。
- 成功退出码为 0，最后一行给出 `B04 PASS: checks=79, real_bits=64`（单精度为 32）。
  断言失败输出 `FAIL` 并非零退出；意外状态码也使测试非零退出。

主要数值比较的舍入容差为 $\tau=2048\,\epsilon$，其中 $\epsilon$ 为 `epsilon(1.0)`：
双精度约 $4.5475\times10^{-13}$，单精度约 $2.4414\times10^{-4}$。

- 标量比较通常要求 $|a-b|\le\tau\max(1,|b|)$。
- 均匀密度恢复报告 $\max|D-3.25|/3.25$；线性场投影报告 $\max|D-D_{ref}|/\max|D_{ref}|$。
- 总量残差以 $\sum_p|c_p|$ 归一化，避免正负电荷抵消使相对误差分母接近零。
- B02 对照报告 $\max|D_{B04}-D_{B02}|/\max(1,\max|D_{B02}|)$。
- 大幅值单元平均以 `huge(1.0)` 归一化，与解析参考值的差不超过 $16\epsilon$。状态码、错误输入的数组保留和特定精确标志使用直接判断；全部实际判据见测试源码。

`METRIC` 行记录上述误差。均匀密度由两点张量积 Gauss 积分构造确定性粒子贡献，
检验的是基函数、物理体积因子与沉积归一化的配套关系。当前算例评价组件数值性质；
应用中的采样噪声、MPI 归并和完整 PIC 时间演化由对应集成测试评价。

运行脚本在对应 `build/<precision>-<mode>/` 目录导出绘图数据：
`hand_nodes.csv` 和 `uniform_nodes.csv` 给出图 1、图 2 的节点值；
`axis_nodes.csv`、`axis_metrics.csv` 和 `axis_totals.csv` 给出轴点平均前后密度、误差与总量。
测试可执行文件的第一个可选参数指定已有输出目录；省略时只运行测试，不导出 CSV。

先运行 `bash run.sh double debug`，再运行 `python plot_results.py`，即可在
`build/figures/` 生成三组双语图；加 `--axis-only` 仅绘制轴点图。
绘图依赖 Python、NumPy、Matplotlib 及可显示中文的字体。
`--data-dir` 可指定其他双精度结果目录，`--output-dir` 可指定图片输出位置。
原始数据和运行日志保存在本地并由 Git 忽略；仓库保留源码、测试说明和已选用的文档插图。

## English: evidence and execution

The test compiles and calls all four public B04 routines. The uniform-grid
comparison also compiles and calls the exact public B02 charge-deposition
routine. Expected results use hand-computed values, independent Gauss
quadrature, physical cell volumes and analytic field integrals.

The suite has **79 assertions** per configuration, plus status checks after each
routine call. It covers eight-node increments, endpoint particles, signed and
zero contributions, actual-array lower bounds, internal faces, linear-field
volume averages, four grid/topology configurations, nonuniform axis weights,
periodic seam identification and invalid-input handling. One periodic angular
cell explicitly exercises duplicate destination indices within one scatter call.
The B02 comparison uses 71 deterministic particles on a uniform full-circle grid
starting at the axis, with signed charges and variable weights, before axis
averaging.

Nineteen assertions exercise the reciprocal-volume limit and its valid neighbor,
positive and negative density-sum overflow, a rounded addition bound, large finite
updates, cancellation, zero amounts, repeated periodic destinations, and cell
averaging of large signed values and zero fields. Overflow
cases check that the entire output array retains its prior values, including when
earlier destinations would receive nonzero contributions.

Run `bash run.sh double debug`, `bash run.sh double release` or
`bash run.sh single debug` from this directory. The script accepts `FC`; its
flags target GNU Fortran. Double precision adds `-fdefault-real-8`. Debug enables
bounds/runtime checking and traps invalid operations, division by zero and
overflow; release uses `-O2`. Artifacts stay in the ignored local `build/`
directory. Success exits with zero and prints `B04 PASS: checks=79`; failures
exit with a nonzero status.

The main comparisons use $2048\epsilon$ for the compiled real kind (approximately
$4.5475\times10^{-13}$ for 64-bit real and $2.4414\times10^{-4}$ for 32-bit real).
Scalar checks scale by $\max(1,|reference|)$. Uniform-density and linear-field
checks use relative maximum norms. Total-amount residuals divide by the sum of
absolute particle amounts; the B02 comparison divides the maximum difference
by $\max(1,\max|D_{B02}|)$. `METRIC` lines retain these values. Error codes and
unchanged outputs are checked directly. Large-value cell averages are normalized
by `huge(1.0)` and compared with analytic references within $16\epsilon$.

Two-point tensor Gauss quadrature supplies deterministic contributions for a
constant physical density. It checks the matching of assignment bases and
cylindrical volume normalization. Sampling noise, MPI reduction and PIC time
evolution belong to application integration tests.

The runner exports plotting data into `build/<precision>-<mode>/`:
`hand_nodes.csv` and `uniform_nodes.csv` contain the nodal values for Figures 1
and 2; `axis_nodes.csv`, `axis_metrics.csv` and `axis_totals.csv` contain axis
densities, errors and totals. The executable's optional first argument names
an existing output directory; without it, the tests run without CSV export.

Run `bash run.sh double debug`, then `python plot_results.py` to generate all
three bilingual figures in `build/figures/`; add `--axis-only` for the axis figure.
Plotting requires Python, NumPy, Matplotlib and a font with Chinese glyphs.
Use `--data-dir` for another double-precision result directory and `--output-dir`
to choose the figure destination. Raw data and run logs stay local and are
ignored by Git; the repository retains source code, test descriptions and
selected documentation figures.

[Module guide / 模块说明](../../../B_Scatter/B04_scatter_3d_cyl_nonuniform/README.md)
