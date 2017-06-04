app.directive 'searchBar', [
  'scopeUtils', '$location',
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
          else if searchedItem.isExcludeFilter
            scope.filterParams.excludeText = searchedItem.feature.name
          else
            $location.path "/feature/#{searchedItem.feature.name}"
            scope.mapApi.locateFeature searchedItem.feature
          scope.searchText = ''

        scope.getSearchItems = ->
          searchItems = []
          # Dummy feature so that filter always matches search item, even for "Filter by [text]"
          searchItems.push
            isTextFilter: true
            feature:
              name: scope.searchText
          searchItems.push
            isExcludeFilter: true
            feature:
              name: scope.searchText

          searchItems = searchItems.concat scope.filteredFeatures.map (feature) ->
            return {
              feature: feature
            }
          return searchItems

        scope.resetTextFilter = ->
          scope.filterParams.searchText = ''

        scope.resetExcludeFilter = ->
          scope.filterParams.excludeText = ''

        scope.chipsExpanded = false
        scope.maxChipsPreviewed = 2
        scope.toggleChips = ->
          scope.chipsExpanded = !scope.chipsExpanded
        scope.shouldDisplayChip = (item) ->
          index = scope.filterParams.blacklist.indexOf item
          return scope.chipsExpanded or index < scope.maxChipsPreviewed

    }
]
