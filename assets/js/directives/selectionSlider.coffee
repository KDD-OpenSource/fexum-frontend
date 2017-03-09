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
        feature: '='
        selectedRanges: '='
      link: {
        pre: (scope, element, attrs) ->
          scope.log = (obj) ->
            console.log obj

          scope.slider =
              options:
                floor: scope.feature.min
                ceil: scope.feature.max
                step: (scope.feature.max - scope.feature.min) / 100
                precision: 4
                noSwitching: true
                enforceStep: false
          scope.selectedRanges[scope.feature.id] = [scope.feature.min, scope.feature.max]

          # Bugfix for rzslider, where initial values were not drawn
          $timeout (-> scope.$broadcast 'rzSliderForceRender'), 1000
        }

    }
]