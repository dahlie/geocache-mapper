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

  # selecting target from list
  $('#search-results ul').on 'click', 'a', (e) -> panTo $(e.currentTarget).data 'id'

  # search update
  $('#search input').on 'change paste keyup', _.throttle ((e) -> updateSearchResults targets, $(@).val()), 1000

  # layer change
  $('.navbar .nav a').on 'click', (e) -> selectLayer e.target.dataset.type

  # use our own 'read file' button
  $openFile = $ '#overlay .btn'
  $files    = $ '#overlay #files'
  $openFile.on 'click', -> $files.click()

  # user selected a file to read
  $('#overlay #files').on 'change', (e) ->
    file = e.target.files[0]
    readFile file, (results) ->
      targets = results

      # create markers and hide overlay
      markers = createMarkers targets
      hideOverlay()

      updateSearchResults targets, ''

createMarkers = (targets) ->
  ids     = _.pluck targets, 'id'
  markers = _.map targets, (t) ->
    new L.Marker t.location,
      riseOnHover: true
      title:       t.nimi

  _.forEach markers, (m) ->
    #m.addClass '.hidden'
    m.addTo map

  _.zipObject ids, markers

updateSearchResults = (targets, search) ->
  console.log 'searching', search
  show = (target) -> $(markers[target.id]._icon).removeClass '.hidden'
  hide = (target) -> $(markers[target.id]._icon).addClass '.hidden'

  # first hide all markers
  _.forEach targets, hide

  # then show markers that match search criteria
  visible = _.filter targets, matches search
  _.forEach visible, show

  # update results to list
  directives =
    'list-group-item':
      'data-id': -> @.id

  $('#search-results ul').render visible, directives

matches = (search) -> (target) ->
  console.log target, search
  true

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
