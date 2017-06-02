app.directive 'slideFilter', [
  'scopeUtils',
  (scopeUtils) ->
    return {
      template: JST['assets/templates/slideFilter']
      restrict: 'E'
      scope:
        filterParams: '='
        features: '='
      link: (scope, element, attrs) ->

        scopeUtils.waitForVariableSet scope, 'features'
          .then ->
            scope.slider =
              options:
                floor: 1
                ceil: scope.features.length
                step: 1
            # Only set bestLimit if it wasn't set by the experiment
            unless scope.filterParams.bestLimit?
              scope.filterParams.bestLimit = scope.features.length

            scope.$watch 'features', ->
              sliderAtMax = scope.slider.options.ceil == scope.filterParams.bestLimit
              scope.slider.options.ceil = scope.features.length
              scope.filterParams.bestLimit =
                Math.min scope.filterParams.bestLimit, scope.features.length
              if sliderAtMax
                scope.filterParams.bestLimit = scope.features.length

    }
]
