app.controller 'LoginCtrl', [
  '$scope',
  'backendService',
  '$location',
  ($scope, backendService, $location) ->

    updateErrors = (form, error) ->
      if error.non_field_errors?
        form.nonFieldError = error.non_field_errors.map((err) -> '  - ' + err + '\n').join ''
      if error.username?
        form.userName.$error.custom = ' ' + error.username[0]
      if error.password?
        form.userPassword.$error.custom = ' ' + error.password[0]

    resetErrors = (form) ->
      form.userName.$error.custom = null
      form.userPassword.$error.custom = null
      form.nonFieldError = null

    successCallback = (form) ->
      resetErrors form
      $location.path '/'

    errorCallback = (form, response) ->
      if response.data?
        updateErrors form, response.data
      else
        console.error response

    $scope.login = ->
      backendService.login $scope.login.user
        .then (response) ->
          successCallback $scope.loginForm
        .fail (response) ->
          errorCallback $scope.loginForm, response

    $scope.register = ->
      backendService.register $scope.register.user
        .then (response) ->
          successCallback $scope.registerForm
        .fail (response) ->
          errorCallback $scope.registerForm, response
]
