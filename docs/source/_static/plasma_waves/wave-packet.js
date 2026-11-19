/* Lesson 08 is a slide deck: a new slide clears the previous explanation.
 * All wave physics stays in wave-packet-model.js. */
(() => {
  'use strict';
  const M = PlasmaPacketModel, $ = id => document.getElementById(id);
  const frac = (a, b) => '<span class="eq-frac"><span>' + a + '</span><span class="sr-only"> / </span><span class="eq-den">' + b + '</span></span>';
  const eq = text => '<p class="math">' + text + '</p>';
  const p = text => '<p>' + text + '</p>';
  const block = (zh, en, cueZh, cueEn) => ({ zh, en, cue: { zh: cueZh, en: cueEn } });
  const vp = frac('ω<sub>c</sub>', 'k<sub>c</sub>'), derivative = frac('dω', 'dk');
  const groupDerivative = '<span class="math-term">(' + derivative + ')<sub>c</sub></span>';
  // Each block is one deliberate reveal. Only this slide's blocks enter the DOM.
  const slides = [
    {
      id: 'packet', visual: 'packet',
      title: ['一群波，形成一个波包', 'Many waves form one packet'],
      lead: ['相近波数的分量叠加，让密度扰动集中在一段空间。', 'Nearby wavenumbers add up to a disturbance concentrated in space.'],
      blocks: [
        block(p('白线是相对密度扰动 <strong>δn/n₀</strong>。下方点阵显示同一密度的疏密变化。'), p('The white curve is the relative density perturbation <strong>δn/n₀</strong>. The electron spacing depicts the same density.'), '', ''),
        block(p('<span class="group-key">蓝色虚线：包络。</span>它勾勒哪里振荡强、哪里振荡弱。'), p('<span class="group-key">Blue dashes: the envelope.</span> It shows where the oscillations are strong or weak.'), '画出包络', 'Show the envelope')
      ]
    },
    {
      id: 'phase', visual: 'packet',
      title: ['跟住内部的一个波峰', 'Follow an inner crest'],
      lead: ['金点跟踪中心分量的同一相位；它不是某个电子。', 'The gold dot follows one phase of the central component, not an electron.'],
      blocks: [
        block(eq('k<sub>c</sub>x − ω<sub>c</sub>t = 0') + p('k<sub>c</sub> = 60 rad/m<br>ω<sub>c</sub> ≈ 1.166 × 10⁸ rad/s'), eq('k<sub>c</sub>x − ω<sub>c</sub>t = 0') + p('k<sub>c</sub> = 60 rad/m<br>ω<sub>c</sub> ≈ 1.166 × 10⁸ rad/s'), '', ''),
        block(eq('x = ' + vp + ' t') + eq('<span class="phase-key">v<sub>ph</sub> = ' + vp + '</span>'), eq('x = ' + vp + ' t') + eq('<span class="phase-key">v<sub>ph</sub> = ' + vp + '</span>'), '由相位求速度', 'Find the phase speed'),
        block(p('<span class="phase-key">v<sub>ph</sub> ≈ 1.944 × 10⁶ m/s。</span>播放或拖动时间，观察金点穿过包络。窄带时，它近似跟随一个内部波峰。'), p('<span class="phase-key">v<sub>ph</sub> ≈ 1.944 × 10⁶ m/s.</span> Play or scrub time: the dot approximately follows an inner crest through the narrow-band envelope.'), '观察它的移动', 'Watch it move')
      ]
    },
    {
      id: 'group', visual: 'packet',
      title: ['再跟住整个包络', 'Now follow the envelope'],
      lead: ['蓝圈定位包络最强处。先预测：它会与金点一起走吗？', 'The blue ring marks the envelope maximum. Predict: will it keep up with the gold dot?'],
      blocks: [
        block(p('播放或拖动时间，比较蓝圈和金点的位置。'), p('Play or scrub time and compare the two markers.'), '', ''),
        block(eq('<span class="group-key">v<sub>g</sub> = ' + groupDerivative + '</span>') + p('窄带、弱失真时，包络速度近似为 v<sub>g</sub>。本例约为 <strong>0.514 × 10⁶ m/s</strong>，比内部相位移动慢。'), eq('<span class="group-key">v<sub>g</sub> = ' + groupDerivative + '</span>') + p('For a narrow band with little distortion, the envelope speed is approximately v<sub>g</sub>. Here it is about <strong>0.514 × 10⁶ m/s</strong>, slower than the inner phase.'), '给这种速度命名', 'Name this speed')
      ]
    },
    {
      id: 'beats', visual: 'none',
      title: ['先用两个波看清拍包络', 'Start with a two-wave beat'],
      lead: ['把两个邻近、等幅的密度波相加，再用和差化积。', 'Add two nearby, equal-amplitude density waves, then use the sum-to-product identity.'],
      blocks: [
        block(eq('δn = A cos(k₁x − ω₁t) + A cos(k₂x − ω₂t)') + p('A [m⁻³]；x [m]；t [s]。定义差值 Δk = k₂ − k₁ [rad/m]、Δω = ω₂ − ω₁ [rad/s]。') + eq('k̄ = ' + frac('k₁ + k₂', '2') + '，　ω̄ = ' + frac('ω₁ + ω₂', '2')), eq('δn = A cos(k₁x − ω₁t) + A cos(k₂x − ω₂t)') + p('A [m⁻³]; x [m]; t [s]. Define Δk = k₂ − k₁ [rad/m] and Δω = ω₂ − ω₁ [rad/s].') + eq('k̄ = ' + frac('k₁ + k₂', '2') + ',　ω̄ = ' + frac('ω₁ + ω₂', '2')), '', ''),
        block(eq('δn = <span class="group-key">2A cos(' + frac('Δk x − Δω t', '2') + ')</span><wbr> · <span class="phase-key">cos(k̄x − ω̄t)</span>') + p('<span class="group-key">慢调制</span> × <span class="phase-key">内部快振荡</span>。两个分量产生周期性的拍；许多分量适当加权，才能得到局部波包。'), eq('δn = <span class="group-key">2A cos(' + frac('Δk x − Δω t', '2') + ')</span><wbr> · <span class="phase-key">cos(k̄x − ω̄t)</span>') + p('<span class="group-key">Slow modulation</span> × <span class="phase-key">fast inner oscillation</span>. Two components produce periodic beats; many weighted components can form a localized packet.'), '把相加改写为相乘', 'Rewrite the sum as a product')
      ]
    },
    {
      id: 'derivative', visual: 'none',
      title: ['为什么群速度是 dω/dk？', 'Why is group speed dω/dk?'],
      lead: ['沿着慢调制的同一相位走，让它的相位保持不变。', 'Follow a fixed phase of the slow modulation.'],
      blocks: [
        block(eq('Δk x − Δω t = 常数'), eq('Δk x − Δω t = constant'), '', ''),
        block(p('对时间求导；这两个给定分量的 Δk、Δω 都是常数：') + eq('Δk ' + frac('dx', 'dt') + ' − Δω = 0') + eq(frac('dx', 'dt') + ' = ' + frac('Δω', 'Δk') + '　[m/s]'), p('Differentiate in time. For these two fixed components, Δk and Δω are constants:') + eq('Δk ' + frac('dx', 'dt') + ' − Δω = 0') + eq(frac('dx', 'dt') + ' = ' + frac('Δω', 'Δk') + '　[m/s]'), '对时间求导', 'Differentiate in time'),
        block(p('两个波数一起趋近 k<sub>c</sub>，割线斜率变成切线斜率：') + eq('<span class="group-key">v<sub>g</sub> = lim<sub>Δk→0</sub> ' + frac('Δω', 'Δk') + ' = ' + groupDerivative + '　[m/s]</span>'), p('As both wavenumbers approach k<sub>c</sub>, the secant slope becomes the tangent slope:') + eq('<span class="group-key">v<sub>g</sub> = lim<sub>Δk→0</sub> ' + frac('Δω', 'Δk') + ' = ' + groupDerivative + '　[m/s]</span>'), '让两个波数趋近', 'Bring the wavenumbers together')
      ]
    },
    {
      id: 'slopes', visual: 'slopes',
      title: ['同一个点，两种斜率', 'One point, two slopes'],
      lead: ['回到 ω–k 图。在中心点 P 附近读出两种速度。', 'Return to the ω–k plot and read both speeds at the central point P.'],
      blocks: [
        block(p('横轴 k [rad/m]，纵轴 ω [rad/s]。<br>P = (k<sub>c</sub>, ω<sub>c</sub>)。'), p('Horizontal: k [rad/m]. Vertical: ω [rad/s].<br>P = (k<sub>c</sub>, ω<sub>c</sub>).'), '', ''),
        block(p('<span class="phase-key">从原点连到 P：读出相速度。</span>') + eq('v<sub>ph</sub> = ' + vp), p('<span class="phase-key">Join the origin to P: phase speed.</span>') + eq('v<sub>ph</sub> = ' + vp), '连到原点', 'Draw the origin ray'),
        block(p('<span class="group-key">在 P 点作切线：读出群速度。</span>') + eq('v<sub>g</sub> = ' + groupDerivative + ''), p('<span class="group-key">Draw the tangent at P: group speed.</span>') + eq('v<sub>g</sub> = ' + groupDerivative + ''), '在 P 点作切线', 'Draw the tangent at P')
      ]
    },
    {
      id: 'model', visual: 'none',
      title: ['算出本例的两种速度', 'Calculate the two speeds'],
      lead: ['沿用 07 的温电子流体模型，电子温度通过压强项体现。', 'Use the warm-electron fluid model from lesson 07; temperature enters through pressure.'],
      blocks: [
        block(eq('ω² = ω₀² + u²k²') + eq('ω₀ = 10⁸ rad/s，　u = 10⁶ m/s') + p('ω₀：k → 0 时的角频率；u：压强项的速度参数。背景均匀、无磁场、离子固定，忽略碰撞与 Landau 阻尼。'), eq('ω² = ω₀² + u²k²') + eq('ω₀ = 10⁸ rad/s,　u = 10⁶ m/s') + p('ω₀ is the k → 0 angular frequency; u is the pressure speed parameter. Uniform background, no magnetic field, fixed ions, no collisions or Landau damping.'), '', ''),
        block(p('对 k 求导，并在 k<sub>c</sub> = 60 rad/m 处取值：') + eq('2ω ' + derivative + ' = 2u²k') + eq('v<sub>g</sub> = ' + frac('u²k<sub>c</sub>', 'ω<sub>c</sub>') + ' ≈ 0.514 × 10⁶ m/s') + p('ω<sub>c</sub> ≈ 1.166 × 10⁸ rad/s；v<sub>ph</sub> = ω<sub>c</sub>/k<sub>c</sub> ≈ 1.944 × 10⁶ m/s。'), p('Differentiate with respect to k, then evaluate at k<sub>c</sub> = 60 rad/m:') + eq('2ω ' + derivative + ' = 2u²k') + eq('v<sub>g</sub> = ' + frac('u²k<sub>c</sub>', 'ω<sub>c</sub>') + ' ≈ 0.514 × 10⁶ m/s') + p('ω<sub>c</sub> ≈ 1.166 × 10⁸ rad/s; v<sub>ph</sub> = ω<sub>c</sub>/k<sub>c</sub> ≈ 1.944 × 10⁶ m/s.'), '代入模型求导', 'Differentiate the model')
      ]
    },
    {
      id: 'spectrum', visual: 'spectrum',
      title: ['选哪些分量来组成波包？', 'Choose the packet components'],
      lead: ['取中心附近的 31 个波数；离中心越远，幅值越小。', 'Take 31 wavenumbers near the center, with smaller amplitudes farther away.'],
      blocks: [
        block(eq('kⱼ = (42 + 1.2j) rad/m') + p('j = 0, …, 30；k<sub>c</sub> = 60 rad/m。每根谱线代表一个密度波分量。'), eq('kⱼ = (42 + 1.2j) rad/m') + p('j = 0, …, 30; k<sub>c</sub> = 60 rad/m. Each spectral line represents one density-wave component.'), '', ''),
        block(eq('wⱼ = exp[−' + frac('(kⱼ − k<sub>c</sub>)²', '2σₖ²') + ']') + eq(frac('Aⱼ', 'n₀') + ' = 0.18 ' + frac('wⱼ', '∑ₗ wₗ')) + p('σₖ = 6 rad/m；wⱼ 无量纲。n₀、Aⱼ [m⁻³]；分母对全部分量求和。'), eq('wⱼ = exp[−' + frac('(kⱼ − k<sub>c</sub>)²', '2σₖ²') + ']') + eq(frac('Aⱼ', 'n₀') + ' = 0.18 ' + frac('wⱼ', '∑ₗ wₗ')) + p('σₖ = 6 rad/m; wⱼ is dimensionless. n₀, Aⱼ [m⁻³]; the denominator sums all components.'), '给各分量分配幅值', 'Assign the amplitudes')
      ]
    },
    {
      id: 'complex', visual: 'none',
      title: ['从叠加式得到白线和包络', 'From the sum to the envelope'],
      lead: ['所有初相位为 0；每个分量按自己的 ωⱼ = ω(kⱼ) 演化。', 'All initial phases are zero; each component evolves with its own ωⱼ = ω(kⱼ).'],
      blocks: [
        block(eq(frac('δn(x,t)', 'n₀') + ' = ∑ⱼ ' + frac('Aⱼ', 'n₀') + ' cos(kⱼx − ωⱼt)') + p('x [m]，t [s]。在 x = 0、t = 0，各分量同相增强；离开中心后相互抵消增多。'), eq(frac('δn(x,t)', 'n₀') + ' = ∑ⱼ ' + frac('Aⱼ', 'n₀') + ' cos(kⱼx − ωⱼt)') + p('x [m], t [s]. At x = 0, t = 0 the components add in phase; away from the center more cancellation occurs.'), '', ''),
        block(p('把同一组分量写成复数和 Z：') + eq('Z(x,t) = ∑ⱼ ' + frac('Aⱼ', 'n₀') + ' exp[i(kⱼx − ωⱼt)]'), p('Write the same components as a complex sum Z:') + eq('Z(x,t) = ∑ⱼ ' + frac('Aⱼ', 'n₀') + ' exp[i(kⱼx − ωⱼt)]'), '写成复数叠加', 'Write the complex sum'),
        block(eq('<span class="white-key">δn/n₀ = Re Z</span>，　<span class="group-key">B(x,t) = |Z(x,t)|</span>') + p('白线取实部，蓝色包络取模。Z、B 均无量纲；蓝圈定位实际计算的 B 的最大值。'), eq('<span class="white-key">δn/n₀ = Re Z</span>,　<span class="group-key">B(x,t) = |Z(x,t)|</span>') + p('The white curve is the real part; the blue envelope is the modulus. Z and B are dimensionless. The ring marks the computed maximum of B.'), '分别取实部和模', 'Take the real part and modulus')
      ]
    },
    {
      id: 'approximation', visual: 'none',
      title: ['近似发生在这一步', 'Here is the approximation'],
      lead: ['分量集中在 k꜀ 附近，才可以用局部切线近似色散曲线。', 'For components concentrated near k꜀, approximate the dispersion curve by its local tangent.'],
      blocks: [
        block(eq('ω(k) ≈ ω<sub>c</sub> + v<sub>g</sub>(k − k<sub>c</sub>)') + p('这是在 k<sub>c</sub> 附近的一阶展开。动画实际使用完整的 ω(k)，没有采用这个近似来强制平移包络。'), eq('ω(k) ≈ ω<sub>c</sub> + v<sub>g</sub>(k − k<sub>c</sub>)') + p('This is a first-order expansion near k<sub>c</sub>. The animation uses the full ω(k); it does not force the envelope to translate rigidly.'), '', ''),
        block(p('代入每个分量的相位，把中心相位分离出来：') + eq('kⱼx − ωⱼt ≈ <span class="phase-key">(k<sub>c</sub>x − ω<sub>c</sub>t)</span><wbr> + <span class="group-key">(kⱼ − k<sub>c</sub>)(x − v<sub>g</sub>t)</span>') + p('下一页把所有分量相加，看这个拆分怎样给出移动的包络。'), p('Substitute into each component phase and separate the central phase:') + eq('kⱼx − ωⱼt ≈ <span class="phase-key">(k<sub>c</sub>x − ω<sub>c</sub>t)</span><wbr> + <span class="group-key">(kⱼ − k<sub>c</sub>)(x − v<sub>g</sub>t)</span>') + p('Next, add all components to see how this split gives a moving envelope.'), '代入并拆开相位', 'Substitute and split the phase')
      ]
    },
    {
      id: 'envelope', visual: 'none',
      title: ['包络为什么以群速度移动？', 'Why does the envelope move at group speed?'],
      lead: ['把共同的中心相位提出求和号，剩余部分记作 F。', 'Factor the common central phase out of the sum, and call the remaining part F.'],
      blocks: [
        block(eq('Z(x,t) ≈ <span class="phase-key">exp[i(k<sub>c</sub>x − ω<sub>c</sub>t)]</span><wbr> · <span class="group-key">F(x − v<sub>g</sub>t)</span>') + eq('F(ξ) = ∑ⱼ ' + frac('Aⱼ', 'n₀') + ' exp[i(kⱼ − k<sub>c</sub>)ξ]') + p('ξ = x − v<sub>g</sub>t [m]；F 无量纲。'), eq('Z(x,t) ≈ <span class="phase-key">exp[i(k<sub>c</sub>x − ω<sub>c</sub>t)]</span><wbr> · <span class="group-key">F(x − v<sub>g</sub>t)</span>') + eq('F(ξ) = ∑ⱼ ' + frac('Aⱼ', 'n₀') + ' exp[i(kⱼ − k<sub>c</sub>)ξ]') + p('ξ = x − v<sub>g</sub>t [m]; F is dimensionless.'), '', ''),
        block(p('中心相位因子的模为 1，因此：') + eq('<span class="group-key">B(x,t) ≈ |F(x − v<sub>g</sub>t)|</span>') + p('保持 x − v<sub>g</sub>t 不变，就是以 v<sub>g</sub> 跟随包络上的同一位置。'), p('The central phase factor has modulus 1, so:') + eq('<span class="group-key">B(x,t) ≈ |F(x − v<sub>g</sub>t)|</span>') + p('Keeping x − v<sub>g</sub>t fixed follows the same envelope position at speed v<sub>g</sub>.'), '取模，读出包络速度', 'Take the modulus and read the speed'),
        block(p('<strong>适用条件：窄带、弱失真。</strong>频带更宽或传播更久时，高阶项可能导致展宽，不能把包络一直当作刚性形状。'), p('<strong>Condition: a narrow band with little distortion.</strong> A wider band or longer propagation can make higher-order terms important and cause spreading.'), '指出近似的边界', 'State the limit of the approximation')
      ]
    },
    {
      id: 'nondispersive', visual: 'packet',
      title: ['如果所有分量一样快呢？', 'What if all components travel equally fast?'],
      lead: ['色散是指不同频率的波分量具有不同的相速度。', 'Dispersion means that components of different frequencies have different phase velocities.'],
      blocks: [
        block(eq('ω = Vk') + p('无色散对照：各分量的相速度都等于 V。采用过原点的直线；V = 1.944 × 10⁶ m/s。'), eq('ω = Vk') + p('All components have phase speed V = 1.944 × 10⁶ m/s. This line passes through the origin.'), '', ''),
        block(p('保持波数、幅值和初相位不变，播放动画。金点与蓝圈一起移动，波包保持形状平移。'), p('Play: the markers move together and the packet keeps its shape. Wavenumbers, amplitudes and initial phases are unchanged.'), '观察两种速度是否相同', 'Compare the two motions'),
        block(eq('v<sub>ph</sub> = v<sub>g</sub> = V') + p('可切回原模型，在同一时刻比较。这是数学对照，不是新增的等离子体色散分支。'), eq('v<sub>ph</sub> = v<sub>g</sub> = V') + p('Switch back at the same time to compare. This is a mathematical comparison, not another plasma branch.'), '解释为什么同步', 'Explain why they stay together')
      ]
    },
    {
      id: 'animation', visual: 'none',
      title: ['动画中的点，代表什么？', 'What do the animated dots mean?'],
      lead: ['点的疏密对应总密度；两种波速都不是单个电子的速度。', 'Dot spacing represents total density. Neither wave speed is an individual electron velocity.'],
      blocks: [
        block(p('点阵使用守恒的运动学映射。它没有求解粒子受力，也没有绘制随机热运动。') + eq('n = n₀ + δn，　' + frac('|δn|', 'n₀') + ' ≤ 0.18') + p('全部幅值之和为 0.18 n₀，因此 n ≥ 0.82 n₀，密度始终为正。n₀、δn、n 的单位为 m⁻³。'), p('The dots use a conservative kinematic map. Particle forces and random thermal motion are not simulated.') + eq('n = n₀ + δn,　' + frac('|δn|', 'n₀') + ' ≤ 0.18') + p('The amplitudes sum to 0.18 n₀, so n ≥ 0.82 n₀ and density stays positive. n₀, δn and n are in m⁻³.'), '', ''),
        block(p('每播放 1 s，对应物理时间 3 × 10⁻⁸ s。动画循环区间为：') + eq('0 ≤ t ≤ 2 × 10⁻⁷ s') + p('离散谱的空间重复间距约为 5.24 m；当前只显示 −0.5 m 至 0.9 m，窗口内是一个波包。'), p('Each playback second represents 3 × 10⁻⁸ s of physical time. The animation loops over:') + eq('0 ≤ t ≤ 2 × 10⁻⁷ s') + p('The discrete spectrum repeats in space about every 5.24 m. The window from −0.5 m to 0.9 m shows one packet.'), '说明时间和观察窗口', 'Read the time and viewing window')
      ]
    },
    {
      id: 'summary', visual: 'none',
      title: ['最后，用两种斜率判断', 'Finish with the two slopes'],
      lead: ['若某点的切线比原点连线更陡，哪一种速度更大？', 'If the tangent is steeper than the origin ray, which speed is greater?'],
      blocks: [
        block(eq('<span class="phase-key">v<sub>ph</sub> = ' + vp + '</span>，　<span class="group-key">v<sub>g</sub> = ' + groupDerivative + '</span>') + p('先用图上的斜率解释，再看答案。'), eq('<span class="phase-key">v<sub>ph</sub> = ' + vp + '</span>,　<span class="group-key">v<sub>g</sub> = ' + groupDerivative + '</span>') + p('Explain using the slopes before revealing the answer.'), '', ''),
        block(p('<strong>群速度更大。</strong>本例 v<sub>g</sub> &lt; v<sub>ph</sub> 只是当前色散关系的结果，并非普遍规律。') + p('相速度跟踪相位；群速度对应窄带包络。不能把群速度无条件等同于能量或信息速度。') + p('推导参考：<a href="https://bpb-us-e1.wpmucdn.com/sites.harvard.edu/dist/0/550/files/2023/11/waves_dispersion.pdf" target="_blank" rel="noopener">David Morin · Dispersion, §6.3</a><br>模型参考：<a href="https://silas.psfc.mit.edu/introplasma/master.pdf" target="_blank" rel="noopener">MIT · Introduction to Plasma Physics</a>'), p('<strong>The group speed is greater.</strong> The result v<sub>g</sub> &lt; v<sub>ph</sub> in our example is specific to its dispersion relation, not universal.') + p('Phase speed follows phase; group speed describes a narrow-band envelope. Group speed is not unconditionally the energy or information speed.') + p('Derivation: <a href="https://bpb-us-e1.wpmucdn.com/sites.harvard.edu/dist/0/550/files/2023/11/waves_dispersion.pdf" target="_blank" rel="noopener">David Morin · Dispersion, §6.3</a><br>Model: <a href="https://silas.psfc.mit.edu/introplasma/master.pdf" target="_blank" rel="noopener">MIT · Introduction to Plasma Physics</a>'), '查看答案与理由', 'Reveal the answer and reasoning')
      ]
    }
  ];

  const texts = {
    zh: { title: '波包、相速度与群速度', chapter: '08 · 波包、相速度与群速度', play: '播放动画', pause: '暂停动画',
      next: '下一步', page: '下一页', replay: '从头回顾', back: '上一步', prev: '上一页', restart: '本页起始', restartLesson: '本课起始', slide: '幻灯片', step: '本页',
      keyboard: 'P 播放 · F 全屏', time: '观察时间 t', compare: '无色散对照：ω = Vk',
      phase: '金点：相位', group: '蓝圈：包络', envelope: '蓝色虚线：包络', dots: '电子密度点阵',
      model: '温电子流体示例；离子固定、无磁场、忽略阻尼。', slowed: '时间减速并循环；点阵表示密度。',
      mathModel: '数学对照 ω = Vk；相同的波数、幅值和初相位。', noCanvas: '图像无法显示；可继续阅读公式与说明。白线表示密度扰动，蓝色包络表示振荡强弱，金点跟踪相位。',
      fullError: '当前预览不允许全屏，请在独立浏览器中打开。' },
    en: { title: 'Wave packets, phase and group velocities', chapter: '08 · Wave packets, phase and group velocities', play: 'Play', pause: 'Pause',
      next: 'Next step', page: 'Next slide', replay: 'Start again', back: 'Back a step', prev: 'Previous slide', restart: 'Restart slide', restartLesson: 'Restart lesson', slide: 'Slide', step: 'Build',
      keyboard: 'P play · F fullscreen', time: 'Observe time t', compare: 'No-dispersion comparison: ω = Vk',
      phase: 'Gold dot: phase', group: 'Blue ring: envelope', envelope: 'Blue dashes: envelope', dots: 'Electron density dots',
      model: 'Warm-electron fluid example; fixed ions, no field or damping.', slowed: 'Time is slowed and looped; dots represent density.',
      mathModel: 'Mathematical comparison ω = Vk; same wavenumbers, amplitudes and initial phases.', noCanvas: 'The figure is unavailable. Continue with the equations and explanation. White denotes the density perturbation, blue the envelope, and gold the central phase.',
      fullError: 'Fullscreen is unavailable here. Open a separate browser tab.' }
  };
  const canvas = $('plasma'), ctx = canvas.getContext('2d');
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  const s = { slide: 0, build: 0, time: 0, paused: true, linear: false, width: 0, height: 0 };
  let lang = 'zh', lastTime = null, toastTimer;
  const current = () => slides[s.slide], text = () => texts[lang];
  const translated = values => values[lang === 'en' ? 1 : 0];
  function readPosition() {
    const match = location.hash.match(/^#slide-(\d+)(?:-step-(\d+))?$/);
    s.slide = match ? Math.max(0, Math.min(slides.length - 1, Number(match[1]) - 1)) : 0;
    s.build = match ? Math.max(0, Math.min(current().blocks.length - 1, Number(match[2] || 1) - 1)) : 0;
    resetScene();
  }
  function resetScene() {
    s.paused = true; s.linear = current().id === 'nondispersive';
    s.time = ['phase', 'group', 'nondispersive'].includes(current().id) ? 8 : 0;
    lastTime = null;
  }
  function writePosition() {
    try {
      const url = new URL(location.href); url.searchParams.set('lang', lang);
      url.hash = 'slide-' + (s.slide + 1) + '-step-' + (s.build + 1);
      history.replaceState(null, '', url);
    } catch (_) { /* Optional in restricted file previews. */ }
  }
  function packetOptions() {
    const id = current().id;
    return { envelope: id !== 'packet' || s.build >= 1,
      phase: ['phase', 'group', 'nondispersive'].includes(id),
      group: ['group', 'nondispersive'].includes(id) };
  }
  function syncTime() {
    const value = (s.time / 10).toFixed(2) + ' × 10⁻⁷ s';
    $('packet-time').value = String(s.time); $('time-output').textContent = value;
    $('packet-time').setAttribute('aria-valuetext', value);
  }
  function canPlay() {
    return !!ctx && current().visual === 'packet' && (current().id !== 'nondispersive' || s.build >= 1);
  }
  function motion() {
    $('motion').hidden = !canPlay();
    $('motion').textContent = s.paused ? text().play : text().pause;
    $('motion').setAttribute('aria-pressed', String(s.paused));
  }
  function render(reason = 'state') {
    const slide = current(), t = text(), options = packetOptions();
    $('lesson').dataset.slide = slide.id; $('lesson').dataset.build = String(s.build);
    $('chapter').textContent = t.chapter;
    document.documentElement.lang = lang === 'zh' ? 'zh-CN' : 'en';
    document.title = translated(slide.title) + ' · ' + t.title + ' | AlgoPlasma';
    $('title').textContent = translated(slide.title);
    $('narration').textContent = translated(slide.lead);
    $('slide-label').textContent = t.chapter;
    // Replacing the content removes all previous-slide prose and open controls.
    if (['page', 'language', 'initial'].includes(reason)) {
      $('slide-content').replaceChildren(...slide.blocks.map((b, i) => {
        const section = document.createElement('section');
        section.className = 'build-block'; section.dataset.build = String(i);
        section.innerHTML = b[lang]; section.hidden = i > s.build; return section;
      }));
    }
    $('slide-content').querySelectorAll('.build-block').forEach((node, i) => {
      node.hidden = i > s.build;
      node.classList.remove('just-revealed');
      if (reason === 'reveal' && i === s.build) {
        void node.offsetWidth; node.classList.add('just-revealed');
      }
    });
    $('slide-layout').dataset.visual = slide.visual;
    $('visual-pane').hidden = slide.visual === 'none';
    $('packet-figure').hidden = slide.visual !== 'packet';
    $('chart-figure').hidden = !['slopes', 'spectrum'].includes(slide.visual);
    $('canvas-fallback').hidden = !!ctx; $('canvas-fallback').textContent = t.noCanvas;
    canvas.hidden = !ctx;
    $('packet-legend').hidden = slide.visual !== 'packet' || !options.envelope;
    $('phase-key').hidden = !options.phase; $('phase-key').textContent = t.phase;
    $('group-key').hidden = !options.envelope; $('group-key').textContent = options.group ? t.group : t.envelope;
    $('time-controls').hidden = !canPlay() || slide.id === 'packet';
    $('time-label').textContent = t.time;
    $('comparison').hidden = slide.id !== 'nondispersive' || s.build < 2;
    $('comparison-label').textContent = t.compare; $('linear-branch').checked = s.linear;
    $('model-note').textContent = s.linear ? (lang === 'zh' ? '数学对照；时间减速并循环。' : 'Mathematical comparison; slowed, looped time.') : (slide.id === 'packet' ? t.model : t.slowed);
    $('model-note').hidden = slide.visual !== 'packet';
    $('chart-note').textContent = slide.visual === 'slopes'
      ? 'ω(k) = √(ω₀² + u²k²) · ω₀ = 10⁸ rad/s · u = 10⁶ m/s'
      : (lang === 'zh' ? '纵轴 Aⱼ/n₀ 无量纲；初相位均为 0 rad。' : 'Vertical Aⱼ/n₀ is dimensionless; all initial phases are 0 rad.');
    const finalBuild = s.build === slide.blocks.length - 1, finalSlide = s.slide === slides.length - 1;
    $('advance-kind').textContent = finalBuild ? (finalSlide ? t.replay : t.page) : t.next;
    $('advance-text').textContent = finalBuild ? (finalSlide ? t.title : translated(slides[s.slide + 1].title)) : slide.blocks[s.build + 1].cue[lang];
    $('advance').dataset.action = finalBuild ? (finalSlide ? 'replay' : 'page') : 'reveal';
    $('back').hidden = s.slide === 0 && s.build === 0;
    $('back').textContent = s.build > 0 ? t.back : t.prev;
    $('restart-slide').textContent = t.restart;
    $('restart-lesson').textContent = t.restartLesson;
    $('stage-count').textContent = t.slide + ' ' + (s.slide + 1) + ' / ' + slides.length;
    $('build-count').textContent = t.step + ' ' + (s.build + 1) + ' / ' + slide.blocks.length;
    $('progress').replaceChildren(...slide.blocks.map((_, i) => {
      const mark = document.createElement('i'); mark.className = i <= s.build ? 'filled' : ''; return mark;
    }));
    $('keyboard-note').textContent = t.keyboard;
    $('language-switch').setAttribute('aria-label', lang === 'zh' ? '选择语言' : 'Choose language');
    document.querySelectorAll('[data-language]').forEach(b => b.setAttribute('aria-pressed', String(b.dataset.language === lang)));
    window.PlasmaNavigation?.setLanguage(lang);
    // Distinguish course navigation from the deck's slide navigation.
    $('previous-lesson').textContent = lang === 'zh' ? '上一课' : 'Prev lesson';
    $('next-lesson').textContent = lang === 'zh' ? '下一课' : 'Next lesson';
    $('lesson-index').textContent = lang === 'zh' ? '课程目录' : 'Contents';
    $('return-link').setAttribute('aria-label', lang === 'zh' ? '返回等离子体波课堂' : 'Return to the plasma waves course');
    $('status').textContent = $('stage-count').textContent + ', ' + $('build-count').textContent + '. ' + translated(slide.title);
    canvas.setAttribute('aria-label', translated(slide.lead) + ' δn/n₀ [1], x [m]. ' + (options.envelope ? t.envelope + '. ' : '') + (options.phase ? t.phase + '. ' : '') + (options.group ? t.group : ''));
    canvas.textContent = canvas.getAttribute('aria-label');
    $('status').textContent += '. ' + $('slide-content').children[s.build].textContent;
    if (reason === 'page') {
      $('slide-main').classList.remove('slide-enter'); void $('slide-main').offsetWidth;
      $('slide-main').classList.add('slide-enter');
      window.scrollTo({ top: 0, behavior: 'instant' });
      $('title').focus({ preventScroll: true });
    }
    writePosition(); syncTime(); motion(); fit(); drawChart();
    if (reason === 'reveal') {
      const fresh = $('slide-content').children[s.build];
      const limit = innerHeight - document.querySelector('.controls').offsetHeight - 16;
      const rect = fresh.getBoundingClientRect();
      if (rect.bottom > limit) fresh.scrollIntoView({ block: rect.height > limit - 24 ? 'start' : 'center', behavior: 'instant' });
    }
  }
  function next() {
    if (s.build < current().blocks.length - 1) { s.build++; render('reveal'); }
    else { s.slide = (s.slide + 1) % slides.length; s.build = 0; resetScene(); render('page'); }
  }
  function back() {
    if (s.build > 0) { s.build--; render('back'); }
    else if (s.slide > 0) { s.slide--; s.build = current().blocks.length - 1; resetScene(); render('page'); }
  }
  function restartLesson() {
    s.slide = 0; restartSlide();
  }
  function restartSlide() {
    s.build = 0; resetScene(); render('page');
  }
  function toggle() { if (canPlay()) { s.paused = !s.paused; lastTime = null; motion(); } }
  function setLanguage(value) {
    lang = value === 'en' ? 'en' : 'zh';
    try { localStorage.setItem('ap-doc-language', lang); } catch (_) { /* Optional preference. */ }
    render('language');
  }
  async function fullscreen() {
    try { if (document.fullscreenElement) await document.exitFullscreen(); else await document.documentElement.requestFullscreen(); }
    catch (_) {
      $('toast').textContent = text().fullError; $('toast').hidden = false;
      clearTimeout(toastTimer); toastTimer = setTimeout(() => { $('toast').hidden = true; }, 4000);
    }
  }
  const gold = '#f4c583', blue = '#b4cefa', mint = '#b5efcf', white = '#eef4f0';
  function line(x1, y1, x2, y2, color = '#30413f', width = 1, dash = []) {
    ctx.beginPath(); ctx.strokeStyle = color; ctx.lineWidth = width; ctx.setLineDash(dash);
    ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke(); ctx.setLineDash([]);
  }
  function label(value, x, y, color = white, size = 23, align = 'center') {
    PlasmaText.label(ctx, value, x, y, color, size, align);
  }
  function dot(x, y, radius, color = mint) {
    ctx.beginPath(); ctx.fillStyle = color; ctx.arc(x, y, radius, 0, 2 * Math.PI); ctx.fill();
  }
  function fit() {
    if (!ctx || current().visual !== 'packet') return;
    const rect = canvas.getBoundingClientRect(), dpr = Math.min(devicePixelRatio || 1, 2);
    if (!rect.width || !rect.height) return;
    s.width = rect.width; s.height = rect.height;
    canvas.width = Math.round(rect.width * dpr); canvas.height = Math.round(rect.height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0); draw();
  }
  function draw() {
    if (!ctx || current().visual !== 'packet' || !s.width) return;
    ctx.clearRect(0, 0, s.width, s.height); ctx.save(); ctx.scale(1, s.height / 350);
    const options = packetOptions(), time = s.time / M.W0, modes = M.modes(s.linear);
    const left = 66, right = s.width - 20, width = right - left, mid = 115, scale = 60 / M.AMPLITUDE;
    const px = x => left + (x - M.XMIN) / (M.XMAX - M.XMIN) * width;
    label('δn / n₀ [1]', 8, 28, white, 26, 'left');
    for (const value of [-.18, 0, .18]) {
      line(left, mid - scale * value, right, mid - scale * value);
      label(value === 0 ? '0' : value.toFixed(2), left - 10, mid - scale * value, white, 22, 'right');
    }
    const samples = Array.from({ length: 361 }, (_, i) => M.sample(M.XMIN + i / 360 * (M.XMAX - M.XMIN), time, modes));
    function trace(fn, color, dash = []) {
      ctx.beginPath(); ctx.strokeStyle = color; ctx.lineWidth = 2.5; ctx.setLineDash(dash);
      samples.forEach((v, i) => { const x = left + i / 360 * width, y = mid - scale * fn(v); if (i) ctx.lineTo(x, y); else ctx.moveTo(x, y); });
      ctx.stroke(); ctx.setLineDash([]);
    }
    if (options.envelope) { trace(v => v.envelope, blue, [9, 6]); trace(v => -v.envelope, blue, [9, 6]); }
    trace(v => v.re, white);
    if (options.group) {
      const x = M.peak(time, s.linear), y = mid - scale * M.sample(x, time, modes).envelope;
      line(px(x), 64, px(x), 193, blue, 1.5, [6, 5]);
      ctx.beginPath(); ctx.strokeStyle = blue; ctx.lineWidth = 3; ctx.arc(px(x), y, 10, 0, 2 * Math.PI); ctx.stroke();
    }
    if (options.phase) {
      const x = M.VP * time, y = mid - scale * M.sample(x, time, modes).re;
      line(px(x), 65, px(x), 193, gold, 1.5); dot(px(x), y, 5, gold);
    }
    label('−0.5', left, 211, white, 22);
    if (s.width >= 500) label('0', px(0), 211, white, 22);
    label('0.9', right, 211, white, 22, 'right'); label('x [m]', right, 247, white, 24, 'right');
    label(text().dots, 8, 280, mint, 26, 'left');
    const columns = Math.max(64, Math.floor(width / 9)), radius = Math.min(3.5, width / columns * .30);
    ctx.save(); ctx.beginPath(); ctx.rect(left, 298, width, 50); ctx.clip();
    for (let j = -2; j <= columns + 2; j++) {
      const q = M.XMIN + j / columns * (M.XMAX - M.XMIN), x = px(M.position(q, time, modes));
      for (let row = 0; row < 4; row++) dot(x, 305 + row * 13, radius, mint);
    }
    ctx.restore(); ctx.restore();
  }
  function drawChart() {
    const visual = current().visual;
    if (!['slopes', 'spectrum'].includes(visual)) return;
    const svg = $('lesson-chart'), w = svg.clientWidth, h = svg.clientHeight;
    if (!w || !h) return;
    const left = w < 400 ? 64 : 82, right = w - 22, top = 58, bottom = h - 74;
    const add = (tag, attrs, value) => {
      const node = document.createElementNS('http://www.w3.org/2000/svg', tag);
      for (const [key, val] of Object.entries(attrs)) node.setAttribute(key, String(val));
      if (value !== undefined) node.textContent = value;
      svg.append(node); return node;
    };
    const ln = (x1, y1, x2, y2, cls) => add('line', { x1, y1, x2, y2, class: cls });
    const txt = (value, x, y, anchor = 'middle') => add('text', { x, y, 'text-anchor': anchor }, value);
    svg.setAttribute('viewBox', '0 0 ' + w + ' ' + h); svg.replaceChildren();
    ln(left, bottom, right + 6, bottom, 'packet-axis'); ln(left, bottom, left, top - 8, 'packet-axis');
    txt('k [rad/m]', right, h - 8, 'end');
    if (visual === 'slopes') {
      const x = k => left + k / 100 * (right - left), y = v => bottom - v / 2.1e8 * (bottom - top);
      txt('ω [rad/s]', left, 27, 'start');
      for (const k of [0, 60, 100]) {
        ln(x(k), bottom, x(k), bottom + 7, 'packet-axis');
        txt(k, x(k), bottom + 32, k === 100 ? 'end' : 'middle');
      }
      ln(left, y(1e8), right, y(1e8), 'packet-guide'); txt('10⁸', left - 12, y(1e8) + 8, 'end');
      add('polyline', { points: Array.from({ length: 101 }, (_, k) => x(k) + ',' + y(M.frequency(k))).join(' '), class: 'packet-branch' });
      if (s.build >= 1) ln(left, bottom, x(M.KC), y(M.WC), 'packet-ray');
      if (s.build >= 2) ln(x(0), y(M.WC - M.VG * M.KC), x(100), y(M.WC + M.VG * (100 - M.KC)), 'packet-tangent');
      add('circle', { cx: x(M.KC), cy: y(M.WC), r: 7, fill: white });
      txt('P', x(M.KC) + 14, y(M.WC) - 18, 'start');
      svg.setAttribute('aria-label', lang === 'zh' ? 'ω–k 色散图。金色原点连线给相速度，蓝色虚线切线给群速度。' : 'ω–k dispersion plot. Gold origin ray: phase speed. Blue dashed tangent: group speed.');
    } else {
      const x = k => left + (k - 40) / 40 * (right - left), y = v => bottom - v / .016 * (bottom - top);
      txt('Aⱼ/n₀ [1]', left, 27, 'start');
      for (const k of [42, 60, 78]) {
        ln(x(k), bottom, x(k), bottom + 7, 'packet-axis'); txt(k, x(k), bottom + 32);
      }
      txt('0', left - 10, bottom + 7, 'end'); txt('0.01', left - 10, y(.01) + 7, 'end');
      ln(left, y(.01), right, y(.01), 'packet-guide');
      for (const mode of M.modes(false)) {
        ln(x(mode.k), bottom, x(mode.k), y(mode.a), 'spectrum-line');
        add('circle', { cx: x(mode.k), cy: y(mode.a), r: 3, fill: mint });
      }
      svg.setAttribute('aria-label', lang === 'zh' ? '31个分量的幅值谱，横轴k为rad/m，纵轴Aⱼ/n₀无量纲。中心60 rad/m，宽度6 rad/m。' : 'Amplitude spectrum of 31 components. k in rad/m; Aⱼ/n₀ dimensionless. Center 60 rad/m, width 6 rad/m.');
    }
  }
  function frame(now) {
    const dt = lastTime === null ? 0 : Math.min((now - lastTime) / 1000, .05); lastTime = now;
    if (!document.hidden && !s.paused && canPlay()) {
      s.time = (s.time + dt * 3) % (M.TMAX * M.W0); syncTime(); draw();
    }
    requestAnimationFrame(frame);
  }
  $('advance').addEventListener('click', next); $('back').addEventListener('click', back);
  $('restart-slide').addEventListener('click', restartSlide);
  $('restart-lesson').addEventListener('click', restartLesson);
  $('motion').addEventListener('click', toggle);
  $('packet-time').addEventListener('input', e => { s.time = Number(e.target.value); s.paused = true; syncTime(); motion(); draw(); });
  $('linear-branch').addEventListener('change', e => { s.linear = e.target.checked; render(); });
  document.querySelectorAll('[data-language]').forEach(b => b.addEventListener('click', () => setLanguage(b.dataset.language)));
  document.addEventListener('keydown', e => {
    if (e.altKey || e.ctrlKey || e.metaKey || e.shiftKey || e.repeat || e.target.closest('input,textarea,select,[contenteditable]')) return;
    if (e.key === ' ' && e.target.closest('button,a')) return;
    // Navigation is button-only; native Enter/Space on focused buttons still works.
    if (e.key.toLowerCase() === 'p') { e.preventDefault(); toggle(); }
    else if (e.key.toLowerCase() === 'f') { e.preventDefault(); fullscreen(); }
  });
  reduced.addEventListener('change', e => { if (e.matches) { s.paused = true; motion(); } });
  document.addEventListener('visibilitychange', () => { lastTime = null; });
  window.addEventListener('hashchange', () => { readPosition(); render('page'); });
  new ResizeObserver(fit).observe(canvas); new ResizeObserver(drawChart).observe($('lesson-chart'));
  let initial = new URLSearchParams(location.search).get('lang');
  if (!['zh', 'en'].includes(initial)) { try { initial = localStorage.getItem('ap-doc-language'); } catch (_) { /* Optional preference. */ } }
  lang = initial === 'en' ? 'en' : 'zh'; readPosition(); render('initial'); requestAnimationFrame(frame);
})();
