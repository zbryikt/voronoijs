#http://www.eecs.tufts.edu/~mhorn01/comp163/algorithm.html

debug = false
render = (points, list) ->
  return
  if debug => console.log JSON.stringify list
  d3.select \#svg .selectAll \line.horizon .data list
    ..enter!append \line .attr class: \horizon
    ..exit!remove!
  d3.select \#svg .selectAll \line.horizon .attr do
    x1: -> window.xscale points[it.0].c.0
    x2: -> window.xscale points[it.1].c.0
    y1: -> window.yscale points[it.0].c.1
    y2: -> window.yscale points[it.1].c.1
    stroke: \#0f0
    "stroke-width": 5

convex = (ps, cb) ->
  rand = -> parseInt(10 * Math.random!)
  #points = [{pair: [], c: [rand!, rand!, rand!]} for i from 0 til 100]
  points = ps.map -> {pair: [], c: it}
  /*
  points = [
    { pair: [], c: [  0   0   0] }
    { pair: [], c: [ 10   0   0] }
    { pair: [], c: [  0  10   0] }
    { pair: [], c: [  0   0  10] }
    { pair: [], c: [  1   1   1] }
    { pair: [], c: [ -1  -1  -1] }
    { pair: [], c: [  0   0   0] }
  ]*/
  if debug => console.log JSON.stringify([0,1,2,3].map(->points[it].c))
  faces = []
  center = []

  inner = (p1,p2) -> [0 1 2].map(-> p1[it] * p2[it]).reduce(((a,b) -> a + b),0)
  side = (f, p) -> ret = inner(f.norm, p.c)
  center = [0 1 2].map((idx)-> [0 1 2 3].reduce(((a,b) -> a + points[b].c[idx]),0) / 4)
  sub = (p1, p2) -> [0 1 2].map -> p1[it] - p2[it]
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

  initset = [0 1 2 3]
  base = 4
  if debug => console.log points.length
  while base < points.length =>
    for idx in [[0 1 2],[0 1 3],[0 2 3],[1 2 3]].map((order) -> order.map -> initset[it])
      f = makeface idx
    if f.degenerate =>
      idx = initset
        .map (it,i) -> [sub(center, points[it].c).reduce(((a,b) -> a + b**2),0),i]
        .sort ((a,b) -> a.0 - b.0)
        .0.1
      initset.splice initset.indexOf(idx), 1
      initset.push base
      base++
    else break

  _parse = (idx) ->
    faces.map -> it.active = false
    flist = points[idx].pair
    elist = []
    horizon = []
    if debug => console.log "adding: (#idx) ", JSON.stringify(points[idx].c)
    if debug => console.log "light face: ", JSON.stringify(flist.map -> it.idx)
    for f in flist => 
      if !(f in faces) => continue
      for i from 0 til 3 =>
        e = [f.idx[i], f.idx[(i + 1)% 3]]
        if e.0 > e.1 => e.sort!
        dup = false
        for e2 in elist =>
          if e.0 == e2.0 and e.1 == e2.1 =>
            e2.dup = true
            dup = true
            break
        if !dup => elist.push e
    for e in elist => if !e.dup => horizon.push e
    removeface(flist)
    if debug => console.log "removed faces", JSON.stringify(flist.map ->it.idx)
    if debug => console.log "light edge: ", horizon
    render(points,horizon)
    for e in horizon =>
      pidx = e ++ [idx]
      f = makeface(pidx)
      if debug => console.log "adding face", JSON.stringify(f.idx)
      f.active = true

  /*
  cb faces
  idx = 4
  parse = ->
    _parse idx
    cb faces
    idx := idx + 1
    if idx < points.length => setTimeout parse, 2000
  setTimeout parse, 2000
  */
  for idx from base til points.length => _parse idx
  cb faces
