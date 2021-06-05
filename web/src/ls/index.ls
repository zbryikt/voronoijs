
box = document.getElementById(\demonstration).getBoundingClientRect!
width = box.width
height = box.height
svg = d3.select \#svg
  .attr do
    width: "#{width}px"
    height: "#{height}px"
    viewBox: [-10,-10,width + 20,height + 20].join(" ")
  .on \mousemove, ->
    [x, y] = [d3.event.clientX - box.left, d3.event.clientY - box.top]
    float-site = {x, y, weight: 30, value: 30}
  .on \click, ->
    if !boundmap => return
    [x, y] = [d3.event.clientX - box.left, d3.event.clientY - box.top]
    boundmap.sites.push {x, y, weight: 30, value: 30}

colors = d3.scale.ordinal!range <[#f381cf #c775e1 #907bdb #81b1da #a9e0ea #8ebc1a #e3a735 #d47b11 #c34128]>

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
          rgb = d3.rgb(colors i)
          "rgba(#{rgb.r},#{rgb.g},#{rgb.b},1.0)"
        else "rgba(0,0,0,0.0)"
      stroke: (d,i) -> \#000
      "stroke-width": (d,i) ->
        if sites[i] and sites[i].lv == 0 => return 5 else 1
    .on \mouseover, -> d3.select(@).attr fill: "rgba(0,0,0,0.5)"
    .on \mouseout, -> d3.select(@).attr fill: "rgba(0,0,0,0.1)"
    .on \click, (d,i) -> 
      sites[i].value += 1000
      setTimeout (->
        treemap.update-value!
        render!
      ), 0
  svg.selectAll \circle.site .data(sites.filter (d,i) -> polygons[i].length and !d.boundary and !d.children)
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
      d.value += 1000
      setTimeout (->
        treemap.update-value!
        render!
      ), 0
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
  len = parseInt(Math.random! * 8) + 2
  if lv == 0 => len = 8
  if lv == 1 => len = 4
  if lv == 2 => len = 4
  if lv >= 3 => return {value: (parseInt(Math.random!*2)*100 + 30), name: Math.random!}
  children = [makedata(lv + 1) for i from 0 til len]
  value = children.reduce(((a,b) -> a + b.value),0)
  return {children, value}
data = makedata!

c1 = children: [ { value: 2001 }, { value: 2002 }, { value: 2003 } ], value: 6006
c2 = children: [ { value: 31 }, { value: 32 }, { value: 2003 } ], value: 2066
testdata = children: [c1,c2], value: 8072

if true =>
  treemap = new voronoi.Treemap( data, voronoi.Polygon.create(width, height, 100), width, height )
  <- setInterval _, 50
  treemap.compute!
  render!
if false =>
  boundmap = new voronoi.Boundmap(
    voronoi.random-site(10, width, height, 500)
    voronoi.Polygon.create(width, height, 10)
    width
    height
  )
  <- setInterval _, 10
  boundmap.compute!
  render!
