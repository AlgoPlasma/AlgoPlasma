"""Record unittest measurements and publish a reproducible documentation snapshot."""
import argparse
from contextlib import contextmanager
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import platform
import re
import shutil
import subprocess
import unittest
import numpy as np

ROOT = Path(__file__).resolve().parents[4]
CASE = Path(__file__).resolve().parents[1]
TITLES = {
    'test_variance_weights_resolve_conflicting_observations': ('相位方差权重', 'Phase-variance weights'),
    'test_psd_units_and_endpoint_scaling': ('PSD 单位与端点', 'PSD units and endpoints'),
    'test_coherence_known_complex_pairs': ('相干度解析对照', 'Analytic coherence checks'),
    'test_reject_invalid_beall_baselines': ('拒绝非法基线', 'Reject invalid baselines'),
    'test_liu_returns_mode_not_arithmetic_or_circular_mean': ('众数相位统计', 'Histogram-mode statistics'),
    'test_branch_cut': ('跨越相位边界', 'Phase branch cut'),
    'test_missing_and_noiseless': ('缺失与无噪声样本', 'Missing and noiseless samples'),
    'test_beall_auto_power_changes_peak': ('Beall 功率权重', 'Beall power weights'),
    'test_no_beall_peak_without_phase': ('无有效相位的谱', 'Spectrum without valid phase'),
    'test_full_grid_matches_dense_reference_for_any_block_size': ('分块网格一致性', 'Blocked-grid agreement'),
    'test_alias_requires_grid_resolution_not_local_refinement': ('网格分辨率', 'Grid resolution'),
    'test_equal_length_baselines_can_resolve_alias': ('等长多方向基线', 'Equal-length baselines'),
    'test_different_lengths_do_not_guarantee_unique_alias': ('共同混叠周期', 'Common alias period'),
    'test_invalid_and_collinear_constraints': ('有效二维约束', 'Valid 2D constraints'),
    'test_leakage_can_bias_real_signal_phase': ('非整周期记录', 'Off-bin records'),
    'test_window_psd_normalization': ('窗口功率归一化', 'Window-power normalization'),
}

LABELS = {
    'test_variance_weights_resolve_conflicting_observations': ['加权波矢 / Weighted wavevector', '加权峰值评分 / Weighted peak score', '稠密评分解析对照 / Analytic dense score', '等权对照 / Equal-weight control'],
    'test_psd_units_and_endpoint_scaling': [f'N={n}, fs={fs} Hz: {q}' for n in [63, 64] for fs in [1000, 2000] for q in ['端点积分功率 / Endpoint power', '总积分功率 / Total power']],
    'test_coherence_known_complex_pairs': ['相干与相消 / Coherent and cancelling', '幅度缩放不变性 / Amplitude invariance'],
    'test_reject_invalid_beall_baselines': [f'{chi}: {q}' for chi in ['zero', 'NaN', 'Inf'] for q in ['length rejects', 'Beall rejects']],
    'test_liu_returns_mode_not_arithmetic_or_circular_mean': ['众数格中心 / Modal bin center (rad)', '相位方差 / Variance (rad²)'],
    'test_branch_cut': ['众数格中心 / Modal bin center (rad)', '方差 / Variance (rad²)'],
    'test_missing_and_noiseless': ['零互谱统计量均为 NaN / All zero-cross statistics NaN', '无噪声方差 / Noiseless variance (rad²)', '部分有效样本的标记 / Partial-data validity'],
    'test_beall_auto_power_changes_peak': ['自功率权重 / Auto-power weights', '自功率谱峰 / Auto-power peak (rad/m)', '互谱幅值谱峰 / Cross-magnitude peak (rad/m)', '自功率逐格谱值 / Auto-power spectrum', '互谱幅值逐格谱值 / Cross-magnitude spectrum'],
    'test_no_beall_peak_without_phase': ['谱峰为 NaN / Peak is NaN'],
    'test_full_grid_matches_dense_reference_for_any_block_size': [f'{rows} 行/批：{quantity}' for rows in [1, 7, 100] for quantity in ['波矢 / Wavevector (rad/m)', '似然 / Log likelihood']],
    'test_alias_requires_grid_resolution_not_local_refinement': ['401 点 kx 误差 / kx error (rad/m)', '4001 点 kx 误差 / kx error (rad/m)', '4001 点 ky / ky (rad/m)'],
    'test_equal_length_baselines_can_resolve_alias': ['恢复波矢 / Recovered wavevector (rad/m)'],
    'test_different_lengths_do_not_guarantee_unique_alias': ['各基线包裹相位差 / Wrapped differences (rad)'],
    'test_invalid_and_collinear_constraints': ['空构型 / Empty', '单基线 / One baseline', '共线 / Collinear', '缺失相位 / Missing phase', '无限方差 / Infinite variance', '剔除无效构型后的结果 / Filtered result'],
    'test_leakage_can_bias_real_signal_phase': ['1.25 周期相位：直接 DFT 参考 / Off-bin phase: direct DFT (rad)', '2 周期相位：直接 DFT 参考 / On-bin phase: direct DFT (rad)', '2 周期相位：解析参考 / On-bin phase: analytic (rad)'],
    'test_window_psd_normalization': ['矩形窗积分功率 / Boxcar power', 'Hann 窗积分功率 / Hann power'],
}

