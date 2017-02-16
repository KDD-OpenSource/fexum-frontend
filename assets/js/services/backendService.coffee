app.factory 'backendService', [
  '$rootScope',
  '$http',
  '$websocket',
  '$q',
  ($rootScope, $http, $websocket, $q) ->

    API_URI = '/api/'
    SOCKET_URI = "ws://#{window.location.host}/bindings"
    TOKEN_KEY = 'loginToken'

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

    wsStream = $websocket SOCKET_URI
    wsStream.reconnectIfNotNormalClose = true

    wsStream.onMessage (message) ->
      jsonData = JSON.parse message.data
      $rootScope.$broadcast "ws/#{jsonData.stream}", jsonData.payload

    wsStream.onClose ->
      $rootScope.$broadcast 'ws/closed'

    waitForWebsocketEvent = (eventName) ->
      return $q (resolve, reject) ->
        removeListener = $rootScope.$on 'ws/' + eventName, ->
          resolve.apply @, arguments
          removeListener()

    class Experiment

      @LAST_EXPERIMENT_KEY = 'lastExperiment'

      constructor: (@id, @dataset, @targetId) ->

      @create: (dataset) =>
        return $http.post API_URI + 'experiments', dataset: dataset.id
          .then (response) =>
            experiment = @fromJson response.data
            experiment.dataset = dataset
            return experiment

      @restore: =>
        lastExperimentJson = localStorage.getItem @LAST_EXPERIMENT_KEY
        if lastExperimentJson?
          lastExperiment = angular.fromJson lastExperimentJson
          return @fromJson lastExperiment

      @fromJson: (json) ->
        experiment = new Experiment(
          json.id,
          json.dataset,
          json.targetId
        )
        experiment.selection = json.selection
        return experiment

      setSelection: (selection) =>
        @selection = selection
        @store()

      getSelection: =>
        return @selection

      store: =>
        lastExperiment =
          id: @id
          dataset: @dataset
          targetId: @targetId
          selection: @selection
        localStorage.setItem Experiment.LAST_EXPERIMENT_KEY, angular.toJson(lastExperiment)

      retrieveDatasetInfo: =>
        # TODO for backend, have endpoint for single dataset
        return retrieveDatasets()
          .then (datasets) =>
            filtered = datasets.filter (dataset) =>
              return dataset.id == @dataset.id
            return filtered[0]
          .fail console.error

      retrieveFeatures: =>
        $http.get API_URI + "datasets/#{@dataset.id}/features"
          .then (response) ->
            # Response is in the form
            # [{name, rank, mean, variance, min, max}, ...]
            features = response.data
            # Order does not matter and is preferred random for rendering => shuffle
            features.shuffle()
            return features
          .fail console.error

      setTarget: (targetFeatureId) =>
        @targetId = targetFeatureId
        # Notify server of new target
        $http.put API_URI + "experiments/#{@id}/target", target: targetFeatureId
          .then (response) =>
            @targetId = targetFeatureId
            @store()
          .fail console.error

      retrieveSlicesForSubset: (featureSubset) =>
        if featureSubset.length == 0
          return $q.resolve []
        paramsString = featureSubset.join ','
        $http.get API_URI + "targets/#{@targetId}/slices?feature__in=#{paramsString}"
          .then (response) ->
            sortByValue = (a, b) -> a.value - b.value
            slices = response.data.map (slice) ->
              features = slice.features.map (feature) ->
                return {
                  feature: feature.feature
                  range: [feature.from_value, feature.to_value]
                }
              return {
                features: features
                frequency: slice.frequency
                deviation: slice.deviation
              }
            return slices
          .fail console.error

      retrieveSlices: (featureId) =>
        $http.get API_URI + "targets/#{@targetId}/features/#{featureId}/slices"
          .then (response) ->
            sortByValue = (a, b) -> a.value - b.value
            slices = response.data.map (slice) ->
              return {
                range: [slice.from_value, slice.to_value]
                frequency: slice.frequency
                deviation: slice.deviation
                marginal: slice.marginal_distribution.sort sortByValue
                conditional: slice.conditional_distribution.sort sortByValue
              }
            return slices
          .fail console.error

      getProbabilityDistribution: (rangesSpecification) =>
        $http.post API_URI + "targets/#{@targetId}/distributions", rangesSpecification
          .then (response) ->
            distribution = response.data
            return distribution
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
      waitForWebsocketEvent: waitForWebsocketEvent

      setAuthorizationHeader: (header) ->
        $http.defaults.headers.common['Authorization'] = header

      isLoggedIn: =>
        @loginToken = localStorage.getItem TOKEN_KEY
        if @loginToken?
          @setAuthorizationHeader "Token #{@loginToken}"
          return true
        return false

      login: (user) =>
        return $http.post API_URI + 'auth/login', username: user.name, password: user.password
          .then (response) =>
            @loginToken = response.data.token
            @setAuthorizationHeader "Token #{@loginToken}"
            localStorage.setItem TOKEN_KEY, @loginToken
            return response.data

      register: (user) =>
        return $http.post API_URI + 'users/register', username: user.name, password: user.password
          .then =>
            @login user

      logout: =>
        return $http.delete API_URI + 'auth/logout'
          .then (response) =>
            @setAuthorizationHeader null
            @loginToken = null
            localStorage.removeItem TOKEN_KEY
          .fail console.error

      getExperiment: (dataset) =>
        experiment = @experiment or Experiment.restore()
        if experiment? and (not dataset? or experiment.dataset.id == dataset.id)
          @experiment = experiment
          return $q.resolve experiment

        saveAndPersist = (experiment) =>
          @experiment = experiment
          experiment.store()
          return experiment

        if not dataset?
          return retrieveDatasets()
            .then (datasets) ->
              if datasets.length > 0
                return datasets[0]
              return $q.reject {
                noDatasets: true
                msg: 'No datasets available'
              }
            .then Experiment.create
            .then saveAndPersist

        return retrieveExperiments()
          .then (experiments) ->
            matchingExperiments = experiments.filter (sess) -> sess.dataset.id == dataset.id
            if matchingExperiments.length > 0
              experiment = Experiment.fromJson matchingExperiments[0]
              experiment.dataset = dataset
              return experiment
            return Experiment.create dataset
          .then saveAndPersist

    return new Service()
]
