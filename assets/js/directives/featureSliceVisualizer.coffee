app.directive 'featureSliceVisualizer', [
  '$timeout',
  '$q',
  'chartTemplates',
  'chartColors',
  'backendService',
  'scopeUtils',
  ($timeout, $q, chartTemplates, chartColors, backendService, scopeUtils) ->

    return {
      restrict: 'E'
      template: JST['assets/templates/featureSliceVisualizer']
      scope:
        ranges: '='
        selectedFeatures: '='
        targetFeature: '='
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
                  xAxis:
                    axisLabel: scope.xFeature.name
                  yAxis:
                    axisLabel: scope.yFeature.name
                  legend:
                    updateState: false
              data: []
          return

        retrieveSamples = (feature) ->
          if not feature.samples?
            return backendService.retrieveSamples feature.id
              .then (samples) -> feature.samples = samples
              .fail console.error
          else
            return $q.resolve feature.samples

        retrieveMarginalDistribution = ->
          return backendService.getSession()
            .then (session) -> session.getProbabilityDistribution []
            .then (distr) -> scope.targetFeature.marginalProbDistr = distr
            .fail console.error

        scopeUtils.waitForVariableSet scope, 'targetFeature'
          .then ->

            # Set defaults for xFeature and yFeature
            if scope.selectedFeatures.length >= 2
              scope.xFeature = scope.selectedFeatures[0]
              scope.yFeature = scope.selectedFeatures[1]
            
            promises = scope.selectedFeatures.map retrieveSamples
            promises.push retrieveSamples scope.targetFeature
            promises.push retrieveMarginalDistribution()
            $q.all promises
              .then -> scope.setupCharts()
              .then -> scope.updateCharts()
              .then -> scope.initialized = true
              .fail console.error
          .fail console.error

        getTargetClasses = ->
          return scope.targetFeature.marginalProbDistr.map (distrBucket) ->
            return distrBucket.value

        createSamples = (xFeature, yFeature, filterFeatures, targetClass) ->
          sampleCount = scope.targetFeature.samples.length

          filteredIndices = [0...sampleCount].filter (index) ->
            if scope.targetFeature.samples[index].y != targetClass
              return false
            for filterFeature in filterFeatures
              sampleValue = filterFeature.samples[index].y
              range = scope.ranges[filterFeature.id]
              if sampleValue > range[1] or sampleValue < range[0]
                return false
            return true

          return filteredIndices.map (index) ->
            return {
              x: xFeature.samples[index].y
              y: yFeature.samples[index].y
            }
          
        createSamplesForState = (targetClass) ->
          filterFeatures = scope.selectedFeatures
          return createSamples scope.xFeature, scope.yFeature, filterFeatures, targetClass

        updateChartCounter = 0
        scope.updateCharts = ->
          if not scope.ranges?
            return

          rangesQuery = objectMap scope.ranges, (featureId, range) ->
            return {
              feature: featureId
              from_value: range[0]
              to_value: range[1]
            }

          updateChartCounter += 1
          currentRun = updateChartCounter
          updateConditionalProbDistrChart = ->
            backendService.getSession()
              .then (session) ->
                return session.getProbabilityDistribution rangesQuery
              .then (conditionalProbDistr) ->
                # Only update if there was no update to the charts since last time
                if currentRun == updateChartCounter
                  scope.conditionalProbDistr.values = conditionalProbDistr
              .fail console.error
          if scope.promiseCDP?
            $timeout.cancel scope.promiseCDP
          scope.promiseCDP = $timeout updateConditionalProbDistrChart, 50

          if scope.selectedFeatures.length >= 2
            scope.scatterChart.options.chart.xAxis.axisLabel = scope.xFeature.name
            scope.scatterChart.options.chart.yAxis.axisLabel = scope.yFeature.name
            scope.scatterChart.data.length = 0
            getTargetClasses().forEach (targetClass) ->
              scope.scatterChart.data.push
                key: targetClass
                values: createSamplesForState targetClass

        updateChartsIfInitialized = ->
          if scope.initialized
            scope.updateCharts()

        scope.$watch 'ranges', updateChartsIfInitialized, true

        scope.updateYFeature = (newFeature) ->
          scope.yFeature = newFeature
          scope.updateCharts()

        scope.updateXFeature = (newFeature) ->
          scope.xFeature = newFeature
          scope.updateCharts()

        return
    }
]
