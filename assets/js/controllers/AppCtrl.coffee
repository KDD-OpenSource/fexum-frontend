app.controller 'AppCtrl', ['$scope', '$http', 'apiUri', 'socketUri', '$q', '$websocket', \
                          'backendService', \
                          ($scope, $http, apiUri, socketUri, $q, $websocket, backendService) ->

  findTargetFeature = (targetFeatureId) ->
    matchPredicate = (feature) -> feature.id == targetFeatureId
    $scope.targetFeature = $scope.features.filter(matchPredicate)[0]

  $scope.$watch 'targetFeature', (newTargetFeature) ->
    if newTargetFeature
      $scope.searchText = newTargetFeature.name
  
  $scope.setTarget = (targetFeature) ->
    if targetFeature?
      $scope.targetFeature = targetFeature

      for feature in $scope.features
        feature.relevancy = null
      backendService.currentSession().then (session) ->
        session.setTarget targetFeature.id, (rar_results) ->
          for result in rar_results
            feature = $scope.features.filter((f) -> f.id == result.feature)[0]
            feature.relevancy = result.relevancy
            feature.redundancy = result.redundancy
            feature.rank = result.rank
    return

  backendService.currentSession().then (session) ->
    console.log session
    session.retrieveFeatures (features) ->
      $scope.features = features
      if $scope.targetFeature?
        findTargetFeature $scope.targetFeature.id
      findTargetFeature session.target
      if session.target?
        backendService.retrieveRarResults (rar_results) ->
          for result in rar_results
            feature = $scope.features.filter((f) -> f.id == result.feature)[0]
            feature.relevancy = result.relevancy
            feature.redundancy = result.redundancy
            feature.rank = result.rank


  return
]
