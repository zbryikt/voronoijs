
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

  iterate:  ->
    console.log @idx
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
    console.log "edges: ", edges.length
    console.log "remove: ", faces.length
    @faces.remove faces
    @faces.add newfaces = [new Convex.face(@, (edge ++ [@idx]), true) for edge in horizon]
    console.log "add: ", horizon.length
    newfaces.for-each (f,i) ~> @pts.for-each (p,i) ~> if f.front(p) => @set-pair f, p
    @idx++

Convex.face = (convex, idx, active = false) ->
  @ <<< {convex, idx, active}
  @pts = idx.map ~> convex.pts[it]
  @norm = Aux.cross(Aux.sub(@pts.2, @pts.0), Aux.sub(@pts.1, @pts.0))
  len = <[x y z]>.reduce(((a,b) ~> a + @norm[b]**2),0)
  @norm = { x: @norm.x / len, y: @norm.y / len, z: @norm.z / len }
  @front = (p) -> Aux.inner(@norm, Aux.sub(p, @pts.0)) > 0
  ip = Aux.inner(@norm, Aux.sub(convex.center, @pts.0)) 
  if ip > 0 => 
    <[x y z]>.for-each ~> @norm[it] = -@norm[it]
    @pts.reverse!
    @idx.reverse!
  else if ip == 0 => @trivial = true
  @


/*

  removeface = (flist) ->
    for f in flist => 
      idx = faces.indexOf(f)
      if idx >= 0 => faces.splice(faces.indexOf(f), 1)

  makeface = (idx) ->
    pts = idx.map -> points[it]
    norm = cross pts.map -> it.c
    ip = inner(norm, sub(center, pts.0.c)) 
    if ip > 0 => 
      norm = norm.map -> -it
      tmp = pts.0
      pts.0 = pts.2
      pts.2 = tmp
      tmp = idx.0
      idx.0 = idx.2
      idx.2 = tmp
    faces.push f = {idx, pts, norm, pair: []}
    for p in points =>
      if inner(f.norm, sub(p.c, f.pts.0.c)) > 0 => 
        f.pair.push p
        p.pair.push f
    if ip == 0 => f.degenerate = true
    f
*/


<- $ document .ready
svgnode = document.getElementById \svg
box = svgnode.getBoundingClientRect!
svg = d3.select \#svg .attr "viewBox": [0,0,box.width,box.height].join(" ")

xscale = d3.scale.linear!range [40, box.width - 40]
yscale = d3.scale.linear!range [box.height - 40, 40]
rscale = d3.scale.linear!range [10, 100]
/*
points = [{
  x: xscale(Math.random!)
  y: yscale(Math.random!)
  z: rscale(Math.random!)
  value: Math.random!*20 + 10
} for i from 0 til 10]
*/
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

convex = new Convex points

center = {x:0, y:0, z:0}
rotate = {x:0, y:0, z:0}
calcenter = ->
  center := {x: 0, y: 0, z: 0}
  points.for-each ->
    center.x += it.x / points.length
    center.y += it.y / points.length
    center.z += it.z / points.length

projection = ({x,y,z}) ->
  x -= center.x
  y -= center.y
  z -= center.z
  y = y * Math.cos(rotate.x) + z * Math.sin(rotate.x)
  z = -y * Math.sin(rotate.x) + z * Math.cos(rotate.x)
  x = x * Math.cos(rotate.y) - z * Math.sin(rotate.y)
  z = x * Math.sin(rotate.y) + z * Math.cos(rotate.y)
  /*
  x = x * Math.cos(rotate.z) + y * Math.sin(rotate.z)
  y = -x * Math.sin(rotate.z) + y * Math.cos(rotate.z)
  */
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
      p.x
    cy: -> 
      p = projection it
      p.y
    r: -> it.value
    fill: -> if it.active => "rgba(255,0,0,0.6)" else "rgba(0,0,0,0.2)"
    stroke: \#000
    opacity: -> 1 - (it.z / 500 )

  svg.selectAll \path.polygon .attr do
    d: ->
      p0 = projection it.pts.0
      p1 = projection it.pts.1
      p2 = projection it.pts.2
      ["M#{p0.x} #{p0.y}"
      "L#{p1.x} #{p1.y}"
      "L#{p2.x} #{p2.y}"
      "L#{p0.x} #{p0.y}"].join("")
      #["M#{it.pts.0.x} #{it.pts.0.y}"
      #"L#{it.pts.1.x} #{it.pts.1.y}"
      #"L#{it.pts.2.x} #{it.pts.2.y}"
      #"L#{it.pts.0.x} #{it.pts.0.y}"].join("")
    fill: "rgba(0,255,0,0.2)"
    stroke: "rgba(0,92,0,0.6)"


next = (delay = 0) ->
  setTimeout (->
    convex.iterate!
    calcenter!
    render!
  ), delay

render!

calcenter!
next 1000
next 2000
next 3000
next 4000
next 5000
next 6000
next 7000
next 8000
next 9000
next 10000
next 11000
setInterval (->
  rotate.y = rotate.y + 0.015
  #rotate.z = rotate.z + 0.02
  #rotate.x = rotate.x + 0.01
  rotate.x = 0.1
  render!
), 100
