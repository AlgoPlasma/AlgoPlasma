.. _g03-references:

.. _g03-s16:

References and Further Reading
------------------------------------------------------------------------

.. container:: ap-lang ap-lang-zh

   以下按教材、原始论文、可公开核对的算法资料排列。正文在相应假设或算法旁标出引用。
   教材与原始模型论文部分全文受限；后列的 NASA 报告、开放论文和官方实现提供可直接核对的公式或选项。

.. container:: ap-lang ap-lang-en

   The references are ordered as textbooks, original papers and publicly checkable algorithm sources.
   The relevant assumptions and algorithms cite them in the main text. Some textbooks and original
   model papers require access; the NASA report, open papers and official implementation documentation
   provide directly accessible equations or options.

.. _g03-ref-bird1994:

1. Bird, G. A. *Molecular Gas Dynamics and the Direct Simulation of Gas Flows*. Oxford University Press, 1994. `DOI <https://doi.org/10.1093/oso/9780198561958.001.0001>`__

.. container:: ap-lang ap-lang-zh

   主教材入口：第 2 章分子模型、第 11 章碰撞抽样。
   `出版方目录 <https://academic.oup.com/book/54839>`__；下面 SPARTA 文档明确回指其 NTC 式 (11.3)、(11.4)。

.. container:: ap-lang ap-lang-en

   Use this as the main textbook: Chapter 2 covers molecular models and Chapter 11 collision sampling.
   See the `publisher's contents <https://academic.oup.com/book/54839>`__.
   The SPARTA documentation below explicitly points back to NTC equations (11.3) and (11.4).

.. _g03-ref-boyd:

2. Boyd, I. D.; Schwartzentruber, T. E. *Nonequilibrium Gas Dynamics and Molecular Simulation*. Cambridge University Press, 2017. `DOI <https://doi.org/10.1017/9781139683494>`__

.. container:: ap-lang ap-lang-zh

   第二本系统教材：重点对照非平衡、内部能量、化学模型和方法适用范围。

.. container:: ap-lang ap-lang-en

   A second systematic textbook: compare nonequilibrium behavior, internal energy, chemistry and the validity ranges of the methods.

.. _g03-ref-bird1963:

3. Bird, G. A. “Approach to Translational Equilibrium in a Rigid Sphere Gas.” *Physics of Fluids* 6, 1518–1519 (1963). `DOI <https://doi.org/10.1063/1.1710976>`__

.. container:: ap-lang ap-lang-zh

   以空间均匀气体的弛豫问题理解随机碰撞方法；对照 :ref:`测试说明 <g03-validation-implementation>` 中的碰撞频率、守恒量与速度分布检验阅读。

.. container:: ap-lang ap-lang-en

   Use homogeneous-gas relaxation to understand the random-collision method. Read alongside
   :ref:`the tests <g03-validation-implementation>` of collision frequency, invariants and velocity distributions.

.. _g03-ref-bird1970:

4. Bird, G. A. “Direct Simulation and the Boltzmann Equation.” *Physics of Fluids* 13, 2676–2681 (1970). `DOI <https://doi.org/10.1063/1.1692849>`__

.. container:: ap-lang ap-lang-zh

   粒子直接模拟与动理学方程的联系；区分物理假设和数值近似。

.. container:: ap-lang ap-lang-en

   Relates direct particle simulation to kinetic equations and separates physical assumptions from numerical approximations.

.. _g03-ref-wagner:

5. Wagner, W. “A convergence proof for Bird's direct simulation Monte Carlo method for the Boltzmann equation.” *Journal of Statistical Physics* 66, 1011–1044 (1992). `DOI <https://doi.org/10.1007/BF01055714>`__

.. container:: ap-lang ap-lang-zh

   进阶：重点阅读粒子数、离散参数的极限过程及收敛所需假设。

.. container:: ap-lang ap-lang-en

   An advanced reference on limits in particle number and discretization parameters and the hypotheses required for convergence.

.. _g03-ref-vss:

6. Koura, K.; Matsumoto, H. “Variable soft sphere molecular model for inverse-power-law or Lennard-Jones potential.” *Physics of Fluids A* 3, 2459–2465 (1991). `DOI <https://doi.org/10.1063/1.858184>`__

.. container:: ap-lang ap-lang-zh

   总截面、散射角与输运系数的关系；先掌握 :ref:`二体散射与碰后速度 <g03-s07>` 再读参数标定。

.. container:: ap-lang ap-lang-en

   Relates total cross section, scattering angle and transport coefficients.
   Understand :ref:`two-body scattering and outgoing velocities <g03-s07>` before parameter calibration.

.. _g03-ref-lb:

7. Borgnakke, C.; Larsen, P. S. “Statistical collision model for Monte Carlo simulation of polyatomic gas mixture.” *Journal of Computational Physics* 18, 405–420 (1975). `DOI <https://doi.org/10.1016/0021-9991(75)90094-7>`__

.. container:: ap-lang ap-lang-zh

   多原子分子的能量重分配。将“发生松弛的概率”和“发生后如何分能量”分开阅读。

