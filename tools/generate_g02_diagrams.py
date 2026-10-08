#!/usr/bin/env python3
"""Draw bilingual G02 documentation schematics, not simulation results.

Run from any directory. SVG files are committed documentation assets.
Optional --preview-dir writes PNGs outside the source tree for visual review.
Requires Matplotlib, Graphviz (dot and neato), and a Chinese font (Noto Sans CJK SC is preferred).
"""
from pathlib import Path
import argparse
from html import escape
import json
import subprocess
import shlex
import math
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch, Circle

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs/source/images/G_Collision/G02"
INK, MUTED = "#17324d", "#52667a"
TEAL, ORANGE, BLUE = "#16857c", "#d77336", "#426db3"
plt.rcParams.update({
    "font.size": 12, "svg.fonttype": "path", "svg.hashsalt": "algoplasma-g02",
    "axes.unicode_minus": False,
})


def canvas(title, subtitle, height=6):
    fig = plt.figure(figsize=(12, height), facecolor="white")
    ax = fig.add_axes([0, 0, 1, 1], xlim=(0, 1), ylim=(0, 1))
    ax.set_axis_off()
    text(ax, .035, .955, title, 22, weight="bold")
    text(ax, .035, .89, subtitle, 12, MUTED)
    return fig, ax


def text(ax, x, y, value, size=13, color=INK, ha="left", **kwargs):
    return ax.text(x, y, value, fontsize=size, color=color, ha=ha,
                   va="center", linespacing=1.5, **kwargs)


def panel(ax, x, y, w, h, fill="#f1f5fa", edge="#d8e2ed"):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.008,rounding_size=0.015",
                              facecolor=fill, edgecolor=edge, linewidth=1.1))


def arrow(ax, a, b, color=TEAL, width=2, dashed=False):
    if a == b:
        ax.add_patch(Circle(a, .004, color=color))
        return
    ax.add_patch(FancyArrowPatch(a, b, arrowstyle="-|>", mutation_scale=15,
                                color=color, linewidth=width,
                                linestyle="--" if dashed else "-"))


def ball(ax, x, y, dx, dy, color):
    ax.add_patch(Circle((x, y), .010, facecolor=color, edgecolor="white", linewidth=1.2))
    arrow(ax, (x+.008, y), (x+dx, y+dy), color, 1.6)


def physical(lang):
    zh = lang == "zh"
    fig, ax = canvas("碰撞使热粒子逐渐冷却" if zh else "Collisions cool hot particles",
                     "碰撞交换动量和能量；每个粒子的速度都会不同。" if zh else
                     "Collisions exchange momentum and energy. Individual velocities differ.")
    titles = ["A：初始", "B：固定背景", "A：许多次碰撞后"] if zh else [
        "A: initially", "B: fixed background", "A: after many collisions"]
    subs = ["3000 K + 向右漂移", "300 K，平均速度为零", "接近 300 K，漂移减弱"] if zh else [
        "3000 K + rightward drift", "300 K, zero mean velocity", "Near 300 K, weak drift"]
    for x, title, sub in zip([.035, .365, .695], titles, subs):
        panel(ax, x, .20, .27, .59)
        text(ax, x+.135, .74, title, 16, ha="center", weight="bold")
        text(ax, x+.135, .665, sub, 12, ha="center")
    for x,y,dx,dy in [(.075,.54,.11,.04),(.10,.43,.14,-.02),(.07,.31,.09,.02),
                      (.20,.53,.06,-.08),(.20,.34,.07,.04)]:
        ball(ax,x,y,dx,dy,ORANGE)
    for x,y,dx,dy in [(.42,.51,.03,.04),(.53,.53,-.04,.02),(.44,.35,-.035,-.035),
                      (.57,.40,.01,-.05),(.52,.30,.03,.02)]:
        ball(ax,x,y,dx,dy,TEAL)
    for x,y,dx,dy in [(.75,.51,.04,.02),(.88,.52,-.045,.035),(.76,.33,-.025,-.035),
                      (.87,.37,.015,-.03),(.81,.43,.025,-.015)]:
        ball(ax,x,y,dx,dy,BLUE)
    arrow(ax,(.307,.46),(.358,.46),MUTED)
    arrow(ax,(.637,.46),(.688,.46),MUTED)
    text(ax,.5,.145,"从 B 的速度分布抽样搭档 → 碰撞 → 记录 B 的能量收支" if zh else
         "Sample a B partner → collide → record energy transferred to B",13,ha="center")
    text(ax,.035,.06,"示意图：箭头表示速度，不是轨迹；方框不表示实体壁面。B 的温度保持固定。" if zh else
         "Schematic velocities, not trajectories or simulation output. Boxes are not walls. B stays fixed.",11,MUTED)
    return fig


