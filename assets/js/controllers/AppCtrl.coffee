app.controller 'AppCtrl', [
  '$scope',
  'backendService',
  '$timeout',
  '$q',
  'scopeUtils',
  '$analytics',
  ($scope, backendService, $timeout, $q, scopeUtils, $analytics) ->

    buildFeatureIdMap = ->
      $scope.featureIdMap = {}
      $scope.features.forEach (feature) ->
        $scope.featureIdMap[feature.id] = feature

    $scope.selectedFeatures = []

    # Retrieve features
    $scope.retrieveFeatures = ->
      backendService.getSession()
        .then (session) -> session.retrieveFeatures()
        .then (features) ->
          $scope.features = features
          buildFeatureIdMap()

          $scope.targetFeature = $scope.featureIdMap[$scope.targetFeatureId]

          # Restore selected states
          if $scope.selectedFeatures.length > 0
            newSelectedFeatures = []
            $scope.selectedFeatures.forEach (feature) ->
              newFeature = $scope.featureIdMap[feature.id]
              if newFeature?
                newSelectedFeatures.push newFeature
            $scope.selectedFeatures = newSelectedFeatures
        .fail console.error


    $scope.redundanciesLoaded = false
    $scope.retrieveRedundancies = ->
      backendService.getSession()
        .then (session) -> session.retrieveRedundancies()
        .then (redundancies) ->
          $scope.redundancies = {}
          redundancies.forEach updateRedundanciesFromItem
          $scope.redundanciesLoaded = true
        .fail console.error

    $scope.getSearchItems = ->
      categoricalFeatures = $scope.features.filter (f) -> f.is_categorical
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

    rarTime = []
    $scope.relevancies = {}
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
      if not feature?
        console.warn 'Got relevancy result that is not for this client'
        return
      $scope.relevancies[feature.id] = featureData.relevancy
      feature.relevancy = featureData.relevancy
      feature.rank = featureData.rank

    $scope.redundancies = {}
    updateRedundanciesFromItem = (redundancyItem) ->
      first = redundancyItem.first_feature
      second = redundancyItem.second_feature

      if not $scope.featureIdMap[first]? or not $scope.featureIdMap[second]?
        console.warn 'Got redundancy result that is not for this client'
        return

      $scope.redundancies[first + ',' + second] =
        firstFeature: first
        secondFeature: second
        redundancy: redundancyItem.redundancy
        weight: redundancyItem.weight

    $scope.relevanciesLoaded = false
    $scope.retrieveRarResults = ->
      backendService.getSession()
        .then (session) -> session.retrieveRarResults()
        .then (rarResults) ->
          $scope.relevancies = {}
          rarResults.forEach updateFeatureFromFeatureSelection
          $scope.relevanciesLoaded = true
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
      if $scope.relevanciesLoaded
        updateFeatureFromFeatureSelection payload.data

    $scope.$on 'ws/redundancy_result', (event, payload) ->
      if $scope.redundanciesLoaded
        updateRedundanciesFromItem payload.data

    $scope.$watch 'dataset', ((newValue, oldValue) ->
      if newValue?
        $scope.retrieveFeatures()
          .then $scope.retrieveRarResults
          .then $scope.retrieveRedundancies
      ), true

    $scope.$watchCollection 'selectedFeatures', (newSelectedFeatures) ->
      backendService.getSession()
        .then (session) -> session.setSelection newSelectedFeatures

    $scope.initializeFromSession = (session) ->
      $scope.targetFeatureId = session.targetId
      $scope.dataset = {id: session.dataset.id, name: session.dataset.name}
      selection = session.getSelection()
      if selection?
        $scope.selectedFeatures = selection

    backendService.getSession()
      .then $scope.initializeFromSession
      .fail console.error

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
      rarTime[targetFeature.id] = Date.now()

      backendService.getSession()
        .then (session) -> session.setTarget targetFeature.id
        .then ->
          $scope.redundancies = {}
          $scope.relevancies = {}
          for feature in $scope.features
            feature.relevancy = null

      # Create promise that waits for updated relevancies
      relevancyUpdate = backendService.waitForWebsocketEvent 'relevancy_result'
      # TODO internationalization
      $scope.addLoadingQueueItem relevancyUpdate,
                                 "Running feature selection for #{targetFeature.name}"

    $scope.$watch 'targetFeature', (newTargetFeature) ->
      if newTargetFeature?
        # Track setting the target in relation to dataset
        $analytics.eventTrack 'setTarget', {
          category: 'd' + $scope.dataset.name,
          label: 't' + $scope.targetFeature.name
        }

]
