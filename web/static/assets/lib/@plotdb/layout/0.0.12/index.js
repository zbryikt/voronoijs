(function(){
  var svgns, layout, resizeObserver;
  svgns = "http://www.w3.org/2000/svg";
  layout = function(opt){
    opt == null && (opt = {});
    this._r = typeof opt.root === 'string'
      ? document.querySelector(opt.root)
      : opt.root;
    this.opt = import$({
      autoSvg: true,
      round: true
    }, opt);
    if (!(this.opt.watchResize != null)) {
      this.opt.watchResize = true;
    }
    this.evtHandler = {};
    this.box = {};
    this.node = {};
    this.group = {};
    return this;
  };
  resizeObserver = {
    wm: new WeakMap(),
    ro: new ResizeObserver(function(list){
      return list.map(function(n){
        var ret;
        ret = resizeObserver.wm.get(n.target);
        return ret.update();
      });
    }),
    add: function(node, obj){
      this.wm.set(node, obj);
      return this.ro.observe(node);
    },
    'delete': function(it){
      this.ro.unobserve(it);
      return this.wm['delete'](it);
    }
  };
  layout.prototype = import$(Object.create(Object.prototype), {
    on: function(n, cb){
      var ref$;
      return ((ref$ = this.evtHandler)[n] || (ref$[n] = [])).push(cb);
    },
    fire: function(n){
      var v, res$, i$, to$, ref$, len$, cb, results$ = [];
      res$ = [];
      for (i$ = 1, to$ = arguments.length; i$ < to$; ++i$) {
        res$.push(arguments[i$]);
      }
      v = res$;
      for (i$ = 0, len$ = (ref$ = this.evtHandler[n] || []).length; i$ < len$; ++i$) {
        cb = ref$[i$];
        results$.push(cb.apply(this, v));
      }
      return results$;
    },
    init: function(cb){
      var this$ = this;
      return Promise.resolve().then(function(){
        var svg, ret;
        if (this$.opt.watchResize) {
          resizeObserver.add(this$._r, this$);
        }
        if (!(this$.opt.autoSvg != null) || this$.opt.autoSvg) {
          svg = this$._r.querySelector('[data-type=render] > svg');
          if (!svg) {
            svg = document.createElementNS(svgns, "svg");
            svg.setAttribute('width', '100%');
            svg.setAttribute('height', '100%');
            this$._r.querySelector('[data-type=render]').appendChild(svg);
          }
          Array.from(this$._r.querySelectorAll('[data-type=layout] .pdl-cell[data-name]')).map(function(node, i){
            var name, g;
            name = node.getAttribute('data-name');
            this$.node[name] = node;
            if (node.hasAttribute('data-only')) {
              return;
            }
            g = this$._r.querySelector("g.pdl-cell[data-name=" + name + "]");
            if (!g) {
              g = document.createElementNS(svgns, "g");
              svg.appendChild(g);
              g.classList.add('pdl-cell');
              g.setAttribute('data-name', name);
            }
            return this$.group[name] = g;
          });
        }
        ret = cb.apply(this$);
        if (ret && typeof ret.then === 'function') {
          return ret.then(function(){
            return this$.update();
          });
        } else {
          return this$.update();
        }
      });
    },
    destroy: function(){
      return resizeObserver['delete'](this._r);
    },
    _rebox: function(b){
      var ret;
      if (!this.opt.round) {
        return b;
      }
      ret = {};
      ret.x = Math.round(b.x);
      ret.width = Math.round(b.x + b.width) - ret.x;
      ret.y = Math.round(b.y);
      ret.height = Math.round(b.y + b.height) - ret.y;
      return ret;
    },
    update: function(opt){
      var this$ = this;
      if (!this._r) {
        return;
      }
      if (!(opt != null) || opt) {
        this.fire('update');
      }
      this.rbox = this._rebox(this._r.getBoundingClientRect());
      Array.from(this._r.querySelectorAll('[data-type=layout] .pdl-cell[data-name]')).map(function(node, i){
        var name, box, g;
        name = node.getAttribute('data-name');
        this$.node[name] = node;
        this$.box[name] = box = this$._rebox(node.getBoundingClientRect());
        box.x -= this$.rbox.x;
        box.y -= this$.rbox.y;
        if (node.hasAttribute('data-only')) {
          return;
        }
        this$.group[name] = g = this$._r.querySelector("g.pdl-cell[data-name=" + name + "]");
        g.setAttribute('transform', "translate(" + Math.round(box.x) + "," + Math.round(box.y) + ")");
        return g.layout = {
          node: node,
          box: box
        };
      });
      if (!(opt != null) || opt) {
        return this.fire('render');
      }
    },
    root: function(){
      return this._r;
    },
    getBox: function(n, cached){
      var rbox, box;
      cached == null && (cached = false);
      if (cached) {
        return this.box[n];
      }
      rbox = this._rebox(this._r.getBoundingClientRect());
      box = this._rebox(this.getNode(n).getBoundingClientRect());
      box.x -= rbox.x;
      box.y -= rbox.y;
      return box;
    },
    getNode: function(it){
      return this.node[it];
    },
    getGroup: function(it){
      return this.group[it];
    },
    getNodes: function(){
      return import$({}, this.node);
    },
    getGroups: function(){
      return import$({}, this.group);
    }
  });
  if (typeof module != 'undefined' && module !== null) {
    module.exports = layout;
  } else if (typeof window != 'undefined' && window !== null) {
    window.layout = layout;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
