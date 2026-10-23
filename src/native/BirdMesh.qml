import QtQuick 2.12
import "SceneShaders.js" as Shaders

ShaderEffect {
    id: bird
    width: 1920; height: 1080
    property vector4d pose: Qt.vector4d(0,0,0,0)
    property vector4d motion: Qt.vector4d(0,0,0,0)
    property real edgeWidth: .75
    blending: true
    mesh: GridMesh { resolution: Qt.size(135,1) }
    vertexShader: Shaders.birdVertex
    fragmentShader: Shaders.birdFragment
    function update(state) {
        if(!state) { if(visible)visible=false; return; }
        pose=Qt.vector4d(state.x,state.y,state.size,state.heading);
        motion=Qt.vector4d(state.bank,state.effort,state.beat,state.alpha);
        var nextVisible=state.alpha>.00001;
        if(visible!==nextVisible)visible=nextVisible;
    }
}
