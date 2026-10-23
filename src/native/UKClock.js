// UK civil time, independent of the native process's TZ and local timezone files.
// Current UK rules: last Sunday March 01:00 UTC to last Sunday October 01:00 UTC.
// https://www.gov.uk/when-do-the-clocks-change
// For current/future display, not historical date conversion before 1996.
function lastSundayUtc(year, month) {
    var end = new Date(Date.UTC(year, month + 1, 0));
    return Date.UTC(year, month, end.getUTCDate() - end.getUTCDay(), 1);
}
function parts(epoch) {
    if (epoch === undefined) epoch = Date.now();
    var utc = new Date(epoch), year = utc.getUTCFullYear();
    var summer = epoch >= lastSundayUtc(year, 2) && epoch < lastSundayUtc(year, 9);
    var local = new Date(epoch + (summer ? 3600000 : 0));
    return {year:local.getUTCFullYear(), month:local.getUTCMonth(), day:local.getUTCDate(),
        weekday:local.getUTCDay(), hour:local.getUTCHours(), minute:local.getUTCMinutes(),
        second:local.getUTCSeconds(), zone:summer ? "BST" : "GMT",
        decimalHour:local.getUTCHours()+local.getUTCMinutes()/60+local.getUTCSeconds()/3600};
}
function pad(value) { return value < 10 ? "0" + value : String(value); }
function timeText(value) { return pad(value.hour) + ":" + pad(value.minute); }
function dateText(value) {
    var weekdays=["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
    var months=["January","February","March","April","May","June","July","August","September","October","November","December"];
    return weekdays[value.weekday]+", "+value.day+" "+months[value.month];
}
if(typeof module !== "undefined") module.exports={parts:parts,timeText:timeText,dateText:dateText,lastSundayUtc:lastSundayUtc};