.. container:: ap-lang ap-lang-en

   Covers polyatomic energy redistribution. Distinguish the probability of relaxation from energy allocation conditional on relaxation.

.. _g03-ref-cl:

8. Cercignani, C.; Lampis, M. “Kinetic models for gas-surface interactions.” *Transport Theory and Statistical Physics* 1, 101–114 (1971). `DOI <https://doi.org/10.1080/00411457108231440>`__

.. container:: ap-lang ap-lang-zh

   从镜面/漫反射走向更一般的表面散射核，关注平衡一致性与模型参数。

.. container:: ap-lang ap-lang-en

   Extends specular/diffuse descriptions to more general surface-scattering kernels; focus on equilibrium consistency and model parameters.

.. _g03-ref-vahedi:

9. Vahedi, V.; Surendra, M. “A Monte Carlo collision model for the particle-in-cell method: applications to argon and oxygen discharges.” *Computer Physics Communications* 87, 179–198 (1995). `DOI <https://doi.org/10.1016/0010-4655(94)00171-W>`__

.. container:: ap-lang ap-lang-zh

   理解 PIC-MCC 的背景碰撞组织，并与 :ref:`NTC 碰撞抽样 <g03-s06>` 中的显式粒子对算法比较。

.. container:: ap-lang ap-lang-en

   Explains the background-collision organization in PIC-MCC; compare it with explicit-pair
   :ref:`NTC collision sampling <g03-s06>`.

.. _g03-ref-nasa:


10. Liechty, D. S. *Extension of a Kinetic Approach to Chemical Reactions to Electronic Energy Levels and Reactions Involving Charged Species with Application to DSMC Simulations*. NASA/TP-2014-218254, 2014. `NASA record and full text <https://ntrs.nasa.gov/citations/20140006397>`__

.. container:: ap-lang ap-lang-zh

   第 2.1 节给出运动/碰撞子问题；第 2.2.1 节说明 NTC、HS 与 VHS。
   注意式 (2.2.2) 后的文字把接受不等号方向写反；本教程使用均匀数小于接受概率的判定。

.. container:: ap-lang ap-lang-en

   Section 2.1 introduces transport/collision subproblems; Section 2.2.1 covers NTC, HS and VHS.
   The prose after equation (2.2.2) reverses the acceptance inequality; this tutorial accepts when
   the uniform variate is less than the acceptance probability.

.. _g03-ref-lb-vhs:


11. Djordjić, V.; Oblapenko, G.; Pavić-Čolić, M.; Torrilhon, M. “Boltzmann collision operator for polyatomic gases in agreement with experimental data and DSMC method.” *Continuum Mechanics and Thermodynamics* 35, 103–119 (2023). `Open full text <https://doi.org/10.1007/s00161-022-01167-8>`__

.. container:: ap-lang ap-lang-zh

   第 3.2、8 节讨论多原子模型中的内能分配与 VHS 加权，可作为从平动弹性碰撞扩展到内能交换的参考。

.. container:: ap-lang ap-lang-en

   Sections 3.2 and 8 discuss internal-energy allocation and VHS weighting in polyatomic models,
   providing a route from translational elastic collisions to internal-energy exchange.

.. _g03-ref-sparta:


12. SPARTA official documentation (checked 2026-10-18): `collision models and parameters <https://sparta.github.io/doc/collide.html>`__, `candidate-count options <https://sparta.github.io/doc/collide_modify.html>`__, `wall models <https://sparta.github.io/doc/surf_collide.html>`__

.. container:: ap-lang ap-lang-zh

   用作实现对照：``remain no`` 使用随机舍入，``remain yes`` 携带小数余量；
   VSS 的 alpha=1 为 VHS 角分布。官方实现不替代分子物理模型本身的文献依据。

.. container:: ap-lang ap-lang-en

   For implementation comparison: ``remain no`` uses stochastic rounding and ``remain yes``
   carries a fractional remainder. VSS with alpha=1 has the VHS angular distribution.
   Official code documentation complements the original molecular-model literature.

.. _g03-ref-mcf:

13. Pikus et al. “DSMC-SPARTA implementation of majorant collision frequency scheme.”
    *AIP Conference Proceedings* 2132, 070026 (2019).
    `DOI <https://doi.org/10.1063/1.5119580>`__.

.. container:: ap-lang ap-lang-zh

   用于比较 NTC 与 majorant collision frequency 的候选时钟组织。本页“连续时间候选时钟：怎样得到另一种调度”直接推导恒定上界下的指数等待与接受拒绝；
   当前 C++ 的连续时钟实现保持成员固定，动画中的反应增殖调度不作为主库已实现的功能。

.. container:: ap-lang ap-lang-en

   Use this to compare candidate-clock organization in NTC and majorant collision frequency schemes.
   The Continuous-Time Candidate Clock section derives exponential waiting and thinning for a
   constant majorant. Current C++ clock membership is fixed; reaction-driven multiplication in the
   animation is outside the implemented library interface.
