# K05 contribution history (Git author dates; edit times include timezone).
# 2026-11-12 10:09 +08:00 | Yinjian Zhao | git ca62b318155e
# 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)

"""Independent analytical teaching diagrams inspired by Brown & Jorns (2023).

No source image, digitized curve, or paper measurement is used. The dimensionless
functions below are deliberately illustrative; see the synthesis page captions.
"""
import argparse
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from analyze_coefficient_walkthrough import save


def main(output):
    output.mkdir(parents=True,exist_ok=True)
    plt.rcParams.update({"font.size":11,"svg.fonttype":"none","axes.grid":True,"grid.alpha":.2})
    u=np.linspace(0,6,500)
    G=lambda x,mu,s:np.exp(-((x-mu)/s)**2)
    spectrum=.15+G(u,1,.5)+.6*G(u,3,.3)+.35*G(u,5,.3)
    growth=.7*G(u,3,.5)+.5*G(u,5,.5)-.5*G(u,1,.4)
    fig,ax=plt.subplots(1,3,figsize=(10.8,3.3),layout="constrained")
    ax[0].plot(u,u+.06*np.sin(np.pi*u),color="#7654a3")
    ax[0].set(xlabel=r"$k_y/k_0$",ylabel=r"$f/f_0$",title="A. A chosen dispersion")
    ax[1].plot(u,spectrum,color="#007c91",label="Location 1")
    ax[1].plot(u,.95*spectrum,"--",color="#d85c32",label="Location 2")
    ax[1].set(xlabel=r"$f/f_0$",ylabel=r"$P/P_0$",title="B. A persistent spectrum");ax[1].legend(fontsize=9)
    ax[2].plot(u,growth,color="#007c91",label="Illustrative growth")
    ax[2].axhline(0,color=".4",lw=.7)
    ax[2].set(xlabel=r"$f/f_0$",ylabel=r"$\gamma/\gamma_0$",title="C. Drive and damping")
    fig.suptitle("Independent schematic - analytical functions, no paper data",fontsize=12)
    save(fig,output,"k05-reading-dispersion-schematic")

    a=np.linspace(-4,4,241);x,y=np.meshgrid(a,a)
    q=np.exp(-((x+y-1)/.32)**2)*np.exp(-((x-y)/6)**2)*(x*y<0)
    transfer=G(u,1,.45)-G(u,3,.45)
    fig,ax=plt.subplots(1,2,figsize=(9.2,3.9),layout="constrained")
    im=ax[0].imshow(q,origin="lower",extent=(-4,4,-4,4),cmap="viridis",vmin=0,vmax=1)
    ax[0].plot([3],[ -2],"wo",ms=5)
    ax[0].annotate(r"$3+(-2)=1$",(3,-2),(-.7,-3.4),color="white",
                   arrowprops=dict(arrowstyle="->",color="white"),fontsize=10)
    ax[0].set(xlabel=r"$f_1/f_0$",ylabel=r"$f_2/f_0$",title="A. Difference-pair geometry",aspect="equal")
    ax[0].grid(False);fig.colorbar(im,ax=ax[0],label=r"Illustrative $|Q|/Q_0$")
    ax[1].plot(u,transfer,color="#202c39")
    ax[1].fill_between(u,0,transfer,where=transfer>=0,color="#007c91",alpha=.35,label="Positive contribution")
    ax[1].fill_between(u,0,transfer,where=transfer<0,color="#d85c32",alpha=.35,label="Negative contribution")
    ax[1].axhline(0,color=".4",lw=.7)
    ax[1].set(xlabel=r"$f/f_0$",ylabel=r"$T/T_0$",title="B. A possible signed pattern")
    ax[1].legend(fontsize=9)
    fig.suptitle("Independent schematic - panel B is prescribed, not inferred from panel A",fontsize=11)
    save(fig,output,"k05-reading-transfer-schematic")


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--output",type=Path,required=True)
    main(p.parse_args().output)
