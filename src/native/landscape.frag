precision highp float;
varying highp vec2 vUV;
uniform sampler2D sourceA;
uniform sampler2D sourceB;
uniform sampler2D clearSky;
uniform sampler2D valleyMask;
uniform sampler2D frontMask;
uniform highp float clearWinterA;
uniform highp float clearWinterB;
uniform highp float blend;
uniform lowp float qt_Opacity;
void main(){
 vec3 colourA=texture2D(sourceA,vUV).rgb;
 vec3 colourB=texture2D(sourceB,vUV).rgb;
 if(clearWinterA+clearWinterB>0.){
  float land=smoothstep(.02,.97,max(texture2D(valleyMask,vUV).a,texture2D(frontMask,vUV).a));
  vec3 sky=texture2D(clearSky,vUV).rgb;
  colourA=mix(colourA,sky,(1.-land)*clearWinterA);
  colourB=mix(colourB,sky,(1.-land)*clearWinterB);
 }
 gl_FragColor=vec4(mix(colourA,colourB,blend),1.)*qt_Opacity;
}
