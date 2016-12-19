app.controller 'FeatureInfoCtrl', ['$scope', '$routeParams', '$filter', \
                                    ($scope, $routeParams, $filter) ->
  $scope.lineChart =
    options:
      chart:
        type: 'lineChart'
        height: 450
        x: (data) -> data.x
        y: (data) -> data.y
        xAxis:
          axisLabel: 'Time (seconds)'
        yAxis:
          axisLabel: 'Value'
      title:
        enable: true
        text: 'Feature line plot'

  $scope.feature = $filter('filter')($scope.features, {name: $routeParams.featureName}, true)[0]

  # TODO replace this with real queries
  $scope.feature.mean = Math.random() * 100
  $scope.feature.variance = Math.random() * 100

  $scope.lineChart.data = ({x: idx, y: Math.random() * 100} for idx in [0..100])
  return

]
