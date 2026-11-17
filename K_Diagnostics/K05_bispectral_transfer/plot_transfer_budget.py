"""Read saved K05 moments; generate figures without refitting."""
from pathlib import Path
import argparse,json,hashlib
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt


def plot(output):
    a=np.load(output/'transfer_arrays.npz');f=a['frequency_hz']/1e6
    plt.rcParams.update({'font.family':'DejaVu Sans','font.size':11,
        'axes.spines.top':False,'axes.spines.right':False,'svg.hashsalt':'k05-budget'})
    blue,orange,green,gray='#2368a2','#bd6225','#218575','#87929e'
    def save(fig,name):
        for ax in fig.axes:ax.grid(alpha=.15)
        for ext in ['svg','png']:
            fig.savefig(output/f'k05-budget-{name}.{ext}',dpi=160,metadata={'Date':None} if ext=='svg' else None)
        svg = output/f'k05-budget-{name}.svg'
        svg.write_text('\n'.join(line.rstrip() for line in svg.read_text(encoding="utf-8").splitlines())+'\n', encoding="utf-8")
        plt.close(fig)
    def spread(ax,v,label,c):
        ax.plot(f,v.mean(axis=0),color=c,label=label)
        ax.fill_between(f,v.min(axis=0),v.max(axis=0),color=c,alpha=.15)
    px,py,ps=np.moveaxis(a['powers'],-1,0)
    fig,ax=plt.subplots(2,1,figsize=(9,6),sharex=True,layout='constrained')
    spread(ax[0],py/px,r'$P_Y/P_X$',blue)
    ax[0].axhline(1,color=gray,ls=':')
    ax[0].set(ylabel='Measured power ratio',title='Training moments: four whole-capture splits')
    ratio=ps/np.minimum(px,py)
    for j,g in enumerate(a['captures']):ax[1].plot(f,ratio[j],lw=1,label=f'Hold out {g}')
    ax[1].axhline(1,color='black',ls='--',label='Necessary upper bound')
    ax[1].fill_between(f,1,1.32,color='#d85c32',alpha=.08)
    ax[1].set(xlabel=r'Frequency $f$ [MHz]',ylabel=r'$P_* / \min(P_X,P_Y)$',ylim=(.90,1.32))
    for z in ax:z.legend(fontsize=9,ncol=3)
    save(fig,'admissibility')
    fig,ax=plt.subplots(3,1,figsize=(9,7.4),sharex=True,layout='constrained')
    for name,label,c in [('ls','Least squares',blue),('kim','Kim algebraic solution',orange)]:
        l=a[name+'_coef'][:,:,0]
        spread(ax[0],abs(l),label,c)
        spread(ax[2],(l*np.exp(-1j*a['phase'])).real-1,label,c)
    spread(ax[1],a['phase']*180/np.pi,r'$\delta=\arg\langle YX^*\rangle$',green)
    bad=~np.all(a['admissible'],axis=0)
    g=(a['kim_coef'][:,:,0]*np.exp(-1j*a['phase'])).real-1
    ax[2].scatter(f[bad],g.mean(axis=0)[bad],facecolors='white',edgecolors=orange,s=20,zorder=4,label='At least one split violates bound')
    ax[0].set(ylabel=r'$|L|$ [dimensionless]',title='Coefficient estimates and reference phase')
    ax[1].set(ylabel=r'Phase $\delta$ [deg]')
    ax[2].set(xlabel=r'Frequency $f$ [MHz]',ylabel=r'$g_{\rm app}=\mathrm{Re}\,\widetilde L-1$')
    ax[2].axhline(0,color=gray,ls=':')
    for z in ax:z.legend(fontsize=9,loc='best')
    save(fig,'coefficients')
    j=int(np.argmin(abs(f-2)))
    fig,ax=plt.subplots(figsize=(9,4.5),layout='constrained')
    labels=[r'$P_A/P_Y$',r'$C_{AB}/P_Y$',r'$P_B/P_Y$',r'$P_r/P_Y$',r'$C_{pr}/P_Y$','Sum']
    for mi,label,c in [(0,'Least squares',blue),(1,'Kim (bound violated here)',orange)]:
        val=a['budgets'][0,j,mi];val=np.r_[val,val.sum()]
        bars=ax.bar(np.arange(6)+(mi-.5)*.34,val,.32,color=c,label=label)
        for b,v in zip(bars,val):
            ax.text(b.get_x()+b.get_width()/2,v+(.025 if v>=0 else -.025),f'{v:.3f}',
                fontsize=8,ha='center',va='bottom' if v>=0 else 'top')
    ax.axhline(0,color=gray,lw=.8)
    ax.set(xticks=np.arange(6),xticklabels=labels,ylabel='Contribution / measured target power',
        ylim=(-.49,1.70),title=f'Held-out capture 2, f = {f[j]:.6f} MHz: all five terms are retained')
    ax.legend(fontsize=9)
    save(fig,'closure')
    fig,ax=plt.subplots(2,1,figsize=(9,6.4),sharex=True,layout='constrained')
    for mi,label in enumerate(['Least squares','Kim algebraic solution (conditional only)']):
        inc=a['increments'][:,:,mi]
        for vals,l,c in [(inc[:,:,0],r'$2g_{\rm app}$',blue),
            (inc[:,:,1],r'$t_{\rm app}$',orange),(inc[:,:,2],r'$s_{\rm step}$',green),
            (inc[:,:,3]+inc[:,:,4],r'$e_r$ (both residual terms)','#8360a0')]:
            spread(ax[mi],vals,l,c)
        spread(ax[mi],a['test_ratio']-1,r'$(P_Y-P_X)/P_X$','black')
        ax[mi].axhline(0,color=gray,lw=.7)
        ax[mi].set(ylabel='Power change / input power',title=label)
        ax[mi].legend(fontsize=9,ncol=3)
    ax[1].set(xlabel=r'Frequency $f$ [MHz]')
    save(fig,'increments')
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    (output/'plot_provenance.json').write_text(json.dumps(dict(
        arrays_sha256=sha(output/'transfer_arrays.npz'),plot_source_sha256=sha(Path(__file__)),
        figures={p.name:sha(p) for p in output.glob('k05-budget-*')}),indent=2)+'\n', encoding="utf-8")


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True)
    plot(p.parse_args().output)
