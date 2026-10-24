// ES5-compatible civil-time adapter. System is the portable default.
function parts(epoch, zone) {
    var d=new Date(epoch), utc=zone==="UTC"||zone==="Europe/London";
    if(zone==="Europe/London") {
        var y=d.getUTCFullYear();
        function boundary(month){var end=new Date(Date.UTC(y,month+1,0));return Date.UTC(y,month,end.getUTCDate()-end.getUTCDay(),1);}
        d=new Date(epoch+(epoch>=boundary(2)&&epoch<boundary(9)?3600000:0));
    }
    function get(name){return d["get"+(utc?"UTC":"")+name]();}
    return {year:get("FullYear"),month:get("Month"),day:get("Date"),weekday:get("Day"),hour:get("Hours"),minute:get("Minutes"),second:get("Seconds"),decimalHour:get("Hours")+get("Minutes")/60+get("Seconds")/3600};
}
function pad(n){return n<10?"0"+n:String(n);}
function timeText(p,format){return format==="12h"?String(p.hour%12||12)+":"+pad(p.minute)+(p.hour<12?" AM":" PM"):pad(p.hour)+":"+pad(p.minute);}
function dateText(p){return ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"][p.weekday]+", "+p.day+" "+["January","February","March","April","May","June","July","August","September","October","November","December"][p.month];}
if(typeof module!=="undefined"&&module.exports)module.exports={parts:parts,timeText:timeText,dateText:dateText};
