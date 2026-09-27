:orphan:

.. result-table

.. rubric:: 运行结果 / Run results

通过 / Passed: 12/12.

.. list-table:: 测试总表 / Test summary
   :header-rows: 1

   * - 序号 / No.
     - 测试 / Test
     - 状态 / Status
   * - 1
     - 网格分辨率 / Grid resolution
     - PASS
   * - 2
     - Beall 功率权重 / Beall power weights
     - PASS
   * - 3
     - 跨越相位边界 / Phase branch cut
     - PASS
   * - 4
     - 共同混叠周期 / Common alias period
     - PASS
   * - 5
     - 等长多方向基线 / Equal-length baselines
     - PASS
   * - 6
     - 分块网格一致性 / Blocked-grid agreement
     - PASS
   * - 7
     - 有效二维约束 / Valid 2D constraints
     - PASS
   * - 8
     - 非整周期记录 / Off-bin records
     - PASS
   * - 9
     - 众数相位统计 / Histogram-mode statistics
     - PASS
   * - 10
     - 缺失与无噪声样本 / Missing and noiseless samples
     - PASS
   * - 11
     - 无有效相位的谱 / Spectrum without valid phase
     - PASS
   * - 12
     - 窗口功率归一化 / Window-power normalization
     - PASS

.. rubric:: 1. 网格分辨率 / Grid resolution

输入 / Input::

   {chi_m: [[0.005, 0], [0.00501, 0], [0, 0.005], [0, 0.00501]], truth_rad_m: [123.4, 0], range_rad_m: 2000, grid_n: [401, 4001]}

计算量 / Measurements::

   {estimates_rad_m: [[1380, 0], [123, 0]]}

.. list-table:: 数值与行为检查 / Numerical and behavior checks
   :header-rows: 1

   * - 计算量 / Quantity
     - 实际 / Actual
     - 参考或界限 / Reference or limit
     - 判据 / Criterion
     - 最大绝对差 / Max absolute difference
     - 状态 / Status
   * - 401 点 kx 误差 / kx error (rad/m)
     - 1256.6
     - 1000
     - actual > limit
     - n/a
     - PASS
   * - 4001 点 kx 误差 / kx error (rad/m)
     - 0.4
     - 1
     - actual < limit
     - n/a
     - PASS
   * - 4001 点 ky / ky (rad/m)
     - 0
     - 0
     - equal
     - 0
     - PASS

.. rubric:: 2. Beall 功率权重 / Beall power weights

输入 / Input::

   {FFT1: [[10], [2]], FFT2: [[0.1], [2]], phase_rad: [-0.5, 0.5]}

.. list-table:: 数值与行为检查 / Numerical and behavior checks
   :header-rows: 1

   * - 计算量 / Quantity
     - 实际 / Actual
     - 参考或界限 / Reference or limit
     - 判据 / Criterion
     - 最大绝对差 / Max absolute difference
     - 状态 / Status
   * - 自功率权重 / Auto-power weights
     - [50.005, 4]
     - [50.005, 4]
     - abs(error) <= 0 + 1e-07*abs(reference)
     - 0
     - PASS
   * - 自功率谱峰 / Auto-power peak (rad/m)
     - -0.5
     - -0.5
     - equal
     - 0
     - PASS
   * - 互谱幅值谱峰 / Cross-magnitude peak (rad/m)
     - 0.5
     - 0.5
     - equal
     - 0
     - PASS

.. rubric:: 3. 跨越相位边界 / Phase branch cut

输入 / Input::

   {phase_deg: [179, -179, 178, 179], bins: 60}

.. list-table:: 数值与行为检查 / Numerical and behavior checks
   :header-rows: 1

   * - 计算量 / Quantity
     - 实际 / Actual
     - 参考或界限 / Reference or limit
     - 判据 / Criterion
     - 最大绝对差 / Max absolute difference
     - 状态 / Status
   * - 距 π 的圆周偏差 / Distance to pi (rad)
     - 0.052359878
     - 0.10471976
     - actual < limit
     - n/a
     - PASS
   * - 方差 / Variance (rad²)
     - 0.00048231092
     - 0.01
     - actual < limit
     - n/a
     - PASS

.. rubric:: 4. 共同混叠周期 / Common alias period

输入 / Input::

   {chi_m: [[0.005, 0], [0.01, 0], [0, 0.005], [0, 0.01]], wavevector_difference_rad_m: [1256.6371, 0]}

