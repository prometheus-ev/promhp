var Prometheus = {};

Prometheus.nopandora = function() {
  var flag = true;

  $$('.nopandora.hidden').each(function(i) {
    if (flag) {
      flag = false;
      $$('.pandoraonly').invoke('hide');
    }

    i.removeClassName('hidden');
  });
};
