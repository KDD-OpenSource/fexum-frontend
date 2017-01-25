app.controller 'FeatureInfoCtrl', [
  '$scope',
  '$routeParams',
  '$timeout',
  'chartTemplates',
  'chartColors',
  'backendService',
  'scopeUtils',
  ($scope, $routeParams, $timeout, chartTemplates, chartColors, backendService, scopeUtils) ->

    $scope.feature =
      name: $routeParams.featureName

    scopeUtils.waitForVariableSet $scope, 'features'
      .then (features) ->
        featurePredicate = (feature) -> feature.name == $routeParams.featureName
        $scope.feature = features.filter(featurePredicate)[0]

    return

  ]
