.pragma library
var phases=['dawn','morning','noon','afternoon','evening','dusk','night'];
function valid(value, choices, fallback) { return choices.indexOf(value)>=0?value:fallback; }
function state(scene,season,style,theme,framing,motion) {
 return {scene:valid(scene,['valley','lookout'],'valley'),season:valid(season,['autumn','winter'],'winter'),style:valid(style,['colour'],'colour'),theme:valid(theme,['auto'].concat(phases),'auto'),framing:valid(framing,['wide','close'],'wide'),motion:!!motion};
}
function rows(s) {
 var r=['scene','season','auto','time'];
 if(s.scene==='lookout')r.push('framing');
 r.push('motion','done');return r;
}
function label(key) { return {scene:'Scene',season:'Season',style:'Style',auto:'Automatic time',time:'Time of day',framing:'Framing',motion:'Motion',done:'Done'}[key]; }
function options(key) { return {scene:['valley','lookout'],season:['autumn','winter'],style:['colour'],auto:['off','on'],time:phases,framing:['wide','close'],motion:['off','on'],done:[]}[key]; }
function title(value) { return value==='close'?'Close-up':value.charAt(0).toUpperCase()+value.slice(1); }
function value(s,key,period) {
 if(key==='auto')return s.theme==='auto'?'on':'off';
 if(key==='time')return s.theme==='auto'?valid(period,phases,'evening'):s.theme;
 if(key==='motion')return s.motion?'on':'off';
 if(key==='done')return '';
 return s[key];
}
function change(s,key,direction,period) {
 var choices=options(key),v=value(s,key,period),i=choices.indexOf(v);
 if(!choices.length)return null;
 v=choices[(Math.max(0,i)+direction+choices.length)%choices.length];
 if(key==='auto')return {key:'lighting',value:{style:'colour',theme:v==='on'?'auto':valid(period,phases,'evening')}};
 if(key==='time')return {key:'lighting',value:{style:'colour',theme:v}};
 if(key==='motion')return {key:'motion',value:v==='on'};
 return {key:key,value:v};
}
function source(scene,season,style,index,framing) {
 var s=state(scene,season,style,'auto','wide',true),name=phases[Math.max(0,Math.min(6,index))];
 if(s.scene==='lookout'&&s.season==='autumn'&&s.style==='colour'&&name==='afternoon'&&framing!=='close')return 'assets/lookout-original/noon-4k.jpg';
 if(s.scene==='lookout'&&s.season==='winter'&&s.style==='colour'&&name==='morning'&&framing==='close')return 'assets/lookout-close/winter/morning-ai-2x.png';
 if(s.scene==='lookout'&&framing==='close')return 'assets/lookout-close/'+s.season+'/'+(s.style==='ember'?'ember':name)+'.jpg';
 if(s.style==='ember')return 'assets/ember/'+s.scene+'-'+s.season+'.jpg';
 if(s.scene==='lookout')return 'assets/lookout-'+s.season+'/'+name+'.jpg';
 return 'assets/'+s.season+'/'+(s.season==='autumn'&&name==='evening'?'evening-vibrant':name)+'.jpg';
}

// Extra separation where bright snow falls directly behind the launcher logos.
function buttonBacking(scene,season,style,period,framing) {
 if(season!=='winter')return 0;
 if(scene==='lookout'&&framing==='close') {
  if(style==='ember')return .30;
  var amounts=[.60,.70,.75,.70,.40,.45,.60];
  return amounts[Math.max(0,phases.indexOf(period))];
 }
 return style!=='ember'&&['dawn','morning','noon','afternoon'].indexOf(period)>=0?.60:0;
}

// Dedicated menu previews avoid reading and decoding full wallpaper files.
function thumbnailSource(scene,season,style,index) {
 var s=state(scene,season,style,'auto','wide',true);
 var name=s.style==='ember'?'ember':phases[Math.max(0,Math.min(6,index))];
 return 'previews/'+s.scene+'-'+s.season+'-'+name+'.jpg';
}