.. list-table:: 数值与行为检查 / Numerical and behavior checks
   :header-rows: 1

   * - 计算量 / Quantity
     - 实际 / Actual
     - 参考或界限 / Reference or limit
     - 判据 / Criterion
     - 最大绝对差 / Max absolute difference
     - 状态 / Status
   * - 各基线包裹相位差 / Wrapped differences (rad)
     - [0, 0, 0, 0]
     - 0
     - abs(error) <= 1e-12 + 1e-07*abs(reference)
     - 0
     - PASS

.. rubric:: 5. 等长多方向基线 / Equal-length baselines

输入 / Input::

   {chi_m: [[0.005, 0], [3.061617e-19, 0.005], [0.0035355339, 0.0035355339], [0.004330127, 0.0025]], truth_rad_m: [1200, 800], range_rad_m: 2000, grid_n: 401}

.. list-table:: 数值与行为检查 / Numerical and behavior checks
   :header-rows: 1

   * - 计算量 / Quantity
     - 实际 / Actual
     - 参考或界限 / Reference or limit
     - 判据 / Criterion
     - 最大绝对差 / Max absolute difference
     - 状态 / Status
   * - 恢复波矢 / Recovered wavevector (rad/m)
     - [1200, 800]
     - [1200, 800]
     - equal
     - 0
     - PASS

.. rubric:: 6. 分块网格一致性 / Blocked-grid agreement

输入 / Input::

   {chi_m: [[0.005, 0], [0, 0.006], [0.003, 0.004]], truth_rad_m: [80, -40], range_rad_m: 200, grid_n: 41, block_rows: [1, 7, 100]}

.. list-table:: 数值与行为检查 / Numerical and behavior checks
   :header-rows: 1

   * - 计算量 / Quantity
     - 实际 / Actual
     - 参考或界限 / Reference or limit
     - 判据 / Criterion
     - 最大绝对差 / Max absolute difference
     - 状态 / Status
   * - 1 行/批：波矢 / Wavevector (rad/m)
     - [80, -40]
     - [80, -40]
     - equal
     - 0
     - PASS
   * - 1 行/批：似然 / Log likelihood
     - 0
     - 0
     - round(abs(error), 7) == 0
     - 0
     - PASS
   * - 7 行/批：波矢 / Wavevector (rad/m)
     - [80, -40]
     - [80, -40]
     - equal
     - 0
     - PASS
   * - 7 行/批：似然 / Log likelihood
     - 0
     - 0
     - round(abs(error), 7) == 0
     - 0
     - PASS
   * - 100 行/批：波矢 / Wavevector (rad/m)
     - [80, -40]
     - [80, -40]
     - equal
     - 0
     - PASS
   * - 100 行/批：似然 / Log likelihood
     - 0
     - 0
     - round(abs(error), 7) == 0
     - 0
     - PASS

.. rubric:: 7. 有效二维约束 / Valid 2D constraints

输入 / Input::

   {invalid_cases: [empty, one baseline, collinear, NaN phase, infinite variance], range_rad_m: 200}

.. list-table:: 数值与行为检查 / Numerical and behavior checks
   :header-rows: 1

   * - 计算量 / Quantity
     - 实际 / Actual
     - 参考或界限 / Reference or limit
     - 判据 / Criterion
     - 最大绝对差 / Max absolute difference
     - 状态 / Status
   * - 空构型 / Empty
     - ValueError
     - ValueError
     - exception type
     - n/a
     - PASS
   * - 单基线 / One baseline
     - ValueError
     - ValueError
     - exception type
     - n/a
     - PASS
   * - 共线 / Collinear
     - ValueError
     - ValueError
     - exception type
     - n/a
     - PASS
   * - 缺失相位 / Missing phase
     - ValueError
     - ValueError
     - exception type
     - n/a
     - PASS
   * - 无限方差 / Infinite variance
     - ValueError
     - ValueError
     - exception type
     - n/a
     - PASS
   * - 剔除无效构型后的结果 / Filtered result
     - 10 fields; kx=80, ky=-40, logL=0
     - 10 fields; kx=80, ky=-40, logL=0
     - equal
     - n/a
     - PASS

.. rubric:: 8. 非整周期记录 / Off-bin records

输入 / Input::

   {samples: 64, cycles: [1.25, 2], phase_difference_rad: 0.8, window: boxcar}

计算量 / Measurements::

   {phase_error_deg: [5.5514466, 1.2722219e-14]}

