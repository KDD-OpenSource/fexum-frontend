app.controller 'ChangeDatasetCtrl', [
  '$scope',
  '$location',
  'Upload',
  'backendService',
  'systemStatus',
  '$analytics'
  ($scope, $location, Upload, backendService, systemStatus, $analytics) ->

    $scope.uploadRunning = false
    $scope.progress = 0

    setCurrentDatasetFromExperiment = (experiment) ->
      filter = (d) -> d.id == experiment.dataset.id
      $scope.currentDataset = $scope.datasets.filter(filter)[0]
      return experiment

    backendService.retrieveDatasets()
      .then (datasets) ->
        $scope.datasets = datasets
        return backendService.getExperiment()
      .then setCurrentDatasetFromExperiment
      .fail console.error

    $scope.upload = (file) ->

      success = (response) ->
        $scope.uploadRunning = false
        $scope.progress = 0
        $scope.changeDataset response.data

      error = (error) ->
        console.error error
        $scope.uploadRunning = false

      progress = (evt) ->
        progressPercentage = parseInt(100.0 * evt.loaded / evt.total)
        $scope.progress = progressPercentage

      $scope.currentUpload = Upload
        .upload
          url: 'api/datasets/upload'
          method: 'PUT'
          data:
            file: file
        .then success, error, progress

      $scope.uploadRunning = true

    $scope.changeDataset = (dataset) ->
      # Track a user selecting a new dataset
      $analytics.eventTrack 'datasetSelected', {
            category: 'd' + dataset.id,
            label: 'datasetInit'
      }

      backendService.getExperiment dataset
        .then setCurrentDatasetFromExperiment
        .then $scope.initializeFromExperiment
        .then systemStatus.checkIfDatasetIsProcessing
        .fail console.error
      
      # Change back to overview
      $location.path '/change-target'

      return
]
