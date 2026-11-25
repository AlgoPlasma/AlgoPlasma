# G03_DSMC

[English](README.md)

C++20 串行、单组分中性单原子、等权重的 HS/VHS/VSS 弹性碰撞数值库。
公开入口统一接收柱坐标粒子数组与非均匀三维 `r/theta/z` 网格。
调用程序负责输入解析、初始化、粒子推进、物理边界、场求解、时间循环与输出；
主库完成一次指定时间间隔内的单元碰撞，并返回统计与守恒报告。

## 接口与使用

包含 `dsmc.hpp` 即可使用模型、标定函数、柱坐标网格、粒子和步进器。
模型直接通过 `DsmcModel(species, weight, parameters)` 构造，
内部按 HS/VHS/VSS 选择碰撞率与散射角分布。
已知参考动力黏度时，先调用 `reference_diameter()` 得到参考直径。

下面展示一次碰撞调用；初始化与完整时间循环由算例组织：

```cpp
#include "dsmc.hpp"
#include <utility>
#include <vector>

int main() {
    using namespace algoplasma::dsmc;

    Species argon{0, "Ar", 6.6335209e-26, 0};
    ElasticModelParameters parameters{ElasticModel::VSS, 4.17e-10, 273.0, 0.81, 1.4};
    DsmcModel model(argon, 1.0e7, parameters);

    CylindricalGrid grid(
        {0.0, 1.0e-3, 3.0e-3},
        {0.0, pi, 2.0 * pi},
        {0.0, 1.0e-3, 4.0e-3},
        AngularBoundary::periodic);
    std::vector<CylindricalParticleState> particles{
        {1, 0, {0.5e-3, 0.25 * pi, 0.5e-3}, {150.0, 20.0, 0.0}},
        {2, 0, {0.6e-3, 0.40 * pi, 0.5e-3}, {-150.0, 0.0, 10.0}}
    };

    StepOptions options; // 默认采用 RoundedNtc。
    DsmcStepper stepper(std::move(model), options);
    DsmcWorkspace workspace;
    StepContext context{1.0e-8, 0, 42, 0}; // dt_s、global_step、seed、substep。
    const auto report = stepper.step(particles, grid, context, workspace);
    (void)report;
}
```

长度以 m、角度以 rad、速度以 m/s、质量以 kg、温度以 K 表示。
`vtheta_mps` 是切向线速度 `r*dtheta/dt`。网格输入为三个严格递增的单元面坐标数组；
周期角向覆盖完整的 `2*pi`，网格从同一组面坐标计算粒子归属与真实体积。
粒子 ID 须唯一，物种 ID 须与模型一致，粒子位置须位于网格内。

这些输入都是 C++ 数值数据。CSV、文本或其他文件的格式、读取方式及编译链接方法由调用程序选择。

## 候选调度与写回

`StepOptions::candidate_schedule` 提供两种候选调度：

- `RoundedNtc`（默认）：候选期望数 `A = N(N-1)/2 * W * K_max * dt / V`，
  先取 `floor(A)`，再按小数部分的概率补一个候选。
- `ContinuousClock`：在积分强度坐标中累计 `-log(U)`，候选数服从 Poisson 分布；
  接受与拒绝都会推进时钟。构造步进器前设置
  `options.candidate_schedule = CandidateSchedule::ContinuousClock` 即可选择。

两者共用覆盖整个子步的碰撞核上界、均匀选对、`K(g)/K_max` 接受判定与弹性散射。
单元成员、体积与统一权重在子步内固定。启用 `record_events` 后记录接受事件；
连续时钟的 `time_offset_s` 是子步内的近似时刻，NTC 对应值为 `nullopt`。
日志达到上限后碰撞计算继续执行；候选预算不足则整步失败。

`step()` 先检查粒子并生成共同 xyz 基底下的内部快照，按单元和粒子 ID 排序后执行碰撞。
全部单元计算及守恒检查成功后，先准备所有局部柱坐标速度，再统一写回原数组。
输入检查、碰撞计算或写回准备抛出异常时，原始粒子速度保持不变。
未改变的快照速度沿用原始局部分量，避免无碰撞时的坐标往返舍入。

调用期间，粒子数组与网格必须保持有效，粒子成员、ID、位置和存储顺序须固定，
也不能被其他代码同时修改。同一个工作区或同一份粒子存储不能并发参与多个 `step()`。
工作区可供后续时间步复用；下一步重新读取当前粒子状态。

## 文件

全部源码由 11 个头文件与 8 个 `.cpp` 文件组成：

| 职责 | 头文件 | 实现文件 |
| --- | --- | --- |
| 公开入口汇集 | `dsmc.hpp` | — |
| 物理量、ID、向量与公共数值检查 | `common.hpp` | 头文件实现 |
| HS/VHS 碰撞核与区间上界 | `rate.hpp` | `fun_G03_dsmc_rate.cpp` |
| 各向同性与 VSS 散射 | `scattering.hpp` | `fun_G03_dsmc_scatter.cpp` |
| 参考动力黏度与直径换算 | `calibration.hpp` | `fun_G03_dsmc_calibration.cpp` |
| 随机流与无偏整数抽样 | `random.hpp` | 头文件实现 |
| 参数校验、模型构造与属性 | `model.hpp` | `fun_G03_dsmc_model.cpp` |
| 柱坐标网格、单元体积、定位与速度变换 | `cylindrical.hpp` | `fun_G03_dsmc_cylindrical.cpp` |
| 柱坐标粒子、快照读取与写回准备 | `particles.hpp` | `fun_G03_dsmc_particles.cpp` |
| 内部函数声明与单元碰撞 | `collision_kernel.hpp` | `fun_G03_dsmc_collision.cpp` |
| 整步调度、内部 `CollisionParticle`、工作区与报告 | `stepper.hpp` | `fun_G03_dsmc_stepper.cpp` |

`particles.hpp` 定义公开的 `CylindricalParticleState`；对应实现提供内部的
`snapshot_particles()` 与 `prepare_particle_velocities()`。
`CollisionCell` 由 `cylindrical.hpp` 定义，内部碰撞函数声明集中在 `collision_kernel.hpp`。
公开计算入口为 `DsmcStepper::step()`。

## 测试与文档

测试位于 [tests/009_collision/G03_DSMC](../../tests/009_collision/G03_DSMC/README.zh-CN.md)，
包含 8 个核心检查组和 6 个碰撞弛豫检查。从仓库根目录运行：

```bash
bash tests/009_collision/G03_DSMC/run.sh
```

测试使用柱坐标接口；默认临时构建并自动清理。依赖、运行组和输出位置见测试 README。

- [Theory & Algorithm](../../docs/source/rst_files/G_Collision/G03_DSMC/fundamentals.rst)：物理模型、标定、配对率、候选调度与柱坐标单元；公式旁展示真实源码。
- [Source Guide](../../docs/source/rst_files/G_Collision/G03_DSMC/implementation.rst)：沿 `step()` 阅读数据、分组、工作区与写回流程。
- [G03_DSMC Validation](../../docs/source/tests/009_collision/G03_DSMC.rst)：调用示例、解析依据、统计容差与检查范围。

随机键的字段顺序、位置标记、用途编号 0–4 与抽样顺序属于重放约定；修改这些规则会改变碰撞轨迹。
文档通过 `literalinclude` 引入当前源码。
