# J03_neutral_continuity_faceflux_2Drz

[中文](README.zh-CN.md) | [English](README.en.md)

J03 从参考密度和有符号面通量建立固定的面输运系数，随后按当前迎风密度计算通量，推进二维柱坐标瞬态连续性方程。它不跟踪粒子、不求速度分布，也不自动重算参考场。

面输运系数具有速度单位，但不等于单元平均速度。输入可以来自任何满足数组、几何与符号约定的参考场算法。

## 文件分工

| 文件 | 任务 |
| --- | --- |
| `mod_J03_neutral_continuity_faceflux_2Drz.f90` | 定义闭合对象、面类型与状态码，包含实现文件 |
| `sub_J03_transport_closure.f90` | 检查几何与拓扑，保存参考场并建立内部面及边界出射系数 |
| `sub_J03_continuity_solver.f90` | 当前通量、稳定步长、瞬态单步、残差、收支及可选稳态求解 |
| `sub_J03_error.f90` | 将状态码转换成错误说明 |

## 瞬态调用顺序

1. `sub_J03_initialize_transport_closure` 初始化一次闭合；检查返回状态。
2. 应用另外指定初始密度和物理时间。
3. 每步更新 `source_rate`、`closure%loss_frequency` 和 `closure%boundary_inflow_flux`。
4. `sub_J03_compute_stable_timestep` 返回保守稳定上限；结合物理精度选择实际时间步。
5. `sub_J03_continuity_step` 返回新密度；检查本步收支后由应用推进时钟。

单步公式为 `n_new=(n_old-dt*div(flux_old)+dt*S)/(1+dt*nu)`。`S` 为产生率，单位 m⁻³s⁻¹；`nu` 为损失频率，单位 s⁻¹。瞬态收支应使用旧密度出流和新密度损失，而非要求流入与流出立即相等。

单步接口不强制检查稳定步长，也不自动拒绝负的新密度。可选负值截断改变粒子总数，不能代替稳定性检查。初始参考密度的有限性、非负性和边界通量方向也需调用者确认。

## 辅助入口与限制

- `sub_J03_compute_residual` 和 `sub_J03_compute_balance` 分别返回局部残差与全域粒子收支。
- `sub_J03_solve_steady` 用固定条件反复推进，同时检查迭代变化和归一化残差；不是物理时间循环的替代品。
- 不同来源的参考场统一调用 `sub_J03_initialize_transport_closure`。
- 修改参考场或几何后须重新初始化系数；单独改参考场副本不会更新闭合。
- 当前为单域求解，不包含 MPI 分区通信或结果汇集。

## 构建与文档

编译模块文件并启用预处理，将本目录加入 include 路径；不要单独编译实现文件。调用方与模块须采用相同实数精度。

Sphinx 的 [J03](../../docs/source/rst_files/J_Fluid/J03_neutral_continuity_faceflux_2Drz.rst) 给出闭合推导、各过程输入输出、完整调用流程和错误说明。运行命令与断言见 [J03 tests](../../tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/README.md)。
