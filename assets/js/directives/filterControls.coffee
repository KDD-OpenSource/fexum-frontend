app.directive 'filterControls', [
  'scopeUtils', '$timeout',
  (scopeUtils, $timeout) ->
    return {
      template: JST['assets/templates/filterControls']
      scope: false
      link: (scope, element, attrs) ->
        scope.filterControls =
          onExpand: ->
            # Bugfix for rzslider, where initial values were not drawn
            $timeout (->
              scope.$broadcast 'rzSliderForceRender'
            ), 500
          refilter: ->
            if scope.features?
              filtered = scope.features.filter (feature) ->
                  (feature.name.search scope.filterControls.textFilter.searchText) != -1 or
                  feature == scope.targetFeature
              console.log scope.filterControls.bestLimit
              if scope.filterControls.bestLimit?
                filtered = filtered.sort (a, b) -> b.relevancy - a.relevancy
                filtered = filtered.slice(0, scope.filterControls.bestLimit)
                console.log filtered
              if scope.targetFeature not in filtered
                filtered.push scope.targetFeature
              scope.filteredFeatures = filtered
          textFilter:
            searchTextChange: (text) ->
              scope.filterControls.refilter()
            onFeatureSelected: (item) ->
              scope.filterControls.searchText = item.name
              scope.filterControls.refilter()
          tagFilter:
            onFeatureSelected: (item) ->
              # TODO
              scope.filterControls.refilter()
            exclusions: []

        scopeUtils.waitForVariableSet scope, 'features'
          .then (features) ->
            scope.filterControls.slider =
                    options:
                      floor: 1
                      ceil: features.length
                      step: 1
            scope.filterControls.bestLimit = features.length

        scope.$watch 'filterControls.bestLimit', ->
          scope.filterControls.refilter()

        return
    }
]