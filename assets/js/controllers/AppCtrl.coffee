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
      $scope.updateRelevancies()
    return

  return
]
