# C03 非均匀柱坐标场插值测试

[English](README.md)

从仓库根目录运行以下命令。

```bash
bash tests/007_gather/C03_gather_3Draz_nonuniform/run.sh
```

需要 GNU Fortran 和 Python 3，仅使用 Python 标准库。可用 `FC` 指定其他兼容 GNU 的编译器可执行文件。构建启用双精度、数组边界和运行时检查，选项为 `-cpp -O2 -fdefault-real-8 -Wall -Wextra -fcheck=all -fbacktrace`。

- `source_f90/main.f90` 为各分量的交错网格填充场值，并对公开的单点接口和包装接口采样。可用命令行参数选择无效输入用例。
- `source_py/analyze.py` 独立计算解析参考，检查预期的全部 6912 行 CSV 数据、测量收敛性，并检查 11 个预期失败用例。
- `make.sh` 构建 `build/main`。
- `run.sh` 构建程序、覆盖 CSV 并运行分析。任一检查失败都会返回非零退出状态。若驱动程序失败，不会继续分析旧 CSV。
- `clean.sh` 清理本测试的 `build/`、`output/` 和 Python 缓存。

覆盖范围包括常量场、均匀和非均匀网格上的多线性场、包装接口和缓存单元、跨接缝的角度周期平移、偏移的局部网格块和幽灵单元值、轴线和单单元网格，以及沿各轴使用 8/16/32 个单元时的平滑场收敛性。每个网格在 96 个确定性位置对全部六个分量采样。精确场用例包括本地所属网格块的角、边、面，以及内部面和单元中心。幽灵单元宽度与相邻所属单元宽度不同。测试过程不进行 MPI 通信。

结果写入 `output/c03_gather.csv`、`output/summary.json`，每个无效输入用例另有一份 `output/<case>.log`。常量场的容差为 `1e-12`，其他精确场的容差为 `2e-11`。平滑场两次加密的收敛阶均须在 `[1.7,2.3]` 内。每个无效输入用例都须以非成功状态结束并给出预期的 C03 错误消息。样本缺失、重复、出乎预期或包含非有限值均视为失败。

[完整双语测试说明](../../../docs/source/tests/007_gather/C03_gather_3Draz_nonuniform.rst)
