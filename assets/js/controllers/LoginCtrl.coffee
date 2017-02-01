app.controller 'LoginCtrl', [
  '$scope',
  'backendService',
  '$location',
  ($scope, backendService, $location) ->

    $scope.clickLogin = ->
      inProgress = true
      backendService.login($scope.user).then ->
          inProgress = false
          $location.path '/'

]
