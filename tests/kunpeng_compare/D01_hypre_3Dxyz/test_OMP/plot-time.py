#!/usr/bin/env python3
import re
import glob
import os
import statistics
import matplotlib.pyplot as plt

# ===================== 正则规则（兼容三类日志）=====================
# 匹配格式：run_gcc_np4_omp1_1.log / run_bisheng_xxx / run_AMD_xxx
filename_pattern = re.compile(
    r"run_(?P<compiler>gcc|bisheng|AMD)_np(?P<np>\d+)_omp(?P<omp>\d+)_(?P<rep>\d+)\.log"
)

# 日志内时间提取规则（保持不变）
hypre_pattern = re.compile(r"\[TIME\]\s+hypre_time_avg\s+=\s+([0-9.Ee+-]+)")
total_pattern = re.compile(r"\[TIME\]\s+total_time\s+=\s+([0-9.Ee+-]+)")

# ===================== 数据容器 =====================
data = {}

# 遍历当前目录下 所有三类日志文件
log_files = sorted(glob.glob("run_*_np*_omp*_*.log"))
for fname in log_files:
    base_name = os.path.basename(fname)
    m = filename_pattern.match(base_name)
    if not m:
        continue

    # 解析文件名信息
    compiler = m.group("compiler")
    np_val = int(m.group("np"))
    omp_val = int(m.group("omp"))

    # 读取日志内容
    with open(fname, "r", errors="ignore") as f:
        text = f.read()

    # 提取耗时
    mh = hypre_pattern.search(text)
    mt = total_pattern.search(text)
    if mh is None or mt is None:
        print(f"WARNING: Missing time data -> {fname}")
        continue

    hypre_time = float(mh.group(1))
    total_time = float(mt.group(1))

    # 按 (编译器, MPI进程数, 线程数) 分组存储
    key = (compiler, np_val, omp_val)
    if key not in data:
        data[key] = {"hypre": [], "total": []}
    data[key]["hypre"].append(hypre_time)
    data[key]["total"].append(total_time)

# 无有效数据则终止
if not data:
    raise RuntimeError(
        "未找到有效日志！\n"
        "支持格式: run_gcc_npX_ompX_X.log / run_bisheng_npX_ompX_X.log / run_AMD_npX_ompX_X.log"
    )

# ===================== 计算均值 & 整理表格数据 =====================
rows = []
for (compiler, np_val, omp_val), vals in sorted(data.items()):
    rows.append({
        "compiler": compiler,
        "np": np_val,
        "omp": omp_val,
        "hypre_avg": statistics.mean(vals["hypre"]),
        "total_avg": statistics.mean(vals["total"]),
        "repeat_cnt": len(vals["hypre"]),
    })

# 终端打印统计表格
print("=" * 80)
print(f"{'compiler':<10} {'np':<4} {'omp':<4} {'repeats':<8} {'hypre_avg(s)':<15} {'total_avg(s)'}")
print("=" * 80)
for r in rows:
    print(
        f"{r['compiler']:<10} {r['np']:<4} {r['omp']:<4} {r['repeat_cnt']:<8} "
        f"{r['hypre_avg']:.8e}     {r['total_avg']:.8e}"
    )
print("=" * 80 + "\n")

# ===================== 绘图配置（点线图 + 标记，适配 plt.plot） =====================
# 线型+标记+颜色：虚线-- 代表HYPRE，实线- 代表总耗时，保留原有样式
style_map = {
    "gcc": {
        "hypre": {"linestyle": "--", "marker": "o", "color": "#1f77b4", "label": "KP-GCC | HYPRE Time"},
        "total": {"linestyle": "-",  "marker": "s", "color": "#1f77b4", "label": "KP-GCC | Total Time"}
    },
    "bisheng": {
        "hypre": {"linestyle": "--", "marker": "^", "color": "#ff7f0e", "label": "KP-BiSheng | HYPRE Time"},
        "total": {"linestyle": "-",  "marker": "D", "color": "#ff7f0e", "label": "KP-BiSheng | Total Time"}
    },
    "AMD": {
        "hypre": {"linestyle": "--", "marker": "*", "color": "#2ca02c", "label": "AMD | HYPRE Time"},
        "total": {"linestyle": "-",  "marker": "v", "color": "#2ca02c", "label": "AMD | Total Time"}
    }
}

# 按 MPI 进程数分组绘图
np_list = sorted(set(r["np"] for r in rows))
ylim = (0, 14)
windows_out_dir = "/mnt/e/kunpeng"

for np_val in np_list:
    plt.figure(figsize=(12, 6.5))
    omp_ticks = sorted({item["omp"] for item in rows if item["np"] == np_val})

    # 遍历三类编译器
    for comp in ["gcc", "bisheng", "AMD"]:
        # 筛选当前进程数 + 当前编译器 的数据
        sub_data = [item for item in rows if item["compiler"] == comp and item["np"] == np_val]
        if not sub_data:
            print(f"INFO: 无 {comp} 数据 (np={np_val})，跳过")
            continue

        # 按 OpenMP 线程升序排列
        sub_data.sort(key=lambda x: x["omp"])
        omp_list = [d["omp"] for d in sub_data]
        hypre_avg = [d["hypre_avg"] for d in sub_data]
        total_avg = [d["total_avg"] for d in sub_data]

        # 获取当前样式
        sty = style_map[comp]
        # 绘制 HYPRE 耗时：虚线 + 数据标记
        plt.plot(omp_list, hypre_avg, linewidth=2, markersize=8, **sty["hypre"])
        # 绘制 总耗时：实线 + 数据标记
        plt.plot(omp_list, total_avg, linewidth=2, markersize=8, **sty["total"])

    # 坐标轴、标题、网格
    plt.xlabel("OMP_NUM_THREADS (OpenMP Threads)", fontsize=11)
    plt.ylabel("Execution Time [s]", fontsize=11)
    plt.title(
        f"Performance Comparison: KP-GCC / KP-BiSheng / AMD\n"
        f"HYPRE Solver Time & Total Time | MPI Process = {np_val} | Y-axis = {ylim[0]}-{ylim[1]} s",
        fontsize=12, pad=15
    )
    plt.ylim(*ylim)

    # X轴刻度优化
    if omp_ticks:
        x_max = max(omp_ticks)
        xticks = list(range(2, x_max + 1, 2))
        if 1 in omp_ticks:
            xticks.insert(0, 1)
        plt.xticks(xticks, rotation=45)

    plt.grid(True, alpha=0.3, linestyle="--")
    plt.legend(loc="upper right", fontsize=9)
    plt.tight_layout()

    # 保存图片
    out_img = f"time_3compares_np{np_val}.png"
    plt.savefig(out_img, dpi=300, bbox_inches="tight")
    print(f"✅ 图片已生成: {out_img}")
    if os.path.isdir(windows_out_dir):
        windows_out_img = os.path.join(windows_out_dir, f"time_kp_amd_np{np_val}_ylim0_14.png")
        plt.savefig(windows_out_img, dpi=300, bbox_inches="tight")
        print(f"✅ 图片已生成: {windows_out_img}")

plt.close("all")
print("\n🎉 全部绘图任务完成！")
