app.directive 'featureMap', ['$timeout', ($timeout) ->
  return {
    restrict: 'E'
    scope:
      features: '='
      targetFeature: '='
      zoomApi: '='
    link: (scope, element, attrs) ->
      svg = angular.element(document.createElementNS('http://www.w3.org/2000/svg', 'svg'))
      element.append svg

      render = ->
        # render nothing if no target is set or feature are not loaded
        features = if scope.targetFeature and scope.features then scope.features else []

        # remove features with undefined relevancy
        features = features.filter (feature) ->
          return feature.relevancy? or feature == scope.targetFeature

        featureCount = features.length
        targetFeatureIndex = features.indexOf scope.targetFeature

        MAX_DISTANCE = 500
        OFFSET = 100

        # evenly arrange the features around the target feature
        getFeaturePosition = (feature, idx) ->
          isTarget = feature == scope.targetFeature
          if isTarget
            return [0, 0]
          radius = (1 - feature.relevancy) * MAX_DISTANCE + OFFSET
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
          return "translate(#{x}, #{y})"

        getFeatureLink = (feature) ->
          encodedName = window.encodeURIComponent feature.name
          return "/feature/#{encodedName}"

        # Update feature map using d3
        nodes = d3.select svg[0]
                    .selectAll 'g.feature'
                    .data features
        # Create new elements
        newNodes = nodes.enter().append 'g'
                    .classed 'feature', true
        newLinks = newNodes.append 'a'
        newLinks.append 'ellipse'
        newLinks.append 'text'
        # Update elements
        nodes.selectAll('text').data(features).text (feature) -> feature.name
        nodes.selectAll('a').data(features).attr 'xlink:href', getFeatureLink
        nodes.attr 'transform', getFeatureTranslationString
              .classed 'is-target', (feature) -> feature == scope.targetFeature
              .exit().remove()

        if features.length > 0
          # Enable feature map paning and zooming
          scope.zoomApi = svgPanZoom svg[0],
                                      fit: false
                                      controlIconsEnabled: false

        return

      # Initial d3 rendering
      render()

      # Rerender when variables change
      # TODO also fire when only name or relevancy are changed
      scope.$watchCollection 'features', render
      scope.$watch 'targetFeature', render
      return
  }
]
