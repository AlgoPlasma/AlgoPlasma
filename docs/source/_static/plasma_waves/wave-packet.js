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
  // Each block is one deliberate step; sequence slides show one working panel.
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
      id: 'beats', visual: 'none', sequence: true,
      title: ['先用两个波看清拍包络', 'Start with a two-wave beat'],
      lead: ['把两个邻近、等幅的密度波相加。下面逐步推导和差化积。', 'Add two nearby, equal-amplitude density waves. Derive the sum-to-product identity step by step.'],
      blocks: [
        block(eq('δn = A cos(k₁x − ω₁t) + A cos(k₂x − ω₂t)') + p('A [m⁻³]；x [m]；t [s]。定义差值 Δk = k₂ − k₁ [rad/m]、Δω = ω₂ − ω₁ [rad/s]。') + eq('k̄ = ' + frac('k₁ + k₂', '2') + '，　ω̄ = ' + frac('ω₁ + ω₂', '2')), eq('δn = A cos(k₁x − ω₁t) + A cos(k₂x − ω₂t)') + p('A [m⁻³]; x [m]; t [s]. Define Δk = k₂ − k₁ [rad/m] and Δω = ω₂ − ω₁ [rad/s].') + eq('k̄ = ' + frac('k₁ + k₂', '2') + ',　ω̄ = ' + frac('ω₁ + ω₂', '2')), '', ''),
        block(p('先把两项的相位简写成 φ₁、φ₂ [rad]：') + eq('φ₁ = k₁x − ω₁t，　φ₂ = k₂x − ω₂t') + p('用平均相位 Φ 和半个相位差 ψ 重新表示它们：') + eq('Φ = ' + frac('φ₁ + φ₂', '2') + '，　ψ = ' + frac('φ₂ − φ₁', '2')) + eq('φ₁ = Φ − ψ，　φ₂ = Φ + ψ') + eq(frac('δn', 'A') + ' = cos(Φ − ψ) + cos(Φ + ψ)'), p('Abbreviate the phases as φ₁ and φ₂ [rad]:') + eq('φ₁ = k₁x − ω₁t,　φ₂ = k₂x − ω₂t') + p('Rewrite them using the mean phase Φ and half-difference ψ:') + eq('Φ = ' + frac('φ₁ + φ₂', '2') + ',　ψ = ' + frac('φ₂ − φ₁', '2')) + eq('φ₁ = Φ − ψ,　φ₂ = Φ + ψ') + eq(frac('δn', 'A') + ' = cos(Φ − ψ) + cos(Φ + ψ)'), '把相位写成和与差', 'Rewrite the phases as sum and difference'),
        block(p('分别使用余弦差角公式与和角公式：') + eq('cos(Φ − ψ) = cosΦ cosψ <span class="phase-key">+ sinΦ sinψ</span>') + eq('cos(Φ + ψ) = cosΦ cosψ <span class="phase-key">− sinΦ sinψ</span>') + p('两式相加，金色的正弦乘积项恰好抵消：') + eq('cosφ₁ + cosφ₂ = 2 cosΦ cosψ') + eq('δn = 2A cosψ cosΦ'), p('Use the cosine difference and sum formulas separately:') + eq('cos(Φ − ψ) = cosΦ cosψ <span class="phase-key">+ sinΦ sinψ</span>') + eq('cos(Φ + ψ) = cosΦ cosψ <span class="phase-key">− sinΦ sinψ</span>') + p('Add the equations. The gold sine-product terms cancel:') + eq('cosφ₁ + cosφ₂ = 2 cosΦ cosψ') + eq('δn = 2A cosψ cosΦ'), '展开余弦，再相加', 'Expand the cosines, then add'),
        block(p('把平均相位和相位差换回波的变量：') + eq('Φ = k̄x − ω̄t，　ψ = ' + frac('Δk x − Δω t', '2')) + eq('δn = <span class="group-key">2A cos(' + frac('Δk x − Δω t', '2') + ')</span><wbr> · <span class="phase-key">cos(k̄x − ω̄t)</span>') + p('<span class="group-key">慢调制</span> × <span class="phase-key">内部快振荡</span>。两个分量产生周期性的拍；许多分量适当加权，才能得到局部波包。'), p('Substitute the wave variables back into the mean and difference phases:') + eq('Φ = k̄x − ω̄t,　ψ = ' + frac('Δk x − Δω t', '2')) + eq('δn = <span class="group-key">2A cos(' + frac('Δk x − Δω t', '2') + ')</span><wbr> · <span class="phase-key">cos(k̄x − ω̄t)</span>') + p('<span class="group-key">Slow modulation</span> × <span class="phase-key">fast inner oscillation</span>. Two components produce periodic beats; many weighted components can form a localized packet.'), '代回波的变量', 'Substitute the wave variables')
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
      id: 'approximation', visual: 'none', sequence: true,
      title: ['近似发生在这一步', 'Here is the approximation'],
      lead: ['上一页给出了精确叠加式。现在要解释：为什么包络能近似用一个速度描述？', 'We have the exact sum. Now ask: why can one speed approximately describe the envelope?'],
      blocks: [
        block(p('逐项计算能画出波包，却还没有直接说明包络怎样移动：') + eq('Z(x,t) = ∑ⱼ ' + frac('Aⱼ', 'n₀') + ' exp[i(kⱼx − ωⱼt)]') + p('我们希望从这个式子中分离出“内部快速相位”和依赖 <strong>x − v<sub>g</sub>t</strong> 的包络。') + p('为看清这一结构，对中心波数附近的 ω(k) 作一阶近似。它用于解释群速度；动画仍逐项使用完整的 ω(kⱼ)。'), p('Evaluating each term draws the packet, but does not yet explain its envelope motion:') + eq('Z(x,t) = ∑ⱼ ' + frac('Aⱼ', 'n₀') + ' exp[i(kⱼx − ωⱼt)]') + p('We want to separate the fast inner phase from an envelope depending on <strong>x − v<sub>g</sub>t</strong>.') + p('A first-order approximation of ω(k) near the center reveals that structure. It explains group speed; the animation still uses the full ω(kⱼ).'), '', ''),
        block(p('先定义第 j 个分量离中心的波数偏差：') + eq('Δkⱼ = kⱼ − k<sub>c</sub>　[rad/m]') + p('在 k<sub>c</sub> 处作 Taylor 展开；ω<sub>c</sub> = ω(k<sub>c</sub>)：') + eq('ωⱼ = ω(k<sub>c</sub> + Δkⱼ)') + eq('ωⱼ = ω<sub>c</sub> + ω′<sub>c</sub> Δkⱼ <wbr>+ ' + frac('1', '2') + ' ω″<sub>c</sub>(Δkⱼ)² + ⋯') + p('ω′<sub>c</sub> = (dω/dk)<sub>c</sub> [m/s]；ω″<sub>c</sub> = (d²ω/dk²)<sub>c</sub> [m²/s]。撇号表示对 k 求导，再在中心取值。'), p('Define the wavenumber offset of component j:') + eq('Δkⱼ = kⱼ − k<sub>c</sub>　[rad/m]') + p('Taylor-expand about k<sub>c</sub>, with ω<sub>c</sub> = ω(k<sub>c</sub>):') + eq('ωⱼ = ω(k<sub>c</sub> + Δkⱼ)') + eq('ωⱼ = ω<sub>c</sub> + ω′<sub>c</sub> Δkⱼ <wbr>+ ' + frac('1', '2') + ' ω″<sub>c</sub>(Δkⱼ)² + ⋯') + p('ω′<sub>c</sub> = (dω/dk)<sub>c</sub> [m/s]; ω″<sub>c</sub> = (d²ω/dk²)<sub>c</sub> [m²/s]. Primes mean derivatives with respect to k, evaluated at the center.'), '先写出 Taylor 展开', 'Write the Taylor expansion'),
        block(p('窄带且观察时间内高阶项的相位累积很小时，保留常数项和一次项。记 v<sub>g</sub> = ω′<sub>c</sub>：') + eq('<span class="group-key">ωⱼ ≈ ω<sub>c</sub> + v<sub>g</sub>(kⱼ − k<sub>c</sub>)</span>') + p('把上面的 <strong>ωⱼ 近似式</strong>，代入每个分量的相位 θⱼ = kⱼx − ωⱼt [rad]：') + eq('θⱼ ≈ kⱼx − [ω<sub>c</sub> + v<sub>g</sub>(kⱼ − k<sub>c</sub>)]t') + eq('θⱼ ≈ kⱼx − ω<sub>c</sub>t − v<sub>g</sub>(kⱼ − k<sub>c</sub>)t'), p('For a narrow band and times over which higher-order phase corrections stay small, keep the constant and linear terms. Write v<sub>g</sub> = ω′<sub>c</sub>:') + eq('<span class="group-key">ωⱼ ≈ ω<sub>c</sub> + v<sub>g</sub>(kⱼ − k<sub>c</sub>)</span>') + p('Substitute this <strong>approximation for ωⱼ</strong> into the phase of each component, θⱼ = kⱼx − ωⱼt [rad]:') + eq('θⱼ ≈ kⱼx − [ω<sub>c</sub> + v<sub>g</sub>(kⱼ − k<sub>c</sub>)]t') + eq('θⱼ ≈ kⱼx − ω<sub>c</sub>t − v<sub>g</sub>(kⱼ − k<sub>c</sub>)t'), '保留一阶并代入相位', 'Keep first order and substitute into phase'),
        block(p('加上再减去 k<sub>c</sub>x，把 kⱼx 写成：') + eq('kⱼx = k<sub>c</sub>x + (kⱼ − k<sub>c</sub>)x') + p('代回上一式，再提取公因子 (kⱼ − k<sub>c</sub>)：') + eq('θⱼ ≈ (k<sub>c</sub>x − ω<sub>c</sub>t)<wbr> + (kⱼ − k<sub>c</sub>)x − (kⱼ − k<sub>c</sub>)v<sub>g</sub>t') + eq('θⱼ ≈ <span class="phase-key">(k<sub>c</sub>x − ω<sub>c</sub>t)</span><wbr> + <span class="group-key">(kⱼ − k<sub>c</sub>)(x − v<sub>g</sub>t)</span>') + p('第一项对所有分量相同；第二项只通过 x − v<sub>g</sub>t 依赖位置和时间。下一页把它放回复数和 Z，读出包络速度。'), p('Add and subtract k<sub>c</sub>x to write:') + eq('kⱼx = k<sub>c</sub>x + (kⱼ − k<sub>c</sub>)x') + p('Substitute back, then factor out (kⱼ − k<sub>c</sub>):') + eq('θⱼ ≈ (k<sub>c</sub>x − ω<sub>c</sub>t)<wbr> + (kⱼ − k<sub>c</sub>)x − (kⱼ − k<sub>c</sub>)v<sub>g</sub>t') + eq('θⱼ ≈ <span class="phase-key">(k<sub>c</sub>x − ω<sub>c</sub>t)</span><wbr> + <span class="group-key">(kⱼ − k<sub>c</sub>)(x − v<sub>g</sub>t)</span>') + p('The first term is common to all components; the second depends on position and time through x − v<sub>g</sub>t. Next, put this into the complex sum Z to read the envelope speed.'), '分离中心相位', 'Separate the central phase')
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
      id: 'animation', visual: 'repetition', sequence: true,
      title: ['点阵、时间与观察窗口', 'Dots, time and the viewing window'],
      lead: ['点的疏密对应总密度。扩大观察窗口，还会看到什么？', 'Dot spacing represents total density. What appears if we widen the viewing window?'],
      blocks: [
        block(p('点阵使用守恒的运动学映射。它没有求解粒子受力，也没有绘制随机热运动；两种波速都不是单个电子的速度。') + eq('n = n₀ + δn，　' + frac('|δn|', 'n₀') + ' ≤ 0.18') + p('全部幅值之和为 0.18 n₀，因此 n ≥ 0.82 n₀，密度始终为正。n₀、δn、n 的单位为 m⁻³。'), p('The dots use a conservative kinematic map. Particle forces and random thermal motion are not simulated; neither wave speed is an electron velocity.') + eq('n = n₀ + δn,　' + frac('|δn|', 'n₀') + ' ≤ 0.18') + p('The amplitudes sum to 0.18 n₀, so n ≥ 0.82 n₀ and density stays positive. n₀, δn and n are in m⁻³.'), '', ''),
        block(p('先看一直使用的局部窗口：') + eq('−0.5 m ≤ x ≤ 0.9 m') + p('这里显示一个波包。每播放 1 s，对应物理时间 3 × 10⁻⁸ s；循环区间为：') + eq('0 ≤ t ≤ 2 × 10⁻⁷ s') + p('点击下一步扩大视野，查看这个窗口之外的密度波。'), p('Start with the original local window:') + eq('−0.5 m ≤ x ≤ 0.9 m') + p('It shows one packet. Each playback second represents 3 × 10⁻⁸ s of physical time, looping over:') + eq('0 ≤ t ≤ 2 × 10⁻⁷ s') + p('Use the next step to widen the view and see the density wave outside this window.'), '观察原来的局部窗口', 'Inspect the original window'),
        block(p('上图把视野扩大到 <strong>−6.5 m 至 6.5 m</strong>，能看到三个重复的波包。金色区域是原观察窗，下图把它放大。') + eq('L = ' + frac('2π rad', '1.2 rad/m') + ' ≈ 5.24 m') + p('播放或拖动时间：三个包络以相同方式演化，彼此相隔 L。宽视野中内部波峰很密，可在下图看清。'), p('The upper view spans <strong>−6.5 m to 6.5 m</strong> and shows three repeating packets. Gold marks the original window, enlarged below.') + eq('L = ' + frac('2π rad', '1.2 rad/m') + ' ≈ 5.24 m') + p('Play or scrub time: all three envelopes evolve identically, separated by L. Use the lower view to resolve the densely packed inner crests.'), '扩大视野，看到多个波包', 'Widen the view to see multiple packets'),
        block(p('为什么重复？本例的波数按同一间隔取样：') + eq('Δk<sub>s</sub> = 1.2 rad/m') + eq('kⱼ = (35 + j)Δk<sub>s</sub>') + p('把位置增加 L = 2π/Δk<sub>s</sub>，每个分量的相位都增加整数个 2π：') + eq('kⱼL = 2π(35 + j)') + eq('δn(x + L,t) = δn(x,t)') + p('所以密度和包络都重复。这来自本例的等间隔离散谱，并非所有物理波包都必须重复。'), p('Why does it repeat? The wavenumbers use a uniform spacing:') + eq('Δk<sub>s</sub> = 1.2 rad/m') + eq('kⱼ = (35 + j)Δk<sub>s</sub>') + p('Increasing x by L = 2π/Δk<sub>s</sub> adds an integer multiple of 2π to every component phase:') + eq('kⱼL = 2π(35 + j)') + eq('δn(x + L,t) = δn(x,t)') + p('Both density and envelope repeat. This follows from this uniformly sampled spectrum; physical packets need not repeat.'), '解释 5.24 m 从哪里来', 'Explain where 5.24 m comes from')
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
  function currentVisual() {
    if (current().id === 'animation') return s.build === 0 ? 'none' : (s.build === 1 ? 'packet' : 'repetition');
    return current().visual;
  }
  function hasPacket() { return ['packet', 'repetition'].includes(currentVisual()); }
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
    return !!ctx && hasPacket() && (current().id !== 'nondispersive' || s.build >= 1);
  }
  function motion() {
    $('motion').hidden = !canPlay();
    $('motion').textContent = s.paused ? text().play : text().pause;
    $('motion').setAttribute('aria-pressed', String(s.paused));
  }
  function render(reason = 'state') {
    const slide = current(), t = text(), options = packetOptions(), visual = currentVisual();
    $('lesson').dataset.visual = visual;
    $('slide-content').dataset.sequence = String(!!slide.sequence);
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
      node.hidden = slide.sequence ? i !== s.build : i > s.build;
      node.classList.remove('just-revealed');
      if (reason === 'reveal' && i === s.build) {
        void node.offsetWidth; node.classList.add('just-revealed');
      }
    });
    $('slide-layout').dataset.visual = visual;
    $('visual-pane').hidden = visual === 'none';
    $('packet-figure').hidden = !hasPacket();
    $('chart-figure').hidden = !['slopes', 'spectrum'].includes(visual);
    $('canvas-fallback').hidden = !!ctx; $('canvas-fallback').textContent = t.noCanvas;
    canvas.hidden = !ctx;
    $('packet-legend').hidden = !hasPacket() || !options.envelope;
    $('phase-key').hidden = !options.phase; $('phase-key').textContent = t.phase;
    $('group-key').hidden = !options.envelope; $('group-key').textContent = options.group ? t.group : t.envelope;
    $('time-controls').hidden = !canPlay() || slide.id === 'packet';
    $('time-label').textContent = t.time;
    $('comparison').hidden = slide.id !== 'nondispersive' || s.build < 2;
    $('comparison-label').textContent = t.compare; $('linear-branch').checked = s.linear;
    $('model-note').textContent = s.linear ? (lang === 'zh' ? '数学对照；时间减速并循环。' : 'Mathematical comparison; slowed, looped time.') : (slide.id === 'packet' ? t.model : t.slowed);
    $('model-note').hidden = !hasPacket();
    if (visual === 'repetition') $('model-note').textContent = lang === 'zh' ? '同一时刻；使用完整 ω(kⱼ)。' : 'Same time; full ω(kⱼ) in both views.';
    $('chart-note').textContent = visual === 'slopes'
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
    if (visual === 'repetition') canvas.setAttribute('aria-label', lang === 'zh' ? '宽视野显示间距约5.24米的三个波包。金色区域为原观察窗，下图在同一时刻将它放大。两图横轴x以米计，纵轴相对密度扰动无量纲，蓝色虚线是包络。' : 'Three packets repeat about every 5.24 m in the wide view. Gold marks the original window, enlarged below at the same time. Both axes: x in meters and dimensionless relative density; blue dashes show the envelope.');
    canvas.textContent = canvas.getAttribute('aria-label');
    $('status').textContent += '. ' + $('slide-content').children[s.build].textContent;
    if (reason === 'page' || (slide.sequence && ['reveal', 'back'].includes(reason))) {
      $('slide-main').classList.remove('slide-enter'); void $('slide-main').offsetWidth;
      $('slide-main').classList.add('slide-enter');
      window.scrollTo({ top: 0, behavior: 'instant' });
      $('title').focus({ preventScroll: true });
    }
    writePosition(); syncTime(); motion(); fit(); drawChart();
    if (reason === 'reveal' && !(slide.sequence && hasPacket())) {
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
    if (!ctx || !hasPacket()) return;
    const rect = canvas.getBoundingClientRect(), dpr = Math.min(devicePixelRatio || 1, 2);
    if (!rect.width || !rect.height) return;
    s.width = rect.width; s.height = rect.height;
    canvas.width = Math.round(rect.width * dpr); canvas.height = Math.round(rect.height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0); draw();
  }
  function draw() {
    if (!ctx || !hasPacket() || !s.width) return;
    if (currentVisual() === 'repetition') { drawRepetition(); return; }
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
  function drawRepetition() {
    const time = s.time / M.W0, modes = M.modes(false), period = 2 * Math.PI / 1.2;
    const left = 66, right = s.width - 18, width = right - left;
    ctx.clearRect(0, 0, s.width, s.height);
    const panel = (min, max, mid, amplitude, ticks, count) => {
      const px = x => left + (x - min) / (max - min) * width;
      for (const v of [-.18, 0, .18]) {
        const y = mid - amplitude * v / .18;
        line(left, y, right, y);
        label(v ? v.toFixed(2) : '0', left - 10, y, white, 22, 'right');
      }
      if (min < -1) {
        ctx.fillStyle = '#f4c58326'; ctx.fillRect(px(M.XMIN), mid - amplitude - 12, px(M.XMAX) - px(M.XMIN), 2 * amplitude + 24);
        line(px(M.XMIN), mid - amplitude - 12, px(M.XMIN), mid + amplitude + 12, gold);
        line(px(M.XMAX), mid - amplitude - 12, px(M.XMAX), mid + amplitude + 12, gold);
      }
      const samples = Array.from({ length: count + 1 }, (_, i) => M.sample(min + i / count * (max - min), time, modes));
      for (const [field, sign, color, dash] of [['envelope', 1, blue, [8, 5]], ['envelope', -1, blue, [8, 5]], ['re', 1, white, []]]) {
        ctx.beginPath(); ctx.strokeStyle = color; ctx.lineWidth = field === 're' ? 1.5 : 2.5; ctx.setLineDash(dash);
        samples.forEach((v, i) => {
          const x = left + i / count * width, y = mid - amplitude * sign * v[field] / .18;
          if (i) ctx.lineTo(x, y); else ctx.moveTo(x, y);
        });
        ctx.stroke(); ctx.setLineDash([]);
      }
      for (const [x, value] of ticks) label(value, px(x), mid + amplitude + 26, white, 22);
      label('x [m]', right, mid + amplitude + 58, white, 23, 'right');
      return px;
    };
    label(lang === 'zh' ? '宽视野' : 'Wide view', 8, 20, mint, 24, 'left');
    label('δn/n₀ [1]', right, 20, white, 22, 'right');
    const px = panel(-6.5, 6.5, 115, 42, [[-period, '−5.24'], [0, '0'], [period, '5.24']], 2400);
    const peak = M.peak(time, false), x1 = px(peak - period), x2 = px(peak);
    line(x1, 54, x2, 54, blue, 2); line(x1, 48, x1, 60, blue, 2); line(x2, 48, x2, 60, blue, 2);
    label('L', (x1 + x2) / 2, 41, blue, 23);
    line(8, 230, right, 230);
    label(lang === 'zh' ? '金色窗口放大' : 'Gold window enlarged', 8, 252, gold, s.width < 400 ? 22 : 26, 'left');
    panel(M.XMIN, M.XMAX, 322, 45, [[M.XMIN, '−0.5'], ...(s.width >= 500 ? [[0, '0']] : []), [M.XMAX, '0.9']], 360);
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
