Plasma Waves
============

.. raw:: html

   <link rel="stylesheet" href="../../_static/plasma_waves/wave-index.css">
   <script src="../../_static/plasma_waves/wave-index.js"></script>
   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. container:: wave-overview

      一个电子只在原处附近振荡，密度波峰为什么能向前传播？从这个问题出发，你会用波长、周期和相位描述一列波，用叠加解释拍频与驻波，再通过波包区分相速度和群速度。

      接下来，从电子运动方程推导色散关系，看看温度如何改变 Langmuir 波的频率，复频率如何描述振幅的增长与衰减。最后，把模拟中的时空电场转换为 ω–k 谱，比较谱峰与理论曲线。

      贡献者：赵隐剑（哈尔滨工业大学）

   .. rubric:: 第一部分 · 波的基础

   .. container:: wave-directory

      * `01 · 电子运动与等离子体振荡 → <../../_static/plasma_waves/01_what_moves.html?lang=zh>`_

        追踪电子和密度波峰，再用电荷分离、电场与惯性解释电子为什么振荡。

      * `02 · 波的测量与相位 → <../../_static/plasma_waves/02_measuring_a_wave.html?lang=zh>`_

        用探针和空间快照测出周期、波长与相速度，再用两个探针的相位差写出密度波。

      * `03 · 干涉、拍频与驻波 → <../../_static/plasma_waves/03_superposition.html?lang=zh>`_

        观察两列波的增强、相消、拍和驻波，区分密度节点与电子运动。

      * `04 · 波的复数表达 → <../../_static/plasma_waves/04_complex_waves.html?lang=zh>`_

        连接旋转与实部投影，用复振幅处理波的叠加和微分。

      * `05 · 色散关系与读图 → <../../_static/plasma_waves/05_dispersion.html?lang=zh>`_

        读出波长、周期与相速度，观察曲线上三个波分量叠加后的电子密度。

      * `06 · 波包、相速度与群速度 → <../../_static/plasma_waves/06_wave_packets.html?lang=zh>`_

        用 14 张幻灯片追踪波峰和包络，推导群速度，比较色散与无色散。

      * `07 · 第一条色散关系怎样推出来？ → <../../_static/plasma_waves/07_deriving_dispersion.html?lang=zh>`_

        从连续性、动量与泊松方程推导冷电子色散关系，再加入压强接回温电子模型。

      * `08 · 温度怎样改变波？ → <../../_static/plasma_waves/08_warm_langmuir.html?lang=zh>`_

        从电子压强推出 Langmuir 波的热修正，并在同一密度下比较冷、热色散曲线。

      * `09 · 波为什么增长或衰减？ → <../../_static/plasma_waves/09_complex_frequency.html?lang=zh>`_

        展开复频率的指数，用探针记录区分振荡角频率与振幅增长率。

      * `10 · 如何看模拟中的 ω–k 谱图？ → <../../_static/plasma_waves/10_reading_spectra.html?lang=zh>`_

        从已知电场记录计算二维谱，读出亮点与亮带，再叠加理论色散曲线。

