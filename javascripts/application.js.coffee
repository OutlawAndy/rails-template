#= require jquery
#= require bower_components
#= require_self
#= require re_anim_frame



@wrapPage = ->
  innerHeight = window.innerHeight
  innerWidth = window.innerWidth
  $('.desktop-sidebar').css 'height', innerHeight
  $('#index-wrapper').css 'height', innerHeight
  $('#index-wrapper').css 'width', innerWidth - 213
  $('body.player-view #index-wrapper').css 'width', innerWidth - 74
  $('body.cert-view #index-wrapper').css 'width', innerWidth
  $('#drawer-container').css 'width', innerWidth # + 250
  $('.main-content').css 'width', innerWidth


$ ->
  wrapPage()

  $('div.dropdown').dropdown()

  $(window).on "orientationchange", ->
    wrapPage()

  $(window).on "resize", ->
    wrapPage()

  window.setTimeout ->
    $('.leaveUpAfter10').addClass('fadeOutUp')
    window.setTimeout ->
      $('.leaveUpAfter10').remove()
    , 2000
  , 5000


_.mixin({
  'snakeCase': (data) ->
    this.filter = (key) ->
       (""+key).replace( /([A-Z])/g, (cap) -> "_"+cap.toLowerCase() ).replace(/-/,"_")
    recurse = (object) ->
      return object unless angular.isObject(object)
      return _.forEach(object, recurse()) if angular.isArray(object)
      _.transform _.pairs(object), (res,tup) =>
        res[this.filter(tup[0])] = recurse(tup[1])
      , {}
    angular.toJson(recurse angular.fromJson(data))
  , 'camelCase': (data) ->
    this.filter = (key) ->
      (""+key).replace(/(_)([a-z])/g, (match,dash,low) -> low.toUpperCase())
    recurse = (object) ->
      return object unless angular.isObject(object)
      return _.map(object, recurse) if angular.isArray(object)
      _.transform _.pairs(object), (res,tup) =>
        res[this.filter(tup[0])] = recurse(tup[1])
      , {}
    if angular.isArray(data) then _.map(data, recurse) else recurse(data)
})

String.prototype.capitalize = ->
  this.charAt(0).toUpperCase() + this.slice(1)