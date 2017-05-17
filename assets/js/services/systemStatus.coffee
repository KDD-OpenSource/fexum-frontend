app.factory 'systemStatus', [
  'backendService',
  '$rootScope',
  '$q',
  (backendService, $rootScope, $q) ->

    loadingQueue = []
    addLoadingQueueItem = (promise, message) ->
      item =
        promise: promise
        message: message
      loadingQueue.push item
      promise.then (result) ->
        # Remove from loading queue when done
        itemIndex = loadingQueue.indexOf item
        loadingQueue.splice itemIndex, 1

    waitForDatasetProcessed = ->
      return backendService.getExperiment()
        .then (experiment) -> experiment.retrieveDatasetInfo()
        .then (datasetInfo) ->
          if datasetInfo.status == 'processing'
            datasetProcessed = backendService.waitForWebsocketEvent 'dataset', (event, payload) ->
              return payload.data.status == 'done' and payload.pk == datasetInfo.id
            addLoadingQueueItem datasetProcessed, "Processing dataset #{datasetInfo.name}"
            return datasetProcessed
          return
        .fail console.error

    waitForFeatureSelection = (targetFeature) ->
      backendService.getFeatureSelectionStatus()
        .then (statusList) ->
          targetStatus = statusList.find (s) -> s.target == targetFeature.id
          unless targetStatus
            return
          curIter = targetStatus.current_iteration
          maxIter = targetStatus.max_iteration
          updateCondition = (event, payload) ->
            return data.type == 'default_hics' and data.target == targetFeature.id
          update = backendService.waitForWebsocketEvent 'calculation', updateCondition
          message = "Running iteration #{curIter} of #{maxIter} for #{targetFeature.name}"
          addLoadingQueueItem update, message
          # Recursively wait until all iterations are done
          return update.then -> waitForFeatureSelection targetFeature

    return {
      loadingQueue: loadingQueue
      waitForFeatureSelection: waitForFeatureSelection
      waitForDatasetProcessed: waitForDatasetProcessed
    }
]
