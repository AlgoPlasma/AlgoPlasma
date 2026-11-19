(() => {
  'use strict';
  const M = PlasmaPacketModel, gold = '#f4c583', blue = '#b4cefa';
  const speed = value => `${(value / 1e6).toFixed(3)} × 10⁶ m/s`;
  const texts = {
    zh: {
      documentTitle: '波包、相速度与群速度', title: '一群波，<span>谁在向前走？</span>', chapter: '08 / 波包、相速度与群速度',
      pause: '暂停动画', play: '播放动画', back: '上一步', returnLabel: '返回等离子体波课堂', progress: '讲解步骤',
      keyboard: '点击点阵或按 → 继续 · F 全屏', fullscreenFailed: '当前预览不允许全屏，请在独立浏览器中打开。',
      model: '窄带温电子流体示例；无磁场、离子固定，忽略阻尼。点阵示意合成密度，时间减速并循环。',
      comparisonModel: '数学对照 ω = Vk；保留相同波数、幅值和初相位。时间减速并循环。',
      steps: [
        '相近波数的分量叠加，让密度扰动集中在一段空间：波包。',
        '蓝色虚线勾勒波包的包络：它告诉我们哪里振荡强、哪里振荡弱。',
        '金点跟踪中心分量的一个等相位位置。相速度描述内部波峰的推进。',
        '蓝圈跟踪包络最强处。窄带、弱失真时，它的速度近似为群速度。',
        '在中心波数处：原点连线给相速度，切线给群速度。两种斜率对应两种运动。',
        '切换对照：当 ω 与 k 成正比，包络与内部波峰会一起移动。'
      ],
      actions: ['画出包络', '跟踪内部波峰', '跟踪包络中心', '回到色散图', '比较无色散情况', '重新读一遍'],
      equations: ['',
        'δn = ∑ⱼ Aⱼ cos(kⱼx − ωⱼt)<small>31 个相近分量；中心波数 k<sub>c</sub> = 60 rad/m；δn、Aⱼ [m⁻³]</small>',
        'v<sub>ph</sub> = ω<sub>c</sub> / k<sub>c</sub>',
        'v<sub>g</sub> = (dω/dk)<sub>c</sub>',
        'v<sub>ph</sub> = ω<sub>c</sub>/k<sub>c</sub>　v<sub>g</sub> = (dω/dk)<sub>c</sub>',
        'ω = Vk　⇒　v<sub>ph</sub> = v<sub>g</sub> = V'],
      descriptions: [
        '31个相近波数的电子密度波叠加成一个局部增强的波包。上方曲线是相对密度扰动δn/n₀，下方是同一组电子的密度点阵。横轴x为米，观察窗为−0.5到0.9m。初始暂停；可以播放动画。',
        '在总密度波外画出正负包络。蓝色虚线的高度来自同一复数叠加的模，刻画振荡强弱；它不是另一组电子或另一种密度。',
        '金点位于中心分量的恒定相位k_c x−ω_c t=0，随x=vph t移动。它近似跟随波包中的一个波峰；它不是被标记的电子。可播放或拖动时间比较位置。',
        '蓝圈定位实际计算的包络最大值；金点仍跟踪中心分量相位。此窄带例子中蓝圈移动更慢，内部波峰穿过包络并逐渐减弱。群速度是中心波数处dω/dk，近似包络速度，不是电子速度。',
        '色散图横轴k [rad/m]、纵轴ω [rad/s]，淡色带表示所取分量42至78 rad/m。中心点k_c=60 rad/m。金色原点连线斜率是相速度；蓝色虚线是切线，其斜率是群速度。右侧仍用各分量的实际色散频率计算波包。',
        '无色散对照采用过原点的直线ω=Vk，V取原模型中心相速度。保持同一组波数、幅值和初相位，所有分量以V传播，波包形状精确平移，金点与蓝圈同步。取消对照即可在同一时刻比较温电子流体分支。'
      ],
      takeaway: '<span class="gold">相速度：跟相位。</span> <span style="color:#b4cefa">群速度：窄带包络。</span> 两者都不是电子速度。',
      envelopeKey: '蓝色虚线：包络', phaseKey: '金点：中心分量相位', groupKey: '蓝圈：包络中心',
      dotsTitle: '同一组电子', slopeTitle: '原点连线与切线', timeLabel: '观察时间 t',
      compare: '无色散对照：ω = Vk', chartDescription: '色散图，横轴k [rad/m]，纵轴ω [rad/s]。金色原点连线给相速度，蓝色切线给群速度。',
      groupNote: '邻近分量：Δω/Δk → dω/dk；窄带包络速度 ≈ v<sub>g</sub>',
      phaseNote: 'k<sub>c</sub> = 60 rad/m；ω<sub>c</sub> = 1.166 × 10⁸ rad/s；金点不是电子',
      derivationTitle: '为什么群速度是 dω/dk？',
      derivation: `
<section class="explanation-section">
<h3>先把两个邻近分量写清楚</h3>
<p>取两个等幅的密度波。A 是密度幅值 [m⁻³]，x 是位置 [m]，t 是时间 [s]：</p><p class="math">δn = A cos(k₁x − ω₁t) + A cos(k₂x − ω₂t)</p><p>定义它们的差值和平均值：</p><p class="math">Δk = k₂ − k₁　[rad/m]</p><p class="math">Δω = ω₂ − ω₁　[rad/s]</p><p class="math">k̄ = <span class="eq-frac"><span>k₁ + k₂</span><span class="sr-only"> / </span><span class="eq-den">2</span></span>　[rad/m]</p><p class="math">ω̄ = <span class="eq-frac"><span>ω₁ + ω₂</span><span class="sr-only"> / </span><span class="eq-den">2</span></span>　[rad/s]</p>
</section>
<section class="explanation-section">
<h3>用和差化积识别包络</h3>
<p>把两项相加，改写成缓慢调制与内部快速振荡的乘积：</p><p class="math">δn = 2A cos[<span class="eq-frac"><span>Δk x − Δω t</span><span class="sr-only"> / </span><span class="eq-den">2</span></span>] · cos(k̄x − ω̄t)</p><p>当两个波数、频率足够接近时，第一项随空间和时间变化较慢，形成拍包络；第二项描述包络内部的振荡。</p>
</section>
<section class="explanation-section">
<h3>跟踪缓慢调制的同一相位</h3>
<p>要跟踪包络上的同一位置，就保持慢变量的相位不变：</p><p class="math">Δk x − Δω t = 常数</p><p>对时间求导。Δk 和 Δω 对这两个给定分量是常数，所以：</p><p class="math">Δk <span class="eq-frac"><span>dx</span><span class="sr-only"> / </span><span class="eq-den">dt</span></span> − Δω = 0</p><p class="math"><span class="eq-frac"><span>dx</span><span class="sr-only"> / </span><span class="eq-den">dt</span></span> = <span class="eq-frac"><span>Δω</span><span class="sr-only"> / </span><span class="eq-den">Δk</span></span>　[m/s]</p><p>这就是两个邻近点之间的割线斜率。</p>
</section>
<section class="explanation-section">
<h3>从割线到切线</h3>
<p>两个波数趋近中心 k<sub>c</sub> 时，割线斜率趋于切线斜率，得到群速度：</p><p class="math">v<sub>g</sub> = lim<sub>Δk→0</sub> <span class="eq-frac"><span>Δω</span><span class="sr-only"> / </span><span class="eq-den">Δk</span></span></p><p class="math">v<sub>g</sub> = (<span class="eq-frac"><span>dω</span><span class="sr-only"> / </span><span class="eq-den">dk</span></span>)<sub>c</sub>　[m/s]</p><p>如果跟踪的是内部快速振荡，则保持 k̄x − ω̄t 不变，得到相速度：</p><p class="math">v<sub>ph</sub> = <span class="eq-frac"><span>ω̄</span><span class="sr-only"> / </span><span class="eq-den">k̄</span></span> → <span class="eq-frac"><span>ω<sub>c</sub></span><span class="sr-only"> / </span><span class="eq-den">k<sub>c</sub></span></span>　[m/s]</p><p>两个分量形成周期性的拍包络；许多邻近分量适当加权，才形成本页观察到的局部波包。</p>
</section>
      `,
      detailsTitle: '波包怎样生成？近似在哪里？',
      details: `
<section class="explanation-section">
<h3>采用哪条色散关系？</h3>
<p>沿用 07 页的温电子流体模型。背景均匀、无磁场、离子固定，忽略碰撞与 Landau 阻尼；电子温度通过压强项进入模型。</p>
<p class="math">ω(k) = √(ω₀² + u²k²)</p>
<p class="math">ω₀ = 10⁸ rad/s</p>
<p class="math">u = 10⁶ m/s</p>
<p>ω₀ 是 k → 0 时的振荡角频率，u 是压强项的速度参数。要计算群速度，先把关系写成 ω² = ω₀² + u²k²，再对 k 求导：</p>
<p class="math">2ω <span class="eq-frac"><span>dω</span><span class="sr-only"> / </span><span class="eq-den">dk</span></span> = 2u²k</p>
<p>在中心波数 k<sub>c</sub> 处取值，记 ω<sub>c</sub> = ω(k<sub>c</sub>)，于是：</p>
<p class="math">v<sub>g</sub> = <span class="eq-frac"><span>u²k<sub>c</sub></span><span class="sr-only"> / </span><span class="eq-den">ω<sub>c</sub></span></span></p>
<p>k<sub>c</sub> 的单位是 rad/m，ω<sub>c</sub> 的单位是 rad/s，得到的 v<sub>g</sub> 单位是 m/s。</p>
</section>
<section class="explanation-section">
<h3>怎样选出组成波包的分量？</h3>
<p>取 31 个等间隔波数。j 只是分量编号，依次为 0、1、…、30：</p>
<p class="math">kⱼ = (42 + 1.2j) rad/m</p>
<p>它们围绕中心波数分布。靠近中心的分量权重大，离中心越远，权重越小：</p>
<p class="math">k<sub>c</sub> = 60 rad/m，　σₖ = 6 rad/m</p>
<p class="math">wⱼ = exp [−<span class="eq-frac"><span>(kⱼ − k<sub>c</sub>)²</span><span class="sr-only"> / </span><span class="eq-den">2σₖ²</span></span>]</p>
<p>σₖ 描述波数权重分布的宽度，wⱼ 是无量纲权重。用这些权重分配密度幅值，并让初相位都为零：</p>
<p class="math"><span class="eq-frac"><span>Aⱼ</span><span class="sr-only"> / </span><span class="eq-den">n₀</span></span> = 0.18 <span class="eq-frac"><span>wⱼ</span><span class="sr-only"> / </span><span class="eq-den">∑ₗ wₗ</span></span></p>
<p class="math">φⱼ = 0 rad</p>
<p>这里 l 与 j 都遍历这 31 个分量；分母是全部权重之和。n₀ 是背景密度，Aⱼ 是各分量的密度幅值，两者单位均为 m⁻³。在初始中心 x = 0、t = 0，各分量同相增强；在当前观察窗内，离开中心后相互抵消增多，形成局部增强的波包。</p>
<p>总密度为 n = n₀ + δn。这样的归一化使总扰动受控，密度始终为正：</p>
<p class="math"><span class="eq-frac"><span>|δn|</span><span class="sr-only"> / </span><span class="eq-den">n₀</span></span> ≤ 0.18，　<span class="eq-frac"><span>n</span><span class="sr-only"> / </span><span class="eq-den">n₀</span></span> ≥ 0.82</p>
<p>离散谱在空间上会重复，间距约为 5.24 m。本页只观察 −0.5 m 到 0.9 m，窗口内显示一个波包。</p>
</section>
<section class="explanation-section">
<h3>白线、蓝色包络与两个标记是什么？</h3>
<p>每个分量按自己的实际角频率 ωⱼ = ω(kⱼ) 演化。先把同一位置、同一时刻的密度扰动相加，得到白线：</p>
<p class="math"><span class="eq-frac"><span>δn(x,t)</span><span class="sr-only"> / </span><span class="eq-den">n₀</span></span> = ∑ⱼ <span class="eq-frac"><span>Aⱼ</span><span class="sr-only"> / </span><span class="eq-den">n₀</span></span> cos(kⱼx − ωⱼt)</p>
<p>x 的单位为 m，t 为 s；因此每个相位 kⱼx − ωⱼt 都是无量纲角度。也可以把相同的叠加写成复数形式，记作 Z：</p>
<p class="math">Z(x,t) = ∑ⱼ <span class="eq-frac"><span>Aⱼ</span><span class="sr-only"> / </span><span class="eq-den">n₀</span></span> exp[i(kⱼx − ωⱼt)]</p>
<p>白线取 Z 的实部；蓝色包络取它的模。用 B 表示相对密度包络，Z 与 B 都无量纲：</p>
<p class="math"><span class="eq-frac"><span>δn</span><span class="sr-only"> / </span><span class="eq-den">n₀</span></span> = Re Z，　B(x,t) = |Z(x,t)|</p>
<p><strong class="group-key">蓝圈</strong>定位计算得到的 B 的最大值。它跟踪振荡最强的位置，不是另一组电子。</p>
<p><strong class="phase-key">金点</strong>跟踪中心分量的固定相位：</p>
<p class="math">k<sub>c</sub>x − ω<sub>c</sub>t = 0</p>
<p class="math">x<sub>phase</sub>(t) = <span class="eq-frac"><span>ω<sub>c</sub></span><span class="sr-only"> / </span><span class="eq-den">k<sub>c</sub></span></span> t = v<sub>ph</sub>t</p>
<p>窄带时，金点近似跟随波包内的一个波峰；随着它穿过包络，这个波峰会增强再减弱。金点也不是某个电子的位置。</p>
</section>
<section class="explanation-section">
<h3>“包络以群速度移动”近似在哪里？</h3>
<p>关键是分量集中在中心波数附近。对色散关系只保留一阶展开：</p>
<p class="math">ω(k) ≈ ω<sub>c</sub> + v<sub>g</sub>(k − k<sub>c</sub>)</p>
<p>代回复数叠加式，可以把中心分量的快速相位提出，剩余部分记作 F：</p>
<p class="math">Z(x,t) ≈ exp[i(k<sub>c</sub>x − ω<sub>c</sub>t)] · F(x − v<sub>g</sub>t)</p>
<p class="math">F(ξ) = ∑ⱼ <span class="eq-frac"><span>Aⱼ</span><span class="sr-only"> / </span><span class="eq-den">n₀</span></span> exp[i(kⱼ − k<sub>c</sub>)ξ]</p>
<p>ξ 的单位为 m，F 无量纲。前面的指数因子模长为 1，所以包络近似只依赖 x − v<sub>g</sub>t：</p>
<p class="math">B(x,t) ≈ |F(x − v<sub>g</sub>t)|</p>
<p>保持 x − v<sub>g</sub>t 不变，就在跟踪包络上的同一位置；这说明它以 v<sub>g</sub> 移动。</p>
<p>动画仍使用完整的 ω(kⱼ)，没有把包络强制平移，因此保留了轻微失真。更宽的频带或更长的传播时间会使高阶项变得重要，可能出现展宽；此时不能继续把包络视为刚性形状。</p>
<p>本例 v<sub>g</sub> &lt; v<sub>ph</sub>，但其他色散关系未必如此。这里讨论的是窄带包络，也不把群速度无条件等同于能量或信息传播速度。</p>
</section>
<section class="explanation-section">
<h3>无色散对照改变了什么？</h3>
<p><strong>色散是指不同频率的波分量具有不同的相速度。</strong>无色散时，各分量的相速度相同。</p><p>本页把色散关系改成经过原点的直线：</p><p class="math">ω = Vk</p><p>令 V 等于原模型的中心相速度：</p>
<p class="math">V = <span class="eq-frac"><span>ω<sub>c</sub></span><span class="sr-only"> / </span><span class="eq-den">k<sub>c</sub></span></span> ≈ 1.944 × 10⁶ m/s</p>
<p>波数、幅值、初相位、空间窗和播放时间比例保持不变。这时所有分量都以同一速度 V 传播，整个波包保持形状平移：</p>
<p class="math">v<sub>ph</sub> = v<sub>g</sub> = V</p>
<p>金点与蓝圈因此同步。这是用于比较的数学模型，不是另一条等离子体色散分支。</p>
</section>
<section class="explanation-section">
<h3>怎样理解动画时间与电子点阵？</h3>
<p>每播放 1 s，对应物理时间 3 × 10⁻⁸ s。动画在下面的时间区间循环回放，拖动时间条会暂停：</p>
<p class="math">0 ≤ t ≤ 2 × 10⁻⁷ s</p>
<p>点阵根据合成密度作守恒的运动学映射，让点的疏密与白线对应。它没有求解粒子受力，也没有绘制随机热运动；相速度和群速度都不是单个电子的运动速度。</p>
<p>读图与群速度推导：<a href="https://bpb-us-e1.wpmucdn.com/sites.harvard.edu/dist/0/550/files/2023/11/waves_dispersion.pdf" target="_blank" rel="noopener">David Morin · Dispersion，§6.3</a>。</p>
<p>温电子流体背景：<a href="https://silas.psfc.mit.edu/introplasma/master.pdf" target="_blank" rel="noopener">MIT · Introduction to Plasma Physics</a>。</p>
</section>
      `
    },
    en: {
      documentTitle: 'Wave packets, phase and group velocities', title: 'A group of waves. <span>What moves forward?</span>', chapter: '08 / Wave packets, phase and group velocities',
      pause: 'Pause', play: 'Play', back: 'Previous step', returnLabel: 'Return to the plasma waves course', progress: 'Explanation step',
      keyboard: 'Click the dots or press → · F fullscreen', fullscreenFailed: 'Fullscreen is unavailable here. Open a separate browser tab.',
      model: 'Narrow-band warm-electron fluid example; no magnetic field, fixed ions, no damping. Dots depict total density; time is slowed and looped.',
      comparisonModel: 'Mathematical comparison ω = Vk; same wavenumbers, amplitudes and initial phases. Time is slowed and looped.',
      steps: [
        'Nearby wavenumbers add up to a density disturbance concentrated in space: a wave packet.',
        'The blue dashed envelope shows where the oscillations are strong and where they are weak.',
        'The gold dot follows a constant phase of the central component. Phase speed tracks the inner crests.',
        'The blue ring follows the strongest part of the envelope. For a narrow band with little distortion, its speed is approximately the group speed.',
        'At the central wavenumber: the origin-to-point slope gives phase speed; the tangent gives group speed.',
        'Switch the comparison: when ω is proportional to k, the envelope and inner crests travel together.'
      ],
      actions: ['Show the envelope', 'Track an inner crest', 'Track the envelope', 'Read the dispersion plot', 'Compare no dispersion', 'Read it again'],
      equations: ['',
        'δn = ∑ⱼ Aⱼ cos(kⱼx − ωⱼt)<small>31 nearby components; central k<sub>c</sub> = 60 rad/m; δn, Aⱼ [m⁻³]</small>',
        'v<sub>ph</sub> = ω<sub>c</sub> / k<sub>c</sub>', 'v<sub>g</sub> = (dω/dk)<sub>c</sub>',
        'v<sub>ph</sub> = ω<sub>c</sub>/k<sub>c</sub>　v<sub>g</sub> = (dω/dk)<sub>c</sub>',
        'ω = Vk　⇒　v<sub>ph</sub> = v<sub>g</sub> = V'],
      descriptions: [
        '31 nearby wavenumbers form a localized electron-density packet. The upper curve is relative perturbation δn/n₀; below is one shared electron population. Horizontal x is in meters, from −0.5 to 0.9m. The animation starts paused and can be played.',
        'Blue dashed upper and lower envelopes surround the total density wave. Their magnitude comes from the modulus of the same complex superposition. The envelope is not another electron population or another density.',
        'The gold dot follows k_c x−ω_c t=0 at x=vph t. It approximately follows an inner crest of the narrow-band packet. It does not mark an electron. Play or scrub time to compare positions.',
        'The blue ring marks the computed envelope maximum while the gold dot follows the central phase. Here the ring travels more slowly; the inner crest passes through the envelope and fades. The derivative dω/dk at the central k is the group speed, approximately the envelope speed, not an electron velocity.',
        'The dispersion axes are k [rad/m] and ω [rad/s]. The shaded band spans the selected 42–78 rad/m; the central point is k_c=60 rad/m. The gold origin ray gives phase speed; the blue dashed tangent gives group speed. The packet still uses each component’s actual dispersion frequency.',
        'The nondispersive comparison uses a line through the origin, ω=Vk, with V equal to the original central phase speed. The same wavenumbers, amplitudes and initial phases now translate exactly at V. The gold dot and blue ring travel together. Uncheck to compare the warm-electron branch at the same time.'
      ],
      takeaway: '<span class="gold">Phase speed: follow phase.</span> <span style="color:#b4cefa">Group speed: the narrow-band envelope.</span> Neither is an electron velocity.',
      envelopeKey: 'Blue dashes: envelope', phaseKey: 'Gold dot: central phase', groupKey: 'Blue ring: envelope center',
      dotsTitle: 'Same electrons', slopeTitle: 'Origin ray and tangent', timeLabel: 'Observe time t',
      compare: 'No-dispersion comparison: ω = Vk', chartDescription: 'Dispersion axes: k [rad/m], ω [rad/s]. Gold origin ray: phase speed. Blue tangent: group speed.',
      groupNote: 'Nearby components: Δω/Δk → dω/dk; narrow-band envelope speed ≈ v<sub>g</sub>',
      phaseNote: 'k<sub>c</sub> = 60 rad/m; ω<sub>c</sub> = 1.166 × 10⁸ rad/s; the gold dot is not an electron',
      derivationTitle: 'Why is group speed dω/dk?',
      derivation: `
<section class="explanation-section">
<h3>Start with two nearby components</h3>
<p>Take two equal-amplitude density waves. A is the density amplitude [m⁻³], x the position [m], and t the time [s]:</p><p class="math">δn = A cos(k₁x − ω₁t) + A cos(k₂x − ω₂t)</p><p>Define their differences and averages:</p><p class="math">Δk = k₂ − k₁　[rad/m]</p><p class="math">Δω = ω₂ − ω₁　[rad/s]</p><p class="math">k̄ = <span class="eq-frac"><span>k₁ + k₂</span><span class="sr-only"> / </span><span class="eq-den">2</span></span>　[rad/m]</p><p class="math">ω̄ = <span class="eq-frac"><span>ω₁ + ω₂</span><span class="sr-only"> / </span><span class="eq-den">2</span></span>　[rad/s]</p>
</section>
<section class="explanation-section">
<h3>Separate modulation from the inner oscillation</h3>
<p>Apply the sum-to-product identity to express the sum as a product:</p><p class="math">δn = 2A cos[<span class="eq-frac"><span>Δk x − Δω t</span><span class="sr-only"> / </span><span class="eq-den">2</span></span>] · cos(k̄x − ω̄t)</p><p>When the two wavenumbers and frequencies are close, the first factor varies slowly in space and time and gives the beat envelope. The second factor describes the faster inner oscillation.</p>
</section>
<section class="explanation-section">
<h3>Follow a fixed modulation phase</h3>
<p>Follow the same location on the envelope by holding the slow phase constant:</p><p class="math">Δk x − Δω t = constant</p><p>Differentiate with respect to time. Δk and Δω are constants for these two specified components:</p><p class="math">Δk <span class="eq-frac"><span>dx</span><span class="sr-only"> / </span><span class="eq-den">dt</span></span> − Δω = 0</p><p class="math"><span class="eq-frac"><span>dx</span><span class="sr-only"> / </span><span class="eq-den">dt</span></span> = <span class="eq-frac"><span>Δω</span><span class="sr-only"> / </span><span class="eq-den">Δk</span></span>　[m/s]</p><p>This is the secant slope between the two nearby points.</p>
</section>
<section class="explanation-section">
<h3>Take the tangent limit</h3>
<p>As the wavenumbers approach the center k<sub>c</sub>, the secant slope approaches the tangent slope. This gives group speed:</p><p class="math">v<sub>g</sub> = lim<sub>Δk→0</sub> <span class="eq-frac"><span>Δω</span><span class="sr-only"> / </span><span class="eq-den">Δk</span></span></p><p class="math">v<sub>g</sub> = (<span class="eq-frac"><span>dω</span><span class="sr-only"> / </span><span class="eq-den">dk</span></span>)<sub>c</sub>　[m/s]</p><p>Following the faster inner oscillation instead holds k̄x − ω̄t constant, giving phase speed:</p><p class="math">v<sub>ph</sub> = <span class="eq-frac"><span>ω̄</span><span class="sr-only"> / </span><span class="eq-den">k̄</span></span> → <span class="eq-frac"><span>ω<sub>c</sub></span><span class="sr-only"> / </span><span class="eq-den">k<sub>c</sub></span></span>　[m/s]</p><p>Two components give a periodic beat envelope. Many nearby, appropriately weighted components form the localized packet seen in this window.</p>
</section>
      `,
      detailsTitle: 'How is the packet built? What is approximate?',
      details: `
<section class="explanation-section">
<h3>Which dispersion relation is used?</h3>
<p>We retain the warm-electron fluid model from page 07: a uniform, unmagnetized background with fixed ions. Collisions and Landau damping are omitted; electron temperature enters through pressure.</p>
<p class="math">ω(k) = √(ω₀² + u²k²)</p>
<p class="math">ω₀ = 10⁸ rad/s</p>
<p class="math">u = 10⁶ m/s</p>
<p>ω₀ is the oscillation angular frequency as k → 0; u is the pressure speed parameter. To calculate group speed, write ω² = ω₀² + u²k² and differentiate with respect to k:</p>
<p class="math">2ω <span class="eq-frac"><span>dω</span><span class="sr-only"> / </span><span class="eq-den">dk</span></span> = 2u²k</p>
<p>Evaluate at the central wavenumber k<sub>c</sub>, with ω<sub>c</sub> = ω(k<sub>c</sub>):</p>
<p class="math">v<sub>g</sub> = <span class="eq-frac"><span>u²k<sub>c</sub></span><span class="sr-only"> / </span><span class="eq-den">ω<sub>c</sub></span></span></p>
<p>k<sub>c</sub> is in rad/m and ω<sub>c</sub> in rad/s, giving v<sub>g</sub> in m/s.</p>
</section>
<section class="explanation-section">
<h3>How are the packet components chosen?</h3>
<p>Take 31 equally spaced wavenumbers. The index j labels the components, from 0 through 30:</p>
<p class="math">kⱼ = (42 + 1.2j) rad/m</p>
<p>Components nearer the central wavenumber have larger weights; those farther away have smaller weights:</p>
<p class="math">k<sub>c</sub> = 60 rad/m,　σₖ = 6 rad/m</p>
<p class="math">wⱼ = exp [−<span class="eq-frac"><span>(kⱼ − k<sub>c</sub>)²</span><span class="sr-only"> / </span><span class="eq-den">2σₖ²</span></span>]</p>
<p>σₖ describes the width of the wavenumber weight distribution, and wⱼ is dimensionless. Use the weights to set the density amplitudes, with zero initial phases:</p>
<p class="math"><span class="eq-frac"><span>Aⱼ</span><span class="sr-only"> / </span><span class="eq-den">n₀</span></span> = 0.18 <span class="eq-frac"><span>wⱼ</span><span class="sr-only"> / </span><span class="eq-den">∑ₗ wₗ</span></span></p>
<p class="math">φⱼ = 0 rad</p>
<p>Both l and j run over the 31 components; the denominator sums all weights. The background density n₀ and amplitudes Aⱼ are in m⁻³. At x = 0, t = 0, the components reinforce in phase. Away from that center within this window, cancellation increases, producing a localized packet.</p>
<p>The total density is n = n₀ + δn. The normalization bounds the perturbation and keeps density positive:</p>
<p class="math"><span class="eq-frac"><span>|δn|</span><span class="sr-only"> / </span><span class="eq-den">n₀</span></span> ≤ 0.18,　<span class="eq-frac"><span>n</span><span class="sr-only"> / </span><span class="eq-den">n₀</span></span> ≥ 0.82</p>
<p>The discrete spectrum repeats in space every 5.24 m. The viewing window, −0.5 m to 0.9 m, shows one packet.</p>
</section>
<section class="explanation-section">
<h3>What do the curves and markers represent?</h3>
<p>Each component evolves with its actual angular frequency ωⱼ = ω(kⱼ). Add their density perturbations at the same position and time to obtain the white curve:</p>
<p class="math"><span class="eq-frac"><span>δn(x,t)</span><span class="sr-only"> / </span><span class="eq-den">n₀</span></span> = ∑ⱼ <span class="eq-frac"><span>Aⱼ</span><span class="sr-only"> / </span><span class="eq-den">n₀</span></span> cos(kⱼx − ωⱼt)</p>
<p>x is in m and t in s, so each phase kⱼx − ωⱼt is a dimensionless angle. Write the same superposition in complex form and call it Z:</p>
<p class="math">Z(x,t) = ∑ⱼ <span class="eq-frac"><span>Aⱼ</span><span class="sr-only"> / </span><span class="eq-den">n₀</span></span> exp[i(kⱼx − ωⱼt)]</p>
<p>The white curve is the real part of Z. The blue envelope is its modulus, denoted B. Both Z and this relative-density envelope B are dimensionless:</p>
<p class="math"><span class="eq-frac"><span>δn</span><span class="sr-only"> / </span><span class="eq-den">n₀</span></span> = Re Z,　B(x,t) = |Z(x,t)|</p>
<p>The <strong class="group-key">blue ring</strong> locates the computed maximum of B, where the oscillations are strongest. It does not represent another electron population.</p>
<p>The <strong class="phase-key">gold dot</strong> follows a fixed phase of the central component:</p>
<p class="math">k<sub>c</sub>x − ω<sub>c</sub>t = 0</p>
<p class="math">x<sub>phase</sub>(t) = <span class="eq-frac"><span>ω<sub>c</sub></span><span class="sr-only"> / </span><span class="eq-den">k<sub>c</sub></span></span> t = v<sub>ph</sub>t</p>
<p>For a narrow band, this approximately follows an inner crest. The crest grows and fades as it crosses the envelope. The gold dot does not mark an individual electron either.</p>
</section>
<section class="explanation-section">
<h3>Where does the group-speed approximation enter?</h3>
<p>The components are concentrated near the central wavenumber. Keep only the first-order expansion of the dispersion relation:</p>
<p class="math">ω(k) ≈ ω<sub>c</sub> + v<sub>g</sub>(k − k<sub>c</sub>)</p>
<p>Substitute this into the complex sum. Factor out the fast central phase and call the remaining function F:</p>
<p class="math">Z(x,t) ≈ exp[i(k<sub>c</sub>x − ω<sub>c</sub>t)] · F(x − v<sub>g</sub>t)</p>
<p class="math">F(ξ) = ∑ⱼ <span class="eq-frac"><span>Aⱼ</span><span class="sr-only"> / </span><span class="eq-den">n₀</span></span> exp[i(kⱼ − k<sub>c</sub>)ξ]</p>
<p>ξ is in m and F is dimensionless. The exponential prefactor has unit modulus, so the envelope approximately depends only on x − v<sub>g</sub>t:</p>
<p class="math">B(x,t) ≈ |F(x − v<sub>g</sub>t)|</p>
<p>Holding x − v<sub>g</sub>t constant follows the same location on the envelope. Its speed is therefore v<sub>g</sub>.</p>
<p>The animation uses the full ω(kⱼ), retaining slight distortion rather than forcing the envelope to translate rigidly. A broader band or longer propagation makes higher-order terms important and can produce spreading.</p>
<p>This example has v<sub>g</sub> &lt; v<sub>ph</sub>; other dispersion relations need not. We are describing a narrow-band envelope, not identifying group speed unconditionally with energy or information speed.</p>
</section>
<section class="explanation-section">
<h3>What changes in the nondispersive comparison?</h3>
<p><strong>Dispersion means that components of different frequencies have different phase speeds.</strong>In the nondispersive case, all components have the same phase speed.</p><p>Our comparison uses a straight line through the origin:</p><p class="math">ω = Vk</p><p>Choose V to match the original central phase speed:</p>
<p class="math">V = <span class="eq-frac"><span>ω<sub>c</sub></span><span class="sr-only"> / </span><span class="eq-den">k<sub>c</sub></span></span> ≈ 1.944 × 10⁶ m/s</p>
<p>Keep the wavenumbers, amplitudes, initial phases, spatial window and playback scale unchanged. Every component now travels at V, so the whole packet translates without changing shape:</p>
<p class="math">v<sub>ph</sub> = v<sub>g</sub> = V</p>
<p>The gold dot and blue ring travel together. This is a mathematical comparison, not an additional plasma dispersion branch.</p>
</section>
<section class="explanation-section">
<h3>How should the time and electron dots be read?</h3>
<p>Each playback second represents 3 × 10⁻⁸ s of physical time. The animation loops over the interval below; scrubbing time pauses it:</p>
<p class="math">0 ≤ t ≤ 2 × 10⁻⁷ s</p>
<p>The dots use a conservative kinematic map of the combined density, so their spacing follows the white curve. Particle forces and random thermal motion are not solved. Neither phase nor group speed is an individual electron velocity.</p>
<p>Geometry and group-speed derivation: <a href="https://bpb-us-e1.wpmucdn.com/sites.harvard.edu/dist/0/550/files/2023/11/waves_dispersion.pdf" target="_blank" rel="noopener">David Morin · Dispersion, §6.3</a>.</p>
<p>Warm-electron background: <a href="https://silas.psfc.mit.edu/introplasma/master.pdf" target="_blank" rel="noopener">MIT · Introduction to Plasma Physics</a>.</p>
</section>
      `
    }
  };
  function chart(a) {
    if (!a.text || a.s.stage < 4) return;
    const svg = a.$('slope-chart'), w = svg.clientWidth, h = svg.clientHeight;
    if (!w || !h) return;
    const left = w < 400 ? 57 : 80, right = w - 24, top = 65, bottom = h - 72;
    const x = k => left + k / 100 * (right - left), y = omega => bottom - omega / 2.1e8 * (bottom - top);
    const add = (tag, attrs, text) => {
      const node = document.createElementNS('http://www.w3.org/2000/svg', tag);
      for (const [key, value] of Object.entries(attrs)) node.setAttribute(key, String(value));
      if (text !== undefined) node.textContent = text;
      svg.append(node); return node;
    };
    const line = (x1, y1, x2, y2, cls) => add('line', { x1, y1, x2, y2, class: cls });
    const label = (text, px, py, anchor = 'middle') => add('text', { x: px, y: py, 'text-anchor': anchor }, text);
    svg.setAttribute('viewBox', `0 0 ${w} ${h}`); svg.replaceChildren();
    add('rect', { x: x(42), y: top, width: x(78) - x(42), height: bottom - top, fill: '#b5efcf', opacity: .09 });
    line(left, bottom, right + 8, bottom, 'packet-axis'); line(left, bottom, left, top - 10, 'packet-axis');
    label('ω [rad/s]', left, 27, 'start'); label('k [rad/m]', right, h - 10, 'end');
    for (const k of [0, 60, 100]) { line(x(k), bottom, x(k), bottom + 7, 'packet-axis'); label(k, x(k), bottom + 32, k === 100 ? 'end' : 'middle'); }
    line(left, y(1e8), right, y(1e8), 'packet-guide'); label('10⁸', left - 12, y(1e8) + 8, 'end');
    const linear = a.s.data.linear, vg = M.groupSpeed(M.KC, linear);
    add('polyline', { points: Array.from({ length: 101 }, (_, k) => `${x(k)},${y(M.frequency(k, linear))}`).join(' '), class: 'packet-branch' });
    line(left, bottom, x(M.KC), y(M.WC), 'packet-ray');
    line(x(0), y(M.WC - vg * M.KC), x(100), y(M.WC + vg * (100 - M.KC)), 'packet-tangent');
    add('circle', { cx: x(M.KC), cy: y(M.WC), r: 7, fill: '#edf5f1', stroke: '#10181c', 'stroke-width': 2 });
    label('P', x(M.KC) + 14, y(M.WC) - 18, 'start');
    svg.setAttribute('aria-label', `${a.text.chartDescription} vph = ${speed(M.VP)}; vg = ${speed(vg)}.`);
  }
  function syncTime(a) {
    a.$('packet-time').value = String(a.s.time);
    const text = `${(a.s.time / 10).toFixed(2)} × 10⁻⁷ s`;
    a.$('time-output').textContent = text;
    a.$('packet-time').setAttribute('aria-valuetext', text);
  }
  PlasmaLesson.start({
    translations: texts, running: s => !s.data.noCanvas, rate: () => 3,
    setup(a) {
      a.s.paused = true; a.s.data.linear = false; a.s.data.noCanvas = !a.ctx;
      a.$('packet-time').addEventListener('input', e => { a.s.time = Number(e.target.value); a.s.paused = true; a.render(); });
      a.$('linear-branch').addEventListener('change', e => { a.s.data.linear = e.target.checked; a.render(); });
      new ResizeObserver(() => chart(a)).observe(a.$('slope-chart'));
    },
    onStage(s, old) {
      if (s.stage === 0) { s.time = 0; s.paused = true; }
      if (s.stage !== 5) s.data.linear = false;
      if (s.stage === 2 && s.time === 0) s.time = 8;
      if (s.stage === 5 && old !== 5) { s.data.linear = true; s.time = 8; }
    },
    update(a) {
      const { s, text: t, $ } = a;
      $('slope-pane').hidden = s.stage < 4; $('slope-heading').textContent = t.slopeTitle;
      $('time-controls').hidden = s.stage < 2; $('time-label').textContent = t.timeLabel;
      $('comparison').hidden = s.stage !== 5; $('comparison-label').textContent = t.compare;
      $('linear-branch').checked = s.data.linear;
      $('packet-legend').hidden = s.stage < 1; $('phase-key').hidden = s.stage < 2;
      $('phase-key').textContent = t.phaseKey; $('group-key').textContent = s.stage >= 3 ? t.groupKey : t.envelopeKey;
      $('model-note').textContent = s.data.linear ? t.comparisonModel : t.model;
      const vg = M.groupSpeed(M.KC, s.data.linear);
      if (s.stage === 2) $('equation').innerHTML = `v<sub>ph</sub> = ω<sub>c</sub>/k<sub>c</sub> = ${speed(M.VP)}<small>${t.phaseNote}</small>`;
      if (s.stage === 3) $('equation').innerHTML = `v<sub>g</sub> = (dω/dk)<sub>c</sub> = ${speed(vg)}<small>${t.groupNote}</small>`;
      if (s.stage >= 4) $('equation').innerHTML = `${s.data.linear ? 'ω = Vk<small>' : '<small>'}<span class="speed-term phase-key">v<sub>ph</sub> = ${speed(M.VP)}</span><span class="speed-term group-key">v<sub>g</sub> = ${speed(vg)}</span></small>`;
      $('group-derivation').hidden = s.stage < 3; $('derivation-summary').textContent = t.derivationTitle;
      $('derivation-content').innerHTML = t.derivation;
      $('packet-details').hidden = s.stage < 1; $('packet-summary').textContent = t.detailsTitle;
      $('packet-description').innerHTML = t.details;
      if (s.stage === 0) { $('group-derivation').open = false; $('packet-details').open = false; }
      syncTime(a); chart(a);
    },
    draw(a) {
      const { s, text: t, ctx, line, label, dot } = a;
      if (s.time > M.TMAX * M.W0) s.time %= M.TMAX * M.W0;
      syncTime(a);
      const time = s.time / M.W0, modes = M.modes(s.data.linear);
      const left = 66, right = s.width - 18, width = right - left, mid = 170, scale = 90 / M.AMPLITUDE;
      const px = x => left + (x - M.XMIN) / (M.XMAX - M.XMIN) * width;
      label('δn / n₀ [1]', 24, 28, '#edf5f1', 26, 'left');
      for (const value of [-.18, 0, .18]) {
        line(left, mid - scale * value, right, mid - scale * value);
        label(value === 0 ? '0' : value.toFixed(2), left - 10, mid - scale * value, '#e0ebe6', 22, 'right');
      }
      const samples = Array.from({ length: 361 }, (_, i) => M.sample(M.XMIN + i / 360 * (M.XMAX - M.XMIN), time, modes));
      function trace(fn, color, dash = [], thick = 2.5) {
        ctx.beginPath(); ctx.strokeStyle = color; ctx.lineWidth = thick; ctx.setLineDash(dash);
        samples.forEach((v, i) => { const x = left + i / 360 * width, y = mid - scale * fn(v); if (i) ctx.lineTo(x, y); else ctx.moveTo(x, y); });
        ctx.stroke(); ctx.setLineDash([]);
      }
      if (s.stage >= 1) { trace(v => v.envelope, blue, [9, 6]); trace(v => -v.envelope, blue, [9, 6]); }
      trace(v => v.re, '#edf5f1');
      if (s.stage >= 3) {
        const x = M.peak(time, s.data.linear), y = mid - scale * M.sample(x, time, modes).envelope;
        line(px(x), 64, px(x), 274, blue, 1.5, [6, 5]);
        ctx.beginPath(); ctx.strokeStyle = blue; ctx.lineWidth = 3; ctx.arc(px(x), y, 10, 0, a.TAU); ctx.stroke();
      }
      if (s.stage >= 2) {
        const x = M.VP * time, y = mid - scale * M.sample(x, time, modes).re;
        line(px(x), 65, px(x), 274, gold, 1.5); dot(px(x), y, 5, gold);
      }
      label('−0.5', left, 292, '#e0ebe6', 22);
      if (s.width >= 500) label('0', px(0), 292, '#e0ebe6', 22);
      label('0.9', right, 292, '#e0ebe6', 22, 'right'); label('x [m]', right, 327, '#e0ebe6', 24, 'right');
      label(t.dotsTitle, 24, 368, '#b5efcf', 26, 'left');
      const columns = Math.max(64, Math.floor(width / 9)), radius = Math.min(3.5, width / columns * .30);
      // Solve each particle once, then reuse its x coordinate in the schematic rows.
      ctx.save(); ctx.beginPath(); ctx.rect(left, 400, width, 75); ctx.clip();
      for (let j = -2; j <= columns + 2; j++) {
        const q = M.XMIN + j / columns * (M.XMAX - M.XMIN), x = px(M.position(q, time, modes));
        for (let row = 0; row < 4; row++) dot(x, 412 + row * 17, radius, '#b5efcf');
      }
      ctx.restore();
    }
  });
})();
