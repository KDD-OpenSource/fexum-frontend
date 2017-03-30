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
        onSliceClicked: '&sliceClick'
      link: (scope, element, attrs) ->

        formatter = d3.format '.5g'

        scope.getSliceFeatureRangeString = (slice, feature) ->
          featureRange = slice.getFeatureRange feature
          featureRange = featureRange.map formatter
          return featureRange.join ', '

        scopeUtils.waitForVariableSet scope, 'features'
          .then -> backendService.getExperiment()
          .then (experiment) ->
            ids = scope.features.map (f) -> f.id
            return experiment.retrieveSlicesForSubset ids
          .then (slices) ->
            sortByDeviation = (a, b) -> b.deviation - a.deviation
            slices.sort sortByDeviation
            slices.forEach (slice) ->
              # Create feature range dictionary for participating features
              slice.rangeDict = {}
              slice.features.forEach (participatingItem) ->
                if participatingItem.range?
                  slice.rangeDict[participatingItem.feature] = participatingItem.range
                else
                  slice.rangeDict[participatingItem.feature] = participatingItem.categories
              # Define function to obtain the range for a given feature
              slice.hasFeatureRange = (feature) ->
                return slice.rangeDict[feature.id]?
              slice.getFeatureRange = (feature) ->
                return slice.rangeDict[feature.id]
            scope.slices = slices
          .fail console.error

        return
    }
]
