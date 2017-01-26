app.factory 'scopeUtils', [
  '$q',
  ($q) ->
    return {
      waitForVariableSet: (scope, variableName) ->
        currentValue = scope.$eval variableName
        if currentValue?
          $q.resolve currentValue
        return $q (resolve, reject) ->
          unregister = scope.$watch variableName, (newValue, oldValue) ->
            if newValue?
              resolve newValue
              unregister()
    }
]
