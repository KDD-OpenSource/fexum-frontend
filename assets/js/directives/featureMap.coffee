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
        mapApi: '='
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
              controlIconsEnabled: false
              onZoom: ->
                render()
              minZoom: 0.00001
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
                .attr 'rx', 5
                .attr 'ry', 5
          newD3Links.append 'text'
          # Update elements
          d3nodes = newD3nodes.merge d3nodes
          d3nodes.select 'a'
                .attr 'xlink:href', getFeatureLink
                .select 'text'
                .text (node) -> node.feature.name
                .attr 'y', -8
          d3nodes.attr 'transform', getFeatureTranslationString
                .classed 'is-target', (node) -> node.isTarget
                .classed 'selected', (node) -> scope.selectedFeatures.includes node.feature
                .on 'mouseover', (node) ->
                  node.hovered = true
                  renderLineLinks()
                .on 'mouseout', (node) ->
                  node.hovered = false
                  renderLineLinks()

          scope.zoomApi.updateBBox()

          return

        renderLineLinks = ->
          if not scope.links?
            return

          filteredLinks = scope.links.filter (link) ->
            return (link.source.hovered or link.target.hovered) \
              and (link.source.isTarget or link.target.isTarget) \
              and link.relevancy?

          d3links = d4.select svg[0]
                      .select 'g.svg-pan-zoom_viewport'
                      .selectAll 'g.link'
                      .data filteredLinks

          # Remove
          d3links.exit().remove()

          # Enter
          newD3Links = d3links.enter()
              .append 'g'
              .classed 'link', true
          newD3Links.append 'line'
          newD3Links.append 'text'

          # Update
          d3links = d3links.merge newD3Links
          d3links.select 'line'
            .attr 'x1', (l) -> l.source.x
            .attr 'y1', (l) -> l.source.y
            .attr 'x2', (l) -> l.target.x
            .attr 'y2', (l) -> l.target.y

          d3links.select 'text'
            .attr 'x', (l) -> (l.target.x - l.source.x) / 2
            .attr 'y', (l) -> (l.target.y - l.source.y) / 2
            .text (l) -> d4.format('.3g') l.relevancy

          # Move links to back
          d3links.each ->
            firstChild = @parentNode.firstChild
            if firstChild?
              @parentNode.insertBefore @, firstChild

        updateNodes = ->

          # Keeps old node positions so that transition looks smooth
          oldNodeMap = {}
          if scope.nodes?
            for node in scope.nodes
              oldNodeMap[node.id] = node

          scope.nodes = scope.features.map (feature) ->
            node = {
              feature: feature
              isTarget: feature == scope.targetFeature
              id: feature.id
              x: 0
              y: 0
            }
            if feature.id of oldNodeMap
              oldNode = oldNodeMap[feature.id]
              node.x = oldNode.x
              node.y = oldNode.y
            if node.isTarget
              node.fx = 0
              node.fy = 0
            return node

        stopSimulation = ->
          if scope.simulation?
            $timeout.cancel scope.simulationTimeout
            scope.simulation.stop()

        setupSimulationTimeout = ->
          # Only setup once
          if scope.simulationTimeout?
            $timeout.cancel scope.simulationTimeout

          scope.simulationTimeout = $timeout scope.simulation.stop, attrs.simulationTimeout * 1000
          scope.simulationTimeout
            .then ->
              scope.simulationTimeout = null
            .fail (error) ->
              scope.simulationTimeout = null
              if error != 'canceled'
                console.error error

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

          setupSimulationTimeout()

        distanceFromCorrelation = (correlation, isRedundancy) ->
          base = 10
          maxDistance = 5000 * (if isRedundancy then 2 else 1)
          # Goal: Distance converges to 0 for strong correlations +
          # uncorrelated features have specific maximum distance
          return Math.pow(base, -Math.sqrt(correlation)) * maxDistance

        updateLinks = ->
          featureIds = scope.features.map (f) -> f.id
          relevancyLinks = objectMap scope.relevancies, (featureId, relevancy) ->
            if featureId in featureIds
              console.assert relevancy?
              return {
                source: scope.targetFeature.id
                target: featureId
                distance: distanceFromCorrelation relevancy, false
                relevancy: relevancy
                strength: 1
              }
            return null
          , true
          redundancyLinks = objectMap scope.redundancies, (key, result) ->
            if result.firstFeature in featureIds and result.secondFeature in featureIds
              # Because relevancy has priority over redundancy:
              weightComparedToRelevancy = 0.0003
              return {
                source: result.firstFeature
                target: result.secondFeature
                distance: distanceFromCorrelation result.redundancy, true
                strength: weightComparedToRelevancy * Math.sqrt result.weight
              }
            return null
          , true
          scope.links = relevancyLinks.concat redundancyLinks
          # Update simulation
          scope.simulation
            .force 'link'
            .links scope.links

          scope.simulation.restart()
          setupSimulationTimeout()

        initialize = ->
          stopSimulation()
          if scope.targetFeature?
            updateNodes()
            setupSimulation()
            render()
            updateLinks()

        scope.mapApi =
          zoomIn: ->
            scope.zoomApi.zoomIn()
          zoomOut: ->
            scope.zoomApi.zoomOut()
          locateFeature: (feature) ->
            node = scope.nodes.find (f) -> f.id == feature.id
            sizes = scope.zoomApi.getSizes()
            zoom = sizes.realZoom
            position =
              x: sizes.width / 2 - node.x * zoom
              y: sizes.height / 2 - node.y * zoom
            scope.zoomApi.pan position
            scope.zoomApi.zoom 0.5

        areFeaturesSet = scopeUtils.waitForVariableSet scope, 'features'
        isTargetFeatureSet = scopeUtils.waitForVariableSet scope, 'targetFeature'
        $q.all [areFeaturesSet, isTargetFeatureSet]
          .then ->
            initialize scope.targetFeature

            # Rerender when variables change
            scope.$watch 'relevancies', updateLinks, true
            scope.$watch 'redundancies', updateLinks, true
            scope.$watch 'targetFeature', initialize
            scope.$watchCollection 'features', initialize
            scope.$watchCollection 'selectedFeatures', render
          .fail console.error

        return
    }
]
