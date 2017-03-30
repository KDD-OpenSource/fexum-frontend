app.directive 'densityPlot', [
  '$timeout',
  'chartTemplates',
  'chartColors',
  'scopeUtils',
  'backendService',
  '$q',
  ($timeout, chartTemplates, chartColors, scopeUtils, backendService, $q) ->
    return {
      restrict: 'E'
      template: JST['assets/templates/densityPlot']
      scope:
        feature: '='
        targetFeature: '='
      link: (scope, element, attrs) ->

        getDataForClass = (targetClass, density) ->
          stepSize = (scope.feature.max - scope.feature.min) / density.length
          return {
            values: density.map (val, idx) ->
              return {
                x: scope.feature.min + idx * stepSize
                y: val
              }
            key: targetClass
          }

        updateCharts = (densities) ->
          scope.densityChart = angular.merge {}, chartTemplates.lineChart,
            options:
              chart:
                isArea: true
                xAxis:
                  axisLabel: "Value of #{scope.feature.name}"
                yAxis:
                  axisLabel: 'Density'
            data: (getDataForClass d.target_class, d.density_values for d in densities)

        scope.$watchGroup ['feature', 'targetFeature'], (newValues, oldValues) ->
          [feature, targetFeature] = newValues
          if feature? and feature.id? and targetFeature? and targetFeature.id?
            backendService.retrieveDensity feature.id, targetFeature.id
              .then updateCharts
              .fail console.error

        return
    }
]
