
Voronoi.Convex = (pts) ->
  @ <<< {pts, polygons: [], edges: {}}
  @pts.for-each -> it.z = it.x ** 2 + it.y **2 - it.weight
  @pair = f2p: {}, p2f: {}
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
  faces.for-each (f,i) ~> @pts.for-each (p,j) ~> if f.front(p) => @set-pair i, j, f, p
  @

Voronoi.Convex.prototype <<< do
  get-pair-by-ptr: (idx) -> @pair.p2f[idx] or []
  get-pair-by-face: (idx) -> @pair.f2p[idx] or []

  #set-pair: (f,p) ->
  #  @pair.{}f2p[][@faces.list.indexOf(f)].push p
  #  @pair.{}p2f[][@pts.indexOf(p)].push f

  set-pair: (fi,pi,f,p) ->
    @pair.{}f2p[][fi].push p
    @pair.{}p2f[][pi].push f

  faces: do
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
    @faces.list.for-each -> it <<< {center: it.get-center!}
    @faces.list = @faces.list.filter -> !it.removed and it.front(it.center)
    @polygons = [[] for i from 0 til @pts.length]
    for p in @pts => p.visited = false
    visited = []
    for face in @faces.list =>
      for p in face.idx
        if p in visited => continue
        visited.push p
        polygon = []
        polygon.idx = p
        for f,i in @faces.list => if p in f.idx => polygon.push f.dual!
        @polygon-reorder polygon
        polygon.cx = polygon.reduce(((a,b) -> a + b.x),0) / polygon.length
        polygon.cy = polygon.reduce(((a,b) -> a + b.y),0) / polygon.length
        if @pts[p].boundary => polygon.boundary = true
        @polygons[p] = polygon
    #console.log @e1, @e2, @e3

  calculate: -> 
    while @idx < @pts.length => @iterate!
    @grid!

  iterate:  ->
    t1 = new Date!getTime!
    if @idx >= @pts.length => return
    faces = @get-pair-by-ptr @idx
    edges = []
    for f in faces => 
      continue if f.removed
      for edge in f.edges =>
        if !edge.ref => edges.push edge else edge.dup = true
        edge.ref++
    horizon = edges.filter(-> it.ref < 2)
    faces.map -> it.removed = true
    t2 = new Date!getTime!
    @faces.add newfaces = [new Voronoi.face(@, (edge ++ [@idx]), true) for edge in horizon]
    [pts, pair, idx, flen, plen, nlen] = [@pts, @pair, @idx, @faces.list.length, @pts.length, newfaces.length]
    t3 = new Date!getTime!
    newfaces.for-each (f,i) ~>
      i += flen - nlen
      [n,precal] = [f.norm, f.precal]
      for j from idx + 1 til plen # @pts.length
        p = pts[j]
        if n.x * p.x + n.y * p.y + n.z * p.z - precal > 0 => # unloop front caculation
          pair.f2p[][i].push p
          pair.p2f[][j].push f

    @idx++
    t4 = new Date!getTime!
    @e1 = (if @e1? => that else 0) + (t2 - t1)
    @e2 = (if @e2? => that else 0) + (t3 - t2)
    @e3 = (if @e3? => that else 0) + (t4 - t3)

