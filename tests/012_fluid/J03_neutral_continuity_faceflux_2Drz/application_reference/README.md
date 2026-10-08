# SN application test

本算例使用 r-z 空间和两个速度分量的约化输运模型，速度求积只有一个平面角度。
柱坐标几何与守恒权重不构成完整轴对称 2D3V；J03 仅求解密度方程。

从仓库根目录运行：

```bash
bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/application_reference/run_application_reference.sh B0
```

J02 默认启用 OpenMP；编译和链接均添加 `-fopenmp`。
建议运行前指定线程数，且为新结果指定独立目录，例如：

```bash
OMP_NUM_THREADS=4 OMP_DYNAMIC=FALSE \
APPLICATION_OUTPUT="$HOME/algoplasma-results/sn-openmp-B0" \
bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/application_reference/run_application_reference.sh B0
```

上述输出目录必须是未使用的新目录；ION 另选目录并将最后参数改为 `ION`。
串行复跑可在相同命令前增加 `OPENMP=0`，同时更换输出目录。
这里的并行只作用于 J02 的离散速度扫描，不作用于 J03 时间推进。

默认读取同级 `application_inputs` 中的网格，有效区域和 ION 损失由 `application_case.f90` 生成。脚本第一个参数选择 `B0` 或 `ION`，第二个参数可指定其他网格目录，但须保持相同的区域索引。

出图需要 NumPy 和 Matplotlib；输入缺失或网格不合法时，脚本在编译前报错。

默认输出仍在本应用的 build 目录。若输出目录已有文件，脚本拒绝覆盖；请设置 `APPLICATION_OUTPUT` 到一个新目录。不要为了重跑而直接清理需要保留的结果。

完整应用必须满足前处理完成、密度有限、J03 密度非负、J03 收敛、归一化残差≤1e-8、相对粒子率失衡≤1e-6。密度场变化只记录，不要求与前处理场相同。输出 summary.txt、日志、场数据和两幅密度图。

2026-10-06 已完成当前公共入口及 4 线程 OpenMP 的完整复跑（`fluid-20261006-192111`）：
B0、ION 分别用 20、15 轮反射迭代收敛；J03 分别推进 3647、6223 步。
局部缩放残差为 4.2844e-9、9.9953e-9，相对粒子收支误差为 2.2322e-7、4.6204e-8。
本次二进制场、图片与 Sphinx 应用测试页的记录一致。空间 MPI 的验证仍来自小测试，
这次完整应用没有启用空间 MPI。
