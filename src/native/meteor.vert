attribute highp vec4 qt_Vertex;
attribute highp vec2 qt_MultiTexCoord0;
uniform highp mat4 qt_Matrix;
uniform highp float progress;
void main(){highp vec2 p=vec2(650.+progress*400.,90.+progress*180.);if(qt_MultiTexCoord0.x>.5)p+=qt_MultiTexCoord0.y<.5?vec2(-125.,-58.):vec2(-60.,-27.5);gl_Position=qt_Matrix*vec4(p,0.,1.);}
