/* Lesson 07: from a fluid model to a dispersion relation. */
(() => {
  'use strict';
  const M = PlasmaDerivationModel, $ = id => document.getElementById(id);
  const f = (a,b) => '<span class="eq-frac"><span>'+a+'</span><span class="sr-only"> / </span><span class="eq-den">'+b+'</span></span>';
  const eq = x => '<p class="math">'+x+'</p>', p = x => '<p>'+x+'</p>';
  const dt = x => f('∂'+x,'∂t'), dx = x => f('∂'+x,'∂x');
  const B = (zh,en,cz='继续推导',ce='Continue the derivation') => ({zh,en,cue:{zh:cz,en:ce}});
  const S = (id,visual,zh,en,lz,le,blocks) => ({id,visual,title:[zh,en],lead:[lz,le],blocks});
  const continuity = dt('n₁')+' + n₀ '+dx('v₁')+' = 0';
  const momentum = 'm<sub>e</sub> '+dt('v₁')+' = −eE₁';
  const poisson = dx('E₁')+' = −'+f('en₁','ε₀');
  const wp = 'ω<sub>pe</sub>', wpsq = 'ω<sub>pe</sub>²';
  const slides = [
    S('question','density','频率，能随便选吗？','Can we choose any frequency?',
      '给定一个电子密度波，什么频率才能让它自洽地演化？','For an electron-density wave, which frequency permits self-consistent evolution?',[
      B(p('先观察这一列密度波。我们已经会写它的形状：')+eq('n₁ = A cos(kx − ωt)')+p('A 是密度幅值 [m⁻³]；k [rad/m]，ω [rad/s]。现在要从物理方程求出 ω 与 k 的约束。'),
        p('Observe the density wave. We can already write its shape:')+eq('n₁ = A cos(kx − ωt)')+p('A is the density amplitude [m⁻³]; k [rad/m], ω [rad/s]. Now derive the constraint between ω and k from physics.')),
      B(p('密度决定电荷和电场，电场推动电子，电子流动又改变密度。')+eq('n₁ → E₁ → v₁ → n₁')+p('同一列波必须同时满足这三个环节。这种相容条件，就是色散关系的来源。'),
        p('Density sets charge and electric field; the field accelerates electrons; their flow changes density.')+eq('n₁ → E₁ → v₁ → n₁')+p('One wave must satisfy all three links simultaneously. Their compatibility gives the dispersion relation.'),'找出自洽的闭环','Identify the feedback loop')
    ]),
    S('model','none','先说清楚：我们在求哪种波？','Specify the wave and the model',
      '先忽略电子压强，从最简单的电子密度振荡开始。','Begin with the simplest electron-density oscillation by neglecting electron pressure.',[
      B(p('只考虑 x 方向的变化；背景均匀、无磁场。离子固定为 nᵢ = n₀，电子可运动。忽略电子压强的情形称为冷电子模型。')+p('电场与扰动都沿 x 方向，描述电子的纵向密度振荡。'),
        p('Allow variation only along x, with a uniform background and no magnetic field. Ions remain at nᵢ = n₀ while electrons move. Neglecting electron pressure gives the cold-electron model.')+p('The field and disturbance are both along x, describing longitudinal electron-density oscillations.')),
      B(p('需要三个随位置和时间变化的量：')+eq('n(x,t)　[m⁻³]')+eq('v(x,t)　[m/s]，　E(x,t)　[V/m]')+p('n：电子数密度；v：电子流体的平均速度；E：电场。电子电荷为 −e，其中 e > 0 [C]；m<sub>e</sub> 是电子质量 [kg]，ε₀ 是真空介电常数 [F/m]。'),
        p('We need three fields varying in position and time:')+eq('n(x,t)　[m⁻³]')+eq('v(x,t)　[m/s],　E(x,t)　[V/m]')+p('n: electron number density; v: mean electron-fluid velocity; E: electric field. Electron charge is −e, with e > 0 [C]; m<sub>e</sub> is electron mass [kg], and ε₀ is vacuum permittivity [F/m].'),'认识变量与单位','Identify variables and units')
    ]),
    S('continuity','none','使用连续性方程','Use the continuity equation',
      '从电子数守恒的连续性方程出发。','Start from the continuity equation for electron number.',[
      B(eq(dt('n')+' + '+dx('(nv)')+' = 0')+p('n [m⁻³] 是电子数密度，v [m/s] 是电子流体速度。两项单位均为 m⁻³ s⁻¹。')+p('它将密度 n 与速度 v 联系起来；另外两个关系来自动量方程和泊松方程。'),
        eq(dt('n')+' + '+dx('(nv)')+' = 0')+p('n [m⁻³] is electron number density and v [m/s] is electron-fluid velocity. Both terms have units m⁻³ s⁻¹.')+p('This relates density n to velocity v. Momentum and Poisson provide the other two relations.'))
    ]),
    S('momentum','none','第二条：电场怎样推动电子？','Second: how does the field move electrons?',
      '使用牛顿定律，并记住电子带负电。','Use Newton’s law and keep the negative electron charge.',[
      B(eq('m<sub>e</sub>'+f('Dv','Dt')+' = −eE')+p('D/Dt 是跟随流体运动的时间导数。对于一维速度场：')+eq(f('Dv','Dt')+' = '+dt('v')+' + v'+dx('v')),
        eq('m<sub>e</sub>'+f('Dv','Dt')+' = −eE')+p('D/Dt follows the moving fluid. In a one-dimensional velocity field:')+eq(f('Dv','Dt')+' = '+dt('v')+' + v'+dx('v'))),
      B(eq('m<sub>e</sub>['+dt('v')+' + v'+dx('v')+'] = −eE')+p('左边包含局部速度变化和穿过不均匀速度场的变化；右边是每个电子所受的电场力。')+p('两边单位均为 N。这一步只考虑电场力。'),
        eq('m<sub>e</sub>['+dt('v')+' + v'+dx('v')+'] = −eE')+p('The left side includes local velocity change and change while moving through a nonuniform velocity field. The right side is the electric force per electron.')+p('Both sides have units N. At this step, only the electric force is included.'),'写成速度场的方程','Write the field equation')
    ]),
    S('poisson','none','第三条：密度怎样产生电场？','Third: how does density produce a field?',
      '背景可以电中性，但扰动中必须允许少量电荷分离。','The background is neutral, but the perturbation must allow a small charge imbalance.',[
      B(p('离子密度固定为 n₀，电子密度为 n：')+eq('ρ = e n₀ − en　[C/m³]')+p('泊松方程的一维形式为：')+eq(dx('E')+' = '+f('ρ','ε₀')+' = '+f('e(n₀ − n)','ε₀')),
        p('The ions remain at n₀ and the electron density is n:')+eq('ρ = e n₀ − en　[C/m³]')+p('In one dimension, Poisson’s equation is:')+eq(dx('E')+' = '+f('ρ','ε₀')+' = '+f('e(n₀ − n)','ε₀'))),
      B(p('写 n = n₀ + n₁，背景正负电荷抵消：')+eq('ρ₁ = −en₁')+eq(poisson)+p('电子过密 n₁ > 0 对应负电荷。若把扰动也强制设成处处电中性，就会删掉这里需要的恢复电场。'),
        p('Write n = n₀ + n₁. The background charges cancel:')+eq('ρ₁ = −en₁')+eq(poisson)+p('An electron excess n₁ > 0 gives negative charge. Imposing exact neutrality on the perturbation would remove the restoring field needed here.'),'消去背景电荷','Cancel the background charge')
    ]),
    S('linear-continuity','none','把小扰动代进去','Insert a small perturbation',
      '线性化：保留扰动的一次项，舍去扰动与扰动的乘积。','Linearization keeps first-order perturbations and drops products of perturbations.',[
      B(p('平衡态为均匀 n₀、v₀ = 0、E₀ = 0。令：')+eq('n = n₀ + n₁，　v = v₁，　E = E₁')+p('|n₁| ≪ n₀，v₁、E₁ 也按同一小参数计为一阶。把它们代入连续性方程：')+eq(dt('(n₀ + n₁)')+' + '+dx('[(n₀ + n₁)v₁]')+' = 0'),
        p('The equilibrium has uniform n₀, v₀ = 0 and E₀ = 0. Let:')+eq('n = n₀ + n₁,　v = v₁,　E = E₁')+p('|n₁| ≪ n₀; v₁ and E₁ are also first order in the same small parameter. Substitute into continuity:')+eq(dt('(n₀ + n₁)')+' + '+dx('[(n₀ + n₁)v₁]')+' = 0')),
      B(eq(dt('n₁')+' + n₀ '+dx('v₁')+' + <span class="phase-key">'+dx('(n₁v₁)')+'</span> = 0')+p('n₀ 不随时空变化；金色项是两个一阶扰动的乘积，属于二阶。舍去它：')+eq(continuity),
        eq(dt('n₁')+' + n₀ '+dx('v₁')+' + <span class="phase-key">'+dx('(n₁v₁)')+'</span> = 0')+p('n₀ is constant in space and time. The gold term is a product of first-order perturbations, hence second order. Drop it:')+eq(continuity),'展开并舍去二阶项','Expand and drop second order')
    ]),
    S('linear-system','none','得到三个线性方程','Obtain three linear equations',
      '对动量方程做同样的处理，泊松方程已经是一阶形式。','Apply the same ordering to momentum; Poisson is already first order.',[
      B(eq('m<sub>e</sub>['+dt('v₁')+' + <span class="phase-key">v₁'+dx('v₁')+'</span>] = −eE₁')+p('金色项是速度扰动与其空间导数的乘积，属于二阶，舍去后：')+eq(momentum),
        eq('m<sub>e</sub>['+dt('v₁')+' + <span class="phase-key">v₁'+dx('v₁')+'</span>] = −eE₁')+p('The gold term multiplies the velocity perturbation by its spatial derivative, making it second order. Dropping it gives:')+eq(momentum)),
      B(eq(continuity)+eq(momentum)+eq(poisson)+p('未知量是 n₁、v₁、E₁。下一步用同一 k、ω 的平面波，把这三个微分方程变成代数方程。'),
        eq(continuity)+eq(momentum)+eq(poisson)+p('The unknowns are n₁, v₁ and E₁. Next, use plane waves with a shared k and ω to turn these differential equations into algebra.'),'把三个方程放在一起','Collect the three equations')
    ]),
    S('plane-wave','none','对三个量使用同一个波模','Use one mode for all three fields',
      '共同的 k、ω 不表示三个量同相；相位差可以放在复振幅里。','A shared k and ω does not require equal phases; the complex amplitudes carry phase differences.',[
      B(eq('ñ₁ = N e<sup>i(kx − ωt)</sup>')+eq('ṽ₁ = V e<sup>i(kx − ωt)</sup>，　Ẽ₁ = ℰ e<sup>i(kx − ωt)</sup>')+p('物理量取实部。N [m⁻³]、V [m/s]、ℰ [V/m] 是常数复振幅；k [rad/m]、ω [rad/s]。以下取 k > 0。'),
        eq('ñ₁ = N e<sup>i(kx − ωt)</sup>')+eq('ṽ₁ = V e<sup>i(kx − ωt)</sup>,　Ẽ₁ = ℰ e<sup>i(kx − ωt)</sup>')+p('Physical fields are the real parts. N [m⁻³], V [m/s] and ℰ [V/m] are constant complex amplitudes; k [rad/m], ω [rad/s]. Take k > 0 below.')),
      B(p('由 04 课的指数微分规则：')+eq('∂<sub>t</sub> → −iω，　∂<sub>x</sub> → ik')+p('代入后约去共同的非零指数因子：')+eq('−iωN + ikn₀V = 0')+eq('−iωm<sub>e</sub>V = −eℰ')+eq('ikℰ = −'+f('eN','ε₀')),
        p('Use the exponential derivative rules from lesson 04:')+eq('∂<sub>t</sub> → −iω,　∂<sub>x</sub> → ik')+p('Substitute and cancel the shared nonzero exponential:')+eq('−iωN + ikn₀V = 0')+eq('−iωm<sub>e</sub>V = −eℰ')+eq('ikℰ = −'+f('eN','ε₀')),'代入并约去指数','Substitute and cancel the exponential')
    ]),
    S('eliminate','none','消去速度和电场振幅','Eliminate velocity and field amplitudes',
      '先用连续性和泊松方程，把 V、ℰ 都写成 N 的倍数。','Use continuity and Poisson to express both V and ℰ in terms of N.',[
      B(eq('−iωN + ikn₀V = 0　⇒　V = '+f('ωN','kn₀'))+eq('ikℰ = −'+f('eN','ε₀')+'　⇒　ℰ = '+f('ieN','kε₀'))+p('第二式用了 1/i = −i。ℰ 与 N 相差一个 i，电场与密度并不同相。'),
        eq('−iωN + ikn₀V = 0　⇒　V = '+f('ωN','kn₀'))+eq('ikℰ = −'+f('eN','ε₀')+'　⇒　ℰ = '+f('ieN','kε₀'))+p('The second result uses 1/i = −i. The factor i means field and density are not in phase.')),
      B(p('把这两个振幅代入动量方程 −iωm<sub>e</sub>V = −eℰ：')+eq('−iωm<sub>e</sub>'+f('ωN','kn₀')+' = −e '+f('ieN','kε₀'))+p('两边同乘 kn₀/(−im<sub>e</sub>)：')+eq('ω²N = '+f('n₀e²','m<sub>e</sub>ε₀')+' N'),
        p('Insert both amplitudes into momentum, −iωm<sub>e</sub>V = −eℰ:')+eq('−iωm<sub>e</sub>'+f('ωN','kn₀')+' = −e '+f('ieN','kε₀'))+p('Multiply both sides by kn₀/(−im<sub>e</sub>):')+eq('ω²N = '+f('n₀e²','m<sub>e</sub>ε₀')+' N'),'代回动量方程','Substitute into momentum'),
      B(eq('['+'ω² − '+f('n₀e²','m<sub>e</sub>ε₀')+']N = 0')+p('N = 0 表示没有密度波。要有非零波幅 N ≠ 0，方括号必须为零：')+eq('<span class="group-key">ω² = '+wpsq+' = '+f('n₀e²','m<sub>e</sub>ε₀')+'</span>'),
        eq('[ω² − '+f('n₀e²','m<sub>e</sub>ε₀')+']N = 0')+p('N = 0 means there is no density wave. A nonzero amplitude N requires the bracket to vanish:')+eq('<span class="group-key">ω² = '+wpsq+' = '+f('n₀e²','m<sub>e</sub>ε₀')+'</span>'),'要求非零波幅','Require a nonzero wave')
    ]),
    S('cold-result','density','第一条关系：冷电子振荡','The first relation: cold-electron oscillations',
      '这次 ω 是从三个方程的相容条件中得到的。','Now ω comes from compatibility of the three equations.',[
      B(eq('ω = ±'+wp+'，　'+wp+' = √('+f('n₀e²','m<sub>e</sub>ε₀')+')')+p('以下取 ω = +ω<sub>pe</sub>。ω<sub>pe</sub> [rad/s] 是电子等离子体角频率；f<sub>pe</sub> = ω<sub>pe</sub>/(2π) [Hz]。')+p('本例 n₀ ≈ 3.14 × 10¹² m⁻³，ω<sub>pe</sub> = 10⁸ rad/s。'),
        eq('ω = ±'+wp+',　'+wp+' = √('+f('n₀e²','m<sub>e</sub>ε₀')+')')+p('Use ω = +ω<sub>pe</sub> below. ω<sub>pe</sub> [rad/s] is the electron plasma angular frequency; f<sub>pe</sub> = ω<sub>pe</sub>/(2π) [Hz].')+p('Here n₀ ≈ 3.14 × 10¹² m⁻³ and ω<sub>pe</sub> = 10⁸ rad/s.')),
      B(p('把波数加倍：波长减半，但冷模型中的振荡频率保持不变。播放动画，对比两列波。')+eq('ω(k) = '+wp)+p('它的 ω–k 图是水平线：v<sub>ph</sub> = ω<sub>pe</sub>/k，v<sub>g</sub> = 0。它不是 06 课的无色散对照 ω = Vk；这里相速度仍随 k 改变。'),
        p('Double k: the wavelength halves, but the cold-model frequency stays the same. Play to compare the two waves.')+eq('ω(k) = '+wp)+p('Its ω–k plot is horizontal: v<sub>ph</sub> = ω<sub>pe</sub>/k and v<sub>g</sub> = 0. This differs from the nondispersive ω = Vk comparison in lesson 06: phase speed here still depends on k.'),'比较两种波长','Compare two wavelengths')
    ]),
    S('restoring','none','用另一条路检查正负号','Check the sign another way',
      '消去速度和电场，直接看密度是否受到恢复作用。','Eliminate velocity and field directly to check the restoring response.',[
      B(p('对连续性方程取一次时间导数：')+eq(f('∂²n₁','∂t²')+' + n₀ '+dx('('+dt('v₁')+')')+' = 0')+p('代入 ∂<sub>t</sub>v₁ = −(e/m<sub>e</sub>)E₁：')+eq(f('∂²n₁','∂t²')+' = '+f('n₀e','m<sub>e</sub>')+dx('E₁')),
        p('Differentiate continuity once in time:')+eq(f('∂²n₁','∂t²')+' + n₀ '+dx('('+dt('v₁')+')')+' = 0')+p('Substitute ∂<sub>t</sub>v₁ = −(e/m<sub>e</sub>)E₁:')+eq(f('∂²n₁','∂t²')+' = '+f('n₀e','m<sub>e</sub>')+dx('E₁'))),
      B(p('再代入泊松方程 ∂<sub>x</sub>E₁ = −en₁/ε₀：')+eq(f('∂²n₁','∂t²')+' = −'+f('n₀e²','m<sub>e</sub>ε₀')+' n₁')+eq(f('∂²n₁','∂t²')+' + '+wpsq+' n₁ = 0')+p('这个方程描述角频率为 ω<sub>pe</sub> 的往复振荡。前一行的负号表示：密度偏离后，会产生反向的恢复作用。'),
        p('Now substitute Poisson, ∂<sub>x</sub>E₁ = −en₁/ε₀:')+eq(f('∂²n₁','∂t²')+' = −'+f('n₀e²','m<sub>e</sub>ε₀')+' n₁')+eq(f('∂²n₁','∂t²')+' + '+wpsq+' n₁ = 0')+p('This equation describes oscillation at angular frequency ω<sub>pe</sub>. The minus sign in the preceding line means that a density deviation induces an opposing, restoring response.'),'得到密度振荡方程','Obtain the density oscillator')
    ]),
    S('pressure','none','加入压强，需要多一个假设','Adding pressure requires one more assumption',
      '热运动可以通过流体压强体现；必须说明压强怎样响应密度。','Thermal effects can enter through fluid pressure; specify how pressure responds to density.',[
      B(p('p [Pa] 是电子压强，写作 p = p₀ + p₁。每个电子的压强力为 −(1/n)∂<sub>x</sub>p；均匀背景满足 ∂<sub>x</sub>p₀ = 0。只保留一阶扰动，得到：')+eq('m<sub>e</sub>'+dt('v₁')+' = −eE₁ − '+f('1','n₀')+dx('p₁'))+p('密度扰动与压强扰动的乘积是二阶项，已略去。要消去新增的未知量 p₁，需要给出它与 n₁ 的关系。'),
        p('Let p [Pa] be electron pressure, with p = p₀ + p₁. The pressure force per electron is −(1/n)∂<sub>x</sub>p. The uniform background has ∂<sub>x</sub>p₀ = 0. Keeping first-order perturbations gives:')+eq('m<sub>e</sub>'+dt('v₁')+' = −eE₁ − '+f('1','n₀')+dx('p₁'))+p('Products of density and pressure perturbations are second order and have been dropped. To eliminate the new unknown p₁, we need its relation to n₁.')),
      B(p('本例取压强扰动与密度扰动成正比：')+eq('p₁ = m<sub>e</sub>u²n₁，　u² = '+f('1','m<sub>e</sub>')+'('+f('dp','dn')+')₀')+p('u [m/s] 表示压强对密度变化的响应强弱；v 才是电子流体的平均速度。(dp/dn)₀ 是在背景密度 n₀ 处求出的压强随密度变化的斜率。')+eq(dt('v₁')+' = −'+f('e','m<sub>e</sub>')+'E₁ − '+f('u²','n₀')+dx('n₁')),
        p('In this example, take the pressure perturbation to be proportional to the density perturbation:')+eq('p₁ = m<sub>e</sub>u²n₁,　u² = '+f('1','m<sub>e</sub>')+'('+f('dp','dn')+')₀')+p('u [m/s] measures the pressure response to a density change; v is the mean electron-fluid velocity. (dp/dn)₀ is the slope of pressure versus density evaluated at the background density n₀.')+eq(dt('v₁')+' = −'+f('e','m<sub>e</sub>')+'E₁ − '+f('u²','n₀')+dx('n₁')),'写出压强与密度的关系','Relate pressure to density')
    ]),
    S('warm-result','none','把压强项带回消元过程','Carry pressure through the elimination',
      '连续性和泊松方程没有改变；只替换动量方程。','Continuity and Poisson are unchanged; only momentum gains a term.',[
      B(eq('−iωV = −'+f('e','m<sub>e</sub>')+'ℰ − ik'+f('u²','n₀')+'N')+p('仍然使用之前得到的 V = ωN/(kn₀)、ℰ = ieN/(kε₀)：')+eq('−iω '+f('ωN','kn₀')+' = −'+f('ie²N','m<sub>e</sub>kε₀')+' − '+f('iku²N','n₀')),
        eq('−iωV = −'+f('e','m<sub>e</sub>')+'ℰ − ik'+f('u²','n₀')+'N')+p('Reuse V = ωN/(kn₀) and ℰ = ieN/(kε₀):')+eq('−iω '+f('ωN','kn₀')+' = −'+f('ie²N','m<sub>e</sub>kε₀')+' − '+f('iku²N','n₀'))),
      B(p('两边同乘 kn₀/(−i)，并要求 N ≠ 0：')+eq('ω²N = ('+f('n₀e²','m<sub>e</sub>ε₀')+' + u²k²)N')+eq('<span class="group-key">ω² = '+wpsq+' + u²k²</span>')+p('第一项来自电场恢复力，第二项来自压强响应。两项单位都是 s⁻²（弧度视为无量纲）。'),
        p('Multiply both sides by kn₀/(−i), and require N ≠ 0:')+eq('ω²N = ('+f('n₀e²','m<sub>e</sub>ε₀')+' + u²k²)N')+eq('<span class="group-key">ω² = '+wpsq+' + u²k²</span>')+p('The first term comes from electric restoring force; the second from pressure. Both have units s⁻², with radians dimensionless.'),'保留压强项，得到新关系','Retain pressure to obtain the relation'),
      B(p('现在接回 05、06 课使用的形式：')+eq('ω(k) = √(ω₀² + u²k²)，　ω₀ = '+wp)+p('取 ω₀ = 10⁸ rad/s、u = 10⁶ m/s，就得到前两课的示例。u → 0 时恢复冷电子结果。'),
        p('This recovers the form used in lessons 05 and 06:')+eq('ω(k) = √(ω₀² + u²k²),　ω₀ = '+wp)+p('Choose ω₀ = 10⁸ rad/s and u = 10⁶ m/s for the earlier example. The limit u → 0 returns the cold result.'),'接回前两课的曲线','Connect to the earlier curve')
    ]),
    S('explore','dispersion','先预测，再改变模型参数','Predict before changing parameters',
      '只改变背景密度，或只打开压强项，观察曲线怎样变化。','Change background density or enable pressure, and observe the curve.',[
      B(p('先预测：把 n₀ 增大到原来的 4 倍，冷电子频率会变成几倍？然后拖动密度条验证。')+eq(wp+' ∝ √n₀')+p('每次调整表示另一个均匀平衡态；离子背景与电子背景一起改变，仍保持背景电中性。'),
        p('Predict: if n₀ becomes four times larger, what happens to the cold frequency? Then check with the density slider.')+eq(wp+' ∝ √n₀')+p('Each setting is a different uniform equilibrium. The ion and electron backgrounds change together and remain neutral.')),
      B(p('密度变为 4 倍，ω<sub>pe</sub> 变为 2 倍。再打开压强项：')+eq('ω² = '+wpsq+' + u²k²')+p('u 固定为 10⁶ m/s。压强使高 k 端抬升；提高 n₀ 会提高曲线左端的频率。图中 k = 0 处表示波长越来越长时的极限，此时 ω → ω<sub>pe</sub>。'),
        p('Four times the density gives twice ω<sub>pe</sub>. Now enable pressure:')+eq('ω² = '+wpsq+' + u²k²')+p('u is fixed at 10⁶ m/s. Pressure raises the high-k part; increasing n₀ raises the frequency at the left end. The point k = 0 represents the limit of increasingly long wavelengths, where ω → ω<sub>pe</sub>.'),'看答案，再比较压强','Reveal the answer and compare pressure')
    ]),
    S('check','none','用相容条件检查一个候选波','Check a candidate wave for compatibility',
      '在同一冷电子背景中，把 k 加倍，再指定 ω = 2ωpe，能得到非零密度波吗？','In the same cold background, double k and prescribe ω = 2ωpe. Is a nonzero density mode possible?',[
      B(p('不要只看正弦函数“画得出来”。把候选频率放进推导得到的条件：')+eq('(ω² − '+wpsq+')N = 0')+p('先判断 N 是否可以非零，再点击下一步。'),
        p('A sinusoid can be drawn without satisfying the physics. Insert the proposed frequency into:')+eq('(ω² − '+wpsq+')N = 0')+p('Decide whether N can be nonzero, then continue.')),
      B(eq('[(2'+wp+')² − '+wpsq+']N = 3'+wpsq+'N = 0')+p('<strong>不能；只能有 N = 0。</strong>改变 k 不会把这里的振荡频率 ω<sub>pe</sub> 变成两倍。色散关系筛选的是能满足全部线性方程的非零波模。')+p('推导路线：模型假设 → 小扰动线性化 → 平面波代入 → 消元 → 非零解条件。'),
        eq('[(2'+wp+')² − '+wpsq+']N = 3'+wpsq+'N = 0')+p('<strong>No: only N = 0 is possible.</strong> Changing k does not double the oscillation frequency ω<sub>pe</sub> in this model. A dispersion relation selects nonzero modes satisfying all linearized equations.')+p('Route: model assumptions → linear perturbations → plane-wave substitution → elimination → nonzero-solution condition.'),'查看答案与推导路线','Reveal the answer and the derivation route'),
      B(p('忽略电子压强时：')+eq('ω² = '+wpsq)+p('加入本课给定的压强与密度关系后：')+eq('ω² = '+wpsq+' + u²k²')+p('两条关系都来自同一要求：密度、速度和电场的变化必须同时满足三个方程。')+p('参考：<a href="https://silas.psfc.mit.edu/introplasma/master.pdf" target="_blank" rel="noopener">MIT · Introduction to Plasma Physics</a>；<a href="https://www.princeton.edu/~idodin/ast553/main.pdf" target="_blank" rel="noopener">Princeton AST 553 · Waves in warm fluid plasma</a>。'),
        p('Neglecting electron pressure:')+eq('ω² = '+wpsq)+p('Including the pressure–density relation used here:')+eq('ω² = '+wpsq+' + u²k²')+p('Both relations follow from the same requirement: the density, velocity and electric field must satisfy all three equations together.')+p('References: <a href="https://silas.psfc.mit.edu/introplasma/master.pdf" target="_blank" rel="noopener">MIT · Introduction to Plasma Physics</a>; <a href="https://www.princeton.edu/~idodin/ast553/main.pdf" target="_blank" rel="noopener">Princeton AST 553 · Waves in warm fluid plasma</a>.'),'回顾两条色散关系','Review both dispersion relations')
    ])
  ];

  // Short explanations accumulate; long derivations move to another working panel.
  // Each number identifies a panel within the same slide. Slide numbers stay stable.
  const buildGroups = {
    'linear-system':[0,1], 'eliminate':[0,0,1],
    'warm-result':[0,0,1], 'check':[0,0,1]
  };

  const ui={
    zh:{title:'第一条色散关系怎样推出来？',chapter:'07 · 第一条色散关系怎样推出来？',next:'下一步',page:'下一页',back:'上一步',prev:'上一页',restart:'本页起始',restartLesson:'本课起始',replay:'从头回顾',slide:'幻灯片',build:'本页',play:'播放动画',pause:'暂停动画',time:'观察时间 t',density:'背景密度倍数',warm:'加入压强：u = 10⁶ m/s',fallback:'图像不可用，可继续阅读公式与说明。冷模型中两种波长具有相同的振荡频率；加入压强后，频率随波数升高。'},
    en:{title:'Deriving the first dispersion relation',chapter:'07 · Deriving the first dispersion relation',next:'Next step',page:'Next slide',back:'Back a step',prev:'Previous slide',restart:'Restart slide',restartLesson:'Restart lesson',replay:'Start again',slide:'Slide',build:'Build',play:'Play',pause:'Pause',time:'Observe time t',density:'Background density factor',warm:'Include pressure: u = 10⁶ m/s',fallback:'The figure is unavailable; continue with the equations. The cold model gives the same oscillation frequency at both wavelengths. Pressure makes frequency rise with wavenumber.'}
  };
  const canvas=$('plasma'),ctx=canvas.getContext('2d');
  const comparison=$('comparison-plasma'),comparisonCtx=comparison.getContext('2d');
  const reduced=matchMedia('(prefers-reduced-motion: reduce)');
  const s={slide:0,build:0,time:0,paused:true,factor:1,warm:false,width:0,height:0};
  let lang='zh',last=null,renderedSlide=null,chartKey='';
  const current=()=>slides[s.slide],tr=a=>a[lang==='en'?1:0],text=()=>ui[lang];
  const running=()=>!!ctx&&current().visual==='density';
  const reset=()=>{s.time=0;s.paused=true;s.factor=1;s.warm=false;last=null;};
  function readHash(){
    const m=location.hash.match(/^#slide-(\d+)(?:-step-(\d+))?$/);
    s.slide=m?Math.max(0,Math.min(slides.length-1,Number(m[1])-1)):0;
    s.build=m?Math.max(0,Math.min(current().blocks.length-1,Number(m[2]||1)-1)):0;reset();
  }
  function save(){
    try{const url=new URL(location.href);url.searchParams.set('lang',lang);url.hash='slide-'+(s.slide+1)+'-step-'+(s.build+1);history.replaceState(null,'',url);}catch(_){}
  }
  function sync(){
    $('packet-time').value=String(s.time);
    const t=(s.time/M.W0/1e-8).toFixed(2)+' × 10⁻⁸ s';
    $('time-output').textContent=t;$('packet-time').setAttribute('aria-valuetext',t);
    $('motion').textContent=s.paused?text().play:text().pause;$('motion').setAttribute('aria-pressed',String(s.paused));
  }
  function fadeIn(node) {
    if(reduced.matches)return;
    node.classList.remove('content-enter');void node.offsetWidth;
    node.classList.add('content-enter');
  }
  function setText(id,value,animate=false) {
    const node=$(id);
    if(node.textContent===value)return;
    node.textContent=value;if(animate)fadeIn(node);
  }
  function show(node,visible,animate=false) {
    const wasHidden=node.hasAttribute('hidden');
    node.toggleAttribute('hidden',!visible);
    if(visible&&wasHidden&&animate)fadeIn(node);
  }
  function renderBlocks(animate) {
    const slide=current(),groups=buildGroups[slide.id]||slide.blocks.map(()=>0);
    const wanted=slide.blocks.map((block,i)=>({block,i,key:slide.id+':'+i}))
      .filter(({i})=>i<=s.build&&groups[i]===groups[s.build]);
    const content=$('slide-content'),keys=new Set(wanted.map(item=>item.key));
    for(const node of [...content.children])if(!keys.has(node.dataset.key))node.remove();
    let newest=null;
    for(const {block,i,key} of wanted){
      let node=[...content.children].find(n=>n.dataset.key===key);
      if(!node){
        node=document.createElement('section');node.className='build-block';
        node.dataset.key=key;node.dataset.language=lang;node.innerHTML=block[lang];
        content.append(node);if(animate)fadeIn(node);newest=node;
      }else if(node.dataset.language!==lang){
        node.dataset.language=lang;node.innerHTML=block[lang];if(animate)fadeIn(node);
      }
      if(i===s.build)$('status').textContent=text().slide+' '+(s.slide+1)+', '+text().build+' '+(s.build+1)+'. '+node.textContent;
    }
    return newest;
  }
  function render(reason='state'){
    const slide=current(),t=text(),v=slide.visual;
    const animate=['page','reveal','back'].includes(reason),changedSlide=renderedSlide!==slide.id;
    const double=slide.id==='cold-result'&&s.build===1;
    document.documentElement.lang=lang==='zh'?'zh-CN':'en';document.title=tr(slide.title)+' | AlgoPlasma';
    $('lesson').dataset.slide=slide.id;$('lesson').dataset.build=String(s.build);$('lesson').dataset.visual=v;
    $('lesson').dataset.double=String(double);
    setText('title',tr(slide.title),animate);setText('narration',tr(slide.lead),animate);
    setText('chapter',t.chapter);setText('slide-label',t.chapter);
    const newest=renderBlocks(animate);
    $('slide-layout').dataset.visual=v;show($('visual-pane'),v!=='none');
    show(canvas,v==='density'&&!!ctx,animate);
    show(comparison,double&&!!ctx&&!!comparisonCtx,animate);
    show($('lesson-chart'),v==='dispersion',animate);
    $('canvas-fallback').hidden=v!=='density'||!!ctx;$('canvas-fallback').textContent=t.fallback;
    $('animation-controls').hidden=!running();$('time-label').textContent=t.time;
    $('parameter-controls').hidden=v!=='dispersion';
    $('density-label').textContent=t.density;$('density-factor').value=String(s.factor);
    $('density-output').textContent=s.factor.toFixed(0)+' × n₀,ref';
    $('density-factor').setAttribute('aria-valuetext',s.factor+'; n₀ = '+(s.factor*M.NREF/1e12).toFixed(3)+' × 10¹² m⁻³');
    show($('warm-control'),v==='dispersion'&&s.build>=1,animate);$('warm-branch').checked=s.warm;$('warm-label').textContent=t.warm;
    const noteDensity=lang==='zh'
      ? 'n₁/n₀ [1]，幅值 0.08；n₀ ≈ 3.14 × 10¹² m⁻³。点的疏密表示电子数密度。'
      : 'n₁/n₀ [1], amplitude 0.08; n₀ ≈ 3.14 × 10¹² m⁻³. Dot spacing represents electron number density.';
    $('model-note').textContent=v==='density'?noteDensity:(lang==='zh'?'实线：所选模型；压强打开时，虚线表示同一密度下未加入压强的结果。':'Solid: selected model. With pressure enabled, dashes show the result without pressure at the same density.');
    $('time-note').hidden=v!=='density';
    $('time-note').textContent=lang==='zh'?'播放 1 s 对应 3 × 10⁻⁸ s；按 6.28 × 10⁻⁸ s 周期循环。':'1 s of playback = 3 × 10⁻⁸ s; loops with a 6.28 × 10⁻⁸ s period.';
    if(slide.id==='cold-result'&&s.build===1)$('time-note').textContent+=(lang==='zh'?' 两图分别比较，未作叠加。':' The plots are separate cases, not a sum.');
    $('parameter-note').hidden=v!=='dispersion';
    $('parameter-note').textContent='n₀ = '+(s.factor*M.NREF/1e12).toFixed(3)+' × 10¹² m⁻³; ωpe = '+(M.plasmaFrequency(s.factor*M.NREF)/1e8).toFixed(3)+' × 10⁸ rad/s';
    const end=s.build===slide.blocks.length-1,final=s.slide===slides.length-1;
    $('advance-kind').textContent=end?(final?t.replay:t.page):t.next;
    $('advance-text').textContent=end?(final?t.title:tr(slides[s.slide+1].title)):slide.blocks[s.build+1].cue[lang];
    $('advance').dataset.action=end?(final?'replay':'page'):'reveal';
    $('back').hidden=s.slide===0&&s.build===0;$('back').textContent=s.build?t.back:t.prev;
    $('restart-slide').textContent=t.restart;$('restart-lesson').textContent=t.restartLesson;
    $('stage-count').textContent=t.slide+' '+(s.slide+1)+' / '+slides.length;$('build-count').textContent=t.build+' '+(s.build+1)+' / '+slide.blocks.length;
    $('progress').replaceChildren(...slide.blocks.map((_,i)=>{const n=document.createElement('i');if(i<=s.build)n.className='filled';return n;}));
    $('keyboard-note').textContent=lang==='zh'?'P 播放 · F 全屏':'P play · F fullscreen';
    $('language-switch').setAttribute('aria-label',lang==='zh'?'选择语言':'Choose language');
    document.querySelectorAll('[data-language]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.language===lang)));
    window.PlasmaNavigation?.setLanguage(lang);
    $('previous-lesson').textContent=lang==='zh'?'上一课':'Prev lesson';$('next-lesson').textContent=lang==='zh'?'下一课':'Next lesson';$('lesson-index').textContent=lang==='zh'?'课程目录':'Contents';
    $('return-link').setAttribute('aria-label',lang==='zh'?'返回等离子体波课堂':'Return to the plasma waves course');
    canvas.setAttribute('aria-label',tr(slide.lead)+' '+noteDensity+' '+(lang==='zh'?'曲线表示密度扰动；下方点阵显示相同的密度变化。':'The curve shows the density perturbation; the dots below display the same density variation.'));canvas.textContent=canvas.getAttribute('aria-label');
    comparison.setAttribute('aria-label',lang==='zh'?'第二种波长：k = 120 rad/m，与上图具有相同的冷电子振荡频率。':'Second wavelength: k = 120 rad/m, with the same cold oscillation frequency as the plot above.');
    save();sync();fit();chart();
    if(animate){
      if(changedSlide||reason==='page'){
        window.scrollTo({top:0,behavior:'instant'});$('title').focus({preventScroll:true});
      }else if(newest){
        const rect=newest.getBoundingClientRect(),bottom=document.querySelector('.controls').getBoundingClientRect().top;
        if(rect.top<0||rect.top+Math.min(rect.height,160)>bottom)
          newest.scrollIntoView({block:'start',behavior:'instant'});
      }
    }
    renderedSlide=slide.id;
  }
  function next(){if(s.build<current().blocks.length-1){s.build++;render('reveal');}else{s.slide=(s.slide+1)%slides.length;s.build=0;reset();render('page');}}
  function back(){if(s.build){s.build--;render('back');}else if(s.slide){s.slide--;s.build=current().blocks.length-1;reset();render('page');}}
  function restart(){s.build=0;reset();render('page');}
  function toggle(){if(running()){s.paused=!s.paused;last=null;sync();}}
  function setLanguage(value){lang=value==='en'?'en':'zh';try{localStorage.setItem('ap-doc-language',lang);}catch(_){}render('language');}
  const mint='#b5efcf',gold='#f4c583',blue='#b4cefa',white='#eef4f0';
  function fit(){
    if(!running())return;
    const dpr=Math.min(devicePixelRatio||1,2);
    for(const [surface,c] of [[canvas,ctx],[comparison,comparisonCtx]]){
      if(surface.hidden||!c)continue;
      const r=surface.getBoundingClientRect();if(!r.width||!r.height)continue;
      const w=Math.round(r.width*dpr),h=Math.round(r.height*dpr);
      if(surface.width!==w||surface.height!==h){surface.width=w;surface.height=h;}
      c.setTransform(dpr,0,0,dpr,0,0);
    }
    draw();
  }
  function draw(){
    if(!running())return;
    const time=s.time/M.W0,compact=current().id==='cold-result';
    function panel(surface,c,k){
      if(surface.hidden||!c)return;
      const width=surface.clientWidth,height=surface.clientHeight;if(!width||!height)return;
      c.clearRect(0,0,width,height);
      const line=(x1,y1,x2,y2)=>{c.beginPath();c.strokeStyle='#30413f';c.lineWidth=1;c.moveTo(x1,y1);c.lineTo(x2,y2);c.stroke();};
      const label=(value,x,y,color=white,size=23,align='left')=>PlasmaText.label(c,value,x,y,color,size,align);
      const left=68,right=width-20,span=right-left,mid=compact?72:110,amp=compact?28:47;
      label('k = '+k+' rad/m',8,24,mint,24);
      if(width>460)label('λ = '+(2*Math.PI/k).toFixed(3)+' m',right,24,white,22,'right');
      for(const value of [-.08,0,.08]){line(left,mid-amp*value/.08,right,mid-amp*value/.08);label(value?value.toFixed(2):'0',left-10,mid-amp*value/.08,white,22,'right');}
      c.beginPath();c.strokeStyle=mint;c.lineWidth=2.5;
      for(let i=0;i<=400;i++){const x=M.XMAX*i/400,y=mid-amp*M.sample(x,time,k).n1/(M.NREF*M.A);if(i)c.lineTo(left+i/400*span,y);else c.moveTo(left,y);}c.stroke();
      label('0',left,mid+amp+25,white,22,'center');label('0.24',right,mid+amp+25,white,22,'right');
      label('x [m]',right,mid+amp+54,white,22,'right');
      const top=compact?170:290,cols=Math.max(38,Math.floor(span/9));
      if(!compact)label(lang==='zh'?'电子密度点阵':'Electron density dots',8,260,mint,25);
      c.save();c.beginPath();c.rect(left,top-5,span,40);c.clip();
      for(let j=-3;j<=cols+3;j++){const q=j/cols*M.XMAX,x=left+M.position(q,time,k)/M.XMAX*span;for(let r=0;r<3;r++){c.beginPath();c.fillStyle=mint;c.arc(x,top+r*13,Math.min(3.3,span/cols*.3),0,2*Math.PI);c.fill();}}c.restore();
    }
    panel(canvas,ctx,60);panel(comparison,comparisonCtx,120);
  }
  function chart(){
    if(current().visual!=='dispersion')return;const svg=$('lesson-chart'),w=svg.clientWidth,h=svg.clientHeight;if(!w||!h)return;
    const key=[w,h,s.factor,s.warm,lang].join(':');if(key===chartKey)return;chartKey=key;
    const l=w<400?78:90,r=w-25,t=60,b=h-75,x=k=>l+k/120*(r-l),y=omega=>b-omega/2.6e8*(b-t);
    const add=(tag,attrs,value)=>{const n=document.createElementNS('http://www.w3.org/2000/svg',tag);for(const[k,v]of Object.entries(attrs))n.setAttribute(k,String(v));if(value!==undefined)n.textContent=value;svg.append(n);return n;};
    const ln=(x1,y1,x2,y2,cls)=>add('line',{x1,y1,x2,y2,class:cls});
    const txt=(v,x,y,a='middle')=>add('text',{x,y,'text-anchor':a},v);
    svg.setAttribute('viewBox','0 0 '+w+' '+h);svg.replaceChildren();ln(l,b,r,b,'packet-axis');ln(l,b,l,t-8,'packet-axis');
    txt('ω [rad/s]',l,28,'start');txt('k [rad/m]',r,h-8,'end');
    for(const k of [0,60,120]){ln(x(k),b,x(k),b+7,'packet-axis');txt(k,x(k),b+32,k===120?'end':'middle');}
    for(const v of [1e8,2e8]){ln(l,y(v),r,y(v),'packet-guide');txt(v===1e8?'10⁸':'2×10⁸',l-10,y(v)+7,'end');}
    const n=s.factor*M.NREF,u=s.warm?1e6:0;
    if(s.warm)ln(l,y(M.plasmaFrequency(n)),r,y(M.plasmaFrequency(n)),'packet-tangent');
    add('polyline',{points:Array.from({length:121},(_,k)=>x(k)+','+y(M.omega(k,n,u))).join(' '),class:'packet-branch'});
    svg.setAttribute('aria-label',(lang==='zh'?'色散关系；':'Dispersion relation; ')+'k [rad/m], ω [rad/s]; n₀ = '+n+' m⁻³; u = '+u+' m/s.');
  }
  function frame(now){const dt=last===null?0:Math.min((now-last)/1000,.05);last=now;if(!document.hidden&&!s.paused&&running()){s.time=(s.time+dt*3)%(2*Math.PI);sync();draw();}requestAnimationFrame(frame);}
  $('advance').addEventListener('click',next);$('back').addEventListener('click',back);
  $('restart-slide').addEventListener('click',restart);$('restart-lesson').addEventListener('click',()=>{s.slide=0;restart();});
  $('motion').addEventListener('click',toggle);
  $('packet-time').addEventListener('input',e=>{s.time=Number(e.target.value);s.paused=true;sync();draw();});
  $('density-factor').addEventListener('input',e=>{s.factor=Number(e.target.value);render();});
  $('warm-branch').addEventListener('change',e=>{s.warm=e.target.checked;render();});
  document.querySelectorAll('[data-language]').forEach(b=>b.addEventListener('click',()=>setLanguage(b.dataset.language)));
  document.addEventListener('keydown',async e=>{
    if(e.altKey||e.ctrlKey||e.metaKey||e.shiftKey||e.repeat||e.target.closest('input,textarea,select,[contenteditable]'))return;
    if(e.key.toLowerCase()==='p'){e.preventDefault();toggle();}
    if(e.key.toLowerCase()==='f'){e.preventDefault();try{if(document.fullscreenElement)await document.exitFullscreen();else await document.documentElement.requestFullscreen();}catch(_){$('toast').textContent=lang==='zh'?'当前预览不允许全屏。':'Fullscreen is unavailable here.';$('toast').hidden=false;setTimeout(()=>{$('toast').hidden=true;},3500);}}
  });
  reduced.addEventListener('change',e=>{if(e.matches){s.paused=true;sync();}});
  document.addEventListener('visibilitychange',()=>{last=null;});
  window.addEventListener('hashchange',()=>{readHash();render('page');});
  document.addEventListener('animationend',e=>{if(e.animationName==='derivation-appear')e.target.classList.remove('content-enter');});
  new ResizeObserver(fit).observe(canvas);new ResizeObserver(fit).observe(comparison);new ResizeObserver(chart).observe($('lesson-chart'));
  let initial=new URLSearchParams(location.search).get('lang');if(!['zh','en'].includes(initial)){try{initial=localStorage.getItem('ap-doc-language');}catch(_){}}
  lang=initial==='en'?'en':'zh';readHash();render('initial');requestAnimationFrame(frame);
})();

/* Plasma-wave contribution history (Git author dates; edit time includes timezone).
 * 2026-11-19 11:06 +08:00 | Yinjian Zhao | git 3242c1a909ef
 * 2026-11-19 11:30 +08:00 | Yinjian Zhao | git 98d8d1aa51e6
 * 2026-11-19 13:47 +08:00 | Yinjian Zhao | git cec49a30b3bd
 * 2026-11-19 16:01 +08:00 | Yinjian Zhao | git 2113cbc05ed4
 * 2026-11-19 16:28 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */
