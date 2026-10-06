// Teaching schedule, not a transport solver or a measured execution trace.
// r index is outermost, z innermost, matching sub_J02_sweep_velocity.
export const NR = 4, NZ = 6;
export const quadrants = [
  {sr:1, sz:1, velocities:[1,2], label:"μ > 0，η > 0 ↗"},
  {sr:-1, sz:1, velocities:[3,4], label:"μ < 0，η > 0 ↖"},
  {sr:1, sz:-1, velocities:[7,8], label:"μ > 0，η < 0 ↘"},
  {sr:-1, sz:-1, velocities:[5,6], label:"μ < 0，η < 0 ↙"},
];
export function orderedCells(q, bounds = [0, NR, 0, NZ]) {
  const {sr,sz}=quadrants[q], [lo,hi,bottom,top]=bounds, cells=[];
  for(let i=sr>0?lo:hi-1; sr>0?i<hi:i>=lo; i+=sr)
    for(let k=sz>0?bottom:top-1; sz>0?k<top:k>=bottom; k+=sz) cells.push([i,k]);
  return cells;
}
export function upstream(q, i, k) {
  const {sr,sz}=quadrants[q];
  return [[i-sr,k],[i,k-sz]];
}
export function owner(i,k) { return [Math.floor(i/2),Math.floor(k/3)]; }
export function schedule(mode) {
  const frames=[{phase:"boundary",q:0,cells:[],done:[]}];
  for(let q=0;q<4;q++){
    let done=[];
    if(mode==="single"){
      frames.push({phase:"ready",q,cells:[],done:[]});
      for(const cell of orderedCells(q)){
        frames.push({phase:"cell",q,cells:[cell],done:[...done]});
        done.push(cell);
      }
    } else {
      const {sr,sz}=quadrants[q];
      // Wavefront grouping is one legal display order; production has no wave barrier.
      for(let wave=0;wave<3;wave++){
        const blocks=[];
        for(let x=0;x<2;x++)for(let y=0;y<2;y++)
          if((sr>0?x:1-x)+(sz>0?y:1-y)===wave) blocks.push([x,y]);
        frames.push({phase:"receive",q,blocks,cells:[],done:[...done]});
        const lists=blocks.map(([x,y])=>orderedCells(q,[2*x,2*x+2,3*y,3*y+3]));
        for(let j=0;j<6;j++){
          const cells=lists.map(a=>a[j]);
          frames.push({phase:"cell",q,blocks,cells,done:[...done]});
          done.push(...cells);
        }
        frames.push({phase:"send",q,blocks,cells:[],done:[...done]});
      }
    }
    frames.push({phase:"quadrant",q,cells:[],done:[...done]});
  }
  frames.push({phase:"check",q:3,cells:[],done:orderedCells(3)});
  return frames;
}
