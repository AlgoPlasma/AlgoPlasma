# K05 contribution history (Git author dates; edit times include timezone).
# 2026-11-13 13:10 +08:00 | Yinjian Zhao | git dfd0f9af0503
# 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)

"""Paired, attributed reference redraws and conditional probe diagnostics.

Only digitized numbers are read for the reference side; no paper screenshot is
embedded. These source-derived readings are not author raw data. See the
reference_digitization README for provenance and reuse limitations.
"""
from pathlib import Path
import argparse
import hashlib
import json
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import ScalarFormatter, FixedLocator
from analyze_paper_comparison import symmetric_q_map

REF=Path(__file__).with_name('reference_digitization')
COLORS={'reference':'#245ab6','model':'#c67611','ls':'#087d82','kim':'#9a3f8e'}


def trace(name):
    return np.loadtxt(REF/(name+'_digitized.csv'),delimiter=',',skiprows=1).T


def frame(ax):
    ax.tick_params(direction='in',top=True,right=True)
    ax.grid(alpha=.13)


def sci(ax,axis,power):
    fmt=ScalarFormatter(useMathText=True);fmt.set_powerlimits((power,power));fmt.set_useOffset(False)
    getattr(ax,axis+'axis').set_major_formatter(fmt)


def spread(ax,f,values,label,color,style='-'):
    ax.plot(f,np.nanmean(values,axis=0),label=label,color=color,ls=style)
    ax.fill_between(f,np.nanmin(values,axis=0),np.nanmax(values,axis=0),color=color,alpha=.12)


def save(fig,output,name):
    for ext in ('svg','png'):
        fig.savefig(output/('k05-compare-'+name+'.'+ext),dpi=150,bbox_inches='tight')
    plt.close(fig)