def drift(lang):
    zh = lang == "zh"
    fig, ax = canvas("整体运动与热运动，可以拆开看" if zh else "Separate drift from thermal motion",
                     "先用三个粒子的 x 速度做一个简单算术例子。" if zh else
                     "An arithmetic example using the x velocities of three particles.",5.8)
    data = [
        (.035, "看到的速度 v" if zh else "Observed velocity v", [400,1000,1600], ORANGE),
        (.365, "平均速度 U" if zh else "Mean velocity U", [1000]*3, BLUE),
        (.695, "相对速度 v − U" if zh else "Relative velocity v − U", [-600,0,600], TEAL),
    ]
    for x,title,values,color in data:
        panel(ax,x,.23,.27,.55)
        text(ax,x+.135,.72,title,15,ha="center",weight="bold")
        for y,value in zip([.59,.46,.33],values):
            start=x+(.13 if color==TEAL else .065)
            arrow(ax,(start,y),(start+value*.00009,y),color)
            text(ax,x+.135,y-.045,f"{value:+d} m/s",11,MUTED,ha="center")
    text(ax,.333,.5,"−",28,ha="center")
    text(ax,.663,.5,"=",28,ha="center")
    text(ax,.5,.15,"给所有粒子都加 200 m/s：平均速度变了，相对平均值的运动不变。" if zh else
         "Add 200 m/s to every particle: the mean changes; relative motion stays the same.",13,ha="center")
    text(ax,.035,.065,"只展示 x 分量；实际程序用 x、y、z 三个方向的相对运动计算平动温度。" if zh else
         "Only x is shown. The simulation uses all three relative velocity components to calculate temperature.",11,MUTED)
    return fig


def timeline(lang):
    zh = lang == "zh"
    fig, ax = canvas("一个时间步内，可以检查多次碰撞" if zh else "Several candidates can occur in one step",
                     "时间步 dt 是一段时间；候选等待时间由随机数抽样。" if zh else
                     "dt is a time interval. Candidate waiting times are sampled randomly.",5.8)
    x0,x1=.075,.925
    line_y=.48
    ax.plot([x0,x1],[line_y,line_y],color=INK,lw=2)
    for x,label in [(x0,"0"),(.755,"dt"),(x1,"t")]:
        ax.plot([x,x],[line_y-.02,line_y+.02],color=INK,lw=1.5)
        text(ax,x,line_y-.07,label,13,ha="center")
    panel(ax,.765,.26,.16,.43,"#f4f4f5","#e1e1e3")
    text(ax,.845,.65,"超出本步" if zh else "Beyond dt",14,MUTED,ha="center")
    candidates=[(.23,True),(.43,False),(.64,True)]
    for x,real in candidates:
        color=TEAL if real else MUTED
        ax.scatter([x],[line_y],s=110,facecolors=color if real else "white",
                   edgecolors=color,linewidths=2,zorder=4)
        text(ax,x,.69,("真实碰撞" if real else "空碰撞") if zh else
             ("Real collision" if real else "Null collision"),14,color,ha="center",weight="bold")
        text(ax,x,.61,("更新粒子状态" if real else "状态不变") if zh else
             ("Update state" if real else "Keep state"),12,color,ha="center")
    ax.scatter([.86],[line_y],s=100,color="#c6cdd4",zorder=4)
    starts=[x0,.23,.43,.64]
    ends=[.23,.43,.64,.86]
    for i,(a,b) in enumerate(zip(starts,ends),1):
        arrow(ax,(a,.29),(b,.29),MUTED,1.2)
        text(ax,(a+b)/2,.34,f"τ{i}",12,MUTED,ha="center")
    text(ax,.5,.15,"本步记录：3 个候选 = 2 次真实碰撞 + 1 次空碰撞；下一候选超过 dt。" if zh else
         "This step: 3 candidates = 2 real + 1 null. The next wait extends beyond dt.",13,ha="center")
    text(ax,.035,.06,"手工示意时刻；超界候选未发生，下一步重新抽样。空碰撞也消耗等待时间。" if zh else
         "Illustrative times. The out-of-step candidate is not executed; sampling restarts next step.",11,MUTED)
    return fig


