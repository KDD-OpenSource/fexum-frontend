app.controller 'AppCtrl', ['$scope', ($scope) ->

  # MOCK FEATURES
  # TODO replace from endpoint
  $scope.features = [
    {
      name: 'degeneration-grade'
      relevancy: 0.1
    }
    {
      name: 'engine-temperature'
      relevancy: 0.3
    }
    {
      name: 'velocity'
      relevancy: 0.3
    }
    {
      name: 'acceleration'
      relevancy: 0.8
    }
    {
      name: 'fuel-consumption'
      relevancy: 0.9
    }
  ]

  $scope.setTarget = (targetFeature) ->
    if targetFeature
      $scope.searchText = targetFeature.name
      $scope.targetFeature = targetFeature
      $scope.targetFeatureIndex = $scope.features.indexOf targetFeature
    $scope.updateMap()
    return

  $scope.isTarget = (feature) ->
    return $scope.targetFeature == feature

  # TODO this could be called whenever features or target change instead
  $scope.updateMap = ->
    featureCount = $scope.features.length
    MAX_DISTANCE = 500

    # evenly arrange the features around the target feature
    getFeaturePosition = (feature, idx) ->
      isTarget = $scope.isTarget feature
      if isTarget
        return [0, 0]
      radius = (1 - feature.relevancy) * MAX_DISTANCE
      # index is 1 too big if this item is behind the target in the list
      if idx > $scope.targetFeatureIndex
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

    nodes = d3.select '#feature-map'
                .selectAll 'g.feature'
                .data $scope.features
    newNodes = nodes.enter().append 'g'
                .classed 'feature', true
    newNodes.append 'ellipse'
    newNodes.append 'text'
                .merge(nodes.selectAll 'text')
                .text (feature) -> feature.name
    allNodes = newNodes.merge nodes
                .attr 'transform', getFeatureTranslationString
                .classed 'is-target', $scope.isTarget
                .exit().remove()

    # Enable feature map paning and zooming
    svgPanZoom '#feature-map',
      fit: false
      controlIconsEnabled: true

    return


  return
]
