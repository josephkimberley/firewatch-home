precision mediump float;
varying highp float coverage;
uniform lowp float qt_Opacity;
void main(){gl_FragColor=vec4(vec3(.27,.13,.12)*coverage,coverage)*qt_Opacity;}
