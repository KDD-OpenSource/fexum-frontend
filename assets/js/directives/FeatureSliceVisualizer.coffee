app.directive 'featureSliceVisualizer', ['$timeout', ($timeout) ->
  return {
    restrict: 'E'
    template: JST['assets/templates/featureSliceVisualizer']
    scope:
      feature: '='
      range: '='
      close: '&onClose'
    link: (scope, element, attrs) ->

      # TODO remove this mockup stuff
      bucketFromId = (id, max) ->
        distance = scope.range[1] - scope.range[0]
        stepSize = distance / max
        
        return [scope.range[0] + id * stepSize, scope.range[0] + (id + 1) * stepSize]

      scope.setupCharts = ->
        scope.histogram =
          options:
            chart:
              type: 'historicalBarChart'
              x: (data) -> data.bucket[1]
              y: (data) -> data.y
              xAxis:
                axisLabel: 'Value'
                tickFormat: d3.format '.02f'
              yAxis:
                axisLabel: 'Count'
                tickFormat: d3.format '.02f'
              margin:
                top: 20
                right: 20
                bottom: 45
                left: 60
          data: [
            {
              # TODO replace this with real queries
              values: ({bucket: bucketFromId(idx, 10), y: Math.floor(Math.random() * 100)} for idx in [0...10])
              key: scope.feature.name
            }
          ]
        scope.marginalProbDistr =
          values: []
          key: 'Marginal probability distribution'
          area: true
          color: 'blue'
        scope.conditionalProbDistr =
          values: []
          key: 'Conditional probability distribution'
          area: true
          color: 'red'
        scope.probabilityDistributions =
          options:
            chart:
              type: 'lineChart'
              x: (data) -> data.x
              y: (data) -> data.y
              xAxis:
                axisLabel: 'Value'
                tickFormat: d3.format '.02f'
              yAxis:
                axisLabel: 'Probability density'
                tickFormat: d3.format '.02f'
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
        # TODO get this from an endpoint
        scope.histogram.data[0].values = ({bucket: bucketFromId(idx, 10), y: Math.floor(Math.random() * 100)} for idx in [0...10])
        return

      scope.showProbabilityDistributions = (slice) ->
        scope.selectedSlice = slice

        range = slice.range
        rangeLength = range[1] - range[0]

        generateChartDataFromValues = (y, idx, arr) ->
          x = range[0] + (idx / (arr.length - 1)) * rangeLength
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
