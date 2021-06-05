var box, width, height, svg, colors, render, makedata, data, c1, c2, testdata, treemap, boundmap;
box = document.getElementById('demonstration').getBoundingClientRect();
width = box.width;
height = box.height;
svg = d3.select('#svg').attr({
  width: width + "px",
  height: height + "px",
  viewBox: [-10, -10, width + 20, height + 20].join(" ")
}).on('mousemove', function(){
  var ref$, x, y, floatSite;
  ref$ = [d3.event.clientX - box.left, d3.event.clientY - box.top], x = ref$[0], y = ref$[1];
  return floatSite = {
    x: x,
    y: y,
    weight: 30,
    value: 30
  };
}).on('click', function(){
  var ref$, x, y;
  if (!boundmap) {
    return;
  }
  ref$ = [d3.event.clientX - box.left, d3.event.clientY - box.top], x = ref$[0], y = ref$[1];
  return boundmap.sites.push({
    x: x,
    y: y,
    weight: 30,
    value: 30
  });
});
colors = d3.scale.ordinal().range(['#f381cf', '#c775e1', '#907bdb', '#81b1da', '#a9e0ea', '#8ebc1a', '#e3a735', '#d47b11', '#c34128']);
render = function(){
  var xscale, yscale, polygons, sites, x$, y$;
  xscale = d3.scale.linear().domain([0, width]).range([0, width]);
  yscale = d3.scale.linear().domain([0, height]).range([0, height]);
  polygons = treemap.getPolygons();
  sites = treemap.getSites();
  x$ = svg.selectAll('path.voronoi').data(polygons);
  x$.enter().append('path').attr({
    'class': 'voronoi'
  });
  x$.exit().remove();
  svg.selectAll('path.voronoi').attr({
    d: function(it){
      var i;
      if (!it || !it.length) {
        return "";
      }
      return ["M" + xscale(it[0].x) + " " + yscale(it[0].y)].concat((function(){
        var i$, to$, results$ = [];
        for (i$ = 1, to$ = it.length; i$ < to$; ++i$) {
          i = i$;
          results$.push("L" + xscale(it[i].x) + " " + yscale(it[i].y));
        }
        return results$;
      }()), ["L" + xscale(it[0].x) + " " + yscale(it[0].y)].join(" "));
    },
    fill: function(d, i){
      var rgb;
      if (sites[i] && sites[i].lv === 0) {
        rgb = d3.rgb(colors(i));
        return "rgba(" + rgb.r + "," + rgb.g + "," + rgb.b + ",1.0)";
      } else {
        return "rgba(0,0,0,0.0)";
      }
    },
    stroke: function(d, i){
      return '#000';
    },
    "stroke-width": function(d, i){
      if (sites[i] && sites[i].lv === 0) {
        return 5;
      } else {
        return 1;
      }
    }
  }).on('mouseover', function(){
    return d3.select(this).attr({
      fill: "rgba(0,0,0,0.5)"
    });
  }).on('mouseout', function(){
    return d3.select(this).attr({
      fill: "rgba(0,0,0,0.1)"
    });
  }).on('click', function(d, i){
    sites[i].value += 1000;
    return setTimeout(function(){
      treemap.updateValue();
      return render();
    }, 0);
  });
  y$ = svg.selectAll('circle.site').data(sites.filter(function(d, i){
    return polygons[i].length && !d.boundary && !d.children;
  }));
  y$.enter().append('circle').attr({
    'class': 'site'
  });
  y$.exit().remove();
  return svg.selectAll('circle.site').attr({
    cx: function(it){
      return xscale(it.x);
    },
    cy: function(it){
      return yscale(it.y);
    },
    r: function(it){
      return Math.sqrt(it.value);
    },
    fill: '#fff',
    stroke: '#000',
    opacity: function(){
      return 0.1;
    }
  }).on('click', function(d, i){
    var p;
    d.value += 1000;
    setTimeout(function(){
      treemap.updateValue();
      return render();
    }, 0);
    if (!boundmap) {
      return;
    }
    p = boundmap.sites[i];
    p.value = Math.pow(Math.sqrt(p.value) + 10, 2);
    p.weight = p.value;
    boundmap.resetWeight();
    d3.event.preventDefault();
    d3.event.stopPropagation();
    d3.returnValue = false;
    return d3.cancelBubble = true;
  });
};
makedata = function(lv){
  var len, children, res$, i$, i, value;
  lv == null && (lv = 0);
  len = parseInt(Math.random() * 8) + 2;
  if (lv === 0) {
    len = 8;
  }
  if (lv === 1) {
    len = 4;
  }
  if (lv === 2) {
    len = 4;
  }
  if (lv >= 3) {
    return {
      value: parseInt(Math.random() * 2) * 100 + 30,
      name: Math.random()
    };
  }
  res$ = [];
  for (i$ = 0; i$ < len; ++i$) {
    i = i$;
    res$.push(makedata(lv + 1));
  }
  children = res$;
  value = children.reduce(function(a, b){
    return a + b.value;
  }, 0);
  return {
    children: children,
    value: value
  };
};
data = makedata();
c1 = {
  children: [
    {
      value: 2001
    }, {
      value: 2002
    }, {
      value: 2003
    }
  ],
  value: 6006
};
c2 = {
  children: [
    {
      value: 31
    }, {
      value: 32
    }, {
      value: 2003
    }
  ],
  value: 2066
};
testdata = {
  children: [c1, c2],
  value: 8072
};
if (true) {
  treemap = new voronoi.Treemap(data, voronoi.Polygon.create(width, height, 100), width, height);
  setInterval(function(){
    treemap.compute();
    return render();
  }, 50);
}
if (false) {
  boundmap = new voronoi.Boundmap(voronoi.randomSite(10, width, height, 500), voronoi.Polygon.create(width, height, 10), width, height);
  setInterval(function(){
    boundmap.compute();
    return render();
  }, 10);
}