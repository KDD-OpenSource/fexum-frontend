app.directive 'filterControls', [
  'scopeUtils',
  (scopeUtils) ->
    return {
      template: JST['assets/templates/filterControls']
      scope: false
      link: (scope, element, attrs) ->

        scope.filterControls =
          refilter: ->
            if scope.features?
              filtered = scope.features.filter (feature) ->
                  (feature.name.search scope.filterControls.textFilter.searchText) != -1 or
                  feature == scope.targetFeature
              if scope.filterControls.bestLimit?
                filtered.sort (a, b) -> b.relevancy - a.relevancy
                filtered = filtered.slice(0, scope.filterControls.bestLimit)
              scope.filteredFeatures = filtered
          textFilter:
            searchTextChange: (text) ->
              scope.filterControls.refilter()
            onFeatureSelected: (item) ->
              console.log 'test'
              scope.filterControls.searchText = item.name
              scope.filterControls.refilter()

        scope.$watch 'filterControls.bestLimit', ->
          scope.filterControls.refilter()

        return
    }
]