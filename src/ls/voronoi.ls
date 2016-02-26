Voronoi = {}

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
