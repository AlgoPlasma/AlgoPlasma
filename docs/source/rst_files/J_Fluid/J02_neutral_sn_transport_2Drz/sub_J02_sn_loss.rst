.. J_Fluid contribution history (Git author dates; edit times include timezone).
   2026-10-06 23:50 +08:00 | Yingjie Chen | git fa8cb9f5be05
   2026-10-23 10:58 +08:00 | Yingjie Chen | git cd0d957281af
   2026-11-25 15:14 +08:00 | Yingjie Chen | git 8652258184b5
   2026-11-25 15:59 +08:00 | Yingjie Chen | edit (Codex-assisted)

Volume Loss
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J02_sn_loss.f90`` 把已知的单位时间损失频率转换成输运方程使用的单位路程损失系数。
   当前模型只移除中性粒子，不向其他离散速度重新分配粒子，也不添加体产生项。
   频率如何由电子密度、反应截面或其他模型获得，属于调用者的物理输入计算。

   .. rubric:: 1. 损失模型与量纲

   若粒子在很短时间 :math:`\mathrm dt` 内被移除的概率为
   :math:`\nu_K\mathrm dt`，则该过程对分布函数的贡献为
   :math:`-\nu_K\psi`。结合稳态输运方程，

   .. math::

      \frac1r\frac{\partial(rv_m\mu_m\psi_m)}{\partial r}
          +\frac{\partial(v_m\eta_m\psi_m)}{\partial z}
          +\nu_K\psi_m=0.

   在当前模型中，同一个离散速度的速率 :math:`v_m` 不随位置变化，
   且由求积构造保证为正。因此除以速率后，

   .. math::

      \frac1r\frac{\partial(r\mu_m\psi_m)}{\partial r}
          +\frac{\partial(\eta_m\psi_m)}{\partial z}
          +\sigma_{K,m}\psi_m=0,\qquad
      \sigma_{K,m}=\frac{\nu_K}{v_m}.

   :math:`\nu_K` 的单位为 :math:`\mathrm{s^{-1}}`，
   :math:`\sigma_{K,m}` 的单位为 :math:`\mathrm{m^{-1}}`。
   这个转换表示同样的单位时间损失对慢粒子的单位路程衰减更强。
   在均匀、无几何扩张的一维路径上，它对应
   :math:`\psi(\ell)=\psi(0)\exp(-\sigma\ell)`；
   完整的径向输运还包含几何散度项，不能直接用此指数替代整个方程。

   .. rubric:: 2. 转换过程的输入、输出和限制

   本文件只有 ``sub_J02_build_sigma_from_frequency`` 一个子程序。

   - 输入 ``quadrature``：提供各离散速度的正速率。
   - 输入 ``frequency(nr,nz)``：逐单元非负损失频率。
     参数名统一为通用损失频率；过程只做单位换算，不计算电离反应率。
   - 输出并分配 ``sigma_t(nr,nz,n_dir)``，
     各离散速度对应的值为 ``frequency/quadrature%speed(m)``。
   - 输出 ``ierr``：空频率数组或任何负频率会失败。求积对象须已成功初始化。

   这个接口不接收网格对象，因此只检查输入数组的两个维度非空，
   与实际网格的尺寸匹配由调用方按扫描接口约定保证。
   所有单元都进行换算，有效区域筛选在扫描时执行。
   当前输入频率不依赖速度；若反应模型要求速度相关频率，
   必须明确扩展该输入含义，不能仍把一个二维频率数组解释为完整速度相关模型。

   .. rubric:: 3. 损失项如何进入单元方程与总收支

   DG 中的损失贡献为

   .. math::

      (\mathsf A^{\mathrm{loss}})_{ab}
          =\sigma_{K,m}\int_K r\phi_a\phi_b\,\mathrm dr\,\mathrm dz.

   后面的 DG 页会展开这个积分的全部矩阵元素。
   对全速度求和、再乘物理单元体积后，单元总粒子损失率为

   .. math::

      Q_K^{\mathrm{loss}}=\nu_Kn_KV_K.

   因此最终物理量中，入口总粒子率应由开放边界逸出率与
   :math:`\sum_KQ_K^{\mathrm{loss}}` 共同平衡。
   令 :math:`\nu_K=0` 即关闭体损失，不需要另换扫描算法。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J02_sn_loss.f90`` converts a prescribed loss frequency per unit time into the loss per unit path length used by the
   transport equation. The model removes neutrals without redistributing particles to other discrete
   velocities or adding a volumetric production term. The caller derives the frequency from electron
   density, reaction cross sections or another physical input model.

   .. rubric:: 1. Loss model and units

   If the probability of removal during a short time :math:`\mathrm dt` is :math:`\nu_K\mathrm dt`, the contribution to the distribution equation
   is :math:`-\nu_K\psi`. Combining it with steady transport gives

   .. math::

      \frac1r\frac{\partial(rv_m\mu_m\psi_m)}{\partial r}
          +\frac{\partial(v_m\eta_m\psi_m)}{\partial z}
          +\nu_K\psi_m=0.

   In this model the speed :math:`v_m` of a given ordinate is independent of position and positive by construction of
   the quadrature. Dividing by the speed gives

   .. math::

      \frac1r\frac{\partial(r\mu_m\psi_m)}{\partial r}
          +\frac{\partial(\eta_m\psi_m)}{\partial z}
          +\sigma_{K,m}\psi_m=0,\qquad
      \sigma_{K,m}=\frac{\nu_K}{v_m}.

   :math:`\nu_K` has units of :math:`\mathrm{s^{-1}}` and :math:`\sigma_{K,m}` has units of :math:`\mathrm{m^{-1}}`. At the same loss frequency, a slower particle experiences
   stronger attenuation per unit distance. On a uniform one-dimensional path without geometric spreading the
   result is :math:`\psi(\ell)=\psi(0)\exp(-\sigma\ell)`. Radial transport also includes geometric divergence and requires the full equation.

   .. rubric:: 2. Conversion routine, inputs, outputs and limits

   The file supplies one routine, ``sub_J02_build_sigma_from_frequency``.

   - Input ``quadrature`` supplies the positive speed of each ordinate.
   - Input ``frequency(nr,nz)`` is a nonnegative cellwise loss frequency. The routine converts the supplied frequency into a
     path-length coefficient. It does not compute an ionization rate.
   - The routine allocates output ``sigma_t(nr,nz,n_dir)``, with the coefficient at each velocity given by ``frequency/quadrature%speed(m)``.
   - Output ``ierr`` reports an empty frequency array or a negative frequency. The quadrature must already have
     been initialized successfully.

   The interface receives no mesh object. It checks that both frequency-array dimensions are nonempty, and
   the caller is responsible for matching them to the mesh used in the sweep. All cells undergo conversion.
   The sweep later applies the active mask. The input currently depends on position only. A speed-dependent
   reaction frequency would require extending the input beyond a single two-dimensional array.

   .. rubric:: 3. Contribution to the cell equation and global balance

   The loss contribution in the DG system is

   .. math::

      (\mathsf A^{\mathrm{loss}})_{ab}
          =\sigma_{K,m}\int_K r\phi_a\phi_b\,\mathrm dr\,\mathrm dz.

   The DG page expands every entry of this matrix. Summing over velocities and multiplying by the physical
   cell volume gives the total cell loss rate

   .. math::

      Q_K^{\mathrm{loss}}=\nu_Kn_KV_K.

   The physical inlet rate is therefore balanced by escape through open boundaries plus :math:`\sum_KQ_K^{\mathrm{loss}}`. Setting :math:`\nu_K=0`
   disables volumetric loss with the same sweep algorithm.
