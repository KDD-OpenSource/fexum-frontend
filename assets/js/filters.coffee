app.filter 'd3format', ['defaultNumFormatter', (defaultNumFormatter) ->
  return (input, formatStr) ->
    if formatStr?
      formatter = d3.format formatStr
    else
      formatter = defaultNumFormatter
    return formatter input
]
