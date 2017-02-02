app.directive 'featureMap', [
  '$timeout',
  'chartColors',
  'scopeUtils',
  '$q',
  '$interval',
  ($timeout, chartColors, scopeUtils, $q, $interval) ->
    return {
      restrict: 'E'
      scope:
        features: '='
        relevancies: '='
        redundancies: '='
        selectedFeatures: '='
        targetFeature: '='
        zoomApi: '='
      link: (scope, element, attrs) ->

        svg = angular.element(document.createElementNS('http://www.w3.org/2000/svg', 'svg'))
        element.append svg

        render = ->
          nodes = scope.nodes

          # remove nodes with undefined relevancy
          nodes = nodes.filter (node) ->
            feature = node.feature
            return scope.relevancies[feature.id]? or node.isTarget

          nodeCount = nodes.length

          # ensure that target feature is at the end of list and therefore drawn on top
          nodes.sort (a, b) -> a.isTarget - b.isTarget

          if not scope.zoomApi?
            # Enable feature map paning and zooming
            scope.zoomApi = svgPanZoom svg[0],
              fit: false
              controlIconsEnabled: false,
              onZoom: render,
              minZoom: 0.00001,
              zoomScaleSensitivity: 0.3

          renderLineLinks()

          getFeaturePosition = (node, idx) ->
            return [node.x, node.y]

          getFeatureTranslationString = (node, idx) ->
            [x, y] = getFeaturePosition node, idx

            #Change size according to zoom level
            zoom = scope.zoomApi.getZoom()
            transform = (Math.tanh(3 * zoom - 1) + 1) / 2 / zoom

            return "translate(#{x}, #{y}) scale(#{transform})"

          getFeatureLink = (node) ->
            encodedName = window.encodeURIComponent node.feature.name
            return "/feature/#{encodedName}"

          # Update feature map using d3
          d3nodes = d4.select svg[0]
                      .select 'g.svg-pan-zoom_viewport'
                      .selectAll 'g.feature'
                      .data nodes
          # Remove old elements
          d3nodes.exit().remove()
          # Create new elements
          newD3nodes = d3nodes.enter().append 'g'
                      .classed 'feature', true
          newD3Links = newD3nodes.append 'a'
          newD3Links.append 'ellipse'
                .attr 'rx', 80
                .attr 'ry', 40
          newD3Links.append 'text'
          # Update elements
          d3nodes.select 'a'
                .attr 'xlink:href', getFeatureLink
                .select 'text'
                .text (node) -> node.feature.name
          d3nodes.attr 'transform', getFeatureTranslationString
                .classed 'is-target', (node) -> node.isTarget
                .classed 'selected', (node) -> scope.selectedFeatures.includes node.feature
                .on 'mouseover', (node) -> node.hovered = true
                .on 'mouseout', (node) -> node.hovered = false

          scope.zoomApi.updateBBox()

          return

        renderLineLinks = ->
            if scope.links?
              filteredLinks = scope.links.filter (link) ->
                return (link.source.hovered or link.target.hovered) \
                  and (link.source.isTarget or link.target.isTarget)

              d3links = d4.select svg[0]
                          .select 'g.svg-pan-zoom_viewport'
                          .selectAll '.link'
                          .data filteredLinks
              d3links.exit().remove()

              g = d3links.enter().append 'g'
                    .classed 'link', true
              g.append 'line'
              g.append 'text'

              d3links.select 'line'
                .attr 'x1', (l) -> l.source.x
                .attr 'y1', (l) -> l.source.y
                .attr 'x2', (l) -> l.target.x
                .attr 'y2', (l) -> l.target.y

              d3links.select 'text'
                .attr 'x', (l) -> (l.target.x - l.source.x) / 2
                .attr 'y', (l) -> (l.target.y - l.source.y) / 2
                .text (l) -> d4.format('.3g') l.target.feature.relevancy

              d3links.each ->
                firstChild = @.parentNode.firstChild
                if firstChild?
                  @.parentNode.insertBefore @, firstChild

        createNodes = ->
          scope.nodes = scope.features.map (feature) ->
            node = {
              feature: feature
              isTarget: feature == scope.targetFeature
              id: feature.id
              x: 0
              y: 0
            }
            if node.isTarget
              node.fx = 0
              node.fy = 0
            return node

        setupSimulation = ->
          forceLinkDef = d4.forceLink []
            .id (d) -> d.id
            .distance (d) -> d.distance
            .strength (d) -> d.strength

          scope.simulation = d4.forceSimulation scope.nodes
            .alphaDecay 0.0001
            .velocityDecay 0.5
            .on 'tick', render
            .force 'link', forceLinkDef

          scope.simulationTimeout = $timeout scope.simulation.stop, attrs.simulationTimeout * 1000
          scope.simulationTimeout.then ->
            scope.simulationTimeout = $interval renderLineLinks, 30

        distanceFromCorrelation = (correlation, isRedundancy) ->
          minDistance = 500
          maxDistance = 10 * minDistance * (if isRedundancy then 2 else 1)
          difference = maxDistance - minDistance
          return maxDistance - (difference * Math.sqrt(Math.sqrt(correlation)))

        updateLinks = ->
          relevancyLinks = objectMap scope.relevancies, (featureId, relevancy) ->
            source: scope.targetFeature.id
            target: featureId
            distance: distanceFromCorrelation relevancy, false
            strength: 1
          redundancyLinks = objectMap scope.redundancies, (key, result) ->
            source: result.firstFeature
            target: result.secondFeature
            distance: distanceFromCorrelation result.redundancy, true
            strength: 0.005 * Math.sqrt result.weight
          scope.links = relevancyLinks.concat redundancyLinks
          scope.simulation
            .force 'link'
            .links scope.links


        initialize = (targetFeature) ->
          if scope.simulation?
            $timeout.cancel scope.simulationTimeout
            scope.simulation.stop()
          if targetFeature?
            createNodes()
            setupSimulation()
            render()
            updateLinks()

        areFeaturesSet = scopeUtils.waitForVariableSet scope, 'features'
        isTargetFeatureSet = scopeUtils.waitForVariableSet scope, 'targetFeature'
        $q.all [areFeaturesSet, isTargetFeatureSet]
          .then ->
            initialize scope.targetFeature

            # Rerender when variables change
            scope.$watch 'relevancies', updateLinks, true
            scope.$watch 'redundancies', updateLinks, true
            scope.$watch 'targetFeature', initialize
            scope.$watchCollection 'selectedFeatures', render
          .fail console.error

        return
    }
]
