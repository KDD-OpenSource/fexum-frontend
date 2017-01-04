app.controller 'FeatureInfoCtrl', ['$scope', '$routeParams', '$timeout', '$http', 'apiUri',\
                                    ($scope, $routeParams, $timeout, $http, apiUri) ->

  retrieveSelectedFeature = (features) ->
    featurePredicate = (feature) -> feature.name == $routeParams.featureName
    $scope.feature = features.filter(featurePredicate)[0]

  # Retrieve selected feature object
  if $scope.features
    retrieveSelectedFeature $scope.features
  else
    # Setup mock feature until loaded
    $scope.feature =
      name: $routeParams.featureName

  $scope.$watch 'features', (newFeatures) ->
    if newFeatures
      retrieveSelectedFeature newFeatures

  $scope.retrieveSamples = ->
    $http.get apiUri + "features/#{$scope.feature.name}/samples"
      .then (response) ->
        samples = response.data.map (sample, idx) ->
          return {
            x: idx
            y: sample.value
          }
        $scope.feature.samples = samples
      .catch console.error

  $scope.retrieveHistogramBuckets = ->
    $http.get apiUri + "features/#{$scope.feature.name}/histogram"
      .then (response) ->
        buckets = response.data.map (bucket) ->
          return {
            range: [bucket.from_value, bucket.to_value]
            count: bucket.count
          }
        $scope.feature.buckets = buckets
      .catch console.error

  $scope.retrieveSlices = ->
    $http.get apiUri + "features/#{$scope.feature.name}/slices"
      .then (response) ->
        slices = response.data
        $scope.feature.slices = slices
      .catch console.error

  $scope.setupCharts = ->
    $scope.lineChart =
      options:
        chart:
          type: 'lineChart'
          x: (data) -> data.x
          y: (data) -> data.y
          xAxis:
            axisLabel: 'Time (seconds)'
          yAxis:
            axisLabel: 'Value'
          margin:
            top: 20
            right: 20
            bottom: 45
            left: 60
      data: [
        {
          values: $scope.feature.samples or []
          key: $scope.feature.name
        }
      ]
    $scope.histogram =
      options:
        chart:
          type: 'historicalBarChart'
          x: (data) -> data.range[1]
          y: (data) -> data.count
          xAxis:
            axisLabel: 'Value'
          yAxis:
            axisLabel: 'Count'
          margin:
            top: 20
            right: 20
            bottom: 45
            left: 60
          bars:
            dispatch:
              elementClick: (event) ->
                $scope.$apply ->
                  $scope.selectedRange = event.data.bucket
                return
      data: [
        {
          values: $scope.feature.buckets or []
          key: $scope.feature.name
        }
      ]

    $scope.$watch 'feature.samples', (newSamples) ->
      if newSamples
        $scope.lineChart.data[0].values = newSamples

    $scope.$watch 'feature.buckets', (newBuckets) ->
      if newBuckets
        $scope.histogram.data[0].values = newBuckets

    $scope.retrieveSamples()
    $scope.retrieveHistogramBuckets()
    return

  $scope.clearSelectedRange = ->
    $scope.selectedRange = null
    return

  # charts should be set up when layouting is done
  # sadly there is no event available for that
  $timeout $scope.setupCharts, 200

  $scope.retrieveSlices()

  return

]
