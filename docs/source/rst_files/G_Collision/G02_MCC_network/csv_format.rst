.. rst-class:: ap-g02 ap-g02-reference

CSV 数据格式与填写
==================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 1. 模型目录与填写顺序

   用户创建一个目录，再按下文把各张 CSV 写进去。``MccEngine::load`` 和 ``g02_validate_model`` 接收整个目录；所有清单和数据表路径相对于它解析。仓库不提供 CSV 文件下载。

   先写物种和内部态，再写反应及反应物/产物，最后写速率规律和数值表。在 manifest 中登记路径。

   .. code-block:: text

      reactions.id → reactants/products/rate_laws.reaction_id
      rate_laws.dataset_id → datasets.dataset_id → datasets.path → x,y 数值表
      states/composition/reactants/products.species → species.name
      reactants/products.state → 对应物种的 states.label

   .. rubric:: 2. 文件与列

   .. include:: ../../../_includes/g02_columns_zh.inc

   ``manifest.csv`` 的表头是 ``key,value``。必填键、允许值和缺列/空值默认如下；组成表可选，省略时不要在 manifest 中登记它。

   .. include:: ../../../_includes/g02_schema_zh.inc

   物种和内部态 ID 为 0–65534 的整数，反应 ID 为有效正整数。物种 ID/name、态 ID 和同物种的 label、反应 ID/name、dataset_id 必须唯一。每个物种恰好一个基态；state 留空时引用该物种声明的基态，不强制叫 ground。

   每条反应恰有一个 stoichiometry=1 的 kinetic projectile；其余反应物为 background，总反应阶数只支持 2 或 3。质量必须正且有限，计量数必须正整数，能量和所有数值必须有限。编译阶段核对反应类型、能量、电荷和已声明的元素组成；未写组成的物种不进入元素库存。

   .. rubric:: 3. 截面与速率系数怎样写

   .. list-table:: 数据类型和单位
      :header-rows: 1
      :widths: 25 35 40

      * - 类型
        - rate_laws
        - datasets / 数值表
      * - 二体截面
        - kind=cross_section；x_source=relative_energy_ev；x_species 留空
        - x_axis=energy；x_unit=eV；y_unit=m2；x 为相对能量，y 为截面
      * - 二体温度速率系数
        - kind=rate_coefficient；x_source=temperature_k；x_species 为参与反应的背景名称
        - x_axis=temperature；x_unit=K；y_unit=m3/s；threshold_ev=0
      * - 三体温度速率系数
        - 与二体温度系数相同
        - x_axis=temperature；x_unit=K；y_unit=m6/s；threshold_ev=0

   截面横轴是双方相对运动的质心能量：``E_rel = μ |v_projectile-v_background|² / (2 e)``，单位 eV，μ 是约化质量，e 是元电荷。若原始数据给的是实验室入射能，需先按对应实验条件转换；不要直接改单位标签。读取器不做 keV→eV 或 cm²→m² 换算。本文仅描述格式，真实截面值与适用区间由用户的数据决定。

   数值表必须是 ``x,y``，至少两个点。x 严格递增、温度/截面能量非负，y 非负；不能含 NaN、无穷或重复 x。linear 允许 y=0；log-linear 要求所有 y>0；log-log 还要求所有 x>0。截面反应 threshold_ev 必须小于数据表最大能量。

   below_min_policy/above_max_policy 选择 error（越界报错）、zero（越界取零）或 clamp（取端点值）；根据数据物理适用范围填写。threshold_ev 是反应阈值，q_value_ev 是可用动能的反应能量增量，正值放能、负值吸能；C03 必须与内部态能差一致。其他能量、角度模型组合还须满足对应算法限制。

   保存为 UTF-8 逗号分隔文本，英文表头保持不变。每条记录占一行，字段数与表头相同；可跳过空行和以 # 开头的注释。含逗号的文字用双引号包住，文字内的双引号写成两个双引号；不支持字段内换行。数值单元格只写数值，例如 300，单位写在 datasets 中。末尾空字段也需要逗号占位。

   .. rubric:: 4. 检查自己的目录

   .. code-block:: bash

      cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_csv_check -DG02_MCC_BUILD_TESTS=ON
      cmake --build /tmp/g02_csv_check --target g02_validate_model -j 4
      /tmp/g02_csv_check/g02_validate_model /path/to/my_model

   成功打印 PASS 并返回 0；格式、引用或模型约束错误返回 1；缺少目录参数返回 2。检查器不执行时间推进，也不证明实验数据可靠。下一节的数值仅用于说明格式，不用于研究结论。

