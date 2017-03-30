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

          formatter = d3.format '.5g'

          scope.slider =
              minValueFnc: (newValue) ->
                if newValue?
                  newValue = Math.max newValue, scope.feature.min
                  return scope.selectedRanges[scope.feature.id][0] = newValue
                else
                  return scope.selectedRanges[scope.feature.id][0]
              maxValueFnc: (newValue) ->
                if newValue?
                  newValue = Math.min newValue, scope.feature.max
                  return scope.selectedRanges[scope.feature.id][1] = newValue
                else
                  return scope.selectedRanges[scope.feature.id][1]
              options:
                floor: scope.feature.min
                ceil: scope.feature.max
                step: (scope.feature.max - scope.feature.min) / 100
                precision: 5
                noSwitching: true
                enforceStep: false
                translate: (value, sliderId, label) -> formatter value

          initialRange = [scope.feature.min, scope.feature.max]
          scope.selectedRanges[scope.feature.id] = initialRange

          # Bugfix for rzslider, where initial values were not drawn
          $timeout (-> scope.$broadcast 'rzSliderForceRender'), 1000
        }

    }
]
