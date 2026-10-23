precision mediump float;
uniform highp float alpha;
uniform lowp float qt_Opacity;
void main(){gl_FragColor=vec4(vec3(.75,.86,1.)*alpha,alpha)*qt_Opacity;}
