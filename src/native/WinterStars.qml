import QtQuick 2.12
// Sparse sky-only stars. One draw call; terrain and clouds remain stationary.
ShaderEffect {
 property real time:0
 property real amount:1
 property real zoom:1.025
 property variant skyImage
 property variant valleyImage
 property variant frontImage
 blending:true
 fragmentShader: "
  precision highp float;
  varying highp vec2 qt_TexCoord0;
  uniform sampler2D skyImage;
  uniform sampler2D valleyImage;
  uniform sampler2D frontImage;
  uniform highp float time;
  uniform highp float amount;
  uniform highp float zoom;
  uniform lowp float qt_Opacity;
  float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
  void main(){
   vec2 uv=(qt_TexCoord0-vec2(.5,.55))/zoom+vec2(.5,.55);
   // Irregular sparse field, strongest overhead and thinning toward the horizon.
   vec2 sky=vec2(fract(uv.x-time*.00018),uv.y+.001*sin(time*.025));
   vec2 grid=vec2(16.,10.);vec2 field=vec2(sky.x,(sky.y-.015)/.30)*grid;
   vec2 cell=floor(field),local=fract(field);
   float seed=hash(cell);
   float height=clamp((cell.y+.5)/10.,0.,1.);
   float density=mix(.70,.06,smoothstep(0.,1.,height));
   float exists=step(1.-density,seed)*step(0.,cell.y)*(1.-step(10.,cell.y));
   vec2 centre=vec2(.05+.90*hash(cell+17.),.05+.90*hash(cell+47.));
   vec2 delta=(local-centre)*vec2(1920./16.,1080.*.30/10.);
   float radius=.8+.6*hash(cell+71.);
   float dotAlpha=1.-smoothstep(radius*.2,radius,length(delta));
   float cloud=dot(texture2D(skyImage,uv).rgb,vec3(.2126,.7152,.0722));
   float land=smoothstep(.02,.97,max(texture2D(valleyImage,uv).a,texture2D(frontImage,uv).a));
   float twinkle=.55+.14*sin(time*(.15+seed*.12)+seed*19.);
   float alpha=exists*dotAlpha*twinkle*(1.-smoothstep(.12,.30,cloud))*(1.-land)*amount*qt_Opacity;
   gl_FragColor=vec4(vec3(.80,.88,1.)*alpha,alpha);
  }"
}
