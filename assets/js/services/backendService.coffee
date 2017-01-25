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

    retrieveSessions = ->
      $http.get API_URI + 'sessions'
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

    class Session

      @LAST_SESSION_KEY = 'lastSession'

      constructor: (@id, @dataset, @targetId) ->

      @create: (dataset) =>
        return $http.post API_URI + 'sessions', dataset: dataset.id
          .then (response) =>
            session = @fromJson response.data
            session.dataset = dataset
            return session

      @restore: =>
        lastSessionJson = localStorage.getItem @LAST_SESSION_KEY
        if lastSessionJson?
          lastSession = angular.fromJson lastSessionJson
          return @fromJson lastSession

      @fromJson: (json) ->
        return new Session(
          json.id,
          json.dataset,
          json.targetId
        )

      store: =>
        lastSession =
          id: @id
          dataset: @dataset
          targetId: @targetId
        localStorage.setItem Session.LAST_SESSION_KEY, angular.toJson(lastSession)

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
        $http.put API_URI + "sessions/#{@id}/target", target: targetFeatureId
          .then (response) =>
            @targetId = targetFeatureId
            @store()
            # console.log "Set new target #{targetFeatureId} on server"
          .fail console.error

      retrieveSlices: (featureId) =>
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
          .fail console.error

      retrieveRarResults: =>
        $http.get API_URI + "sessions/#{@id}/rar_results"
          .then (response) ->
            rar_results = response.data
            return rar_results

    service =
      retrieveDatasets: retrieveDatasets
      retrieveHistogramBuckets: retrieveHistogramBuckets
      retrieveSamples: retrieveSamples
      waitForWebsocketEvent: waitForWebsocketEvent

      getSession: (dataset) ->
        session = @session or Session.restore()
        if session? and (not dataset? or session.dataset.id == dataset.id)
          @session = session
          return $q.resolve session

        saveAndPersist = (session) =>
          @session = session
          session.store()
          return session

        if not dataset?
          return retrieveDatasets()
            .then (datasets) ->
              if datasets.length > 0
                return datasets[0]
              else
                return $q.reject 'No datasets available'
            .then Session.create
            .then saveAndPersist
            .fail console.error

        return retrieveSessions()
          .then (sessions) ->
            matchingSessions = sessions.filter (sess) -> sess.dataset == dataset.id
            if matchingSessions.length > 0
              session = Session.fromJson matchingSessions[0]
              session.dataset = dataset
              return session
            return Session.create dataset
          .then saveAndPersist
          .fail console.error

    return service
]
