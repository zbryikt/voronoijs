Voronoi.Polygon = Polygon = {}

Polygon.center = (p) ->
  if !p or !p.length => return {x: NaN, y: NaN}
  return do
    x: p.reduce(((a,b) -> a + b.x),0) / p.length
    y: p.reduce(((a,b) -> a + b.y),0) / p.length

Polygon.area = (p) ->
  (for i from 0 til p.length
    j = (i + 1) % p.length
    [pi,pj] = [p[i], p[j]]
    (pi.x * pj.y - pi.y * pj.x)
  ).reduce(((a,b) -> a + b/2), 0)

Polygon.intersect = (ply1, ply2) ->
  hit = false
  cx1 = ply1.reduce(((a,b)-> a + b.x),0) / ply1.length
  cy1 = ply1.reduce(((a,b)-> a + b.y),0) / ply1.length
  for i from 0 til ply1.length =>
    [Q,QN] = [ply1[i], ply1[(i + 1) % ply1.length]]
    [Vx,Vy] = [(QN.x - Q.x), (QN.y - Q.y)]
    cx2 = ply2.reduce(((a,b)-> a + b.x),0) / ply2.length
    cy2 = ply2.reduce(((a,b)-> a + b.y),0) / ply2.length
    precal = Q.x * Vy - Q.y * Vx
    ts = for j from 0 til ply2.length
      [P,PN] = [ply2[j], ply2[(j + 1) % ply2.length]]
      [Ux,Uy] = [(PN.x - P.x), (PN.y - P.y)]
      if Uy * Vx - Ux * Vy == 0 => continue # Parallel
      else # if t >= 0 and t <= 1 => intersect
        t = (P.x * Vy - P.y * Vx - precal) / ( Uy * Vx - Ux * Vy)
        if t < 0 or t > 1 => continue
        [tx, ty] = [P.x + Ux * t, P.y + Uy * t]
        [x2, y2] = [cx2 - tx, cy2 - ty]
        inner = (-Vx * Uy + Vy * Ux) * (-x2 * Uy + y2 * Ux) > 0
        [t, j, tx, ty, inner]
        #fix: buggy about direction
    if ts.length < 2 => 
      if (-(cx1 - Q.x) * Vy + (cy1 - Q.y) * Vx) * (-(cx2 - Q.x) * Vy + (cy2 - Q.y) * Vx) < 0 =>
        return []
      continue
    [start, end] = if ts.0.4 => [ts.0, ts.1] else [ts.1, ts.0]
    new-polygon = [{x: start.2, y: start.3}, {x: end.2, y: end.3}]
    idx = end.1
    do
      idx = ( idx + 1 ) % ply2.length
      new-polygon.push ply2[idx]
    while idx != start.1
    ply2 = new-polygon
  ply2

Polygon.create = (width, height, side) ->
  if side < 3 => side = 3
  [{
    x: ((width/2) + (width/2) * Math.cos(Math.PI * 2 * i / side)) * 1
    y: ((height/2) + (height/2) * Math.sin(Math.PI * 2 * i / side)) * 1
  } for i from 0 til side]
