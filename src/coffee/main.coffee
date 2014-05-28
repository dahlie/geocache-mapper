$ 			      = require 'jquery'
_             = require 'lodash'
_str          = require 'underscore.string'
q             = require 'q'
leaflet       = require 'leaflet'
leafletlabel  = require 'leaflet.label'
transparency  = require 'transparency'

readFile     = require './filereader.coffee'

_.mixin _str.exports()

map                = null
layers             = null
currentLayer       = null
overlays           = null
targets            = null
markers            = { }
selectedCategories = null

$search            = null
$popupTemplate     = null

$ ->
  createMap()

  # selecting target from list
  $('#search-results ul').on 'click', 'a', (e) -> panTo $(e.currentTarget).data 'id'

  # search update
  $search = $ '#search input'
  $search.on 'change paste keyup', _.throttle updateSearchResults, 200

  $popupTemplate = $ '#popup-template > div'

  # layer change
  $('.navbar .nav a').on 'click', (e) -> selectLayer e.target.dataset.type

  # use our own 'read file' button
  $openFile = $ '#overlay .btn'
  $files    = $ '#overlay #files'
  $openFile.on 'click', -> $files.click()

  # user selected a file to read
  $('#overlay #files').on 'change', (e) -> readFiles e.target.files    

  # drag'n'drop support
  dropZone = $('body')
  dropZone.on 'dragover', (e) ->
    e.stopPropagation()
    e.preventDefault()
    e.originalEvent.dataTransfer.dropEffect = 'copy'

  dropZone.on 'drop', (e) -> 
    console.log e
    e.stopPropagation()
    e.preventDefault()
    readFiles e.originalEvent.dataTransfer.files

readFiles = (files) ->
  q.all(_.map files, readFile)
   .then (results) ->
      targets = _.flatten results

      # create markers and hide overlay
      markers = createMarkers targets
      hideOverlay()

      updateSearchResults targets, '', selectedCategories

createMarkers = (targets) ->
  ids     = _.pluck targets, 'id'
  zipped  = {}

  # group markers by category and add them on separate layers
  categories = _.groupBy targets, 'luokittelu'
  overlays   = _.reduce _.keys(categories), (acc, key) ->
    group = new L.LayerGroup()
    _.forEach categories[key], (t) ->
      zipped[t.id] = new L.Marker(t.location, riseOnHover: true)
        .bindLabel(t.nimi)
        .bindPopup(createPopupFor(t), minWidth: 500, maxWidth: 500)
        .addTo(group)
        .on 'click', (e) -> map.panTo e.target.getLatLng()


    group.addTo map
    acc[key] = group
    acc
  , { }

  # by default all categories are selected
  selectedCategories = _.keys overlays
  $('#categories').show().find('ul').render selectedCategories, 'category-name': text: -> @.value
  $('#categories ul a').on 'click', toggleLayer
  zipped

createPopupFor = (target) ->
  popup = $popupTemplate.clone().show()
  popup.render target,
    'lat': text: -> _.numberFormat @.location[0], 4
    'lng': text: -> _.numberFormat @.location[1], 4
  popup[0]

toggleLayer = (e) ->
  name = e.currentTarget.text
  $(@).toggleClass 'selected'

  # show or hide categories
  if map.hasLayer overlays[name]
    _.pull selectedCategories, name
    map.removeLayer overlays[name]
  else
    map.addLayer overlays[name]
    selectedCategories.push name

  updateSearchResults()

updateSearchResults = ->
  show = (target) ->
    $(markers[target.id]._icon).removeClass 'hidden'
    $(markers[target.id]._shadow).removeClass 'hidden'
  hide = (target) ->
    $(markers[target.id]._icon).addClass 'hidden'
    $(markers[target.id]._shadow).addClass 'hidden'

  # first hide all markers
  _.forEach targets, hide

  # then show markers that match search criteria
  visible = _.filter targets, matches $search.val().toLowerCase(), selectedCategories
  _.forEach visible, show

  # update results to list
  directives =
    'list-group-item':
      'data-id': -> @.id

  if _.isEmpty visible
    $('#no-search-results').show()
    $('#search-results ul').hide()
  else
    $('#no-search-results').hide()
    $('#search-results ul').show().render visible, directives

matches = (search, categories) -> (target) ->
  return false unless _.contains categories, target.luokittelu

  _.isEmpty(search) or
  _str.include(target.nimi.toLowerCase(), search) or
  _str.include(target.kuvaus.toLowerCase(), search)

hideOverlay = ->
  $('#overlay').hide()
  $('#search-results').show()

panTo = (id) ->
  map.panTo markers[id].getLatLng()
  markers[id].openPopup()

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
  selectLayer 'openStreetMap'

selectLayer = (name) ->
  layer = layers[name]
  map.addLayer layer, true 
  map.removeLayer currentLayer if currentLayer?
  currentLayer = layer
