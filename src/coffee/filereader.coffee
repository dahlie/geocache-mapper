_      = require 'lodash'
proj4  = require 'proj4'

ETRS  = '+proj=utm +zone=35 +ellps=GRS80 +units=m +no_defs'
WGS84 = '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs '

module.exports = (file, cb) ->
  reader = new FileReader()
  reader.onload = (e) ->
    targets = _.map JSON.parse(e.target.result), (t) ->
      t.id       = _.uniqueId()
      t.location = proj4(ETRS, WGS84, [t.itainen, t.pohjoinen]).reverse()
      t

    cb targets

  reader.readAsText file

