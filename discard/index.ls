
Aux = do
  inner: (p1,p2) -> <[x y z]>.map(-> p1[it] * p2[it]).reduce(((a,b) -> a + b),0)
  sub: (p1, p2) -> 
    ret = {}
    <[x y z]>.map -> ret[it] = p1[it] - p2[it]
    ret
  cross: (v1, v2) -> do
    x: v1.y * v2.z - v1.z * v2.y
    y: v1.z * v2.x - v1.x * v2.z
    z: v1.x * v2.y - v1.y * v2.x

Convex = (pts, debug) ->
  @ <<< {pts, debug, polygons: []}
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

  calculate: -> 
    while @idx < @pts.length => @iterate!
    @grid!
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
    z =       D / C
    @dual.value = {x,y,z}
    return @dual.value

<- $ document .ready

count = 50
points = [{
  x: Math.random!
  y: Math.random!
  value: 0.01
} for i from 0 til count].map -> 
  it.z = (it.x) ** 2 + (it.y) ** 2 - it.value
  it
sum = points.reduce(((a,b) -> a + b.value),0)

points.map -> it.value = it.value / sum

boundary = [
  * x: 0, y: 0, boundary: true
  * x: 0, y: 1, boundary: true
  * x: 1, y: 0, boundary: true
  * x: 1, y: 1, boundary: true
].map (->
  it.value = 0.0
  it.z = it.x ** 2 + it.y ** 2 - it.value
  it
)



box = document.getElementById(\svg).getBoundingClientRect!
width = box.height
height = box.height
rscale = d3.scale.linear!domain [0,1] .range [0,30]
svg = d3.select \#svg 

render = ->
  polygons = convex.polygons
  seg = 60
  omega = [{
    x: (0.5 + 0.7 * Math.cos(Math.PI * 2 * i / seg)) * 1
    y: (0.5 + 0.7 * Math.sin(Math.PI * 2 * i / seg)) * 1
  } for i from 0 til seg]
  polygons = polygons.map -> 
    ret = Polygon-intersect omega, it
    ret <<< it{cx, cy}
  sites = polygons.map (it, i)-> 
    it{x: cx, y: cy} <<< {value: points[i].value}

  xrange = d3.extent(sites.map -> it.x)
  yrange = d3.extent(sites.map -> it.y)
  xscale = d3.scale.linear!domain xrange.map(->it*2) .range [0,height]
  yscale = d3.scale.linear!domain yrange.map(->it*2) .range [height,0]

  svg.selectAll \path.voronoi .data convex.polygons
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
    .on \click, (d,i) -> console.log i
  svg.selectAll \circle.site .data sites
    ..enter!append \circle .attr class: \site
    ..exit!remove!
  svg.selectAll \circle.site .attr do
    cx: -> xscale it.x
    cy: -> yscale it.y
    r: -> rscale it.value
    fill: \none
    stroke: \#000
    opacity: -> 1
  /*
  for i from 0 til points.length => points[i] <<< sites[i]
  xrange = d3.extent points.map -> it.x
  yrange = d3.extent points.map -> it.y
  for i from 0 til points.length =>
    p = points[i]
    p.x = ( p.x - xrange.0 ) / (xrange.1 - xrange.0)
    p.y = ( p.y - yrange.0 ) / (yrange.1 - yrange.0)
    p.x = p.x * 2 - 1
    p.y = p.y * 2 - 1
    p.z = p.x **2 + p.y ** 2 - p.value
  console.log "normalized x/y range:" , d3.extent(points.map -> it.x), d3.extent(points.map -> it.y)
  */

console.log "x/y range:" , d3.extent(points.map -> it.x), d3.extent(points.map -> it.y)
convex = new Convex points
convex.calculate!
render!

setInterval (-> 
  convex := new Convex points
  convex.calculate!
  render!
), 500

