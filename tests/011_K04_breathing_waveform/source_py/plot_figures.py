"""Redraw K04 Figures 1-12 from saved numerical results; no GUI required."""
import argparse
from pathlib import Path
from _paths import CASE_DIR
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from run_example import DEFAULT_OUTPUT


def make_figures(data, output_dir):
    """Save the twelve PNG files referenced by the K04 learning page."""
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    t = data['t']
    fs = data['fs']
    xs = data['xs']
    truths = data['truths']
    F = data['F']
    f = data['f']
    f0 = data['f0']
    F_hat = data['F_hat']
    z = data['z']
    phi = data['phi']
    theta = data['theta']
    B = data['B']
    mu = data['mu']
    K_train = data['K_train']
    a = data['a']
    gamma = data['gamma']
    w = data['w']
    H = data['H']
    positions = data['positions']
    C = data['C']
    R = data['R']
    C_known = data['C_known']
    error = data['error']
    res_mean = data['res_mean']
    res_rms = data['res_rms']
    B, H = int(B), int(H)
    plt.rcParams.update({'font.family':'DejaVu Sans','font.size':11,'axes.spines.top':False,
        'axes.spines.right':False,'axes.titleweight':'bold','axes.grid':True,'grid.alpha':.15,
        'figure.facecolor':'white','text.color':'#273748','axes.labelcolor':'#273748'})
    blue,orange,teal,gray,purple = '#2764a1','#d77725','#158477','#87949e','#783daf'
    def save(fig, name):
        fig.savefig(output_dir/f'r3_{name}.png', dpi=175, bbox_inches='tight')
        plt.close(fig)
    sl=(t>=.008)&(t<.00815)
    us=(t[sl]-.008)*1e6
    fig,ax=plt.subplots(figsize=(9.4,3.2),layout='constrained')
    ax.plot(us,xs[0][sl],color=gray,lw=.9,label=r'$x_{0,i}$: xs[0][i]')
    ax.plot(us,truths[0][sl],color=orange,lw=1.8,label=r'$C_{\rm known}$: generator only')
    ax.set(xlabel=r'Time from 8 ms ($\mu$s)',ylabel=r'$x_{0,i}$ / xs[0][i] (V)',title='01  One spatial point, record 0')
    ax.legend(fontsize=9)
    save(fig,'01_x')

    fig,axes=plt.subplots(1,2,figsize=(10,3.4),layout='constrained')
    pos=f>=0
    axes[0].plot(f[pos]/1e3,np.abs(F[pos])/len(t),color=blue,lw=.9)
    axes[0].set(xlim=(0,650),ylim=(-.035,1.08),xlabel=r'$f_k$ (kHz)',ylabel=r'$|F_k|/N$ (V)',title='02a  Before selecting a band')
    for freq,label in [(f0,'1'),(2*f0,'2'),(5*f0,'5'),(12*f0,'12')]:
        k=np.argmin(np.abs(f-freq))
        axes[0].annotate(label,xy=(freq/1e3,abs(F[k])/len(t)),xytext=(freq/1e3+.5,abs(F[k])/len(t)+.09),color=purple)
    band=(f>=34e3)&(f<=46e3)
    axes[1].plot(f[band]/1e3,np.abs(F[band])/len(t),color=blue,marker='.',ms=3,lw=.8)
    axes[1].axvspan(35,45,color=orange,alpha=.12)
    axes[1].annotate(f'{f0/1e3:.2f} kHz',xy=(f0/1e3,np.abs(F).max()/len(t)),xytext=(40.5,.7),arrowprops={'arrowstyle':'->'})
    axes[1].set(xlabel=r'$f_k$ (kHz)',ylabel=r'$|F_k|/N$ (V)',title='02b  Search only 35-45 kHz')
    save(fig,'02_F')

    fig,ax=plt.subplots(figsize=(9.4,3.2),layout='constrained')
    order=np.argsort(f); use=order[(f[order]>=-110e3)&(f[order]<=130e3)]
    ax.plot(f[use]/1e3,np.abs(F[use])/len(t),color=gray,lw=1.2,label=r'Original $|F_k|/N$')
    ax.plot(f[use]/1e3,np.abs(F_hat[use])/len(t),color=purple,lw=1.3,label=r'Selected $|\widehat F_k|/N$')
    ax.axvspan(25,55,color=purple,alpha=.09)
    ax.set(xlabel=r'$f_k$ (kHz)',ylabel='Coefficient magnitude / N (V)',title='03  A new spectrum: keep only positive 25-55 kHz')
    ax.legend(fontsize=9,loc='upper left')
    save(fig,'03_Fhat')

    fig,axes=plt.subplots(1,2,figsize=(10,3.4),layout='constrained',gridspec_kw={'width_ratios':[2,1]})
    axes[0].plot(us,z[sl].real,color=blue,label=r'Re $z(t_i)$')
    axes[0].plot(us,z[sl].imag,color=orange,label=r'Im $z(t_i)$')
    axes[0].set(xlabel=r'Time from 8 ms ($\mu$s)',ylabel=r'$z$ components (V)',title='04a  The real and imaginary parts of z')
    axes[0].legend(fontsize=9)
    axes[1].plot(z[sl].real,z[sl].imag,color=teal,lw=1)
    q0=z[sl][10]; axes[1].arrow(0,0,q0.real,q0.imag,color=purple,width=.01,length_includes_head=True)
    axes[1].set(xlabel=r'Re $z$ (V)',ylabel=r'Im $z$ (V)',aspect='equal',title='04b  A rotating arrow')
    save(fig,'04_z')

    fig,axes=plt.subplots(1,2,figsize=(10,3.2),layout='constrained')
    shift=np.floor(phi[sl][0]/(2*np.pi))
    axes[0].plot(us,phi[sl]/(2*np.pi)-shift,color=blue)
    axes[0].set(xlabel=r'Time from 8 ms ($\mu$s)',ylabel=r'$\phi/(2\pi)$ minus an integer',title='05a  Count completed turns')
    axes[1].plot(us,theta[sl]/(2*np.pi),'.',color=teal,ms=2)
    axes[1].set(xlabel=r'Time from 8 ms ($\mu$s)',ylabel=r'$\theta/(2\pi)$',title='05b  Position within one turn')
    save(fig,'05_phase')

    fig,axes=plt.subplots(1,2,figsize=(10,3.4),layout='constrained')
    for j,color in zip([1,2,3],[blue,teal,orange]):
        axes[0].plot(us,xs[j][sl],color=color,lw=.8,label=f'xs[{j}]')
        take=np.arange(0,len(t),101)
        axes[1].scatter(positions[j][take]/(2*np.pi),xs[j][take],color=color,s=2,alpha=.3)
    axes[0].set(xlabel=r'Time from 8 ms ($\mu$s)',ylabel=r'$x_{j,i}$ (V)',title='06a  Three training records in time')
    axes[0].legend(fontsize=9)
    axes[1].set(xlabel=r'$\theta_{j,i}/(2\pi)$',ylabel=r'$x_{j,i}$ (V)',title='06b  The same samples, sorted by cycle position')
    save(fig,'06_fold')

    centers=(np.arange(B)+.5)/B
    fig,axes=plt.subplots(1,2,figsize=(10,3.3),layout='constrained')
    axes[0].plot(centers,mu,'.',color=orange,ms=3)
    axes[0].set(xlabel=r'Bin center $(b+1/2)/B$ (turns)',ylabel=r'$\mu_{-0,b}$ (V)',title='07a  One average voltage per bin')
    axes[1].plot(np.arange(B),K_train,color=blue,lw=.8)
    axes[1].set(xlabel='Bin number b',ylabel=r'$\sum_{j\ne0} K_{j,b}$ (samples)',title='07b  Samples contributing to each mean')
    save(fig,'07_mu')

    fig,axes=plt.subplots(1,2,figsize=(10,3.5),layout='constrained')
    n=np.arange(21)
    axes[0].stem(n-.12,a[:21].real,linefmt=blue,markerfmt='o',basefmt=' ',label=r'Re $a_n$')
    axes[0].stem(n+.12,a[:21].imag,linefmt=orange,markerfmt='s',basefmt=' ',label=r'Im $a_n$')
    axes[0].set(xlabel='Harmonic order n',ylabel=r'$a_n$ components (V)',title='08a  Complex coefficients, orders 0-20',xticks=[0,2,5,10,12,15,20])
    axes[0].legend(fontsize=9)
    axes[1].semilogy(np.arange(1,101),2*np.abs(a[1:101]),'.-',color=teal,ms=3,lw=.7)
    axes[1].set(xlabel='Harmonic order n',ylabel=r'$2|a_n|$ (V), logarithmic scale',title='08b  How much each positive order contributes')
    save(fig,'08_a')

    fig,axes=plt.subplots(1,2,figsize=(10,3.5),layout='constrained',gridspec_kw={'width_ratios':[1.5,1]})
    axes[0].plot(centers,mu,'.',color=blue,ms=3,label=r'256 bin means $\mu_{-0,b}$')
    axes[0].plot(gamma/(2*np.pi),w,color=orange,lw=1.3,label=r'Curve $W(\theta)$')
    axes[0].set(xlabel=r'Cycle position $\theta/(2\pi)$',ylabel='Voltage (V)',title='09a  Sum the retained orders to get W')
    axes[0].legend(fontsize=9)
    take=np.arange(500,505)
    axes[1].plot(gamma[take]/(2*np.pi),w[take],'o-',color=purple,lw=1)
    for ell in take:
        axes[1].annotate(str(ell),xy=(gamma[ell]/(2*np.pi),w[ell]),xytext=(0,9),textcoords='offset points',ha='center',fontsize=8)
    axes[1].margins(.12,.3)
    axes[1].set_xticks(gamma[take[[0,2,4]]]/(2*np.pi))
    axes[1].set(xlabel=r'$\gamma_\ell/(2\pi)=\ell/M$',ylabel=r'$w_\ell=W(\gamma_\ell)$ (V)',title='09b  Five of the 4096 lookup points')
    save(fig,'09_W')

    fig,axes=plt.subplots(1,3,figsize=(11,3.25),layout='constrained')
    idx=np.flatnonzero(sl)[300]; tx=(t[idx]-.008)*1e6; th=positions[0][idx]/(2*np.pi)
    axes[0].plot(us,positions[0][sl]/(2*np.pi),'.',color=blue,ms=1.4)
    axes[0].plot(tx,th,'o',color=purple)
    axes[0].set(xlabel=r'Time from 8 ms ($\mu$s)',ylabel=r'$\theta_{0,i}/(2\pi)$',title='10a  Read the position')
    axes[1].plot(gamma/(2*np.pi),w,color=orange)
    axes[1].plot(th,C[idx],'o',color=purple)
    axes[1].set(xlabel=r'Cycle position $\theta/(2\pi)$',ylabel=r'$W(\theta)$ (V)',title='10b  Look up its voltage')
    axes[2].plot(us,C[sl],color=teal)
    axes[2].plot(tx,C[idx],'o',color=purple)
    axes[2].set(xlabel=r'Time from 8 ms ($\mu$s)',ylabel=r'$C(t_i)$ (V)',title='10c  Put it at that time')
    save(fig,'10_replay')

    fig,axes=plt.subplots(3,1,figsize=(9.4,7),sharex=True,layout='constrained',gridspec_kw={'height_ratios':[2,1.4,1]})
    axes[0].plot(us,xs[0][sl],color=gray,lw=.8,label='xs[0]: input')
    axes[0].plot(us,C[sl],color=orange,lw=1.7,label='C: estimated')
    axes[0].plot(us,C_known[sl],'--',color=blue,lw=1,label='C_known: generator answer')
    axes[0].set(ylabel='Voltage (V)',title='11  Separate the remainder from the estimation error')
    axes[0].legend(fontsize=9)
    axes[1].plot(us,R[sl],color=teal,lw=.8)
    axes[1].set(ylabel=r'$R=x_{0,i}-C(t_i)$ (V)')
    axes[2].plot(us,1000*error[sl],color=purple,lw=.8)
    axes[2].set(xlabel=r'Time from 8 ms ($\mu$s)',ylabel=r'$C-C_{\rm known}$ (mV)')
    save(fig,'11_result')

    fig,axes=plt.subplots(1,2,figsize=(10,3.6),layout='constrained')
    bidx=np.minimum(np.floor(positions[0]*B/(2*np.pi)).astype(int),B-1)
    chosen=[32,160]; labels=['Early position\nb = 32','Half a cycle later\nb = 160']
    for xx,bb,col in zip([0,1],chosen,[blue,orange]):
        vals=R[bidx==bb]; pick=vals[:100]; jitter=np.linspace(-.16,.16,len(pick))
        axes[0].scatter(xx+jitter,pick,s=9,color=col,alpha=.65)
        axes[0].hlines(res_mean[bb],xx-.25,xx+.25,color=purple,lw=2)
    axes[0].axhline(0,color=gray,lw=.7)
    axes[0].margins(y=.18)
    axes[0].set(xticks=[0,1],xticklabels=labels,ylabel='Residual R (V)',title='12a  Many cycles at each of two positions')
    axes[0].text(.02,.98,'Purple lines: mean of all points in each bin',transform=axes[0].transAxes,va='top',fontsize=8)
    axes[1].bar([0,1],res_rms[chosen],color=[blue,orange],width=.5)
    for k,bb in enumerate(chosen):
        axes[1].text(k,res_rms[bb]+.015,f'{res_rms[bb]:.3f} V',ha='center',fontsize=10)
    axes[1].set(xticks=[0,1],xticklabels=labels,ylabel=r'RMS residual $\sqrt{\mathrm{mean}(R^2)}$ (V)',title='12b  Typical size of those fluctuations',ylim=(0,float(max(res_rms[chosen]))*1.22))
    save(fig,'12_residual')



def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, default=DEFAULT_OUTPUT/'synthetic_result.npz')
    parser.add_argument('--output-dir', type=Path, default=DEFAULT_OUTPUT/'figures')
    args = parser.parse_args()
    with np.load(args.input, allow_pickle=False) as data:
        make_figures(data, args.output_dir)
    print(f"Saved 12 figures to {args.output_dir.resolve()}")


if __name__ == '__main__':
    main()
