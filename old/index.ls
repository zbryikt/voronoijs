<- $ document .ready

svgnode = document.getElementById("svg")
svg = d3.select svgnode
box = svgnode.getBoundingClientRect!
width = box.width
height = box.height
width = height
window.xscale = xscale = d3.scale.linear().domain([0,1]).range([20, width - 20])
window.yscale = yscale = d3.scale.linear().domain([0,1]).range([height - 20, 20])
window.rscale = yscale = d3.scale.linear().domain([0,1]).range([0, width])
svg.attr do
  viewBox: [0, 0, width, height].join(" ")
/*
points = [{x: Math.random!, y: Math.random!, value: 1.0 * Math.random!} for i from 0 til 50]
svg.selectAll("circle.site").data(points)
  ..enter!append \circle .attr do
    class: \site
    cx: -> xscale it.x
    cy: -> yscale it.y
    r: -> it.value * 100
    fill: \#999
*/

points = [{x: Math.random!, y: Math.random!, value: Math.random! * 0.02 + 0.01} for i from 0 til 8]
# test case
#points = [{"x":0.424870609305799,"y":0.1748470920138061,"z":0.7488041063770652},{"x":0.32649940019473433,"y":0.4185706675052643,"z":0.5802994559053332},{"x":0.9347621656488627,"y":0.5137749393470585,"z":0.37738077947869897},{"x":0.921880749752745,"y":0.26007285504601896,"z":0.6238251540344208},{"x":0.6938414475880563,"y":0.3447506034281105,"z":0.47653517057187855},{"x":0.807099528843537,"y":0.5118813302833587,"z":0.22787888487800956}]
/*points = [
  * x: 0.1, y: 0.2, z: 0.1
  * x: 0.1, y: 0.1, z: 0.8
  * x: 0.1, y: 0.8, z: 0.5
  * x: 0.1, y: 0.8, z: 0.1
  * x: 0.3, y: 0.3, z: 0.2
  * x: 0.6, y: 0.5, z: 0.6
]*/
/*
points = points.map -> do
  x: parseInt(it.x * 10) / 10
  y: parseInt(it.y * 10) / 10
  z: parseInt(it.z * 10) / 10
console.log points
*/

svg.selectAll("circle.site").data(points)
  ..enter!append \circle .attr do
    class: \site
    cx: -> xscale it.x
    cy: -> yscale it.y
    r: -> rscale it.value
    fill: -> "rgba(0,0,0,#{(it.x ** 2 + it.y ** 2 - it.value)})"
    stroke: \#000

svg.selectAll("text").data(points)
  .enter!append \text .attr do
    class: \site
    x: -> xscale it.x
    y: -> yscale it.y
    dy: 20
    dx: -20
    "text-anchor": "middle"
    "dominant-baseline": "central"
  .text (d,i) -> i

(triangles) <- convex points.map(-> [it.x, it.y, ((it.x)**2 + (it.y)**2) - it.value]), _
console.log points.length, triangles.length
#(triangles) <- convex points.map(->[it.x, it.y, it.z]), _
duals = []
lines = []

for item in triangles =>
  [x1,y1,z1] = item.pts.0.c
  [x2,y2,z2] = item.pts.1.c
  [x3,y3,z3] = item.pts.2.c
  lines.push [[x1,y1,z1],[x2,y2,z2],item.active]
  lines.push [[x1,y1,z1],[x3,y3,z3],item.active]
  lines.push [[x2,y2,z2],[x3,y3,z3],item.active]

drawline = true
if drawline? =>
  svg.selectAll("line.edge").data(lines)
    ..enter!append \line .attr class: \edge
    ..exit!remove!
  svg.selectAll("line.edge")
    .attr do
      x1: -> xscale it.0.0
      y1: -> yscale it.0.1
      x2: -> xscale it.1.0
      y2: -> yscale it.1.1
      stroke: -> "rgba(0,0,0,0.1)" #if it.2 => \#f00 else \#999
      "stroke-width": 2

