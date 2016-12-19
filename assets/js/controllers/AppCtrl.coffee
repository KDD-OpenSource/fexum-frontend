app.controller 'AppCtrl', ['$scope', ($scope) ->

  # MOCK FEATURES
  # TODO replace from endpoint
  $scope.features = [
    {
      name: 'fuel-consumption'
      relevancy: 0.9
    }
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
      relevancy: 0.6
    }
    {
      name: 'fuel-gauge'
      relevancy: 0.9
    }
    {
      name: 'mass'
      relevancy: 0.1
    }
    {
      name: 'brakes-state'
      relevancy: 0.2
    }
    {
      name: 'age'
      relevancy: 0.4
    }
    {
      name: 'elapsed-time'
      relevancy: 0.2
    }
    {
      name: 'feature #1'
      relevancy: 0.3
    }
    {
      name: 'feature #2'
      relevancy: 0.3
    }
    {
      name: 'feature #3'
      relevancy: 0.4
    }
    {
      name: 'feature #4'
      relevancy: 0.45
    }
    {
      name: 'feature #5'
      relevancy: 0.75
    }
    {
      name: 'feature #6'
      relevancy: 0.15
    }
  ]

  $scope.updateRelevancies = ->
    # TODO actually update the features
    $scope.features.forEach (feature) ->
      randomRelevancy = Math.random()
      feature.relevancy = randomRelevancy

  $scope.setTarget = (targetFeature) ->
    if targetFeature
      $scope.searchText = targetFeature.name
      $scope.targetFeature = targetFeature
      $scope.targetFeatureIndex = $scope.features.indexOf targetFeature
      $scope.updateRelevancies()
    $scope.updateMap()
    return

  $scope.isTarget = (feature) ->
    return $scope.targetFeature == feature

  # TODO this could be called whenever features or target change instead
  $scope.updateMap = ->
    featureCount = $scope.features.length
    MAX_DISTANCE = 500
    OFFSET = 100

    # evenly arrange the features around the target feature
    getFeaturePosition = (feature, idx) ->
      isTarget = $scope.isTarget feature
      if isTarget
        return [0, 0]
      radius = (1 - feature.relevancy) * MAX_DISTANCE + OFFSET
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

    getFeatureLink = (feature) ->
      encodedName = window.encodeURIComponent feature.name
      return "/feature/#{encodedName}"

    # Update feature map using d3
    nodes = d3.select '#feature-map'
                .selectAll 'g.feature'
                .data $scope.features
    newNodes = nodes.enter().append 'g'
                .classed 'feature', true
    newLinks = newNodes.append 'a'
    newLinks.append 'ellipse'
    newLinks.append 'text'
                .merge(nodes.selectAll 'text')
                .text (feature) -> feature.name
    newLinks.merge(nodes.selectAll 'a')
                .attr 'xlink:href', getFeatureLink
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
