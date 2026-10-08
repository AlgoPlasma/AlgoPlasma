Legacy Utilities
==========================================================================================

.. toctree::
   :maxdepth: 1
   :titlesonly:

   Cartesian Step <sub_J01_continuity_freeflow>
   Cylindrical Flux Utilities <sub_J01_continuity_freeflow_2Drz>

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   本章介绍保留在 J01 目录中的连续性工具，不是粒子前处理流程的一部分。
   调用者已经给定密度、速度或通量，本模块据此计算一次通量或密度更新。

   这些接口属于 ``mod_J01_continuity_freeflow``。
   只编译该模块文件并启用预处理，不单独编译其中包含的两个实现文件。
   原有过程名、参数和三维索引约定保留不变。

   .. rubric:: 按输入选择接口

   .. list-table::
      :header-rows: 1
      :widths: 27 40 33

      * - 接口
        - 已知数据
        - 本次完成的操作
      * - ``sub_J01_continuity_freeflow``
        - 三维节点密度、给定速度、扣减量与保护层
        - 计算三方向数值通量，并原地更新密度
      * - ``sub_J01_build_faceflux_2Drz``
        - 二维单元密度与给定速度
        - 返回内部面与开放边界出射通量
      * - ``sub_J01_continuity_step_2Drz``
        - 二维几何、旧密度、已给通量与源损
        - 分配并返回一步新密度

   三维接口采用归一化单位步长与保护层；
   二维接口采用物理体积、面积、时间步和单元中心数组。
   它们不是应按三维再二维依次执行的计算链，也不是同一套数组布局。

   .. rubric:: 模块常量与调用边界

   二维四面次序为径向低/高、轴向低/高，编号 1 至 4；
   面类型为内部面 0、开放面 1、壁面 2。
   这些名称也出现在同目录的粒子模块中。
   同时引用两个模块时，应使用 ``only`` 明确导入所需名称，避免常量名称冲突。

   该模块包含两个实现文件，分别提供上述三维和二维工具。
   两个算法页分别给出自己的更新公式、输入输出、稳定性与边界要求。
   三维工具不返回面通量数组；二维工具返回的通量也不等于粒子历史的穿面统计。

   .. rubric:: 原接口的相关应用文献

   以下保留原三维接口文档列出的应用背景文献，不作为当前粒子前处理或新增接口的验证结果。


   .. raw:: html

      <ul>
        <li>K. Zhong, D. Zeng, Y. Zhao, and D. Yu, <em>Effects of RZ magnetic field components on electron drift instability in hall thrusters via 3D PIC simulations</em>, <em>Physics Letters A</em> 590 (2026) 131809. DOI: <a href="https://doi.org/10.1016/j.physleta.2026.131809" target="_blank" rel="noopener noreferrer">10.1016/j.physleta.2026.131809</a>.</li>
        <li>Y. Zhao and K. Zhong, <em>Effect of Magnetic Field Configuration on Hall Thruster Azimuthal Instability in 3D PIC simulations</em>, IEPC-2025-063, 39th International Electric Propulsion Conference, London, United Kingdom, 14-19 September 2025.</li>
        <li>Y. Zhao and K. Zhong, <em>3D PIC Simulations on Hall Thruster Electron Drift Instability: Influence of Magnetic Field on Electron Transport</em>, arXiv:2512.06222 [physics.plasm-ph] (2025). DOI: <a href="https://doi.org/10.48550/arXiv.2512.06222" target="_blank" rel="noopener noreferrer">10.48550/arXiv.2512.06222</a>.</li>
        <li>K. Zhong, D. Zeng, Y. Zhao, and D. Yu, <em>3D PIC Study of Magnetic Field Effects on Hall Thruster Electron Drift Instability</em>, arXiv:2504.14144 [physics.plasm-ph] (2025). DOI: <a href="https://doi.org/10.48550/arXiv.2504.14144" target="_blank" rel="noopener noreferrer">10.48550/arXiv.2504.14144</a>.</li>
        <li>Z. Liu, Z. Zhao, and Y. Zhao, <em>Near-Wall Pathways of Anomalous Electron Transport in Hall Thrusters Revealed by 3D PIC Simulations</em>, arXiv:2603.14849 [physics.plasm-ph] (2026). DOI: <a href="https://doi.org/10.48550/arXiv.2603.14849" target="_blank" rel="noopener noreferrer">10.48550/arXiv.2603.14849</a>.</li>
      </ul>

   原三维接口贡献者：赵隐剑（2025/12/02），哈尔滨工业大学。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   These retained interfaces use prescribed fields rather than particle histories.
   Compile ``mod_J01_continuity_freeflow``, which includes the Cartesian step and cylindrical utilities.

   - Cartesian step: node-stored density, velocities, decrement and guards in normalized unit steps.
   - Cylindrical flux builder: given cell density/velocity to internal and outgoing fluxes.
   - Cylindrical step: prescribed fluxes and physical geometry to a newly allocated density.

   They use different layouts and are not successive stages.
   Use explicit ONLY imports if both J01 modules
   are referenced, since face/status constants share names.
   The original Cartesian routine is attributed to Yinjian ZHAO (2025/12/02), Harbin Institute of Technology.
