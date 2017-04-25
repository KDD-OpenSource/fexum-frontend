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

    # TODO backend does not support status whether feature selection is still running yet

    checkIfDatasetIsProcessing = ->
      return backendService.getExperiment()
        .then (experiment) -> experiment.retrieveDatasetInfo()
        .then (datasetInfo) ->
          if datasetInfo.status == 'processing'
            return waitForDatasetProcessed datasetInfo
          return
        .fail console.error

    waitForDatasetProcessed = (dataset) ->
      datasetProcessed = $q (resolve, reject) ->
        unregister = $rootScope.$on 'ws/dataset', (event, payload) ->
          if payload.data.status == 'done' and payload.pk == dataset.id
            resolve payload.data
            unregister()
      addLoadingQueueItem datasetProcessed, "Processing dataset #{dataset.name}"
      return datasetProcessed

    waitForFeatureSelection = (targetFeature) ->
      # Create promise that waits for updated relevancies
      # TODO show user current iteration and wait until HiCS is completely terminated
      relevancyUpdate = backendService.waitForWebsocketEvent 'NOT_YET_IMPLEMENTED'
      addLoadingQueueItem relevancyUpdate, "Running iterative feature selection for #{targetFeature.name}"
      return relevancyUpdate

    # Initialize system status
    checkIfDatasetIsProcessing()

    return {
      loadingQueue: loadingQueue
      waitForFeatureSelection: waitForFeatureSelection
      waitForDatasetProcessed: waitForDatasetProcessed
      checkIfDatasetIsProcessing: checkIfDatasetIsProcessing
    }
]
