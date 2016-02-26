Voronoi = {}

Aux = do
  inner: (p1,p2) -> p1.x * p2.x + p1.y * p2.y + p1.z * p2.z
  sub: (p1, p2) -> {x: p1.x - p2.x, y: p1.y - p2.y, z: p1.z - p2.z}
  cross: (v1, v2) -> do
    x: v1.y * v2.z - v1.z * v2.y
    y: v1.z * v2.x - v1.x * v2.z
    z: v1.x * v2.y - v1.y * v2.x

Voronoi.Treemap = (root, omega, width, height, lv = 0) ->
  @ <<< {root, omega, width, height}
  @sites = [child <<< {
    x: Math.random! * width
    y: Math.random! * height
    lv
  } for child in root.children]
  @boundmap = new Voronoi.Boundmap @sites, omega, width, height
  @boundmap.compute!
  @treemap = []
  for child, i in root.children => if child.children =>
    @treemap.push new Voronoi.Treemap(child, @boundmap.polygons[i], width, height, lv + 1)
  @

Voronoi.Treemap.prototype = do
  compute: ->
    @boundmap.compute!
    (d,i) <~ @treemap.for-each
    d.set-omega @boundmap.polygons[i]
    d.compute!
  get-sites: -> ([@boundmap.sites] ++ @treemap.map(-> it.sites)).reduce(((a,b) -> a ++ b),[])
  get-polygons: -> ([@boundmap.polygons] ++ @treemap.map -> it.get-polygons!).reduce(((a,b) -> a ++ b),[])
  set-omega: (omega) ->
    @omega = omega
    @boundmap = new Voronoi.Boundmap @sites, omega, @width, @height


Voronoi.Boundmap = (sites, omega, width, height) ->
  @ <<< {sites, omega, width, height}
  @powerbox = new Voronoi.PowerDiagram sites, width, height
  @powerbox.compute!
  @clip!
  @

Voronoi.random-site = (count, width, height, weight) ->
  [{
    x: (width) * Math.random!
    y: (height) * Math.random!
    value: 1 + Math.random! * weight
  } for i from 0 til count].map -> it <<< {weight: it.value}

Voronoi.Boundmap.prototype = do
  clip: ->
    @polygons = @powerbox.convex.polygons.map ~> Voronoi.Polygon.intersect @omega, it
    @centroids = @polygons.map -> Voronoi.Polygon.center it
  adopt-pos: ->
    {sites,centroids,polygons} = @{sites, centroids, polygons}
    for i from 0 til centroids.length - 4 =>
      if !sites[i] or !polygons[i].length or sites[i].boundary => continue
      sites[i].x = centroids[i].x
      sites[i].y = centroids[i].y
      [weight,min] = [Math.sqrt(sites[i].weight), -1]
      for j from 0 til polygons[i].length =>
        [p,q] = [polygons[i][j], polygons[i][(j + 1) % polygons[i].length]]
        distance = Math.abs(
          ((q.y - p.y) * sites[i].x - (q.x - p.x) * sites[i].y + q.x * p.y - q.y * p.x) /
          Math.sqrt((q.y - p.y) ** 2 + (q.x - p.x) ** 2)
        )
        if min == -1 or min > distance => min = distance
      weight = Math.min(weight, min) ** 2
      sites[i].weight = weight
  reset-weight: -> @sites.for-each (d,i) ~> d.weight = d.pvalue = d.value
  adopt-weight: ->
    {sites,centroids,polygons} = @{sites, centroids, polygons}
    valuesum = 0
    sites.for-each (s) ->
      valuesum := valuesum + s.value
      if s.pvalue != s.value => s.weight = s.value # auto update
      s.pvalue = s.value
    areasum = Voronoi.Polygon.area @omega
    for i from 0 til centroids.length - 4 =>
      if !sites[i] or !polygons[i].length or sites[i].boundary => continue
      target-area = areasum * sites[i].value / valuesum
      current-area = Polygon.area polygons[i]
      weight = Math.sqrt(sites[i].weight) * target-area / current-area
      min = -1
      for j from 0 til centroids.length =>
        if i == j => continue
        d = Math.sqrt((centroids[j].x - sites[i].x) ** 2 + (centroids[j].y - sites[i].y) ** 2)
        if min == -1 or min > d => min = d
      weight = Math.min(weight, min) ** 2
      if weight < @powerbox.epsilon => weight = @powerbox.epsilon
      sites[i].weight = weight
  
  compute: ->
    @adopt-pos!
    @powerbox = new Voronoi.PowerDiagram @sites, @width, @height
    @powerbox.compute!
    @clip!
    @adopt-weight!
    @powerbox = new Voronoi.PowerDiagram @sites, @width, @height
    @powerbox.compute!
    @clip!


Voronoi.PowerDiagram = (sites, width, height) ->
  @ <<< {sites, width, height}
  @boundary = [
    * x: -width, y: -height, boundary: true
    * x: -width, y: 2 * height, boundary: true
    * x: 2 * width, y: -height, boundary: true
    * x: 2 * width, y: 2 * height, boundary: true
  ].map(~> it <<< {boundary: true, weight: @epsilon, value: @epsilon})
  @convex = new Voronoi.Convex JSON.parse(JSON.stringify(sites ++ @boundary))
  @

Voronoi.PowerDiagram.prototype = do
  epsilon: 0.0000000001
  compute: -> @convex.calculate!
