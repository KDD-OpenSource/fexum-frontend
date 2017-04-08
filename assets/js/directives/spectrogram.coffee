app.directive 'spectrogram', [
  'backendService',
  'scopeUtils',
  (backendService, scopeUtils) ->
    return {
      restrict: 'E'
      template: JST['assets/templates/spectrogram']
      scope:
        feature: '='
      link: (scope, element, attrs) ->
        featureAvailable = scopeUtils.waitForVariableSet scope, 'feature.id'
        featureAvailable.then ->
          return backendService.retrieveSpectrogram scope.feature.id
        .then (spectrogram) ->
          scope.image_url = spectrogram.image_url
    }
]
