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

    resetExperimentData = ->
      $scope.featuresLoaded = false
      $scope.selectedFeatures = []
      $scope.filterParams =
        bestLimit: null
        blacklist: []
        searchText: ''
        excludeText: ''
    resetExperimentData()

    findFeaturesFromIds = (featureIds) ->
      return featureIds.map (fid) -> $scope.featureIdMap[fid]

    # Retrieve features
    $scope.retrieveFeatures = ->
      backendService.getExperiment()
        .then (experiment) -> return $q.all [experiment, experiment.retrieveFeatures()]
        .then ([experiment, features]) ->
          $scope.filteredFeatures = features
          # All filters applied except slider, that way the ceiling is always correct on the slider
          $scope.intermediateFilteredFeatures = features
          $scope.features = features
          buildFeatureIdMap()

          # Restore targetFeature
          $scope.targetFeature = $scope.featureIdMap[$scope.targetFeatureId]
          # Restore selected states
          $scope.selectedFeatures = findFeaturesFromIds experiment.getSelection()
          # Restore filterParams blacklist
          $scope.filterParams.blacklist = findFeaturesFromIds experiment.getFilterParams().blacklist

          $scope.featuresLoaded = true
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
              timingCategory: 'd' + $scope.datasetId + '|t' + $scope.targetFeature.id,
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
      if status != 'error' and type == 'default_hics'
        $scope.retrieveRarResults()
        $scope.retrieveRedundancies()

    $scope.$on 'ws/dataset', (event, payload) ->
      backendService.getExperiment()
        .then (experiment) ->
          datasetId = experiment.datasetId
          if payload.data.status == 'done' and payload.pk == datasetId
            $scope.reloadDataset()
        .fail console.error

    $scope.$watch 'datasetId', ((newValue, oldValue) ->
      if newValue?
        $scope.reloadDataset()
        systemStatus.waitForDatasetProcessed()
      return
      ), true

    $scope.$watchCollection 'selectedFeatures', (newSelectedFeatures) ->
      return unless $scope.featuresLoaded
      newSelectedFeatureIds = newSelectedFeatures.map (f) -> f.id
      backendService.getExperiment()
        .then (experiment) -> experiment.setSelection newSelectedFeatureIds
        .fail console.error

    $scope.initializeFromExperiment = (experiment) ->
      $scope.targetFeatureId = experiment.targetId
      $scope.datasetId = experiment.datasetId
      resetExperimentData()
      filterParams = experiment.getFilterParams()
      $scope.filterParams.bestLimit = filterParams.bestLimit
      $scope.filterParams.searchText = filterParams.searchText
      $scope.filterParams.excludeText = filterParams.excludeText
      return

    backendService.getExperiment()
      .then $scope.initializeFromExperiment
      .fail (error) ->
        if error.noDatasets
          $location.path '/change-dataset'
        else
          console.error 'Could not load experiment', error

    $scope.loadingQueue = systemStatus.loadingQueue

    $scope.setTarget = (targetFeature) ->
      return if $scope.targetFeature == targetFeature
      $scope.targetFeature = targetFeature
      rarTime[targetFeature.id] = Date.now()

      backendService.getExperiment()
        .then (experiment) -> experiment.setTarget targetFeature.id
        .then ->
          $scope.redundancies = {}
          $scope.relevancies = {}
          for feature in $scope.features
            feature.relevancy = null
          $scope.retrieveRarResults()
          $scope.retrieveRedundancies()
        .fail console.error

    $scope.$watch 'targetFeature', (newTargetFeature) ->
      if newTargetFeature?
        # Remove target from selection, if contained
        $scope.selectedFeatures.removeObject newTargetFeature

        # Track setting the target in relation to dataset
        $analytics.eventTrack 'setTarget', {
          category: 'd' + $scope.datasetId,
          label: 't' + $scope.targetFeature.id
        }

        systemStatus.waitForFeatureSelection newTargetFeature
      return

    $scope.refilter = ->
      # Simple text filter
      filtered = $scope.features.filter (feature) ->
          (feature.name.search $scope.filterParams.searchText) != -1
      # Text filter that excludes features
      if $scope.filterParams.excludeText? and $scope.filterParams.excludeText.length > 0
        filtered = filtered.filter (feature) ->
            (feature.name.search $scope.filterParams.excludeText) == -1

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

    onFilterParamsChanged = (newValue, oldValue) ->
      return if angular.equals newValue, oldValue
      return unless $scope.featuresLoaded
      $scope.refilter()
      serialized =
        bestLimit: newValue.bestLimit
        blacklist: newValue.blacklist.map (f) -> f.id
        searchText: newValue.searchText
        excludeText: newValue.excludeText
      backendService.getExperiment()
        .then (experiment) -> experiment.setFilterParams serialized
        .fail console.error

    $scope.$watch 'filterParams', onFilterParamsChanged, true

]
