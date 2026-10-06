以下允许值表列出推荐的标准写法；解析器也接受 elastic、reservoir、phase_space 等兼容别名，完整别名见源码。G02 算法 C01 是抽样流程，不是 reactions.algorithm 的可填反应值。

.. list-table:: 允许值
   :header-rows: 1
   :widths: 43 57

   * - 字段 / 键
     - 规则
   * - ``species.representation``
     - kinetic / background
   * - ``reactants.role``
     - projectile / background
   * - ``reactions.algorithm``
     - C02–C08（CSV 中填 C02 等原始值；不填“G02 算法”前缀）
   * - ``reactions.angular_model``
     - isotropic / cone / identity_exchange
   * - ``reactions.energy_model``
     - n_body_phase_space / equal_share
   * - ``rate_laws.kind``
     - cross_section / rate_coefficient
   * - ``rate_laws.x_source``
     - relative_energy_ev（截面）/ temperature_k（速率系数）
   * - ``datasets.x_axis; x_unit; y_unit``
     - energy; eV; m2 或 temperature; K; m3/s（二体）/ m6/s（三体）
   * - ``datasets.interpolation``
     - linear / log-linear / log-log
   * - ``datasets.below_min_policy / above_max_policy``
     - error / zero / clamp
   * - ``enabled / is_ground``
     - true/1/yes/on 为真；false/0/no/off/空值为假；忽略大小写

.. list-table:: 必填键：manifest.csv
   :header-rows: 1
   :widths: 43 57

   * - 字段 / 键
     - 规则
   * - ``format``
     - 必须为 g02-mcc-model-package
   * - ``format_version``
     - 必须为 1
   * - ``name / version``
     - 模型名称和版本；均不可为空
   * - ``species / states / reactions``
     - 三个 CSV 文件的相对路径；均必填
   * - ``reactants / products / rate_laws / datasets``
     - 四个 CSV 文件的相对路径；均必填
   * - ``composition``
     - 可选；无键或空值时不加载组成表
   * - ``checksum.<relative path>``
     - 可选；填写后校验该文件的 16 位十六进制 FNV-1a 64 校验和

.. list-table:: 留空默认
   :header-rows: 1
   :widths: 43 57

   * - 字段 / 键
     - 规则
   * - ``states.energy_ev; reactions.ker_min_ev / radiated_energy_ev``
     - 空值或缺列 → 0 eV
   * - ``reactants.state / products.state``
     - 空值或缺列 → 对应物种声明的基态（不一定叫 ground）
   * - ``reactions.angular_model``
     - 空值或缺列 → isotropic
   * - ``reactions.energy_model``
     - 空值或缺列 → n_body_phase_space
   * - ``reactions.angular_cos_min / angular_cos_max``
     - 空值或缺列 → 0；cone 时建议显式填写所需范围
   * - ``reactions.enabled / states.is_ground``
     - 空值 → false；缺列报错。每个物种仍须恰好一个基态
   * - ``datasets.source / version / license / notes``
     - 空值或缺列 → 空字符串；科研数据应补齐来源与许可
   * - ``rate_laws.x_species``
     - 空值或缺列 → 空字符串；temperature_k 速率律必须指定有效背景物种
   * - ``composition（manifest 键）``
     - 空值或缺键 → 不读取组成；未声明组成的物种不计入元素库存
   * - ``其他必需数值/字段``
     - 质量、ID、计量数、threshold_ev、q_value_ev、x/y 等无通用默认；按模型约束填写

建议按列清单保留完整表头。“缺列”表示表头里没有该列；“空值”表示有列但单元格为空，两者并不总等价。枚举值允许也不保证组合有效：例如 equal_share 恰好两个产物，identity_exchange 还必须满足严格共振条件。
