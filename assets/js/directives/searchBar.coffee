app.directive 'searchBar', [
  'scopeUtils', '$location'
  (scopeUtils, $location) ->
    return {
      template: JST['assets/templates/searchBar']
      restrict: 'E'
      scope:
        filterParams: '='
        filteredFeatures: '='
        mapApi: '='
      link: (scope, element, attrs) ->

        scope.onFeatureSearched = (searchedItem) ->
          if not searchedItem?
            return
          if searchedItem.isTextFilter
            scope.filterParams.searchText = searchedItem.feature.name
          else
            $location.path "/feature/#{searchedItem.feature.name}"
            scope.mapApi.locateFeature searchedItem.feature
          scope.searchText = ''

        scope.getSearchItems = ->
          searchItems = []
          # Dummy feature so that filtering works as intended
          searchItems.push
            isTextFilter: true
            feature:
              name: scope.searchText

          searchItems = searchItems.concat scope.filteredFeatures.map (feature) ->
            return {
              feature: feature
              isTextFilter: false
            }
          return searchItems

        scope.resetTextFilter = ->
          scope.filterParams.searchText = ''

    }
]