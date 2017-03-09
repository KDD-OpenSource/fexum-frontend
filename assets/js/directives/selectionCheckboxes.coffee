app.directive 'selectionCheckboxes', [
  '$timeout',
  '$q',
  'backendService',
  'scopeUtils',
  ($timeout, $q, backendService, scopeUtils) ->

    return {
      restrict: 'E'
      template: JST['assets/templates/selectionCheckboxes']
      scope:
        selectedRanges: '='
        feature: '='
      link: (scope, element, attrs) ->

        scope.isChecked = (category) ->
          range = scope.selectedRanges[scope.feature.id]
          if range? and range[category]?
            return range[category]
          return false

        scope.isDisabled = (category) ->
          return scope.selectedRanges[scope.feature.id]? and
            (v for own k, v of scope.selectedRanges[scope.feature.id] when v).length <= 1 and
            scope.selectedRanges[scope.feature.id][category] == true

    }
]