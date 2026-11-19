/* The plotting rectangle is in CSS pixels; units and scales are explicit. */
(() => {
  'use strict';
  const M = WaveLabModel, w0 = PlasmaDerivationModel.W0;
  const mint = '#b5efcf', gold = '#f4c583', ink = '#eef4f0', grid = '#3c4b50';
  const palette = [[20,31,48],[49,75,128],[42,145,153],[158,210,142],[255,226,118]];
  function interpolate(stops, value) {
    const pos = Math.max(0,Math.min(1,value)) * (stops.length - 1);
    const ix = Math.min(stops.length - 2,Math.floor(pos));
    return 'rgb(' + stops[ix].map((v,i) => Math.round(v+(stops[ix+1][i]-v)*(pos-ix))).join(',') + ')';
  }
  const dbColors = Array.from({length:161}, (_,i) => interpolate(palette,i/160));
  const fieldColors = Array.from({length:201}, (_,i) => interpolate([[109,178,255],[23,35,45],[245,191,108]],i/200));
  const cache = new Map();
  function powerFor(kind, amplitude) {
    const key = kind === 'pair' ? kind + amplitude : kind;
    if (!cache.has(key)) cache.set(key,M.spectrum(M.sampleField(M.modesFor(kind,amplitude))));
    return cache.get(key);
  }
  function peakAt(kind, amplitude, k) {
    const power = powerFor(kind,amplitude);
    const column = power[k], peak = Math.max(...column);
    const max = Math.max(...power.map(c=>Math.max(...c)));
    return {frequency:(M.binMin+column.indexOf(peak))*M.dw, db:10*Math.log10(peak/max)};
  }
  let field;
  function draw(canvas, kind, s) {
    const ctx = canvas.getContext('2d');
    if (!ctx || !canvas.clientWidth) return;
    const width = canvas.clientWidth, height = canvas.clientHeight;
    const scale = Math.min(devicePixelRatio || 1, 2);
    const pixels = Math.round(width*scale), rows = Math.round(height*scale);
    if (canvas.width !== pixels || canvas.height !== rows) { canvas.width = pixels; canvas.height = rows; }
    ctx.setTransform(scale,0,0,scale,0,0);
    ctx.fillStyle = '#141f25'; ctx.fillRect(0,0,width,height);
    const small = width < 400, font = small ? 18 : 22;
    const l = small ? 56 : 70, r = width-24, t = 55;
    let b = height-73;
    const x = v => l + (r-l)*(v-x0)/(x1-x0);
    const y = v => b - (b-t)*(v-y0)/(y1-y0);
    let x0, x1, y0, y1;
    function line(xa,ya,xb,yb,color,weight=1) {
      ctx.beginPath();ctx.strokeStyle=color;ctx.lineWidth=weight;ctx.moveTo(xa,ya);ctx.lineTo(xb,yb);ctx.stroke();
    }
    function label(word,xx,yy,align='left',color=ink) {
      ctx.font='600 '+font+'px "Segoe UI","Microsoft YaHei",sans-serif';ctx.textAlign=align;
      ctx.fillStyle=color;ctx.fillText(word,xx,yy);
    }
    function axis(horizontal,vertical,xTicks,yTicks,lines=true) {
      label(vertical,12,30); label(horizontal,r,height-10,'right');
      for (const n of xTicks) {
        if (lines) line(x(n),t,x(n),b,grid);
        label(String(n),x(n),b+font+6,'center');
      }
      for (const n of yTicks) {
        if (lines) line(l,y(n),r,y(n),grid);
        label(String(n),l-7,y(n)+font/3,'right');
      }
      line(l,t,l,b,ink);line(l,b,r,b,ink);
    }
    function curve(fn,color,weight=3,dash=[],end=x1) {
      ctx.save();ctx.beginPath();ctx.rect(l,t,r-l,b-t);ctx.clip();
      ctx.beginPath();ctx.lineWidth=weight;ctx.strokeStyle=color;ctx.setLineDash(dash);
      const last=x(end);
      for(let px=l;px<=Math.ceil(last);px++){
        const u=Math.min(px,last), v=x0+(u-l)/(r-l)*(x1-x0);
        if(px===l)ctx.moveTo(u,y(fn(v)));else ctx.lineTo(u,y(fn(v)));
      }
      ctx.stroke();ctx.restore();
    }
    function dot(xv,yv,color) {ctx.fillStyle=color;ctx.beginPath();ctx.arc(x(xv),y(yv),5,0,2*Math.PI);ctx.fill();}
    if (kind==='pressure') {
      x0=0;x1=0.4;y0=-1.35;y1=1.35;
      axis('x (m)','p₁ / max|p₁|',[0,0.2,0.4],[-1,0,1]);
      const wave=v=>Math.cos(2*Math.PI*(v/0.4-0.5-s.time/4));
      curve(wave,mint);
      for(let j=1;j<12;j++){
        const v=j*0.4/12, dir=Math.sin(2*Math.PI*(v/0.4-0.5-s.time/4));
        const len=(r-l)/22*dir;
        if(Math.abs(len)<2)continue;
        const xx=x(v), yy=y(wave(v))-13, tip=xx+len;
        line(xx,yy,tip,yy,gold,2.5);
        line(tip,yy,tip-Math.sign(len)*4,yy-4,gold,2);
        line(tip,yy,tip-Math.sign(len)*4,yy+4,gold,2);
      }
    } else if (kind==='dispersion') {
      x0=0;x1=24;y0=0.99;y1=1.07;
      axis('k (rad/m)','ω (10⁸ rad/s)',[0,8,16,24],[1,1.03,1.06]);
      const warm=k=>M.warmOmega(k,s.energy)/w0;
      curve(warm,mint,3);curve(()=>1,gold,2.5,[8,5]);
      line(x(s.k),t,x(s.k),b,'#8e9f9b',1.5);
      dot(s.k,warm(s.k),mint);dot(s.k,1,gold);
    } else if (['damped','growth','frequency'].includes(kind)) {
      x0=0;x1=4;y0=-4;y1=4;
      if (kind==='frequency') {y0=-1.4;y1=1.4;}
      if (kind==='damped') {y0=-1.2;y1=1.2;}
      axis('t (s)','E (V/m)',[0,1,2,3,4],kind==='growth'?[-4,-2,0,2,4]:[-1,0,1]);
      const amp=t=>Math.exp(s.gamma*t), trace=t=>amp(t)*Math.cos(s.omega*t);
      curve(amp,gold,2,[7,5]);curve(t=>-amp(t),gold,2,[7,5]);
      curve(trace,'#65867e',2);curve(trace,mint,3,[],s.time);
      dot(s.time,trace(s.time),mint);
    } else if (kind==='field') {
      if (!field) field=M.sampleField(M.modesFor('single'));
      const cols=42, nRows=32;
      b=height*0.53;
      x0=-M.dx/2;x1=(cols-0.5)*M.dx;y0=-M.dt*0.5e9;y1=(nRows-0.5)*M.dt*1e9;
      for(let j=0;j<cols;j++) for(let i=0;i<nRows;i++) {
        ctx.fillStyle=fieldColors[Math.round((1+field[i*M.nx+j])*100)];
        ctx.fillRect(x((j-0.5)*M.dx),y((i+0.5)*M.dt*1e9),(r-l)/cols+0.4,(b-t)/nRows+0.4);
      }
      label('t (ns)',12,30);
      for (const v of [0,90,180]) label(String(v),l-7,y(v)+font/3,'right');
      const row=Math.round(s.time*31/4);
      line(l,y(row*M.dt*1e9),r,y(row*M.dt*1e9),'#fff',2.5);
      const mid=height*0.76, amp=height*0.09;
      label('E (V/m)',12,b+font+7);
      for (const v of [-1,1]) label(String(v),l-7,mid-amp*v+font/3,'right');
      line(l,mid,r,mid,grid);
      for (let j=1;j<cols;j++) {
        line(x((j-1)*M.dx),mid-amp*field[row*M.nx+j-1],x(j*M.dx),mid-amp*field[row*M.nx+j],mint,3);
      }
      for (const v of [0,1,2]) label(String(v),x(v),height-30,'center');
      label('x (m)',r,height-7,'right');
    } else {
      const power=powerFor(kind==='overlay'?'band':kind,s.amplitude);
      const peak=Math.max(...power.map(c=>Math.max(...c)));
      const unit=M.dw/1e8;
      x0=-0.5;x1=M.kMax+0.5;y0=(M.binMin-0.5)*unit;y1=(M.binMax+0.5)*unit;
      for(let k=0;k<power.length;k++) for(let j=0;j<power[k].length;j++){
        const db=10*Math.log10(Math.max(1e-12,power[k][j]/peak));
        ctx.fillStyle=dbColors[Math.round(4*Math.max(0,40+Math.min(0,db)))];
        ctx.fillRect(x(k-0.5),y((M.binMin+j+0.5)*unit),Math.ceil(x(1)-x(0)),Math.ceil(y(0)-y(unit)));
      }
      axis('k (rad/m)','ω (10⁸ rad/s)',[0,8,16,24],[0.98,1,1.04,1.08],false);
      if(kind==='overlay' && s.overlay){
        const theory=k=>M.warmOmega(k,4)/w0;
        curve(theory,'#18212b',4,[8,5]);curve(theory,'#ffffff',2,[8,5]);
      }
      if (kind==='overlay') {
        const measured=peakAt('band',s.amplitude,s.probeK);
        if (measured.db>=-40) {
          ctx.beginPath();ctx.arc(x(s.probeK),y(measured.frequency/w0),7,0,2*Math.PI);
          ctx.strokeStyle='#fff';ctx.lineWidth=2;ctx.stroke();
        }
      }
    }
  }
  globalThis.WaveLabPlots = {draw, peakAt};
})();

/* Plasma-wave contribution history (Git author dates; edit time includes timezone).
 * 2026-11-19 15:26 +08:00 | Yinjian Zhao | git b9e33596c00f
 * 2026-11-19 16:28 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */
