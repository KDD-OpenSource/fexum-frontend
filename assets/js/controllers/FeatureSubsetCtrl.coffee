app.controller 'FeatureSubsetCtrl', [
  '$scope',
  '$stateParams',
  'scopeUtils',
  ($scope, $stateParams, scopeUtils) ->

    if $stateParams.select? or $stateParams.unselect
      scopeUtils.waitForVariableSet $scope, 'features'
        .then (features) ->
          for feature in features
            searchedName = $stateParams.select or $stateParams.unselect
            if feature.name == searchedName
              if $stateParams.select?
                $scope.select feature
              else
                $scope.unselect feature
              return

    $scope.unselect = (feature) ->
      index = $scope.selectedFeatures.indexOf feature
      $scope.selectedFeatures.splice index, 1

    $scope.select = (feature) ->
      index = $scope.selectedFeatures.indexOf feature
      if index == -1
        $scope.selectedFeatures.push feature
]
