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
  }

};
