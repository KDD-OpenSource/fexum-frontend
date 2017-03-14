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
          scope.slider =
              minValueFnc: (newValue) ->
                if newValue?
                  return scope.selectedRanges[scope.feature.id][0] =
                    Math.max newValue, scope.feature.min
                else
                  return scope.selectedRanges[scope.feature.id][0]
              maxValueFnc: (newValue) ->
                if newValue?
                  return scope.selectedRanges[scope.feature.id][1] =
                    Math.min newValue, scope.feature.max
                else
                  return scope.selectedRanges[scope.feature.id][1]
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