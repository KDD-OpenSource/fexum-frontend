app.controller 'AnalysisCtrl', [
  '$scope',
  '$timeout',
  '$analytics'
  ($scope, $timeout, $analytics) ->

    if $scope.dataset? and $scope.targetFeature?
      $analytics.eventTrack 'analyzeFeatures', {
        category: 'd' + $scope.dataset.name + 't' + $scope.targetFeature.name
        label: $scope.selectedFeatures.map((f) -> f.name).join '|'
      }

    $scope.selectedRanges = {}

    updateSelectedRangeForFeature = (featureId) ->
      slider = $scope.sliders[featureId]
      range = [slider.minValue, slider.maxValue]
      $scope.selectedRanges[featureId] = range

    sliderWatches = []

    watchSlider = (featureId) ->
      watchVariables = ["sliders['#{featureId}'].minValue", "sliders['#{featureId}'].maxValue"]
      return $scope.$watchGroup watchVariables, ->
        updateSelectedRangeForFeature featureId

    $scope.$watch 'features', (features) ->
      if features?
        # Clear current watches
        sliderWatches.forEach (unregisterWatch) ->
          unregisterWatch()
        sliderWatches.length = 0

        # Create sliders
        $scope.sliders = {}
        $scope.selectedFeatures.forEach (feature) ->
          $scope.sliders[feature.id] =
            minValue: feature.min
            minValueFnc: (newValue) ->
              if newValue?
                return @minValue = Math.max newValue, feature.min
              else
                return @minValue
            maxValue: feature.max
            maxValueFnc: (newValue) ->
              if newValue?
                return @maxValue = Math.min newValue, feature.max
              else
                return @maxValue
            options:
              floor: feature.min
              ceil: feature.max
              step: (feature.max - feature.min) / 100
              precision: 4
              noSwitching: true
          updateSelectedRangeForFeature feature.id
          sliderWatches.push watchSlider feature.id

        # Bugfix for rzslider, where initial values were not drawn
        $timeout (-> $scope.$broadcast 'rzSliderForceRender'), 1000

    $scope.getSlider = (feature) ->
      if $scope.sliders?
        return $scope.sliders[feature.id]
      return {}

    $scope.updateFromSlice = (slice) ->
      # Rest all sliders first
      $scope.selectedFeatures
        .map (feature) -> $scope.sliders[feature.id]
        .forEach (slider) ->
          slider.minValue = slider.options.floor
          slider.maxValue = slider.options.ceil

      analyticsLabel = []
      # Then set from slice
      slice.features.forEach (feature) ->
        name = $scope.featureIdMap[feature.feature].name
        analyticsLabel.push name + '=[' + feature.range[0] + ',' + feature.range[1] + ']'

        slider = $scope.sliders[feature.feature]
        slider.minValue = feature.range[0]
        slider.maxValue = feature.range[1]

      # Only send analytics if name was found for every feature (otherwise data is useless)
      $analytics.eventTrack 'recommendedSliceSelected', {
        category: 'd' + $scope.dataset.name + 't' + $scope.targetFeature.name
        label: analyticsLabel.join '|'
      }

    return
]
