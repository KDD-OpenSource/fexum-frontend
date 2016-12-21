app.controller 'FeatureInfoCtrl', ['$scope', '$routeParams', '$filter', '$timeout', \
                                    ($scope, $routeParams, $filter, $timeout) ->

  # Retrieve feature object
  $scope.feature = $filter('filter')($scope.features, {name: $routeParams.featureName}, true)[0]

  $scope.setupCharts = ->
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
          margin:
            top: 20
            right: 20
            bottom: 45
            left: 60
      data: [
        {
          # TODO replace this with real queries
          values: ({x: idx, y: Math.floor(Math.random() * 100)} for idx in [0..100])
          key: $scope.feature.name
        }
      ]
    $scope.histogram =
      options:
        chart:
          type: 'historicalBarChart'
          x: (data) -> data.bucket[1]
          y: (data) -> data.y
          xAxis:
            axisLabel: 'Value'
          yAxis:
            axisLabel: 'Count'
          margin:
            top: 20
            right: 20
            bottom: 45
            left: 60
          bars:
            dispatch:
              elementClick: (event) ->
                $scope.$apply ->
                  $scope.selectedRange = event.data.bucket
                return
      data: [
        {
          # TODO replace this with real queries
          values: ({bucket: [idx - 1, idx], y: Math.floor(Math.random() * 100)} for idx in [1..10])
          key: $scope.feature.name
        }
      ]

    return

  $scope.clearSelectedRange = ->
    $scope.selectedRange = null
    return

  # charts should be set up when layouting is done
  # sadly there is no event available for that
  $timeout $scope.setupCharts, 200

  # TODO replace this with real queries
  $scope.feature.mean = Math.random() * 100
  $scope.feature.variance = Math.random() * 100
  $scope.feature.slices = []
  for idx in [0...100]
    rangeStart = Math.random() * 10
    rangeLength = Math.random() * 2
    $scope.feature.slices.push {
      range: [rangeStart, rangeStart + rangeLength]
      marginal: [0, 0.1, 0.5, 0.1, 0]
      conditional: [0, 0.1, 0.3, 0.5, 0.8]
    }

  return

]
