// Resize only the explicitly identified, same-origin educational frame.
window.addEventListener("message",function(event){
  const frame=document.getElementById("sn-walkthrough");
  if(!frame||event.origin!==location.origin||event.source!==frame.contentWindow)return;
  if(event.data?.type!=="sn-walkthrough-height")return;
  const height=Number(event.data.height);
  if(Number.isFinite(height)&&height>=300&&height<=5000)frame.style.height=(height+6)+"px";
});
