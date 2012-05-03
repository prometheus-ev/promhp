var Prometheus = {

  lang: 'en',

  switch_locale_switcher: function(restore) {
    var s = $('locale_switcher');
    if (s) {
      if (restore) {
        var c = this.locale_switcher_content;
        if (c) {
          s.innerHTML = c;
        }
      }
      else {
        this.locale_switcher_content = s.innerHTML;
      }
    }
  },

  switch_to_standard_mode: function() {
    var expire_at = new Date();
    expire_at.setDate(expire_at.getDate() + 1);
    var value = "standard-mode; expires=" + expire_at.toUTCString();
    document.cookie = value;

    this.remove_mobile_stylesheet();
  },

  check_view_mode: function() {
    var cookie = document.cookie.split(";");

    for (i = 0; i < cookie.length;i++) {
      if (cookie[i] == 'standard-mode') {
        this.remove_mobile_stylesheet();
      }
    }
  },

  remove_mobile_stylesheet: function() {
    $('mobil-stylesheet').remove();
  },

  newwindow: function() {
    $$('a.newwindow').each(function(i) {
      if (!Object.isString(i.target) || i.target.blank()) {
        i.target = '_blank';
      }
    });
  }

};

document.observe('dom:loaded', Prometheus.newwindow.bindAsEventListener(document));
