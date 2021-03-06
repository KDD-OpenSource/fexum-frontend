app.directive 'featureSliceVisualizer', [
  '$timeout',
  '$q',
  'chartTemplates',
  'chartColors',
  'backendService',
  'scopeUtils',
  '$analytics',
  ($timeout, $q, chartTemplates, chartColors, backendService, scopeUtils, $analytics) ->

    return {
      restrict: 'E'
      template: JST['assets/templates/featureSliceVisualizer']
      scope:
        ranges: '='
        selectedFeatures: '='
        targetFeature: '='
        scatterPlotSampleCount: '='
      link: (scope, element, attrs) ->

        scope.setupCharts = ->
          marginalProbDistr =
            values: scope.targetFeature.marginalProbDistr
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
                x: (data) -> data.value
                y: (data) -> data.probability
                xAxis:
                  axisLabel: scope.targetFeature.name
                yAxis:
                  axisLabel: 'Probability density'
                  tickFormat: d3.format '.0%'
                forceY: [0, 1]
                stacked: false
                showControls: false
                legend:
                  rightAlign: false
                  maxKeyLength: 1000
            data: [marginalProbDistr, conditionalProbDistr]

          scope.conditionalProbDistr = scope.probabilityDistributions.data[1]

          if scope.selectedFeatures.length >= 2
            scope.scatterChart = angular.merge {}, chartTemplates.scatterChart,
              options:
                chart:
                  height: 200 # TODO make this work in css
                  interactiveUpdateDelay: 0
                  duration: 0
                  xAxis:
                    axisLabel: scope.xFeature.name
                  yAxis:
                    axisLabel: scope.yFeature.name
                  legend:
                    updateState: false
              data: []
          return

        retrieveMarginalDistribution = ->
          if scope.targetFeature.marginalProbDistr
            return $q.resolve scope.targetFeature.marginalProbDistr
          return backendService.getExperiment()
            .then (experiment) -> experiment.getProbabilityDistribution []
            .then (response) ->
              scope.targetFeature.marginalProbDistr = response.distribution
            .fail console.error

        scopeUtils.waitForVariableSet scope, 'targetFeature'
          .then ->
            # Set defaults for xFeature and yFeature
            if scope.selectedFeatures.length >= 2
              scope.xFeature = scope.selectedFeatures[0]
              scope.yFeature = scope.selectedFeatures[1]
            
            retrieveMarginalDistribution()
              # TODO remove timeout, it waits until layouting is done
              .then -> $timeout null, 1500
              .then -> scope.setupCharts()
              .then -> scope.updateCharts()
              .then -> scope.initialized = true
              .fail console.error
          .fail console.error

        getTargetClasses = ->
          return scope.targetFeature.marginalProbDistr.map (distrBucket) ->
            return distrBucket.value

        createSamples = (samples, xFeature, yFeature, targetClass) ->
          sampleCount = samples[scope.targetFeature.id].length

          filteredIndices = [0...sampleCount].filter (index) ->
            if samples[scope.targetFeature.id][index] != targetClass
              return false
            return true

          return filteredIndices.map (index) ->
            return {
              x: samples[xFeature.id][index]
              y: samples[yFeature.id][index]
            }
          
        filterSamplesByClass = (samples, targetClass) ->
          return createSamples samples, scope.xFeature, scope.yFeature, targetClass

        updateChartCounter = 0
        scope.updateCharts = ->
          if not scope.ranges?
            return

          rangesQuery = objectMap scope.ranges, (featureId, range) ->
            feature = (f for f in scope.selectedFeatures when f.id == featureId)[0]
            if feature.is_categorical
              # categories where checkbox is true
              categories = (parseFloat(k) for own k, v of range when v)
              return {
                feature: featureId
                categories: categories
              }
            else
              return {
                feature: featureId
                range: {
                  from_value: range[0]
                  to_value: range[1]
                }
              }

          updateChartCounter += 1
          currentRun = updateChartCounter

          updateConditionalProbDistrChart = ->
            backendService.getExperiment()
              .then (experiment) ->
                sampleCount = scope.scatterPlotSampleCount
                return experiment.getProbabilityDistribution rangesQuery, sampleCount
              .then (response) ->
                {distribution, samples} = response

                # Only update if there was no update to the charts since last time
                if currentRun < updateChartCounter
                  return
                
                scope.conditionalProbDistr.values = distribution

                if scope.selectedFeatures.length >= 2
                  scope.scatterChart.data.length = 0
                  getTargetClasses().forEach (targetClass, i) ->
                    scope.scatterChart.data.push
                      key: targetClass
                      values: filterSamplesByClass samples, targetClass
                      color: chartColors.targetClassColors[i]

              .fail console.error

          # Prevent flooding server with requests
          if scope.promiseCDP?
            $timeout.cancel scope.promiseCDP
          scope.promiseCDP = $timeout updateConditionalProbDistrChart, 50

          if scope.selectedFeatures.length >= 2
            scatterChart = scope.scatterChart.options.chart
            scatterChart.xAxis.axisLabel = scope.xFeature.name
            scatterChart.yAxis.axisLabel = scope.yFeature.name
            scatterChart.forceY = [scope.yFeature.min, scope.yFeature.max]
            scatterChart.forceX = [scope.xFeature.min, scope.xFeature.max]

        updateChartsIfInitialized = ->
          if scope.initialized
            scope.updateCharts()

        scope.$watch 'ranges', updateChartsIfInitialized, true

        scope.updateYFeature = (newFeature) ->
          scope.yFeature = newFeature
          scope.updateCharts()

          backendService.getExperiment().then (experiment) ->
            $analytics.eventTrack 'scatterAxisChanged', {
              category: "d#{experiment.datasetId}t#{scope.targetFeature.id}" +
                        "f#{scope.selectedFeatures.map((f) -> f.id).join '|'}"
              label: 'x=' + scope.xFeature.id + '|y=' + newFeature.id
            }

        scope.updateXFeature = (newFeature) ->
          scope.xFeature = newFeature
          scope.updateCharts()

          backendService.getExperiment().then (experiment) ->
            $analytics.eventTrack 'scatterAxisChanged', {
              category: "d#{experiment.datasetId}t#{scope.targetFeature.id}" +
                        "f#{scope.selectedFeatures.map((f) -> f.id).join '|'}"
              label: 'x=' + newFeature.id + '|y=' + scope.yFeature.id
            }

        return
    }
]
