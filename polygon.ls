Polygon-center = (p) ->
  if !p or !p.length => return {x: NaN, y: NaN}
  return do
    x: p.reduce(((a,b) -> a + b.x),0) / p.length
    y: p.reduce(((a,b) -> a + b.y),0) / p.length

Polygon-area = (p) ->
  (for i from 0 til p.length
    j = (i + 1) % p.length
    [pi,pj] = [p[i], p[j]]
    (pi.x * pj.y - pi.y * pj.x)
  ).reduce(((a,b) -> a + b/2), 0)

Polygon-intersect = (polygon1, polygon2) ->
  hit = false
  polygon2 = JSON.parse(JSON.stringify(polygon2))
  cx1 = polygon1.reduce(((a,b)-> a + b.x),0) / polygon1.length
  cy1 = polygon1.reduce(((a,b)-> a + b.y),0) / polygon1.length
  for i from 0 til polygon1.length =>
    Q = polygon1[i]
    Vx = (polygon1[(i + 1) % polygon1.length].x - polygon1[i].x)
    Vy = (polygon1[(i + 1) % polygon1.length].y - polygon1[i].y)
    cx2 = polygon2.reduce(((a,b)-> a + b.x),0) / polygon2.length
    cy2 = polygon2.reduce(((a,b)-> a + b.y),0) / polygon2.length
    ts = for j from 0 til polygon2.length
      P = polygon2[j]
      Ux = (polygon2[(j + 1) % polygon2.length].x - polygon2[j].x)
      Uy = (polygon2[(j + 1) % polygon2.length].y - polygon2[j].y)
      if Uy * Vx - Ux * Vy == 0 => [-1,j] # Parallel
      else # if t >= 0 and t <= 1 => intersect
        t = (((P.x - Q.x) * Vy) - ((P.y - Q.y) * Vx)) / ( Uy * Vx - Ux * Vy)
        [tx, ty] = [P.x + Ux * t, P.y + Uy * t]
        [x1, y1] = [Vx, Vy]
        [x2, y2] = [cx2 - tx, cy2 - ty]
        inner = (-x1 * Uy + y1 * Ux) * (-x2 * Uy + y2 * Ux) > 0
        [t, j, tx, ty, inner]
        #fix: buggy about direction
    ts = ts.filter(-> it.0 >= 0 and it.0 <= 1)
    if ts.length < 2 => 
      if (-(cx1 - Q.x) * Vy + (cy1 - Q.y) * Vx) * (-(cx2 - Q.x) * Vy + (cy2 - Q.y) * Vx) < 0 =>
        return []
      continue
    [start, end] = if ts.0.4 => [ts.0, ts.1] else [ts.1, ts.0]
    new-polygon = [{x: start.2, y: start.3}, {x: end.2, y: end.3}]
    idx = end.1
    do
      idx = ( idx + 1 ) % polygon2.length
      new-polygon.push polygon2[idx]
    while idx != start.1
    polygon2 = new-polygon
  polygon2

#p1 = [[0,0],[2,0],[2,2],[0,2]].map -> {x: it.0, y: it.1}
#p2 = [[1,1],[3,1],[3,3],[1,3]].map -> {x: it.0, y: it.1}
#ret = Polygon-intersect p1, p2
#console.log ret
