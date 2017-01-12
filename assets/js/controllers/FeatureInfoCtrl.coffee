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
          dispatch:
            renderEnd: ->
              # somehow nvd3 only defines after the first rendering
              if not $scope.lineChartApi?
                return

              element = $scope.lineChartApi.getElement()
              svgElement = element[0]

              chart = $scope.lineChartApi.getScope().chart
              if not chart?
                return

              highlightedRange = if $scope.selectedRange? then [$scope.selectedRange] else []

              highlightRect = d3.select svgElement
                .select 'g.nv-focus'
                .selectAll 'rect.highlight'
                .data highlightedRange
              highlightRect.exit().remove()
              highlightRect.enter().append 'rect'
                .attr 'class', 'highlight'

              highlightRect
                .attr 'x', chart.xAxis.scale() chart.xAxis.domain()[0]
                .attr 'y', (d) -> chart.yAxis.scale() d[1]
                .attr 'width', chart.xAxis.scale()(chart.xAxis.domain()[1]) \
                                - chart.xAxis.scale()(chart.xAxis.domain()[0])
                .attr 'height', (d) -> chart.yAxis.scale()(d[0]) \
                                        - chart.yAxis.scale()(d[1])
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
                  $scope.lineChartApi.update()
                return
          dispatch:
            renderEnd: ->
              element = $scope.histogramApi.getElement()
              svg = d3.select element[0]
              svg.selectAll 'rect.nv-bar'
                .classed 'selected', (d) ->
                  return d.range == $scope.selectedRange
                .classed 'significant', (d) ->
                  containedSlices = $scope.feature.slices.filter (slice) ->
                    return slice.range[0] < d.range[1] and
                            slice.range[1] > d.range[0]
                  return containedSlices.length > 0
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

    $scope.$watch 'feature.slices', $scope.histogramApi.update

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
