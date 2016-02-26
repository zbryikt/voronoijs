Voronoi = {}

Aux = do
  inner: (p1,p2) -> p1.x * p2.x + p1.y * p2.y + p1.z * p2.z
  sub: (p1, p2) -> {x: p1.x - p2.x, y: p1.y - p2.y, z: p1.z - p2.z}
  cross: (v1, v2) -> do
    x: v1.y * v2.z - v1.z * v2.y
    y: v1.z * v2.x - v1.x * v2.z
    z: v1.x * v2.y - v1.y * v2.x