def flowchart(lang, detailed=False):
    """Use standard symbols; keep the graph source separate from its renderer."""
    zh = lang == "zh"
    title = ("G02 MCC：一个完整时间步" if detailed else "G02 MCC：程序总流程") if zh else (
        "G02 MCC: one complete time step" if detailed else "G02 MCC: program flow")
    subtitle = ("候选时间循环与粒子循环；统一提交本步结果" if detailed else
                "C++ 批量入口 MccStepper::step()") if zh else (
        "Candidate and particle loops; commit the completed batch" if detailed else
        "Batch API: MccStepper::step()")
    # Name the actual implementation, rather than inventing a public entry for
    # each decision. Internal helpers are explicitly marked in both languages.
    engine_file = "fun_G02_mcc_engine.cpp"
    batch_file = "fun_G02_mcc_batch.cpp"
    internal = "内部" if zh else "internal"
    references = {
        "stage": ("MccStepper::step()", "PreparedMccStep::prepare_commit()", batch_file),
        "commit": ("PreparedMccStep::commit()", batch_file),
        "report": ("PreparedMccStep::take_report()", batch_file),
    }
    if detailed:
        references.update({
            "start": ("MccStepper::step()", "batch.hpp"),
            "snapshot": ("MccStepper::prepare_step()", batch_file),
            "particle": (f"MccEngine::collide_impl() ({internal})", engine_file),
            "wait": ("CounterRng::uniform_open()", "rng.hpp", engine_file),
            "candidate": (engine_file, "table.hpp / rng.hpp"),
            "real": (engine_file, "fun_G02_mcc_kinematics.cpp"),
            "null": (engine_file,),
            "refresh": (f"build_active_channels() ({internal})", engine_file),
        })
    else:
        references.update({
            "start": ('#include "mcc.hpp"',),
            "csv": ("manifest.csv",),
            "load": ("MccEngine::load()", engine_file,
                     "fun_G02_mcc_model.cpp", "fun_G02_mcc_compile.cpp"),
            "prepare": ("MccStepper::prepare_step()", batch_file),
            "collisions": (f"MccEngine::collide_full_batch() ({internal})", engine_file),
        })
    heading = ('<<B>' + escape(title) + '</B><BR/>'
               '<FONT POINT-SIZE="15">' + escape(subtitle) + '</FONT>>')
    lines = [
        "strict digraph MCC {",
        '  graph [rankdir=TB, splines=ortho, nodesep=0.44, ranksep=0.48,',
        '         bgcolor="white", pad=0.12, fontname="Noto Sans CJK SC",',
        f'         fontsize=22, labelloc=t, label={heading}];',
        '  node [shape=box, style=filled, fillcolor="white", color="#243746",',
        '        fontcolor="#162a38", fontname="Noto Sans CJK SC",',
        '        fontsize=20, penwidth=1.5, margin="0.22,0.14"];',
        '  edge [color="#243746", fontcolor="#243746", fontname="Noto Sans CJK SC",',
        '        fontsize=15, penwidth=1.3, arrowsize=0.8];',
    ]

    def node(name, cn, en, shape="box", extra=""):
        fill = {"ellipse": "#e9f3ef", "diamond": "#fff7df", "parallelogram": "#eef4fb"}.get(shape, "white")
        value = cn if zh else en
        if name in references:
            # Wrap qualified names at the scope boundary, keeping every symbol
            # and filename intact while avoiding a wide canvas with tiny text.
            body = escape(value).replace("\n", "<BR/>")
            refs = "<BR/>".join(
                escape(ref).replace("::", "::<BR/>").replace(" (", "<BR/>(")
                if len(ref) > 28 else escape(ref)
                for ref in references[name])
            # Separate the action and its source annotation. Cell padding stays
            # zero here; the node margin provides consistent outer breathing room.
            label = ('<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0" CELLPADDING="0">'
                     '<TR><TD>' + body + '</TD></TR>'
                     '<TR><TD HEIGHT="7"></TD></TR>'
                     '<TR><TD><FONT FACE="DejaVu Sans Mono" '
                     'POINT-SIZE="16" COLOR="#52667a">' + refs + '</FONT></TD></TR>'
                     '</TABLE>>')
        else:
            label = json.dumps(value, ensure_ascii=False)
        if shape == "diamond":
            extra += ', margin="0.14,0.09"'
        if shape == "parallelogram":
            # Graphviz's automatic size leaves a large empty slant on multi-line
            # I/O labels. Keep standard symbols with dimensions sized for these
            # labels, retaining clearance on both sloping sides.
            width, height = {
                "csv": (4.0 if zh else 4.2, 1.2 if zh else 1.4),
                "input": (3.8 if zh else 4.1, 1.2),
                "report": (5.2, (2.0 if zh else 2.2) if not detailed else 1.8),
            }[name]
            extra += f", fixedsize=shape, width={width}, height={height}"
        lines.append(f'  {name} [label={label}, '
                     f'shape={shape}, fillcolor="{fill}"{extra}];')

    def edge(a, b, cn="", en="", extra=""):
        label = cn if zh else en
        badge = ('<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0" '
                 'CELLPADDING="2" BGCOLOR="white"><TR><TD>' + escape(label) + '</TD></TR></TABLE>>')
        attrs = ([f'xlabel={badge}'] if label else [])
        if extra:
            attrs.append(extra)
        lines.append(f'  {a} -> {b}' + (' [' + ', '.join(attrs) + ']' if attrs else '') + ';')

    if not detailed:
        node("start", "开始", "Start", "ellipse")
        node("csv", "输入 CSV 模型目录", "Input CSV model\ndirectory", "parallelogram")
        node("load", "读取并校验反应模型\n编译后跨时间步复用", "Load and validate the model\nCompile for reuse across steps")
        node("valid", "模型加载\n成功？", "Model\nloaded?", "diamond")
        node("step_entry", "", "", "point", ", width=0.045, height=0.045")
        node("input", "提供本步粒子\n背景与 Δt", "Provide particles,\nbackground and Δt", "parallelogram")
        node("prepare", "准备背景缓存\n建立粒子快照", "Prepare background cache\nand particle snapshot")
        node("collisions", "逐粒子完成碰撞处理\n抽候选 → 真实 / 空碰撞\n循环处理剩余时间", "Process each particle\nCandidates → real / null events\nLoop over remaining time", )
        node("stage", "汇总统计\n分配产物 ID 并准备存储", "Reduce statistics\nAssign product IDs\nPrepare storage for commit")
        node("ready", "本步准备\n全部成功？", "All step preparation\nsucceeded?", "diamond")
        node("commit", "统一写回粒子变化", "Commit all particle changes")
        node("report", "返回并读取 StepReport\n主程序应用背景收支", "Read StepReport\nHost applies background\nexchange", "parallelogram")
        node("next", "还有下一个\n时间步？", "Another\ntime step?", "diamond")
        node("end", "结束", "End", "ellipse")
        node("error", "抛出 Error\n结束\n不提交更新", "Throw Error\nStop without\nparticle commit", "ellipse", ', fillcolor="#fbeceb", color="#aa4444"')
        for a, b in [("start", "csv"), ("csv", "load"), ("load", "valid"),
                     ("input", "prepare"), ("prepare", "collisions"), ("collisions", "stage"),
                     ("stage", "ready"), ("commit", "report"), ("report", "next")]:
            edge(a, b)
        edge("valid", "step_entry", "是", "Yes")
        edge("step_entry", "input")
        edge("valid", "error", "否", "No", "constraint=false")
        edge("ready", "commit", "是", "Yes")
        edge("ready", "error", "否", "No")
        edge("next", "step_entry", "是", "Yes", "constraint=false")
        edge("next", "end", "否", "No")
        lines.append("  {rank=same; commit; error;}")
        lines.append('  start -> csv -> load -> valid -> step_entry -> input -> prepare -> collisions -> stage -> ready -> commit -> report -> next -> end [weight=100];')
        # These are exception paths, not normal control flow: preparation can fail
        # before reaching the final success gate, and no visible writes occur.
        edge("prepare", "error", "出错", "Error", 'style=dashed, color="#aa4444", constraint=false')
        edge("collisions", "error", "出错", "Error", 'style=dashed, color="#aa4444", constraint=false')
    else:
        node("start", "进入 step()", "Enter step()", "ellipse")
        node("snapshot", "准备背景缓存与活动通道\n建立粒子快照", "Prepare background\nand channel cache\nCreate particle snapshot")
        node("more", "还有本步有效\n主粒子？", "More eligible\nprimary particles?", "diamond")
        node("particle", "取下一粒子，r = Δt\n只在工作区计算", "Take next particle; r = Δt\nCompute in workspace")
        node("active", "剩余时间 r > 0\n且总频率上界\nΛ > 0？", "Remaining time r > 0\nand total majorant\nΛ > 0?", "diamond")
        node("wait", "抽样候选等待时间\nτ = −ln(1 − u) / Λ", "Sample candidate waiting time\nτ = −ln(1 − u) / Λ")
        node("inside", "τ ≤ r？", "τ ≤ r?", "diamond")
        node("candidate", "检查候选上限，r ← r − τ\n选通道并抽背景速度\n计算真实频率", "Check candidate limit; r ← r − τ\nSelect channel and sample partner\nCompute actual rate")
        node("accept", "按真实频率 /\n通道上界\n接受候选？", "Accept candidate?\nactual rate /\nchannel majorant", "diamond")
        node("real", "真实碰撞：计算末态与收支\n更新工作区粒子\n暂存新产物", "Real collision: outgoing state\nRecord exchange\nUpdate workspace particle\nStage new products")
        node("null", "空碰撞：记录候选\n粒子状态保持不变", "Null collision: record candidate\nKeep particle state")
        node("removed", "主粒子\n被移除？", "Primary particle\nremoved?", "diamond")
        node("refresh", "按碰后物种 / 内部态\n重新确定活动通道与上界", "Refresh channels and majorant\nfor outgoing species\n/ internal state")
        node("finish", "结束该粒子并暂存结果\n新产物从下一步参与", "Finish particle\nStage result\nNew products join next step")
        node("stage", "汇总统计\n分配产物 ID 并准备存储", "Reduce statistics\nAssign product IDs\nPrepare storage for commit")
        node("ready", "所有准备\n均成功？", "All preparation\nsucceeded?", "diamond")
        node("commit", "统一写回所有粒子变化", "Commit all particle changes")
        node("report", "返回 StepReport", "Return StepReport", "parallelogram")
        node("end", "本步结束", "End of step", "ellipse")
        node("error", "任一准备阶段出错\n抛出 Error，本步结束\n不提交粒子更新", "Any preparation error\nThrow Error; end step\nNo particle commit", "ellipse", ', fillcolor="#fbeceb", color="#aa4444"')
        for a, b in [("start", "snapshot"), ("snapshot", "more"), ("particle", "active"),
                     ("wait", "inside"), ("candidate", "accept"), ("real", "removed"),
                     ("finish", "more"), ("stage", "ready"), ("commit", "report"), ("report", "end")]:
            edge(a, b, extra="constraint=false" if a == "finish" else "")
        edge("more", "particle", "是", "Yes")
        edge("more", "stage", "否", "No")
        edge("active", "wait", "是", "Yes")
        edge("active", "finish", "否", "No")
        edge("inside", "candidate", "是", "Yes")
        edge("inside", "finish", "否：超出本步", "No: beyond step")
        edge("accept", "real", "是", "Yes")
        edge("accept", "null", "否", "No")
        edge("null", "active", "继续", "Continue", "constraint=false")
        edge("removed", "finish", "是", "Yes")
        edge("removed", "refresh", "否", "No")
        edge("refresh", "active", "继续", "Continue", "constraint=false")
        edge("ready", "commit", "是", "Yes")
        edge("ready", "error", "否", "No")
        # Any preparation failure uses this same no-commit exit. Detailed
        # examples of failed checks are in the figure caption, keeping the
        # drawing compact and avoiding a second note-to-error routing layer.
        lines.append("  {rank=same; real; null;}")
        lines.append("  {rank=same; refresh; finish;}")
        lines.append("  {rank=same; commit; error;}")
        lines.append('  start, snapshot, more, particle, active, wait, inside, candidate, accept, real, removed, refresh, stage, ready, commit, report, end [group="main"];')
        lines.append('  start -> snapshot -> more -> particle -> active -> wait -> inside -> candidate -> accept -> real -> removed -> refresh [weight=100];')
        lines.append('  refresh -> stage [style=invis, weight=100];')
        lines.append('  stage -> ready -> commit -> report -> end [weight=100];')
    lines.append("}")
    return "\n".join(lines) + "\n"