.. list-table:: 数值与行为检查 / Numerical and behavior checks
   :header-rows: 1

   * - 计算量 / Quantity
     - 实际 / Actual
     - 参考或界限 / Reference or limit
     - 判据 / Criterion
     - 最大绝对差 / Max absolute difference
     - 状态 / Status
   * - 1.25 周期相位误差 / Phase error (rad)
     - 0.096891022
     - 0.087266463
     - actual > limit
     - n/a
     - PASS
   * - 2 周期相位误差 / Phase error (rad)
     - 2.220446e-16
     - 1e-12
     - actual < limit
     - n/a
     - PASS

.. rubric:: 9. 众数相位统计 / Histogram-mode statistics

输入 / Input::

   {phase_rad: [0.011, 0.012, 0.013, 0.22], bins: 60}

.. list-table:: 数值与行为检查 / Numerical and behavior checks
   :header-rows: 1

   * - 计算量 / Quantity
     - 实际 / Actual
     - 参考或界限 / Reference or limit
     - 判据 / Criterion
     - 最大绝对差 / Max absolute difference
     - 状态 / Status
   * - 相位均值 / Mean (rad)
     - 0.052359878
     - 0.052359878
     - round(abs(error), 7) == 0
     - 1.4571677e-16
     - PASS
   * - 相位方差 / Variance (rad²)
     - 0.010816667
     - 0.010816667
     - round(abs(error), 7) == 0
     - 0
     - PASS

.. rubric:: 10. 缺失与无噪声样本 / Missing and noiseless samples

输入 / Input::

   {shape: [4, 3], cases: [zero/one FFT, one/one FFT, partly missing phases]}

计算量 / Measurements::

   {zero_mean_rad: [nan, nan, nan], zero_variance_rad2: [nan, nan, nan], partial_mean_rad: [0.15707963, nan], valid_counts: [2, 1]}

.. list-table:: 数值与行为检查 / Numerical and behavior checks
   :header-rows: 1

   * - 计算量 / Quantity
     - 实际 / Actual
     - 参考或界限 / Reference or limit
     - 判据 / Criterion
     - 最大绝对差 / Max absolute difference
     - 状态 / Status
   * - 零互谱统计量均为 NaN / All zero-cross statistics NaN
     - True
     - True
     - true
     - n/a
     - PASS
   * - 无噪声方差 / Noiseless variance (rad²)
     - [1e-12, 1e-12, 1e-12]
     - 1e-12
     - abs(error) <= 1e-25 + 0*abs(reference)
     - 0
     - PASS
   * - 部分有效样本的标记 / Partial-data validity
     - True
     - True
     - true
     - n/a
     - PASS

.. rubric:: 11. 无有效相位的谱 / Spectrum without valid phase

输入 / Input::

   {phase_rad: [NaN], power: [5]}

计算量 / Measurements::

   {spectrum: [[0, 0]], peak_rad_m: [nan]}

.. list-table:: 数值与行为检查 / Numerical and behavior checks
   :header-rows: 1

   * - 计算量 / Quantity
     - 实际 / Actual
     - 参考或界限 / Reference or limit
     - 判据 / Criterion
     - 最大绝对差 / Max absolute difference
     - 状态 / Status
   * - 谱峰为 NaN / Peak is NaN
     - True
     - True
     - true
     - n/a
     - PASS

.. rubric:: 12. 窗口功率归一化 / Window-power normalization

输入 / Input::

   {seed: 42, segments: 4, nperseg: 64, fs_hz: 64, windows: [boxcar, hann]}

计算量 / Measurements::

   {boxcar: {PSD_integral: 0.87633965, time_power: 0.87633965, absolute_error: 1.110223e-16}, hann: {PSD_integral: 0.78909869, time_power: 0.78909869, absolute_error: 0}}

.. list-table:: 数值与行为检查 / Numerical and behavior checks
   :header-rows: 1

   * - 计算量 / Quantity
     - 实际 / Actual
     - 参考或界限 / Reference or limit
     - 判据 / Criterion
     - 最大绝对差 / Max absolute difference
     - 状态 / Status
   * - 矩形窗积分功率 / Boxcar power
     - 0.87633965
     - 0.87633965
     - round(abs(error), 7) == 0
     - 1.110223e-16
     - PASS
   * - Hann 窗积分功率 / Hann power
     - 0.78909869
     - 0.78909869
     - round(abs(error), 7) == 0
     - 0
     - PASS

“最大绝对差”用于相等性比较；不等式检查直接比较实际值与界限。
Max absolute difference is an equality diagnostic; inequality checks use the stated limit.
表格数值显示 8 位有效数字；字典比较展示主要字段，完整精度与全部字段见 summary.json。
Tables show eight significant digits and key dictionary fields; summary.json retains full values.
