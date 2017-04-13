app.directive 'cornerMenu', ->
  return {
    restrict: 'E'
    scope:
      logout: '&logout'
    template: JST['assets/templates/cornerMenu']
    link: (scope, element, attrs) ->

      return
  }
