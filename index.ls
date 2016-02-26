
<- $ document .ready
nearlyzero = 0.0000000001
reZ = -> it <<< z: it.x ** 2 + it.y ** 2 - it.value
av = 0
all-value = -> av := sites.reduce(((a,b) -> a + b.data),0)
alpha = 1

box = document.getElementById(\bound).getBoundingClientRect!
width = box.width
height = box.height
svg = d3.select \#svg .attr do
  width: "#{width}px"
  height: "#{height}px"
  viewBox: [0,0,width,height].join(" ")

boundary = [
  * x: -width, y: -height, boundary: true
  * x: -width, y: 2 * height, boundary: true
  * x: 2 * width, y: -height, boundary: true
  * x: 2 * width, y: 2 * height, boundary: true
].map(-> it <<< {boundary: true, value: nearlyzero}).map reZ


omega = [
  * x: 10, y: 10
  * x: width - 10, y: 10
  * x: width - 10, y: height - 10
  * x: 10, y: height - 10
]
seg = 20
omega = [{
  x: ((width/2) + (width/2) * Math.cos(Math.PI * 2 * i / seg)) * 1
  y: ((height/2) + (height/2) * Math.sin(Math.PI * 2 * i / seg)) * 1
} for i from 0 til seg]
area-omega = Polygon.area omega
polygons = []
centers = []

clip = ->
  polygons := convex.polygons
  polygons := polygons.map -> Voronoi.Polygon.intersect omega, it

render = ->

  /*

  seg = 60
  omega = [{
    x: (0.0 + 2500.0 * Math.cos(Math.PI * 2 * i / seg)) * 1
    y: (0.0 + 2500.0 * Math.sin(Math.PI * 2 * i / seg)) * 1
  } for i from 0 til seg]

  polygons = polygons.map -> 
    ret = Polygon-intersect omega, it
    ret <<< it{cx, cy}
  */
  #sites = polygons.map (it, i)-> 
  #  it{x: cx, y: cy} <<< {value: points[i].value}
  /*
  console.log polygons.map((d,i) -> 
    "#i(#{points[i].x},#{points[i].y}): " + (d.map -> 
      "#{parseInt(10*it.x)/10} #{parseInt(10*it.y)/10}"
    ).join("|")
  ).join("\n")
  */

  #xrange = d3.extent(sites.map -> it.x)
  #yrange = d3.extent(sites.map -> it.y)
  /*
  xrange = [-1000,1000]
  yrange = [-1000,1500]
  xscale = d3.scale.linear!domain xrange.map(->it) .range [0,height]
  yscale = d3.scale.linear!domain yrange.map(->it) .range [height,0]
  */
  xscale = d3.scale.linear!domain [0,width] .range [0,width]
  yscale = d3.scale.linear!domain [0,height] .range [0,height]
  svg.selectAll \path.voronoi .data polygons
    ..enter!append \path .attr class: \voronoi
    ..exit!remove!
  svg.selectAll \path.voronoi
    .attr do
      d: -> 
        if !it.length => return ""
        ["M#{xscale it.0.x} #{yscale it.0.y}"] ++
        ["L#{xscale it[i]x} #{yscale it[i]y}" for i from 1 til it.length] ++
        ["L#{xscale it.0.x} #{yscale it.0.y}"].join(" ")
      fill: "rgba(0,0,0,0.1)"
      stroke: \#000
    .on \mouseover, -> d3.select(@).attr fill: "rgba(0,0,0,0.5)"
    .on \mouseout, -> d3.select(@).attr fill: "rgba(0,0,0,0.1)"
  svg.selectAll \circle.site .data sites
    ..enter!append \circle .attr class: \site
    ..exit!remove!
  svg.selectAll \circle.site
    .attr do
      cx: -> xscale it.x
      cy: -> yscale it.y
      r: -> Math.sqrt(it.data) # Math.sqrt(it.value)
        #rscale Math.sqrt(it.value)
      fill: \#fff
      stroke: \#000
      opacity: -> 0.1
    .on \click, (d,i) -> 
      alpha := 1
      p = sites[i]
      p.data = (Math.sqrt(p.data) + 10 ) ** 2
      p.value = p.data
      for i from 0 til sites.length => 
        sites[i].value = sites[i].data
        reZ sites[i]
      all-value!
      reZ p
      #p.z = p.x ** 2 + p.y ** 2 - p.value
      calc!
      d3.event.preventDefault!
      d3.event.stopPropagation!
      d3.returnValue = false
      d3.cancelBubble = true

  /*
  centers = polygons.map -> Voronoi.Polygon.center it
  for i from 0 til centers.length - 4 =>
    if !sites[i] or !polygons[i].length or sites[i].boundary => continue
    sites[i].x = centers[i].x
    sites[i].y = centers[i].y
  */
  /*
  for i from 0 til centers.length - 4 =>
    if !sites[i] or !polygons[i].length or sites[i].boundary => continue
    a = Polygon.area polygons[i]
    drate = (sites[i].data) / av
    target-area = area-omega * drate
    current-area = a

    v = Math.sqrt(v) * target-area / current-area
    min = -1
    for j from 0 til centers.length =>
      if i == j => continue
      d = Math.sqrt((centers[j].x - sites[i].x) ** 2 + (centers[j].y - sites[i].y) ** 2)
      if min == -1 or min > d => min = d
    v = d3.min([v, min])**2
    if v < nearlyzero => v = nearlyzero
    sites[i].value = v
    reZ sites[i]
  */

