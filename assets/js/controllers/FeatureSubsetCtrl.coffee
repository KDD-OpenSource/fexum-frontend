app.controller 'FeatureSubsetCtrl', [
  '$scope',
  '$routeParams',
  ($scope, $routeParams) ->

    if $routeParams.select? or $routeParams.unselect
      $scope.waitForVariableSet 'features'
        .then (features) ->
          for feature in features
            searchedName = $routeParams.select or $routeParams.unselect
            if feature.name == searchedName
              feature.selected = $routeParams.select?
              return
]
