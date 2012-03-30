var Pandora = {};

Pandora.Behaviour = {

  list: [],

  register: function(rules, execute) {
    this.list.push(rules);

    if (execute) {
      this.execute(rules);
    }
  },

  start: function() {
    this.add_dom_load_event(function() {
      Pandora.Behaviour.apply(true);
    });
  },

  apply: function(fire_dom_loaded, ancestor) {
    this.list.each(function(rules) {
      Pandora.Behaviour.execute(rules, fire_dom_loaded, ancestor);
    });
  },

  execute: function(rules, fire_dom_loaded, ancestor) {
    $H(rules).each(function(rule) {
      var elements = $$(rule.key);

      if (ancestor) {
        ancestor = $(ancestor);
        elements = elements.select(function(element) {
          return element === ancestor || element.descendantOf(ancestor);
        });
      }

      if (elements.size() > 0) {
        Pandora.Behaviour.apply_rule(rule.value, elements, fire_dom_loaded);
      }
    });
  },

  apply_rule: function(rule, elements, fire_dom_loaded) {
    $H(rule).each(function(pair) {
      var event_name = pair.key;
      var handler    = pair.value;

      // this will be during document's dom:loaded (or later), so
      // elements' dom:loaded handlers have to be executed immediately
      if (event_name === 'dom:loaded') {
        if (fire_dom_loaded) {
          elements.each(function(element) {
            handler.bind(element)();
          });
        }
      }
      else {
        elements.each(function(element) {
          element.observe(event_name, handler.bindAsEventListener(element));
        });
      }
    });
  },

  add_load_event: function(func) {
    Event.observe(window, 'load', func.bindAsEventListener(window));
  },

  add_dom_load_event: function(func) {
    document.observe('dom:loaded', func.bindAsEventListener(document));
  }

};

Pandora.Behaviour.start();

Pandora.Behaviour.register({
  'body': {
    'dom:loaded': function(e) {
      this.removeClassName('nojs');
      this.addClassName('js');
    }
  },
  '.autoselect': {
    'dom:loaded': function(e) {
      this.form_for_autosubmit(function(form) { form.reset(); });
    },
    change: function(e) {
      this.autosubmit();
    }
  },
  '.autosubmit': {
    click: function(e) {
      this.autosubmit();
    }
  },
  '#content': {
    'dom:loaded': function(e) {
      if (window.location.hash) {
        Pandora.Utils.reveal_anchor(window.location.hash.substr(1));
      }
      else {
        var input = this.select('input[type=text]').first();
        if (input && input.value.blank() && !input.up('.noautofocus')) {
          input.focus();
        }
      }
    }
  },
  'input[type=text], input[type=password]': {
    'dom:loaded': function(e) {
      var is_mandatory = this.hasClassName('mandatory');
      var is_prompt    = this.hasClassName('prompt');

      var insertions = {};

      $A(['before', 'after']).each(function(i) {
        var span = document.createElement('span');
        Element.extend(span);

        span.className = 'input-left-right';

        if (is_mandatory) {
          span.addClassName('mandatory');
        }

        if (is_prompt) {
          span.addClassName('prompt');
        }

        insertions[i] = span;
      });

      this.insert(insertions);
    }
  },
  '.undim input[type=checkbox]': {
    change: function(e) {
      this.toggle_dim();
    }
  },
  'span.short span.a': {
    click: function(e) {
      this.toggle_truncated(e, true);
    }
  },
  'span.full span.a': {
    click: function(e) {
      this.toggle_truncated(e, false);
    }
  },
  '.section_toggle': {
    click: function(e) {
      this.toggle_section();
    }
  },
  '.section_heading a': {
    click: function(e) {
      if (!e.element.hasClassName('ignore-handler')) {
        var section_wrap = this.up('.section_wrap');
        if (section_wrap) {
          section_wrap.expand_section();
        }
      }
    }
  },
  '.popup_toggle': {
    click: function(e) {
      var popup = this.next('.popup');
      if (popup) {
        popup.toggle_popup(this, e);
      }
    }
  },
  '.popup': {
    click: function(e) {
      e.stop();
    }
  },
  '#object-summary a': {
    click: function(e) {
      Pandora.Utils.reveal_anchor(this.href.split('#', 2).last());
    }
  },
  '.download_link': {
    click: function(e) {
      var element = this.next('.download_box');
      if (element) {
        element.modal_box();
      }
    }
  },
  '.thumbnail_select td input[checked]': {
    'dom:loaded': function(e) {
      this.up('td').addClassName('checked');
    }
  },
  '.thumbnail_select td.thumbnail': {
    click: function(e) {
      $$('.thumbnail_select td.checked').invoke('removeClassName', 'checked');

      var td = this.previous('td');
      if (td) {
        var radio = td.down('input[type=radio]');
        if (radio) {
          radio.checked = 'checked';
          td.addClassName('checked');
        }
      }
    }
  }
});

