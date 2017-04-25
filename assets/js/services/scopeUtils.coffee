app.factory 'scopeUtils', [
  '$q',
  ($q) ->

    waitForVariableSet = (scope, variableName) ->
      currentValue = scope.$eval variableName
      if currentValue?
        $q.resolve currentValue
      return $q (resolve, reject) ->
        unregister = scope.$watch variableName, (newValue, oldValue) ->
          if newValue?
            resolve newValue
            unregister()
    waitForVariablesSet = (scope, variableNames) ->
      return $q.all [waitForVariableSet scope, v for v in variableNames]

    return {
      waitForVariableSet: waitForVariableSet
      waitForVariablesSet: waitForVariablesSet
    }
]
