app.directive 'featureSliceVisualizer', [
  '$timeout',
  'chartTemplates',
  'chartColors',
  'backendService',
  '$analytics'
  ($timeout, chartTemplates, chartColors, backendService, $analytics) ->

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

        getScatterData = (selected) ->
          if scope.targetFeature.samples? and scope.selectedSlice?
            return [0...scope.targetFeature.samples.length].map (idx) ->
                x: scope.targetFeature.samples[idx].y, y: scope.feature.samples[idx].y
            .filter (e) ->
                (scope.selectedSlice.range[0] <= e.y <= scope.selectedSlice.range[1]) == selected
          else return []

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

          scope.scatterChart = angular.merge {}, chartTemplates.scatterChart,
            options:
              chart:
                xAxis:
                  axisLabel: scope.targetFeature.name
                yAxis:
                  axisLabel: scope.feature.name
                legend:
                  updateState: false
            data: [
              {
                values: getScatterData(false)
                key: 'Unselected',
                color: chartColors.targetColor
              },
              {
                values: getScatterData(true)
                key: 'Selected',
                color: chartColors.selectionColor2
              }
            ]

          backendService.retrieveSamples scope.targetFeature.id
            .then (samples) ->
              scope.targetFeature.samples = samples
              scope.scatterChart.data[0].values = getScatterData(false)
              scope.scatterChart.data[1].values = getScatterData(true)
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
          backendService.getSession().then (session) ->
            $analytics.eventTrack 'sliceClick', {
              category: "d#{session.dataset.name}|t#{scope.targetFeature.name}" +
                        "|f#{scope.feature.name}",
              label: 's' + slice.range[0] + '-' + slice.range[1]
            }

          generateChartDataFromValues = (item, idx, arr) ->
            return { x: item.value, y: item.frequency }

          setValues = ->
            scope.marginalProbDistr.values = slice.marginal.map generateChartDataFromValues
            scope.conditionalProbDistr.values = slice.conditional.map generateChartDataFromValues

            scope.scatterChart.data[0].values = getScatterData(false)
            scope.scatterChart.data[1].values = getScatterData(true)

          # layouting needs to be done first, then we can redraw the chart
          $timeout setValues, 0

          return
        return
    }
]
