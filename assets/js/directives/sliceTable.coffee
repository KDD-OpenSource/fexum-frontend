app.directive 'sliceTable', [
  'scopeUtils',
  'backendService',
  '$q',
  (scopeUtils, backendService, $q) ->
    return {
      restrict: 'E'
      template: JST['assets/templates/sliceTable']
      scope:
        features: '='
      link: (scope, element, attrs) ->

        scopeUtils.waitForVariableSet scope, 'features'
          .then -> backendService.getSession()
          .then (session) ->
            slices = scope.features.map (feature) ->
              return session.retrieveSlices feature.id
            return $q.all slices
          .then (slices) ->
            mergedSlices = []
            return mergedSlices.concat slices
          .then (slices) ->
            scope.slices = slices
          .fail console.error

        return
    }
]
