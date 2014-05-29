_      = require 'lodash'
q      = require 'q'
proj4  = require 'proj4'

ETRS  = '+proj=utm +zone=35 +ellps=GRS80 +units=m +no_defs'
WGS84 = '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs '

FIELDS = [
  'pohjoinen'
  'itainen',
  'paikkakunta'
  'tarkenne1'
  'tarkenne2'
  'luokittelu'
  'varmuus'
  'kiinnostavuus'
  'nimi'
  'kuvaus'
]

read = (cb) -> (file) ->
  try
    cb file
  catch e
    return null

readJSON = read (file) -> JSON.parse file
readCSV  = read (file) -> _.map file.split('\n'), (line) -> _.zipObject FIELDS, line.split ';'

module.exports = (file) ->
  reader   = new FileReader()
  deferred = q.defer()
  
  reader.onload = (e) ->
    data  = readJSON e.target.result
    data  = data or readCSV e.target.result

    targets = _.map data, (t) ->
      t.id       = _.uniqueId()
      t.nimi     = t.nimi or 'tuntematon'
      t.location = proj4(ETRS, WGS84, [t.itainen, t.pohjoinen]).reverse()
      t

    deferred.resolve targets

  reader.readAsText file

  deferred.promise

