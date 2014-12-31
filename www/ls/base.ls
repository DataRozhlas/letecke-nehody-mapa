init = ->
  {world} = ig.data
  land = topojson.feature world, world.objects."land"
  width = 1000
  height = 650
  projection = d3.geo.mercator!
    ..scale width / (Math.PI * 2)
    ..translate [width / 2, 350]
  path = d3.geo.path!
    ..projection projection

  container = d3.select ig.containers.base
  svg = container.append \svg
    ..attr \class \map
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

  r = d3.scale.sqrt!
    ..domain [0 484]
    ..range [1 10]

  airports = d3.tsv.parse ig.data.airports, (row)->
    row.lon = parseFloat row.x
    row.lat = parseFloat row.y
    row.fatalities = parseInt row.fatalities, 10
    coords = projection [row.lon, row.lat]
    row.cx = coords.0
    row.cy = coords.1
    row.r = r row.fatalities
    row
  # range = ['rgb(255,245,240)','rgb(254,224,210)','rgb(252,187,161)','rgb(252,146,114)','rgb(251,106,74)','rgb(239,59,44)','rgb(203,24,29)','rgb(165,15,21)','rgb(103,0,13)']
  # len = airports.length
  # step = Math.floor len / (range.length - 2)
  # airports.sort (a, b) -> b.fatalities - a.fatalities
  # bands = for i in [0 to len by step]
  #   airports[i].fatalities
  # bands.push 0
  # fill = d3.scale.linear!
  #   ..domain bands.reverse!
  #   ..range range
  svg.append \g .attr \class \airports-bg
    .selectAll \circle .data airports .enter!append \circle
      ..attr \r -> r it.fatalities
      ..attr \cx (.cx)
      ..attr \cy (.cy)
  svg.append \g .attr \class \airports
    .selectAll \circle .data airports .enter!append \circle
      ..attr \r (.r)
      ..attr \cx (.cx)
      ..attr \cy (.cy)

  voronoi = d3.geom.voronoi!
    ..x ~> it.cx
    ..y ~> it.cy
    ..clipExtent [[0, 0], [width, height - 100]]
  voronoiPolygons = voronoi airports

  graphTip = new ig.GraphTip container

  container.append \svg
    ..attr \class \voronoi
    ..attr \width width
    ..attr \height height
    ..selectAll \path .data voronoiPolygons .enter!append \path
      ..attr \d -> "M#{it.join "L"}Z"
      ..on \mouseover ({point}) ->
        text = "<h2>#{point.name}<h2>"
        text += "<h3>#{point.city}, #{point.country}</h3>"
        text += "<p>Celkem <b>#{point.fatalities}</b> obětí</p>"
        graphTip.display point.cx, point.cy - point.r, text
      ..on \mouseout ->
        graphTip.hide!

if d3?
  init!
else
  $ window .bind \load ->
    if d3?
      init!