def serial(value):
    if isinstance(value, np.ndarray):
        return serial(value.tolist())
    if isinstance(value, np.generic):
        return serial(value.item())
    if isinstance(value, float) and not np.isfinite(value):
        return str(value)
    if isinstance(value, dict):
        return {str(k): serial(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [serial(v) for v in value]
    return value

def display(value):
    value = serial(value)
    if isinstance(value, float):
        return f'{value:.8g}'
    if isinstance(value, list):
        return '[' + ', '.join(display(v) for v in value) + ']'
    if isinstance(value, dict):
        return '{' + ', '.join(f'{k}: {display(v)}' for k, v in value.items()) + '}'
    return str(value)

def table_value(value):
    if isinstance(value, dict) and 'kx' in value:
        return f"{len(value)} fields; kx={display(value['kx'])}, ky={display(value['ky'])}, logL={display(value['peak_log_likelihood'])}"
    return display(value)

class RecordedCase(unittest.TestCase):
    def setUp(self):
        self.inputs, self.observed, self.arrays, self.measurements = {}, {}, {}, []

    def _record_assert(self, method, actual, expected, criterion, *args, **kwargs):
        entry = dict(actual=serial(actual), expected=serial(expected), criterion=criterion)
        try:
            a, b = np.asarray(actual, dtype=float), np.asarray(expected, dtype=float)
            if method in {'assertEqual', 'assertAlmostEqual'}:
                entry['max_abs_error'] = float(np.max(np.abs(a-b)))
        except (TypeError, ValueError):
            pass
        self.measurements.append(entry)
        try:
            getattr(super(), method)(actual, expected, *args, **kwargs)
        except Exception:
            entry['passed'] = False
            raise
        entry['passed'] = True

    def assertAlmostEqual(self, actual, expected, *args, **kwargs):
        return self._record_assert('assertAlmostEqual', actual, expected,
                                   'round(abs(error), 7) == 0', *args, **kwargs)

    def assertEqual(self, actual, expected, *args, **kwargs):
        return self._record_assert('assertEqual', actual, expected, 'equal', *args, **kwargs)

    def assertLess(self, actual, expected, *args, **kwargs):
        return self._record_assert('assertLess', actual, expected, 'actual < limit', *args, **kwargs)

    def assertGreater(self, actual, expected, *args, **kwargs):
        return self._record_assert('assertGreater', actual, expected, 'actual > limit', *args, **kwargs)

    def assertTrue(self, actual, *args, **kwargs):
        entry = dict(actual=bool(actual), expected=True, criterion='true')
        self.measurements.append(entry)
        try:
            super().assertTrue(actual, *args, **kwargs)
        except Exception:
            entry['passed'] = False
            raise
        entry['passed'] = True

    @contextmanager
    def assertRaises(self, exception):
        entry = dict(expected=exception.__name__, criterion='exception type')
        self.measurements.append(entry)
        try:
            yield
        except exception as error:
            entry.update(actual=type(error).__name__, passed=True)
        except Exception as error:
            entry.update(actual=type(error).__name__, passed=False)
            raise
        else:
            entry.update(actual='no exception', passed=False)
            self.fail('Expected ' + exception.__name__)

    def array_close(self, actual, expected, rtol=1e-7, atol=0):
        entry = dict(actual=serial(actual), expected=serial(expected),
                     max_abs_error=float(np.max(np.abs(np.asarray(actual)-expected))),
                     atol=float(atol), rtol=float(rtol),
                     criterion=f'abs(error) <= {atol:.17g} + {rtol:.17g}*abs(reference)')
        self.measurements.append(entry)
        try:
            np.testing.assert_allclose(actual, expected, rtol=rtol, atol=atol, equal_nan=False)
        except Exception:
            entry['passed'] = False
            raise
        entry['passed'] = True

class Result(unittest.TextTestResult):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.records = []
        self.data = {}

    def capture(self, test, status, error=None):
        name = test._testMethodName
        record = dict(id=name, title_zh=TITLES[name][0], title_en=TITLES[name][1],
                      status=status, inputs=serial(test.inputs),
                      observed=serial(test.observed), checks=serial(test.measurements))
        for label, metric in zip(LABELS[name], record['checks']):
            metric['quantity'] = label
        if error:
            record['error'] = self._exc_info_to_string(error, test)
        if test.arrays:
            record['data_file'] = f'details/{name}.npz'
            self.data[name] = test.arrays
        self.records.append(record)

    def addSuccess(self, test):
        super().addSuccess(test)
        self.capture(test, 'PASS')

    def addFailure(self, test, error):
        super().addFailure(test, error)
        self.capture(test, 'FAIL', error)

    def addError(self, test, error):
        super().addError(test, error)
        self.capture(test, 'ERROR', error)

def provenance():
    import matplotlib
    paths = sorted((ROOT/'K_Diagnostics').rglob('*.py'))
    paths += sorted((CASE/'source_py').glob('*.py'))
    paths += [CASE/'run.sh', CASE/'clean.sh']
    return dict(generated_at_utc=datetime.now(timezone.utc).isoformat(),
                git_head=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                python=platform.python_version(), numpy=np.__version__, matplotlib=matplotlib.__version__,
                execution='deterministic small synthetic cases; vectorized grids; one worker',
                source_sha256={str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},
                note='Source hashes identify the tested working-tree files, including uncommitted changes.')

def write_rst(summary, outdir):
    lines = [':orphan:', '', '.. result-table', '',
             '.. rubric:: 运行结果 / Run results', '',
             f"通过 / Passed: {sum(r['status']=='PASS' for r in summary['tests'])}/{len(summary['tests'])}.", '',
             '.. list-table:: 测试总表 / Test summary', '   :header-rows: 1', '',
             '   * - 序号 / No.', '     - 测试 / Test', '     - 状态 / Status']
    for number, row in enumerate(summary['tests'], start=1):
        lines += [f"   * - {number}", f"     - {row['title_zh']} / {row['title_en']}", f"     - {row['status']}"]
    for number, row in enumerate(summary['tests'], start=1):
        lines += ['', f".. rubric:: {number}. {row['title_zh']} / {row['title_en']}", '',
                  '输入 / Input::', '', '   '+display(row['inputs']), '']
        if row['observed']:
            lines += ['计算量 / Measurements::', '', '   '+display(row['observed']), '']
        lines += ['.. list-table:: 数值与行为检查 / Numerical and behavior checks',
                  '   :header-rows: 1', '', '   * - 计算量 / Quantity', '     - 实际 / Actual', '     - 参考或界限 / Reference or limit',
                  '     - 判据 / Criterion', '     - 最大绝对差 / Max absolute difference', '     - 状态 / Status']
        for metric in row['checks']:
            lines += ['   * - '+metric.get('quantity', 'Check'), '     - '+table_value(metric.get('actual')), '     - '+table_value(metric['expected']),
                      '     - '+metric['criterion'], '     - '+display(metric.get('max_abs_error', 'n/a')),
                      '     - '+('PASS' if metric.get('passed') else 'FAIL')]
        if row.get('error'):
            lines += ['', '异常 / Error::', ''] + ['   '+s for s in row['error'].splitlines()]
    lines += ['', '“最大绝对差”用于相等性比较；不等式检查直接比较实际值与界限。',
              'Max absolute difference is an equality diagnostic; inequality checks use the stated limit.',
              '表格数值显示 8 位有效数字；字典比较展示主要字段，完整精度与全部字段见 summary.json。',
              'Tables show eight significant digits and key dictionary fields; summary.json retains full values.', '']
    (outdir/'results.rst').write_text('\n'.join(lines), encoding='utf-8')


# Select recorded assertions for the reader-facing page. Numerical values,
# tolerances and statuses always come from the same report as the full table.
FOCUSED_CHECKS = {
    'spectrum': [
        ('window_psd_normalization', 0, '矩形窗积分功率', 'Boxcar integrated power'),
        ('window_psd_normalization', 1, 'Hann 窗积分功率', 'Hann integrated power'),
        ('leakage_can_bias_real_signal_phase', 0, '1.25 周期相位：直接 DFT / °', 'Off-bin phase: direct DFT / °'),
        ('leakage_can_bias_real_signal_phase', 1, '2 周期相位：直接 DFT / °', 'On-bin phase: direct DFT / °'),
        ('leakage_can_bias_real_signal_phase', 2, '2 周期相位：解析参考 / °', 'On-bin phase: analytic / °'),
    ],
    'phase': [
        ('liu_returns_mode_not_arithmetic_or_circular_mean', 0, '案例 A：众数格中心 / °', 'Case A: modal bin center / °'),
        ('liu_returns_mode_not_arithmetic_or_circular_mean', 1, '案例 A：样本方差 / °²', 'Case A: sample variance / °²'),
        ('branch_cut', 0, '案例 B：众数格中心 / °', 'Case B: modal bin center / °'),
        ('branch_cut', 1, '案例 B：样本方差 / °²', 'Case B: sample variance / °²'),
    ],
    'beall': [
        ('beall_auto_power_changes_peak', 0, '规定权重：平均自功率', 'Required weight: mean auto-power'),
        ('beall_auto_power_changes_peak', 3, '规定权重：逐格谱值', 'Required weight: bin values'),
        ('beall_auto_power_changes_peak', 1, '规定权重：谱峰 / rad m⁻¹', 'Required weight: peak / rad m⁻¹'),
        ('beall_auto_power_changes_peak', 4, '误用对照：逐格谱值', 'Misuse control: bin values'),
        ('beall_auto_power_changes_peak', 2, '误用对照：谱峰 / rad m⁻¹', 'Misuse control: peak / rad m⁻¹'),
    ],
}

GROUP_CONCLUSIONS = {
    'spectrum': ('这组输入的窗口功率归一化和互相位均符合参考计算。',
                 'Window-power normalization and cross phases agree with the references for these inputs.'),
    'phase': ('两个独立案例的众数格中心与样本方差均符合手算参考，包括跨越 ±180° 的样本。',
              'Modal bin centers and sample variances match the hand calculations, including the branch-cut case.'),
    'beall': ('规定权重的谱值与峰位符合手算参考；误用对照得到不同峰位，也符合其对照参考。',
              'The required weight gives the reference spectrum and peak; the misuse control gives a different peak matching its own reference.'),

}


def focused_metric(name, index, metric):
    """Convert phase display only; preserve recorded radians and pass/fail decisions.

    Scaling the absolute error and tolerance alongside both compared values keeps
    the displayed inequality equivalent. Relative tolerances are dimensionless.
    """
    factor = 1.0
    if name in ('liu_returns_mode_not_arithmetic_or_circular_mean', 'branch_cut'):
        factor = (180 / np.pi)**(2 if index == 1 else 1)
    elif name == 'leakage_can_bias_real_signal_phase':
        factor = 180 / np.pi
    converted = dict(metric)
    if factor != 1:
        for key in ('actual', 'expected', 'max_abs_error'):
            if key in metric:
                converted[key] = serial(np.asarray(metric[key], dtype=float) * factor)
        converted['atol'] = metric['atol'] * factor
        converted['criterion'] = (f'abs(error) <= {converted["atol"]:.17g} + '
                                  f'{metric["rtol"]:.17g}*abs(reference)')
    return converted


def group_outcome(records, selectors, language):
    """Never infer group success from a partial set of successful assertions."""
    failed, missing = [], []
    for name, index, title_zh, title_en in selectors:
        row = records.get('test_' + name, {})
        title = title_zh if language == 'zh' else title_en
        checks = row.get('checks', [])
        if index >= len(checks):
            missing.append(title)
        elif not checks[index].get('passed'):
            failed.append(title)
    # A selected assertion may pass before a later assertion/error fails its test.
    failed_tests = sorted({name for name, *_ in selectors
                           if records.get('test_' + name, {}).get('status') in ('FAIL', 'ERROR')})
    incomplete_tests = {name for name, *_ in selectors
                        if records.get('test_' + name, {}).get('status') != 'PASS'}
    if failed or failed_tests:
        details = failed or [TITLES['test_' + name][0 if language == 'zh' else 1] for name in failed_tests]
        return 'FAIL', ('未满足预期：' if language == 'zh' else 'Unmet expectations: ') + '；'.join(details)
    if missing or incomplete_tests:
        return 'NOT RUN', ('检查尚未全部完成，不能判定通过。' if language == 'zh' else
                           'Checks are incomplete; success cannot be concluded.')
    return 'PASS', ''


def short_criterion(metric, language):
    """Compact display of the recorded rule, without introducing new tolerances."""
    criterion = metric['criterion']
    if criterion == 'round(abs(error), 7) == 0':
        return '差值按 7 位小数舍入为 0' if language == 'zh' else 'Round error to 7 decimals: 0'
    if criterion == 'equal':
        return '相等' if language == 'zh' else 'Equal'
    if criterion == 'exception type':
        return '异常类型一致' if language == 'zh' else 'Same exception type'
    if criterion in ('actual < limit', 'actual > limit'):
        sign = '<' if '<' in criterion else '>'
        return f'{sign} {display(metric["expected"])}'
    match = re.fullmatch(r'abs\(error\) <= (\S+) \+ (\S+)\*abs\(reference\)', criterion)
    if match:
        absolute, relative = match.groups()
        return f'atol={display(float(absolute))}; rtol={display(float(relative))}'
    return criterion


def write_focused_rst(summary, outdir):
    """Write bilingual, includable result tables directly from captured checks."""
    records = {r['id']: r for r in summary['tests']}
    for language in ('zh', 'en'):
        zh = language == 'zh'
        lines = [':orphan:', '', '.. checks-overview-start', '',
                 ('下表由同次运行记录自动生成；显示 8 位有效数字，完整精度见数值报告。'
                  if zh else 'Tables are generated from the same run, showing eight significant digits; the numerical report retains full precision.'), '',
                 '.. checks-overview-end', '']
        headers = (['检查量', '预期值', '实际值', '最大绝对差', '比较规则', '状态'] if zh else
                   ['Quantity', 'Expected', 'Actual', 'Max absolute difference', 'Comparison rule', 'Status'])
        for group, selectors in FOCUSED_CHECKS.items():
            status, reason = group_outcome(records, selectors, language)
            status_label = {'PASS': '通过', 'FAIL': '失败', 'NOT RUN': '未完成'}[status] if zh else status
            lines += [f'.. checks-{group}-start', '',
                      f'**本次核对：{status_label}（{status}）**' if zh else f'**This run: {status_label}**', '',
                      '.. list-table::',
                      '   :header-rows: 1', '   :widths: 22 16 16 12 24 10', '',
                      '   * - ' + headers[0]]
            lines += ['     - ' + h for h in headers[1:]]
            for name, index, title_zh, title_en in selectors:
                row = records.get('test_' + name, {})
                checks = row.get('checks', [])
                title = title_zh if zh else title_en
                if index >= len(checks):
                    cells = [title, '—', '—', '—', '—', 'NOT RUN']
                else:
                    metric = focused_metric(name, index, checks[index])
                    cells = [title, table_value(metric.get('expected')), table_value(metric.get('actual')),
                             display(metric['max_abs_error']) if 'max_abs_error' in metric else '—',
                             short_criterion(metric, language), 'PASS' if metric.get('passed') else 'FAIL']
                lines += ['   * - ' + cells[0]] + ['     - ' + c for c in cells[1:]]
            conclusion = GROUP_CONCLUSIONS[group][0 if zh else 1] if status == 'PASS' else reason
            lines += ['', ('**结论：** ' if zh else '**Conclusion:** ') + conclusion]
            if group == 'spectrum':
                errors = records.get('test_leakage_can_bias_real_signal_phase', {}).get('observed', {}).get('phase_error_deg')
                if errors is not None:
                    lines += ['', (f'相对输入相位差的偏差：1.25 周期为 {display(errors[0])}°，2 周期为 {display(errors[1])}°。'
                                   '这是本次信号的读数偏差，不参与通过与否的判断。' if zh else
                                   f'Bias relative to the input phase difference: {display(errors[0])}° for 1.25 cycles and '
                                   f'{display(errors[1])}° for 2 cycles. These observations are not pass/fail thresholds.')]
            lines += ['', f'.. checks-{group}-end', '']
        (outdir / f'checks_{language}.rst').write_text('\n'.join(lines), encoding='utf-8')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--outdir', type=Path, default=CASE/'output')
    parser.add_argument('--publish-docs', action='store_true', help='update the small documentation snapshot after all checks pass')
    args = parser.parse_args()
    from test_regressions import Regressions
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(Regressions)
    result = unittest.TextTestRunner(verbosity=2, resultclass=Result).run(suite)
    out = args.outdir
    (out/'details').mkdir(parents=True, exist_ok=True)
    for name, arrays in result.data.items():
        np.savez_compressed(out/'details'/f'{name}.npz', **arrays)
    summary = dict(passed=result.wasSuccessful(), tests=result.records, provenance=provenance())
    (out/'summary.json').write_text(json.dumps(serial(summary), ensure_ascii=False, indent=2, allow_nan=False)+'\n', encoding='utf-8')
    (out/'provenance.json').write_text(json.dumps(summary['provenance'], indent=2)+'\n', encoding='utf-8')
    write_rst(summary, out)
    write_focused_rst(summary, out)
    if result.wasSuccessful():
        from plot_results import plot_results
        plot_results(out)
        if args.publish_docs:
            destination = ROOT/'docs/source/tests/010_diagnostics/_generated/case_basic_checks'
            destination.mkdir(parents=True, exist_ok=True)
            # Publish only this case's explicit artifact set.
            for filename in ['summary.json', 'provenance.json', 'results.rst', 'checks_zh.rst', 'checks_en.rst']:
                shutil.copy2(out/filename, destination/filename)
            for folder in ['details', 'figures']:
                shutil.copytree(out/folder, destination/folder, dirs_exist_ok=True)
    return 0 if result.wasSuccessful() else 1

if __name__ == '__main__':
    raise SystemExit(main())
