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

  activeAptLinkGroup = svg.append \g
    ..attr \class \active-apt-link

  aptLinkGroup = svg.append \g
    ..attr \class \apt-link

  r = d3.scale.sqrt!
    ..domain [0 484]
    ..range [1 10]

  airports = d3.tsv.parse ig.data.airports, (row)->
    row.lon = parseFloat row.x
    row.lat = parseFloat row.y
    row.fatalities = parseInt row.fatalities, 10
    row.incidents = []
    coords = projection [row.lon, row.lat]
    row.cx = coords.0
    row.cy = coords.1
    row.r = r row.fatalities
    row
  airportsAssoc = {}
  for airport in airports
    airportsAssoc[airport.code] = airport

  allEvents = d3.tsv.parse ig.data.events, (row) ->
    row.fatalities = parseInt row.fatalities, 10
    row.date = new Date!
      ..setTime 0
      ..setFullYear row.file.substr 0, 4
      ..setMonth (parseInt((row.file.substr 4, 2), 10) - 1)
      ..setDate row.file.substr 6, 2
    row

  for event in allEvents
    airportsAssoc[event.dep]?incidents.push event
    airportsAssoc[event.dest]?incidents.push event

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

  selectedApt = svg.append \circle
    ..attr \class "airport-selected disabled"

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
        drawAirportLine point
      ..on \mouseout ->
        activeApt.classed \disabled yes
        graphTip.hide!
        unDrawLines!
      ..on \click ({point}) -> onAptClick point

  nonZoomCenter = projection [0, 0]
  zoomCenter = null
  zoomAmount = 1
  zoomTranslation = null
  ig.onAptClick = onAptClick = (point) ->
    displayIncident point
    selectedApt
      ..datum point
      ..attr \r point.r / Math.sqrt zoomAmount
      ..attr \cx point.cx
      ..attr \cy point.cy
      ..classed \disabled no
    zoomTo point.lat, point.lon
    drawAirportLine point, activeAptLinkGroup

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
    svg.selectAll \circle .attr \r (.r / zoomSqrt)

  ig.zoomOut = zoomOut = ->
    backbutton.classed \hidden yes
    nonZoomCenter := projection [0, 0]
    zoomCenter := null
    zoomAmount := 1
    zoomTranslation := null
    for elm in [svg, voronoiSvg]
      elm.style \transform ""
      elm.classed \zoomed no
    svg.selectAll \circle .attr \r (.r)
    selectedApt.classed \disabled yes
    unDrawLines activeAptLinkGroup


  getPointDisplayedCenter = (point) ->
    out = [point.cx, point.cy]
    if zoomCenter
      out.0 = (width  / 2) + (zoomAmount * ((out.0 + zoomTranslation.0) - (width  / 2)))
      out.1 = (height / 2) + (zoomAmount * ((out.1 + zoomTranslation.1) - (height / 2)))
    out.1 -= zoomAmount * point.r / Math.sqrt zoomAmount
    out

  displayIncident = (point) ->
    incidentList.display point

  drawAirportLine = (apt, targetGroup) ->
    drawLine do
      apt.incidents
        .filter -> airportsAssoc[it.dep] and airportsAssoc[it.dest]
        .map -> [airportsAssoc[it.dep], airportsAssoc[it.dest]]
      targetGroup


  drawLine = (aptList, targetGroup) ->
    targetGroup ?= aptLinkGroup
    defs = for aptPair in aptList
      feature =
        type: \LineString
        coordinates: aptPair.map -> [it.lon, it.lat]
      path feature
    targetGroup.selectAll \path .remove!
    targetGroup.selectAll \path .data defs .enter!append \path
      ..attr \d -> it

  unDrawLines = (targetGroup) ->
    targetGroup ?= aptLinkGroup
    targetGroup.selectAll \path .remove!

  incidentList = new ig.IncidentList container, airportsAssoc, allEvents

  backbutton = ig.utils.backbutton container
    ..on \click zoomOut
    ..attr \class "backbutton backbutton-map hidden"


if d3?
  init!
else
  $ window .bind \load ->
    if d3?
      init!
