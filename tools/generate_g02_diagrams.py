#!/usr/bin/env python3
"""Draw bilingual G02 documentation schematics, not simulation results.

Run from any directory. SVG files are committed documentation assets.
Optional --preview-dir writes PNGs outside the source tree for visual review.
Requires Matplotlib and a Chinese font (Noto Sans CJK SC is preferred).
"""
from pathlib import Path
import argparse
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
    fig, ax = canvas("热粒子怎样逐渐冷却？" if zh else "How do hot particles cool?",
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
        text(ax,x,.61,("更新速度" if real else "速度不变") if zh else
             ("Update velocity" if real else "Keep velocity"),12,color,ha="center")
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


def architecture(lang):
    zh = lang == "zh"
    fig, ax = canvas("G02：程序各部分怎样配合？" if zh else "G02: how the source files work together",
                     "每个框先说明用途，再标出可以打开查阅的源码文件。" if zh else
                     "Each box names a task and its source file.", 8)
    boxes = [
        (.06,.73,.88,.10,"主程序：提供粒子、背景与时间步" if zh else "Host: particles, background and time step", "C++: mcc.hpp  |  C: c_api.h  |  Fortran: mod_G02_MCC_network.f90"),
        (.20,.56,.60,.11,"批量处理粒子（接入数组、分工、提交）" if zh else "Batch processing: adapt arrays, share work, commit", "batch.hpp / fun_G02_mcc_batch.cpp"),
        (.06,.36,.40,.12,"读取反应数据与准备查表" if zh else "Load reactions and prepare tables", "fun_G02_mcc_model.cpp"),
        (.54,.36,.40,.12,"抽样碰撞（何时发生、选哪条反应）" if zh else "Sample time and reaction", "engine.hpp / fun_G02_mcc_engine.cpp"),
        (.54,.17,.40,.12,"计算碰后速度（动量与能量约束）" if zh else "Compute outgoing velocities", "fun_G02_mcc_kinematics.cpp"),
        (.06,.17,.40,.12,"返回粒子更新与统计报告" if zh else "Return particle updates and reports", "batch.hpp: StepReport"),
    ]
    for x,y,w,h,title,sub in boxes:
        panel(ax,x,y,w,h,"#e9f5f1" if y==.56 else "#f1f5fa")
        text(ax,x+w/2,y+h*.68,title,13,ha="center",weight="bold")
        text(ax,x+w/2,y+h*.28,sub,10,ha="center")
    arrow(ax,(.5,.725),(.5,.675));arrow(ax,(.65,.55),(.74,.485))
    arrow(ax,(.47,.42),(.53,.42));arrow(ax,(.74,.355),(.74,.295))
    arrow(ax,(.535,.23),(.465,.23))
    text(ax,.06,.09,"模型准备：fun_G02_mcc_compile.cpp；查表：fun_G02_mcc_table.cpp" if zh else
         "Preparation: fun_G02_mcc_compile.cpp; lookup: fun_G02_mcc_table.cpp",10,MUTED)
    text(ax,.06,.045,"批量入口接收宿主数组；MPI 负责多进程协调，背景演化由主程序处理。" if zh else
         "The batch entry adapts host arrays. MPI coordinates ranks; the host evolves the background.",11,MUTED)
    return fig


def step_flow(lang):
    zh = lang == "zh"
    fig, ax = canvas("一个碰撞时间步的流程" if zh else "Flow of one collision time step",
                     "先在工作区准备结果；所有粒子成功后才写回主程序数组。" if zh else
                     "Prepare in workspace; commit only after all particles succeed.", 10)
    def box(y, title, sub="", x=.12, w=.55):
        panel(ax,x,y,w,.085)
        text(ax,x+w/2,y+.055,title,13,ha="center",weight="bold")
        if sub: text(ax,x+w/2,y+.022,sub,10,ha="center")
    box(.77,"取下一个符合本步条件的粒子" if zh else "Take the next eligible particle", "fun_G02_mcc_batch.cpp")
    box(.64,"读取状态与背景，准备活动通道" if zh else "Read state/background; prepare channels", "fun_G02_mcc_engine.cpp")
    box(.51,"抽样等待时间：候选在本步内？" if zh else "Sample waiting time: inside this step?", "无通道或超时 → 结束该粒子" if zh else "No channel / outside step → finish particle")
    box(.38,"按通道上界选反应，再接受或拒绝" if zh else "Select a channel; accept or reject", "真实频率 / 通道上界" if zh else "Actual rate / channel bound")
    box(.25,"真实碰撞：更新；空碰撞：保持状态" if zh else "Real: update; null: preserve state", "fun_G02_mcc_kinematics.cpp (real events)")
    box(.12,"扣除等待时间，继续处理剩余时间" if zh else "Consume waiting time; continue remainder", "删除粒子则结束；新产物下一步参与" if zh else "Removal ends particle; births participate next step")
    for y in [.77,.64,.51,.38,.25]: arrow(ax,(.395,y-.005),(.395,y-.043))
    # Loop inside a particle.
    ax.plot([.115,.075,.075,.115],[.16,.16,.68,.68],color=TEAL,lw=1.6)
    arrow(ax,(.075,.68),(.115,.68))
    box(.51,"结束该粒子" if zh else "Finish particle", "还有粒子 → 返回顶部" if zh else "More particles → back to top", x=.74,w=.23)
    arrow(ax,(.675,.55),(.735,.55));text(ax,.705,.585,"否" if zh else "No",10,ha="center")
    text(ax,.44,.485,"是 / Yes",10)
    box(.25,"全部成功？" if zh else "All succeeded?", "含容量 / MPI 检查" if zh else "Capacity / MPI checks",x=.74,w=.23)
    arrow(ax,(.855,.505),(.855,.34))
    text(ax,.855,.43,"全部处理完" if zh else "All particles done",10,ha="center")
    box(.12,"成功：统一写回" if zh else "Success: commit", "失败：保留原数组" if zh else "Failure: keep input",x=.74,w=.23)
    arrow(ax,(.855,.245),(.855,.21))
    text(ax,.12,.05,"右侧提交步骤仅在全部粒子处理完后执行；任意准备错误均退出，不提交。" if zh else
         "Commit after all particles finish. Any preparation error aborts without committing.",11,MUTED)
    return fig


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
                      ("event_timeline",timeline),("architecture",architecture),("step_flow",step_flow)]:
        for lang in ["zh","en"]:
            fig=draw(lang)
            fig.savefig(OUTPUT/f"{name}_{lang}.svg",metadata={"Date":None,"Description":"G02 documentation schematic; not simulation output."})
            if args.preview_dir:
                fig.savefig(args.preview_dir/f"{name}_{lang}.png",dpi=130)
            plt.close(fig)
    print(f"Wrote 10 SVG schematics to {OUTPUT}")


if __name__ == "__main__":
    main()