def plot(extended,comparison,output):
    output.mkdir(parents=True,exist_ok=True)
    a=np.load(extended/'extended_arrays.npz')
    old=np.load(comparison/'comparison_arrays.npz')
    f=a['frequency_hz']; fm=f/1e6
    speed=2150.; separation=.0037; inverse_time=speed/separation
    gamma=a['increments'][:,:,:,0]*inverse_time/2
    transfer=a['increments'][:,:,:,1]*a['test_powers'][:,:,0,None]*inverse_time/2
    good=a['admissible'].all(axis=0)&a['identified'].all(axis=0)
    plt.rcParams.update({'font.family':'DejaVu Sans','font.size':11,
        'axes.labelsize':12,'axes.titlesize':12,'legend.fontsize':9,
        'lines.linewidth':1.3,'svg.fonttype':'none','svg.hashsalt':'k05-r43'})

    # Figure 2(a): the experimental side is an assumed model, not measured k.
    fig,axs=plt.subplots(1,2,figsize=(10.5,3.9),layout='constrained')
    axs[0].plot(*trace('dispersion'),color=COLORS['reference'],ls='--')
    axs[1].plot(old['dispersion_ky'],old['dispersion_omega'].real/(2*np.pi),color=COLORS['ls'])
    for ax in axs:
        ax.set(xlim=(0,1e4),ylim=(0,5e7),xlabel=r'Azimuthal wave number $k_y$ (m$^{-1}$)')
        sci(ax,'y',7);frame(ax)
    axs[0].set(title='[1], Fig. 2(a): approximate redraw',ylabel=r'Source ordinate $\omega_k$ [Hz]')
    axs[1].set(title='Assumed kinetic branch for this experiment',ylabel=r'$f=\omega_r/(2\pi)$ (Hz)')
    save(fig,output,'dispersion')
    fig,axs=plt.subplots(1,2,figsize=(10.5,3.6),layout='constrained')
    axs[0].plot(old['dispersion_ky'],old['dispersion_omega'].real/(2*np.pi)/1e6,color=COLORS['ls'])
    axs[0].set(xlabel=r'$k_y$ (m$^{-1}$)',ylabel=r'$f=\omega_r/(2\pi)$ (MHz)',title='Same branch, local scale')
    axs[1].plot(old['dispersion_omega'].real/(2*np.pi)/1e6,old['dispersion_vg']/1e3,color=COLORS['ls'],label='Branch derivative')
    axs[1].axhline(speed/1e3,color=COLORS['model'],ls='--',label='Assumed reference speed')
    axs[1].set(xlabel='$f$ (MHz)',ylabel=r'$v_{g,y}$ (km/s)',title='No branch extrapolation above 5.59 MHz')
    axs[1].legend()
    for ax in axs:frame(ax)
    save(fig,output,'dispersion-local')

    fig,axs=plt.subplots(1,2,figsize=(10.5,3.9),layout='constrained')
    for name,label,style,color in [('psd_x','$P_x$','-',COLORS['reference']),('psd_y','$P_y$','--',COLORS['model'])]:
        axs[0].loglog(*trace(name),label=label,ls=style,color=color)
    for key,label,style in [('psd_c1',r'$S_{XX}^{+}$: C1','-'),('psd_c3',r'$S_{YY}^{+}$: C3','--')]:
        axs[1].loglog(old['psd_frequency_hz'][1:],old[key].mean(0)[1:]*1e12,label=label,ls=style)
    for ax in axs:
        ax.set(xlim=(1e5,1e8),ylim=(.2,4000),xlabel='$f$ (Hz)')
        ax.xaxis.set_major_locator(FixedLocator([1e6,1e7,1e8]));ax.yaxis.set_major_locator(FixedLocator([1,100]));frame(ax);ax.legend()
    axs[0].set(title='[1], Fig. 2(b): approximate redraw',ylabel=r'Source power spectrum $P$ (Hz$^{-1}$)')
    axs[1].set(title='Measured voltage spectra; four-record mean',ylabel=r'$S^+(f)$ ($\mu$V$^2$/Hz)')
    save(fig,output,'spectra')

    def growth_axes(local=False):
        fig,axs=plt.subplots(1,2 if not local else 1,figsize=(10.5,4.4),squeeze=False)
        fig.subplots_adjust(left=.08,right=.92,bottom=.18,top=.85,wspace=.63)
        axs=axs.ravel()
        if not local:
            ax=axs[0];right=ax.twinx()
            ax.plot(*trace('growth_measured'),color=COLORS['reference'],label=r'Source $\gamma_{f(y)}$')
            right.plot(*trace('growth_model'),color=COLORS['model'],ls='--',label=r'Source $\gamma_f$')
            right.set(ylim=(-.5e6,3e6),ylabel=r'Model $\gamma_f$ (s$^{-1}$)');sci(right,'y',6)
            ax.set(title='[1], Fig. 2(c): approximate redraw',ylim=(-.5e5,3e5))
            ax.legend(loc='upper left');right.legend(loc='upper right')
        ax=axs[-1];right=ax.twinx()
        for mi,name,label,style in [(0,'ls','Joint LS','-'),(1,'kim','Kim','--')]:
            spread(ax,f,gamma[:,:,mi],label,COLORS[name],style)
        ax.plot(f[~good],gamma[:,~good,1].mean(0),'o',ms=2.6,mfc='none',mec=COLORS['kim'])
        right.plot(old['dispersion_omega'].real/(2*np.pi),old['dispersion_omega'].imag,
                   color=COLORS['model'],ls=':',label='Separate kinetic model')
        right.set_ylabel(r'Model $\gamma_{\rm th}$ (s$^{-1}$)')
        ax.set_title('Voltage-model rates\nAssumed $v_*=2.15$ km/s')
        if not local:
            ax.set_ylim(-.5e5,3e5);right.set_ylim(-.5e6,3e6)
            for mi,color in [(0,COLORS['ls']),(1,COLORS['kim'])]:
                below=gamma[:,:,mi].mean(0)<-.5e5
                ax.plot(f[below],np.full(below.sum(),-.5e5),'v',color=color,ms=3,clip_on=False)
                above=gamma[:,:,mi].mean(0)>3e5
                ax.plot(f[above],np.full(above.sum(),3e5),'^',color=color,ms=3,clip_on=False)
        else:
            ax.set_xlim(.5e6,20e6)
        ax.legend(loc='lower left',ncol=2);right.legend(loc='upper right')
        for axis in axs:
            axis.set(xlabel='$f$ (Hz)',ylabel=r'Apparent amplitude rate $\gamma_{y,\rm app}$ (s$^{-1}$)')
            if not local:axis.set_xlim(0,3.5e7)
            sci(axis,'x',7 if not local else 6);sci(axis,'y',5);frame(axis);axis.axhline(0,color='.5',lw=.5)
        if not local:
            axs[0].set_ylabel(r'Diagnosed rate $\gamma_{f(y)}$ (s$^{-1}$)')
        sci(right,'y',6 if not local else 5)
        save(fig,output,'growth-local' if local else 'growth')
    growth_axes();growth_axes(True)

    maps={}
    for method in ('ls','kim'):
        fold_maps=[]
        for g in range(4):
            bins,m=symmetric_q_map(a['pairs'],a['pair_count'],a[method+'_coef'][g,:,1:])
            fold_maps.append(abs(m))
        stack=np.array(fold_maps)
        # All four are fitted; preserve all-NaN blank cells without a warning.
        count=np.sum(np.isfinite(stack),axis=0)
        maps[method]=np.divide(np.nansum(stack,axis=0),count,out=np.full(count.shape,np.nan),where=count>0)
    spacing=float(np.median(np.diff(f)))
    extent=(bins[0]*spacing-spacing/2,bins[-1]*spacing+spacing/2)*2
    heat=np.load(REF/'paper_heatmap_digitized.npz')
    fig,axs=plt.subplots(1,2,figsize=(10.5,4.5),layout='constrained')
    for ax,z,ext,title,label in [(axs[0],heat['log_q'],heat['extent_hz'],'[1], Fig. 3(a): image-derived redraw',r'Source $\log_{10}|Q_f^{1,2}|$'),
            (axs[1],np.log10(maps['kim']),extent,'Kim coefficients; retain failed bounds',r'$\log_{10}(|Q^{\rm sym}|/\mathrm{V}^{-1})$')]:
        im=ax.imshow(z,origin='lower',extent=ext,cmap='magma',vmin=-2,vmax=1,interpolation='nearest',rasterized=True)
        ax.set(xlim=(-5e7,5e7),ylim=(-5e7,5e7),xlabel='$f_1$ (Hz)',ylabel='$f_2$ (Hz)',title=title)
        sci(ax,'x',7);sci(ax,'y',7);fig.colorbar(im,ax=ax,shrink=.8,label=label,ticks=[-2,-1,0,1])
    save(fig,output,'coupling')
    finite=np.r_[np.log10(maps['ls'][np.isfinite(maps['ls'])]),np.log10(maps['kim'][np.isfinite(maps['kim'])])]
    local_limits=(float(finite.min()),float(finite.max()))
    fig,axs=plt.subplots(1,2,figsize=(10.5,4.5),layout='constrained')
    for ax,method,title in zip(axs,['ls','kim'],['Joint LS','Kim; necessary bounds often fail']):
        im=ax.imshow(np.log10(maps[method]),origin='lower',extent=np.array(extent)/1e6,
            cmap='magma',vmin=local_limits[0],vmax=local_limits[1],rasterized=True)
        ax.set(xlabel='$f_1$ (MHz)',ylabel='$f_2$ (MHz)',title=title)
        fig.colorbar(im,ax=ax,shrink=.8,label=r'$\log_{10}(|Q^{\rm sym}|/\mathrm{V}^{-1})$')
    save(fig,output,'coupling-local')

    fig,axs=plt.subplots(1,2,figsize=(10.5,4.2),layout='constrained')
    axs[0].semilogx(*trace('transfer'),color=COLORS['reference'],ls='--')
    for mi,method,style in [(0,'ls','-'),(1,'kim','--')]:
        spread(axs[1],f,transfer[:,:,mi],method.upper() if mi==0 else 'Kim',COLORS[method],style)
    axs[1].plot(f[~good],transfer[:,~good,1].mean(0),'o',ms=3,mfc='none',mec=COLORS['kim'])
    for ax in axs:
        ax.set(xscale='log',xlim=(1e5,1e8),ylim=(-4e7,4e7),xlabel='$f$ (Hz)');sci(ax,'y',7)
        ax.axhline(0,color='.45',lw=.6);frame(ax)
    axs[0].set(title='[1], Fig. 3(b): approximate redraw',ylabel=r'Source transfer $T_f$ (source normalization)')
    axs[1].set(title='Conditional voltage contribution; $v_*=2.15$ km/s',ylabel=r'$T_f^{(1/2)}$ (V$^2$/s)');axs[1].legend()
    save(fig,output,'transfer')
    fig,axs=plt.subplots(2,2,figsize=(10.5,6.5),layout='constrained')
    for col,(lo,hi) in enumerate([(.5,5),(5,20)]):
        sel=(fm>=lo)&(fm<hi)
        for mi,method,style in [(0,'ls','-'),(1,'kim','--')]:
            spread(axs[0,col],fm[sel],transfer[:,sel,mi],method.upper() if mi==0 else 'Kim',COLORS[method],style)
            spread(axs[1,col],fm[sel],a['increments'][:,sel,mi,1]*100,method.upper() if mi==0 else 'Kim',COLORS[method],style)
        for row in range(2):
            axs[row,col].set(xlabel='$f$ (MHz)',xlim=(lo,hi));axs[row,col].axhline(0,color='.5',lw=.6);frame(axs[row,col])
        axs[0,col].set_title(f'{lo:g}–{hi:g} MHz; same 20 MHz input basis')
        axs[0,col].legend()
    for ax in axs[0]:ax.set_ylabel(r'$T_f^{(1/2)}$ (V$^2$/s)')
    for ax in axs[1]:ax.set_ylabel(r'Across-gap contribution $t_f$ (%)')
    save(fig,output,'transfer-local')

    fig,axs=plt.subplots(2,2,figsize=(10.5,6.8),layout='constrained')
    spread(axs[0,0],fm,a['coherence'],'Training coherence','#47586e')
    axs[0,0].set(ylabel=r'$C_{XY}^2$',ylim=(0,1.02),title='Same-frequency linear information')
    for mi,label,color,style in [(0,'Linear only','#555','-'),(1,'Joint LS',COLORS['ls'],'-'),(2,'Kim',COLORS['kim'],'--')]:
        spread(axs[0,1],fm,a['nmse'][:,:,mi],label,color,style)
    axs[0,1].set(ylabel=r'Held-out NMSE $\epsilon_f$',title='Does the model predict new records?');axs[0,1].legend()
    fractions=a['powers'][:,:,2]/np.minimum(a['powers'][:,:,0],a['powers'][:,:,1])
    spread(axs[1,0],fm,fractions,'Common-power bound',COLORS['kim'])
    axs[1,0].axhline(1,color='k',ls=':',label='Necessary upper bound')
    axs[1,0].set(ylabel=r'$P_*/\min(P_X^{\rm train},P_Y^{\rm train})$',title='A value above 1 fails the Kim bound');axs[1,0].legend()
    for col,label,color,style in [(1,r'Quadratic $t_f$',COLORS['ls'],'-'),(2,r'Finite-step square $s_f$',COLORS['model'],'--'),(3,r'Residual $r_f$','#555',':')]:
        spread(axs[1,1],fm,100*a['increments'][:,:,0,col],label,color,style)
    axs[1,1].set(ylabel='Contribution / $P_X$ (%)',title='Joint-LS power budget: retained corrections');axs[1,1].legend()
    for ax in axs.flat:ax.set(xlabel='$f$ (MHz)',xlim=(.5,20));frame(ax)
    save(fig,output,'reliability')
    source_files=[extended/'extended_arrays.npz',comparison/'comparison_arrays.npz',Path(__file__)]+list(REF.glob('*.csv'))+[REF/'paper_heatmap_digitized.npz']
    manifest=dict(inputs={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in source_files},
        assumed_speed_m_per_s=speed,separation_m=separation,local_q_log_limits=local_limits,
        gamma_mean_below_reference_axis=[int((gamma[:,:,mi].mean(0)<-5e4).sum()) for mi in (0,1)],
        gamma_mean_above_reference_axis=[int((gamma[:,:,mi].mean(0)>3e5).sum()) for mi in (0,1)],
        kim_pass_all_folds=int(good.sum()),targets=len(f),
        transfer_mean_ranges={name:[float(transfer[:,:,mi].mean(0).min()),float(transfer[:,:,mi].mean(0).max())] for mi,name in enumerate(['ls','kim'])},
        figures={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in output.glob('k05-compare-*')})
    (output/'plot_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--extended',type=Path,required=True)
    p.add_argument('--comparison',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    a=p.parse_args();plot(a.extended,a.comparison,a.output)
