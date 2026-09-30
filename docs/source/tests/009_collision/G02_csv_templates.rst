.. rst-class:: ap-g02 ap-g02-guide

G02_csv_templates
=================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip::
      :class: g02-terms

      - projectile / primary：projectile 是当前跟踪的入射粒子；primary 是一次事件后对这条原粒子记录的处理结果，可更新、移除或改变物种。background 是用密度、温度等描述的碰撞伙伴。

   .. rubric:: CSV 模板：从一条碰撞反应开始
      :class: g02-chapter

   原始 G02 文件已经带有三套完整示例，现在都保留在 ``tests/009_collision/G02_MCC_network/data/``。
   推荐复制 ``collision_box_elastic/``：它只描述 A + B → A + B，一眼就能对照每张表。
   ``demo_binary/`` 展示多种二体反应，``demo_three_body/`` 展示三体反应，熟悉格式后再看。

   .. note::

      示例中的质量、截面与速率都是合成值，只用来验证软件。表格格式正确不代表物理数据可靠。
      ``templates/blank/`` 是新增的空白模板：表头与原始示例一致，文件清单已预填，其余数据行需要自己补齐。

   G02 模块内也提供相同的空白模板：``G_Collision/G02_MCC_network/templates/blank/``。
   可以从任一位置复制完整目录；修改格式时需同步两份模板。

   .. rubric:: 1. 每个文件做什么？

   CSV 的第一行是列名；后面每一行是一条记录。**复制整个目录**，因为这些表会互相引用。
   下载后也要保留 ``tables/elastic.csv`` 的子目录。下表同时提供空白表和原始已填示例。

   .. list-table::
      :header-rows: 1
      :widths: 22 53 25

      * - 文件
        - 用途与填写要点
        - 下载
      * - ``manifest.csv``
        - 文件清单；预填格式版本和相对路径，只改模型名称与版本等信息。
        - :download:`空白 <../../../../tests/009_collision/G02_MCC_network/templates/blank/manifest.csv>` /
          :download:`已填 <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/manifest.csv>`
      * - ``species.csv``
        - 粒子种类：整数 id、唯一 name、质量 mass_kg（kg）、整数电荷 charge_state，以及 kinetic 或 background。
        - :download:`空白 <../../../../tests/009_collision/G02_MCC_network/templates/blank/species.csv>` /
          :download:`已填 <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/species.csv>`
      * - ``states.csv``
        - 内部能级：id、species 名称、label、energy_ev（eV）、正整数 degeneracy、is_ground。每个物种恰好一个基态。
        - :download:`空白 <../../../../tests/009_collision/G02_MCC_network/templates/blank/states.csv>` /
          :download:`已填 <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/states.csv>`
      * - ``composition.csv``
        - 元素计数：species、element、正整数 count。可选；只对声明的组成核算元素守恒。
        - :download:`空白 <../../../../tests/009_collision/G02_MCC_network/templates/blank/composition.csv>` /
          :download:`已填 <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/composition.csv>`
      * - ``reactions.csv``
        - 反应的 id、name、算法、能量参数、散射模型及 enabled。入门示例用 G02 算法 C02 弹性碰撞。
        - :download:`空白 <../../../../tests/009_collision/G02_MCC_network/templates/blank/reactions.csv>` /
          :download:`已填 <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/reactions.csv>`
      * - ``reactants.csv``
        - 反应前：reaction_id、role、species、state、stoichiometry。role 为 projectile 或 background。
        - :download:`空白 <../../../../tests/009_collision/G02_MCC_network/templates/blank/reactants.csv>` /
          :download:`已填 <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/reactants.csv>`
      * - ``products.csv``
        - 反应后：reaction_id、species、state、stoichiometry。stoichiometry 表示该粒子出现几个。
        - :download:`空白 <../../../../tests/009_collision/G02_MCC_network/templates/blank/products.csv>` /
          :download:`已填 <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/products.csv>`
      * - ``rate_laws.csv``
        - 如何查表：reaction_id、kind、dataset_id、x_source、x_species。示例按背景 B 的温度查速率系数。
        - :download:`空白 <../../../../tests/009_collision/G02_MCC_network/templates/blank/rate_laws.csv>` /
          :download:`已填 <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/rate_laws.csv>`
      * - ``datasets.csv``
        - 数据编号与路径、横纵轴单位、插值和超出范围的处理，以及来源、版本、许可。
        - :download:`空白 <../../../../tests/009_collision/G02_MCC_network/templates/blank/datasets.csv>` /
          :download:`已填 <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/datasets.csv>`
      * - ``tables/elastic.csv``
        - 数值表 x,y；示例 x 是温度 K，y 是二体速率系数 m³/s。x 必须严格递增，y 非负。
        - :download:`空白 <../../../../tests/009_collision/G02_MCC_network/templates/blank/tables/elastic.csv>` /
          :download:`已填 <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/tables/elastic.csv>`

   .. rubric:: 2. 按什么顺序填写？

   1. **先定物种和能级**：填写 ``species.csv`` 、 ``states.csv``，按需要填写 ``composition.csv``。
      ``kinetic`` 是程序跟踪的粒子，``background`` 是用密度和温度描述的背景。
      示例 A 和 B 质量相等，均处于 ``ground`` （基态）；X、Y 是示例的抽象元素标签。
   2. **再定反应**：先在 ``reactions.csv`` 建立一条反应，再在 ``reactants.csv`` 和 ``products.csv`` 写出前后粒子。
      ``reaction_id`` 必须引用已存在的反应 id；``species`` 填物种名称，``state`` 填该物种的能级 label。
      ``stoichiometry=1`` 表示出现一个粒子。反应物应恰有一个计量为 1 的 kinetic projectile。
   3. **最后填碰撞有多快**：填写数值表、``datasets.csv`` 和 ``rate_laws.csv``，检查 ``manifest.csv`` 中的路径。
      文件名可以更改，但引用它的路径也要同步修改。

   .. code-block:: text

      reactions.csv: id=1
          ├─ reactants.csv / products.csv: reaction_id=1
          └─ rate_laws.csv: reaction_id=1, dataset_id=ds_elastic
                 └─ datasets.csv: dataset_id=ds_elastic, path=tables/elastic.csv
                        └─ tables/elastic.csv: x,y

   改 A 的名称时，要同步修改 states、composition、reactants 和 products 中的引用；
   若改变 ``x_species`` 指定的背景名称，rate_laws 中也要同步改。
   改反应 id 要联动反应物、产物和速率表；改 dataset_id 要联动 rate_laws 与 datasets。

   .. rubric:: 3. 哪些值可以留空，单位怎么选？

   .. rubric:: CSV 格式速查

   .. include:: ../../_includes/g02_schema_zh.inc

   初次填写请保留所有表头，按已填示例逐列填写。只在理解含义后使用默认值：

   - ``composition.csv`` 整体可选；不用时删除 manifest 中的 composition 条目。
   - 本例的 ``angular_model=isotropic`` 表示各方向均匀散射，不用角度范围，两个 ``angular_cos_*`` 单元格留空。
     改成 ``cone`` 时需按模型给出余弦范围，不能照抄这两个空格。
   - ``ker_min_ev`` 、 ``radiated_energy_ev`` 留空默认 0，``energy_ev`` 留空也默认 0；初学者建议明确写 0。
     ``source`` 、 ``version`` 、 ``license`` 、 ``notes`` 是数据来源说明，读取器允许空值；真实数据应填写可追溯的来源与许可。
   - ``enabled`` 用 ``true`` 或 ``false``；空白模板需要填入至少一条启用的反应，检查工具才会报告通过。
     其他可选默认值和完整模型约束见 :doc:`模型接口说明 </rst_files/G_Collision/G02_MCC_network/fun_G02_mcc_model>`。

   .. list-table:: 截面和速率系数不能混用
      :header-rows: 1
      :widths: 24 38 38

      * - 输入类型
        - rate_laws
        - datasets 与数值表
      * - 二体截面
        - kind=cross_section；x_source=relative_energy_ev
        - x_axis=energy；x_unit=eV；y_unit=m2
      * - 二体速率系数（本例）
        - kind=rate_coefficient；x_source=temperature_k；x_species=B
        - x_axis=temperature；x_unit=K；y_unit=m3/s
      * - 三体速率系数
        - 同样按指定背景的温度查表
        - 温度单位 K；y_unit=m6/s

   本例在 100–10000 K 范围内使用常数速率系数 ``1e-14 m3/s``；这两行不是测量结果。
   数值表的 x 应严格递增，至少给两个数据点。不要在数值单元格写 ``300 K``，应只写 ``300``，单位放在 datasets 中。
   保存为 UTF-8、逗号分隔格式，保留英文表头；含逗号的文字用双引号包住，字段内部不要换行。
   不要把漏填的质量、编号或数据点随意补成零。

   .. rubric:: 4. 复制后怎样检查？

   在 Linux/WSL 中，从仓库根目录执行。下面会新建一个工作目录，并复制已填好的最小示例：

   .. code-block:: bash

      model_dir=$(mktemp -d /tmp/g02_model.XXXXXX)
      cp -R tests/009_collision/G02_MCC_network/data/collision_box_elastic/. "$model_dir/"
      cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_csv_check -DG02_MCC_ENABLE_FORTRAN=OFF -DG02_MCC_BUILD_TESTS=ON
      cmake --build /tmp/g02_csv_check --target g02_validate_model -j 4
      /tmp/g02_csv_check/g02_validate_model "$model_dir"

   从空白开始时，把复制源改为 ``tests/009_collision/G02_MCC_network/templates/blank/.``，填好后再运行检查。
   成功返回 0 并打印 ``PASS``；加载错误、编译约束不符或未填写模板返回 1；缺少目录参数返回 2。
   它检查已有的格式、关联、单位和模型约束，不验证数据的实验可靠性，也不执行碰撞时间推进。

   使用原始弹性示例时，还可按 :doc:`零维碰撞盒教程 <G02_collision_box>` 检查运行结果。
   修改质量比、反应类型或速率规律后，原碰撞盒的解析判据可能不适用，不能把检查工具的 PASS 当成碰撞盒验证通过。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - The projectile is the tracked incoming particle. The primary outcome tells what happens to that original particle record: update, removal or species change. Background partners are described by density and temperature.

   An identical blank copy is available at ``G_Collision/G02_MCC_network/templates/blank/``. Copy the whole folder and keep both copies synchronized when updating the schema.

   .. rubric:: CSV templates: start with one collision reaction
      :class: g02-chapter

   The original G02 files already contained three complete examples, now under
   ``tests/009_collision/G02_MCC_network/data/``. Start with ``collision_box_elastic/``:
   it describes just A + B → A + B. ``demo_binary/`` adds several two-body reactions;
   ``demo_three_body/`` demonstrates three-body reactions.

   .. note::

      The example masses, cross sections and rates are synthetic software-test values, not research data.
      The new ``templates/blank/`` retains the original headers and a prefilled manifest; fill the other data rows before use.

   .. rubric:: 1. What does each file do?

   The first CSV row contains column names; later rows contain records. **Copy the whole directory**,
   because tables refer to one another. Preserve the ``tables/elastic.csv`` subdirectory when downloading.
   The table links both blank and original filled files.

   .. list-table::
      :header-rows: 1
      :widths: 22 53 25

      * - File
        - Purpose and fields
        - Download
      * - ``manifest.csv``
        - Package index; format and relative paths are prefilled. Set the model name and version.
        - :download:`Blank <../../../../tests/009_collision/G02_MCC_network/templates/blank/manifest.csv>` /
          :download:`Filled <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/manifest.csv>`
      * - ``species.csv``
        - Species: integer id, unique name, mass_kg in kg, integer charge_state, and kinetic or background representation.
        - :download:`Blank <../../../../tests/009_collision/G02_MCC_network/templates/blank/species.csv>` /
          :download:`Filled <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/species.csv>`
      * - ``states.csv``
        - Internal states: id, species name, label, energy_ev in eV, positive integer degeneracy and is_ground. Exactly one ground state per species.
        - :download:`Blank <../../../../tests/009_collision/G02_MCC_network/templates/blank/states.csv>` /
          :download:`Filled <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/states.csv>`
      * - ``composition.csv``
        - Element counts: species, element and positive integer count. Optional; element balance uses declared compositions.
        - :download:`Blank <../../../../tests/009_collision/G02_MCC_network/templates/blank/composition.csv>` /
          :download:`Filled <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/composition.csv>`
      * - ``reactions.csv``
        - Reaction id, name, algorithm, energy parameters, scattering models and enabled flag. The example uses G02 algorithm C02 elastic collisions.
        - :download:`Blank <../../../../tests/009_collision/G02_MCC_network/templates/blank/reactions.csv>` /
          :download:`Filled <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/reactions.csv>`
      * - ``reactants.csv``
        - Before collision: reaction_id, role, species, state and stoichiometry. Role is projectile or background.
        - :download:`Blank <../../../../tests/009_collision/G02_MCC_network/templates/blank/reactants.csv>` /
          :download:`Filled <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/reactants.csv>`
      * - ``products.csv``
        - After collision: reaction_id, species, state and stoichiometry, the number of copies of that species/state.
        - :download:`Blank <../../../../tests/009_collision/G02_MCC_network/templates/blank/products.csv>` /
          :download:`Filled <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/products.csv>`
      * - ``rate_laws.csv``
        - How to look up a rate: reaction_id, kind, dataset_id, x_source and x_species. The example uses background B temperature.
        - :download:`Blank <../../../../tests/009_collision/G02_MCC_network/templates/blank/rate_laws.csv>` /
          :download:`Filled <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/rate_laws.csv>`
      * - ``datasets.csv``
        - Dataset ID, path, axis units, interpolation and out-of-range behavior, plus source, version and license.
        - :download:`Blank <../../../../tests/009_collision/G02_MCC_network/templates/blank/datasets.csv>` /
          :download:`Filled <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/datasets.csv>`
      * - ``tables/elastic.csv``
        - Values x,y; here x is temperature in K and y is a two-body rate coefficient in m³/s. x must strictly increase; y must be nonnegative.
        - :download:`Blank <../../../../tests/009_collision/G02_MCC_network/templates/blank/tables/elastic.csv>` /
          :download:`Filled <../../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/tables/elastic.csv>`

   .. rubric:: 2. Fill in this order

   1. **Species and states first:** fill species, states and optional composition.
      ``kinetic`` means tracked particles; ``background`` means gas described by density and temperature.
      A and B have equal mass and are in their ``ground`` states; X and Y are abstract element labels for this example.
   2. **Define the reaction:** add a reactions row, then its reactants and products.
      ``reaction_id`` refers to a reaction id; ``species`` uses a species name; ``state`` uses that species' state label.
      ``stoichiometry=1`` means one particle. Exactly one kinetic projectile with stoichiometry 1 is required.
   3. **Supply the rate:** fill the numerical table, datasets and rate_laws, then check the manifest paths.
      If you rename a file, update its references too.

   .. code-block:: text

      reactions.csv: id=1
          ├─ reactants.csv / products.csv: reaction_id=1
          └─ rate_laws.csv: reaction_id=1, dataset_id=ds_elastic
                 └─ datasets.csv: dataset_id=ds_elastic, path=tables/elastic.csv
                        └─ tables/elastic.csv: x,y

   Renaming A requires updating states, composition, reactants and products.
   Renaming the background selected by ``x_species`` also requires updating rate_laws.
   Reaction IDs must agree across reaction, reactant, product and rate-law tables;
   dataset IDs must agree in rate_laws and datasets.

   .. rubric:: 3. Empty values and units

   .. rubric:: CSV schema quick reference

   .. include:: ../../_includes/g02_schema_en.inc

   Keep every header and use the filled example as your first guide. Only use defaults when their meaning is clear:

   - Composition is optional; remove its manifest entry if omitting the file.
   - With ``angular_model=isotropic``, the two ``angular_cos_*`` cells are unused and empty in this example.
     A ``cone`` model needs suitable cosine bounds.
   - Empty ``ker_min_ev``, ``radiated_energy_ev`` and ``energy_ev`` default to zero; explicitly write 0 when starting out.
     Source, version, license and notes metadata may be empty to the reader; real data should have traceable provenance and licensing.
   - Use ``true`` or ``false`` for enabled. The checker requires at least one enabled reaction.
     See the :doc:`model interface guide </rst_files/G_Collision/G02_MCC_network/fun_G02_mcc_model>` for other defaults and constraints.

   .. list-table:: Cross sections and rate coefficients have different units
      :header-rows: 1
      :widths: 24 38 38

      * - Input
        - rate_laws
        - datasets and numerical table
      * - Two-body cross section
        - kind=cross_section; x_source=relative_energy_ev
        - x_axis=energy; x_unit=eV; y_unit=m2
      * - Two-body rate coefficient (this example)
        - kind=rate_coefficient; x_source=temperature_k; x_species=B
        - x_axis=temperature; x_unit=K; y_unit=m3/s
      * - Three-body rate coefficient
        - Look up the specified background temperature
        - Temperature in K; y_unit=m6/s

   The example uses a constant ``1e-14 m3/s`` over 100–10000 K. These are invented values, not measurements.
   x must strictly increase; supply at least two points. Write ``300`` in a numerical cell, not ``300 K``; units belong in datasets.
   Save as UTF-8 comma-separated text, retain the English headers, quote text containing commas, and avoid line breaks within fields.
   Do not replace missing masses, IDs or data points with arbitrary zeros.

   .. rubric:: 4. Copy and check

   Run from the repository root in Linux/WSL. These commands create a new working directory and copy the minimal filled example:

   .. code-block:: bash

      model_dir=$(mktemp -d /tmp/g02_model.XXXXXX)
      cp -R tests/009_collision/G02_MCC_network/data/collision_box_elastic/. "$model_dir/"
      cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_csv_check -DG02_MCC_ENABLE_FORTRAN=OFF -DG02_MCC_BUILD_TESTS=ON
      cmake --build /tmp/g02_csv_check --target g02_validate_model -j 4
      /tmp/g02_csv_check/g02_validate_model "$model_dir"

   To start blank, copy ``tests/009_collision/G02_MCC_network/templates/blank/.`` instead and fill it before checking.
   Success prints ``PASS`` and returns 0. Loading errors, failed constraints or unfilled templates return 1; missing arguments return 2.
   This checks existing format, references, units and model constraints, not experimental reliability or collision time evolution.

   For the original elastic example, also follow the :doc:`collision-box tutorial <G02_collision_box>`.
   Changing the mass ratio, reaction type or rate law may invalidate that box's analytic reference;
   passing this checker is not a collision-box validation.

