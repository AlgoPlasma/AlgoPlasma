"""Render English figures from local B04 data; run `bash run.sh double debug` first.

Run with Python, NumPy and Matplotlib. Both documentation languages use
the same English figures.
"""
from pathlib import Path
import argparse
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import TwoSlopeNorm

HERE = Path(__file__).resolve().parent
DATA = HERE/'build/double-debug'
OUT = HERE/'build/figures'


def render():
    plt.rcParams.update({'font.family':'sans-serif',
        'font.sans-serif':['Microsoft YaHei','Noto Sans CJK SC','DejaVu Sans'],
        'font.size':11,'mathtext.fontset':'stix','axes.unicode_minus':False,
        'axes.spines.top':False,'axes.spines.right':False,'figure.facecolor':'white'})
    blue,orange='#245779','#d47428'
    hand=np.genfromtxt(DATA/'hand_nodes.csv',delimiter=',',names=True)
    active=hand[(hand['i']<=1)&(hand['j']<=1)&(hand['k']<=1)]
    assert len(active)==8 and abs(hand['amount'].sum()-8)<1e-14
    fig,axs=plt.subplots(1,3,figsize=(14,5.1),gridspec_kw={'width_ratios':[1,1,1.5]})
    fig.subplots_adjust(left=.06,right=.98,bottom=.24,top=.79,wspace=.38)
    fig.suptitle('Single-particle assignment: nodal amounts and reference',fontsize=17)
    for k,ax in enumerate(axs[:2]):
        ax.plot([1,2,2,1,1],[0,0,1,1,0],color='#adbcc5')
        for row in active[active['k']==k]:
            i,j=int(row['i']),int(row['j'])
            ax.plot([1.25,row['r']],[.5,row['phi']],':',color='#bdc7ce')
            ax.scatter(row['r'],row['phi'],s=65,color=blue,zorder=3)
            ax.annotate(f'({i},{j},{k})\n{row["amount"]:.2f}',(row['r'],row['phi']),
                xytext=(9 if i==0 else -9,10 if j==0 else -10),textcoords='offset points',
                ha='left' if i==0 else 'right',va='bottom' if j==0 else 'top',color=blue)
        ax.scatter(1.25,.5,marker='*',s=170,color=orange,zorder=4)
        ax.set(xlim=(.86,2.14),ylim=(-.14,1.14),xlabel='r',ylabel=r'$\phi$ / rad',title=f'z = {2*k}')
    ax=axs[2]
    x=np.arange(8)
    ax.bar(x,active['amount_reference'],color='#d6e1e8',label='Hand reference')
    ax.plot(x,active['amount'],'o',mfc='white',mec=orange,mew=1.7,label='B04')
    ax.set_xticks(x,[f'({int(p["i"])},{int(p["j"])},{int(p["k"])})' for p in active],rotation=40,ha='right',fontsize=9)
    ax.set(ylabel=r'$D_a V_a$',ylim=(0,2.8),title='Eight nodal amounts')
    ax.legend(frameon=False)
    fig.text(.06,.055,'Stars: projections of the same particle. Total = 8; maximum absolute difference = 0 for this case.')
    fig.savefig(OUT/'hand_en.png',dpi=180,bbox_inches='tight',pad_inches=.15)
    plt.close(fig)

    nodes=np.genfromtxt(DATA/'uniform_nodes.csv',delimiter=',',names=True)
    assert len(nodes)==80 and np.max(np.abs(nodes['relative_error']))<2048*np.finfo(float).eps
    plane=nodes[nodes['j']==0]; line=plane[plane['k']==0]
    r,z=np.unique(nodes['r']),np.unique(nodes['z'])
    fig,axs=plt.subplots(1,3,figsize=(14,5.2))
    fig.subplots_adjust(left=.06,right=.96,bottom=.24,top=.79,wspace=.4)
    fig.suptitle('Nonuniform cylindrical grid: constant-density recovery',fontsize=17)
    for ax in [axs[0],axs[2]]:
        for v in r: ax.axvline(v,lw=.7,color='#ccd4da',zorder=0)
        for v in z: ax.axhline(v,lw=.7,color='#ccd4da',zorder=0)
        ax.set(xlim=(-.045,1.045),ylim=(-.36,1.06),xticks=r,yticks=z,xlabel='r',ylabel='z')
        ax.tick_params(axis='x',rotation=45,labelsize=9)
    axs[0].scatter(plane['r'],plane['z'],s=28,color=blue)
    axs[0].set_title('Actual nodes, phi = 0')
    axs[1].axhline(3.25,color=blue,label='Reference 3.25')
    axs[1].plot(line['r'],line['density'],'o',mfc='white',mec=orange,mew=1.6,label='B04')
    axs[1].set(xlabel='r',ylabel='D',ylim=(0,4),title='phi = 0, z = -0.3')
    axs[1].legend(frameon=False,loc='lower right')
    points=axs[2].scatter(plane['r'],plane['z'],c=plane['relative_error']*1e16,
        cmap='RdBu_r',norm=TwoSlopeNorm(0,vmin=-10,vmax=10),s=90,edgecolors='#536775',lw=.4)
    axs[2].set_title('Nodal relative error, phi = 0')
    cb=fig.colorbar(points,ax=axs[2],fraction=.05,pad=.04)
    cb.set_label(r'$[(D-D_0)/D_0]\times10^{16}$')
    maximum=np.max(np.abs(nodes['relative_error']))
    fig.text(.06,.07,'384 Gauss contributions, 80 independent nodes; errors shown without spatial interpolation.')
    fig.text(.06,.015,f'Global maximum relative error = {maximum:.3e}; pass threshold = 4.547e-13.')
    fig.savefig(OUT/'uniform_en.png',dpi=180,bbox_inches='tight',pad_inches=.15)
    plt.close(fig)


