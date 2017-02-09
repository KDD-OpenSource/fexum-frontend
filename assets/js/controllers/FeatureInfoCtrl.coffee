app.controller 'FeatureInfoCtrl', [
  '$scope',
  '$stateParams',
  '$timeout',
  'chartTemplates',
  'chartColors',
  'backendService',
  'scopeUtils',
  '$analytics',
  ($scope, $stateParams, $timeout, chartTemplates, chartColors,
  backendService, scopeUtils, $analytics) ->

    $scope.feature =
      name: $stateParams.featureName

    scopeUtils.waitForVariableSet $scope, 'features'
      .then (features) ->
        featurePredicate = (feature) -> feature.name == $stateParams.featureName
        $scope.feature = features.filter(featurePredicate)[0]

    return

  ]
