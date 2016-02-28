
<- $ document .ready

box = document.getElementById(\bound).getBoundingClientRect!
width = box.width
height = box.height
svg = d3.select \#svg
  .attr do
    width: "#{width}px"
    height: "#{height}px"
    viewBox: [0,0,width,height].join(" ")
  .on \mousemove, ->
    [x, y] = [d3.event.clientX - box.left, d3.event.clientY - box.top]
    float-site = {x, y, weight: 30, value: 30}
  .on \click, ->
    if !boundmap => return
    [x, y] = [d3.event.clientX - box.left, d3.event.clientY - box.top]
    boundmap.sites.push {x, y, weight: 30, value: 30}

colors = d3.scale.ordinal!range <[ #8c2243 #b22f60 #2957aa #46d9cd #34a491 #65ac36 #8e7d2f #d8a62a #b6802a #8a4f36 #b65244]>

render = ->
  xscale = d3.scale.linear!domain [0,width] .range [0,width]
  yscale = d3.scale.linear!domain [0,height] .range [0,height]
  polygons = treemap.get-polygons!
  sites = treemap.get-sites!
  svg.selectAll \path.voronoi .data polygons
    ..enter!append \path .attr class: \voronoi
    ..exit!remove!
  svg.selectAll \path.voronoi
    .attr do
      d: -> 
        if !it or !it.length => return ""
        ["M#{xscale it.0.x} #{yscale it.0.y}"] ++
        ["L#{xscale it[i]x} #{yscale it[i]y}" for i from 1 til it.length] ++
        ["L#{xscale it.0.x} #{yscale it.0.y}"].join(" ")
      fill: (d,i) -> 
        if sites[i] and sites[i].lv == 0 => 
          rgb = d3.rgb(colors sites[i].value)
          "rgba(#{rgb.r},#{rgb.g},#{rgb.b},0.5)"
        else "rgba(0,0,0,0.2)"
      stroke: (d,i) -> \#000
      "stroke-width": (d,i) ->
        if sites[i] and sites[i].lv == 0 => return 5 else 1
    .on \mouseover, -> d3.select(@).attr fill: "rgba(0,0,0,0.5)"
    .on \mouseout, -> d3.select(@).attr fill: "rgba(0,0,0,0.1)"
  svg.selectAll \circle.site .data(sites.filter (d,i) -> polygons[i].length and !d.boundary)
    ..enter!append \circle .attr class: \site
    ..exit!remove!
  svg.selectAll \circle.site
    .attr do
      cx: -> xscale it.x
      cy: -> yscale it.y
      r: -> Math.sqrt(it.value)
      fill: \#fff
      stroke: \#000
      opacity: -> 0.1
    .on \click, (d,i) -> 
      if !boundmap => return
      p = boundmap.sites[i]
      p.value = (Math.sqrt(p.value) + 10 ) ** 2
      p.weight = p.value
      boundmap.reset-weight!
      d3.event.preventDefault!
      d3.event.stopPropagation!
      d3.returnValue = false
      d3.cancelBubble = true


makedata = (lv = 0) ->
  len = parseInt(Math.random! * 15) + 2
  if lv >= 2 => return {value: (parseInt(Math.random!*2)*100 + 30), name: Math.random!}
  children = [makedata(lv + 1) for i from 0 til len]
  value = children.reduce(((a,b) -> a + b.value),0)
  return {children, value}
data = makedata!

if true =>
  treemap = new Voronoi.Treemap( data, Polygon.create(width, height, 100), width, height )
  <- setInterval _, 10
  treemap.compute!
  render!
if false =>
  boundmap = new Voronoi.Boundmap(
    Voronoi.random-site(10, width, height, 500)
    Voronoi.Polygon.create(width, height, 10)
    width
    height
  )
  <- setInterval _, 10
  boundmap.compute!
  render!
