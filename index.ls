
Aux = do
  inner: (p1,p2) -> <[x y z]>.map(-> p1[it] * p2[it]).reduce(((a,b) -> a + b),0)
  side: (f, p) -> ret = @inner(f.norm, p)
  sub: (p1, p2) -> 
    ret = {}
    <[x y z]>.map -> ret[it] = p1[it] - p2[it]
    ret
  cross: (v1, v2) -> do
    x: v1.y * v2.z - v1.z * v2.y
    y: v1.z * v2.x - v1.x * v2.z
    z: v1.x * v2.y - v1.y * v2.x

Convex = (pts, debug) ->
  @ <<< {pts, debug}
  @faces.list = []
  if @debug => console.log "Create convex for point set ( length #{pts.length} )" 
  if @pts.length < 4 => return #TODO trivial case
  [initset,@idx] = [[0 1 2 3], 3]
  while @idx < @pts.length =>
    @idx++
    @center = {}
    <[x y z]>.map((idx) ~> 
      @center[idx] = [0 1 2 3].reduce(((a,b) ~> a + @pts[initset[b]][idx]),0) / 4)
    faces = [new Convex.face(@,idx) for idx in 
      [[0 1 2],[0 1 3],[0 2 3],[1 2 3]].map (it) -> it.map((jt)-> initset[jt])]
    if !faces.filter(-> it.trivial).length => break
    # coplane - remove a node closest to center
    idx = initset
      .map((it,i) ~> 
        vector = Aux.sub(@center, @pts[it])
        <[x y z]>.reduce(((a,b) -> a + vector[b]**2),0)
        [vector,i]
      ).sort((a,b) -> a.0 - b.0).0.1
    initset.splice initset.indexOf(idx), 1
    initset.push @idx
  @faces.add faces
  faces.for-each (f,i) ~> @pts.for-each (p,i) ~> if f.front(p) => @set-pair f, p
  @

Convex.prototype <<< do
  pair: f2p: {}, p2f: {}
  get-pair: (item, idx) ->
    if item instanceof Convex.face => return @pair.f2p[@faces.list.indexOf(item)] or []
    @pair.p2f[@pts.indexOf(item)] or []

  set-pair: (f,p) ->
    @pair.{}f2p[][@faces.list.indexOf(f)].push p
    @pair.{}p2f[][@pts.indexOf(p)].push f

  faces: do
    list: []
    contain: -> it in @list
    add: -> if Array.isArray(it) => @list ++= it else @list.push it
    remove: (faces) -> 
      if !Array.isArray(faces) => faces = [faces]
      (f) <~ faces.for-each
      idx = @list.indexOf(f)
      if idx >= 0 => @list.splice idx, 1

  polygon-reorder: (ps) ->
    cx = ps.reduce(((a,b) -> a + b.x),0) / ps.length
    cy = ps.reduce(((a,b) -> a + b.y),0) / ps.length
    clen = (cx ** 2 + cy ** 2)
    angle = (p) ->
      len = Math.sqrt(clen * ((p.x - cx) ** 2 + (p.y - cy) ** 2))

      a = Math.acos(( -cx * (p.x - cx) - cy * (p.y - cy) ) / len)
      b = Math.acos(( cy * (p.x - cx) - cx * (p.y - cy) ) / len)
      if b > Math.PI/2 => a = 6.28 - a
      return a
    ps.sort (a,b) -> angle(a) - angle(b)
      

  grid: ->
    @polygons = []
    for p in @pts => p.visited = false
    visited = []
    for face in @faces.list =>
      center = face.center!
      if !face.front({x: center.x, y: center.y, z: -100}) => continue
      for p in face.idx
        if p in visited => continue
        visited.push p
        polygon = []
        polygon.idx = p
        for f,i in @faces.list =>
          center = f.center!
          if !f.front({x: center.x, y: center.y, z: -100}) => continue

          if p in f.idx => polygon.push f.dual!
        @polygon-reorder polygon
        polygon.cx = polygon.reduce(((a,b) -> a + b.x),0) / polygon.length
        polygon.cy = polygon.reduce(((a,b) -> a + b.y),0) / polygon.length
        if @pts[p].boundary => polygon.boundary = true
        @polygons.push polygon
    console.log @pts.length, "vs", @polygons.length
        
  iterate:  ->
    if @idx >= @pts.length => return
    @faces.list.map -> it.active = false
    @pts[@idx].active = true
    faces = @get-pair @pts[@idx]
    edges = []
    count = 0
    for f in faces => 
      if !(@faces.contain f) => continue
      for i from 0 til 3 =>
        count++
        edge = {} <<< {dup: false, node: [f.idx[i], f.idx[(i + 1)% 3]]}
        if edge.node.0 > edge.node.1 => edge.node.reverse!
        dupes = edges.filter(-> it.node.0 == edge.node.0 and it.node.1 == edge.node.1).map -> it <<< dup: true
        if !dupes.length => edges.push edge
    horizon = edges.filter(-> !it.dup ).map -> it.node
    @faces.remove faces
    @faces.add newfaces = [new Convex.face(@, (edge ++ [@idx]), true) for edge in horizon]
    newfaces.for-each (f,i) ~> @pts.for-each (p,i) ~> if f.front(p) => @set-pair f, p
    @idx++

