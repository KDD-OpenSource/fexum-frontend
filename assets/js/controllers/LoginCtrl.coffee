app.controller 'LoginCtrl', [
  '$scope',
  'backendService',
  '$location',
  ($scope, backendService, $location) ->

    $scope.clickLogin = ->
      backendService.login($scope.user)
        .then ->
          $scope.login.userName.$error.custom = null
          $scope.login.userPassword.$error.custom = null
          document.getElementById('errorField').textContent = null
          document.getElementById('errorField').setAttribute 'style', 'visibility:hidden;'
          $location.path '/'
        .catch (response) ->
          error = response.data
          if error.non_field_errors?
            errorMessage = error.non_field_errors.map((err) -> '  - ' + err + '\n')
            document.getElementById('errorField').textContent = errorMessage
            document.getElementById('errorField').setAttribute 'style', 'visibility:visible;'
          if error.username?
            $scope.login.userName.$error.custom = ' ' + error.username[0]
          if error.password?
            $scope.login.userPassword.$error.custom = ' ' + error.password[0]


    $scope.clickRegister = ->
      # TODO

]
