Particle transport
=================================================================

.. toctree::
   :maxdepth: 1
   :hidden:

   mod_J01_neutral_free_molecular_2Drz
   sub_J01_free_molecular_mc_2Drz
   sub_J01_fm_sampling
   sub_J01_fm_trajectory
   sub_J01_fm_reflection
   sub_J01_fm_statistics

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>


.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 职责与模型

   本模块通过独立粒子历史计算无分子间碰撞的稳态中性场，返回密度、平均速度和带符号面通量。
   它不推进连续性方程。具体几何、入口参数、采样规模和文件输出由测试或应用驱动配置。

   当前实现采用二维 r-z 直线轨迹和两个速度分量，按柱坐标面积、体积归一化。
   它不包含周向运动、体内电离和分子碰撞。入口使用截断正态入射事件分布，
   不等同于储气池 Maxwell 通量采样；定义见采样页。

   .. rubric:: 实现文件

   * :doc:`模块与数据结构 <mod_J01_neutral_free_molecular_2Drz>`
   * :doc:`前处理调度 <sub_J01_free_molecular_mc_2Drz>`
   * :doc:`入口与随机采样 <sub_J01_fm_sampling>`
   * :doc:`轨迹与网格定位 <sub_J01_fm_trajectory>`
   * :doc:`壁面反射 <sub_J01_fm_reflection>`
   * :doc:`驻留统计与通量归一化 <sub_J01_fm_statistics>`

   .. rubric:: 与 J02、J03 的关系

   J01 按粒子轨迹估计场，J02 按离散纵标和 DG 离散求解分布函数。它们是两种前处理入口，
   不是前后相接的算法。两者向 J03 传递同样含义的参考密度和面通量，
   不意味着不同的入口分布、速度维数或损失模型会给出相同物理解。

   J03 从参考通量和迎风参考密度构造固定面速度，后续通量随当前密度变化：

   .. math::

      u_f=\frac{\Gamma_f^{\rm ref}}{\max(n_{\rm up}^{\rm ref},n_{\rm floor})},\qquad
      \Gamma_f(t)=u_f n_{\rm up}(t).

   因此固定的是面速度，不是面通量。入口由应用驱动单独给出，不能把净边界通量同时当作入射和出射。
   改变入口、反射或损失条件时需要重新评估闭合是否仍然适用。

   .. rubric:: 连续性接口与测试

   :doc:`continuity` 保留三维连续性 API 和给定速度的二维 LF 工具，
   不再包含粒子前处理。两套模块位于同一源码目录，分别编译和调用。
   :doc:`模块测试 </tests/011_fluid/J01_fm_tests>` 检查各个计算环节；
   :doc:`应用测试 </tests/011_fluid/application_tests>` 展示本前处理场与其 J03 连续性解。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   The module estimates steady free-molecular density and face fluxes from independent histories.
   It uses reduced two-velocity straight r-z trajectories, not full three-velocity axisymmetric kinetics.
   Sampling, tracing, reflection and estimators are separate include files.
   J02 is an alternative discrete-ordinates preprocessor; both feed the generic J03 closure.
   Legacy continuity APIs remain in :doc:`continuity`.
