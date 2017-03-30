app.filter 'd3format', ->
  return (input, formatStr = '.5g') ->
    formatter = d3.format formatStr
    return formatter input
