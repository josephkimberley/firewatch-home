import QtQuick 2.12
import "Appearance.js" as Appearance
Item {
 id:panel;anchors.fill:parent;visible:opened
 property bool opened:false
 // Decode all 28 tiny previews after the scene settles; retain their cached pixels.
 property bool previewsLoaded:false
 onOpenedChanged:if(opened)previewsLoaded=true
 Timer {interval:1500;running:!panel.previewsLoaded&&!panel.busy;repeat:false;onTriggered:panel.previewsLoaded=true}
 property var selectionState:Appearance.state('valley','winter','colour','auto','wide',true)
 property string period:'evening'
 property string fontFamily:'Arial'
 property bool busy:false
 property int focusIndex:0
 readonly property var scenes:[{label:'Valley',scene:'valley',season:'autumn'},{label:'Snowy valley',scene:'valley',season:'winter'},{label:'Lookout',scene:'lookout',season:'autumn'},{label:'Snowy lookout',scene:'lookout',season:'winter'}]
 readonly property int previewIndex:Math.max(0,Appearance.phases.indexOf(period))
 readonly property int selectedScene:(selectionState.scene==='lookout'?2:0)+(selectionState.season==='winter'?1:0)
 readonly property var lowerKeys:selectionState.scene==='lookout'?[4,5,6,7,8,9]:[4,5,6,7,9]
 signal changed(string key,var value)
 signal dismissed()
 function open(){focusIndex=selectedScene;opened=true;}
 function close(){opened=false;dismissed();}
 function change(key,direction){var r=Appearance.change(selectionState,key,direction,period);if(r)changed(r.key,r.value);}
 function activate(index){
  focusIndex=index;
  if(index<4){var s=scenes[index];changed('sceneChoice',{scene:s.scene,season:s.season});}
  else if(index===4)change('time',-1);
  else if(index===5||index===6)change('time',1);
  else if(index===7)change('auto',1);
  else if(index===8)change('framing',1);
  else if(index===9)change('motion',1);
  else close();
 }
 function handle(key,repeat){
  if(key===Qt.Key_Back||key===Qt.Key_Escape||key===461){close();return true;}
  var row=focusIndex<4?[0,1,2,3]:lowerKeys;
  if(key===Qt.Key_Left||key===Qt.Key_Right){var d=key===Qt.Key_Left?-1:1;focusIndex=row[(row.indexOf(focusIndex)+d+row.length)%row.length];return true;}
  if(key===Qt.Key_Down){focusIndex=focusIndex<4?5:focusIndex;return true;}
  if(key===Qt.Key_Up){focusIndex=selectedScene;return true;}
  if(key===Qt.Key_Return||key===Qt.Key_Enter||key===Qt.Key_Select){if(!repeat)activate(focusIndex);return true;}
  return false;
 }
 onLowerKeysChanged:if(focusIndex>=4&&lowerKeys.indexOf(focusIndex)<0)focusIndex=9
 MouseArea{anchors.fill:parent;onClicked:panel.close()}
 Rectangle {
  objectName:"floatingMenu"
  anchors.right:parent.right;anchors.rightMargin:100;anchors.bottom:parent.bottom;anchors.bottomMargin:254
  width:754;height:276;radius:5;color:'#c9142022';border.width:0
  MouseArea{anchors.fill:parent;onClicked:mouse.accepted=true}
  Row{x:16;y:20;spacing:14
   Repeater{model:4
    delegate:Item{
     id:card;property int sceneIndex:index;width:170;height:153
     Repeater {model:7
      delegate:Image {
       objectName:"appearanceThumbnail"+card.sceneIndex+"_"+index
       x:0;y:0;width:170;height:96;visible:index===panel.previewIndex
       source:panel.previewsLoaded?Qt.resolvedUrl(Appearance.thumbnailSource(panel.scenes[card.sceneIndex].scene,panel.scenes[card.sceneIndex].season,'colour',index)):''
       sourceSize:Qt.size(320,180);cache:true;asynchronous:true;fillMode:Image.PreserveAspectCrop;smooth:true
      }
     }
     Rectangle{x:-4;y:-4;width:178;height:104;radius:5;color:'transparent';border.width:panel.focusIndex===index?2:panel.selectedScene===index?1:0;border.color:panel.focusIndex===index?'#f4ebdd':'#a6f4ebdd'}
     Text{x:0;y:111;text:panel.scenes[index].label;font.family:panel.fontFamily;font.pixelSize:24;font.letterSpacing:.4;color:'#f1e4cf'}
     Text{x:151;y:111;visible:panel.selectedScene===index;text:'✓';font.family:panel.fontFamily;font.pixelSize:21;color:'#eee0c5'}
     MouseArea{anchors.fill:parent;hoverEnabled:true;onEntered:panel.focusIndex=index;onClicked:panel.activate(index)}
     Accessible.role:Accessible.Button;Accessible.name:panel.scenes[index].label;Accessible.onPressAction:panel.activate(index)
    }
   }
  }
  Rectangle{x:16;y:195;width:722;height:1;color:'#20fff2dc'}
  Repeater{model:4
   delegate:Rectangle{
    property int key:4+index
    x:[16,50,156,218][index];y:210;width:index===1?102:index===3?64:30;height:46;radius:4;color:panel.focusIndex===key?'#15fff2dc':'transparent';border.width:panel.focusIndex===key?1:0;border.color:'#fff2dc'
    Text{anchors.centerIn:parent;text:index===0?'‹':index===1?Appearance.title(Appearance.value(panel.selectionState,'time',panel.period)):index===2?'›':Appearance.value(panel.selectionState,'auto',panel.period)==='on'?'Auto ✓':'Auto';font.family:panel.fontFamily;font.pixelSize:23;font.letterSpacing:.4;color:index===3&&Appearance.value(panel.selectionState,'auto',panel.period)==='on'?'#eee0c5':'#f1e4cf'}
    MouseArea{anchors.fill:parent;hoverEnabled:true;onEntered:panel.focusIndex=parent.key;onClicked:panel.activate(parent.key)}
    Accessible.role:Accessible.Button;Accessible.name:index===0?'Previous time':index===3?'Automatic time': 'Next time';Accessible.onPressAction:panel.activate(key)
   }
  }
  Rectangle{x:204;y:221;width:1;height:24;color:'#35fff2dc'}
  Rectangle{x:304;y:221;width:1;height:24;color:'#35fff2dc';visible:panel.selectionState.scene==='lookout'}
  Rectangle{x:318;y:210;width:108;height:46;radius:4;visible:panel.selectionState.scene==='lookout'
   color:panel.focusIndex===8?'#15fff2dc':'transparent';border.width:panel.focusIndex===8?1:0;border.color:'#fff2dc'
   Text{anchors.centerIn:parent;text:panel.selectionState.framing==='close'?'Close-up ✓':'Close-up';font.family:panel.fontFamily;font.pixelSize:23;font.letterSpacing:.4;color:panel.selectionState.framing==='close'?'#eee0c5':'#f1e4cf'}
   MouseArea{anchors.fill:parent;hoverEnabled:true;onEntered:panel.focusIndex=8;onClicked:panel.activate(8)}
   Accessible.role:Accessible.CheckBox;Accessible.name:'Close-up';Accessible.checked:panel.selectionState.framing==='close';Accessible.onPressAction:panel.activate(8)
  }
  Rectangle{x:610;y:210;width:128;height:46;radius:4
   color:panel.focusIndex===9?'#15fff2dc':'transparent';border.width:panel.focusIndex===9?1:0;border.color:'#fff2dc'
   Row{anchors.centerIn:parent;spacing:8
    Rectangle{width:6;height:6;radius:3;anchors.verticalCenter:parent.verticalCenter;color:panel.selectionState.motion?'#eacb92':'#73766f'}
    Text{text:panel.selectionState.motion?'Motion on':'Motion off';font.family:panel.fontFamily;font.pixelSize:23;font.letterSpacing:.4;color:'#f1e4cf'}
   }
   MouseArea{anchors.fill:parent;hoverEnabled:true;onEntered:panel.focusIndex=9;onClicked:panel.activate(9)}
   Accessible.role:Accessible.CheckBox;Accessible.name:'Motion';Accessible.checked:panel.selectionState.motion;Accessible.onPressAction:panel.activate(9)
  }
 }
}
