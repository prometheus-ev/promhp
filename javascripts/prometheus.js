var Prometheus = {};

Prometheus.lang = 'en';

Prometheus.nopandora = function() {
  var flag = true;
  var text = Prometheus.lang === 'de' ?
    "<strong>Das Bildarchiv steht Ihnen zur Zeit leider nicht zur Verfügung!</strong>\n" +
    "Wir bemühen uns, den Betrieb schnellstmöglich wiederherzustellen. Bitte\n" +
    "entschuldigen Sie die Unannehmlichkeiten.\n<br /><br />Ihr prometheus-Team"
  :
    "<strong>The image archive is currently not available!</strong>\n" +
    "We're sorry about this inconvenience and try to recover the\n" +
    "service as soon as possible.\n<br /><br />Your prometheus Team"

  $$('.nopandora.hidden').each(function(i) {
    if (flag) {
      flag = false;
      $$('.pandoraonly').invoke('hide');
    }

    i.update(text).removeClassName('hidden');
  });
};

Prometheus.stretch_main = function() {
  var height = $('workspace').getHeight();

  var main = $('main');
  if (main.getHeight() < height) {
    main.setStyle({ height: height + 'px' });
  }
};

document.observe('dom:loaded', Prometheus.stretch_main.bindAsEventListener(document));
