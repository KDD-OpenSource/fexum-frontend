app.controller 'AppCtrl', [
  '$scope',
  'backendService',
  'systemStatus',
  '$timeout',
  '$q',
  'scopeUtils',
  '$analytics',
  '$location',
  ($scope, backendService, systemStatus, $timeout, $q, scopeUtils, $analytics, $location) ->

    buildFeatureIdMap = ->
      $scope.featureIdMap = {}
      $scope.features.forEach (feature) ->
        $scope.featureIdMap[feature.id] = feature

    $scope.selectedFeatures = []

    $scope.logout = ->
      backendService.logout()
        .then ->
          $location.path '/login'

    # Retrieve features
    $scope.retrieveFeatures = ->
      backendService.getExperiment()
        .then (experiment) -> experiment.retrieveFeatures()
        .then (features) ->
          $scope.filteredFeatures = features
          $scope.semifilteredFeatures = features
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

    $scope.retrieveRedundancies = ->
      backendService.getExperiment()
        .then (experiment) -> experiment.retrieveRedundancies()
        .then (redundancies) ->
          $scope.redundancies = {}
          redundancies.forEach updateRedundanciesFromItem
        .fail console.error

    rarTime = []
    $scope.relevancies = {}
    updateFeatureFromFeatureSelection = (featureData) ->
      # Log rar calculation time in Analytics
      if $scope.targetFeature? and rarTime[$scope.targetFeature.id]?
        delta = Date.now() - rarTime[$scope.targetFeature.id]
        rarTime[$scope.targetFeature.id] = null

        $analytics.userTimings {
              timingCategory: 'd' + $scope.dataset.id + '|t' + $scope.targetFeature.id,
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

    $scope.retrieveRarResults = ->
      backendService.getExperiment()
        .then (experiment) -> experiment.retrieveRarResults()
        .then (rarResults) ->
          $scope.relevancies = {}
          rarResults.forEach updateFeatureFromFeatureSelection
        .fail console.error

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

    $scope.reloadDataset = ->
      $scope.retrieveFeatures()
        .then $scope.retrieveRarResults
        .then $scope.retrieveRedundancies

    $scope.$on 'ws/rar_result', (event, payload) ->
      if payload.data.status == 'done'
        $scope.retrieveRarResults()
        $scope.retrieveRedundancies()

    $scope.$on 'ws/dataset', (event, payload) ->
      backendService.getExperiment()
        .then (experiment) ->
          dataset = experiment.dataset
          if payload.data.status == 'done' and payload.pk == dataset.id
            $scope.reloadDataset()
        .fail console.error

    $scope.$watch 'dataset', ((newValue, oldValue) ->
      if newValue?
        $scope.reloadDataset()
      ), true

    $scope.$watchCollection 'selectedFeatures', (newSelectedFeatures) ->
      backendService.getExperiment()
        .then (experiment) -> experiment.setSelection newSelectedFeatures
        .fail console.error

    $scope.initializeFromExperiment = (experiment) ->
      $scope.targetFeatureId = experiment.targetId
      $scope.dataset = {id: experiment.dataset.id, name: experiment.dataset.name}
      selection = experiment.getSelection()
      if selection?
        $scope.selectedFeatures = selection

    backendService.getExperiment()
      .then $scope.initializeFromExperiment
      .fail (error) ->
        if error.noDatasets
          $location.path '/change-dataset'
        else
          console.error error

    $scope.loadingQueue = systemStatus.loadingQueue

    $scope.setTarget = (targetFeature) ->
      $scope.targetFeature = targetFeature
      rarTime[targetFeature.id] = Date.now()

      backendService.getExperiment()
        .then (experiment) -> experiment.setTarget targetFeature.id
        .then ->
          $scope.redundancies = {}
          $scope.relevancies = {}
          for feature in $scope.features
            feature.relevancy = null
        .fail console.error

      systemStatus.waitForFeatureSelection targetFeature

    $scope.$watch 'targetFeature', (newTargetFeature) ->
      if newTargetFeature?
        # Remove target from selection, if contained
        $scope.selectedFeatures.removeObject newTargetFeature

        # Track setting the target in relation to dataset
        $analytics.eventTrack 'setTarget', {
          category: 'd' + $scope.dataset.id,
          label: 't' + $scope.targetFeature.id
        }

    $scope.filterParams =
      bestLimit: null
      blacklist: []
      searchText: ''

    $scope.refilter = ->
      if $scope.features?
        # Simple text filter
        filtered = $scope.features.filter (feature) ->
            (feature.name.search $scope.filterParams.searchText) != -1

        # Blacklist filter
        if $scope.filterParams.blacklist?
          filtered = filtered.filter (feature) ->
            feature not in $scope.filterParams.blacklist

        $scope.semifilteredFeatures = filtered
        # k-best filter
        if $scope.filterParams.bestLimit?
          filtered = filtered.sort (a, b) -> b.relevancy - a.relevancy
          filtered = filtered.slice(0, $scope.filterParams.bestLimit)

        # Target needs to be in there at all times for relevancy links
        if $scope.targetFeature not in filtered
          filtered.push $scope.targetFeature

        $scope.filteredFeatures = filtered

    $scope.$watch 'filterParams', $scope.refilter, true


]