def route_flowchart(source, detailed):
    """Measure standard symbols with dot, then reserve explicit orthogonal lanes.

    neato -n2 preserves these node/edge positions in both SVG and PNG. In
    particular, loop labels never depend on dot's orthogonal xlabel placement.
    Coordinates below are Graphviz points (72 points per inch), with y upwards.
    """
    measured = subprocess.run(["dot", "-Tplain"],
                             input=source.replace("splines=ortho", "splines=polyline").encode(),
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
    sizes = {}
    pairs = []
    for line in measured.stdout.decode().splitlines():
        fields = shlex.split(line)
        if fields[0] == "node":
            sizes[fields[1]] = (float(fields[4]) * 72, float(fields[5]) * 72)
        elif fields[0] == "edge":
            pairs.append((fields[1], fields[2]))

    order = (["start", "snapshot", "more", "particle", "active", "wait", "inside",
              "candidate", "accept", "real", "removed", "refresh", "stage", "ready",
              "commit", "report", "end"] if detailed else
             ["start", "csv", "load", "valid", "input", "prepare", "collisions",
              "stage", "ready", "commit", "report", "next", "end"])
    side_rows = {"real": "null", "refresh": "finish", "commit": "error"} if detailed else {"commit": "error"}
    main_width = max(sizes[name][0] for name in order)
    side_width = max(sizes[name][0] for name in side_rows.values())
    main_x = main_width / 2 + (88 if detailed else 52)
    main_right = main_x + main_width / 2
    side_x = main_right + 64 + side_width / 2
    positions = {}
    y = 0
    previous_height = 0
    for name in order:
        height = max(sizes[name][1], sizes[side_rows[name]][1] if name in side_rows else 0)
        if positions:
            y -= previous_height / 2 + 38 + height / 2
        positions[name] = (main_x, y)
        if name in side_rows:
            positions[side_rows[name]] = (side_x, y)
        previous_height = height
    if not detailed:
        bottom = positions["valid"][1] - sizes["valid"][1] / 2
        top = positions["input"][1] + sizes["input"][1] / 2
        positions["step_entry"] = (main_x, (bottom + top) / 2)

    def port(name, side):
        x, y = positions[name]
        w, h = sizes[name]
        return {"n": (x, y+h/2), "s": (x, y-h/2),
                "e": (x+w/2, y), "w": (x-w/2, y)}[side]

    routes = {}

    def route(a, b, points, label=None):
        # Drop redundant corners, including zero-length spans at a merge point.
        clean = []
        for point in points:
            if not clean or point != clean[-1]:
                clean.append(point)
        routes[a, b] = (clean, label)

    def vertical(a, b):
        start, end = port(a, "s"), port(b, "n")
        route(a, b, [start, end], (start[0]+25, (start[1]+end[1])/2))

    # Every visible spine connector gets its own inter-node gap.
    for a, b in pairs:
        if a in order and b in order and order.index(b) == order.index(a)+1:
            vertical(a, b)
    if not detailed:
        vertical("valid", "step_entry")
        vertical("step_entry", "input")
        loop_x = main_x - main_width / 2 - 30
        start, end = port("next", "w"), port("step_entry", "w")
        route("next", "step_entry", [start, (loop_x, start[1]), (loop_x, end[1]), end],
              ((start[0]+loop_x)/2, start[1]+16))
        # Separate exception lanes terminate at different points on the error
        # ellipse. Labels stay above the horizontal outgoing branches.
        error_x, error_y = positions["error"]
        error_w, error_h = sizes["error"]
        for name, fraction in [("valid", 0.52), ("prepare", 0.12), ("collisions", -0.28)]:
            start = port(name, "e")
            lane_x = error_x + error_w/2*fraction
            end_y = error_y + error_h/2*math.sqrt(1-fraction*fraction)
            route(name, "error", [start, (lane_x, start[1]), (lane_x, end_y)],
                  (start[0]+(lane_x-start[0])/2, start[1]+16))
        start, end = port("ready", "e"), port("error", "w")
        lane_x = main_right + 28
        route("ready", "error", [start, (lane_x, start[1]), (lane_x, end[1]), end],
              ((start[0]+lane_x)/2, start[1]+16))
    else:
        # Two left lanes separate the particle loop and remaining-time loop.
        for a, b, lane_x in [("more", "stage", 18), ("refresh", "active", 50)]:
            start, end = port(a, "w"), port(b, "w")
            label = (((end[0]+lane_x)/2, end[1]+18) if a == "refresh" else
                     ((start[0]+lane_x)/2, start[1]+16))
            route(a, b, [start, (lane_x, start[1]), (lane_x, end[1]), end], label)
        side_right = side_x + side_width / 2
        # Null events return through the gap between the two node columns.
        start = port("null", "w")
        active_x, active_y = positions["active"]
        active_w, active_h = sizes["active"]
        end = (active_x + active_w*.25, active_y - active_h*.25)
        lane_x = main_right + 26
        route("null", "active", [start, (lane_x, start[1]), (lane_x, end[1]), end],
              (lane_x+48, (start[1]+end[1])/2))
        start, end = port("accept", "e"), port("null", "n")
        route("accept", "null", [start, (end[0], start[1]), end],
              (main_right+68, start[1]+16))
        for a, lane_x, offset in [("active", side_right+30, 0.16),
                                  ("inside", side_right+8, -0.16)]:
            start = port(a, "e")
            finish_x, finish_y = positions["finish"]
            finish_w, finish_h = sizes["finish"]
            end = (finish_x+finish_w/2, finish_y+finish_h*offset)
            route(a, "finish", [start, (lane_x, start[1]), (lane_x, end[1]), end],
                  (start[0]+60, start[1]+16))
        start, end = port("removed", "e"), port("finish", "n")
        route("removed", "finish", [start, (end[0], start[1]), end],
              (start[0]+32, start[1]+16))
        start, end = port("finish", "s"), port("more", "e")
        outer_x = side_right+56
        route("finish", "more", [start, (start[0], start[1]-20),
                                   (outer_x, start[1]-20), (outer_x, end[1]), end])
        start, end = port("ready", "e"), port("error", "n")
        route("ready", "error", [start, (end[0], start[1]), end],
              (start[0]+32, start[1]+16))

    def edge_position(points):
        # Graphviz stores cubic paths; repeated control points keep each span
        # straight. Reserve the final 8 points for the arrowhead.
        end = points[-1]
        previous = points[-2]
        length = math.hypot(end[0]-previous[0], end[1]-previous[1])
        if length <= 8:
            raise ValueError("Flowchart arrow has insufficient clearance")
        before_arrow = (end[0]-(end[0]-previous[0])*8/length,
                        end[1]-(end[1]-previous[1])*8/length)
        shortened = points[:-1] + [before_arrow]
        controls = [shortened[0]]
        for left, right in zip(shortened, shortened[1:]):
            controls.extend([left, right, right])
        return "e,{:.2f},{:.2f} ".format(*end) + " ".join("{:.2f},{:.2f}".format(*p) for p in controls)

    overrides = ['  graph [splines=true];']
    for name, (x, y) in positions.items():
        overrides.append(f'  {name} [pos="{x:.2f},{y:.2f}!"];')
    for a, b in pairs:
        if (a, b) not in routes:
            raise ValueError(f"Flowchart edge needs an explicit route: {a} -> {b}")
        points, label = routes[a, b]
        attributes = [f'pos="{edge_position(points)}"']
        if label:
            attributes.append(f'xlp="{label[0]:.2f},{label[1]:.2f}"')
        overrides.append(f'  {a} -> {b} [' + ', '.join(attributes) + '];')
    return source.rsplit("}", 1)[0] + "\n".join(overrides) + "\n}\n"


def render_flowchart(name, lang, preview_dir=None):
    source = route_flowchart(flowchart(lang, detailed=name == "step_flow"),
                             detailed=name == "step_flow").encode("utf-8")
    svg = subprocess.run(["neato", "-n2", "-Tsvg"], input=source, stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE, check=True).stdout.decode("utf-8")
    # Provide native Windows font fallback while preserving Linux rendering.
    svg = svg.replace('font-family="Noto Sans CJK SC"',
                      'font-family="Noto Sans CJK SC,Microsoft YaHei,sans-serif"')
    svg = svg.replace('font-family="DejaVu Sans Mono"',
                      'font-family="DejaVu Sans Mono,Consolas,monospace"')
    (OUTPUT / f"{name}_{lang}.svg").write_text(
        "\n".join(line.rstrip() for line in svg.splitlines()) + "\n", encoding="utf-8")
    if preview_dir:
        subprocess.run(["neato", "-n2", "-Tpng", "-Gdpi=150", "-o", str(preview_dir / f"{name}_{lang}.png")],
                       input=source, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview-dir",type=Path)
    parser.add_argument("--font",type=Path,help="Optional font file with Chinese glyphs")
    args=parser.parse_args()
    candidates = [args.font] if args.font else [
        Path.home()/".local/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc",
        Path("/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"),
        Path("/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc"),
        Path("C:/Windows/Fonts/msyh.ttc"),
    ]
    font = next((p for p in candidates if p and p.is_file()),None)
    if font is None:
        raise SystemExit("A Chinese font is required; pass its file with --font.")
    font_manager.fontManager.addfont(str(font))
    plt.rcParams["font.family"] = [font_manager.FontProperties(fname=str(font)).get_name(), "DejaVu Sans"]
    OUTPUT.mkdir(parents=True,exist_ok=True)
    if args.preview_dir:
        args.preview_dir.mkdir(parents=True,exist_ok=True)
    for name,draw in [("physical_box",physical),("drift_temperature",drift),
                      ("event_timeline",timeline)]:
        for lang in ["zh","en"]:
            fig=draw(lang)
            svg_path = OUTPUT / f"{name}_{lang}.svg"
            fig.savefig(svg_path, metadata={"Date": None, "Description": "G02 documentation schematic; not simulation output."})
            # Matplotlib path data has trailing spaces; normalize generated assets.
            svg_path.write_text("\n".join(line.rstrip() for line in svg_path.read_text().splitlines()) + "\n")
            if args.preview_dir:
                fig.savefig(args.preview_dir/f"{name}_{lang}.png",dpi=130)
            plt.close(fig)
    for name in ["architecture", "step_flow"]:
        for lang in ["zh", "en"]:
            render_flowchart(name, lang, args.preview_dir)
    print(f"Wrote 10 SVG schematics to {OUTPUT}")


if __name__ == "__main__":
    main()
