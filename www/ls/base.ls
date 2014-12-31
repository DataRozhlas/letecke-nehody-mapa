init = ->
  {world} = ig.data
  land = topojson.feature world, world.objects."land"
  width = 1000
  height = 800
  projection = d3.geo.mercator!
    ..scale width / (Math.PI * 2)
    ..translate [width / 2, height / 2]
  path = d3.geo.path!
    ..projection projection

  container = d3.select ig.containers.base
  svg = container.append \svg
    ..attr \width width
    ..attr \height height
  svg.append \path
    ..attr \class \land
    ..datum land
    ..attr \d path
  svg.append \path
    ..attr \class \countries
    ..datum topojson.mesh world, world.objects.countries, (a, b) -> a isnt b
    ..attr \d path

if d3?
  init!
else
  $ window .bind \load ->
    if d3?
      init!
