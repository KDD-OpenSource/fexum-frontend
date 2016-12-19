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

  return
]
