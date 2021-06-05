(function(){
  var svgns, layout;
  svgns = "http://www.w3.org/2000/svg";
  layout = function(opt){
    opt == null && (opt = {});
    this.root = typeof opt.root === 'string'
      ? document.querySelector(opt.root)
      : opt.root;
    this.opt = import$({
      autoSvg: true
    }, opt);
    this.evtHandler = {};
    this.box = {};
    this.node = {};
    this.group = {};
    return this;
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
        window.addEventListener('resize', function(){
          return this$.update();
        });
        if (!(this$.opt.autoSvg != null) || this$.opt.autoSvg) {
          svg = this$.root.querySelector('[data-type=render] > svg');
          if (!svg) {
            svg = document.createElementNS(svgns, "svg");
            svg.setAttribute('width', '100%');
            svg.setAttribute('height', '100%');
            this$.root.querySelector('[data-type=render]').appendChild(svg);
          }
          Array.from(this$.root.querySelectorAll('[data-type=layout] .pdl-cell[data-name]')).map(function(node, i){
            var name, g;
            name = node.getAttribute('data-name');
            this$.node[name] = node;
            if (node.hasAttribute('data-only')) {
              return;
            }
            g = this$.root.querySelector("g.pdl-cell[data-name=" + name + "]");
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
    update: function(opt){
      var this$ = this;
      if (!this.root) {
        return;
      }
      if (!(opt != null) || opt) {
        this.fire('update');
      }
      this.rbox = this.root.getBoundingClientRect();
      Array.from(this.root.querySelectorAll('[data-type=layout] .pdl-cell[data-name]')).map(function(node, i){
        var name, ref$, box, g;
        name = node.getAttribute('data-name');
        this$.node[name] = node;
        this$.box[name] = box = {
          x: (ref$ = node.getBoundingClientRect()).x,
          y: ref$.y,
          width: ref$.width,
          height: ref$.height
        };
        box.x -= this$.rbox.x;
        box.y -= this$.rbox.y;
        if (node.hasAttribute('data-only')) {
          return;
        }
        this$.group[name] = g = this$.root.querySelector("g.pdl-cell[data-name=" + name + "]");
        g.setAttribute('transform', "translate(" + box.x + "," + box.y + ")");
        return g.layout = {
          node: node,
          box: box
        };
      });
      if (!(opt != null) || opt) {
        return this.fire('render');
      }
    },
    getBox: function(it){
      var rbox, box;
      rbox = this.root.getBoundingClientRect();
      box = this.getNode(it).getBoundingClientRect();
      box.x -= rbox.x;
      box.y -= rbox.y;
      return box;
    },
    getNode: function(it){
      return this.node[it];
    },
    getGroup: function(it){
      return this.group[it];
    }
  });
  if (typeof window != 'undefined' && window !== null) {
    window.layout = layout;
  }
  if (typeof module != 'undefined' && module !== null) {
    module.exports = layout;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
