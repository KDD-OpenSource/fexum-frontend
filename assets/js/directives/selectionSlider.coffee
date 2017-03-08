app.directive 'selectionSlider', [
  '$timeout',
  '$q',
  'backendService',
  'scopeUtils',
  ($timeout, $q, backendService, scopeUtils) ->

    return {
      restrict: 'E'
      template: JST['assets/templates/selectionSlider']
      scope:
        sliders: '='
        feature: '='
      link: (scope, element, attrs) ->

        scope.getSlider = ->
          if scope.sliders?
            return scope.sliders[scope.feature.id]
          return {}

    }
]