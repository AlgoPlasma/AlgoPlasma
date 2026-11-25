Wall Reflection
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J01_fm_reflection.f90`` 只有 ``sub_J01_reflect_velocity`` 一个过程。
   跟踪过程已经确定碰到哪个壁面；本过程只修改粒子速度，再交回同一条轨迹继续计算。

   .. rubric:: 1. 碰壁前后应满足什么条件

   设 :math:`\boldsymbol n_f` 是从气体指向壁外的单位法向。
   碰壁前有 :math:`\boldsymbol v\cdot\boldsymbol n_f>0`，
   反射后必须有 :math:`\boldsymbol v'\cdot\boldsymbol n_f<0`。
   当前壁面不吸附粒子，碰壁后仍只有一条、权重不变的历史；
   壁面可以改变运动方向，也可以在热漫反射时改变粒子能量。

   输入 :math:`d\in[0,1]` 对应 ``diffuse_fraction``。
   每次碰壁独立抽一个均匀随机数：小于 :math:`d` 时漫反射，否则镜面反射。
   这是选择一次反射事件，不是把同一粒子的两个速度向量按比例相加。

   .. rubric:: 2. 镜面反射保留切向速度

   将速度分解为法向和切向分量，镜面反射为

   .. math::

      \boldsymbol v'=\boldsymbol v
          -2(\boldsymbol v\cdot\boldsymbol n_f)\boldsymbol n_f.

   因此径向壁只翻转 :math:`v_r`，轴向壁只翻转 :math:`v_z`。
   切向分量和速率保持不变，轨迹在同一气体侧继续。

   .. rubric:: 3. 热漫反射为什么使用不同的法向分布

   壁温为 :math:`T_{\mathrm w}`，定义
   :math:`\sigma_{\mathrm w}=\sqrt{k_{\mathrm B}T_{\mathrm w}/M}`，
   其中 :math:`M` 是粒子质量，:math:`k_{\mathrm B}` 是 Boltzmann 常数。
   用 :math:`c>0` 表示返回气体的法向速率，:math:`v_t` 表示切向速度。
   壁面热分布本身按速度呈高斯形，但离开壁面的粒子统计要乘穿面的速率 :math:`c`。
   归一化后的联合概率密度是

   .. math::

      p(c,v_t)=
         \frac{c}{\sigma_{\mathrm w}^2}
             e^{-c^2/(2\sigma_{\mathrm w}^2)}
         \frac{1}{\sqrt{2\pi}\sigma_{\mathrm w}}
             e^{-v_t^2/(2\sigma_{\mathrm w}^2)},\qquad c>0.

   它分成两个独立分布。切向是零均值正态；法向累计概率为

   .. math::

      F_c(c)=\int_0^c\frac{s}{\sigma_{\mathrm w}^2}
                      e^{-s^2/(2\sigma_{\mathrm w}^2)}\,\mathrm ds
             =1-e^{-c^2/(2\sigma_{\mathrm w}^2)}.

   抽取相互独立的随机变量 :math:`\xi\sim U(0,1)` 和
   :math:`Z\sim N(0,1)`，分别用于法向和切向速度。
   :math:`\xi` 是均匀随机数，:math:`Z` 是标准正态随机数。
   反解得到 :math:`c=\sigma_{\mathrm w}\sqrt{-2\ln(1-\xi)}`。
   由于 :math:`1-\xi` 也服从均匀分布，代码等价地使用

   .. math::

      c=\sigma_{\mathrm w}\sqrt{-2\ln\xi},\qquad
      v_t=\sigma_{\mathrm w}Z.

   这就是法向 Rayleigh 分布与切向正态分布。不能把法向速率简单改为正态随机数的绝对值；
   后者缺少穿面速率加权，表示的是不同的物理模型。

   .. rubric:: 4. 把法向、切向速度写回坐标分量

   .. list-table::
      :header-rows: 1
      :widths: 28 24 24 24

      * - 碰到的面
        - 外法向
        - 漫反射后的 :math:`v_r'`
        - 漫反射后的 :math:`v_z'`
      * - 径向低端
        - :math:`(-1,0)`
        - :math:`c`
        - :math:`v_t`
      * - 径向高端
        - :math:`(1,0)`
        - :math:`-c`
        - :math:`v_t`
      * - 轴向低端
        - :math:`(0,-1)`
        - :math:`v_t`
        - :math:`c`
      * - 轴向高端
        - :math:`(0,1)`
        - :math:`v_t`
        - :math:`-c`

   每一行都保证法向分量返回气体。切向正态分量可正可负，
   所以漫反射还可能改变粒子沿另一个坐标方向的运动趋势。

   .. rubric:: 5. 过程输入与输出

   ``sub_J01_reflect_velocity``：

   - 输入并原地修改 ``ur,uz``，单位 m/s；输出为反射后粒子速度。
   - 输入 ``face``，必须为四个合法面常量之一。
   - 输入 ``diffuse_fraction``，必须在 :math:`[0,1]`。
   - 输入 ``sigma_wall``，是正的速度标准差（m/s），不是温度（K）；
     完整调用过程根据质量和壁温计算它。
   - 不修改位置、不记录穿面、不改变历史权重，也不返回 ``ierr``。
     单独调用时必须满足面编号、速度方向和参数的前置条件。

   轨迹过程负责碰壁后的微小向内定位，再计算下一段飞行。
   在两面交会的角点，反射导致的切向改向会影响后续碰面处理，下一页按执行顺序说明。
   若新增吸附模型，不能只让速度归零；还需要规定历史结束方式及粒子损失统计。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J01_fm_reflection.f90`` provides a single routine, ``sub_J01_reflect_velocity``. After the tracker
   identifies the wall face, this routine changes the velocity and returns control to the same history.

   .. rubric:: 1. Incident and reflected velocities

   Let :math:`\boldsymbol n_f` be the unit normal pointing out of the gas. An incident particle satisfies
   :math:`\boldsymbol v\cdot\boldsymbol n_f>0`; the reflected particle must satisfy
   :math:`\boldsymbol v'\cdot\boldsymbol n_f<0`. The wall does not adsorb particles, so the same history
   continues with unchanged weight. A reflection changes the direction and, for thermal diffuse reflection,
   can change the energy.

   The input :math:`d\in[0,1]` corresponds to ``diffuse_fraction``. At each wall hit the routine draws an
   independent uniform variate. A value below :math:`d` selects diffuse reflection; all other values select
   specular reflection. Each hit selects one of the two events.

   .. rubric:: 2. Specular reflection preserves tangential velocity

   Resolve the velocity into components normal and tangential to the wall. Specular reflection gives

   .. math::

      \boldsymbol v'=\boldsymbol v
          -2(\boldsymbol v\cdot\boldsymbol n_f)\boldsymbol n_f.

   A radial wall reverses only :math:`v_r`; an axial wall reverses only :math:`v_z`. Speed and tangential
   velocity are preserved, and the particle continues on the gas side.

   .. rubric:: 3. Normal velocity in thermal diffuse reflection

   For a wall at :math:`T_{\mathrm w}` define
   :math:`\sigma_{\mathrm w}=\sqrt{k_{\mathrm B}T_{\mathrm w}/M}`, where :math:`M` is the particle mass and
   :math:`k_{\mathrm B}` the Boltzmann constant. Let :math:`c>0` be the normal speed back into the gas and
   :math:`v_t` the tangential velocity. The wall Maxwellian is Gaussian in velocity. Sampling particles
   leaving the surface weights it by the crossing speed :math:`c`, giving the normalized joint density

   .. math::

      p(c,v_t)=
         \frac{c}{\sigma_{\mathrm w}^2}
             e^{-c^2/(2\sigma_{\mathrm w}^2)}
         \frac{1}{\sqrt{2\pi}\sigma_{\mathrm w}}
             e^{-v_t^2/(2\sigma_{\mathrm w}^2)},\qquad c>0.

   The components are independent. The tangential component is normal with zero mean. The cumulative
   distribution of the normal speed is

   .. math::

      F_c(c)=\int_0^c\frac{s}{\sigma_{\mathrm w}^2}
                      e^{-s^2/(2\sigma_{\mathrm w}^2)}\,\mathrm ds
             =1-e^{-c^2/(2\sigma_{\mathrm w}^2)}.

   Draw independent :math:`\xi\sim U(0,1)` and :math:`Z\sim N(0,1)` for the normal and tangential
   velocities, respectively. Here :math:`\xi` is uniform and :math:`Z` is standard normal. Inverting the
   cumulative distribution gives :math:`c=\sigma_{\mathrm w}\sqrt{-2\ln(1-\xi)}`. Since :math:`1-\xi` is
   also uniform, the code equivalently uses

   .. math::

      c=\sigma_{\mathrm w}\sqrt{-2\ln\xi},\qquad
      v_t=\sigma_{\mathrm w}Z.

   The normal speed is Rayleigh distributed and the tangential component is Gaussian. Taking the absolute
   value of a Gaussian for the normal speed would omit the crossing-speed weight and describe a different
   wall model.

   .. rubric:: 4. Transforming normal and tangential velocities to grid coordinates

   .. list-table::
      :header-rows: 1
      :widths: 28 24 24 24

      * - Face hit
        - Outward normal
        - Reflected :math:`v_r'`
        - Reflected :math:`v_z'`
      * - Lower radial
        - :math:`(-1,0)`
        - :math:`c`
        - :math:`v_t`
      * - Upper radial
        - :math:`(1,0)`
        - :math:`-c`
        - :math:`v_t`
      * - Lower axial
        - :math:`(0,-1)`
        - :math:`v_t`
        - :math:`c`
      * - Upper axial
        - :math:`(0,1)`
        - :math:`v_t`
        - :math:`-c`

   In every row the normal component points back into the gas. The tangential Gaussian has either sign, so
   a diffuse reflection can reverse motion along the other coordinate too.

   .. rubric:: 5. Procedure inputs and outputs

   ``sub_J01_reflect_velocity``:

   - ``ur,uz`` (m/s) is updated in place to the reflected particle velocity.
   - ``face`` must be one of the four valid face constants.
   - ``diffuse_fraction`` must lie in :math:`[0,1]`.
   - ``sigma_wall`` is a positive velocity standard deviation in m/s. The driver computes it from particle
     mass and wall temperature in kelvin.
   - The routine leaves position and history weight unchanged, records no crossing, and has no ``ierr``
     result. Direct callers must supply a valid face, incident direction and reflection parameters.

   The tracker places the particle slightly inside the wall after reflection, then finds the next flight
   segment. At a corner the new tangential velocity affects how the other face is handled; the next page
   describes the ordering. An adsorption extension must specify how the history ends and how particle
   losses are tallied. Setting velocity to zero alone does not model adsorption.
