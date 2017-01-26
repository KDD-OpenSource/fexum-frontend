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
            ids = scope.features.map (f) -> f.id
            return session.retrieveSlicesForSubset ids
          .then (slices) ->
            sortByDeviation = (a, b) -> b.deviation - a.deviation
            slices.sort sortByDeviation
            slices.forEach (slice) ->
              # Create feature range dictionary for participating features
              slice.rangeDict = {}
              slice.features.forEach (participatingItem) ->
                slice.rangeDict[participatingItem.feature] = participatingItem.range
              # Define function to obtain the range for a given feature
              slice.getFeatureRange = (feature) ->
                return slice.rangeDict[feature.id]
            scope.slices = slices
          .fail console.error

        return
    }
]
