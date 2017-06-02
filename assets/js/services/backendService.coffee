app.factory 'backendService', [
  '$rootScope',
  '$http',
  '$websocket',
  '$q',
  ($rootScope, $http, $websocket, $q) ->

    API_URI = '/api/'
    SOCKET_URI = "ws://#{window.location.host}/bindings"

    # coffeescript doesn't like functions called catch...
    $q.prototype.fail = $q.prototype.catch

    retrieveDatasets = ->
      $http.get API_URI + 'datasets'
      .then (response) ->
        datasets = response.data
        return datasets
      .fail console.error

    retrieveExperiments = ->
      $http.get API_URI + 'experiments'
        .then (response) ->
          return response.data
        .fail console.error

    retrieveDensity = (featureId, targetFeatureId) ->
      $http.get API_URI + "features/#{featureId}/density/#{targetFeatureId}"
        .then (response) ->
          densities = response.data
          return densities
        .fail console.error

    retrieveHistogramBuckets = (featureId) ->
      $http.get API_URI + "features/#{featureId}/histogram"
        .then (response) ->
          buckets = response.data.map (bucket) ->
            return {
              range: [bucket.from_value, bucket.to_value]
              count: bucket.count
            }
          return buckets
        .fail console.error

    retrieveSpectrogram = (featureId) ->
      $http.get API_URI + "features/#{featureId}/spectrogram"
        .then (response) ->
          return response.data
        .fail console.error

    retrieveSamples = (featureId) ->
      $http.get API_URI + "features/#{featureId}/samples"
        .then (response) ->
          samples = response.data.map (sample, idx) ->
            return {
              x: idx
              y: sample.value
            }
          return samples
        .fail console.error

    getFeatureSelectionStatus = ->
      $http.get API_URI + 'calculations'
        .then (response) ->
          return response.data
        .fail console.error

    wsStream = $websocket SOCKET_URI
    wsStream.reconnectIfNotNormalClose = true

    wsStream.onMessage (message) ->
      jsonData = JSON.parse message.data
      $rootScope.$broadcast "ws/#{jsonData.stream}", jsonData.payload

    wsStream.onClose ->
      $rootScope.$broadcast 'ws/closed'

    waitForWebsocketEvent = (eventName, conditionCallback) ->
      return $q (resolve, reject) ->
        removeListener = $rootScope.$on 'ws/' + eventName, ->
          if not conditionCallback or conditionCallback.apply @, arguments
            resolve.apply @, arguments
            removeListener()

    class Experiment

      constructor: (@id, @datasetId, @targetId) ->

      @create: (datasetId) =>
        return $http.post API_URI + 'experiments', dataset: datasetId
          .then (response) =>
            experiment = @fromJson response.data
            return experiment

      @current: =>
        return $http.get API_URI + 'experiments/current'
          .then (response) =>
            experiment = @fromJson response.data
            return experiment
          .fail (response) ->
            if response.status == 404
              return null
            return $q.reject response


      @fromJson: (json) ->
        experiment = new Experiment(
          json.id,
          json.dataset,
          json.target
        )
        experiment.selection = json.analysis_selection
        experiment.filterParams =
          bestLimit: json.visibility_rank_filter
          blacklist: json.visibility_blacklist
          searchText: json.visibility_text_filter
        return experiment

      makeCurrent: =>
        return $http.put API_URI + "experiments/current/#{@id}"
          .fail console.error

      setFilterParams: (filterParams) =>
        @filterParams = filterParams
        $http.patch API_URI + "experiments/#{@id}",
            visibility_text_filter: filterParams.searchText
            visibility_rank_filter: filterParams.bestLimit
            visibility_blacklist: filterParams.blacklist
          .fail console.error

      getFilterParams: =>
        return @filterParams

      setSelection: (selection) =>
        @selection = selection
        $http.patch API_URI + "experiments/#{@id}",
            analysis_selection: selection
          .fail console.error

      getSelection: =>
        return @selection

      retrieveDatasetInfo: =>
        # TODO for backend, have endpoint for single dataset
        return retrieveDatasets()
          .then (datasets) =>
            filtered = datasets.filter (dataset) =>
              return dataset.id == @datasetId
            return filtered[0]
          .fail console.error

      retrieveFeatures: =>
        $http.get API_URI + "datasets/#{@datasetId}/features"
          .then (response) ->
            # Response is in the form
            # [{name, rank, mean, variance, min, max}, ...]
            features = response.data
            # Order does not matter and is preferred random for rendering => shuffle
            features.shuffle()

            # TODO: DEBUG ONLY, REMOVE WHEN IMPLEMENTED IN BACKEND
            features.forEach (f) ->
              if f.is_categorical and not f.categories?
                f.categories = [1, 2, 3, 4, 5, 6, 7, 8, 9]

            return features
          .fail console.error

      setTarget: (targetFeatureId) =>
        @targetId = targetFeatureId
        # Notify server of new target
        $http.put API_URI + "experiments/#{@id}/target", target: targetFeatureId
          .then (response) =>
            @targetId = targetFeatureId
          .fail console.error

      retrieveSlicesForSubset: (featureSubset) =>
        if featureSubset.length == 0
          return $q.resolve []
        params =
          features: featureSubset
        $http.post API_URI + "targets/#{@targetId}/slices", params
          .then (response) ->
            sortByValue = (a, b) -> a.value - b.value
            slices = response.data.map (slice) ->
              features = []
              for feature, sliceDesc of slice.features
                isCategorical = not sliceDesc.from_value?
                if isCategorical
                  features.push
                    feature: feature
                    categories: sliceDesc
                else
                  features.push
                    feature: feature
                    range: [sliceDesc.from_value, sliceDesc.to_value]
              return {
                features: features
                deviation: slice.deviation
              }
            return slices
          .fail console.error

      getProbabilityDistribution: (rangesSpecification) =>
        $http.post API_URI + "targets/#{@targetId}/distributions", rangesSpecification
          .then (response) ->
            distribution = response.data
            return distribution
          .fail console.error

      requestFeatureSelectionForSubset: (featureSubset) =>
        params =
          features: featureSubset
        $http.post API_URI + "targets/#{@targetId}/hics", params
          .then (response) ->
            return response.data
          .fail console.error

      retrieveRarResults: =>
        if @targetId?
          relevancy = $http.get API_URI + "targets/#{@targetId}/relevancy_results"
            .then (response) ->
              rar_results = response.data
              return rar_results
        else
          relevancy = $q.resolve []
        return relevancy

      retrieveRedundancies: =>
        if @targetId?
          redundancies = $http.get API_URI + "targets/#{@targetId}/redundancy_results"
            .then (response) ->
              redundancies = response.data
              return redundancies
            .fail console.error
        else
          redundancies = $q.resolve []
        return redundancies

    class Service

      retrieveDatasets: retrieveDatasets
      retrieveHistogramBuckets: retrieveHistogramBuckets
      retrieveSamples: retrieveSamples
      retrieveSpectrogram: retrieveSpectrogram
      retrieveDensity: retrieveDensity
      waitForWebsocketEvent: waitForWebsocketEvent
      getFeatureSelectionStatus: getFeatureSelectionStatus

      login: (user) ->
        return $http.post API_URI + 'auth/login', username: user.name, password: user.password
          .then (response) ->
            return response.data

      register: (user) =>
        return $http.post API_URI + 'users/register', username: user.name, password: user.password
          .then =>
            @login user

      logout: ->
        return $http.delete API_URI + 'auth/logout'
          .fail console.error

      getExperiment: (datasetId) =>
        if @experiment?
          p_experiment = $q.resolve @experiment
        else
          p_experiment = Experiment.current().then (e) => @experiment = e

        return p_experiment.then (experiment) =>
          if experiment? and (not datasetId? or experiment.datasetId == datasetId)
            return experiment

          setExperiment = (experiment) =>
            @experiment = experiment
            experiment.makeCurrent()
            return experiment

          if not datasetId?
            return retrieveDatasets()
              .then (datasets) ->
                if datasets.length > 0
                  return datasets[0]
                return $q.reject {
                  noDatasets: true
                  msg: 'No datasets available'
                }
              .then Experiment.create
              .then setExperiment

          return retrieveExperiments()
            .then (experiments) ->
              matchingExperiments = experiments.filter (e) -> e.dataset == datasetId
              if matchingExperiments.length > 0
                experiment = Experiment.fromJson matchingExperiments[0]
                return experiment
              return Experiment.create datasetId
            .then setExperiment

    return new Service()
]
