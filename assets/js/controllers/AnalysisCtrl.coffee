app.controller 'AnalysisCtrl', [
  '$scope',
  '$timeout',
  ($scope, $timeout) ->

    $scope.$watch 'features', (features) ->
      if features?
        $scope.sliders = {}
        features.forEach (feature) ->
          $scope.sliders[feature.id] =
            minValue: feature.min
            maxValue: feature.max
            options:
              floor: feature.min
              ceil: feature.max
              step: (feature.max - feature.min) / 100
              precision: 4
              noSwitching: true
        # Bugfix for rzslider, where initial values were not drawn
        $timeout (-> $scope.$broadcast 'rzSliderForceRender'), 1000

    $scope.getSlider = (feature) -> $scope.sliders[feature.id]

    $scope.updateFromSlice = (slice) ->
      # Rest all sliders first
      $scope.selectedFeatures
        .map (feature) -> $scope.sliders[feature.id]
        .forEach (slider) ->
          slider.minValue = slider.options.floor
          slider.maxValue = slider.options.ceil
      # Then set from slice
      slice.features.forEach (feature) ->
        slider = $scope.sliders[feature.feature]
        slider.minValue = feature.range[0]
        slider.maxValue = feature.range[1]

    return
]