.. container:: ap-lang ap-lang-en

   .. rubric:: 1. Directory and writing order

   Create a directory and write the CSV files described below. ``MccEngine::load`` and ``g02_validate_model`` take that directory; manifest/table paths resolve relative to it. The repository provides no downloadable CSV files.

   Write species/states first, then reactions and reactants/products, then rate laws and numerical tables. Register paths in the manifest.

   .. code-block:: text

      reactions.id → reactants/products/rate_laws.reaction_id
      rate_laws.dataset_id → datasets.dataset_id → datasets.path → x,y table
      states/composition/reactants/products.species → species.name
      reactants/products.state → that species' states.label

   .. rubric:: 2. Files and columns

   .. include:: ../../../_includes/g02_columns_en.inc

   ``manifest.csv`` uses ``key,value``. Required keys, allowed values and missing-column/empty-cell defaults follow. Composition is optional; omit its manifest entry when omitting the file.

   .. include:: ../../../_includes/g02_schema_en.inc

   Species/state IDs are integers 0–65534; reaction IDs are valid positive integers. Species ID/name, state ID and per-species label, reaction ID/name and dataset_id must be unique. Exactly one ground state per species is required; an empty state selects its declared ground state, which need not be named ground.

   Each reaction has one kinetic projectile with stoichiometry=1 and background partners, total order 2 or 3. Masses must be positive/finite, counts positive integers and all numbers finite. Compilation checks algorithm, energy, charge and declared element inventories. Species without composition do not contribute to the element inventory.

   .. rubric:: 3. Cross sections and rate coefficients

   .. list-table:: Data and units
      :header-rows: 1
      :widths: 25 35 40

      * - Type
        - rate_laws
        - datasets / numerical table
      * - Two-body cross section
        - kind=cross_section; x_source=relative_energy_ev; x_species empty
        - x_axis=energy; x_unit=eV; y_unit=m2; x is relative energy, y cross section
      * - Two-body temperature coefficient
        - kind=rate_coefficient; x_source=temperature_k; x_species names a background reactant
        - x_axis=temperature; x_unit=K; y_unit=m3/s; threshold_ev=0
      * - Three-body temperature coefficient
        - Same rate-law fields as two-body temperature coefficients
        - x_axis=temperature; x_unit=K; y_unit=m6/s; threshold_ev=0

   Cross-section x is centre-of-mass relative energy: ``E_rel = μ |v_projectile-v_background|² / (2 e)``, in eV, where μ is reduced mass and e elementary charge. Laboratory incident-energy data require conversion for the relevant experimental conditions. The reader performs no keV→eV or cm²→m² conversion. Actual values and validity intervals come from the user's physical data.

   Numerical tables use ``x,y`` with at least two points. x must strictly increase; temperature/cross-section energy is nonnegative and y nonnegative. NaN, infinity and duplicate x are invalid. Linear interpolation permits zero y; log-linear requires all y>0; log-log additionally requires all x>0. Cross-section threshold_ev must be below the maximum energy.

   Choose below_min_policy/above_max_policy as error (reject), zero or clamp (endpoint value), according to physical validity. threshold_ev is the reaction threshold; q_value_ev adds to available kinetic energy, positive for release and negative for consumption. C03 q must match internal-state energy differences. Other energy/angular combinations must satisfy their algorithm's constraints.

   Use UTF-8 comma-separated text with unchanged English headers. One record per line, with exactly the header's field count. Blank lines and lines starting with # are skipped. Quote text containing commas and escape an internal quote as two quotes; multiline fields are unsupported. Write numbers alone, such as 300; put units in datasets. Preserve trailing empty cells with commas.

   .. rubric:: 4. Validate your directory

   .. code-block:: bash

      cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_csv_check -DG02_MCC_BUILD_TESTS=ON
      cmake --build /tmp/g02_csv_check --target g02_validate_model -j 4
      /tmp/g02_csv_check/g02_validate_model /path/to/my_model

   Success prints PASS and returns 0. Format/reference/model errors return 1; missing arguments return 2. This does not advance collisions or establish experimental validity. The values in the following example illustrate format only.

.. rubric:: 5. 完整最小示例 / Complete minimal inline example

下面十段内容各保存为标题指定的文件；最后一段放入 tables 子目录。A/B 是虚构粒子，X/Y 是元素记账标签，质量和截面都是说明格式的合成值。
Save each block under its stated filename, with the last in the tables subdirectory. A/B, X/Y, masses and cross sections are synthetic format examples.

.. rubric:: manifest.csv

.. code-block:: text

   key,value
   format,g02-mcc-model-package
   format_version,1
   name,inline_elastic_example
   version,1.0.0
   species,species.csv
   states,states.csv
   composition,composition.csv
   reactions,reactions.csv
   reactants,reactants.csv
   products,products.csv
   rate_laws,rate_laws.csv
   datasets,datasets.csv

.. rubric:: species.csv

.. code-block:: text

   id,name,mass_kg,charge_state,representation
   0,A,4e-26,0,kinetic
   1,B,4e-26,0,background

.. rubric:: states.csv

.. code-block:: text

   id,species,label,energy_ev,degeneracy,is_ground
   0,A,ground,0,1,true
   1,B,ground,0,1,true

.. rubric:: composition.csv

.. code-block:: text

   species,element,count
   A,X,1
   B,Y,1

.. rubric:: reactions.csv

.. code-block:: text

   id,name,algorithm,threshold_ev,q_value_ev,ker_min_ev,radiated_energy_ev,angular_model,angular_cos_min,angular_cos_max,energy_model,enabled
   1,A_B_elastic,C02,0,0,0,0,isotropic,,,n_body_phase_space,true

.. rubric:: reactants.csv

.. code-block:: text

   reaction_id,role,species,state,stoichiometry
   1,projectile,A,ground,1
   1,background,B,ground,1

.. rubric:: products.csv

.. code-block:: text

   reaction_id,species,state,stoichiometry
   1,A,ground,1
   1,B,ground,1

.. rubric:: rate_laws.csv

.. code-block:: text

   reaction_id,kind,dataset_id,x_source,x_species
   1,cross_section,ds_elastic,relative_energy_ev,

.. rubric:: datasets.csv

.. code-block:: text

   dataset_id,path,x_axis,x_unit,y_unit,interpolation,below_min_policy,above_max_policy,source,version,license,notes
   ds_elastic,tables/elastic.csv,energy,eV,m2,linear,zero,error,illustrative,1.0,CC0-1.0,Synthetic values for format illustration only

.. rubric:: tables/elastic.csv

.. code-block:: text

   x,y
   0,1e-20
   100,1e-20

:doc:`Model <group_model_data>`
