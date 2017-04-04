app.directive 'filterControls', [
  'scopeUtils', '$timeout', '$mdExpansionPanel',
  (scopeUtils, $timeout, $mdExpansionPanel) ->
    return {
      template: JST['assets/templates/filterControls']
      scope: false
      link: (scope, element, attrs) ->

        scope.filterControls =
          expandable: false
          onExpand: ->
            $mdExpansionPanel().waitFor 'filterPanel'
              .then (panel) ->
                scope.filterControls.expandable = true
                panel.expand()
                # Bugfix for rzslider, where initial values were not drawn
                $timeout (->
                  scope.$broadcast 'rzSliderForceRender'
                ), 500
          onCollapse: ->
            $mdExpansionPanel().waitFor 'filterPanel'
              .then (panel) ->
                panel.collapse()
                scope.filterControls.expandable = false
          refilter: ->
            if scope.features?
              # Simple text filter
              filtered = scope.features.filter (feature) ->
                  (feature.name.search scope.filterControls.textFilter.searchText) != -1 or
                  feature == scope.targetFeature

              # k-best filter
              if scope.filterControls.bestLimit?
                filtered = filtered.sort (a, b) -> b.relevancy - a.relevancy
                filtered = filtered.slice(0, scope.filterControls.bestLimit)

              # Blacklist filter
              console.log scope.filterControls.blacklist
              if scope.filterControls.blacklist?
                filtered = filtered.filter (feature) ->
                  feature not in scope.filterControls.blacklist

              # Target needs to be in there at all times for relevancy links
              if scope.targetFeature not in filtered
                filtered.push scope.targetFeature

              scope.filteredFeatures = filtered
          textFilter:
            searchTextChange: (text) ->
              scope.filterControls.refilter()
          tagFilter: null
          blacklist: []

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
        scope.$watchCollection 'filterControls.blacklist', ->
          scope.filterControls.refilter()

        return
    }
]