# 012_fluid Tests

[English](README.md)

本目录验证 [J_Fluid](../../J_Fluid/README.zh-CN.md) 的中性粒子参考场和连续性求解。
J01、J02 分别提供自由分子（FM）与离散纵标（SN）前处理；J03 使用参考场的面通量推进密度。
前处理采用 r-z 空间和两个速度分量的约化模型，J03 求解标量密度方程。

## 测试内容

| 目录 | 检查内容 |
| --- | --- |
| [J01_free_molecular](J01_free_molecular/README.zh-CN.md) | 3 个程序：采样、反射、轨迹、统计和完整 FM 入口 |
| [J02_neutral_sn_transport_2Drz](J02_neutral_sn_transport_2Drz/README.zh-CN.md) | 12 个普通程序：速度求积、反应系数、DG 算子、边界、输运及重构；另有并行一致性检查 |
| [J03_neutral_continuity_faceflux_2Drz](J03_neutral_continuity_faceflux_2Drz/README.zh-CN.md) | 6 个程序：闭合、瞬态、平衡、应用配置，以及 FM/SN 接入 J03 |
| [application_reference_J01](J03_neutral_continuity_faceflux_2Drz/application_reference_J01/README.zh-CN.md) | 完整 FM → J03 的无损 B0 应用 |
| [application_reference](J03_neutral_continuity_faceflux_2Drz/application_reference/README.zh-CN.md) | 完整 SN → J03 的 B0 与给定损失 ION 应用 |

21 个普通程序使用解析关系、独立积分或离散收支作为参考。
两项串联测试将实际前处理结果交给 J03：FM 用两单元时间解析解核对，
SN 用 `psi(r,z)=exp(-a*z)/r` 检查空间加密和连续性演化。
推导、容差及记录见[串联测试文档](../../docs/source/tests/012_fluid/integration_tests.rst)。

## 环境与运行

需要 Bash 和 GNU Fortran。应用验收与绘图还需要 Python 3、NumPy 和 Matplotlib；
单独的输入网格检查只使用 Python 标准库。以下命令均从仓库根目录运行：

```bash
bash tests/012_fluid/J01_free_molecular/run.sh
bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run.sh
bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh
```

各程序须通过自身断言并以零状态退出。逐项日志保存在对应目录的 `build/`。

应用验收逻辑可独立检查。先编译 SN 应用驱动，再运行 Python 检查：

```bash
bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/application_reference/make.sh
python3 tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/test_application_checks.py
```

这里的编译命令只生成可执行文件。Python 检查会向实际 J03 驱动提供负值、NaN 和无穷参考密度，
确认其在时间推进前报错；未编译驱动时，该项检查明确跳过。
有效单元内的前处理密度和连续性密度都须有限且非负。

## 并行与完整应用

普通 J02 构建会重建自己的 `build/`，因此并行测试放在普通测试之后：

```bash
bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run_parallel.sh
MPIEXEC_FLAGS=--oversubscribe bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run_mpi.sh
```

MPI 检查需要 MPI 编译器和启动器。`--oversubscribe` 是 Open MPI 在本机进程槽不足时使用的可选参数。
完整应用耗时更长，运行方法、模型范围和通过条件见上表各应用 README；
快速测试的通过情况只覆盖对应的小规模检查。

## 输出与清理

构建文件和日志位于各测试的 `build/`，保持在提交之外。
完整应用默认也向自身 `build/` 写结果；可通过 `APPLICATION_OUTPUT` 选择其他目录。
应用脚本要求输出目录为空，重复运行应指定新的输出目录。

J03 的 `clean.sh` 会删除自身及两个完整应用的构建目录，包括其中的结果。
需要保留的应用输出应先另存；指定到这些目录之外的输出由使用者管理。
输入网格和应用范围见[公共输入说明](J03_neutral_continuity_faceflux_2Drz/application_inputs/README.zh-CN.md)。
