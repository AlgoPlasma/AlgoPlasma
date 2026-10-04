.. _load-model-package-compile-model-table:

.. rst-class:: ap-g02 ap-g02-reference

模型加载与校验：读取 CSV 反应数据
==============================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip::
      :class: g02-terms

      - majorant（频率上界）：一个不小于真实碰撞频率的数，用它安排候选事件，再按“真实频率÷上界”接受候选。上界过松会增加空碰撞；低于真实频率则报错。

   .. _g02-schema-zh:

   本页是 CSV schema（格式规则）的完整文档基准；README 的 schema 表是摘要，以本页为准。当前版本的实际校验由 fun_G02_mcc_model.cpp 和 fun_G02_mcc_compile.cpp 执行。

   .. rubric:: CSV 格式速查

   .. include:: ../../../_includes/g02_columns_zh.inc

   .. include:: ../../../_includes/g02_schema_zh.inc

   实现文件：``fun_G02_mcc_model.cpp``。下面保留对应 C++ 接口的实际名称，方便对照调用。

   .. rubric:: 直接用途

   模型加载分两步：先检查文件与字段是否能读懂，再检查反应物理和单位是否自洽。
   compile_model 的“编译”是把模型数据整理成便于运行的结构，不是调用 C++ 编译器。

   .. code-block:: cpp

      ModelDefinition load_model_package(const std::filesystem::path& package_dir);
      CompiledModel compile_model(ModelDefinition model, CompileOptions options = {});

   package_dir 为输入目录；load 返回 ModelDefinition。
   compile 接收模型值并返回 CompiledModel，包含可用通道索引与频率上界。
   常规入口 MccEngine::load 把两步串起来。失败抛 Error，并尽可能附上文件、行号或反应 ID。

   .. list-table:: CompileOptions
      :header-rows: 1
      :widths: 35 20 45

      * - 字段
        - 默认值
        - 用途
      * - majorant_safety_factor
        - 1.05
        - 给计算出的频率上界留 5% 余量。
      * - diagnostic_majorant_scale
        - 1.0
        - 诊断测试缩放；正常使用保持 1。
      * - relative_tolerance
        - 1e-9
        - 动量与能量核算的相对容差。
      * - max_events_per_step
        - 64
        - 旧 collide 接口的候选上限；批量上限由 StepOptions 控制。

   .. rubric:: Table：数据点之间的插值

   Table::validate(context) 检查非空、递增的 x 网格、有限非负 y 和插值条件。
   Table::sample(x_value, outside) 返回一个 y，outside 为输出 bool。
   x_value 的单位按表的 x_unit：能量 eV 或背景温度 K。
   y_unit 分别为 m2、m3/s 或 m6/s。

   .. list-table::
      :header-rows: 1
      :widths: 30 70

      * - 选项
        - 含义
      * - linear
        - 两点之间用直线插值。
      * - log-linear
        - x 保持线性，对 y 取对数后插值；y 必须为正。
      * - log-log
        - 两个坐标都取对数后插值，需要正的 x、y。
      * - error / zero / clamp
        - 超出范围时报错 / 返回零 / 使用相邻边界值。后两者设置 outside=true。

   segment_upper_bounds() 返回各段 y 上界，upper_bound() 返回总 y 上界。
   截面转成碰撞频率还需要相对速率；compile_model 单独计算 sigma(E)·v(E) 的保守分段上界，
   因此不能直接把最大的截面数值当作频率。

   .. rubric:: CSV 与注册表辅助函数

   read_csv_table(path) 返回 CsvTable；parse_csv_line(line,context) 解析一行。
   CsvTable 的 column/value/value_or 按列名取字段；
   csv_real、csv_real_or、csv_int、csv_bool 转换为对应类型并定位坏字段。
   fnv1a64_hex 用于模型包可选完整性校验。
   SpeciesRegistry 和 StateRegistry 提供 add/at/contains、名称查找与 all；
   状态查询同时指定物种。

   上面的 schema 表统一说明列名、允许值和默认；:doc:`入门教程 <../G02_MCC_network>` 解释物理含义和能量正负号。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - A majorant bounds the true collision rate from above. Candidates use this bound and are accepted with actual-rate/bound probability. Loose bounds waste candidates; violated bounds cause errors.

   .. _g02-schema-en:

   This page is the full CSV schema reference; the README table is a summary and defers to this page. Current validation is implemented by fun_G02_mcc_model.cpp and fun_G02_mcc_compile.cpp.

   .. rubric:: CSV schema quick reference

   .. include:: ../../../_includes/g02_columns_en.inc

   .. include:: ../../../_includes/g02_schema_en.inc

   Implementation: ``fun_G02_mcc_model.cpp``. The C++ interface names below match the callable API.

   .. rubric:: Direct purpose

   Loading validates files and references; compilation validates reaction physics/units and prepares runtime indices and bounds.
   Here compilation organizes model data; it does not invoke a C++ compiler.

   .. code-block:: cpp

      ModelDefinition load_model_package(const std::filesystem::path& package_dir);
      CompiledModel compile_model(ModelDefinition model, CompileOptions options = {});

   The input directory yields ModelDefinition; compilation returns CompiledModel.
   MccEngine::load combines both. Errors include file, line or reaction context where available.

   .. list-table:: CompileOptions
      :header-rows: 1
      :widths: 35 20 45

      * - Field
        - Default
        - Purpose
      * - majorant_safety_factor
        - 1.05
        - 5% margin above computed bounds.
      * - diagnostic_majorant_scale
        - 1.0
        - Diagnostic scaling; keep 1 in normal use.
      * - relative_tolerance
        - 1e-9
        - Relative conservation tolerance.
      * - max_events_per_step
        - 64
        - Bounded collide candidate cap; batch uses StepOptions.

   .. rubric:: Table operations

   validate(context) checks a nonempty increasing x grid, finite nonnegative y and interpolation constraints.
   sample(x_value,outside) returns y and sets the output bool for permitted out-of-domain sampling.
   Units come from x_unit (eV or K) and y_unit (m2, m3/s, m6/s).

   linear interpolates on linear coordinates; log-linear keeps x linear and interpolates log(y), requiring positive y;
   log-log uses logarithms of both positive coordinates.
   Domain policies error/zero/clamp respectively reject, return zero, or use the boundary value;
   the last two set outside=true.

   segment_upper_bounds and upper_bound bound y.
   For cross sections, compile_model separately bounds sigma(E) times relative speed,
   so a maximum cross section alone is not a collision frequency.

   .. rubric:: CSV and registries

   read_csv_table returns CsvTable; parse_csv_line parses one record.
   column/value/value_or access named fields; csv_real, csv_real_or, csv_int and csv_bool convert them.
   fnv1a64_hex supports optional integrity checks.
   SpeciesRegistry and StateRegistry expose add/at/contains, name lookup and all;
   state lookup includes species.

   The schema tables above define columns, allowed values and defaults. The :doc:`tutorial <../G02_MCC_network>` explains physical meaning and energy signs.

.. container:: g02-backlink

   :doc:`返回 G02 教程 / Back to G02 <../G02_MCC_network>`

.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fun_G02_mcc_model.cpp``

:doc:`Model <group_model_data>`
