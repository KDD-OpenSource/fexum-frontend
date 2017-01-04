app.controller 'AppCtrl', ['$scope', '$http', 'apiUri', 'socketUri', '$q', '$websocket', \
                          ($scope, $http, apiUri, socketUri, $q, $websocket) ->

  # Retrieve features
  $scope.retrieveFeatures = ->
    $http.get apiUri + 'features'
      .then (response) ->
        # Response is in the form
        # [{name, relevancy, redundancy, rank, mean, variance, min, max}, ...]
        $scope.features = response.data
      .catch console.error

  # Retrieve target
  $scope.retrieveTarget = ->
    $http.get apiUri + 'features/target'
      .then (response) ->
        # Response is in the form
        # {feature: {name, ...}}
        targetFeatureName = response.data.feature.name
        matchPredicate = (feature) -> feature.name == targetFeatureName
        $scope.targetFeature = $scope.features.filter(matchPredicate)[0]
      .catch (response) ->
        if response.status == 204
          console.log 'No target set'
        else
          console.error response

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

  wsStream = $websocket socketUri
  wsStream.onMessage (message) ->
    jsonData = JSON.parse message.data
    $scope.$broadcast "ws/#{jsonData.event_name}", jsonData.payload

  $scope.waitForWebsocketEvent = (eventName) ->
    return $q (resolve, reject) ->
      removeListener = $scope.$on 'ws/' + eventName, ->
        resolve.apply this, arguments
        removeListener()

  $scope.$on 'ws/relevancy-update', (event, payload) ->
    $scope.retrieveFeatures()

  $scope.$watch 'targetFeature', (newTargetFeature) ->
    if newTargetFeature
      $scope.searchText = newTargetFeature.name
  
  $scope.setTarget = (targetFeature) ->
    if targetFeature
      $scope.targetFeature = targetFeature

      # Notify server of new target
      $http.put apiUri + "features/target", { 'feature_name': targetFeature.name }
        .then (response) ->
          console.log "Set new target #{targetFeature.name} on server"
        .catch console.error

      # Create promise that waits for updated relevancies
      relevancyUpdate = $scope.waitForWebsocketEvent 'relevancy-update'
      # TODO internationalization
      $scope.addLoadingQueueItem relevancyUpdate, 'Running feature selection'
    return

  $scope.retrieveFeatures().then $scope.retrieveTarget

  return
]
