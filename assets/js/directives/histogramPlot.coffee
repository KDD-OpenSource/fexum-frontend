app.directive 'histogramPlot', [
  '$timeout',
  'chartTemplates',
  'chartColors',
  'scopeUtils',
  'backendService',
  '$q',
  ($timeout, chartTemplates, chartColors, scopeUtils, backendService, $q) ->
    return {
      restrict: 'E'
      template: JST['assets/templates/histogramPlot']
      scope:
        feature: '='
      link: (scope, element, attrs) ->

        scope.setupCharts = ->
          scope.histogram = angular.merge {}, chartTemplates.historicalBarChart,
            options:
              chart:
                xAxis:
                  axisLabel: scope.feature.name
                dispatch:
                  renderEnd: ->
                    element = scope.histogramApi.getElement()
                    svg = d3.select element[0]

                    slicesContained = (d) ->
                      return scope.feature.slices.filter (slice) ->
                        return slice.range[0] < d.range[1] and
                                slice.range[1] > d.range[0]

                    buckets = scope.histogram.data[0].values
                    bucketSignificances = buckets.map (bucket) ->
                      slices = slicesContained bucket
                      if slices.length == 0
                        return null
                      # TODO reintroduce significances or rename to deviations
                      sliceSignificances = slices.map (slice) -> slice.deviation
                      return sliceSignificances.mean()

                    filteredSignificances = bucketSignificances.filter (b) -> b?
                    minSignificance = Math.min.apply null, filteredSignificances
                    maxSignificance = Math.max.apply null, filteredSignificances

                    svg.selectAll 'rect.nv-bar'
                      .classed 'significant', (d) ->
                        return slicesContained(d).length > 0
                      .attr 'significance', (d, i) ->
                        significance = bucketSignificances[i]
                        if not significance?
                          return 0
                        significanceValueRange = maxSignificance - minSignificance
                        if significanceValueRange != 0
                          scaledSignificance = (significance - minSignificance) \
                                                / significanceValueRange
                        else
                          scaledSignificance = 1

                        significanceLevel = Math.ceil(scaledSignificance * 10) * 10
                        return significanceLevel
            data: [
              {
                values: scope.feature.buckets
                key: scope.feature.name
                color: chartColors.defaultColor
              }
            ]

        scope.$watch 'feature.buckets', (newBuckets) ->
          if newBuckets? and scope.histogram?
            scope.histogram.data[0].values = newBuckets

        featureAvailable = scopeUtils.waitForVariableSet scope, 'feature.id'
        bucketsAvailable = featureAvailable
          .then (featureId) ->
            return backendService.retrieveHistogramBuckets featureId
          .then (buckets) -> scope.feature.buckets = buckets
          .fail console.error
        slicesAvailable = featureAvailable
          .then (featuredId) ->
            return backendService.getExperiment()
          .then (experiment) -> experiment.retrieveSlices scope.feature.id
          .then (slices) -> scope.feature.slices = slices
          .fail console.error
        $q.all [bucketsAvailable, slicesAvailable]
          .then scope.setupCharts

        return
    }
]
