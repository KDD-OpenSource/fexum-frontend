app.directive 'cornerMenu', [
  'backendService', '$location',
  (backendService, $location) ->
    return {
      restrict: 'E'
      template: JST['assets/templates/cornerMenu']
      link: (scope, element, attrs) ->

        scope.logout = ->
        backendService.logout()
          .then ->
            $location.path '/login'

        return
    }
]