.. container:: ap-lang ap-lang-en

   .. container:: wave-overview

      How can a density crest travel while each electron oscillates near its starting point? Use wavelength, period and phase to describe a wave, superpose waves to explain beats and standing waves, then follow a wave packet to distinguish phase velocity from group velocity.

      Next, derive a dispersion relation from the electron equations of motion, explore how temperature shifts the Langmuir-wave frequency, and use complex frequency to describe growth and damping. Finally, turn a space–time field record into an ω–k spectrum and compare its peaks with the predicted curve.

      Contributor: Yinjian Zhao (Harbin Institute of Technology)

   .. rubric:: Part 1 · Wave basics

   .. container:: wave-directory

      * `01 · Electron motion and plasma oscillations → <../../_static/plasma_waves/01_what_moves.html?lang=en>`_

        Track an electron and a density crest, then use charge separation, electric force and inertia to explain electron oscillations.

      * `02 · Wave measurements and phase → <../../_static/plasma_waves/02_measuring_a_wave.html?lang=en>`_

        Measure period, wavelength and phase speed, then compare two probes and express the density wave in terms of its phase.

      * `03 · Interference, beats and standing waves → <../../_static/plasma_waves/03_superposition.html?lang=en>`_

        Explore reinforcement, cancellation, beats and standing waves, and distinguish density nodes from electron motion.

      * `04 · Complex wave representation → <../../_static/plasma_waves/04_complex_waves.html?lang=en>`_

        Connect rotation to real-part projection and use complex amplitudes for superposition and differentiation.

      * `05 · Reading a dispersion relation → <../../_static/plasma_waves/05_dispersion.html?lang=en>`_

        Read wavelength, period and phase speed, then combine three points into one density pattern.

      * `06 · Wave packets, phase and group velocities → <../../_static/plasma_waves/06_wave_packets.html?lang=en>`_

        A 14-slide sequence: track phase and envelope, derive group speed, and compare dispersive and nondispersive waves.

      * `07 · Deriving the first dispersion relation → <../../_static/plasma_waves/07_deriving_dispersion.html?lang=en>`_

        Derive the cold-electron relation from continuity, momentum and Poisson, then add pressure to recover the warm model.

      * `08 · How does temperature change the wave? → <../../_static/plasma_waves/08_warm_langmuir.html?lang=en>`_

        Derive the thermal correction from electron pressure and compare cold and warm Langmuir waves at one density.

      * `09 · Why do waves grow or damp? → <../../_static/plasma_waves/09_complex_frequency.html?lang=en>`_

        Expand the complex-frequency exponent and use a probe trace to distinguish oscillation from amplitude growth.

      * `10 · How do we read an ω–k spectrum? → <../../_static/plasma_waves/10_reading_spectra.html?lang=en>`_

        Transform a known field record, read its spectral peaks and band, and overlay the theoretical dispersion curve.

.. Plasma-wave contribution history (Git author dates; edit time includes timezone).
   2026-11-17 19:33 +08:00 | Yinjian Zhao | git fb1cc989ad32
   2026-11-17 19:41 +08:00 | Yinjian Zhao | git 7667d669c7ec
   2026-11-17 19:50 +08:00 | Yinjian Zhao | git 3e022dd90c69
   2026-11-17 20:09 +08:00 | Yinjian Zhao | git c97a40fba286
   2026-11-17 20:14 +08:00 | Yinjian Zhao | git 022513948783
   2026-11-17 20:26 +08:00 | Yinjian Zhao | git 80d9ffd0c710
   2026-11-17 20:54 +08:00 | Yinjian Zhao | git d334e2e4b253
   2026-11-17 21:23 +08:00 | Yinjian Zhao | git 789e519340b7
   2026-11-18 08:16 +08:00 | Yinjian Zhao | git 45f247468130
   2026-11-18 15:43 +08:00 | Yinjian Zhao | git 1f9402dd7fdd
   2026-11-18 16:04 +08:00 | Yinjian Zhao | git 92c692b04920
   2026-11-18 16:36 +08:00 | Yinjian Zhao | git 4be5f6b5764f
   2026-11-19 09:27 +08:00 | Yinjian Zhao | git 8e569041c60d
   2026-11-19 11:06 +08:00 | Yinjian Zhao | git 3242c1a909ef
   2026-11-19 15:26 +08:00 | Yinjian Zhao | git b9e33596c00f
   2026-11-19 16:01 +08:00 | Yinjian Zhao | git 2113cbc05ed4
   2026-11-19 16:12 +08:00 | Yinjian Zhao | git cf0e315a57e8
   2026-11-19 16:16 +08:00 | Yinjian Zhao | git a23fd84e77e6
   2026-11-19 16:28 +08:00 | Yinjian Zhao | edit (Codex-assisted)
