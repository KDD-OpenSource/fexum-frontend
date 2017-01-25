app.directive 'featureMap', ['$timeout', 'chartColors', ($timeout, chartColors) ->
  return {
    restrict: 'E'
    scope:
      features: '='
      selectedFeatures: '='
      targetFeature: '='
      zoomApi: '='
    link: (scope, element, attrs) ->
      maxDistance = attrs.maxDistance
      offset = attrs.offset

      svg = angular.element(document.createElementNS('http://www.w3.org/2000/svg', 'svg'))
      element.append svg

      render = ->
        # render nothing if no target is set or feature are not loaded
        if not scope.targetFeature? or not scope.features
          return

        features = scope.features

        # remove features with undefined relevancy
        features = features.filter (feature) ->
          return feature.relevancy? or feature == scope.targetFeature

        featureCount = features.length
        targetFeatureIndex = features.indexOf scope.targetFeature

        # swap target feature to be the last feature to draw it above all other elements
        if targetFeatureIndex < features.length - 1
          features[targetFeatureIndex] = features[features.length - 1]
          features[features.length - 1] = scope.targetFeature
          targetFeatureIndex = features.length - 1

        if not scope.zoomApi?
          # Enable feature map paning and zooming
          scope.zoomApi = svgPanZoom svg[0],
            fit: false
            controlIconsEnabled: false,
            onZoom: render,
            minZoom: 0.00001,
            zoomScaleSensitivity: 0.3

        # evenly arrange the features around the target feature
        getFeaturePosition = (feature, idx) ->
          isTarget = feature == scope.targetFeature
          if isTarget
            return [0, 0]
          radius = (1 - feature.relevancy) * maxDistance + offset
          # index is 1 too big if this item is behind the target in the list
          if idx > targetFeatureIndex
            idx -= 1
          # calculate angle
          angle = (2 * Math.PI / (featureCount - 1)) * idx
          # convert polar coordinates to cartesian coordinates
          x = radius * Math.cos angle
          y = radius * Math.sin angle
          return [x, y]

        getFeatureTranslationString = (feature, idx) ->
          [x, y] = getFeaturePosition feature, idx

          #Change size according to zoom level
          zoom = scope.zoomApi.getZoom()
          transform = (Math.tanh(3 * zoom - 1) + 1) / 2 / zoom

          return "translate(#{x}, #{y}) scale(#{transform})"

        getFeatureLink = (feature) ->
          encodedName = window.encodeURIComponent feature.name
          if feature == scope.targetFeature
            return '#'
          return '/selections'

        getClickAction = (feature) ->
          if feature == scope.targetFeature
            return
          scope.$apply ->
            index = scope.selectedFeatures.indexOf feature
            if index >= 0
              scope.selectedFeatures.splice index, 1
            else
              scope.selectedFeatures.push feature

        # Update feature map using d3
        nodes = d3.select svg[0]
                    .select 'g.svg-pan-zoom_viewport'
                    .selectAll 'g.feature'
                    .data features
        # Remove old elements
        nodes.exit().remove()
        # Create new elements
        newNodes = nodes.enter().append 'g'
                    .classed 'feature', true
        newLinks = newNodes.append 'a'
        newLinks.append 'ellipse'
              .attr 'rx', 80
              .attr 'ry', 40
        newLinks.append 'text'
        # Update elements
        nodes.select 'a'
              .attr 'xlink:href', getFeatureLink
              .on 'click', getClickAction
              .select 'text'
              .text (feature) -> feature.name
        nodes.attr 'transform', getFeatureTranslationString
              .classed 'is-target', (feature) -> feature == scope.targetFeature
              .classed 'selected', (feature) -> scope.selectedFeatures.includes feature

        scope.zoomApi.updateBBox()

        return

      # Initial d3 rendering
      render()

      # Rerender when variables change
      scope.$watch 'features', render, true
      scope.$watch 'targetFeature', render
      scope.$watchCollection 'selectedFeatures', render
      return
  }
]
