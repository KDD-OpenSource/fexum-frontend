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
        scope.selectedRanges[scope.feature.id] = {}
        for c in scope.feature.categories
          scope.selectedRanges[scope.feature.id][c] = true

        scope.isDisabled = (category) ->
          return (v for own k, v of scope.selectedRanges[scope.feature.id] when v).length <= 1 and
            scope.selectedRanges[scope.feature.id][category] == true

    }
]