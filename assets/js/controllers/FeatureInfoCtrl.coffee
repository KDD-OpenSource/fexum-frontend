app.controller 'FeatureInfoCtrl', [
  '$scope',
  '$routeParams',
  '$timeout',
  'chartTemplates',
  'chartColors',
  'backendService',
  'scopeUtils',
  '$analytics',
  ($scope, $routeParams, $timeout, chartTemplates, chartColors,
  backendService, scopeUtils, $analytics) ->

    $scope.feature =
      name: $routeParams.featureName

    scopeUtils.waitForVariableSet $scope, 'features'
      .then (features) ->
        featurePredicate = (feature) -> feature.name == $routeParams.featureName
        $scope.feature = features.filter(featurePredicate)[0]

    return

  ]
