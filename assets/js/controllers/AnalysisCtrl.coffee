app.controller 'AnalysisCtrl', [
  '$scope',
  '$timeout',
  '$analytics'
  ($scope, $timeout, $analytics) ->

    if $scope.dataset? and $scope.targetFeature?
      $analytics.eventTrack 'analyzeFeatures', {
        category: 'd' + $scope.dataset.id + 't' + $scope.targetFeature.id
        label: $scope.selectedFeatures.map((f) -> f.id).join '|'
      }

    $scope.selectedRanges = {}
    $scope.sliders = {}

    $scope.updateFromSlice = (slice) ->
      # Rest all sliders first
      $scope.selectedFeatures.forEach (feature) ->
        if feature.is_categorical
          for c in feature.categories
            $scope.selectedRanges[feature.id][c] = true
        else
          slider = $scope.sliders[feature.id]
          slider.minValue = slider.options.floor
          slider.maxValue = slider.options.ceil

      analyticsLabel = []
      # Then set from slice
      slice.features.forEach (feature) ->
        if feature.is_categorical
          $scope.selectedRanges[feature.id] = {}
          for c in feature.range
            $scope.selectedRanges[feature.id][c] = feature.range
        else
          analyticsLabel.push feature.feature + '=[' +
            feature.range[0] + ',' + feature.range[1] + ']'

          slider = $scope.sliders[feature.feature]
          if slider?
            slider.minValue = feature.range[0]
            slider.maxValue = feature.range[1]

      $analytics.eventTrack 'recommendedSliceSelected', {
        category: 'd' + $scope.dataset.id + 't' + $scope.targetFeature.id
        label: analyticsLabel.join '|'
      }

    updateSelectedRangeForFeature = (featureId) ->
      if $scope.sliders[featureId]?
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
        $scope.selectedFeatures.forEach (feature) ->
          if feature.is_categorical
            $scope.selectedRanges[feature.id] = {}
            for c in feature.categories
              $scope.selectedRanges[feature.id][c] = true
          else
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
                enforceStep: false
            updateSelectedRangeForFeature feature.id
            sliderWatches.push watchSlider feature.id

        # Bugfix for rzslider, where initial values were not drawn
        $timeout (-> $scope.$broadcast 'rzSliderForceRender'), 1000

    return
]
