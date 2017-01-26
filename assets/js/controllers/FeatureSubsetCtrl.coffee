app.controller 'FeatureSubsetCtrl', [
  '$scope',
  '$routeParams',
  'scopeUtils',
  ($scope, $routeParams, scopeUtils) ->

    if $routeParams.select? or $routeParams.unselect
      scopeUtils.waitForVariableSet $scope, 'features'
        .then (features) ->
          for feature in features
            searchedName = $routeParams.select or $routeParams.unselect
            if feature.name == searchedName
              if $routeParams.select?
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