Convex.face = (convex, idx, active = false) ->
  @ <<< {convex, idx, active}
  @pts = idx.map ~> convex.pts[it]
  @norm = Aux.cross(Aux.sub(@pts.2, @pts.0), Aux.sub(@pts.1, @pts.0))
  len = <[x y z]>.reduce(((a,b) ~> a + @norm[b]**2),0)
  @norm = { x: @norm.x / len, y: @norm.y / len, z: @norm.z / len }
  @front = (p) -> Aux.inner(@norm, Aux.sub(p, @pts.0)) > 0
  @center = -> 
    ret = {x:0, y: 0, z:0 }
    @pts.map ~> 
      ret.x += it.x / @pts.length
      ret.y += it.y / @pts.length
      ret.z += it.z / @pts.length
    ret
  ip = Aux.inner(@norm, Aux.sub(convex.center, @pts.0)) 
  if ip > 0 => 
    <[x y z]>.for-each ~> @norm[it] = -@norm[it]
    @pts.reverse!
    @idx.reverse!
  else if ip == 0 => @trivial = true
  @

Convex.face.prototype <<< do
  dual: ->
    if @dual.value => @dual.value
    {x:x1,y:y1,z:z1} = @pts.0
    {x:x2,y:y2,z:z2} = @pts.1
    {x:x3,y:y3,z:z3} = @pts.2
    A = y1 * ( z2 - z3 ) + y2 * ( z3 - z1 ) + y3 * ( z1 - z2 )
    B = z1 * ( x2 - x3 ) + z2 * ( x3 - x1 ) + z3 * ( x1 - x2 )
    C = x1 * ( y2 - y3 ) + x2 * ( y3 - y1 ) + x3 * ( y1 - y2 )
    D = x1 * ( y2 * z3 - y3 * z2 ) + x2 * ( y3 * z1 - y1 * z3 ) + x3 * ( y1 * z2 - y2 * z1 )
    x = 0.5 * -A / C 
    y = 0.5 * -B / C
    z =       -D / C
    @dual.value = {x,y,z}
    return @dual.value



<- $ document .ready
svgnode = document.getElementById \svg
box = svgnode.getBoundingClientRect!
svgnode2 = document.getElementById \svg2
box2 = svgnode2.getBoundingClientRect!
svg = d3.select \#svg .attr "viewBox": [0,0,box.width,box.height].join(" ")
svg2 = d3.select \#svg2 .attr "viewBox": [0,0,box2.width,box2.height].join(" ")

xscale = d3.scale.linear!domain [0,1] .range [40, box.width - 40]
yscale = d3.scale.linear!domain [0,1] .range [box.height - 40, 40]
rscale = d3.scale.linear!domain [0,1] .range [3, 10]

