$ 			     = require 'jquery'
_            = require 'lodash'
leaflet      = require 'leaflet'
transparency = require 'transparency'

readFile     = require './filereader.coffee'

map           = null
layerControl  = null
targets       = null
markers       = { }

$ ->
  createMap()
  registerHandlers()

  $('#search-results ul').on 'click', 'a', (e) ->
    panTo $(e.currentTarget).data 'id'

registerHandlers = ->
  # navigation bar
  $tabs = $ '.navbar .nav a'
  $tabs.on 'click', (e) -> selectLayer e.target.dataset.type

  # file
  $openFile = $ '#overlay .btn'
  $files    = $ '#overlay #files'

  # register listener for read file button
  $openFile.on 'click', -> $files.click()

  $('#overlay #files').on 'change', (e) ->
    file = e.target.files[0]
    readFile file, (targets)->
      drawMarkers targets
      updateSearchResults targets
      hideOverlay()

drawMarkers = (targets) ->
  targets.forEach (t) ->
    marker = new L.Marker t.location,
      riseOnHover: true
      title:       t.nimi

    markers[t.id] = marker
    marker.addTo map

updateSearchResults = (targets) ->
  directives =
    'list-group-item':
      'data-id': -> @.id

  $('#search-results ul').render targets, directives

hideOverlay = ->
  $('#overlay').hide()

panTo = (id) ->
  map.panTo markers[id].getLatLng()

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
