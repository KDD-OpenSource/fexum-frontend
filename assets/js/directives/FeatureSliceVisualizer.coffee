app.directive 'featureSliceVisualizer', ->
  return {
    restrict: 'E'
    template: JST['assets/templates/featureSliceVisualizer']
    scope:
      feature: '='
      range: '='
      close: '&onClose'
    link: (scope, element, attrs) ->
      return
  }
