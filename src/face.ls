
Voronoi.face = (convex, idx, active = false) ->
  @ <<< {convex, idx, active, removed: false}
  @pts = [p0,p1,p2] = [convex.pts[idx.0], convex.pts[idx.1], convex.pts[idx.2]]
  c = convex.center
  [x1,y1,z1] = [p2.x - p0.x, p2.y - p0.y, p2.z - p0.z]
  [x2,y2,z2] = [p1.x - p0.x, p1.y - p0.y, p1.z - p0.z]
  @norm = n = do # cross product
    x: y1 * z2 - z1 * y2
    y: z1 * x2 - x1 * z2
    z: x1 * y2 - y1 * x2
  len = n.x ** 2 + n.y ** 2 + n.z ** 2
  @norm = n = do
    x: n.x / len
    y: n.y / len
    z: n.z / len
  ip = n.x * (c.x - p0.x) + n.y * (c.y - p0.y) + n.z * (c.z - p0.z) #inner product
  if ip > 0 => 
    [n.x, n.y, n.z] = [-n.x, -n.y, -n.z]
    @pts.reverse!
    idx.reverse!
  else if ip == 0 => @trivial = true
  @edges = for i from 0 til 3 =>
    j = (i + 1 ) % 3
    [p,q] = if idx[i] > idx[j] => [idx[j],idx[i]] else [idx[i],idx[j]]
    (if convex.edges{}[p][q] => that else convex.edges{}[p][q] = [p, q]) <<< ref: 0
  @precal = ( n.x * p0.x + n.y * p0.y + n.z * p0.z ) # speedup calculation of front inner product
  @

Voronoi.face.prototype <<< do
  front: (p) ->
    n = @norm
    n.x * p.x + n.y * p.y + n.z * p.z - @precal > 0

  get-center: ->
    [ret,len] = [{x: 0, y: 0}, @pts.length]
    @pts.for-each ~> [ret.x,ret.y] = [ret.x + it.x, ret.y + it.y]
    ret <<< {x: ret.x / len, y: ret.y / len, z: -100}
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

