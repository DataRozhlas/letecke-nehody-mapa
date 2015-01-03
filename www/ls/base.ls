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

  container = d3.select ig.containers.base .append \div
    ..attr \class \container
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
  aptCircles = svg.append \g .attr \class \airports-bg
    .selectAll \circle .data airports .enter!append \circle
      ..attr \r -> r it.fatalities
      ..attr \cx (.cx)
      ..attr \cy (.cy)
  aptCircleBgs = svg.append \g .attr \class \airports
    .selectAll \circle .data airports .enter!append \circle
      ..attr \r (.r)
      ..attr \cx (.cx)
      ..attr \cy (.cy)

  activeApt = svg.append \circle
    ..attr \class "airport-active disabled"

  voronoi = d3.geom.voronoi!
    ..x ~> it.cx
    ..y ~> it.cy
    ..clipExtent [[0, 0], [width, height - 100]]
  voronoiPolygons = voronoi airports

  graphTip = new ig.GraphTip container

  voronoiSvg = container.append \svg
    ..attr \class \voronoi
    ..attr \width width
    ..attr \height height
    ..selectAll \path .data voronoiPolygons .enter!append \path
      ..attr \d -> "M#{it.join "L"}Z"
      ..on \mouseover ({point}) ->
        text = "<h2>#{point.name}<h2>"
        text += "<h3>#{point.city}, #{point.country}</h3>"
        text += "<p>Celkem <b>#{point.fatalities}</b> obětí</p>"
        [x, y] = getPointDisplayedCenter point
        graphTip.display x, y, text
        activeApt
          ..datum point
          ..attr \r point.r / Math.sqrt zoomAmount
          ..attr \cx point.cx
          ..attr \cy point.cy
          ..classed \disabled no
      ..on \mouseout ->
        activeApt.classed \disabled yes
        graphTip.hide!
      ..on \click ({point}) ->
        console.log point
        zoomTo point.lat, point.lon
  nonZoomCenter = projection [0, 0]
  zoomCenter = null
  zoomAmount = 1
  zoomTranslation = null
  zoomTo = (lat, lon) ->
    backbutton.classed \hidden no
    coords = projection [lon, lat]
    zoomCenter := coords
    zoom = 8
    zoomAmount := zoom
    tX = width / 2 - coords.0
    tY = height / 2 - coords.1
    zoomTranslation := [tX, tY]
    for elm in [svg, voronoiSvg]
      elm.style \transform "scale(#zoom) translate(#{tX}px, #{tY}px)"
      elm.classed \zoomed yes
    zoomSqrt = Math.sqrt zoom
    aptCircles.attr \r -> it.r / zoomSqrt
    aptCircleBgs.attr \r -> it.r / zoomSqrt

  zoomOut = ->
    backbutton.classed \hidden yes
    nonZoomCenter := projection [0, 0]
    zoomCenter := null
    zoomAmount := 1
    zoomTranslation := null
    for elm in [svg, voronoiSvg]
      elm.style \transform ""
      elm.classed \zoomed no
    aptCircles.attr \r -> it.r
    aptCircleBgs.attr \r -> it.r


  getPointDisplayedCenter = (point) ->
    out = [point.cx, point.cy]
    if zoomCenter
      out.0 = (width  / 2) + (zoomAmount * ((out.0 + zoomTranslation.0) - (width  / 2)))
      out.1 = (height / 2) + (zoomAmount * ((out.1 + zoomTranslation.1) - (height / 2)))
    out.1 -= zoomAmount * point.r / Math.sqrt zoomAmount
    out

  backbutton = ig.utils.backbutton container
    ..on \click zoomOut
    ..attr \class "backbutton backbutton-map hidden"

if d3?
  init!
else
  $ window .bind \load ->
    if d3?
      init!
