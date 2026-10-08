import {NR,NZ,quadrants,orderedCells,upstream,owner,schedule} from "./sn_walkthrough_model.mjs";
const $=id=>document.getElementById(id);
const mathCache=new Map();
// Reuse Sphinx's local KaTeX parser; the browser renders the resulting MathML.
function typeset(root){
 for(const el of root.querySelectorAll("[data-tex]")){
  const tex=el.dataset.tex,display=el.classList.contains("formula"),key=display+":"+tex;
  if(el.dataset.rendered===key)continue;
  if(!mathCache.has(key))mathCache.set(key,katex.renderToString(tex,{
   output:"mathml",displayMode:display,throwOnError:true,strict:"error"
  }));
  el.innerHTML=mathCache.get(key);
  // MathML Core only guarantees the normal variant; preserve the requested
  // matrix/vector font with CSS in browsers that ignore the other variants.
  for(const glyph of el.querySelectorAll('[mathvariant="bold-italic"],[mathvariant="sans-serif"]')){
   glyph.dataset.variant=glyph.getAttribute("mathvariant");
   glyph.setAttribute("mathvariant","normal");
  }
  el.dataset.rendered=key;
 }
}
let mode="hybrid",frames=schedule(mode),index=0,iteration=1,timer=null,term="incoming",reconstructed=false;
quadrants.forEach((q,i)=>{const o=document.createElement("option");o.value=i;o.textContent=q.label;$("quadrant").append(o)});
function stop(){clearTimeout(timer);timer=null;$("play").textContent="播放"}
function play(){if(index===frames.length-1){stop();return}index++;render();timer=setTimeout(play,Number($("pace").value))}
function setIndex(i){stop();reconstructed=false;index=Math.max(0,Math.min(frames.length-1,i));render()}
$("play").onclick=()=>{if(timer){stop()}else{$("play").textContent="暂停";timer=setTimeout(play,Number($("pace").value))}};
$("prev").onclick=()=>setIndex(index-1);$("next").onclick=()=>setIndex(index+1);
$("timeline").oninput=()=>setIndex(Number($("timeline").value));
$("reset").onclick=()=>{iteration=1;setIndex(0)};
$("mode").onchange=()=>{mode=$("mode").value;frames=schedule(mode);setIndex(0)};
$("quadrant").onchange=()=>setIndex(frames.findIndex(f=>f.q===Number($("quadrant").value)&&f.phase!=="boundary"));
$("repeat").onclick=()=>{iteration++;setIndex(0)};
$("finish").onclick=()=>{stop();reconstructed=true;render()};
document.querySelectorAll("[data-term]").forEach(b=>b.onclick=()=>{term=b.dataset.term;renderAssembly();sendSize()});
document.addEventListener("visibilitychange",()=>{if(document.hidden)stop()});
window.addEventListener("pagehide",stop);
const same=(a,b)=>a[0]===b[0]&&a[1]===b[1], inside=([i,k])=>i>=0&&i<NR&&k>=0&&k<NZ;
const point=([i,k])=>[74+i*76+38,402-k*52-26];
function draw(){
 const f=frames[index],q=quadrants[f.q],done=f.done,current=f.cells;
 let out="";
 const line=(x1,y1,x2,y2,color="#155b8f",dash="",arrow=true)=>'<line x1="'+x1+'" y1="'+y1+'" x2="'+x2+'" y2="'+y2+'" stroke="'+color+'" stroke-width="2" '+(dash?'stroke-dasharray="'+dash+'" ':'')+(arrow?'marker-end="url(#'+(color==="#8c3970"?"wallarrow":"arrow")+')"':'')+'/>';
 const text=(x,y,value,extra="")=>'<text x="'+x+'" y="'+y+'" '+extra+'>'+value+'</text>';
 out+=text(84,20,"上端开放：外部入射为零");
 for(let i=0;i<NR;i++)for(let k=0;k<NZ;k++){
  const cell=[i,k],isCurrent=current.some(c=>same(c,cell)),isDone=done.some(c=>same(c,cell));
  const [x,y]=point(cell);
  out+='<rect x="'+(x-37)+'" y="'+(y-25)+'" width="74" height="50" fill="'+(isCurrent?"#f3d491":isDone?"#dcebf6":"#fff")+'" stroke="'+(isCurrent?"#8b651d":"#a4b1bc")+'" stroke-width="'+(isCurrent?2:1)+'"/>';
  out+=text(x,y+4,(isCurrent?"● ":isDone?"✓ ":"")+(i+1)+","+(k+1),'text-anchor="middle"');
 }
 // The same global boundaries exist in both execution modes.
 out+=line(71,402,71,90,"#8c3970","",false)+line(381,402,381,90,"#8c3970","",false);
 out+=line(74,405,150,405,"#8c3970","",false)+line(302,405,378,405,"#8c3970","",false);
 out+=line(151,406,301,406,"#155b8f","",false);
 out+=text(166,431,'给定入口 <tspan font-style="italic">h</tspan><tspan baseline-shift="sub" font-size="10">m</tspan>');
 out+=text(11,260,"反射壁",'transform="rotate(-90 11 260)"')+text(450,200,"反射壁",'transform="rotate(90 450 200)"');
 out+=line(74,402,74,66,"#24313d","",false)+text(53,65,"z ↑")+text(376,452,"r →");
 if(mode==="hybrid"){
  out+=line(226,90,226,402,"#5e6870","6 4",false)+line(74,246,378,246,"#5e6870","6 4",false);
  for(let x=0;x<2;x++)for(let y=0;y<2;y++)out+=text(77+x*152,101+(1-y)*156,'P<tspan baseline-shift="sub" font-size="9">'+x+','+y+'</tspan>','style="font-size:10px"');
 }
 if(f.phase==="cell"){
  for(const c of current){
   const [x,y]=point(c);
   for(const up of upstream(f.q,...c)){
    const [ux,uy]=point(up);
    if(inside(up)){
     const remote=mode==="hybrid"&&!same(owner(...up),owner(...c));
     out+=line(ux,uy,x,y,"#155b8f",remote?"4 3":"");
    }else{
     const wall=(up[0]<0||up[0]>=NR)||(up[1]<0&&(c[0]===0||c[0]===3));
     const clippedX=Math.max(58,Math.min(395,ux)),clippedY=Math.max(62,Math.min(420,uy));
     out+=line(clippedX,clippedY,x,y,wall?"#8c3970":"#155b8f",wall?"4 3":"");
    }
   }
  }
 }
 if((f.phase==="receive"||f.phase==="send")&&mode==="hybrid"){
  for(const [x,y] of f.blocks){
   const c=[2*x+(q.sr>0?0:1),3*y+(q.sz>0?0:2)];
   const end=f.phase==="send"?[2*x+(q.sr>0?1:0),3*y+(q.sz>0?2:0)]:c;
   for(const delta of [[q.sr,0],[0,q.sz]]){
    const from=f.phase==="send"?end:[c[0]-delta[0],c[1]-delta[1]],to=f.phase==="send"?[end[0]+delta[0],end[1]+delta[1]]:c;
    if(inside(from)&&inside(to)){const a=point(from),b=point(to);out+=line(...a,...b,"#155b8f","4 3")}
   }
  }
 }
 if(f.phase==="boundary"){
  out+=text(89,48,iteration===1?"旧分布为零 → 第一轮反射入流为零":"读取上一轮壁面出射 → 固定本轮反射入流");
 }
 $("drawing").innerHTML=out;
}
function renderAssembly(){
 document.querySelectorAll("[data-term]").forEach(b=>b.setAttribute("aria-pressed",String(b.dataset.term===term)));
 const f=frames[index],c=f.cells[0],where=c?"当前单元 ("+(c[0]+1)+","+(c[1]+1)+")":"任一待求解单元 K";
 const content={
  incoming:'<p>'+where+" 的两个迎风面提供右端。内部面取本轮已求出的上游多项式；跨分区面取已接收的三个系数；入口用给定的 <span data-tex=\"h_m\"></span>；壁面用上一轮分布确定的反射入流。</p><div class=\"formula\" data-tex=\"b_a^{(\\ell+1)}=\\sum_{f:\\,\\beta_f&lt;0}|\\beta_f|\\int_f r\\phi_a\\psi_f^{\\mathrm{up},(\\ell+1)}\\,\\mathrm ds\"></div><p class=\"small\"><span data-tex=\"\\psi_f^{\\mathrm{up},(\\ell+1)}\"></span> 是本轮使用的已知入流面值；其中壁面项由旧分布计算，并不使用尚未求出的本轮出射值。跨分区传递的是上游单元的 <span data-tex=\"\\boldsymbol c^{(\\ell+1)}=(c_0^{(\\ell+1)},c_1^{(\\ell+1)},c_2^{(\\ell+1)})^{\\mathsf T}\"></span>。</p><div class=\"code\">sub_J02_add_neighbor_rhs / sub_J02_add_constant_rhs / sub_J02_add_specular_rhs</div>",
  outgoing:"<p>出流面满足 <span data-tex=\"\\beta_f&gt;0\"></span>，面值取本单元未知分布。把 <span data-tex=\"\\psi=\\sum_{b=1}^{3}\\phi_b c_{b-1}\"></span> 代入面积分，每个出流面贡献一个矩阵：</p><div class=\"formula\" data-tex=\"(F_f)_{ab}=|\\beta_f|\\int_f r\\phi_a\\phi_b\\,\\mathrm ds,\\qquad a,b=1,2,3\"></div><p class=\"small\">径向面上 <span data-tex=\"r\"></span> 为常数，<span data-tex=\"\\mathrm ds=\\mathrm dz\"></span>；轴向面上 <span data-tex=\"\\mathrm ds=\\mathrm dr\"></span>。共同的周向张角已约去。组装时将全部出流面的 <span data-tex=\"\\mathsf F_f\"></span> 相加。</p><div class=\"code\">sub_J02_add_self_face_matrix</div>",
  volume:"<p>把守恒输运方程乘以检验函数 <span data-tex=\"\\phi_a\"></span> 并分部积分，面项已归入出流矩阵和入流右端，剩下体输运矩阵 <span data-tex=\"\\mathsf T\"></span> 和损失矩阵 <span data-tex=\"\\sigma\\mathsf H\"></span>：</p><div class=\"formula\" data-tex=\"\\begin{aligned}T_{ab}&amp;=-\\int_K r\\phi_b(\\boldsymbol\\Omega\\cdot\\nabla\\phi_a)\\,\\mathrm dr\\,\\mathrm dz,\\\\ H_{ab}&amp;=\\int_K r\\phi_a\\phi_b\\,\\mathrm dr\\,\\mathrm dz.\\end{aligned}\"></div><p class=\"small\"><span data-tex=\"\\sigma=\\nu_K/v_m\"></span> 在当前单元和离散速度下是常数。第一行的检验函数 <span data-tex=\"\\phi_1=1\"></span> 梯度为零，所以 <span data-tex=\"T_{1b}=0\"></span>；这一行仍包含出流和损失，约束单元粒子收支。</p><div class=\"code\">sub_J02_add_volume_matrix / sub_J02_add_absorption_matrix</div>",
  solve:"<div class=\"formula\" data-tex=\"\\mathsf A=\\mathsf T+\\sigma\\mathsf H+\\sum_{f:\\,\\beta_f&gt;0}\\mathsf F_f,\\qquad \\mathsf A\\boldsymbol c^{(\\ell+1)}=\\boldsymbol b^{(\\ell+1)}\"></div><p>用部分选主元求解三阶线性方程组，再检查四个角点 <span data-tex=\"\\psi=c_0\\pm c_1\\pm c_2\"></span> 是否非负。若出现负值，采用常数回退：</p><div class=\"formula\" data-tex=\"\\boldsymbol c^{(\\ell+1)}\\leftarrow\\begin{pmatrix}b_1^{(\\ell+1)}/A_{11}\\\\0\\\\0\\end{pmatrix}\"></div><p class=\"small\">这里 <span data-tex=\"b_1\"></span> 和 <span data-tex=\"A_{11}\"></span> 是矩阵第一行的元素，对应程序中的 <code>rhs(1)</code>、<code>a(1,1)</code>。回退保留第一行粒子收支，一般不再满足原系统的第二、三行。</p><p>将三个系数写入本轮分布，随后供下游单元计算入流。图中当前单元变为“✓ 已求解”。</p><div class=\"code\">sub_J02_solve_local_3x3 → sub_J02_enforce_local_positivity → psi(:,i,k,m)</div>"
 };
 $("assembly").innerHTML=content[term];
 typeset($("assembly"));
}
function render(){
 const f=frames[index],q=quadrants[f.q];
 $("timeline").max=frames.length-1;$("timeline").value=index;$("progress").value=(index+1)+"/"+frames.length;
 $("iteration").textContent="当前第 "+iteration+" 轮（ℓ = "+(iteration-1)+"）";$("quadrant").value=f.q;
 $("prev").disabled=index===0;$("next").disabled=index===frames.length-1;$("play").disabled=index===frames.length-1;
 $("convergence").hidden=f.phase!=="check"||reconstructed;
 $("repeat").hidden=f.phase!=="check";$("finish").hidden=f.phase!=="check";
 $("finish").disabled=iteration<2;$("finish").title=iteration<2?"正式程序至少完成两轮后才检查收敛出口":"";
 const cells=f.cells.map(([i,k])=>"("+(i+1)+","+(k+1)+")").join("、");
 const stages={
 boundary:["固定本轮边界入流","上一轮所有速度的分布保持不变。逐面计算漫反射归一化，并按镜面对应方向读取旧出射分布。"+(iteration===1?"第一轮旧分布为零；只有规定入口提供粒子。":"从第二轮起，壁面返回上一轮到达壁面的粒子。"),"sub_J02_solve_source_iteration → sub_J02_sweep / sub_J02_compute_diffuse_wall_constants"],
 ready:["分配离散速度任务","单域 OpenMP 可以同时分配所有离散速度。这里分四组显示，便于观察迎风方向；单域程序没有四组之间的同步屏障。","sub_J02_sweep_batch · schedule(static)"],
 receive:["接收上游分区系数","本组方向："+q.label+"。当前分区先接收两个上游方向的界面系数，随后才能开始区域内扫描。物理外边界没有上游进程，按入口、出口或壁面条件处理。","sub_J02_mpi_sweep · MPI_Recv → sub_J02_sweep_batch"],
 cell:["求解单元 "+cells,"按 i 外层、k 内层的迎风顺序前进。蓝箭头指出本轮已知的上游；虚线跨分区箭头使用接收缓冲区；紫箭头来自上一轮壁面。下方展开本单元方程的四个组装步骤。","sub_J02_sweep_velocity → DG 单元装配 → 3×3 求解 → 保正"],
 send:["发送下游分区所需系数","本分区完成这一方向组的全部速度任务后，将两个下游边界上的三个系数打包发送，并等待发送完成。接收方据此继续。图中同一波前的分区可以并行。","sub_J02_mpi_sweep · MPI_Isend → MPI_Waitall"],
 quadrant:["这一符号组合完成","这组离散速度在整个域内已有本轮分布。下一组改变迎风方向，壁面仍使用同一份上一轮数据，不立即使用刚得到的出射结果。","sub_J02_mpi_sweep · quadrant = 0,1,2,3"],
 check:["所有速度完成：检查反射迭代","比较本轮与上一轮的全部空间系数，按下方公式计算相对变化。MPI 的最大值与求和覆盖所有分区。至少完成两轮且达到容差后才停止；本图仅演示流程，不计算实际收敛值。","sub_J02_solve_source_iteration · 全域归约 → 相对变化判据"]
 };
 let [title,desc,routine]=stages[f.phase];
 if(reconstructed){title="收敛后：积分得到场与面通量";desc="对各离散速度用权重求和，先得到单元密度和平均速度，再按迎风面迹重构内部面与开放面通量。MPI 还重构进程交界面通量；只有全部成功后 result%converged 才置真。";routine="sub_J02_reconstruct_cell_moments → internal_face_fluxes → open_boundary_fluxes → partition_fluxes";}
 $("stage").textContent=title;$("explanation").textContent=desc;$("routine").textContent=routine;
 $("workers").innerHTML=q.velocities.map((m,t)=>'<span class="worker">线程示意 '+(t+1)+'：m = '+m+' '+q.label.slice(-1)+'</span>').join("");
 draw();renderAssembly();sendSize();
}
function sendSize(){requestAnimationFrame(()=>parent.postMessage({type:"sn-walkthrough-height",height:Math.ceil(document.body.getBoundingClientRect().height)},location.origin))}
new ResizeObserver(sendSize).observe(document.body);document.querySelectorAll("details").forEach(d=>d.addEventListener("toggle",sendSize));
typeset(document);
render();
