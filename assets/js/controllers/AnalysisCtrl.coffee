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

    $scope.updateFromSlice = (slice) ->
      # Reset all values first
      $scope.selectedFeatures.forEach (feature) ->
        if feature.is_categorical
          for c in feature.categories
            $scope.selectedRanges[feature.id][c] = true
        else
          $scope.selectedRanges[feature.id] = [feature.min, feature.max]

      analyticsLabel = []
      # Then set from slice
      slice.features.forEach (feature) ->
        feature.id = feature.feature
        if feature.is_categorical
          $scope.selectedRanges[feature.id] = {}
          for c in feature.categories
            $scope.selectedRanges[feature.id][c] = angular.copy feature.categories

          analyticsLabel.push feature.id + '=[' +
            feature.categories.join(',') + ']'
        else
          $scope.selectedRanges[feature.id] = angular.copy feature.range

          analyticsLabel.push feature.id + '=[' +
            feature.range.join(',') + ']'

      $analytics.eventTrack 'recommendedSliceSelected', {
        category: 'd' + $scope.dataset.id + 't' + $scope.targetFeature.id
        label: analyticsLabel.join '|'
      }


    return
]
