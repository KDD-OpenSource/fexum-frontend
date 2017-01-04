app.directive 'featureSliceVisualizer', ['$timeout', ($timeout) ->
  return {
    restrict: 'E'
    template: JST['assets/templates/featureSliceVisualizer']
    scope:
      feature: '='
      targetFeature: '='
      range: '='
      close: '&onClose'
    link: (scope, element, attrs) ->

      # Filter the feature buckets for the selected range
      getSubBuckets = ->
        if not scope.feature.buckets
          return []
        scope.feature.buckets.filter (bucket) ->
          return bucket.range[0] >= scope.range[0] and
                  bucket.range[1] <= scope.range[1]

      scope.setupCharts = ->
        scope.histogram =
          options:
            chart:
              type: 'historicalBarChart'
              x: (data) -> data.range[1]
              y: (data) -> data.count
              valueFormat: d3.format '.2e'
              xAxis:
                axisLabel: 'Value'
                tickFormat: d3.format '.2e'
              yAxis:
                axisLabel: 'Count'
                tickFormat: d3.format '.2e'
              margin:
                top: 20
                right: 20
                bottom: 45
                left: 60
          data: [
            {
              values: getSubBuckets()
              key: scope.feature.name
            }
          ]
        scope.marginalProbDistr =
          values: []
          key: 'Marginal probability distribution'
          area: true
          color: 'rgb(31, 119, 180)'
        scope.conditionalProbDistr =
          values: []
          key: 'Conditional probability distribution'
          area: true
          color: '#F44336'
        scope.probabilityDistributions =
          options:
            chart:
              type: 'lineChart'
              x: (data) -> data.x
              y: (data) -> data.y
              valueFormat: d3.format '.2e'
              xAxis:
                axisLabel: 'Value'
                tickFormat: d3.format '.2e'
              yAxis:
                axisLabel: 'Probability density'
                tickFormat: d3.format '.2e'
              legend:
                rightAlign: false
                maxKeyLength: 1000
              margin:
                top: 20
                right: 20
                bottom: 45
                left: 60
          data: [scope.marginalProbDistr, scope.conditionalProbDistr]

        return

      # charts should be set up when layouting is done
      # sadly there is no event available for that
      $timeout scope.setupCharts, 200

      scope.$watch 'range', ->
        # reset slice selection when new bucket got selected
        scope.selectedSlice = null
        # update histogram
        if scope.histogram
          scope.histogram.data[0].values = getSubBuckets()
        return

      scope.showProbabilityDistributions = (slice) ->
        scope.selectedSlice = slice

        targetRange = [scope.targetFeature.min, scope.targetFeature.max]
        targetRangeLength = targetRange[1] - targetRange[0]

        generateChartDataFromValues = (y, idx, arr) ->
          x = targetRange[0] + (idx / (arr.length - 1)) * targetRangeLength
          return { x: x, y: y }

        setValues = ->
          scope.marginalProbDistr.values = slice.marginal.map generateChartDataFromValues
          scope.conditionalProbDistr.values = slice.conditional.map generateChartDataFromValues

        # layouting needs to be done first, then we can redraw the chart
        $timeout setValues, 0

        return
      return
  }
]
