app.controller 'AppCtrl', ['$scope', ($scope) ->

  $scope.features = [
    { name: 'velocity' }
    { name: 'degeneration-grade' }
    { name: 'engine-temperature' }
  ]

  $scope.setTarget = (targetFeature) ->
    if targetFeature
      $scope.searchText = targetFeature.name
      console.log targetFeature

  # Enable feature map paning and zooming
  svgPanZoom '#feature-map',
    fit: false
    controlIconsEnabled: true

  return
]
