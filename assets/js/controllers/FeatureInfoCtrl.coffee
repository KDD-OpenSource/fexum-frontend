app.controller 'FeatureInfoCtrl', ['$scope', '$routeParams', '$timeout', '$http', 'apiUri', 'chartTemplates',\
                                    ($scope, $routeParams, $timeout, $http, apiUri, chartTemplates) ->

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
        slices = response.data.map (slice) ->
          sortByValue = (a, b) -> a.value - b.value
          return {
            range: [slice.from_value, slice.to_value]
            score: slice.score
            marginal: slice.marginal_distribution.sort sortByValue
            conditional: slice.conditional_distribution.sort sortByValue
          }
        $scope.feature.slices = slices
      .catch console.error

  $scope.setupCharts = ->
    
    # Merges buckets in chunks of mergeCount
    mergeBuckets = (buckets, mergeCount) ->
      # Split buckets array into multiple arraies of size mergeCount
      subBuckets = (buckets[index...index+mergeCount] \
                      for index in [0...buckets.length] by mergeCount)
      # Combine each bucketlist to a single bucket
      subBuckets = subBuckets.map (bucketList) ->
        countSum = bucketList.reduce ((a, bucket) -> a + bucket.count), 0
        return {
          range: [bucketList[0].range[0], bucketList[bucketList.length - 1].range[1]]
          count: countSum
        }
      return subBuckets

    mergeBucketsSqrt = (buckets) ->
      if not buckets or buckets.length == 0
        return []
      bucketCount = buckets.length
      bucketMergeCount = Math.floor(Math.sqrt(buckets.length))
      return mergeBuckets buckets, bucketMergeCount
        
    $scope.lineChart = angular.merge {}, chartTemplates.lineChart,
      options:
        chart:
          xAxis:
            axisLabel: 'Time (seconds)'
          yAxis:
            axisLabel: 'Value'
      data: [
        {
          values: $scope.feature.samples or []
          key: $scope.feature.name
        }
      ]
    $scope.histogram = angular.merge {}, chartTemplates.historicalBarChart,
      options:
        chart:
          xAxis:
            axisLabel: $scope.feature.name
          bars:
            dispatch:
              elementClick: (event) ->
                $scope.$apply ->
                  $scope.selectedRange = event.data.range
                  $scope.histogramApi.update()
                return
          dispatch:
            renderEnd: ->
              element = $scope.histogramApi.getElement()
              d3.select(element[0]).selectAll 'rect.nv-bar'
                .classed 'selected', (d) ->
                  return d.range == $scope.selectedRange
      data: [
        {
          values: mergeBucketsSqrt $scope.feature.buckets
          key: $scope.feature.name
        }
      ]

    $scope.$watch 'feature.samples', (newSamples) ->
      if newSamples
        $scope.lineChart.data[0].values = newSamples

    $scope.$watch 'feature.buckets', (newBuckets) ->
      if newBuckets
        $scope.histogram.data[0].values = mergeBucketsSqrt newBuckets

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
