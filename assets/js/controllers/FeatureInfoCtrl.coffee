app.controller 'FeatureInfoCtrl', ['$scope', '$routeParams', '$timeout', '$http', 'apiUri', \
                                    'chartTemplates', 'chartColors', 'backendService', \
                                    ($scope, $routeParams, $timeout, $http, apiUri, \
                                    chartTemplates, chartColors, backendService) ->

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

  $scope.setupCharts = ->
    
    # Merges buckets in chunks of mergeCount
    mergeBuckets = (buckets, mergeCount) ->
      # Split buckets array into multiple arraies of size mergeCount
      subBuckets = (buckets[index...index + mergeCount] \
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
          color: chartColors.defaultColor
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

              slicesContained = (d) ->
                return $scope.feature.slices.filter (slice) ->
                  return slice.range[0] < d.range[1] and
                          slice.range[1] > d.range[0]

              buckets = $scope.histogram.data[0].values
              bucketSignificances = buckets.map (bucket) ->
                slices = slicesContained bucket
                if slices.length == 0
                  return null
                sliceSignificances = slices.map (slice) -> slice.significance
                return sliceSignificances.mean()

              filteredSignificances = bucketSignificances.filter (b) -> b?
              minSignificance = Math.min.apply null, filteredSignificances
              maxSignificance = Math.max.apply null, filteredSignificances

              svg.selectAll 'rect.nv-bar'
                .classed 'selected', (d) ->
                  return d.range == $scope.selectedRange
                .classed 'significant', (d) ->
                  return slicesContained(d).length > 0
                .attr 'significance', (d, i) ->
                  significance = bucketSignificances[i]
                  if not significance?
                    return 0
                  scaledSignificance = (significance - minSignificance) /
                                        (maxSignificance - minSignificance)
                  significanceLevel = Math.ceil(scaledSignificance * 10) * 10
                  return significanceLevel
      data: [
        {
          values: mergeBucketsSqrt $scope.feature.buckets
          key: $scope.feature.name
          color: chartColors.defaultColor
        }
      ]

    $scope.$watch 'feature.samples', (newSamples) ->
      if newSamples
        $scope.lineChart.data[0].values = newSamples

    $scope.$watch 'feature.buckets', (newBuckets) ->
      if newBuckets
        $scope.histogram.data[0].values = mergeBucketsSqrt newBuckets

    $scope.$watch 'feature.slices', $scope.histogramApi.update

    backendService.retrieveSamples $scope.feature.id, (samples) ->
      $scope.feature.samples = samples
    backendService.retrieveHistogramBuckets $scope.feature.id, (buckets) ->
      $scope.feature.buckets = buckets
    return

  $scope.clearSelectedRange = ->
    $scope.selectedRange = null
    return

  # charts should be set up when layouting is done
  # sadly there is no event available for that
  $timeout $scope.setupCharts, 200

  backendService.currentSession().then (session) ->
    session.retrieveSlices $scope.feature.id, (slices) ->
      $scope.feature.slices = slices

  return

]
