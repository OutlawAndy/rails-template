#= require jquery
#= require bower_components
#= require turbolinks
#= require_self
#= require re_anim_frame


_.mixin({
  'snakeCase': (data) ->
    _filter_ = (key) ->
       (""+key).replace( /([A-Z])/g, (cap) -> "_"+cap.toLowerCase() ).replace(/-/,"_")
    recurse = (object) ->
      return object unless angular.isObject(object)
      return _.forEach(object, recurse()) if angular.isArray(object)
      _.transform _.pairs(object), (res,tup) ->
        res[_filter_(tup[0])] = recurse(tup[1])
      , {}
    angular.toJson(recurse angular.fromJson(data))
  , 'camelCase': (data) ->
    _filter_ = (key) ->
      (""+key).replace(/(_)([a-z])/g, (match,dash,low) -> low.toUpperCase())
    recurse = (object) ->
      return object unless angular.isObject(object)
      return _.map(object, recurse) if angular.isArray(object)
      _.transform _.pairs(object), (res,tup) ->
        res[_filter_(tup[0])] = recurse(tup[1])
      , {}
    if angular.isArray(data) then _.map(data, recurse) else recurse(data)
})
