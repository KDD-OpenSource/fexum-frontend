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

        scope.toggleCategory = (category) ->
          if category in scope.selectedRanges[scope.feature.id]
            scope.selectedRanges[scope.feature.id] =
              (c for c in scope.selectedRanges[scope.feature.id] when c isnt category)
          else
            scope.selectedRanges[scope.feature.id].push category
          console.log scope.selectedRanges[scope.feature.id]
          #console.log feature.categories

        scope.isChecked = (category) ->
          if scope.selectedRanges? and scope.selectedRanges[scope.feature.id]?
            return category in scope.selectedRanges[scope.feature.id]
          return false
    }
]