# 非均匀速率分组验证

本目录检验 J02 的速率求积扩展，为 CEX 做数值准备；不包含碰撞算子。

## 运行

在 AlgoPlasma 根目录运行：

```bash
python3 tests/012_fluid/J02_neutral_sn_transport_2Drz/nonuniform_speed/run_comparison.py --output /path/to/output
```

需要 GNU Fortran、Python、NumPy 和 Matplotlib。脚本不清理已有输出。
报告 `report.md`、原始数据 `moments.csv`、`transport.csv`、`angle_cutoff.csv`，
以及 PNG/SVG 图保存在指定目录。`--analyze-only` 可从现有 CSV 重新生成图和报告。
参考输运解使用 16384 个速率组；串行双精度运行的峰值内存约 1.5 GB。

## 对比设计

- 相同速率上限 16000 m/s、相同角度数和组数，比较等宽、二次幂边界和分段等宽。
- 分布采用二维漂移 Maxwell 模型：550 K/300 m/s 的冷分量、12000 m/s 漂移/600 m/s 热标准差的快分量，以及 90%/10% 混合。
- 分别核对未归一化的密度、轴向流密度、原始二阶矩、正轴向半空间通量，参考无限速度域解析值。
- 输运比较在固定 2×6 空间网格和 128 角度下使用同一入口总通量、开放边界及给定损失频率，参考速率组进一步细化。
- 单独比较角度数和截断上限，不把守恒误差当作精度误差，也不把固定空间网格结果解释为全离散收敛。

非均匀分组没有普遍优于等宽分组的保证。分段位置使用了本例的先验分布信息；
局部加密、速率上限和角度分辨率都需随未来离子背景重新检查。

## 模块及并行测试

常规模块测试已自动包含 `test_J02_nonuniform_quadrature.f90`；
`run_parallel.sh` 也会在串行和 OpenMP 下运行它。
MPI 测试可用第四个参数 `nonuniform` 选择四组 `[0,0.2,0.6,1.5,3]`：

```bash
OMP_NUM_THREADS=2 mpiexec -np 4 /path/to/test_J02_mpi.out 2 2 custom nonuniform
```

2026-10-08 的实际验证记录保存在 `algoplasma-runs/nonuniform_speed_20261008_130915`。
初始试探使用仅两组 `[0,0.35,3]` 时，带混合漫反射的参考求解在 5000 次迭代后仍不收敛。
用修改前模块手工填入同一求积后，复现了相同的停滞（相对变化约 2.2909e-3），
确认不是新构造接口引入的回归。
因此“能构造合法求积”不代表所有极粗网格的壁面源迭代都会收敛；
该试探的源文件和完整日志单独保留，未修改现有壁面求解算法。
