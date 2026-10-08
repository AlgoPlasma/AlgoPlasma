Volume Loss
==========================================================================================

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
- 输入 ``ionization_frequency(nr,nz)``：逐单元非负损失频率。
  参数名保留电离含义，但过程实际只做单位换算，不计算电离反应率。
- 输出并分配 ``sigma_t(nr,nz,n_dir)``，
  各离散速度对应的值为 ``ionization_frequency/quadrature%speed(m)``。
- 输出 ``ierr``：无效求积、空频率数组或任何负频率会失败。

这个接口不接收网格对象，因此只检查输入数组的两个维度非空，
不能单独确认它们等于实际网格维数；完整的尺寸匹配由扫描接口检查。
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
