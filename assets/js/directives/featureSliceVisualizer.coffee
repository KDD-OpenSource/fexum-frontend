app.directive 'featureSliceVisualizer', ['$timeout', 'chartTemplates', 'chartColors',\
                                          ($timeout, chartTemplates, chartColors) ->
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
        scope.histogram = angular.merge {}, chartTemplates.historicalBarChart,
          options:
            chart:
              xAxis:
                axisLabel: scope.feature.name
          data: [
            {
              values: getSubBuckets()
              key: scope.feature.name
            }
          ]
        marginalProbDistr =
          values: []
          key: 'Marginal probability distribution'
          area: true
          color: chartColors.targetColor
        conditionalProbDistr =
          values: []
          key: 'Conditional probability distribution'
          area: true
          color: chartColors.selectionColor2
        scope.probabilityDistributions = angular.merge {}, chartTemplates.multiBarChart,
          options:
            chart:
              xAxis:
                axisLabel: scope.targetFeature.name
              yAxis:
                axisLabel: 'Probability density'
                tickFormat: d3.format '.0%'
              stacked: false
              showControls: false
              legend:
                rightAlign: false
                maxKeyLength: 1000
          data: [marginalProbDistr, conditionalProbDistr]

        # Store distributions in scope to update later
        scope.marginalProbDistr = scope.probabilityDistributions.data[0]
        scope.conditionalProbDistr = scope.probabilityDistributions.data[1]

        return

      # charts should be set up when layouting is done
      # sadly there is no event available for that
      $timeout scope.setupCharts, 200

      scope.$watch 'range', ->
        # reset slice selection when new bucket got selected and it is no longer in the bucket
        if scope.selectedSlice? and
            (scope.selectedSlice.range[0] > scope.range[1] or
            scope.selectedSlice.range[1] < scope.range[0])
          scope.selectedSlice = null
        # update histogram
        if scope.histogram
          scope.histogram.data[0].values = getSubBuckets()
        return

      scope.showProbabilityDistributions = (slice) ->
        generateChartDataFromValues = (item, idx, arr) ->
          return { x: item.value, y: item.frequency }

        setValues = ->
          scope.marginalProbDistr.values = slice.marginal.map generateChartDataFromValues
          scope.conditionalProbDistr.values = slice.conditional.map generateChartDataFromValues

        # layouting needs to be done first, then we can redraw the chart
        $timeout setValues, 0

        return
      return
  }
]
