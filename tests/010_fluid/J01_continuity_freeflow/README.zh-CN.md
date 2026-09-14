# J01 连续性方程自由流测试

本目录独立验证 `J_Fluid/J01_continuity_freeflow`，不依赖完整的流体或 PIC
应用程序。

第一轮测试覆盖当前例程的公开行为：

- 零速度、零源项时密度保持不变；
- 当前源项符号约定 `n_new = n_old - s`；
- 确定性三维非均匀场的单步参考公式；
- x、y、z 三方向正负单位速度下的精确整格平移；
- `n0` 完整保存旧密度，且文档所述更新区之外的 guard cells 不变；
- 周期边界、零源项条件下的总密度守恒。

测试故意为三个方向设置不同的上下界和尺寸，以避免立方网格掩盖 x/y/z
索引混用。

## 运行

在仓库根目录执行：

```bash
bash tests/010_fluid/J01_continuity_freeflow/run.sh
```

成功时最后输出：

```text
RESULT: PASS
```

编译配置开启 GNU Fortran 数组越界检查、未初始化实数标记、浮点异常捕获和
常用警告。构建产物位于 `build/`。

## 清理

```bash
bash tests/010_fluid/J01_continuity_freeflow/clean.sh
```

