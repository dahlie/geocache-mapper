$ 			      = require 'jquery'
_             = require 'lodash'
_str          = require 'underscore.string'
leaflet       = require 'leaflet'
leafletlabel  = require 'leaflet.label'
transparency  = require 'transparency'

readFile     = require './filereader.coffee'

_.mixin _str.exports()

map           = null
layers        = null
overlays      = null
targets       = null
markers       = { }

$ ->
  createMap()

  # selecting target from list
  $('#search-results ul').on 'click', 'a', (e) -> panTo $(e.currentTarget).data 'id'

  # search update
  $('#search input').on 'change paste keyup', _.throttle ((e) -> updateSearchResults targets, $(@).val().toLowerCase()), 200

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
  zipped  = {}

  # group markers by category and add them on separate layers
  categories = _.groupBy targets, 'luokittelu'
  overlays   = _.reduce _.keys(categories), (acc, key) ->
    group = new L.LayerGroup()
    _.forEach categories[key], (t) ->
      marker = new L.Marker(t.location, riseOnHover: true).bindLabel(t.nimi).addTo(group)
      zipped[t.id] = marker
    group.addTo map
    acc[key] = group
    acc
  , { }

  $('#categories ul').render _.keys(overlays), 'category-name': text: -> @.value
  $('#categories ul a').on 'click', toggleLayer
  zipped

toggleLayer = (e) ->
  name = e.currentTarget.text
  $(@).toggleClass 'selected'
  if map.hasLayer overlays[name]
    map.removeLayer overlays[name]
  else
    map.addLayer overlays[name]

updateSearchResults = (targets, search) ->
  show = (target) ->
    $(markers[target.id]._icon).removeClass 'hidden'
    $(markers[target.id]._shadow).removeClass 'hidden'
  hide = (target) ->
    $(markers[target.id]._icon).addClass 'hidden'
    $(markers[target.id]._shadow).addClass 'hidden'

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
  _.isEmpty(search) or
  _str.include(target.nimi.toLowerCase(), search) or
  _str.include(target.kuvaus.toLowerCase(), search)

hideOverlay = ->
  $('#overlay').hide()
  $('#search-results').show()

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
    zoom:        9
    maxZoom:     18
    zoomControl: false

  new L.Control.Zoom(position: 'bottomright').addTo map
  layers.basic.addTo map

selectLayer = (layer) ->
  $input = $ ".leaflet-control-layers label:contains(#{layer}) input"
  $input.click()