def render_axis():
    plt.rcParams.update({'font.family':'sans-serif',
        'font.sans-serif':['Microsoft YaHei','Noto Sans CJK SC','DejaVu Sans'],
        'font.size':12,'mathtext.fontset':'stix','axes.unicode_minus':False,
        'axes.spines.top':False,'axes.spines.right':False,'figure.facecolor':'white'})
    data=np.genfromtxt(DATA/'axis_nodes.csv',delimiter=',',names=True)
    nodes=data[data['k']==0]
    assert len(nodes)==4
    x=nodes['j']
    reference=nodes['reference'][0]
    assert np.max(np.abs(nodes['density_after']-reference)) <= 2048*np.finfo(float).eps*abs(reference)
    fig,ax=plt.subplots(figsize=(11,5.3))
    fig.subplots_adjust(left=.10,right=.97,bottom=.22,top=.82)
    fig.suptitle('Axis averaging: four angular entries share one density',fontsize=17)
    ax.bar(x,nodes['density_before'],width=.50,color='#cbdde8',edgecolor='#68899e',
           label='Density before the call')
    ax.axhline(reference,color='#245779',lw=1.8,
               label=f'Weighted reference {reference:.8f}')
    ax.axhline(np.mean(nodes['density_before']),color='#777777',ls=':',lw=1.5,
               label='Equal-weight mean 3.75')
    ax.scatter(x,nodes['density_after'],marker='s',s=85,facecolors='white',edgecolors='#c26019',
               linewidths=2,zorder=5,label='Density returned by B04')
    for xx,yy in zip(x,nodes['density_before']):
        ax.annotate(f'{yy:g}',(xx,yy),xytext=(0,-6),textcoords='offset points',
                    ha='center',va='top',color='#245779')
    ax.set(xticks=x,xlim=(-.6,3.6),ylim=(0,9.4),
           xlabel='Angular storage index j (one physical axis point, k = 0)',
           ylabel='Nodal density D')
    ax.legend(frameon=False,loc='upper left',ncols=2,fontsize=10.5)
    fig.text(.10,.07,'Bars: input [1, 2, 4, 8]; squares: actual routine output; solid line: independent reference.',fontsize=11)
    fig.text(.10,.02,'Nonuniform angular spacing gives unequal integral weights; all four entries represent r = 0.',fontsize=11)
    fig.savefig(OUT/'axis_average_en.png',dpi=180,bbox_inches='tight',pad_inches=.15)
    plt.close(fig)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--axis-only',action='store_true',help='Render only the axis-averaging results.')
    parser.add_argument('--data-dir',type=Path,default=DATA,help='Double-precision CSV directory produced by run.sh.')
    parser.add_argument('--output-dir',type=Path,default=OUT,help='Figure directory (default: ignored build/figures).')
    options=parser.parse_args()
    DATA=options.data_dir
    OUT=options.output_dir
    required=['axis_nodes.csv'] if options.axis_only else ['hand_nodes.csv','uniform_nodes.csv','axis_nodes.csv']
    missing=[str(DATA/name) for name in required if not (DATA/name).is_file()]
    if missing:
        parser.error('Missing CSV data: '+', '.join(missing)+'. Run bash run.sh double debug first.')
    OUT.mkdir(parents=True,exist_ok=True)
    if not options.axis_only:
        render()
    render_axis()
    print(f'English figures written to {OUT}.')
