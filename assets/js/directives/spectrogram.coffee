app.directive 'spectrogram', [
  'backendService',
  (backendService) ->
    return {
      restrict: 'E'
      template: JST['assets/templates/spectrogram']
      scope:
        feature: '='
      link: (scope, element, attrs) ->

        return
    }
]
