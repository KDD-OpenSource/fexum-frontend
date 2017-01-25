app.directive 'timeSeriesPlot', [
  '$timeout',
  'chartTemplates',
  'chartColors',
  'scopeUtils',
  'backendService',
  ($timeout, chartTemplates, chartColors, scopeUtils, backendService) ->
    return {
      restrict: 'E'
      template: JST['assets/templates/timeSeriesPlot']
      scope:
        feature: '='
        highlightedRange: '='
      link: (scope, element, attrs) ->

        scope.setupCharts = ->
          scope.lineChart = angular.merge {}, chartTemplates.lineChart,
            options:
              chart:
                xAxis:
                  axisLabel: 'Time (seconds)'
                yAxis:
                  axisLabel: 'Value'
                dispatch:
                  renderEnd: ->
                    # somehow nvd3 only defines after the first rendering
                    if not scope.lineChartApi?
                      return

                    element = scope.lineChartApi.getElement()
                    svgElement = element[0]

                    chart = scope.lineChartApi.getScope().chart
                    if not chart?
                      return

                    highlightedRange = if scope.highlightedRange? \
                                        then [scope.highlightedRange] else []

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
                values: scope.feature.samples or []
                key: scope.feature.name
                color: chartColors.defaultColor
              }
            ]

        scope.$watch 'feature.samples', (newSamples) ->
          if newSamples? and scope.lineChart?
            scope.lineChart.data[0].values = newSamples

        scopeUtils.waitForVariableSet scope, 'feature.id'
          .then (featureId) ->
            return backendService.retrieveSamples featureId
          .then (samples) -> scope.feature.samples = samples
          .then scope.setupCharts
          .fail console.error

        return
    }
]
