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
        $timeout (-> $scope.$broadcast 'rzSliderForceRender'), 100

    $scope.getSlider = (feature) -> $scope.sliders[feature.id]

    return
]
