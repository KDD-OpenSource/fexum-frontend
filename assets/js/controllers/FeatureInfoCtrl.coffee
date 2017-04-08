app.controller 'FeatureInfoCtrl', [
  '$scope',
  '$stateParams',
  'scopeUtils',
  '$location',
  ($scope, $stateParams, scopeUtils, $location) ->

    $scope.feature =
      name: $stateParams.featureName

    scopeUtils.waitForVariableSet $scope, 'features'
      .then (features) ->
        featurePredicate = (feature) -> feature.name == $stateParams.featureName
        $scope.feature = features.filter(featurePredicate)[0]

    $scope.disableFeature = (feature) ->
      $scope.filterParams.blacklist.push feature
      $location.path '/'

    $scope.canBeTarget = (feature) ->
      return feature != $scope.targetFeature and not (feature in $scope.filterParams.blacklist) \
        and feature.is_categorical

    return

  ]
