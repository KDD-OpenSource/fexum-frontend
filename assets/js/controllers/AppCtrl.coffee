app.controller 'AppCtrl', ['$scope', '$http', 'apiUri', 'socketUri', '$q', '$websocket', \
                          'backendService', \
                          ($scope, $http, apiUri, socketUri, $q, $websocket, backendService) ->

  findTargetFeature = (targetFeatureName) ->
    matchPredicate = (feature) -> feature.name == targetFeatureName
    $scope.targetFeature = $scope.features.filter(matchPredicate)[0]

  $scope.$watch 'targetFeature', (newTargetFeature) ->
    if newTargetFeature
      $scope.searchText = newTargetFeature.name
  
  $scope.setTarget = (targetFeature) ->
    if targetFeature?
      $scope.targetFeature = targetFeature

      backendService.setTarget targetFeature, ->
        for feature in $scope.features
            feature.relevancy = null
        $scope.retrieveSelectedFeature
    return

  backendService.retrieveFeatures (features) ->
      $scope.features = features
      console.log features
      if $scope.targetFeature?
        findTargetFeature $scope.targetFeature.name
      backendService.retrieveTarget (targetFeatureName) -> findTargetFeature targetFeatureName

  return
]
