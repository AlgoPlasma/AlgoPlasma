#!/usr/bin/env python3
"""Run the Fortran benchmark and produce CSV-backed figures and a Chinese report."""
from pathlib import Path
import argparse
import csv
import json
import os
import subprocess
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SCHEMES = ['uniform', 'power2', 'piecewise']
LABELS = {'uniform': 'Uniform', 'power2': 'Quadratic edges', 'piecewise': 'Piecewise edges'}
COLORS = {'uniform': '#64748b', 'power2': '#2563eb', 'piecewise': '#d97706'}


def read_csv(path):
    with path.open() as stream:
        return list(csv.DictReader(stream))


def number(row, key):
    return float(row[key])


def select(rows, scheme, count, case=None):
    return next(r for r in rows if r['scheme'] == scheme and int(r['n_speeds']) == count
                and (case is None or r['case'] == case))


def relative(row, key):
    return abs(number(row, key) / number(row, key + '_exact') - 1)


def grid(scheme, n):
    if scheme == 'uniform':
        return np.linspace(0, 16000, n + 1)
    if scheme == 'power2':
        return 16000 * np.linspace(0, 1, n + 1)**2
    knots = [0, 1600, 9000, 15000, 16000]
    return np.concatenate([np.linspace(a, b, c * (n // 16) + 1)[:-1]
                           for a, b, c in zip(knots[:-1], knots[1:], [8, 2, 5, 1])] + [[16000]])


def analyze(out):
    moments = read_csv(out / 'moments.csv')
    transport = read_csv(out / 'transport.csv')
    controls = read_csv(out / 'angle_cutoff.csv')
    assert len(moments) == 54 and len(transport) == 21 and len(controls) == 21
    for rows in [moments, transport, controls]:
        for row in rows:
            for key, value in row.items():
                if key not in ['scheme', 'case', 'study']:
                    assert np.isfinite(float(value)), (key, value)
    assert max(number(r, 'balance') for r in transport) < 1e-10
    for scheme in SCHEMES:
        for case in ['cold', 'fast', 'mixture']:
            r = select(moments, scheme, 512, case)
            assert max(relative(r, k) for k in ['density', 'jz', 'v2', 'forward_flux']) < 1e-3
    ref_check = next(r for r in transport if r['scheme'] == 'reference_check')
    plt.rcParams.update({'font.size': 10, 'axes.spines.top': False, 'axes.spines.right': False,
                         'figure.facecolor': 'white', 'savefig.facecolor': 'white'})
    fig, axes = plt.subplots(2, 2, figsize=(10.8, 7.4), constrained_layout=True)
    for ax, case, key, title in [
        (axes[0, 0], 'cold', 'density', '(a) Cold component: density'),
        (axes[0, 1], 'fast', 'density', '(b) Fast component: density'),
        (axes[1, 0], 'mixture', 'v2', '(c) Mixture: raw second velocity moment')]:
        for scheme in SCHEMES:
            rows = [r for r in moments if r['scheme'] == scheme and r['case'] == case]
            ax.loglog([int(r['n_speeds']) for r in rows],
                      [max(relative(r, key), 1e-16) * 100 for r in rows],
                      'o-', color=COLORS[scheme], label=LABELS[scheme], markersize=4)
        ax.set_title(title, loc='left')
        ax.set_ylabel('Relative error (%)')
    ax = axes[1, 1]
    for scheme in SCHEMES:
        rows = [r for r in transport if r['scheme'] == scheme]
        ax.loglog([int(r['n_speeds']) for r in rows],
                  [number(r, 'density_L1') * 100 for r in rows],
                  'o-', color=COLORS[scheme], label=LABELS[scheme], markersize=4)
    reference_percent = number(ref_check, 'density_L1') * 100
    ax.axhline(reference_percent, color='#991b1b', linestyle=':', linewidth=1.2)
    ax.text(18, reference_percent*1.3, '8192 to 16384: reference change', fontsize=8, color='#991b1b')
    ax.set_title('(d) Open channel: density field', loc='left')
    ax.set_ylabel('Volume-weighted relative L1 error (%)')
    for ax in axes.flat:
        ax.set_xlabel('Number of speed groups')
        ax.set_xticks([16, 32, 64, 128, 256, 512], ['16', '32', '64', '128', '256', '512'])
        ax.grid(True, which='major', color='#e2e8f0', linewidth=.6)
    axes[0, 0].legend(frameon=False, fontsize=9)
    fig.suptitle('Nonuniform speed groups: fixed cutoff at 16 km/s\n(a-c): 512 angles; (d): 128 angles on the same 2 x 6 mesh', fontsize=12)
    fig.savefig(out / 'convergence.png', dpi=180)
    fig.savefig(out / 'convergence.svg')
    plt.close(fig)
    fig, axes = plt.subplots(4, 1, figsize=(10.8, 5.8), sharex=True,
                              gridspec_kw={'height_ratios': [2, 1, 1, 1]}, constrained_layout=True)
    v = np.linspace(0, 16000, 4001)
    cold_sigma = np.sqrt(1.380649e-23 * 550 / 2.18017e-25)
    for fraction, drift, thermal, color, label in [
        (.9, 300, cold_sigma, '#2563eb', '90% cold component'),
        (.1, 12000, 600, '#d97706', '10% fast component')]:
        radial_pdf = fraction * v / thermal**2 * np.exp(-(v*v+drift*drift)/(2*thermal**2)) \
            * np.i0(v*drift/thermal**2)
        axes[0].plot(v/1000, radial_pdf*1000, color=color, label=label)
    axes[0].set_ylabel('Speed PDF\n(per km/s)')
    axes[0].set_yscale('log'); axes[0].set_ylim(1e-6, 5)
    axes[0].legend(frameon=False, loc='upper center', ncol=2)
    for ax, scheme in zip(axes[1:], SCHEMES):
        e = grid(scheme, 32) / 1000
        ax.vlines(e, 0, 1, color=COLORS[scheme], linewidth=.7)
        ax.scatter((e[1:]+e[:-1])/2, np.full(32, .5), s=8, color=COLORS[scheme])
        ax.set_ylim(0, 1); ax.set_yticks([]); ax.set_ylabel(LABELS[scheme], rotation=0, ha='right', va='center')
    axes[-1].set_xlabel('Speed (km/s)')
    axes[-1].set_xlim(0, 16)
    fig.suptitle('Same 32 groups; edges and midpoint nodes', fontsize=14)
    fig.savefig(out / 'speed_grids.png', dpi=180)
    fig.savefig(out / 'speed_grids.svg')
    plt.close(fig)
    lines = [
        '# J02 非均匀速率分组对比', '',
        '本实验扩展 AlgoPlasma 的 J02 速度求积；没有加入 CEX 碰撞。所有分布均属于当前二维速度约化模型。', '',
        '## 接口与公式', '',
        '新增 `sub_J02_build_speed_groups_from_edges` 和 `sub_J02_build_phase_quadrature_from_edges`。'
        '输入从零开始、有限且严格递增的速率边界。节点为算术中点，权重为 '
        '`W_g = (v_hi-v_lo)*(v_hi+v_lo)/2`，即对 `v dv` 精确积分；对分布的中点近似仍有误差。'
        '角度规则、速度组内排列和原等宽接口保持兼容。', '',
        '```fortran',
        "call sub_J02_build_phase_quadrature_from_edges(128, speed_edge, 'midpoint', quad, ierr)",
        '```', '',
        '## 对比条件', '',
        '- 截断上限统一为 16000 m/s；速率组数为 16、32、64、128、256、512。',
        '- 原始矩积分使用 512 个角度，未经离散密度或通量归一化，参考值取无限二维速度平面的解析积分。',
        '- 冷分布：Xe 质量 2.18017e-25 kg、550 K、轴向漂移 300 m/s。',
        '- 快分布：轴向漂移 12000 m/s、每个速度分量的热标准差 600 m/s。',
        '- 混合分布：90% 冷分布、10% 快分布，比例按粒子数定义。',
        '- `uniform`：等宽；`power2`：边界 v_i=16000*(i/N)^2；`piecewise`：'
        '[0,1600,9000,15000,16000] m/s 四段，组数按 8:2:5:1 分配。',
        '- 非均匀分组策略由应用指定；库不预设“最佳网格”。分段位置使用了本实验的分布信息。', '',
        '![分组位置](speed_grids.png)', '',
        '## 32 组时的结果', '',
        '| 分组 | 冷分布密度误差 | 快分布密度误差 | 混合分布二阶矩误差 | 通道密度场误差 |',
        '|---|---:|---:|---:|---:|'
    ]
    zh = {'uniform': '等宽', 'power2': '二次幂边界', 'piecewise': '分段等宽'}
    for scheme in SCHEMES:
        c = select(moments, scheme, 32, 'cold'); f = select(moments, scheme, 32, 'fast')
        m = select(moments, scheme, 32, 'mixture'); t = select(transport, scheme, 32)
        lines.append(f"| {zh[scheme]} | {relative(c,'density')*100:.6g}% | {relative(f,'density')*100:.6g}% | "
                     f"{relative(m,'v2')*100:.6g}% | {number(t,'density_L1')*100:.6g}% |")
    angle = next(r for r in transport if r['scheme'] == 'angle_check')
    lines += ['',
        '在这个跨越冷、快两个速度尺度的算例中，两种非均匀分组都改善了小组数下的综合精度。'
        '二次幂边界在 32 组时的冷分布密度更准确，分段网格的快分布及此通道密度场更准确。'
        '不能据此认定某种非均匀方案对所有分布、所有观测量都更优。', '',
        '![误差收敛](convergence.png)', '',
        '二阶矩为原始积分 ∫v²f d²v；乘以 m/2 即得到本二维速度模型的动能密度。'
        'CSV 同时保存密度、轴向流密度、二阶矩和正轴向半空间通量。'
        '混合分布误差可能存在抵消，故同时报告冷、快分量。', '',
        '## 输运验证及参考解', '',
        '输运比较使用 2×6 的开放环形通道，r=0.015–0.025 m、z=0–0.04 m，'
        '固定损失频率 2e4 s⁻¹，全部方案使用 128 个角度及单位入口粒子数通量密度。'
        '本测试包含速度相关的 nu/v 吸收，但不包含 CEX。密度误差按柱坐标单元体积加权 L1 计算。', '',
        '参考解使用相同空间网格及角度规则、16384 个等宽速率组。'
        f"8192 与 16384 组的密度场相对差为 {number(ref_check,'density_L1'):.6e}。"
        '该差值只量化此次参考解细化变化，不是严格误差上界。', '',
        f"所有通道算例的最大相对粒子收支误差为 {max(number(r,'balance') for r in transport):.6e}。", '',
        '独立将分段 512 组的角度数从 128 增到 256 后，'
        f"所得场与上述 128 角度参考解的差为 {number(angle,'density_L1'):.6e}。"
        '因此小的速率离散误差不能解释为完整输运解已经收敛；角度和空间误差仍需独立检查。'
        '本轮目的在于隔离速率分组的影响，不评价大型应用精度或并行加速比。', '',
        '## 角度与截断检查', '',
        '`angle_cutoff.csv` 保存 128/256/512/1024 个角度的原始矩检查，以及 '
        '4096 等宽速率组下 14000/16000/18000 m/s 上限的检查。'
        '提高组数不能补回截断域之外的粒子。快分布低误差处也需区分尾部截断与离散误差。', '',
        '## 可重复运行', '',
        '```bash',
        'python3 tests/012_fluid/J02_neutral_sn_transport_2Drz/nonuniform_speed/run_comparison.py --output /path/to/output',
        '```', '',
        '依赖 GNU Fortran、Python、NumPy、Matplotlib。输出目录保留源码编译日志、原始 CSV、PNG/SVG 和本报告。'
        '默认输出到独立的 `build/nonuniform_speed` 子目录，不清理已有应用输出。', ''
    ]
    if (out / 'validation.md').exists():
        lines += ['## 模块回归与已知限制', '', '[查看本次验证记录](validation.md)，包括极粗两组下的壁面迭代不收敛记录。', '']
    (out / 'report.md').write_text('\n'.join(lines), encoding='utf-8')
    metrics = {'transport_reference_groups': 16384,
               'transport_reference_refinement_L1': number(ref_check, 'density_L1'),
               'max_transport_balance': max(number(r, 'balance') for r in transport),
               'scope': 'Reduced 2D velocity quadrature; no CEX; fixed spatial grid for transport comparison'}
    (out / 'summary.json').write_text(json.dumps(metrics, indent=2), encoding='utf-8')
    print(out / 'report.md')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, default=HERE.parent / 'build/nonuniform_speed')
    parser.add_argument('--analyze-only', action='store_true')
    args = parser.parse_args()
    out = args.output.resolve(); out.mkdir(parents=True, exist_ok=True)
    if not args.analyze_only:
        build = out / 'compile'; build.mkdir(exist_ok=True)
        source = ROOT / 'J_Fluid/J02_neutral_sn_transport_2Drz'
        flags = ['-cpp', '-O2', '-std=f2008', '-fdefault-real-8', '-fcheck=all', '-fbacktrace',
                 '-ffpe-trap=invalid,zero,overflow', '-Wall', '-Wextra']
        fc = os.environ.get('FC', 'gfortran')
        with (out / 'compile.log').open('w') as log:
            subprocess.run([fc, *flags, '-I'+str(source), '-J'+str(build), '-c',
                            str(source / 'mod_J02_neutral_sn_transport_2Drz.f90'), '-o', str(build / 'module.o')],
                           stdout=log, stderr=log, check=True)
            subprocess.run([fc, *flags, '-I'+str(build), '-J'+str(build), str(HERE / 'compare_speed_grids.f90'),
                            str(build / 'module.o'), '-o', str(build / 'compare.out')],
                           stdout=log, stderr=log, check=True)
        with (out / 'run.log').open('w') as log:
            subprocess.run([str(build / 'compare.out'), str(out)], stdout=log, stderr=log, check=True)
    analyze(out)


if __name__ == '__main__':
    main()
