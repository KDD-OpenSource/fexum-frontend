app.controller 'FeatureInfoCtrl', ['$scope', '$routeParams', '$filter', '$timeout', \
                                    ($scope, $routeParams, $filter, $timeout) ->

  # Retrieve feature object
  $scope.feature = $filter('filter')($scope.features, {name: $routeParams.featureName}, true)[0]

  $scope.setupCharts = ->
    console.log 'Setting up charts'
    $scope.lineChart =
      options:
        chart:
          type: 'lineChart'
          x: (data) -> data.x
          y: (data) -> data.y
          xAxis:
            axisLabel: 'Time (seconds)'
          yAxis:
            axisLabel: 'Value'
      data: [
        {
          # TODO replace this with real queries
          values: ({x: idx, y: Math.floor(Math.random() * 100)} for idx in [0..100])
          key: $scope.feature.name
        }
      ]
    return

  # charts should be set up when layouting is done
  # sadly there is no event available for that
  $timeout $scope.setupCharts, 200

  # TODO replace this with real queries
  $scope.feature.mean = Math.random() * 100
  $scope.feature.variance = Math.random() * 100

  return

]
