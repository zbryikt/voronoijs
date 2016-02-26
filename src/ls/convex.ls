
Voronoi.Convex = (pts) ->
  @ <<< {pts, polygons: []}
  @faces.list = []
  if @pts.length < 4 => return
  [initset,@idx] = [[0 1 2 3], 3]
  while @idx < @pts.length =>
    @idx++
    @center = {}
    <[x y z]>.map((idx) ~> 
      @center[idx] = [0 1 2 3].reduce(((a,b) ~> a + @pts[initset[b]][idx]),0) / 4)
    faces = [new Voronoi.face(@,idx) for idx in 
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

Voronoi.Convex.prototype <<< do
  pair: f2p: {}, p2f: {}
  get-pair-by-ptr: (idx) -> @pair.p2f[idx] or []
  get-pair-by-face: (idx) -> @pair.f2p[idx] or []

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
    faces = @get-pair-by-ptr @idx
    edges = []
    for f in faces => 
      #f.removed => continue
      if !(@faces.contain f) => continue
      for i from 0 til 3 =>
        edge = {} <<< {dup: false, node: [f.idx[i], f.idx[(i + 1)% 3]]}
        if edge.node.0 > edge.node.1 => edge.node.reverse!
        dupes = edges.filter(-> it.node.0 == edge.node.0 and it.node.1 == edge.node.1).map -> it <<< dup: true
        if !dupes.length => edges.push edge
    horizon = edges.filter(-> !it.dup ).map -> it.node
    #@faces.map -> it.removed = true
    @faces.remove faces
    @faces.add newfaces = [new Voronoi.face(@, (edge ++ [@idx]), true) for edge in horizon]
    newfaces.for-each (f,i) ~> @pts.for-each (p,i) ~> if f.front(p) => @set-pair f, p
    @idx++

