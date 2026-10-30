"""Figures for the applied mean-I–V workflow; all plotted curves are reproducible."""
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

BLUE, ORANGE, GREEN, GRAY = '#2368a2', '#bd6225', '#238269', '#6b7280'


def make_plots(summary, arrays, output):
    plt.rcParams.update({'font.family':'DejaVu Sans','font.size':11,
        'axes.spines.top':False,'axes.spines.right':False,'svg.hashsalt':'k05-sweep-mean'})
    r=next(x for x in summary['records'] if x['file']=='10140015.WDF')
    a=arrays[15];v,i=a['bins'][:,:2].T; f=r['main_fit']
    ion=np.polyval(f['ion_coeff_a'],v);ie=i-ion
    def save(fig,name):
        for ax in fig.axes: ax.grid(alpha=.17)
        fig.savefig(output/f'k05-sweep-{name}.svg',metadata={'Date':None})
        fig.savefig(output/f'k05-sweep-{name}.png',dpi=160)
        svg = output/f'k05-sweep-{name}.svg'
        svg.write_text('\n'.join(line.rstrip() for line in svg.read_text().splitlines())+'\n')
        plt.close(fig)

    fig,ax=plt.subplots(2,1,figsize=(9,5.1),sharex=True,layout='constrained')
    t,s,u,q16,q84=a['overview'].T
    ax[0].plot(t,s,color=BLUE,label='CH3_2: 2 ms mean')
    ax[1].fill_between(t,q16,q84,color=ORANGE,alpha=.16,label='16–84% sample spread')
    ax[1].plot(t,u,color=ORANGE,lw=1,label='CH4_2: 2 ms mean')
    for z in ax:
        z.axvspan(*r['ramp_time_s'],color=GREEN,alpha=.12,label='Selected upward ramp')
        z.legend(fontsize=9,loc='upper left',ncol=2)
    ax[0].set(ylabel=r'Supply $V_s$ [V]',title='Select the ramp; keep the hold and return separate')
    ax[1].set(xlabel=r'Time from record start $t$ [s]',ylabel=r'Resistor voltage $u_R$ [V]',xlim=(0,10))
    save(fig,'raw')

    fig,ax=plt.subplots(1,2,figsize=(9,4),layout='constrained')
    sample=a['example_current']*1e3;ex=r['bin_example']
    ax[0].scatter(a['example_supply'],sample,s=7,alpha=.4,color=GRAY)
    ax[0].set(xlabel=r'Supply $V_s$ [V]',ylabel=r'Net current $I$ [mA]',title=f'{len(sample)} samples in one 1 V bin',xlim=(75,76))
    ax[1].hist(sample,bins=40,color='#a4c3db',edgecolor='white')
    ax[1].set(xlabel=r'Net current $I$ [mA]',ylabel='Sample count',title='The distribution has a positive tail')
    for z in ax:
        for value,label,c in [(ex['mean_current_a']*1e3,'Mean',BLUE),(ex['median_current_a']*1e3,'Median',ORANGE)]:
            if z is ax[0]:z.axhline(value,color=c,lw=1.8,label=f'{label}: {value:.3f} mA')
            else:z.axvline(value,color=c,lw=1.8,label=f'{label}: {value:.3f} mA')
        z.legend(fontsize=9)
    save(fig,'bin')

    fig,ax=plt.subplots(1,2,figsize=(9,4.2),layout='constrained')
    ax[0].plot(v,i*1e3,color=BLUE,label=r'Mean net current $\bar{I}$')
    ax[0].axhline(0,color=GRAY,lw=.8);ax[0].axvline(r['floating_v'],color=GREEN,ls=':',label=fr'$V_f={r["floating_v"]:.2f}$ V')
    ax[0].set(xlim=(-100,240),ylim=(-1,17),xlabel=r'Probe voltage $\bar{V}_p$ [V]',ylabel=r'Current $I$ [mA]',title='Full mean I–V curve')
    ax[1].plot(v,i*1e3,'.',color=BLUE,label='Mean net current')
    ax[1].plot(v,ion*1e3,'--',color=ORANGE,label=r'Linear $I_{\rm ion,fit}$')
    ax[1].axvspan(*f['ion_window_v'],color=GREEN,alpha=.12,label='Background fit interval')
    ax[1].set(xlim=(-95,-30),ylim=(-.65,.3),xlabel=r'Probe voltage $\bar{V}_p$ [V]',ylabel=r'Current $I$ [mA]',title='Fit the negative-current branch first')
    for z in ax:z.legend(fontsize=9)
    save(fig,'background')

    fig,ax=plt.subplots(1,2,figsize=(9,4.3),layout='constrained')
    for peak,derivative in zip(r['candidate_tests'],a['derivatives']):
        ax[0].plot(a['derivative_grid'],derivative*1e3,lw=1,label=f'{peak["span_v"]} V')
    ax[0].axvline(r['plasma_candidate_v'],color=GRAY,ls='--',lw=1)
    ax[0].set(xlim=(-35,35),xlabel=r'Probe voltage $\bar{V}_p$ [V]',ylabel=r'$d\bar{I}/d\bar{V}_p$ [mA/V]',title=fr'Candidate $V_{{\rm pl}}^{{*}}={r["plasma_candidate_v"]:.1f}$ V')
    ax[0].legend(title='Smoothing span',fontsize=8,title_fontsize=9,ncol=2)
    valid=ie>0
    ax[1].plot(v[valid],np.log(ie[valid]/1e-3),'.-',ms=3,lw=.8,color='#7c9fb9',label='After ion subtraction')
    lo,hi=f['electron_window_v'];x=np.array(f['actual_window_v'])
    ax[1].axvspan(lo,hi,color=BLUE,alpha=.09)
    ax[1].plot(x,f['slope_per_v']*x+f['intercept'],color=BLUE,lw=2.8,label=fr'$m={f["slope_per_v"]:.5f}$ V$^{{-1}}$')
    ax[1].set(xlim=(-40,20),ylim=(-3,2.8),xlabel=r'Probe voltage $\bar{V}_p$ [V]',ylabel=r'$\ln[I_e/(1\,\mathrm{mA})]$',title=fr'$T_{{e,\rm fit}}=1/m={f["te_ev"]:.2f}$ eV')
    ax[1].legend(fontsize=9,loc='lower right')
    save(fig,'fit')

    fig,ax=plt.subplots(1,2,figsize=(9,4.2),layout='constrained')
    ov,oi=a['legacy_curve'][:,:2].T
    for x,y,label,c in [(v,i,'Supply-bin mean',BLUE),(ov,oi,'Probe-bin median',ORANGE)]:
        ax[0].plot(x,y*1e3,color=c,label=label)
    ax[0].axhline(0,color=GRAY,lw=.8)
    ax[0].set(xlim=(-45,12),ylim=(-.7,10),xlabel=r'Probe voltage $V_p$ [V]',ylabel=r'Net current $I$ [mA]',title='Same record, different summary curves')
    old_e=oi-np.polyval(a['legacy_ion_coeff'],ov)
    for x,y,window,label,c in [(v,ie,f['electron_window_v'],f'Mean workflow: {f["te_ev"]:.2f} eV',BLUE),
                             (ov,old_e,a['legacy_window'],f'Median workflow: {summary["comparison"][0]["te_ev"]:.2f} eV',ORANGE)]:
        ok=y>0;sel=ok&(x>=window[0])&(x<=window[1])
        co=np.polyfit(x[sel],np.log(y[sel]/1e-3),1)
        ax[1].plot(x[ok],np.log(y[ok]/1e-3),color=c,alpha=.35)
        xp=[x[sel].min(),x[sel].max()];ax[1].plot(xp,np.polyval(co,xp),color=c,lw=3,label=label)
    ax[1].set(xlim=(-40,15),ylim=(-3,2.8),xlabel=r'Probe voltage $V_p$ [V]',ylabel=r'$\ln[I_e/(1\,\mathrm{mA})]$',title='A steeper fitted line gives a smaller 1/m')
    for z in ax:z.legend(fontsize=9)
    save(fig,'comparison')

    fig,ax=plt.subplots(1,2,figsize=(9,4.3),layout='constrained')
    matrix=np.array([[next(q['te_ev'] for q in r['sensitivity'] if q['valid'] and q['lower_margin_v']==l and
                         q['upper_margin_v']==u and q['ion_window_v']==[-80,-50] and q['ion_model']=='linear')
                     for u in [3,5,8]] for l in [0,2,5]])
    ax[0].imshow(matrix,cmap='YlGnBu',vmin=8.5,vmax=10.5)
    for j in range(3):
        for k in range(3):ax[0].text(k,j,f'{matrix[j,k]:.2f}',ha='center',va='center',color='black')
    ax[0].add_patch(Rectangle((.5,.5),1,1,fill=False,ec=ORANGE,lw=2.5))
    ax[0].set(xticks=[0,1,2],xticklabels=['3','5','8'],yticks=[0,1,2],yticklabels=['0','2','5'],
        xlabel=r'Upper margin $V_{\rm pl}^{*}-V_{\rm high}$ [V]',ylabel=r'Lower margin $V_{\rm low}-V_f$ [V]',title=r'Electron fit bounds: $T_{e,\rm fit}$ [eV]')
    ions=summary['config']['ion_window_tests_v']
    for model,offset,c in [('linear',-.08,BLUE),('constant',.08,ORANGE)]:
        vals=[next(q['te_ev'] for q in r['sensitivity'] if q['valid'] and q['lower_margin_v']==2 and q['upper_margin_v']==5 and q['ion_window_v']==ion and q['ion_model']==model) for ion in ions]
        ax[1].plot(np.arange(4)+offset,vals,'o',color=c,label=model.title()+' background')
    ax[1].axhline(f['te_ev'],color=GRAY,ls=':',lw=1)
    ax[1].set(xticks=np.arange(4),xticklabels=['−90:−60','−80:−50','−70:−40','−90:−40'],
        xlabel='Ion-background interval [V]',ylabel=r'Slope temperature $T_{e,\rm fit}$ [eV]',title='Keep the central electron window fixed')
    ax[1].tick_params(axis='x',labelsize=9);ax[1].legend(fontsize=9)
    save(fig,'sensitivity')

    fig,ax=plt.subplots(figsize=(9,4.5),layout='constrained')
    ax.plot(v,i*1e3,color=BLUE,label='Example mean I–V')
    ax.plot(v,ion*1e3,'--',color=GRAY,label=r'Extrapolated $I_{\rm ion,fit}$')
    xp=np.linspace(-90,5,100)
    for sc,c in zip(summary['operating_scenarios'],[GREEN,ORANGE,'#8053a0']):
        vc=sc['cathode_to_chamber_v'];x=sc['probe_to_chamber_v'];y=sc['net_current_a']*1e3
        ax.plot(xp,(vc-40.5-xp),color=c,lw=.8,alpha=.4)
        ax.plot(x,y,'o',color=c,label=fr'Assumed $V_c={vc:+.0f}$ V: $V_p={x:.1f}$ V')
    ax.set(xlim=(-90,0),ylim=(-2,4),xlabel=r'Probe voltage $V_p$ [V]',ylabel=r'Net current $I$ [mA]',title='Use the mean curve to locate conditional operating points')
    ax.legend(fontsize=9,loc='upper left')
    save(fig,'bias')
