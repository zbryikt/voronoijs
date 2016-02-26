
<- $ document .ready
nearlyzero = 0.0000000001

reZ = -> it <<< z: it.x ** 2 + it.y ** 2 - it.value
normAll = -> 
  max = d3.max sites.map -> it.value
  sites.for-each -> it.value = ( it.value / max ) * width
  sites.map reZ


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

render = ->
  polygons = convex.polygons
  omega = [
    * x: 10, y: 10
    * x: width - 10, y: 10
    * x: width - 10, y: height - 10
    * x: 10, y: height - 10
  ]

  seg = 60
  omega = [{
    x: ((width/2) + (width/2) * Math.cos(Math.PI * 2 * i / seg)) * 1
    y: ((height/2) + (height/2) * Math.sin(Math.PI * 2 * i / seg)) * 1
  } for i from 0 til seg]

  polygons = polygons.map -> Voronoi.Polygon.intersect omega, it
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
      r: ->  Math.sqrt(it.value)
        #rscale Math.sqrt(it.value)
      fill: \#fff
      stroke: \#000
      opacity: -> 1
    .on \click, (d,i) -> 
      p = sites[i]
      p.value = (Math.sqrt(p.value) + 10 ) ** 2
      p.z = p.x ** 2 + p.y ** 2 - p.value
      #normAll!
      calc!
      d3.event.preventDefault!
      d3.event.stopPropagation!
      d3.returnValue = false
      d3.cancelBubble = true

  if start =>
    centers = polygons.map -> Voronoi.Polygon.center it
    for i from 0 til centers.length - 4 =>
      if sites[i] and polygons[i].length and !sites[i].boundary => 
        sites[i].x += (centers[i].x - sites[i].x) * 0.01
        sites[i].y += (centers[i].y - sites[i].y) * 0.01
        reZ sites[i]
  #for i from 0 til points.length => points[i] <<< sites[i]
  #xrange = d3.extent points.map -> it.x
  #yrange = d3.extent points.map -> it.y
  /*
  for i from 0 til points.length =>
    p = points[i]
    p.x = ( p.x - xrange.0 ) / (xrange.1 - xrange.0)
    p.y = ( p.y - yrange.0 ) / (yrange.1 - yrange.0)
    p.x = (p.x * 2 - 1) * 150
    p.y = (p.y * 2 - 1) * 150
    p.z = p.x **2 + p.y ** 2 - p.value
  */
  #console.log "normalized x/y range:" , d3.extent(points.map -> it.x), d3.extent(points.map -> it.y)

svg.on \click, ->
  [x, y] = [d3.event.clientX - box.left, d3.event.clientY - box.top]
  sites.push reZ {x, y, value: 30}
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
  x: (width / 4) + (width / 2) * Math.random!
  y: (height / 4) + (height / 2) * Math.random!
  value: 30 + Math.random!* 30
} for i from 0 til 20].map -> reZ it

calc = ->
  t1 = new Date!getTime!
  points := JSON.parse(JSON.stringify(sites ++ float-site ++ boundary))
  t2 = new Date!getTime!
  convex := new Voronoi.Convex points
  t3 = new Date!getTime!
  while convex.idx < convex.pts.length => convex.iterate!
  t4 = new Date!getTime!
  convex.grid!
  t5 = new Date!getTime!
  render!
  t6 = new Date!getTime!
  console.log (t2 - t1), (t3 - t2), (t4 - t3), (t5 - t4), (t6 - t5)
calc!

start = false
setTimeout (->
  start := true
  setInterval (-> 
    calc!
  ),100
), 200
/*setInterval (-> 
  convex := new Convex points
  convex.calculate!
  render!
), 1000
*/

