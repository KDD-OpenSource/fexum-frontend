app.controller 'AppCtrl', [
  '$scope',
  'backendService',
  'systemStatus',
  '$timeout',
  '$q',
  '$analytics',
  '$location',
  ($scope, backendService, systemStatus, $timeout, $q, $analytics, $location) ->

    buildFeatureIdMap = ->
      $scope.featureIdMap = {}
      $scope.features.forEach (feature) ->
        $scope.featureIdMap[feature.id] = feature

    $scope.selectedFeatures = []

    restoreFeatureListByOldList = (oldList) ->
      if oldList.length > 0
        newList = []
        oldList.forEach (feature) ->
          newFeature = $scope.featureIdMap[feature.id]
          if newFeature?
            newList.push newFeature
        return newList
      return []

    # Retrieve features
    $scope.retrieveFeatures = ->
      backendService.getExperiment()
        .then (experiment) -> experiment.retrieveFeatures()
        .then (features) ->
          $scope.filteredFeatures = features
          # All filters applied except slider, that way the ceiling is always correct on the slider
          $scope.intermediateFilteredFeatures = features
          $scope.features = features
          buildFeatureIdMap()

          # Restore targetFeature
          $scope.targetFeature = $scope.featureIdMap[$scope.targetFeatureId]
          # Restore selected states
          $scope.selectedFeatures = restoreFeatureListByOldList $scope.selectedFeatures
          # Restore filterParams blacklist
          $scope.filterParams.blacklist = restoreFeatureListByOldList $scope.filterParams.blacklist
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

      # features only contains one element because only bivariates are retrieved
      feature = $scope.featureIdMap[featureData.features[0]]
      if not feature?
        console.warn 'Got relevancy result that is not for this client'
        return
      $scope.relevancies[feature.id] = featureData.relevancy
      feature.relevancy = featureData.relevancy

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

    $scope.$on 'ws/calculation', (event, payload) ->
      # Status is one of ['error', 'processing', 'done']
      status = payload.data.status
      # Type is one of ['default_hics', 'fixed_feature_set_hics']
      type = payload.data.type
      if status == 'done' and type == 'default_hics'
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
        systemStatus.waitForDatasetProcessed()
      return
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
      filterParams = experiment.getFilterParams()
      if filterParams?
        $scope.filterParams = filterParams

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

    $scope.$watch 'targetFeature', (newTargetFeature) ->
      if newTargetFeature?
        # Remove target from selection, if contained
        $scope.selectedFeatures.removeObject newTargetFeature

        # Track setting the target in relation to dataset
        $analytics.eventTrack 'setTarget', {
          category: 'd' + $scope.dataset.id,
          label: 't' + $scope.targetFeature.id
        }

        systemStatus.waitForFeatureSelection newTargetFeature
      return

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

          for feature in $scope.filterParams.blacklist
            $scope.selectedFeatures.removeObject feature

        # All filters applied except slider, that way the ceiling is always correct on the slider
        $scope.intermediateFilteredFeatures = filtered
        # k-best filter
        if $scope.filterParams.bestLimit?
          filtered = filtered.sort (a, b) -> b.relevancy - a.relevancy
          filtered = filtered.slice(0, $scope.filterParams.bestLimit)

        # Target needs to be in there at all times for relevancy links
        if $scope.targetFeature? and $scope.targetFeature not in filtered
          filtered.push $scope.targetFeature

        $scope.filteredFeatures = filtered

    onFilterParamsChanged = ->
      $scope.refilter()
      backendService.getExperiment()
        .then (experiment) -> experiment.setFilterParams $scope.filterParams
        .fail console.error
      
    $scope.$watch 'filterParams', onFilterParamsChanged, true


]
