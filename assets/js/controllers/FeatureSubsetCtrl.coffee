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
              feature.selected = $routeParams.select?
              return
]
