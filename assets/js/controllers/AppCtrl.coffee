app.controller 'AppCtrl', [
  '$scope',
  'backendService',
  '$timeout',
  '$q',
  'scopeUtils',
  ($scope, backendService, $timeout, $q, scopeUtils) ->

    buildFeatureIdMap = ->
      $scope.featureIdMap = {}
      $scope.features.forEach (feature) ->
        $scope.featureIdMap[feature.id] = feature

    # Retrieve features
    $scope.retrieveFeatures = ->
      backendService.getSession()
        .then (session) -> session.retrieveFeatures()
        .then (features) ->
          # Restore selected states
          if $scope.features?
            for feature in features
              oldFeature = $scope.featureIdMap[feature.id]
              if oldFeature?
                feature.selected = oldFeature.selected

          $scope.features = features
          buildFeatureIdMap()
          features.forEach (feature) ->
            # TODO remove this mock value
            feature.isCategorical = true

          $scope.targetFeature = $scope.featureIdMap[$scope.targetFeatureId]
        .fail console.error

    $scope.getSearchItems = ->
      categoricalFeatures = $scope.features.filter (f) -> f.isCategorical
      targetChoices = categoricalFeatures.map (feature, i) ->
        return {
          feature: feature
          index: i
          isTargetChoice: true
        }
      locatableFeatures = $scope.features.map (feature, i) ->
        return {
          feature: feature
          index: i
          isTargetChoice: false
        }
      searchItems = locatableFeatures.concat targetChoices
      return searchItems.sort (a, b) -> a.index - b.index

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

    $scope.$on 'ws/rar_result', (event, payload) ->
      updateFeatureFromFeatureSelection(payload.data)

    $scope.$watch 'datasetId', ((newValue, oldValue) ->
      if newValue?
        $scope.retrieveFeatures()
          .then $scope.retrieveRarResults
      ), true

    backendService.getSession()
      .then (session) ->
        $scope.datasetId = session.dataset
        $scope.targetFeatureId = session.target

    $scope.onFeatureSearched = (searchedItem) ->
      if not searchedItem?
        return
      if searchedItem.isTargetChoice
        $scope.setTarget searchedItem.feature
      else
        # TODO zoom to location of feature
        console.log 'Zooming to location feature'
      $scope.searchText = ''

    $scope.setTarget = (targetFeature) ->
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
]
