Voronoi = {}

Voronoi.Treemap = (root, omega, width, height, lv = 0) ->
  @ <<< {root, omega, width, height, lv}
  @sites = [child <<< {
    x: Math.random! * width
    y: Math.random! * height
    lv
  } for child in root.children]
  if lv == 0 => @normalize-value root, Polygon.area(omega), @correct-value(root)
  @boundmap = new Voronoi.Boundmap @sites, omega, width, height, true
  @boundmap.compute!
  @treemap = []
  for child, i in root.children => if child.children =>
    @treemap.push new Voronoi.Treemap(child, @boundmap.polygons[i], width, height, lv + 1)
  @

Voronoi.Treemap.prototype = do
  update-value: ->
    @normalize-value @root, Polygon.area(@omega), @correct-value(@root)
    @boundmap = new Voronoi.Boundmap @sites, @omega, @width, @height, true
    for t in @treemap => t.update-value!
    @compute!

  correct-value: (d) ->
    if !(d?) => d = @sites
    for item in d.children or [] =>
    d.value = ([@correct-value(item or null) for item in (d.children or [])].reduce(
      ((a,b)-> a + b),0)
    ) or d.value or 0

  normalize-value: (d, area, value) ->
    d.value = 0.05 * d.value * area / value
    for item in (d.children or []) => @normalize-value item, area, value

  compute: ->
    @boundmap.compute!
    (d,i) <~ @treemap.for-each
    d.set-omega @boundmap.polygons[i]
    d.compute!
  get-sites: -> (
    [@boundmap.sites] ++ [[{boundary: true} for i from 0 til 4]] ++ @treemap.map(-> it.get-sites!)).reduce(
      ((a,b) -> a ++ b),[])
  get-polygons: -> ([@boundmap.polygons] ++ @treemap.map -> it.get-polygons!).reduce(((a,b) -> a ++ b),[])
  set-omega: (omega) ->
    @omega = omega
    @boundmap = new Voronoi.Boundmap @sites, omega, @width, @height


Voronoi.Boundmap = (sites, omega, width, height, normalized) ->
  @ <<< {sites, omega, width, height}
  if !(normalized?) =>
    value-sum = sites.reduce(((a,b)-> a + b.value),0)
    area-sum = Polygon.area omega
    sites.for-each -> it.nvalue = 0.1 * it.value * area-sum / value-sum
  else => sites.for-each -> it.nvalue = it.value
  sites.for-each -> it.nvalue = it.value
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
    @polygons = @powerbox.convex.polygons.map ~> if it => Voronoi.Polygon.intersect @omega, it else []
    @centroids = @polygons.map -> if it => Voronoi.Polygon.centroid it else {x: null, y: null}
  adopt-pos: ->
    {sites,centroids,polygons} = @{sites, centroids, polygons}
    for i from 0 til centroids.length - 4 =>
      if !sites[i] or !polygons[i] or sites[i].boundary => continue
      # if polygon is gone, reset location to try to recreate it
      if !polygons[i].length => [sites[i].x, sites[i].y] = [@width * Math.random!, @height * Math.random!]
      else [sites[i].x, sites[i].y] = [centroids[i].x, centroids[i].y]
    for i from 0 til centroids.length - 4 =>
      if !sites[i] or !polygons[i].length or sites[i].boundary => continue
      [weight,min] = [Math.sqrt(sites[i].weight), -1]
      for j from 0 til polygons[i].length =>
        [p,q] = [polygons[i][j], polygons[i][(j + 1) % polygons[i].length]]
        distance = Math.abs(
          ((q.y - p.y) * sites[i].x - (q.x - p.x) * sites[i].y + q.x * p.y - q.y * p.x) /
          Math.sqrt((q.y - p.y) ** 2 + (q.x - p.x) ** 2)
        ) * 10
        if min == -1 or min > distance => min = distance
      weight = Math.min(weight, min) ** 2
      sites[i].weight = weight
  reset-weight: ->
    @sites.for-each (d,i) ~> d.weight = d.pvalue = d.nvalue
  adopt-weight: ->
    {sites,centroids,polygons} = @{sites, centroids, polygons}
    valuesum = 0
    sites.for-each (s) ->
      valuesum := valuesum + s.nvalue
      if s.pvalue != s.nvalue => s.weight = s.nvalue # auto update
      s.pvalue = s.nvalue
    areasum = Voronoi.Polygon.area @omega
    for i from 0 til centroids.length - 4 =>
      if !sites[i] or !polygons[i].length or sites[i].boundary => continue
      target-area = areasum * sites[i].nvalue / valuesum
      current-area = Polygon.area polygons[i]
      weight = Math.sqrt(sites[i].weight)
      new-weight = Math.sqrt(sites[i].weight) * target-area / current-area
      weight = 0.5 * ( new-weight - weight ) + weight # * 0.5 to smooth weight adoption
      min = -1
      for j from 0 til centroids.length - 4 =>
        if i == j or !@polygons[j] => continue
        d = Math.sqrt((centroids[j].x - sites[i].x) ** 2 + (centroids[j].y - sites[i].y) ** 2)
        if isNaN(d) => continue
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
