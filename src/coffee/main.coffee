$ 			 = require 'jquery'
_        = require 'lodash'
proj4    = require 'proj4'
leaflet  = require 'leaflet'

map           = null
layerControl  = null
targets       = null

ETRS  = '+proj=utm +zone=35 +ellps=GRS80 +units=m +no_defs'
WGS84 = '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs '

$ ->
  createMap()
  registerLayerHandlers()
  registerFileHandler()

registerLayerHandlers = ->
  $tabs = $ '.navbar .nav a'

  $tabs.on 'click', (e) ->
    selectLayer e.target.dataset.type

registerFileHandler = ->
  $openFile = $ '#overlay .btn'
  $files    = $ '#overlay #files'

  # register listener for read file button
  $openFile.on 'click', -> $files.click()

  $('#overlay #files').on 'change', (e) -> readFile e.target.files[0]

readFile = (file) ->
    reader = new FileReader()
    reader.onload = (e) ->
      targets = eval e.target.result
      drawMarkers targets
      hideOverlay()

    reader.readAsText file

drawMarkers = (targets) ->
  targets.forEach (t) ->
    location = proj4 ETRS, WGS84, [t.itainen, t.pohjoinen]
    marker = new L.Marker location.reverse(),
      riseOnHover: true
      title:       t.nimi

    marker.addTo map

hideOverlay = ->
  $('#overlay').hide()

createMap = ->
  L.Icon.Default.imagePath = '/images'

  layers =
    basic: L.tileLayer 'http://{s}.kartat.kapsi.fi/peruskartta/{z}/{x}/{y}.png',
      attribution: 'Kartta: Maanmittauslaitos'
      maxZoom:     18
      subdomains:  ['tile1', 'tile2']

    background: L.tileLayer 'http://{s}.kartat.kapsi.fi/taustakartta/{z}/{x}/{y}.png',
      attribution: 'Kartta: Maanmittauslaitos'
      maxZoom:     18
      subdomains:  ['tile1', 'tile2']

    orto: L.tileLayer 'http://{s}.kartat.kapsi.fi/ortokuva/{z}/{x}/{y}.png',
      attribution: 'Kartta: Maanmittauslaitos'
      maxZoom:     18
      subdomains:  ['tile1', 'tile2']

    openStreetMap: L.tileLayer 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap.org</a>'
      maxZoom:     18

  map = L.map 'map',
    center:  new L.LatLng(61.5000, 23.7667)
    zoom:    9
    maxZoom: 18

  layerControl = L.control.layers layers, null, collapsed: false
  layerControl.addTo map
  selectLayer 'basic'

selectLayer = (layer) ->
  $input = $ ".leaflet-control-layers label:contains(#{layer}) input"
  $input.click()
