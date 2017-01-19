
app.factory 'backendService', ['$http', '$websocket', 'apiUri', 'socketUri', \
                                ($http, $websocket, apiUri, socketUri) ->
  service =
    session: null
    wsStream: $websocket socketUri
    loadingDict: {}
    enqueueLoadingTask: (eventName, message, completion) ->
      item =
        completion: completion
        message: message
      @.loadingDict.push item

    retrieveFeatures: (completion) ->
      $http.get apiUri + 'features'
        .then (response) ->
          # Response is in the form
          # [{name, relevancy, redundancy, rank, mean, variance, min, max}, ...]
          features = response.data
          # Order does not matter and is preferred random for rendering => shuffle
          features.shuffle()
          completion(features)
        .catch console.error
     # Retrieve target
    retrieveTarget: (completion) ->
      $http.get apiUri + 'features/target'
        .then (response) ->
          # Response is in the form
          # {feature: {name, ...}}
          targetFeatureName = response.data.feature.name
          completion(targetFeatureName)
        .catch (response) ->
          if response.status == 204
            console.log 'No target set'
          else
            console.error response
    setTarget: (targetFeature, completion) ->
      # Notify server of new target
      $http.put(apiUri + 'features/target', {
          feature:
            name: targetFeature.name
        })
        .then (response) ->
          console.log "Set new target #{targetFeature.name} on server"
          completion()
        .catch console.error

      # Listen for when relevancy calculations are finished
      @.enqueueLoadingTask 'relevancy-update',
        "Running feature selection for #{targetFeature.name}",
        ->
          backendService.retrieveFeatures(completion)
    retrieveSamples: (feature, completion) ->
      $http.get apiUri + "features/#{feature.name}/samples"
        .then (response) ->
          samples = response.data.map (sample, idx) ->
            return {
              x: idx
              y: sample.value
            }
          completion()
        .catch console.error
    retrieveHistogramBuckets: (feature, completion) ->
      $http.get apiUri + "features/#{feature.name}/histogram"
        .then (response) ->
          buckets = response.data.map (bucket) ->
            return {
              range: [bucket.from_value, bucket.to_value]
              count: bucket.count
            }
          completion()
        .catch console.error
    retrieveSlices: (feature, completion) ->
      $http.get apiUri + "features/#{feature.name}/slices"
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
          completion()
        .catch console.error

  service.wsStream.onMessage (message) ->
    jsonData = JSON.parse message.data
    @.loadingDict["#{jsonData.event_name}"].completion(jsonData)
      .then -> @.loadingDict[eventName] = null

  return service
]