/* diamond 
points =[
  * x: 300, y: 400, z: 200, value: 10
  * x: 900, y: 400, z: 200, value: 10
  * x: 900, y: 400, z: 400, value: 10
  * x: 300, y: 400, z: 400, value: 10
  * x: 600, y: 200, z: 300, value: 10
  * x: 600, y: 600, z: 300, value: 10
]
points = [i for i from 0 til 6.28 by (6.28 / 12)].map((i)->
  x: 600 + 200 * Math.cos(i), y: 300 + 30 * ( i % 2) - 15, z: 400 + 200 * Math.sin(i), value: 10
) ++ [
  * x: 600, y: 150, z: 400, value: 10
  * x: 600, y: 450, z: 400, value: 10
]
*/
/*
points = [{"x":0.424870609305799,"y":0.1748470920138061,"z":0.7488041063770652},{"x":0.32649940019473433,"y":0.4185706675052643,"z":0.5802994559053332},{"x":0.9347621656488627,"y":0.5137749393470585,"z":0.37738077947869897},{"x":0.921880749752745,"y":0.26007285504601896,"z":0.6238251540344208},{"x":0.6938414475880563,"y":0.3447506034281105,"z":0.47653517057187855},{"x":0.807099528843537,"y":0.5118813302833587,"z":0.22787888487800956}].map ->
  it.x = xscale(it.x)
  it.y = yscale(it.y)
  it.z = rscale(it.z)
  it.value = Math.random!*20 + 10
  it

points = [
  * x: 0.1, y: 0.2, z: 0.1
  * x: 0.1, y: 0.1, z: 0.8
  * x: 0.1, y: 0.8, z: 0.5
  * x: 0.1, y: 0.8, z: 0.1
  * x: 0.3, y: 0.3, z: 0.2
  * x: 0.6, y: 0.5, z: 0.6
].map ->
  it.x = xscale(it.x)
  it.y = yscale(it.y)
  it.z = rscale(it.z)
  it.value = Math.random!*20 + 10
  it
*/


/*
points = [{"x":383.79792971536517,"y":111.89106427459046},{"x":324.0820639953017,"y":238.51067258417606},{"x":461.4851806801744,"y":44.859080305788666},{"x":757.2686711652204,"y":188.08447949867696},{"x":551.9969127769582,"y":297.280772855971},{"x":731.1774751567282,"y":71.85471177147701},{"x":905.8344591339119,"y":310.47343367990106},{"x":107.13961837114766,"y":226.179325342644},{"x":146.61588511196896,"y":158.96419118298218},{"x":98.78940558061004,"y":167.19204908562824}]
points.map ->
  it.value = Math.random!*50 + 10
  it.z = (it.x - 400) ** 2 + (it.y - 400) ** 2 - it.value ** 2
*/


count = 500
points = [{
  x: Math.random! * 1
  y: Math.random! * 1
  value: Math.random! * 0.1 + 0.1
} for i from 0 til count].map -> 
  it.z = (it.x) ** 2 + (it.y) ** 2 - 0 #it.value
  it

points ++= [
  * x: 0, y: 0, boundary: true
  * x: 0, y: 1, boundary: true
  * x: 1, y: 0, boundary: true
  * x: 1, y: 1, boundary: true
].map (->
  it.value = 0.0
  it.z = it.x ** 2 + it.y ** 2 - it.value
  it
)
convex = new Convex points

center = {x:0, y:0, z:0}
rotate = {x:0, y:0, z:0}
calcenter = ->
  center := {x: 0, y: 0, z: 0}
  points.for-each ->
    center.x += (it.x / points.length)
    center.y += (it.y / points.length)
    center.z += (it.z / points.length)

projection = ({x,y,z}) ->
  x -= center.x
  y -= center.y
  z -= center.z
  x2 = x
  y2 = y * Math.cos(rotate.x) + z * Math.sin(rotate.x)
  z2 = -y * Math.sin(rotate.x) + z * Math.cos(rotate.x)
  x3 = x2 * Math.cos(rotate.y) - z2 * Math.sin(rotate.y)
  y3 = y2
  z3 = x2 * Math.sin(rotate.y) + z2 * Math.cos(rotate.y)
  x4 = x3 * Math.cos(rotate.z) + y3 * Math.sin(rotate.z)
  y4 = -x3 * Math.sin(rotate.z) + y3 * Math.cos(rotate.z)
  z4 = z3
  x = x4
  y = y4
  x += center.x
  y += center.y
  z += center.z

  #x = box.width / 2 + ((x - box.width / 2) / (z + 110)) * 50
  #y = box.height / 2 + ((y - box.height / 2) / (z + 110)) * 50
  {x,y,z}

