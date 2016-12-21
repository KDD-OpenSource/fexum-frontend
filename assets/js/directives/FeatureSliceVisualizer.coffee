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
              yAxis:
                axisLabel: 'Count'
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

        return

      # charts should be set up when layouting is done
      # sadly there is no event available for that
      $timeout scope.setupCharts, 200
      scope.$watch 'range', scope.setupCharts

      scope.showProbabilityDistribution = (slice) ->
        console.log 'Show prob distr for', slice
        return
      return
  }
]
