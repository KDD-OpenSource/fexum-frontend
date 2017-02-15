app.controller 'LoginCtrl', [
  '$scope',
  'backendService',
  '$location',
  ($scope, backendService, $location) ->

    updateErrors = (error) ->
      if error.non_field_errors?
        $scope.errorMessage = error.non_field_errors.map((err) -> '  - ' + err + '\n').join ''
      if error.username?
        $scope.loginForm.userName.$error.custom = ' ' + error.username[0]
      if error.password?
        $scope.loginForm.userPassword.$error.custom = ' ' + error.password[0]

    resetErrors = ->
      $scope.loginForm.userName.$error.custom = null
      $scope.loginForm.userPassword.$error.custom = null
      $scope.errorMessage = null

    successCallback = ->
      resetErrors()
      $location.path '/'

    errorCallback = (response) ->
      if response.data?
        updateErrors response.data
      else
        console.error response

    $scope.login = ->
      backendService.login $scope.user
        .then successCallback
        .fail errorCallback

    $scope.register = ->
      backendService.register $scope.user
        .then successCallback
        .fail errorCallback
]
