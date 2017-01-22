app.factory 'backendService', [
  '$rootScope',
  '$http',
  '$websocket',
  '$q',
  ($rootScope, $http, $websocket, $q) ->

    API_URI = '/api/'
    SOCKET_URI = "ws://#{window.location.host}/socket"

    retrieveDatasets = ->
      $http.get API_URI + 'datasets'
        .then (response) ->
          datasets = response.data
          return datasets
        .catch console.error

    retrieveHistogramBuckets = (featureId) ->
      $http.get API_URI + "features/#{featureId}/histogram"
        .then (response) ->
          buckets = response.data.map (bucket) ->
            return {
              range: [bucket.from_value, bucket.to_value]
              count: bucket.count
            }
          return buckets
        .catch console.error

    retrieveSamples = (featureId) ->
      $http.get API_URI + "features/#{featureId}/samples"
        .then (response) ->
          samples = response.data.map (sample, idx) ->
            return {
              x: idx
              y: sample.value
            }
          return samples
      .catch console.error

    wsStream = $websocket SOCKET_URI
    wsStream.onMessage (message) ->
      jsonData = JSON.parse message.data
      $rootScope.$broadcast "ws/#{jsonData.event_name}", jsonData.payload

    waitForWebsocketEvent = (eventName) ->
      return $q (resolve, reject) ->
        removeListener = $rootScope.$on 'ws/' + eventName, ->
          resolve.apply @, arguments
          removeListener()

    class Session

      @LAST_SESSION_KEY = 'lastSession'

      constructor: (@id, @dataset, @target) ->
        @deregisterListeners =
          $rootScope.$on 'ws/relevancy-update', @retrieveRarResults

      destroy: ->
        @deregisterListeners()

      @create: (datasetId) ->
        return $http.post API_URI + 'sessions', dataset: datasetId
          .then (response) ->
            return new Session(
              response.data.id,
              response.data.dataset,
              response.data.target
            )

      @restore: ->
        lastSessionJson = localStorage.getItem @LAST_SESSION_KEY
        if lastSessionJson?
          lastSession = angular.fromJson lastSessionJson
          return new Session(
            lastSession.id,
            lastSession.dataset,
            lastSession.target
          )

      store: ->
        lastSession =
          id: @id
          dataset: @dataset
          target: @target
        localStorage.setItem @LAST_SESSION_KEY, angular.toJson(lastSession)

      retrieveFeatures: ->
        $http.get API_URI + "datasets/#{@dataset}/features"
          .then (response) ->
            # Response is in the form
            # [{name, rank, mean, variance, min, max}, ...]
            features = response.data
            # Order does not matter and is preferred random for rendering => shuffle
            features.shuffle()
            return features
          .catch console.error

      setTarget: (targetFeatureId) ->
        @target = targetFeatureId
        # Notify server of new target
        $http.put API_URI + "sessions/#{@id}/target", target: targetFeatureId
          .then (response) ->
            console.log "Set new target #{targetFeatureId} on server"
          .catch console.error

      retrieveSlices: (featureId) ->
        $http.get API_URI + "sessions/#{@id}/features/#{featureId}/slices"
          .then (response) ->
            sortByValue = (a, b) -> a.value - b.value
            slices = response.data.map (slice) ->
              return {
                range: [slice.from_value, slice.to_value]
                frequency: slice.frequency
                significance: slice.significance
                deviation: slice.deviation
                marginal: slice.marginal_distribution.sort sortByValue
                conditional: slice.conditional_distribution.sort sortByValue
              }
            return slices
          .catch console.error

      retrieveRarResults: ->
        $http.get API_URI + "sessions/#{@id}/rar_results"
          .then (response) ->
            rar_results = response.data
            return rar_results

    service =

      retrieveDatasets: retrieveDatasets
      retrieveHistogramBuckets: retrieveHistogramBuckets
      retrieveSamples: retrieveSamples
      waitForWebsocketEvent: waitForWebsocketEvent

      getSession: (datasetId) ->
        session = @session or Session.restore()
        if session?
          @session = session
          return $q.resolve session

        if not datasetId?
          return retrieveDatasets()
            .then (datasets) -> datasets[0]
            .then Session.create
            .then (session) -> @session = session

        return Session.create dataSetId
          .then (session) -> @session = session

    return service
]
