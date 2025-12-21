begun_auto_url = 'http://autocontext.begun.ru/sense.php?';

begun_last_modified_time = Date.parse(document.lastModified) / 1000;
begun_referrer_url = document.referrer;

if (window.begun_page_url == null) {
  window.begun_page_url = document.location;
}
if (window.begun_page_url!=document.location) {
 window.begun_page_location = document.location;
}


function begun_quoted(str) {
  return (str != null) ? '"' + str + '"' : '""';
}

function begun_escape(str) {
  return escape(str);
}

function begun_append(param, value) {
  if (value) {
    window.begun_auto_url += '&' + param + '=' + begun_escape(value);
  }
}

function begun_autocontext() {
  var w = window;
  var stopwords;
  if (stopwords == null) stopwords = '';
  begun_append('url', w.begun_page_url);
  begun_append('pad_id', w.begun_auto_pad);
  begun_append('ref', w.begun_referrer_url);
  begun_append('loc', w.begun_page_location);
  begun_append('lmt', w.begun_last_modified_time);

  begun_append('kw', w.begun_auto_keywords);
  begun_append('stopwords', w.stopwords);
  begun_append('begun_self_keywords' , w.begun_self_keywords);
  begun_append('n', w.begun_auto_limit);
  begun_append('oe', w.begun_auto_encoding);
  begun_append('begun_utf8', window.begun_utf8);
  begun_append('begun_koi8', window.begun_koi8);

  if (w.begun_scroll) begun_append('begun_scroll', w.begun_scroll);

  w.begun_auto_url = w.begun_auto_url.substring(0, 1524);
  w.begun_auto_url = w.begun_auto_url.replace(/%[0-9a-fA-F]?$/, '');

  begun_append('rnd', Math.random());


  document.write('<scr' + 'ipt language="JavaScript1.1"' + ' src=' + begun_quoted(w.begun_auto_url) +'></scr' + 'ipt>');
}

var PositionBA = {
    cumulativeOffset: function(element) {
        var valueT = 0, valueL = 0;
        do {
            valueT += element.offsetTop  || 0;
            valueL += element.offsetLeft || 0;
            element = element.offsetParent;
        } while (element);
        return [valueL, valueT];
    }
}

begun_autocontext();



