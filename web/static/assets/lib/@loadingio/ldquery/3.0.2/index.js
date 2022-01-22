(function(){
  var ajaxErr, ld$obj, ld$, k, ref$, v, ns, xhrpar, fetch;
  if (!(typeof ld$ != 'undefined' && ld$ !== null)) {
    ajaxErr = function(s, d, j){
      var ref$;
      return ref$ = new Error(s + " " + d), ref$.data = d, ref$.json = j, ref$.id = s, ref$.code = s, ref$.name = 'lderror', ref$.message = d, ref$;
    };
    ld$obj = function(dom){
      return import$(dom, ld$obj.prototype);
    };
    ld$ = function(it){
      return new ld$obj(it);
    };
    ld$obj.prototype = {
      find: function(s, n){
        var r, ref$, ret, e;
        if (!(r = this).querySelector) {
          ref$ = [document, r.toString(), s], r = ref$[0], s = ref$[1], n = ref$[2];
        }
        if (s instanceof HTMLElement) {
          return s;
        }
        try {
          if (n === 0) {
            return r.querySelector(s);
          }
          ret = Array.from(r.querySelectorAll(s));
          if (n) {
            return ret[n];
          } else {
            return ret;
          }
        } catch (e$) {
          e = e$;
          console.warn("ld$.find exception: " + s + " / " + n + " under ", r);
          throw e;
        }
      },
      index: function(){
        return Array.from(this.parentNode.childNodes).indexOf(this);
      },
      child: function(){
        return Array.from(this.childNodes);
      },
      parent: function(s, e){
        var n;
        e == null && (e = null);
        n = this;
        while (n && n !== e) {
          n = n.parentNode;
        }
        if (n !== e) {
          return null;
        }
        if (!s) {
          return this;
        }
        n = this;
        while (n && n !== e && (!n.matches || (n.matches && !n.matches(s)))) {
          n = n.parentNode;
        }
        if (n === e && (!e || !e.matches || !e.matches(s))) {
          return null;
        }
        return n;
      },
      cls: function(o, p, n){
        var k, v, i$, ref$, len$, ref1$, l, results$ = [], results1$ = [], this$ = this;
        if (typeof o === 'object') {
          for (k in o) {
            v = o[k];
            results$.push(this.classList[v ? 'add' : 'remove'](k));
          }
          return results$;
        } else {
          for (i$ = 0, len$ = (ref$ = [[p, !!o], [n, !o]]).length; i$ < len$; ++i$) {
            ref1$ = ref$[i$], l = ref1$[0], v = ref1$[1];
            results1$.push((Array.isArray(l)
              ? l
              : [l]).map(fn$));
          }
          return results1$;
        }
        function fn$(it){
          return this$.classList.toggle(it, v);
        }
      },
      attr: function(n, v){
        var k, results$ = [];
        if (typeof n === 'object') {
          for (k in n) {
            v = n[k];
            results$.push(this.setAttribute(k, v));
          }
          return results$;
        } else if (v == null) {
          return this.getAttribute(n);
        } else {
          return this.setAttribute(n, v);
        }
      },
      on: function(n, cb){
        return this.addEventListener(n, cb);
      },
      remove: function(){
        if (this.parentNode) {
          return this.parentNode.removeChild(this);
        }
      },
      insertAfter: function(n, s){
        return this.insertBefore(n, s.nextSibling);
      }
    };
    for (k in ref$ = ld$obj.prototype) {
      v = ref$[k];
      fn$(k, v);
    }
    ns = {
      svg: "http://www.w3.org/2000/svg"
    };
    xhrpar = function(u, o, p){
      var c, that, k, v;
      c = import$({}, o);
      if (p.json) {
        c.body = JSON.stringify(p.json);
        (c.headers || (c.headers = {}))['Content-Type'] = 'application/json; charset=UTF-8';
      }
      if (that = p.params) {
        u = u + ("?" + (function(){
          var ref$, results$ = [];
          for (k in ref$ = that) {
            v = ref$[k];
            results$.push(k + "=" + encodeURIComponent(v));
          }
          return results$;
        }()).join('&'));
      }
      if (ld$.fetch.headers && !p.noDefaultHeaders) {
        import$(c.headers || (c.headers = {}), ld$.fetch.headers);
      }
      return {
        c: c,
        u: u
      };
    };
    import$(ld$, {
      json: function(v){
        var e;
        try {
          return JSON.parse(v);
        } catch (e$) {
          e = e$;
          return v;
        }
      },
      fetch: function(url, o, opt){
        o == null && (o = {});
        opt == null && (opt = {});
        return new Promise(function(res, rej){
          var ref$, u, c, h;
          ref$ = xhrpar(url, o, opt), u = ref$.u, c = ref$.c;
          h = setTimeout(function(){
            rej(ajaxErr(1006, "timeout"));
            return h = null;
          }, opt.timeout || 20 * 1000);
          return fetch(u, c).then(function(v){
            if (!h) {
              return;
            }
            clearTimeout(h);
            if (!(v && v.ok)) {
              return v.clone().text().then(function(t){
                var json, e;
                try {
                  json = JSON.parse(t);
                  if (json && json.name === 'lderror') {
                    return rej(import$(ajaxErr(v.status, t), json));
                  }
                } catch (e$) {
                  e = e$;
                  json = null;
                }
                return rej(ajaxErr(v.status, t, json));
              });
            } else {
              return res(opt.type != null ? v[opt.type]() : v);
            }
          })['catch'](function(e){
            clearTimeout(h);
            return rej(e);
          });
        });
      },
      create: function(o){
        var n, k, v;
        n = o.ns
          ? document.createElementNS(ns[o.ns] || o.ns, o.name)
          : document.createElement(o.name);
        if (o.style) {
          import$(n.style, o.style);
        }
        if (o.attr) {
          (function(){
            var ref$, results$ = [];
            for (k in ref$ = o.attr) {
              v = ref$[k];
              results$.push([k, v]);
            }
            return results$;
          }()).map(function(p){
            return n.setAttribute(p[0], p[1]);
          });
        }
        if (o.className) {
          n.classList.add.apply(n.classList, o.className);
        }
        if (o.text) {
          n.appendChild(document.createTextNode(o.text));
        }
        if (o.html) {
          n.innerHTML = o.html;
        }
        return n;
      }
    });
    ld$.xhr = function(url, o, opt){
      o == null && (o = {});
      opt == null && (opt = {});
      return new Promise(function(res, rej){
        var ref$, u, c, x, p, k, v;
        ref$ = xhrpar(url, o, opt), u = ref$.u, c = ref$.c;
        x = new XMLHttpRequest();
        x.onreadystatechange = function(){
          var ret, e;
          if (x.readyState === XMLHttpRequest.DONE) {
            if (x.status === 200) {
              try {
                ret = opt.type === 'json'
                  ? JSON.parse(x.responseText)
                  : x.responseText;
              } catch (e$) {
                e = e$;
                return rej(ajaxErr(x.status, x.responseText));
              }
              return res(ret);
            } else {
              return rej(ajaxErr(x.status, x.responseText));
            }
          }
        };
        x.onloadstart = function(){
          return opt.progress({
            percent: 0,
            val: 0,
            len: 0
          });
        };
        if (opt.progress) {
          p = function(evt){
            var ref$, val, len;
            ref$ = [evt.loaded, evt.total], val = ref$[0], len = ref$[1];
            return opt.progress({
              percent: val / len,
              val: val,
              len: len
            });
          };
          if (x.upload) {
            x.upload.onprogress = p;
          } else {
            x.onprogress = p;
          }
        }
        x.open(c.method || 'GET', u, true);
        for (k in ref$ = c.headers || {}) {
          v = ref$[k];
          x.setRequestHeader(k, v);
        }
        return x.send(c.body);
      });
    };
    ld$.fetch.headers = {};
    if (typeof window != 'undefined' && window !== null) {
      window.ld$ = ld$;
      fetch = window.fetch;
    }
    if (typeof module != 'undefined' && module !== null) {
      if (fetch == null) {
        fetch = require("node-fetch");
      }
      module.exports = ld$;
    }
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
  function fn$(k, v){
    return ld$[k] = function(z){
      var args, res$, i$, to$;
      res$ = [];
      for (i$ = 1, to$ = arguments.length; i$ < to$; ++i$) {
        res$.push(arguments[i$]);
      }
      args = res$;
      return v.apply(z, args);
    };
  }
}).call(this);
