app.directive 'featureSliceVisualizer', [
  '$q',
  'chartTemplates',
  'chartColors',
  'backendService',
  'scopeUtils',
  ($q, chartTemplates, chartColors, backendService, scopeUtils) ->

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
            values: scope.targetFeature.marginalDistribution
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
                stacked: false
                showControls: false
                legend:
                  rightAlign: false
                  maxKeyLength: 1000
            data: [marginalProbDistr, conditionalProbDistr]

          # Store distribution in scope to update later
          scope.conditionalProbDistr = conditionalProbDistr

          scope.scatterChart = angular.merge {}, chartTemplates.scatterChart,
            options:
              chart:
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
          else
            return $q.resolve feature.samples

        scopeUtils.waitForVariableSet scope, 'targetFeature'
          .then ->
            promises = scope.selectedFeatures.map retrieveSamples
            promises.push retrieveSamples scope.targetFeature
            promises.push backendService.getSession()
              # Retrieve marginal probability distribution for target
              .then (session) -> session.getProbabilityDistribution []
              .then (distr) -> scope.targetFeature.marginalProbDistr = distr
            $q.all promises
              .then -> scope.setupCharts
              .then -> scope.updateCharts
              .then -> scope.initialized = true
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
          displayedFeatures = new Set [scope.xFeature, scope.yFeature]
          filterFeatures = scope.selectedFeatures.filter (x) -> not displayedFeatures.has x
          return createSamples scope.xFeature, scope.yFeature, filterFeatures, targetClass

        scope.updateCharts = ->
          if not scope.ranges?
            return

          rangesQuery = scope.ranges.map (featureId, range) ->
            return {
              feature: featureId
              from_value: range[0]
              to_value: range[1]
            }

          session = backendService.getSession()
          session
            .then (session) ->
              return session.getProbabilityDistribution rangesQuery
            .then (conditionalProbDistr) ->
              scope.conditionalProbDistr.values = conditionalProbDistr
            .fail console.error

          scope.scatterChart.data.clear()
          getTargetClasses().forEach (targetClass) ->
            scope.scatterChart.data.push
              key: targetClass
              values: createSamplesForState targetClass

        scope.$watch 'ranges', ->
          if scope.initialized
            scope.updateCharts()

        return
    }
]
