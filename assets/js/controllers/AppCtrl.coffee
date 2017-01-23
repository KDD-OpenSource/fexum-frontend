app.controller 'AppCtrl', ['$scope', 'backendService', ($scope, backendService) ->

  # Retrieve features
  $scope.retrieveFeatures = ->
    backendService.getSession()
      .then (session) ->
        $scope.targetFeatureId = session.target
        return session.retrieveFeatures()
      .then (features) ->
        $scope.features = features
        $scope.featureIdMap = {}
        features.forEach (feature) ->
          $scope.featureIdMap[feature.id] = feature
        $scope.targetFeature = $scope.featureIdMap[$scope.targetFeatureId]
      .fail console.error

  updateFeatureFromFeatureSelection = (featureData) ->
    feature = $scope.featureIdMap[featureData.feature]
    feature.relevancy = featureData.relevancy
    feature.redundancy = featureData.redundancy
    feature.rank = featureData.rank

  $scope.retrieveRarResults = ->
    backendService.getSession()
      .then (session) -> session.retrieveRarResults()
      .then (rarResults) -> rarResults.forEach updateFeatureFromFeatureSelection

  $scope.loadingQueue = []
  $scope.addLoadingQueueItem = (promise, message) ->
    item =
      promise: promise
      message: message
    $scope.loadingQueue.push item
    promise.then (result) ->
      # Remove from loading queue when done
      itemIndex = $scope.loadingQueue.indexOf item
      $scope.loadingQueue.splice itemIndex, 1

  $scope.$on 'ws/rar_result', (event, payload) ->
    updateFeatureFromFeatureSelection(payload.data)

  $scope.$watch 'targetFeature', (newTargetFeature) ->
    if newTargetFeature
      $scope.searchText = newTargetFeature.name

  $scope.setTarget = (targetFeature) ->
    if targetFeature?
      $scope.targetFeature = targetFeature

      backendService.getSession()
        .then (session) -> session.setTarget targetFeature.id
        .then ->
          for feature in $scope.features
            feature.relevancy = null

      # Create promise that waits for updated relevancies
      relevancyUpdate = backendService.waitForWebsocketEvent 'rar_result'
      # TODO internationalization
      $scope.addLoadingQueueItem relevancyUpdate,
                                 "Running feature selection for #{targetFeature.name}"
    return

  $scope.retrieveFeatures()
    .then $scope.retrieveRarResults

  return
]
