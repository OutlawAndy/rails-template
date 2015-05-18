template = """
<div id="drawer-opener" class="drawer-handle" ng-click="slideDrawer()" ng-class="{'is-closed': isClosed, 'is-open': !isClosed}">
  <div class="line-icon">
    <div class="line-container">
      <span class="line-top"></span>
      <span class="line-mid"></span>
      <span class="line-bot"></span>
    </div>
  </div>
  <div class="line-ring">
    <svg class="svg-ring">
      <path class="path" fill="none" stroke="white" stroke-miterlimit="10" stroke-width="4" d="M 34 2 C 16.3 2 2 16.3 2 34 s 14.3 32 32 32 s 32 -14.3 32 -32 S 51.7 2 34 2" />
    </svg>
  </div>
  <div class="path-line">
    <div class="animate-path">
      <div class="path-rotation"></div>
    </div>
  </div>
  <svg width="0" height="0"><mask id="mask">
    <path xmlns="http://www.w3.org/2000/svg" fill="none" stroke="#ff0000" stroke-miterlimit="10" stroke-width="4" d="M 34 2 c 11.6 0 21.8 6.2 27.4 15.5 c 2.9 4.8 5 16.5 -9.4 16.5 h -4" /></mask>
  </svg>
</div>
"""

angular.module('side.drawer',[]).directive 'drawerHandle', ->
  restrict: 'E'
  replace: true
  template: template
  link: (scope, el, attrs) ->
    scope.isClosed = true
    scope.slideDrawer = ->
      if scope.isClosed
        e = new CustomEvent('drawerShouldOpen', {
          bubbles: true,
          cancelable: true
        });
        $(el)[0].dispatchEvent(e)
        scope.isClosed = false
        scope.$apply
      else
        e = new CustomEvent('drawerShouldClose', {
          bubbles: true,
          cancelable: true
        });
        $(el)[0].dispatchEvent(e)
        scope.isClosed = true
        scope.$apply
      return
    $(document.body).on "drawerDidSlide", (e) ->
      switch e.originalEvent.detail.sideDrawer
        when 'open'
          scope.isClosed = false
          scope.$apply()
        when 'closed'
          scope.isClosed = true
          scope.$apply()