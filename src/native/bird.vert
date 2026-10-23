attribute highp vec4 qt_Vertex;
attribute highp vec2 qt_MultiTexCoord0;
uniform highp mat4 qt_Matrix;
uniform highp vec4 pose; // x,y,size,heading
uniform highp vec4 motion; // bank,effort,beat,alpha
uniform highp float edgeWidth;
varying highp float coverage;
highp vec2 forwardBasis,sideBasis;
highp vec2 w0,w1,w2,w3,w4,w5;
highp vec2 xy(highp vec3 p){
 return pose.xy+(p.x*forwardBasis+p.y*sideBasis-vec2(0.,p.z))*pose.z;
}
void initWing(highp float side){
 highp float phase=motion.z+side*.055,stroke=sin(phase+.16*sin(phase)),wristStroke=sin(phase-.48);
 highp float projection=(side>0.?.89:1.)*clamp(1.-side*motion.x*.38,.68,1.3);
 highp float extension=(1.80-motion.y*(.13+.24*abs(stroke)))*projection;
 highp float fold=motion.y*(.5+.5*wristStroke),sweep=.12+motion.y*(.10-.20*stroke);
 highp float elbowLift=.08+motion.y*stroke*.39+side*motion.x*.19;
 highp float wristLift=.16+motion.y*sin(phase-.20)*.76+side*motion.x*.38;
 highp float tipLift=.20+motion.y*sin(phase-.34)*1.16+side*motion.x*.55;
 w0=xy(vec3(-.12,side*.10,0.));
 w1=xy(vec3(-.10-sweep,side*extension*.49,elbowLift));
 w2=xy(vec3(-.34-sweep-fold*.16,side*extension*.85,wristLift));
 w3=xy(vec3(-.56-fold*.24,side*extension,tipLift));
 w4=xy(vec3(-.63-fold*.13,side*extension*.64,wristLift*.68));
 w5=xy(vec3(-.48,side*.1,0.));
}
highp vec2 wing(highp float side,int i){
 if(i==0)return w0;if(i==1)return w1;if(i==2)return w2;
 if(i==3)return w3;if(i==4)return w4;return w5;
}
highp vec2 body(int i){
 if(i==0)return xy(vec3(.65,0.,0.));
 if(i==1)return xy(vec3(.13,-.15,0.));
 if(i==2)return xy(vec3(-.55,0.,0.));
 return xy(vec3(.13,.15,0.));
}
highp vec2 polygon(bool isWing,highp float side,int i){return isWing?wing(side,i):body(i);}
highp float polygonArea(bool isWing,highp float side){
 int n=isWing?6:4;highp float area=0.;highp vec2 origin=polygon(isWing,side,0);
 for(int k=0;k<6;k++){if(k<n){int j=k+1;if(j==n)j=0;highp vec2 a=polygon(isWing,side,k)-origin,b=polygon(isWing,side,j)-origin;area+=a.x*b.y-b.x*a.y;}}
 return area;
}
highp vec2 outer(bool isWing,highp float side,int i){
 int n=isWing?6:4;highp float area=polygonArea(isWing,side);
 int prev=i-1;if(prev<0)prev=n-1;int next=i+1;if(next==n)next=0;
 highp vec2 p=polygon(isWing,side,i),a=p-polygon(isWing,side,prev),b=polygon(isWing,side,next)-p;
 highp float sign=area>0.?1.:-1.;
 a=vec2(sign*a.y,-sign*a.x)/max(length(a),.000001);b=vec2(sign*b.y,-sign*b.x)/max(length(b),.000001);
 return p+(a+b)/max(.5,1.+dot(a,b))*edgeWidth;
}
highp vec2 fringe(bool isWing,highp float side,int t,int corner){
 int n=isWing?6:4;int i=t/2,j=i+1;if(j==n)j=0;bool second=t-i*2==1;
 coverage=motion.w*(isWing?.97:1.);
 if(abs(polygonArea(isWing,side))<.01)coverage=0.;
 if(corner==0)return polygon(isWing,side,i);
 if(!second&&corner==1)return polygon(isWing,side,j);
 coverage=0.;return outer(isWing,side,second&&corner==2?i:j);
}
highp vec2 vertex(int triangle,int corner){
 coverage=motion.w;
 if(triangle<32){
  highp float side=triangle<16?-1.:1.;int t=triangle;if(t>=16)t-=16;
  initWing(side);
  if(t>=4)return fringe(true,side,t-4,corner);
  int i=0;
  if(t==0){i=corner==0?0:(corner==1?1:5);coverage*=.94;}
  if(t==1){i=corner==0?1:(corner==1?4:5);coverage*=.94;}
  if(t==2)i=corner==0?1:(corner==1?2:4);
  if(t==3)i=corner==0?2:(corner==1?3:4);
  return wing(side,i);
 }
 int t=triangle-32;
 if(t>=5)return fringe(false,0.,t-5,corner);
 if(t==0)return body(corner==0?0:(corner==1?1:2));
 if(t==1)return body(corner==0?0:(corner==1?2:3));
 if(t==2)return xy(corner==0?vec3(.67,-.045,0.):(corner==1?vec3(.88,0.,0.):vec3(.67,.065,0.)));
 if(t==3)return xy(corner==0?vec3(-.45,0.,0.):(corner==1?vec3(-.91,-.20,0.):vec3(-.77,.025,0.)));
 return xy(corner==0?vec3(-.45,0.,0.):(corner==1?vec3(-.77,-.025,0.):vec3(-.91,.20,0.)));
}
void main(){
 highp float cs=cos(pose.w),sn=sin(pose.w);
 forwardBasis=vec2(cs*.60,sn*.60);sideBasis=vec2(.86*cs-.45*sn,.18*cs+.57*sn);
 // Three grid cells per independent triangle; connecting cells are degenerate.
 int column=int(floor(qt_MultiTexCoord0.x*135.+.5));int triangle=column/3;
 int local=column-triangle*3;int corner=local==0?0:(local==1?(qt_MultiTexCoord0.y<.5?1:2):2);
 if(triangle>44){triangle=44;corner=2;}
 highp vec2 p=vertex(triangle,corner);gl_Position=qt_Matrix*vec4(p,0.,1.);
}
