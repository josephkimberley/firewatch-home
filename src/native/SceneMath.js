// Route, lighting and pose equations copied from approved release 2.2.4.
.pragma library
var phaseNames = ['dawn','morning','noon','afternoon','evening','dusk','night'];
// Local-clock phase boundaries. Blend into each new phase over 15 minutes.
var phaseHours = [5.5,8,9,14.5,17,20,22];
var phaseNights = [.18,0,0,0,0,.35,1];
function sample(mode,hour) {
    var ix=phaseNames.indexOf(mode);
    if(mode!=='auto') return {a:ix<0?4:ix,b:ix<0?4:ix,mix:0};
    var h=hour<5.5?hour+24:hour;
    for(var i=6;i>=0;i--) {
        if(h>=phaseHours[i]) {
            var elapsed=h-phaseHours[i];
            if(elapsed>=.25)return {a:i,b:i,mix:0};
            var t=elapsed/.25;
            return {a:(i+6)%7,b:i,mix:t*t*(3-2*t)};
        }
    }
    return {a:6,b:6,mix:0};
}
function source(season,index) {var name=phaseNames[index];return 'assets/'+season+'/'+(season==='autumn'&&name==='evening'?'evening-vibrant':name)+'.jpg';}
function title(index) {var name=phaseNames[index];return name.charAt(0).toUpperCase()+name.slice(1);}
function birdClamp(v,a,b){return Math.max(a,Math.min(b,v));}
function birdSmooth(a,b,v){var q=birdClamp((v-a)/(b-a),0,1);return q*q*(3-2*q);}
function birdRandom(seed){return function(){seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;};}
function makeBirdRoute(index,cycle){
 var group=index<3,id=group?0:index-2,r=birdRandom((9137+id*71237+cycle*52361)>>>0),direction=r()<.5?1:-1;
 var y=155+r()*95,points=[[-95,y]],circle=!group&&r()<.32;
 if(circle){var cx=640+r()*580,cy=190+r()*50,rx=105+r()*80,ry=35+r()*30;
  points.push([cx-rx-270,cy-35],[cx-rx,cy],[cx,cy-ry],[cx+rx,cy],[cx,cy+ry],[cx-rx,cy],[cx,cy-ry],[cx+rx+300,cy-45]);
 }else{points.push([310+r()*95,y-25-r()*38],[690+r()*100,y+25+r()*45],[1120+r()*100,y-35-r()*35],[1560+r()*95,y+10+r()*28]);}
 points.push([2020,155+r()*115]);
 if(direction<0)points.forEach(function(q){q[0]=1920-q[0];});
 var knots=[0];for(var k=1;k<points.length;k++)knots.push(knots[k-1]+Math.hypot(points[k][0]-points[k-1][0],points[k][1]-points[k-1][1]));
 var length=knots[knots.length-1];for(k=1;k<knots.length;k++)knots[k]/=length;
 var tangents=points.map(function(point,k){var before=Math.max(0,k-1),after=Math.min(points.length-1,k+1),span=knots[after]-knots[before];return[(points[after][0]-points[before][0])/span,(points[after][1]-points[before][1])/span];});
 return{points:points,knots:knots,tangents:tangents,circle:circle,direction:direction};
}
function sampleBirdRoute(route,u){
 var p=route.points,k=route.knots,m=route.tangents;u=birdClamp(u,0,1);var j=0;while(j<k.length-2&&u>k[j+1])j++;
 var span=k[j+1]-k[j],s=(u-k[j])/span,s2=s*s,s3=s2*s;
 var a=2*s3-3*s2+1,b=s3-2*s2+s,c=-2*s3+3*s2,d=s3-s2;
 var da=(6*s2-6*s)/span,db=3*s2-4*s+1,dc=(-6*s2+6*s)/span,dd=3*s2-2*s;
 return{x:a*p[j][0]+b*span*m[j][0]+c*p[j+1][0]+d*span*m[j+1][0],y:a*p[j][1]+b*span*m[j][1]+c*p[j+1][1]+d*span*m[j+1][1],vx:da*p[j][0]+db*m[j][0]+dc*p[j+1][0]+dd*m[j+1][0],vy:da*p[j][1]+db*m[j][1]+dc*p[j+1][1]+dd*m[j+1][1]};
}
// Stable scratch objects keep the per-frame path free of temporary route/pose
// allocations. Route creation remains once per flight cycle, as before.
var birdFrameScratch=[];
function sampleBirdRouteInto(route,u,out){
 var p=route.points,k=route.knots,m=route.tangents;u=birdClamp(u,0,1);var j=0;while(j<k.length-2&&u>k[j+1])j++;
 var span=k[j+1]-k[j],s=(u-k[j])/span,s2=s*s,s3=s2*s;
 var a=2*s3-3*s2+1,b=s3-2*s2+s,c=-2*s3+3*s2,d=s3-s2;
 var da=(6*s2-6*s)/span,db=3*s2-4*s+1,dc=(-6*s2+6*s)/span,dd=3*s2-2*s;
 out.x=a*p[j][0]+b*span*m[j][0]+c*p[j+1][0]+d*span*m[j+1][0];
 out.y=a*p[j][1]+b*span*m[j][1]+c*p[j+1][1]+d*span*m[j+1][1];
 out.vx=da*p[j][0]+db*m[j][0]+dc*p[j+1][0]+dd*m[j+1][0];
 out.vy=da*p[j][1]+db*m[j][1]+dc*p[j+1][1]+dd*m[j+1][1];return out;
}
function sampleBirdDirectionInto(route,u,out){
 var p=route.points,k=route.knots,m=route.tangents;u=birdClamp(u,0,1);var j=0;while(j<k.length-2&&u>k[j+1])j++;
 var span=k[j+1]-k[j],s=(u-k[j])/span,s2=s*s;
 var da=(6*s2-6*s)/span,db=3*s2-4*s+1,dc=(-6*s2+6*s)/span,dd=3*s2-2*s;
 out.vx=da*p[j][0]+db*m[j][0]+dc*p[j+1][0]+dd*m[j+1][0];
 out.vy=da*p[j][1]+db*m[j][1]+dc*p[j+1][1]+dd*m[j+1][1];return out;
}
function birdHeadingDelta(a,b){return Math.atan2(Math.sin(b-a),Math.cos(b-a));}
var birdRoutes=[];
function birdState(t,i,panX,panY,night){
 var group=i<3,period=group?94:88+(i-3)*17.31,clock=t+(group?18-i*1.8:[10,51,83,31][i-3]),cycle=Math.floor(clock/period),age=clock-cycle*period;
 var flight=group?60:54+(i-3)*4.7;if(age>flight||night>.65)return null;
 var cached=birdRoutes[i];if(!cached||cached.cycle!==cycle)cached=birdRoutes[i]={cycle:cycle,route:makeBirdRoute(i,cycle)};
 var scratch=birdFrameScratch[i];if(!scratch)scratch=birdFrameScratch[i]={q:{},pre:{},post:{},pose:{}};
 var u=age/flight,route=cached.route,q=sampleBirdRouteInto(route,u,scratch.q),speed=Math.hypot(q.vx,q.vy),heading=Math.atan2(q.vy,q.vx);
 var pre=sampleBirdDirectionInto(route,u-.012,scratch.pre),post=sampleBirdDirectionInto(route,u+.012,scratch.post),turn=birdHeadingDelta(Math.atan2(pre.vy,pre.vx),Math.atan2(post.vy,post.vx));
 var bank=birdClamp(turn*1.7,-.72,.72)+.055*Math.sin(t*.43+i*3.1);
 var separation=group?(i-1)*(12+3*Math.sin(t*.17+i))+Math.sin(t*.29+i*2)*3:Math.sin(t*.21+i)*4;
 var x=q.x-Math.sin(heading)*separation+panX*.9,y=q.y+Math.cos(heading)*separation+panY*.9;
 var size=(group?6.2-i*.36:5.1+(i%3)*.5)*(1+.06*Math.sin(u*5+i));
 var climb=birdClamp(-q.vy/Math.max(1,speed),0,1),glide=birdSmooth(-.1,.5,Math.sin(age*(.31+i*.012)+i*2.71)+.22*Math.sin(age*.73+i));
 var effort=Math.max(1-glide*.94,climb*.78),beat=t*(5.8+i*.57)+i*2.71;
 var alpha=(1-night)*(group?.53:.43)*birdSmooth(0,.06,u)*(1-birdSmooth(.94,1,u));
 // Returned object is reused on the next call for this bird. Consumers must
 // copy its scalar values immediately; BirdMesh.update does so.
 var out=scratch.pose;out.x=x;out.y=y;out.size=size;out.heading=heading;
 out.bank=bank;out.effort=effort;out.beat=beat;out.alpha=alpha;return out;
}