svg.on \click, ->
  alpha := 1
  [x, y] = [d3.event.clientX - box.left, d3.event.clientY - box.top]
  sites.push reZ {x, y, value: 30, data: 30}
  all-value!
  calc!

float-site = []

svg.on \mousemove, ->
  [x, y] = [d3.event.clientX - box.left, d3.event.clientY - box.top]
  float-site := reZ {x, y, value: 30}
  calc!

points = []
convex = null
sites = []
sites = [{
  x: (width) * Math.random!
  y: (height) * Math.random!
  value: 1 + Math.random!* 600
} for i from 0 til 100].map -> 
  it.data = it.value
  reZ it

all-value!

calc = ->

  for i from 0 til centers.length - 4 =>
    if !sites[i] or !polygons[i].length or sites[i].boundary => continue
    /*sites[i].x = centers[i].x
    sites[i].y = centers[i].y*/

    v = Math.sqrt(sites[i].value)
    min = -1
    for j from 0 til polygons[i].length =>
      p = polygons[i][j]
      q = polygons[i][(j + 1) % polygons[i].length]
      distance = Math.abs(
        ((q.y - p.y) * sites[i].x - (q.x - p.x) * sites[i].y + q.x * p.y - q.y * p.x) /
        Math.sqrt((q.y - p.y) ** 2 + (q.x - p.x) ** 2)
      )
      if min == -1 or min > distance => min = distance
    v = Math.min(v, min) ** 2
    sites[i].value = v
    reZ sites[i]

  points := JSON.parse(JSON.stringify(sites ++ float-site ++ boundary ))
  convex := new Voronoi.Convex points
  convex.calculate!
  clip!

  for i from 0 til centers.length - 4 =>
    if !sites[i] or !polygons[i].length or sites[i].boundary => continue
    v = sites[i].value
    a = Polygon.area polygons[i]
    drate = (sites[i].data) / av
    target-area = area-omega * drate
    current-area = a

    u = Math.sqrt(v)
    v = Math.sqrt(v) * target-area / current-area
    min = -1
    for j from 0 til centers.length =>
      if i == j => continue
      d = Math.sqrt((centers[j].x - sites[i].x) ** 2 + (centers[j].y - sites[i].y) ** 2)
      if min == -1 or min > d => min = d
    v = Math.min(v, min) ** 2
    if v < nearlyzero => v = nearlyzero
    #sites[i].value += (v - sites[i].value) * alpha
    sites[i].value = v
    reZ sites[i]

  points := JSON.parse(JSON.stringify(sites ++ float-site ++ boundary ))
  convex := new Voronoi.Convex points
  convex.calculate!
  clip!
  centers := polygons.map -> Voronoi.Polygon.center it
  for i from 0 til centers.length - 4 =>
    if !sites[i] or !polygons[i].length or sites[i].boundary => continue
    sites[i].x = centers[i].x
    sites[i].y = centers[i].y
  render!

points := JSON.parse(JSON.stringify(sites ++ float-site ++ boundary ))
convex := new Voronoi.Convex points
convex.calculate!
centers := polygons.map -> Voronoi.Polygon.center it
clip!
render!

setTimeout (->
  setInterval (-> 
    calc!
    alpha := alpha * 0.99
  ),10
), 200
