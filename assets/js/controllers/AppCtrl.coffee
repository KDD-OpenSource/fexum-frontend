app.controller 'AppCtrl', [
  '$scope',
  'backendService',
  '$timeout',
  '$analytics'
  ($scope, backendService, $timeout, $analytics) ->

    # Retrieve features
    $scope.retrieveFeatures = ->
      backendService.getSession()
        .then (session) -> session.retrieveFeatures()
        .then (features) ->
          $scope.features = features
          $scope.featureIdMap = {}
          features.forEach (feature) ->
            $scope.featureIdMap[feature.id] = feature
          $scope.targetFeature = $scope.featureIdMap[$scope.targetFeatureId]
        .fail console.error

    rarTime = []
    updateFeatureFromFeatureSelection = (featureData) ->
      # Log rar calculation time in Analytics
      if $scope.targetFeature? and rarTime[$scope.targetFeature.id]?
        delta = Date.now() - rarTime[$scope.targetFeature.id]
        rarTime[$scope.targetFeature.id] = null

        $analytics.userTimings {
              timingCategory: 'd' + $scope.dataset.name + '|t' + $scope.targetFeature.name,
              timingVar: 'rarFinished',
              timingLabel: 'ElapsedTimeMs',
              timingValue: delta
        }

      feature = $scope.featureIdMap[featureData.feature]
      feature.relevancy = featureData.relevancy
      feature.rank = featureData.rank

    $scope.retrieveRarResults = ->
      backendService.getSession()
        .then (session) -> session.retrieveRarResults()
        .then (rarResults) -> rarResults.forEach updateFeatureFromFeatureSelection
        .fail console.error

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

    isRefetching = false
    $scope.$on 'ws/closed', ->
      # When websocket is closed we might have missed important notifications
      if isRefetching
        return
      isRefetching = true
      timeoutDuration = 1000
      refetch = ->
        $scope.retrieveRarResults()
          .then ->
            isRefetching = false
          .fail (error) ->
            console.error error
            timeoutDuration *= 2
            $timeout refetch, timeoutDuration
      $timeout refetch, timeoutDuration

    $scope.$on 'ws/relevancy_result', (event, payload) ->
      updateFeatureFromFeatureSelection(payload.data)

    $scope.$watch 'dataset', ((newValue, oldValue) ->
      if newValue?
        $scope.retrieveFeatures()
          .then $scope.retrieveRarResults
      ), true

    backendService.getSession()
      .then (session) ->
        $scope.dataset = {id: session.dataset.id, name: session.dataset.name}
        $scope.targetFeatureId = session.targetId
      .fail console.error

    $scope.$watch 'targetFeature', (newTargetFeature) ->
      if newTargetFeature?
        $scope.searchText = newTargetFeature.name
        # Track setting the target in relation to dataset
        $analytics.eventTrack 'setTarget', {
          category: 'd' + $scope.dataset.name,
          label: 't' + $scope.targetFeature.name
        }

    $scope.setTarget = (targetFeature) ->
      if targetFeature?
        $scope.targetFeature = targetFeature
        rarTime[targetFeature.id] = Date.now()

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
]
