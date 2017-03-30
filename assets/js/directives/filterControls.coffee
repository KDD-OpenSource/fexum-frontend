app.directive 'filterControls', [
  'scopeUtils',
  (scopeUtils) ->
    return {
      restrict: 'E'
      template: JST['assets/templates/filterControls']
      scope:
        features: '='
      link: (scope, element, attrs) ->
        return
    }
]