# J03_neutral_continuity_faceflux_2Drz

J03 用固定面速度推进二维柱坐标瞬态连续性方程。J01 或 J02 提供参考密度和面通量；J03 将参考通量除以迎风参考密度得到面速度，后续通量为面速度乘当前迎风密度。

## 调用方式

1. `sub_J03_initialize_transport_closure` 检查输入，建立面速度与几何。两个 import 过程是兼容入口。
2. 每个物理时间步更新 `source_rate` 和 `closure%loss_frequency`；有时变入口时更新 `closure%boundary_inflow_flux`。
3. `sub_J03_compute_stable_timestep` 返回保守 CFL 上限，再结合物理时间分辨率选择 dt。
4. `sub_J03_continuity_step` 返回新密度，调用方推进时钟；不必等待稳态。

更新式为 `n_new=(n-dt*div(flux)+dt*S)/(1+dt*nu)`。源项单位 m⁻³s⁻¹，损失频率 s⁻¹，dt 单位 s。单步过程不自动拒绝超过 CFL 的时间步。负值截断会改变总量，不应代替稳定性检查。

## 辅助稳态入口

`sub_J03_solve_steady` 用固定源损和边界反复推进，必须同时满足密度变化阈值与归一化残差阈值。可选 `residual_tolerance` 指定后者，默认 `max(tolerance,100*epsilon(1.0))`；可选 `final_scaled_residual` 返回最后残差。尺度由初始参考输运及源损项确定，不依赖 dt。

`sub_J03_compute_residual` 返回局部残差和体积积分；`sub_J03_compute_balance` 返回入射、出射、体源、体损失粒子率以及相对总量失衡。瞬态允许总量变化，稳态才要求入射加体源等于出射加损失。

## 几何要求与测试

内部面的两侧标记必须一致，共享面积差不得超过 `100*epsilon(1.0)*max(A_left,A_right)`。轴线的零面积边界合法，内部面面积必须为正。

```bash
bash tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh
```

测试包括瞬态指数衰减、源损演化、时变损失、两单元输运、时间步收敛、守恒及错误诊断。完整应用测试使用仓库中的输入数据，但仍需单独运行，不能由小测试结果代替。