t2p = (triangle-set) ->
  ret = []
  for item in triangle-set =>
    [x1,y1,z1] = item.pts.0.c
    [x2,y2,z2] = item.pts.1.c
    [x3,y3,z3] = item.pts.2.c
    A = y1 * ( z2 - z3 ) + y2 * ( z3 - z1 ) + y3 * ( z1 - z2 )
    B = z1 * ( x2 - x3 ) + z2 * ( x3 - x1 ) + z3 * ( x1 - x2 )
    C = x1 * ( y2 - y3 ) + x2 * ( y3 - y1 ) + x3 * ( y1 - y2 )
    D = x1 * ( y2 * z3 - y3 * z2 ) + x2 * ( y3 * z1 - y1 * z3 ) + x3 * ( y1 * z2 - y2 * z1 )
    a = - ( A/C ) / 2
    b = - ( B/C ) / 2
    c = ( D/C )
    ret.push {x: a, y: b}
  center = ret.reduce(((a,b) -> {x: a.x + b.x, y: a.y + b.y}), {x:0, y:0})
  center.x = center.x / ret.length
  center.y = center.y / ret.length

  ret.sort (a,b) ->
    dc = center.x ** 2 + center.y ** 2
    da1 = (a.x - center.x) ** 2 + (a.y - center.y) ** 2
    db1 = (b.x - center.x) ** 2 + (b.y - center.y) ** 2
    da2 = (a.x - center.y) ** 2 + (a.y - center.x) ** 2
    db2 = (b.x - center.y) ** 2 + (b.y - center.x) ** 2
    a1 = (-center.x * (a.x - center.x) + -center.y * (a.y - center.y)) / ( dc * da1 )
    b1 = (-center.x * (b.x - center.x) + -center.y * (b.y - center.y)) / ( dc * db1 )
    a2 = (-center.y * (a.x - center.y) + -center.x * (a.y - center.x)) / ( dc * da2 )
    b2 = (-center.y * (b.x - center.y) + -center.x * (b.y - center.x)) / ( dc * db2 )
    if a2 < 0 => a1 = -a1 - 2
    if b2 < 0 => b1 = -b1 - 2
    return a1 - b1
  ret
drawPolygon = true
if drawPolygon? =>
  polygon = []
  for p,i in points =>
    set = triangles.filter (t) ->
      if i in t.idx => return true else false
      /*
      console.log t.idx
      idx = [0,1,2].filter((idx) ->
        p.x == t.pts[idx].c.0 and p.y == t.pts[idx].c.1
      ).0
      return idx? and t.norm.2 < 0*/
    console.log i, (set.length)
    polygon.push t2p set
    break
  svg.selectAll \path.polygon .data polygon
    ..enter!append \path .attr class: \polygon
    ..exit!remove!
  svg.selectAll \path.polygon .attr do
    d: ->
      (
        ["M#{xscale it.0.x} #{yscale it.0.y}"] ++
        it.map(-> "L#{xscale it.x} #{yscale it.y}") ++
        ["L#{xscale it.0.x} #{yscale it.0.y}"]
      ).join(" ")
    fill: \none
    stroke: "#00f"
    "stroke-width": 2

/*
for item in triangles
  [x1,y1,z1] = item.pts.0.c
  [x2,y2,z2] = item.pts.1.c
  [x3,y3,z3] = item.pts.2.c
  lines.push [[x1,y1,z1],[x2,y2,z2],item.active]
  lines.push [[x1,y1,z1],[x3,y3,z3],item.active]
  lines.push [[x2,y2,z2],[x3,y3,z3],item.active]

  A = y1 * ( z2 - z3 ) + y2 * ( z3 - z1 ) + y3 * ( z1 - z2 )
  B = z1 * ( x2 - x3 ) + z2 * ( x3 - x1 ) + z3 * ( x1 - x2 )
  C = x1 * ( y2 - y3 ) + x2 * ( y3 - y1 ) + x3 * ( y1 - y2 )
  D = x1 * ( y2 * z3 - y3 * z2 ) + x2 * ( y3 * z1 - y1 * z3 ) + x3 * ( y1 * z2 - y2 * z1 )
  a = -( A/C ) / 2
  b = -( B/C ) / 2
  c = ( D/C )
  console.log [a,b]
  duals.push {x: a, y: b, value: 1}

svg.selectAll("circle.vertex").data(duals)
  ..enter!append \circle .attr do
    class: \vertex
  ..exit!remove!
svg.selectAll("circle.vertex")
  .attr do
    cx: -> xscale it.x
    cy: -> yscale it.y
    r: -> 10
    fill: \#f00
*/
