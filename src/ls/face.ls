
Voronoi.face = (convex, idx, active = false) ->
  @ <<< {convex, idx, active, removed: false}
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

Voronoi.face.prototype <<< do
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

