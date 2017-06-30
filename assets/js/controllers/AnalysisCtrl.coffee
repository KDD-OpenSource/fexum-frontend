app.controller 'AnalysisCtrl', [
  '$scope',
  '$timeout',
  '$analytics',
  'scopeUtils',
  'backendService',
  ($scope, $timeout, $analytics, scopeUtils, backendService) ->

    logAnalytics = ->
      $analytics.eventTrack 'analyzeFeatures', {
        category: 'd' + $scope.datasetId + 't' + $scope.targetFeatureId
        label: $scope.selectedFeatures.map((f) -> f.id).join '|'
      }

    scopeUtils.waitForVariableSet $scope, 'selectedFeatures'
      .then ->
        logAnalytics()
        return backendService.getExperiment()
      .then (experiment) ->
        selectedFeatureIds = $scope.selectedFeatures.map (feature) -> feature.id
        experiment.requestFeatureSelectionForSubset selectedFeatureIds

    $scope.selectedRanges = {}

    $scope.updateFromSlice = (slice) ->
      # Reset all values first
      $scope.selectedFeatures.forEach (feature) ->
        if feature.is_categorical
          for c in feature.categories
            $scope.selectedRanges[feature.id][c] = true
        else
          $scope.selectedRanges[feature.id] = [feature.min, feature.max]
        return

      analyticsLabel = []
      # Then set from slice
      slice.features.forEach (filter) ->
        feature = $scope.featureIdMap[filter.feature]
        if filter.categories?
          $scope.selectedRanges[feature.id] = {}

          for category in feature.categories
            isCategoryContained = category in filter.categories
            $scope.selectedRanges[feature.id][category] = isCategoryContained

          analyticsLabel.push feature.id + '=[' +
            filter.categories.join(',') + ']'
        else
          $scope.selectedRanges[feature.id] = angular.copy filter.range

          analyticsLabel.push feature.id + '=[' +
            filter.range.join(',') + ']'

      $analytics.eventTrack 'recommendedSliceSelected', {
        category: 'd' + $scope.dataset.id + 't' + $scope.targetFeature.id
        label: analyticsLabel.join '|'
      }


    return
]
