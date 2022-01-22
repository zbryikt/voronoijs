(function(){
  var Voronoi, Aux, Polygon;
  Voronoi = {};
  Voronoi.Treemap = function(root, omega, width, height, lv){
    var res$, i$, ref$, len$, child, i;
    lv == null && (lv = 0);
    this.root = root;
    this.omega = omega;
    this.width = width;
    this.height = height;
    this.lv = lv;
    res$ = [];
    for (i$ = 0, len$ = (ref$ = root.children).length; i$ < len$; ++i$) {
      child = ref$[i$];
      res$.push((child.x = Math.random() * width, child.y = Math.random() * height, child.lv = lv, child));
    }
    this.sites = res$;
    if (lv === 0) {
      this.normalizeValue(root, Polygon.area(omega), this.correctValue(root));
    }
    this.boundmap = new Voronoi.Boundmap(this.sites, omega, width, height, true);
    this.boundmap.compute();
    this.treemap = [];
    for (i$ = 0, len$ = (ref$ = root.children).length; i$ < len$; ++i$) {
      i = i$;
      child = ref$[i$];
      if (child.children) {
        this.treemap.push(new Voronoi.Treemap(child, this.boundmap.polygons[i], width, height, lv + 1));
      }
    }
    return this;
  };
  Voronoi.Treemap.prototype = {
    updateValue: function(){
      var i$, ref$, len$, t;
      this.normalizeValue(this.root, Polygon.area(this.omega), this.correctValue(this.root));
      this.boundmap = new Voronoi.Boundmap(this.sites, this.omega, this.width, this.height, true);
      for (i$ = 0, len$ = (ref$ = this.treemap).length; i$ < len$; ++i$) {
        t = ref$[i$];
        t.updateValue();
      }
      return this.compute();
    },
    correctValue: function(d){
      var i$, ref$, len$, item;
      if (!(d != null)) {
        d = this.sites;
      }
      for (i$ = 0, len$ = (ref$ = d.children || []).length; i$ < len$; ++i$) {
        item = ref$[i$];
      }
      return d.value = (function(){
        var i$, ref$, len$, results$ = [];
        for (i$ = 0, len$ = (ref$ = d.children || []).length; i$ < len$; ++i$) {
          item = ref$[i$];
          results$.push(this.correctValue(item || null));
        }
        return results$;
      }.call(this)).reduce(function(a, b){
        return a + b;
      }, 0) || d.value || 0;
    },
    normalizeValue: function(d, area, value){
      var i$, ref$, len$, item, results$ = [];
      d.value = 0.05 * d.value * area / value;
      for (i$ = 0, len$ = (ref$ = d.children || []).length; i$ < len$; ++i$) {
        item = ref$[i$];
        results$.push(this.normalizeValue(item, area, value));
      }
      return results$;
    },
    compute: function(){
      var this$ = this;
      this.boundmap.compute();
      return this.treemap.forEach(function(d, i){
        d.setOmega(this$.boundmap.polygons[i]);
        return d.compute();
      });
    },
    getSites: function(){
      var i;
      return ([this.boundmap.sites].concat([(function(){
        var i$, results$ = [];
        for (i$ = 0; i$ < 4; ++i$) {
          i = i$;
          results$.push({
            boundary: true
          });
        }
        return results$;
      }())], this.treemap.map(function(it){
        return it.getSites();
      }))).reduce(function(a, b){
        return a.concat(b);
      }, []);
    },
    getPolygons: function(){
      return ([this.boundmap.polygons].concat(this.treemap.map(function(it){
        return it.getPolygons();
      }))).reduce(function(a, b){
        return a.concat(b);
      }, []);
    },
    setOmega: function(omega){
      this.omega = omega;
      return this.boundmap = new Voronoi.Boundmap(this.sites, omega, this.width, this.height);
    }
  };
  Voronoi.Boundmap = function(sites, omega, width, height, normalized){
    var valueSum, areaSum;
    this.sites = sites;
    this.omega = omega;
    this.width = width;
    this.height = height;
    if (!(normalized != null)) {
      valueSum = sites.reduce(function(a, b){
        return a + b.value;
      }, 0);
      areaSum = Polygon.area(omega);
      sites.forEach(function(it){
        return it.nvalue = 0.1 * it.value * areaSum / valueSum;
      });
    } else {
      sites.forEach(function(it){
        return it.nvalue = it.value;
      });
    }
    sites.forEach(function(it){
      return it.nvalue = it.value;
    });
    this.powerbox = new Voronoi.PowerDiagram(sites, width, height);
    this.powerbox.compute();
    this.clip();
    return this;
  };
  Voronoi.randomSite = function(count, width, height, weight){
    var i;
    return (function(){
      var i$, to$, results$ = [];
      for (i$ = 0, to$ = count; i$ < to$; ++i$) {
        i = i$;
        results$.push({
          x: width * Math.random(),
          y: height * Math.random(),
          value: 1 + Math.random() * weight
        });
      }
      return results$;
    }()).map(function(it){
      return it.weight = it.value, it;
    });
  };
  Voronoi.Boundmap.prototype = {
    clip: function(){
      var this$ = this;
      this.polygons = this.powerbox.convex.polygons.map(function(it){
        if (it) {
          return Voronoi.Polygon.intersect(this$.omega, it);
        } else {
          return [];
        }
      });
      return this.centroids = this.polygons.map(function(it){
        if (it) {
          return Voronoi.Polygon.centroid(it);
        } else {
          return {
            x: null,
            y: null
          };
        }
      });
    },
    adoptPos: function(){
      var ref$, sites, centroids, polygons, i$, to$, i, weight, min, j$, to1$, j, p, q, distance, results$ = [];
      ref$ = {
        sites: this.sites,
        centroids: this.centroids,
        polygons: this.polygons
      }, sites = ref$.sites, centroids = ref$.centroids, polygons = ref$.polygons;
      for (i$ = 0, to$ = centroids.length - 4; i$ < to$; ++i$) {
        i = i$;
        if (!sites[i] || !polygons[i] || sites[i].boundary) {
          continue;
        }
        if (!polygons[i].length) {
          ref$ = [this.width * Math.random(), this.height * Math.random()], sites[i].x = ref$[0], sites[i].y = ref$[1];
        } else {
          ref$ = [centroids[i].x, centroids[i].y], sites[i].x = ref$[0], sites[i].y = ref$[1];
        }
      }
      for (i$ = 0, to$ = centroids.length - 4; i$ < to$; ++i$) {
        i = i$;
        if (!sites[i] || !polygons[i].length || sites[i].boundary) {
          continue;
        }
        ref$ = [Math.sqrt(sites[i].weight), -1], weight = ref$[0], min = ref$[1];
        for (j$ = 0, to1$ = polygons[i].length; j$ < to1$; ++j$) {
          j = j$;
          ref$ = [polygons[i][j], polygons[i][(j + 1) % polygons[i].length]], p = ref$[0], q = ref$[1];
          distance = Math.abs(((q.y - p.y) * sites[i].x - (q.x - p.x) * sites[i].y + q.x * p.y - q.y * p.x) / Math.sqrt(Math.pow(q.y - p.y, 2) + Math.pow(q.x - p.x, 2))) * 10;
          if (min === -1 || min > distance) {
            min = distance;
          }
        }
        weight = Math.pow(Math.min(weight, min), 2);
        results$.push(sites[i].weight = weight);
      }
      return results$;
    },
    resetWeight: function(){
      return this.sites.forEach(function(d, i){
        return d.weight = d.pvalue = d.nvalue;
      });
    },
    adoptWeight: function(){
      var ref$, sites, centroids, polygons, valuesum, areasum, i$, to$, i, targetArea, currentArea, weight, newWeight, min, j$, to1$, j, d, results$ = [];
      ref$ = {
        sites: this.sites,
        centroids: this.centroids,
        polygons: this.polygons
      }, sites = ref$.sites, centroids = ref$.centroids, polygons = ref$.polygons;
      valuesum = 0;
      sites.forEach(function(s){
        valuesum = valuesum + s.nvalue;
        if (s.pvalue !== s.nvalue) {
          s.weight = s.nvalue;
        }
        return s.pvalue = s.nvalue;
      });
      areasum = Voronoi.Polygon.area(this.omega);
      for (i$ = 0, to$ = centroids.length - 4; i$ < to$; ++i$) {
        i = i$;
        if (!sites[i] || !polygons[i].length || sites[i].boundary) {
          continue;
        }
        targetArea = areasum * sites[i].nvalue / valuesum;
        currentArea = Polygon.area(polygons[i]);
        weight = Math.sqrt(sites[i].weight);
        newWeight = Math.sqrt(sites[i].weight) * targetArea / currentArea;
        weight = 0.5 * (newWeight - weight) + weight;
        min = -1;
        for (j$ = 0, to1$ = centroids.length - 4; j$ < to1$; ++j$) {
          j = j$;
          if (i === j || !this.polygons[j]) {
            continue;
          }
          d = Math.sqrt(Math.pow(centroids[j].x - sites[i].x, 2) + Math.pow(centroids[j].y - sites[i].y, 2));
          if (isNaN(d)) {
            continue;
          }
          if (min === -1 || min > d) {
            min = d;
          }
        }
        weight = Math.pow(Math.min(weight, min), 2);
        if (weight < this.powerbox.epsilon) {
          weight = this.powerbox.epsilon;
        }
        results$.push(sites[i].weight = weight);
      }
      return results$;
    },
    compute: function(){
      this.adoptPos();
      this.powerbox = new Voronoi.PowerDiagram(this.sites, this.width, this.height);
      this.powerbox.compute();
      this.clip();
      this.adoptWeight();
      this.powerbox = new Voronoi.PowerDiagram(this.sites, this.width, this.height);
      this.powerbox.compute();
      return this.clip();
    }
  };
  Voronoi.PowerDiagram = function(sites, width, height){
    var this$ = this;
    this.sites = sites;
    this.width = width;
    this.height = height;
    this.boundary = [
      {
        x: -width,
        y: -height,
        boundary: true
      }, {
        x: -width,
        y: 2 * height,
        boundary: true
      }, {
        x: 2 * width,
        y: -height,
        boundary: true
      }, {
        x: 2 * width,
        y: 2 * height,
        boundary: true
      }
    ].map(function(it){
      return it.boundary = true, it.weight = this$.epsilon, it.value = this$.epsilon, it;
    });
    this.convex = new Voronoi.Convex(JSON.parse(JSON.stringify(sites.concat(this.boundary))));
    return this;
  };
  Voronoi.PowerDiagram.prototype = {
    epsilon: 0.0000000001,
    compute: function(){
      return this.convex.calculate();
    }
  };
  Aux = {
    inner: function(p1, p2){
      return p1.x * p2.x + p1.y * p2.y + p1.z * p2.z;
    },
    sub: function(p1, p2){
      return {
        x: p1.x - p2.x,
        y: p1.y - p2.y,
        z: p1.z - p2.z
      };
    },
    cross: function(v1, v2){
      return {
        x: v1.y * v2.z - v1.z * v2.y,
        y: v1.z * v2.x - v1.x * v2.z,
        z: v1.x * v2.y - v1.y * v2.x
      };
    }
  };
  Voronoi.Convex = function(pts){
    var ref$, initset, faces, res$, i$, len$, idx, this$ = this;
    this.pts = pts;
    this.polygons = [];
    this.edges = {};
    this.pts.forEach(function(it){
      return it.z = Math.pow(it.x, 2) + Math.pow(it.y, 2) - it.weight;
    });
    this.pair = {
      f2p: {},
      p2f: {}
    };
    this.faces.list = [];
    if (this.pts.length < 4) {
      return;
    }
    ref$ = [[0, 1, 2, 3], 3], initset = ref$[0], this.idx = ref$[1];
    while (this.idx < this.pts.length) {
      this.idx++;
      this.center = {};
      ['x', 'y', 'z'].map(fn$);
      res$ = [];
      for (i$ = 0, len$ = (ref$ = [[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]].map(fn1$)).length; i$ < len$; ++i$) {
        idx = ref$[i$];
        res$.push(new Voronoi.face(this, idx));
      }
      faces = res$;
      if (!faces.filter(fn2$).length) {
        break;
      }
      idx = initset.map(fn3$).sort(fn4$)[0][1];
      initset.splice(initset.indexOf(idx), 1);
      initset.push(this.idx);
    }
    this.faces.add(faces);
    faces.forEach(function(f, i){
      return this$.pts.forEach(function(p, j){
        if (f.front(p)) {
          return this$.setPair(i, j, f, p);
        }
      });
    });
    return this;
    function fn$(idx){
      return this$.center[idx] = [0, 1, 2, 3].reduce(function(a, b){
        return a + this$.pts[initset[b]][idx];
      }, 0) / 4;
    }
    function fn1$(it){
      return it.map(function(jt){
        return initset[jt];
      });
    }
    function fn2$(it){
      return it.trivial;
    }
    function fn3$(it, i){
      var vector;
      vector = Aux.sub(this$.center, this$.pts[it]);
      ['x', 'y', 'z'].reduce(function(a, b){
        return a + Math.pow(vector[b], 2);
      }, 0);
      return [vector, i];
    }
    function fn4$(a, b){
      return a[0] - b[0];
    }
  };
  import$(Voronoi.Convex.prototype, {
    getPairByPtr: function(idx){
      return this.pair.p2f[idx] || [];
    },
    getPairByFace: function(idx){
      return this.pair.f2p[idx] || [];
    },
    setPair: function(fi, pi, f, p){
      var ref$, ref1$;
      ((ref$ = (ref1$ = this.pair).f2p || (ref1$.f2p = {}))[fi] || (ref$[fi] = [])).push(p);
      return ((ref$ = (ref1$ = this.pair).p2f || (ref1$.p2f = {}))[pi] || (ref$[pi] = [])).push(f);
    },
    faces: {
      contain: function(it){
        return in$(it, this.list);
      },
      add: function(it){
        if (Array.isArray(it)) {
          return this.list = this.list.concat(it);
        } else {
          return this.list.push(it);
        }
      },
      remove: function(faces){
        var this$ = this;
        if (!Array.isArray(faces)) {
          faces = [faces];
        }
        return faces.forEach(function(f){
          var idx;
          idx = this$.list.indexOf(f);
          if (idx >= 0) {
            return this$.list.splice(idx, 1);
          }
        });
      }
    },
    polygonReorder: function(ps){
      var cx, cy, clen, angle;
      cx = ps.reduce(function(a, b){
        return a + b.x;
      }, 0) / ps.length;
      cy = ps.reduce(function(a, b){
        return a + b.y;
      }, 0) / ps.length;
      clen = Math.pow(cx, 2) + Math.pow(cy, 2);
      angle = function(p){
        var len, a, b;
        len = Math.sqrt(clen * (Math.pow(p.x - cx, 2) + Math.pow(p.y - cy, 2)));
        a = Math.acos((-cx * (p.x - cx) - cy * (p.y - cy)) / len);
        b = Math.acos((cy * (p.x - cx) - cx * (p.y - cy)) / len);
        if (b > Math.PI / 2) {
          a = 6.28 - a;
        }
        return a;
      };
      return ps.sort(function(a, b){
        return angle(a) - angle(b);
      });
    },
    grid: function(){
      var res$, i$, to$, i, ref$, len$, p, visited, face, lresult$, j$, ref1$, len1$, polygon, k$, ref2$, len2$, f, results$ = [];
      this.faces.list.forEach(function(it){
        return it.center = it.getCenter(), it;
      });
      this.faces.list = this.faces.list.filter(function(it){
        return !it.removed && it.front(it.center);
      });
      res$ = [];
      for (i$ = 0, to$ = this.pts.length; i$ < to$; ++i$) {
        i = i$;
        res$.push([]);
      }
      this.polygons = res$;
      for (i$ = 0, len$ = (ref$ = this.pts).length; i$ < len$; ++i$) {
        p = ref$[i$];
        p.visited = false;
      }
      visited = [];
      for (i$ = 0, len$ = (ref$ = this.faces.list).length; i$ < len$; ++i$) {
        face = ref$[i$];
        lresult$ = [];
        for (j$ = 0, len1$ = (ref1$ = face.idx).length; j$ < len1$; ++j$) {
          p = ref1$[j$];
          if (in$(p, visited)) {
            continue;
          }
          visited.push(p);
          polygon = [];
          polygon.idx = p;
          for (k$ = 0, len2$ = (ref2$ = this.faces.list).length; k$ < len2$; ++k$) {
            i = k$;
            f = ref2$[k$];
            if (in$(p, f.idx)) {
              polygon.push(f.dual());
            }
          }
          this.polygonReorder(polygon);
          polygon.cx = polygon.reduce(fn$, 0) / polygon.length;
          polygon.cy = polygon.reduce(fn1$, 0) / polygon.length;
          if (this.pts[p].boundary) {
            polygon.boundary = true;
          }
          lresult$.push(this.polygons[p] = polygon);
        }
        results$.push(lresult$);
      }
      return results$;
      function fn$(a, b){
        return a + b.x;
      }
      function fn1$(a, b){
        return a + b.y;
      }
    },
    calculate: function(){
      while (this.idx < this.pts.length) {
        this.iterate();
      }
      return this.grid();
    },
    iterate: function(){
      var t1, faces, edges, i$, len$, f, j$, ref$, len1$, edge, horizon, t2, newfaces, pts, pair, idx, flen, plen, nlen, t3, t4, that;
      t1 = new Date().getTime();
      if (this.idx >= this.pts.length) {
        return;
      }
      faces = this.getPairByPtr(this.idx);
      edges = [];
      for (i$ = 0, len$ = faces.length; i$ < len$; ++i$) {
        f = faces[i$];
        if (f.removed) {
          continue;
        }
        for (j$ = 0, len1$ = (ref$ = f.edges).length; j$ < len1$; ++j$) {
          edge = ref$[j$];
          if (!edge.ref) {
            edges.push(edge);
          } else {
            edge.dup = true;
          }
          edge.ref++;
        }
      }
      horizon = edges.filter(function(it){
        return it.ref < 2;
      });
      faces.map(function(it){
        return it.removed = true;
      });
      t2 = new Date().getTime();
      this.faces.add(newfaces = (function(){
        var i$, ref$, len$, results$ = [];
        for (i$ = 0, len$ = (ref$ = horizon).length; i$ < len$; ++i$) {
          edge = ref$[i$];
          results$.push(new Voronoi.face(this, edge.concat([this.idx]), true));
        }
        return results$;
      }.call(this)));
      ref$ = [this.pts, this.pair, this.idx, this.faces.list.length, this.pts.length, newfaces.length], pts = ref$[0], pair = ref$[1], idx = ref$[2], flen = ref$[3], plen = ref$[4], nlen = ref$[5];
      t3 = new Date().getTime();
      newfaces.forEach(function(f, i){
        var ref$, n, precal, i$, to$, j, p, results$ = [];
        i += flen - nlen;
        ref$ = [f.norm, f.precal], n = ref$[0], precal = ref$[1];
        for (i$ = idx + 1, to$ = plen; i$ < to$; ++i$) {
          j = i$;
          p = pts[j];
          if (n.x * p.x + n.y * p.y + n.z * p.z - precal > 0) {
            ((ref$ = pair.f2p)[i] || (ref$[i] = [])).push(p);
            results$.push(((ref$ = pair.p2f)[j] || (ref$[j] = [])).push(f));
          }
        }
        return results$;
      });
      this.idx++;
      t4 = new Date().getTime();
      this.e1 = ((that = this.e1) != null ? that : 0) + (t2 - t1);
      this.e2 = ((that = this.e2) != null ? that : 0) + (t3 - t2);
      return this.e3 = ((that = this.e3) != null ? that : 0) + (t4 - t3);
    }
  });
  Voronoi.face = function(convex, idx, active){
    var ref$, p0, p1, p2, c, x1, y1, z1, x2, y2, z2, n, len, ip, res$, i$, i, j, p, q, that, ref1$;
    active == null && (active = false);
    this.convex = convex;
    this.idx = idx;
    this.active = active;
    this.removed = false;
    this.pts = (ref$ = [convex.pts[idx[0]], convex.pts[idx[1]], convex.pts[idx[2]]], p0 = ref$[0], p1 = ref$[1], p2 = ref$[2], ref$);
    c = convex.center;
    ref$ = [p2.x - p0.x, p2.y - p0.y, p2.z - p0.z], x1 = ref$[0], y1 = ref$[1], z1 = ref$[2];
    ref$ = [p1.x - p0.x, p1.y - p0.y, p1.z - p0.z], x2 = ref$[0], y2 = ref$[1], z2 = ref$[2];
    this.norm = n = {
      x: y1 * z2 - z1 * y2,
      y: z1 * x2 - x1 * z2,
      z: x1 * y2 - y1 * x2
    };
    len = Math.pow(n.x, 2) + Math.pow(n.y, 2) + Math.pow(n.z, 2);
    this.norm = n = {
      x: n.x / len,
      y: n.y / len,
      z: n.z / len
    };
    ip = n.x * (c.x - p0.x) + n.y * (c.y - p0.y) + n.z * (c.z - p0.z);
    if (ip > 0) {
      ref$ = [-n.x, -n.y, -n.z], n.x = ref$[0], n.y = ref$[1], n.z = ref$[2];
      this.pts.reverse();
      idx.reverse();
    } else if (ip === 0) {
      this.trivial = true;
    }
    res$ = [];
    for (i$ = 0; i$ < 3; ++i$) {
      i = i$;
      j = (i + 1) % 3;
      ref$ = idx[i] > idx[j]
        ? [idx[j], idx[i]]
        : [idx[i], idx[j]], p = ref$[0], q = ref$[1];
      res$.push((ref$ = (that = ((ref1$ = convex.edges)[p] || (ref1$[p] = {}))[q])
        ? that
        : ((ref1$ = convex.edges)[p] || (ref1$[p] = {}))[q] = [p, q], ref$.ref = 0, ref$));
    }
    this.edges = res$;
    this.precal = n.x * p0.x + n.y * p0.y + n.z * p0.z;
    return this;
  };
  import$(Voronoi.face.prototype, {
    front: function(p){
      var n;
      n = this.norm;
      return n.x * p.x + n.y * p.y + n.z * p.z - this.precal > 0;
    },
    getCenter: function(){
      var ref$, ret, len;
      ref$ = [
        {
          x: 0,
          y: 0
        }, this.pts.length
      ], ret = ref$[0], len = ref$[1];
      this.pts.forEach(function(it){
        var ref$;
        return ref$ = [ret.x + it.x, ret.y + it.y], ret.x = ref$[0], ret.y = ref$[1], ref$;
      });
      return ret.x = ret.x / len, ret.y = ret.y / len, ret.z = -100, ret;
    },
    dual: function(){
      var ref$, x1, y1, z1, x2, y2, z2, x3, y3, z3, A, B, C, D, x, y, z;
      if (this.dual.value) {
        this.dual.value;
      }
      ref$ = this.pts[0], x1 = ref$.x, y1 = ref$.y, z1 = ref$.z;
      ref$ = this.pts[1], x2 = ref$.x, y2 = ref$.y, z2 = ref$.z;
      ref$ = this.pts[2], x3 = ref$.x, y3 = ref$.y, z3 = ref$.z;
      A = y1 * (z2 - z3) + y2 * (z3 - z1) + y3 * (z1 - z2);
      B = z1 * (x2 - x3) + z2 * (x3 - x1) + z3 * (x1 - x2);
      C = x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2);
      D = x1 * (y2 * z3 - y3 * z2) + x2 * (y3 * z1 - y1 * z3) + x3 * (y1 * z2 - y2 * z1);
      x = 0.5 * -A / C;
      y = 0.5 * -B / C;
      z = -D / C;
      this.dual.value = {
        x: x,
        y: y,
        z: z
      };
      return this.dual.value;
    }
  });
  Voronoi.Polygon = Polygon = {};
  Polygon.centroid = function(p){
    var len, ref$, cx, cy, a, i$, i, u, v;
    if (!p || !p.length) {
      return {
        x: NaN,
        y: NaN
      };
    }
    len = p.length;
    ref$ = [0, 0, 0], cx = ref$[0], cy = ref$[1], a = ref$[2];
    for (i$ = 0; i$ < len; ++i$) {
      i = i$;
      ref$ = [p[i], p[(i + 1) % len]], u = ref$[0], v = ref$[1];
      cx += (u.x + v.x) * (u.x * v.y - v.x * u.y);
      cy += (u.y + v.y) * (u.x * v.y - v.x * u.y);
      a += (u.x * v.y - v.x * u.y) * 3;
    }
    return {
      x: cx / a,
      y: cy / a
    };
  };
  Polygon.area = function(p){
    var i, j, pi, pj;
    return (function(){
      var i$, to$, ref$, results$ = [];
      for (i$ = 0, to$ = p.length; i$ < to$; ++i$) {
        i = i$;
        j = (i + 1) % p.length;
        ref$ = [p[i], p[j]], pi = ref$[0], pj = ref$[1];
        results$.push(pi.x * pj.y - pi.y * pj.x);
      }
      return results$;
    }()).reduce(function(a, b){
      return a + b / 2;
    }, 0);
  };
  Polygon.intersect = function(ply1, ply2){
    var cx1, cy1, i$, to$, i, ref$, Q, QN, Vx, Vy, cx2, cy2, precal, ts, res$, j$, to1$, j, P, PN, Ux, Uy, t, tx, ty, x2, y2, inner, start, end, newPolygon, idx;
    if (!ply1 || !ply1.length) {
      return [];
    }
    cx1 = ply1.reduce(function(a, b){
      return a + b.x;
    }, 0) / ply1.length;
    cy1 = ply1.reduce(function(a, b){
      return a + b.y;
    }, 0) / ply1.length;
    for (i$ = 0, to$ = ply1.length; i$ < to$; ++i$) {
      i = i$;
      ref$ = [ply1[i], ply1[(i + 1) % ply1.length]], Q = ref$[0], QN = ref$[1];
      ref$ = [QN.x - Q.x, QN.y - Q.y], Vx = ref$[0], Vy = ref$[1];
      cx2 = ply2.reduce(fn$, 0) / ply2.length;
      cy2 = ply2.reduce(fn1$, 0) / ply2.length;
      precal = Q.x * Vy - Q.y * Vx;
      res$ = [];
      for (j$ = 0, to1$ = ply2.length; j$ < to1$; ++j$) {
        j = j$;
        ref$ = [ply2[j], ply2[(j + 1) % ply2.length]], P = ref$[0], PN = ref$[1];
        ref$ = [PN.x - P.x, PN.y - P.y], Ux = ref$[0], Uy = ref$[1];
        if (Uy * Vx - Ux * Vy === 0) {
          continue;
        } else {
          t = (P.x * Vy - P.y * Vx - precal) / (Uy * Vx - Ux * Vy);
          if (t < 0 || t > 1) {
            continue;
          }
          ref$ = [P.x + Ux * t, P.y + Uy * t], tx = ref$[0], ty = ref$[1];
          ref$ = [cx2 - tx, cy2 - ty], x2 = ref$[0], y2 = ref$[1];
          inner = (-Vx * Uy + Vy * Ux) * (-x2 * Uy + y2 * Ux) > 0;
          res$.push([t, j, tx, ty, inner]);
        }
      }
      ts = res$;
      if (ts.length < 2) {
        if ((-(cx1 - Q.x) * Vy + (cy1 - Q.y) * Vx) * (-(cx2 - Q.x) * Vy + (cy2 - Q.y) * Vx) < 0) {
          return [];
        }
        continue;
      }
      ref$ = ts[0][4]
        ? [ts[0], ts[1]]
        : [ts[1], ts[0]], start = ref$[0], end = ref$[1];
      newPolygon = [
        {
          x: start[2],
          y: start[3]
        }, {
          x: end[2],
          y: end[3]
        }
      ];
      idx = end[1];
      do {
        idx = (idx + 1) % ply2.length;
        newPolygon.push(ply2[idx]);
      } while (idx !== start[1]);
      ply2 = newPolygon;
    }
    return ply2;
    function fn$(a, b){
      return a + b.x;
    }
    function fn1$(a, b){
      return a + b.y;
    }
  };
  Polygon.create = function(width, height, side){
    var i$, i, results$ = [];
    if (side < 3) {
      side = 3;
    }
    for (i$ = 0; i$ < side; ++i$) {
      i = i$;
      results$.push({
        x: (width / 2 + (width / 2) * Math.cos(Math.PI * 2 * i / side)) * 1,
        y: (height / 2 + (height / 2) * Math.sin(Math.PI * 2 * i / side)) * 1
      });
    }
    return results$;
  };
  if (typeof module != 'undefined' && module !== null) {
    module.exports = Voronoi;
  }
  if (typeof window != 'undefined' && window !== null) {
    window.voronoi = Voronoi;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
  function in$(x, xs){
    var i = -1, l = xs.length >>> 0;
    while (++i < l) if (x === xs[i]) return true;
    return false;
  }
}).call(this);
