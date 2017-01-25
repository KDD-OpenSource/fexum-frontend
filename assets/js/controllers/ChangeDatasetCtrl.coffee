app.controller 'ChangeDatasetCtrl', [
  '$scope',
  '$location',
  'Upload',
  'backendService',
  '$analytics'
  ($scope, $location, Upload, backendService, $analytics) ->

    $scope.uploadRunning = false
    $scope.progress = 0

    setCurrentDatasetFromSession = (session) ->
      $scope.datasetId = session.dataset.id
      $scope.datasetName = session.dataset.name
      filter = (d) -> d.id == session.dataset.id
      $scope.currentDataset = $scope.datasets.filter(filter)[0]

    backendService.retrieveDatasets()
      .then (datasets) ->
        $scope.datasets = datasets
        return backendService.getSession()
      .then setCurrentDatasetFromSession
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
            category: 'd' + dataset.name,
            label: 'datasetInit'
      }
      console.log dataset

      backendService.getSession dataset
        .then setCurrentDatasetFromSession
        .fail console.error
      # Change back to overview
      $location.path '/'

      return
]