Effect.Shadow = Class.create(Effect.Base, {
  initialize: function(element) {
    this.element = $(element);
    if (!this.element) {
      throw Effect._elementDoesNotExistError;
    }

    this.start(Object.extend({
      startcolor: '#FFFF99',
      endcolor:   '#FFFFFF'
    }, arguments[1] || {}));
  },
  setup: function() {
    if (this.element.getStyle('display') === 'none') {
      this.cancel(); return;
    }

    this.oldStyle = {
      boxShadow: this.element.getStyle('boxShadow') || 'none'
    };

    var s = this.options.startcolor;
    var e = this.options.endcolor;

    this._base = $R(0, 2).map(function(i) {
      return parseInt(s.slice(i * 2 + 1, i * 2 + 3), 16);
    });

    var b = this._base;

    this._delta = $R(0, 2).map(function(i) {
      return parseInt(e.slice(i * 2 + 1, i * 2 + 3), 16) - b[i];
    });
  },
  update: function(position) {
    var b = this._base;
    var d = this._delta;

    this.element.setStyle({
      boxShadow: '0 0 3px 3px ' + $R(0, 2).inject('#', function(m, v, i) {
        return m + (b[i] + d[i] * position).round().toColorPart();
      })
    });
  },
  finish: function() {
    this.element.setStyle(this.oldStyle);
  }
});

Pandora.ModalBox = {

  dialog_id: 'modal_box_dialog',

  overlay_id: 'modal_box_overlay',

  show: function(content) {
    var dialog = $(this.dialog_id);
    if (dialog) {
      dialog.show();
    }
    else {
      dialog = document.createElement('div');
      dialog.id = this.dialog_id;

      dialog.setStyle({
        position:        'fixed',
        top:             '35%',
        left:            '35%',
        border:          '2px solid #4C4C4C',
        backgroundColor: '#262626',
        padding:         '10px',
        width:           '30%',
        height:          '120px',
        zIndex:          99999,
        overflow:        'auto'
      });

      document.body.insert(dialog);
    }

    var overlay = $(this.overlay_id);
    if (overlay) {
      overlay.show();
    }
    else {
      overlay = document.createElement('div');
      overlay.id = this.overlay_id;

      overlay.setStyle({
        position:        'fixed',
        top:             0,
        left:            0,
        width:           '100%',
        height:          '100%',
        backgroundColor: '#000000',
        zIndex:          99990,
        opacity:         0.6
      });

      overlay.toggle_reset_handler(this.hide, true);

      document.body.insert(overlay);
    }

    dialog.update(content);
  },

  hide: function() {
    var object = Pandora.ModalBox;

    $w('dialog_id overlay_id').each(function(i) {
      var element = $(object[i]);
      if (element) {
        element.hide();
      }
    });
  }

};

Pandora.Utils = {

  wrap: function(name, wrapper) {
    this[name] = this[name].wrap(wrapper);
  },

  merge: function() {
    return $A(arguments).inject(new Hash(), function(m, i) {
      m.update(i);
      return m;
    }).toObject();
  },

  modifier_key: function(e) {
    return e.ctrlKey || (e.altKey && e.shiftKey) || e.metaKey;
  },

  list_toggle: function(name, form) {
    var master = name + '_master';
    var item   = name + '_list_item';

    var rules = {};

    rules['.' + master] = {
      click: function(e) {
        var element = $(form);

        element.toggle_checkboxes(item, this.id);
        element.toggle_checkboxes(master, this.id);
      }
    };

    rules['.' + item] = {
      click: function(e) {
        var element = $(form);

        element.toggle_masters(item, master);

        element.select_range(this, item, e, function(_this) {
          element.toggle_masters(item, master);
        });
      }
    };

    Pandora.Behaviour.register(rules);
  },

  reveal_anchor: function(anchor) {
    if (anchor && !anchor.blank()) {
      var element;
      var target = $$('a[name="' + anchor + '"]').first();

      if (target) {
        element = target.up('.section_wrap') || target;
      }
      else {
        element = $(anchor + '-section');
        target = element;
      }

      if (element) {
        if (element.hasClassName('section_wrap')) {
          element.expand_section();
        }

        element.reveal();
        target.scrollTo();
      }
    }
  },

  toggle_clear_popups: function(install, run) {
    $(document.body).toggle_reset_handler(function() {
      $$('.popup').invoke('toggle_popup');
      Pandora.Utils.toggle_clear_popups();
    }, install, run);
  },

  toggle_clear_croppables: function(install, run) {
    $(document.body).toggle_reset_handler(function() {
      Cropper.reset();
      Pandora.Utils.toggle_clear_croppables();
    }, install, run, 'mousedown');
  },

  clip: function(value, min, max) {
    return [[min, value].max(), max].min();
  },

  update_session: function(parameters) {
    if (Pandora.session_update_url) {
      if (/^https?:/.test(Pandora.session_update_url)) {
        window.location.href = Pandora.session_update_url +
          (Pandora.session_update_url.include('?') ? '&' : '?') +
          Object.toQueryString(parameters);
      }
      else {
        var _ = new Ajax.Request(Pandora.session_update_url, {
          parameters:   parameters,
          evalJS:       false,
          evalJSON:     false,
          asynchronous: false
        });
      }
    }
  },

  invisible: $w('hidden noscript'),

  prev_checked: {},

  zoom_enabled: {}

};

