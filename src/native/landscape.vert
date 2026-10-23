attribute highp vec4 qt_Vertex;
attribute highp vec2 qt_MultiTexCoord0;
uniform highp mat4 qt_Matrix;
uniform highp float time;
uniform highp float artworkZoom;
uniform highp float landscapeWind;
uniform highp float night;
uniform highp vec2 focusPan;
varying highp vec2 vUV;
highp vec4 wind;
void tree(highp vec2 p, highp float cx, highp float root, highp float top, highp float width, highp float amp, highp float phase) {
 // Exact zero-support rejection; smoothstep masks are zero outside this box.
 if(p.y<=top-28.||p.y>=root||abs(p.x-cx)>=width+35.)return;
 highp float h=clamp((root-p.y)/(root-top),0.,1.);
 highp float edge=width*(1.-.72*h);
 highp float mask=(1.-smoothstep(edge*.65,edge+35.,abs(p.x-cx)))*smoothstep(top-28.,top,p.y)*(1.-smoothstep(root-12.,root,p.y));
 highp float weight=mask*pow(h,1.65)*amp;
 if(weight>wind.x)wind=vec4(weight,phase,h,mask*clamp(abs(p.x-cx)/width,0.,1.)*h);
}
void main(){
 // Qt GridMesh uses the opposite cell diagonal to the original indexed mesh.
 // Mirroring its logical Y restores the identical triangles and interpolation.
 highp vec2 p=vec2(qt_MultiTexCoord0.x,1.-qt_MultiTexCoord0.y)*vec2(1920.,1080.);
 wind=vec4(0.);
 tree(p,376.,825.,312.,108.,5.4,.3);tree(p,548.,591.,319.,67.,3.4,2.1);
 tree(p,839.,721.,418.,58.,3.2,4.7);tree(p,1106.,650.,385.,66.,3.8,1.3);
 tree(p,1220.,615.,458.,24.,1.6,5.8);tree(p,1807.,324.,92.,59.,3.4,3.5);
 tree(p,1320.,560.,418.,27.,1.7,6.4);
 highp float upper=1.-smoothstep(25.,80.,p.y);
 highp float centre=smoothstep(655.,790.,p.x)*(1.-smoothstep(1110.,1240.,p.x))*(1.-smoothstep(200.,300.,p.y));
 highp float sky=max(upper,centre),nearDepth=smoothstep(280.,850.,p.y);
 highp vec2 pos=p;
 highp float gust=sin(time*.63+wind.y)+.32*sin(time*.27+wind.y*1.7)+.12*sin(time*1.13+wind.y);
 pos.x+=wind.x*gust*landscapeWind;
 pos.y+=wind.w*.32*sin(time*1.04+wind.z*17.+wind.y)*landscapeWind;
 vUV=p/vec2(1920.,1080.);
 gl_Position=qt_Matrix*vec4((pos-vec2(960.,594.))*artworkZoom+vec2(960.,594.),0.,1.);
}
