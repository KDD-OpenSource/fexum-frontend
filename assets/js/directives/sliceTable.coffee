app.directive 'sliceTable', [
  'scopeUtils',
  'backendService',
  'defaultNumFormatter',
  (scopeUtils, backendService, defaultNumFormatter) ->
    return {
      restrict: 'E'
      template: JST['assets/templates/sliceTable']
      scope:
        features: '='
        onSliceClicked: '&sliceClick'
      link: (scope, element, attrs) ->

        scope.getSliceFeatureRangeString = (slice, feature) ->
          featureRange = slice.getFeatureRange feature
          unless feature.is_categorical
            featureRange = featureRange.map defaultNumFormatter
          return featureRange.join ', '

        updateTable = ->
          backendService.getExperiment()
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

        scope.$on 'ws/calculation', (event, payload) ->
          status = payload.data.status
          type = payload.data.type
          if status == 'done' and type == 'fixed_feature_set_hics'
            # TODO only update if it was for this subset
            updateTable()

        scopeUtils.waitForVariableSet scope, 'features'
          .then updateTable

        return
    }
]