Pandora.ElementMethods = {

  apply_rule: function(element, rule) {
    Pandora.Behaviour.apply_rule(rule, $A([$(element)]));
  },

  _original_visible: Element.Methods.visible,

  visible: function(element) {
    element = $(element);

    return Pandora.Utils.invisible.inject(
      element._original_visible(),
      function(m, i) { return m && !element.hasClassName(i); }
    );
  },

  _original_show: Element.Methods.show,

  show: function(element) {
    element = $(element);

    Pandora.Utils.invisible.each(function(i) {
      element.removeClassName(i);
    });

    return element._original_show();
  },

  really_visible: function(element) {
    element = $(element);

    var offset = element.cumulativeOffset();
    return offset[0] !== 0 || offset[1] !== 0;
  },

  reveal: function(element) {
    element = $(element);

    if (!element.visible()) {
      element.show();
    }

    if (!element.really_visible()) {
      var parent = $(element.parentNode);
      if (parent) {
        parent.reveal();
      }
    }
  },

  walk: function() {
    var args = $A(arguments);
    var element = $(args.shift());

    var callback;
    if (Object.isFunction(args.last())) {
      callback = args.pop();
    }

    var target = args.inject(element, function(m, i) {
      if (m) {
        if (Object.isArray(i)) {
          return m[i.shift()].apply(m, i);
        }
        else {
          return m[i]();
        }
      }
    });

    if (target && callback) {
      return callback(target);
    }
    else {
      return target;
    }
  },

  select_by_class_name: function(element, class_name) {
    return $(element).select('.' + class_name);
  },

  intermediateAncestors: function(element, parent) {
    element = $(element);

    if (!element.descendantOf(parent)) {
      return;
    }

    var elements = [];

    (function(i) {
      var j = i.parentNode;
      if (j && j !== parent) {
        elements.push(j);
        arguments.callee(j);
      }
    })(element);

    return elements;
  },

  update_selected: function(element, selector, new_content) {
    var selected = $(element).down(selector);
    if (selected) {
      selected.update(new_content);
    }
  },

  group_item_class: function(element) {
    return $(element).id.sub(/group_master/, 'group_item');
  },

  all_checked: function(element, checkbox_class) {
    element = $(element);

    return element.select_by_class_name(checkbox_class).all(function(i) {
      return i.disabled || i.checked;
    });
  },

  check: function(element, checked) {
    element = $(element);

    element.checked = checked;
    element.toggle_dim();
  },

  toggle_handler: function(element, name, handler, run, receiver) {
    element = $(element);
    var key = '_' + name + '_handler';

    if (!receiver) {
      receiver = element;
    }

    if (element[key]) {
      Event.stopObserving(receiver, name, element[key]);
      delete element[key];
    }

    if (handler) {
      if (run) {
        handler(run);
      }

      element[key] = handler.bindAsEventListener(receiver);
      Event.observe(receiver, name, element[key]);
    }
  },

  toggle_global_handler: function(element, name, handler, run) {
    $(element).toggle_handler(name, handler, run, document);
  },

  toggle_combined_handler: function(element, handler, install, run, name, key) {
    element = $(element);

    element.toggle_handler(name, install && handler, run);
    element.toggle_global_handler('keydown', install && function(e) {
      if (e.keyCode === key) {
        handler();
      }
    });
  },

  toggle_reset_handler: function(element, handler, install, run, name) {
    $(element).toggle_combined_handler(handler,
      install, run, name || 'click', Event.KEY_ESC);
  },

  register_cursor_handler: function(element, handler, initial_style) {
    element = $(element);

    if (!initial_style) {
      initial_style = element.getStyle('cursor');
    }

    var cursor = function(cursor_style) {
      element.style.cursor = cursor_style || initial_style;
    };

    element.apply_rule({
      mouseover: function(e) {
        element.toggle_global_handler('keydown', function(e) {
          handler(cursor, e);
        }, e);

        element.toggle_global_handler('keyup', function() {
          cursor();
        });
      },
      mouseout: function(e) {
        cursor();

        element.toggle_global_handler('keydown');
        element.toggle_global_handler('keyup');
      }
    });

    cursor();
  },

  toggle_popup: function(element, toggle, e) {
    element = $(element);
    var visible = element.visible();

    if (toggle) {
      Pandora.Utils.toggle_clear_popups(!visible, true);

      element.toggle();
      $(toggle).toggle_undim();
    }
    else if (visible) {
      element.hide();

      toggle = element.previous('.popup_toggle');
      if (toggle) {
        toggle.toggle_undim();
      }
    }

    if (e) {
      e.stop();
    }
  },

  toggle_dim: function(element) {
    element = $(element);

    var undim = element.up('.undim');
    if (undim) {
      undim.toggle_class_name_if(element.checked, 'checked');
    }
  },

  toggle_undim: function(element) {
    element = $(element);

    var undim = element.up('.undim');
    if (undim) {
      undim.toggleClassName('undimmed');
    }
  },

  toggle_checkbox: function(element, checked) {
    element = $(element);

    if (element && element.disabled === false) {
      element.check(checked == null ? !element.checked : checked);
    }
  },

  toggle_checkboxes: function(element, checkbox_class, master_id) {
    element = $(element);

    element.select_by_class_name(checkbox_class).invoke(
      'toggle_checkbox', master_id ? $(master_id).checked : null
    );
  },

  toggle_master: function(element, checkbox_class, master_id) {
    element = $(element);

    var master = $(master_id);
    if (master) {
      master.check(element.all_checked(checkbox_class));
    }
  },

  toggle_masters: function(element, checkbox_class, master_class) {
    element = $(element);

    var masters = element.select_by_class_name(master_class);
    var checked = element.all_checked(checkbox_class);

    masters.each(function(i) { i.check(checked); });
  },

  toggle_group_master: function(element, start_element, group_master_class) {
    element = $(element);

    start_element.walk(
      ['up', 1],
      ['previous', '.group_master'],
      ['down', '.' + group_master_class],
      function(i) { i.check(element.all_checked(i.group_item_class())); }
    );
  },

  toggle_group_masters: function(element, group_master_class) {
    element = $(element);

    element.select_by_class_name(group_master_class).each(function(i) {
      i.check(element.all_checked(i.group_item_class()));
    });
  },

  toggle_group: function(element, group_class, group_master_class, group_toggle_class, _this) {
    element = $(_this || element);

    var members = $$('.' + group_class);
    var class_name;

    var is_group_master = element.hasClassName(group_master_class);

    var expanded = is_group_master ?
      members.any(function(i) { return i.visible(); }) :
      members.first().visible();

    var expand_class   = 'expand';
    var collapse_class = 'collapse';

    if (expanded) {
      members.invoke('hide');
      class_name = expand_class;
    }
    else {
      members.invoke('show');
      class_name = collapse_class;
    }

    var toggles = $$('.' + group_toggle_class);

    if (is_group_master) {
      toggles.each(function(i) {
        i.down().className = class_name;
      });
    }
    else {
      element.down().className = class_name;

      class_name = toggles.any(function(i) {
        return i.down().hasClassName(collapse_class);
      }) ? collapse_class : expand_class;
    }

    $$('.' + group_master_class).each(function(i) {
      i.down().className = class_name;
    });
  },

  toggle_elements: function(element, expand_text, collapse_text, element_class) {
    element = $(element);

    var members = $$('.' + element_class);
    var text;

    if (element.innerHTML === collapse_text) {
      members.invoke('hide');
      text = expand_text;
    }
    else {
      members.invoke('show');
      text = collapse_text;
    }

    element.innerHTML = text;
  },

  select_range: function(element, start_element, checkbox_class, e, callback) {
    element = $(element);

    var prev = Pandora.Utils.prev_checked[checkbox_class];
    Pandora.Utils.prev_checked[checkbox_class] = start_element;

    if (!prev || (e && !e.shiftKey)) {
      return;
    }

    var checked  = start_element.checked;
    var value    = start_element.value;
    var prevalue = prev.value;
    var in_range = false;

    var toggle = function(i) {
      if (!i.disabled) {
        i.check(checked);
      }
    };

    element.select_by_class_name(checkbox_class).each(function(i) {
      var ivalue   = i.value;
      var boundary = ivalue === value || ivalue === prevalue;

      if (in_range) {
        if (boundary) {
          in_range = false;
        }

        toggle(i);
      }
      else {
        if (boundary) {
          in_range = true;
          toggle(i);
        }
      }
    });

    if (callback) {
      callback(start_element);
    }
  },

  append_clone: function(element, clone_class, adder) {
    element = $(element);

    // clone element...
    var clone = element.cloneNode(true);
    Element.extend(clone);

    // ...clearing any input fields...
    $A(clone.getElementsByTagName('input')).each(function(i) {
      i.value = '';
    });

    // ...and selected options
    $A(clone.getElementsByTagName('select')).each(function(i) {
      i.options[i.selectedIndex].selected = false;
    });

    // set class name for future reference
    if (clone_class) {
      clone.addClassName(clone_class);
    }

    // hide "adder" if provided
    if (adder) {
      adder.hide();
    }

    // finally insert the new element!
    element.insert({ after: clone });

    return clone;
  },

  fit_dimensions: function(element, width, height) {
    element = $(element);

    if (width) {
      element.fit_width(width);
    }

    if (height) {
      element.fit_height(height);
    }
  },

  reset_dimensions: function(element) {
    element = $(element);

    if (element._original_width) {
      element.width = element._original_width;
    }

    if (element._original_height) {
      element.height = element._original_height;
    }
  },

  fit_width: function(element, width) {
    element = $(element);

    if (element.width <= width) {
      return;
    }

    var original_width  = element.width;
    var original_height = element.height;

    if (!element._original_width) {
      element._original_width = original_width;
    }

    if (!element._original_height) {
      element._original_height = original_height;
    }

    element.width  = width;
    element.height = original_height * width / original_width;
  },

  fit_height: function(element, height) {
    element = $(element);

    if (element.height <= height) {
      return;
    }

    var original_width  = element.width;
    var original_height = element.height;

    if (!element._original_width) {
      element._original_width = original_width;
    }

    if (!element._original_height) {
      element._original_height = original_height;
    }

    element.height = height;
    element.width  = original_width * height / original_height;
  },

  fit_scale: function(element, width, height, callback) {
    element = $(element);

    if (!height) {
      height = width || window.innerHeight;
    }

    if (!width) {
      width = window.innerWidth;
    }

    var dim = element.getDimensions();

    var scale = [height / dim.height, width / dim.width].min();

    style = {
      'WebkitTransform':       'scale(' + scale + ')',
      'WebkitTransformOrigin': '0 0',
         'MozTransform':       'scale(' + scale + ')',
         'MozTransformOrigin': '0 0',
          'MsTransform':       'scale(' + scale + ')',
          'MsTransformOrigin': '0 0',
           'OTransform':       'scale(' + scale + ')',
           'OTransformOrigin': '0 0'
    };

    if (callback) {
      callback(style, scale, dim, width, height);
    }

    element.setStyle(style);
  },

  zoom_enabled: function(element, toggle_class) {
    element = $(element);

    if (Pandora.Utils.zoom_enabled[toggle_class] == null) {
      var zoom_default = false;

      var toggle = $$('.' + toggle_class).first();
      if (toggle) {
        var toggle_attr = toggle.attributes._zoom_enabled;
        if (toggle_attr) {
          zoom_default = toggle_attr.nodeValue === 'true';
        }
      }

      Pandora.Utils.zoom_enabled[toggle_class] = zoom_default;
    }

    return Pandora.Utils.zoom_enabled[toggle_class];
  },

  toggle_zoom: function(element, enable_text, disable_text, toggle_class) {
    element = $(element);

    Pandora.Utils.zoom_enabled[toggle_class] = !element.zoom_enabled(toggle_class);
    var enabled = Pandora.Utils.zoom_enabled[toggle_class];

    $$('.' + toggle_class).each(function(i) {
      i.title = enabled ? disable_text : enable_text;

      var toggle = i.down('.zoom_link');
      if (toggle) {
        toggle.toggle_class_names('enabled', 'disabled');
      }
    });
  },

  zoom: function(element, factor, toggle_class) {
    element = $(element);

    if (!element.height > 0 || !element.zoom_enabled(toggle_class)) {
      return;
    }

    element._zoom_delayed = function() {
      element._zoom_delayed = null;

      var original = element._before_zoom;
      if (!original) {
        var offset = element.positionedOffset();

        original = {
          position:  element.style.position,
          width:     element.width,
          height:    element.height,
          top:       offset.top,
          left:      offset.left,
          zIndex:    element.style.zIndex,
          maxWidth:  element.style.maxWidth,
          maxHeight: element.style.maxHeight
        };

        if (element.attributes._zoom_src) {
          element._zoom_src = element.attributes._zoom_src.nodeValue;
          original.src = element.src;
        }

        element._before_zoom = original;
      }

      if (element._zoom_src) {
        element.src = element._zoom_src;
      }

      element.setStyle({
        position:  'absolute',
        width:     original.width * factor + 'px',
        height:    original.height * factor + 'px',
        top:       original.top - original.height * (factor - 1) / 2 + 'px',
        left:      original.left - original.width * (factor - 1) / 2 + 'px',
        zIndex:    original.zIndex + 1,
        maxWidth:  'none',
        maxHeight: 'none'
      });
    }.delay(0.5);
  },

  unzoom: function(element, toggle_class) {
    element = $(element);

    if (!element.zoom_enabled(toggle_class)) {
      return;
    }

    var timeout = element._zoom_delayed;
    if (timeout) {
      window.clearTimeout(timeout);
      element._zoom_delayed = null;

      return;
    }

    var original = element._before_zoom;
    if (!original) {
      return;
    }

    if (original.src) {
      element.src = original.src;
    }

    element.setStyle({
      position:  original.position,
      width:     original.width + 'px',
      height:    original.height + 'px',
      top:       original.top + 'px',
      left:      original.left + 'px',
      zIndex:    original.zIndex,
      maxWidth:  original.maxWidth,
      maxHeight: original.maxHeight
    });
  },

  hover: function(element, alt) {
    element = $(element);

    var hover_src = element.attributes[alt ? '_alt_hover_src' : '_hover_src'];
    if (hover_src) {
      if (!element._original_src) {
        element._original_src = element.src;
      }

      element.src = hover_src.value;

      if (alt || alt == null) {
        element.walk('up', 'next', 'down', function(i) { i.hover(true); });
      }

      if (!alt) {
        element.walk('up', 'previous', 'down', function(i) { i.hover(false); });
      }
    }
  },

  unhover: function(element, alt) {
    element = $(element);

    var original_src = element._original_src;
    if (original_src) {
      element.src = original_src;

      if (alt || alt == null) {
        element.walk('up', 'next', 'down', function(i) { i.unhover(true); });
      }

      if (!alt) {
        element.walk('up', 'previous', 'down', function(i) { i.unhover(false); });
      }
    }
  },

  toggle_truncated: function(element, e, expand) {
    if (Pandora.Utils.modifier_key(e)) {
      var short, full, parent;

      var parent_attr = element.attributes._parent;
      if (parent_attr) {
        parent = $(parent_attr.nodeValue);
      }

      if (parent) {
        short = parent.select('span.short');
        full  = parent.select('span.full');
      }
      else {
        short = $$('span.short');
        full  = $$('span.full');
      }

      var hideshow = expand ? [short, full] : [full, short];
      hideshow[0].invoke('hide');
      hideshow[1].invoke('show');
    }
    else {
      var d = element.up('span.truncated');

      d.down('span.' + (expand ? 'short' : 'full')).hide();
      d.down('span.' + (expand ? 'full' : 'short')).show();
    }
  },

  autosubmit: function(element) {
    element = $(element);

    var name = element.attributes._name;
    name = name && name.value;

    element.form_for_autosubmit(function(form) {
      if (name) {
        form.insert('<input type="hidden" name="' + name + '" value="commit" />');
      }

      if (!form.onsubmit || form.onsubmit()) {
        form[form.hasClassName('ajax-request') ? 'request' : 'submit']();
      }
    }, function(form) {
      var query = {};

      if (name) {
        query[name] = 'commit';
      }

      if (element.getValue) {
        query[element.name] = element.getValue();
      }

      var action = form.attributes._action;
      action = action ? action.value : window.location.href;

      if (form.hasClassName('ajax-request')) {
        Ajax.Request(action, { parameters: query });
      }
      else {
        window.location.href = action.append_query(query);
      }
    });
  },

  form_for_autosubmit: function(element, real_callback, pseudo_callback) {
    element = $(element);

    var callback;

    var form = element.up('.pseudo-form');
    if (form) {
      callback = pseudo_callback;
    }
    else {
      form = element.form || element.up('form');
      callback = real_callback;
    }

    if (form && callback) {
      return callback(form);
    }
    else {
      return form;
    }
  },

  toggle_section: function(element, class_name, up, expand_text, collapse_text, session_key) {
    element = $(element);

    if (!class_name) {
      class_name = 'section';
    }

    if (!element.hasClassName(class_name + '_toggle')) {
      element = element.down('.' + class_name + '_toggle');
      if (!element) {
        return;
      }
    }

    var toggle = element.down(), collapsed;
    if (toggle) {
      toggle.toggle_class_names('expand', 'collapse');

      collapsed = toggle.hasClassName('expand');
      toggle.title = collapsed ? expand_text : collapse_text;
    }

    element.up(up || 0).select_by_class_name(class_name).invoke('toggle');

    if (Object.isString(session_key) && !session_key.empty()) {
      Pandora.Utils.update_session({
        key:   session_key,
        value: collapsed ? new Date().getTime() / 1000 : ''
      });
    }
  },

  expand_section: function(element) {
    element = $(element);

    var section = element.down('.section');
    if (section && !section.really_visible()) {
      element.toggle_section();
    }
  },

  toggle_class_names: function() {
    var args = $A(arguments);
    var element = $(args.shift());

    args.each(function(i) { element.toggleClassName(i); });
  },

  toggle_class_name_if: function(element, condition, class_name) {
    element = $(element);

    if (condition) {
      element.addClassName(class_name);
    }
    else {
      element.removeClassName(class_name);
    }
  },

  setDimensions: function(element, dim, save) {
    element = $(element);

    if (save) {
      element[save] = element.getDimensions();
    }

    if (Object.isString(dim)) {
      dim = element[dim];
    }
    else if (Object.isElement(dim)) {
      dim = dim.getDimensions();
    }
    else if (Object.isArray(dim)) {
      dim = { width: dim[0], height: dim[1] };
    }

    element.setStyle({ width: dim.width + 'px', height: dim.height + 'px' });
  },

  make_draggable: function(element, options, object) {
    element = $(element);

    if (element.hasClassName('placeholder')) {
      return;
    }

    options = Pandora.Utils.merge({
      revert: 'failure',
      zindex: 10001,
      scroll: window,
      scrollSensitivity: 1
    }, options, object && object.draggable_options);

    var on_start   = options.onStart;
    var on_dropped = options.onDropped;
    var on_end     = options.onEnd;

    options.onStart = function(draggable, e) {
      if (on_start) {
        on_start(draggable, e);
      }

      draggable.element._dropped = false;

      if (Pandora.Utils.modifier_key(e)) {
        draggable.element._copy_draggable = true;

        draggable._clone = draggable.element.cloneNode(true);

        draggable._originallyAbsolute = (draggable.element.getStyle('position') == 'absolute');
        if (!draggable._originallyAbsolute) {
          Position.absolutize(draggable.element);
        }

        draggable.element.parentNode.insertBefore(draggable._clone, draggable.element);
      }
    };

    options.onDropped = function(draggable_element) {
      if (on_dropped) {
        on_dropped(draggable_element);
      }

      draggable_element._dropped = true;
    };

    options.onEnd = function(draggable, e) {
      if (on_end) {
        on_end(draggable, e);
      }

      if (draggable.element._copy_draggable) {
        draggable.element._copy_draggable = false;

        if (!draggable.element._dropped) {
          if (!draggable._originallyAbsolute) {
            Position.relativize(draggable.element);
            draggable.element.style.position = 'relative';
          }

          delete draggable._originallyAbsolute;

          Element.remove(draggable._clone);
          draggable._clone = null;
        }
      }
      else if (draggable.element._dropped) {
        draggable.originalZ = options.zindex;
      }
    };

    var handle;

    if (options.handle) {
      if (Object.isString(options.handle)) {
        handle = element.down('.' + options.handle);
      }

      if (!handle) {
        handle = $(options.handle);
      }
    }
    else {
      handle = element;
    }

    handle.register_cursor_handler(function(cursor, e) {
      if (Pandora.Utils.modifier_key(e)) {
        cursor('copy');
      }
    }, 'move');

    element.addClassName('draggable');

    return new Draggable(element, options);
  },

  make_droppable: function(element, options, object) {
    element = $(element);

    options = Pandora.Utils.merge({
      hoverclass: 'dragdrop'
    }, options, object && object.droppable_options);

    element.addClassName('droppable');

    Droppables.add(element, options);
  },

  make_croppable: function(element, options, object) {
    element = $(element);

    options = Pandora.Utils.merge({
      singleton:      true,
      skipEmpty:      true,
      captureKeys:    false,
      autoIncludeCSS: '../stylesheets'
    }, options, object && object.croppable_options);

    var on_end_crop = options.onEndCrop;

    options.onEndCrop = function(coords, dimensions, croppable) {
      if (on_end_crop) {
        on_end_crop(coords, dimensions, croppable);
      }

      Pandora.Utils.toggle_clear_croppables(true);
    };

    return new Cropper.Img(element, options);
  },

  make_resizable: function(element, opts, options, object) {
    element = $(element);

    var handle, parent, container, intermediates;
    var handle_dim, element_dim, max_dim;
    var callback, fx, fy, set_dimensions;

    if (Object.isElement(opts)) {
      handle    = opts;
      opts      = {};
    }
    else {
      handle    = opts.handle;
      parent    = opts.parent;
      container = opts.container;
      callback  = opts.callback;
    }

    options = Pandora.Utils.merge({
      handle: handle,
      zindex: 10001,
      scroll: window,
      scrollSensitivity: 1
    }, options, object && object.resizable_options);

    var on_start = options.onStart;
    var on_end   = options.onEnd;
    var revert   = options.revert;
    var effect   = options.reverteffect;
    var snap     = options.snap;

    options.onStart = function(draggable, e) {
      handle_dim  = handle.getDimensions();
      element_dim = element.getDimensions();

      var resizables = [element];

      if (parent) {
        resizables.push(parent);

        intermediates = element.intermediateAncestors(parent);

        if (container) {
          var parent_offset = parent.positionedOffset();
          var container_dim = container.getDimensions();

          max_dim = {
            width:  container_dim.width  - parent_offset.left,
            height: container_dim.height - parent_offset.top
          };
        }
      }

      var slope = element_dim.height / element_dim.width;
      fx = function(x) { return slope * x; };
      fy = function(y) { return y / slope; };

      set_dimensions = function(x, y) {
        resizables.invoke('setDimensions', [
          x || element_dim.width,
          y || element_dim.height
        ]);
      };

      if (on_start) {
        on_start(draggable, e);
      }

      element.addClassName('resized');

      if (parent) {
        parent.addClassName('resizing');
      }

      if (max_dim) {
        intermediates.invoke('setDimensions', max_dim);
      }
    };

    options.onEnd = function(draggable, e) {
      if (on_end) {
        on_end(draggable, e);
      }

      if (e.keyCode === Event.KEY_ESC) {
        set_dimensions();

        if (max_dim) {
          intermediates.invoke('setDimensions', element_dim);
        }

        element.removeClassName('resized');
      }
      else {
        handle._dropped = true;

        if (intermediates) {
          intermediates.invoke('setDimensions', element);
        }

        if (callback) {
          var dim = element.getDimensions();
          callback(draggable, e, dim.width, dim.height);
        }
      }

      if (parent) {
        parent.removeClassName('resizing');
      }
    };

    if (Object.isUndefined(revert)) {
      options.revert = function() {
        return !handle._dropped;
      };
    }

    if (Object.isUndefined(effect)) {
      var handle_align = {};

      $w('top right bottom left').each(function(i) {
        handle_align[i] = handle.getStyle(i);
      });

      options.reverteffect = function() {
        handle.setStyle(handle_align);
      };
    }

    options.snap = function(x, y, draggable) {
      if (handle.offsetParent) {
        if (snap) {
          var res = snap(x, y, draggable, handle_dim, max_dim);
          x = res[0];
          y = res[1];
        }
        else if (opts.keep_ratio) {
          var y2 = fx(x);
          if (y2 > y) {
            y = y2;
          }
          else {
            x = fy(y);
          }

          x = Pandora.Utils.clip(x, handle_dim.width,  max_dim.width);
          y = fx(x);

          y = Pandora.Utils.clip(y, handle_dim.height, max_dim.height);
          x = fy(y);
        }
        else {
          x = Pandora.Utils.clip(x, handle_dim.width,  max_dim.width);
          y = Pandora.Utils.clip(y, handle_dim.height, max_dim.height);
        }

        set_dimensions(x, y);
      }
      else {
        var current_dim = element.getDimensions();
        x = current_dim.width;
        y = current_dim.height;
      }

      return [x - handle_dim.width, y - handle_dim.height];
    };

    return new Draggable(handle, options);
  },

  modal_box: function(element) {
    Pandora.ModalBox.show($(element).innerHTML);
  }

};

Pandora.StringMethods = {

  append_query: function(query) {
    if (Object.isString(query)) {
      query = encodeURI(query);
    }
    else {
      query = $H(query).toQueryString();
    }

    return this.append_query_string(query);
  },

  append_query_string: function(query_string) {
    if (!query_string.empty()) {
      return this + (this.include('?') ? '&' : '?') + query_string;
    }
    else {
      return this;
    }
  }

};

Element.addMethods(Pandora.ElementMethods);
Object.extend(String.prototype, Pandora.StringMethods);
