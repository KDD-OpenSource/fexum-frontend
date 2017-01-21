
app.factory 'backendService', ['$http', '$websocket', '$q', 'apiUri', 'socketUri', \
                                ($http, $websocket, $q, apiUri, socketUri) ->
  service =
    currentSession: ->
      deferred = $q.defer()
      @.openSession(null, -> deferred.resolve(@.session))
      return deferred.promise
    session: null
    retrieveDatasets: (completion) ->
      $http.get apiUri + 'datasets'
        .then (response) ->
          datasets = response.data
          completion datasets
    retrieveHistogramBuckets: (featureId, completion) ->
      $http.get apiUri + "features/#{featureId}/histogram"
        .then (response) ->
          console.log 'bucket'
          buckets = response.data.map (bucket) ->
            return {
              range: [bucket.from_value, bucket.to_value]
              count: bucket.count
            }
          completion(buckets)
        .catch console.error
    retrieveSamples: (featureId, completion) ->
      $http.get apiUri + "features/#{featureId}/samples"
        .then (response) ->
          console.log 'samples'
          samples = response.data.map (sample, idx) ->
            {
              x: idx
              y: sample.value
            }
          completion(samples)
        .catch console.error
    retrieveFeatures: (dataset, completion) ->
      $http.get apiUri + "datasets/#{dataset}/features"
        .then (response) ->
          # Response is in the form
          # [{name, rank, mean, variance, min, max}, ...]
          features = response.data
          # Order does not matter and is preferred random for rendering => shuffle
          features.shuffle()
          completion(features)
        .catch console.error
    openSession: (datasetId, sessionCompletion) ->
      if session? and not datasetId?
        sessionCompletion()
        return

      @.retrieveDatasets (datasets) ->
        dataset = datasets[0]
        if datasetId?
          dataset = datasets.filter((ds) -> ds.id == datasetId)[0]
        return dataset
      .then (dataset) ->
        $http.post apiUri + 'sessions', {
          dataset: dataset.id
        }
        .then (response) ->
          newSession = response.data
          session = {
            id: newSession.id
            dataset: newSession.dataset
            target: newSession.target
            retrieveFeatures: (completion) ->
              service.retrieveFeatures @.dataset, completion
            setTarget: (targetFeatureId, completion) ->
              @.target = targetFeatureId
              # Notify server of new target
              $http.put apiUri + "sessions/#{@.id}/target", {
                  target: targetFeatureId
                }
                .then (response) ->
                  console.log "Set new target #{targetFeatureId} on server"
                .catch console.error

              # Listen for when relevancy calculations are finished
              @.enqueueLoadingTask 'relevancy-update',
                "Running feature selection for #{targetFeatureId}", ->
                  session.retrieveRarResults(completion)
            retrieveSlices: (featureId, completion) ->
              $http.get apiUri + "sessions/#{@.id}/features/#{featureId}/slices"
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
                  completion(slices)
                .catch console.error
            retrieveRarResults: (completion) ->
              $http.get apiUri + "sessions/#{@.id}/rar_results"
                .then (response) ->
                  rar_results = response.data
                  completion(rar_results)

            # Stuff related to listening for rar result
            wsStream: $websocket socketUri
            loadingDict: {}
            enqueueLoadingTask: (eventName, message, completion) ->
              item =
                completion: completion
                message: message
              @.loadingDict["ws/#{eventName}"] = item
          }

          session.wsStream.onMessage (message) ->
            jsonData = JSON.parse message.data
            session.loadingDict["ws/#{jsonData.event_name}"].completion(jsonData)
            session.loadingDict["ws/#{jsonData.event_name}"] = null
          @.session = session
          sessionCompletion()
  return service
]