render = ->
  svg.selectAll \circle.site .data points
    ..enter!append \circle .attr class: \site
    ..exit!remove!

  svg.selectAll \path.polygon .data convex.faces.list
    ..enter!append \path .attr class: \polygon
    ..exit!remove!

  svg.selectAll \circle.site .attr do
    cx: -> 
      p = projection it
      xscale(p.x)
    cy: -> 
      p = projection it
      yscale(p.y)
    r: -> rscale(it.value)
    #fill: -> if it.active => "rgba(255,0,0,0.6)" else "rgba(0,0,0,0.2)"
    fill: \none
    stroke: \#000
    opacity: -> 1# 1 - (it.z / 500 )

  svg.selectAll \path.polygon .attr do
    d: ->
      p0 = projection it.pts.0
      p1 = projection it.pts.1
      p2 = projection it.pts.2
      ["M#{xscale p0.x} #{yscale p0.y}"
      "L#{xscale p1.x} #{yscale p1.y}"
      "L#{xscale p2.x} #{yscale p2.y}"
      "L#{xscale p0.x} #{yscale p0.y}"].join("")
    fill: ->
      center = it.center!
      if it.front({x:center.x,y:center.y,z:-100}) => "rgba(0,255,0,0.4)"
      else "rgba(255,255,0,0.05)"
    stroke: ->
      center = it.center!
      if it.front({x:center.x,y:center.y,z:-100}) => "rgba(0,92,0,0.4)"
      else "rgba(0,92,0,0.05)"

  svg.selectAll \circle.facedual .data(convex.faces.list.map -> {f: it, p: it.dual!})
    ..enter!append \circle .attr class: \facedual
    ..exit!remove!

  svg.selectAll \circle.facedual .attr do
    cx: ->
      p = projection it.p
      xscale p.x
    cy: ->
      p = projection it.p
      yscale p.y
    r: 3
    fill: "rgba(192,0,0,0.3)"
    stroke: \#f00
    opacity: ->
      center = it.f.center!
      if it.f.front({x:center.x,y:center.y,z:-100}) => 1
      else 0.2
    "stroke-width": 2
  
  if !convex.polygons => return
  xrange = d3.extent convex.polygons.filter(->!it.boundary).map -> it.cx
  yrange = d3.extent convex.polygons.filter(->!it.boundary).map -> it.cy
  xrange = [-0.5 0.5]
  yrange = [-0.5 0.5]
  x2scale = d3.scale.linear!domain xrange .range [50,900]
  y2scale = d3.scale.linear!domain yrange .range [500,50]
  svg2.selectAll \path.voronoi .data (convex.polygons or [])
    ..enter!append \path .attr class: \voronoi
    ..exit!remove!
  svg2.selectAll \path.voronoi
    .attr do
      d: -> 
        ["M#{x2scale it.0.x} #{y2scale it.0.y}"] ++
        ["L#{x2scale it[i]x} #{y2scale it[i]y}" for i from 1 til it.length] ++
        ["L#{x2scale it.0.x} #{y2scale it.0.y}"].join(" ")
      fill: "rgba(0,0,0,0.1)"
      stroke: \#000
    .on \mouseover, -> d3.select(@).attr fill: "rgba(0,0,0,0.5)"
    .on \mouseout, -> d3.select(@).attr fill: "rgba(0,0,0,0.1)"
  svg2.selectAll \circle.voronoi .data (convex.polygons or [])
    ..enter!append \circle .attr class: \voronoi
    ..exit!remove!
  svg2.selectAll \circle.voronoi
    .attr do
      cx: -> x2scale it.cx
      cy: -> y2scale it.cy
      r: -> rscale(points[it.idx].value)
      fill: "rgba(255,0,0,0.2)"
      stroke: \#f00

next = (delay = 0) ->
  setTimeout (->
    convex.iterate!
    calcenter!
    render!
  ), delay

calcenter!
start = new Date!getTime!
console.log "start: #start"
for i from 0 til count => convex.iterate!
mid = new Date!getTime!
console.log "grid: #mid ( elapsed: #{mid - start})"
convex.grid!
end = new Date!getTime!
console.log "end: #end"
console.log "elapsed: #{end - mid} / total: #{end - start}"


setInterval (->
  rotate.y = rotate.y + 0.00
  rotate.z =  rotate.z + 0.0
  #rotate.x = rotate.x + 0.01
  render!
), 1000
