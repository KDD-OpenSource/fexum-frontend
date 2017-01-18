app.constant 'chartColors',
  defaultColor: '#90A4AE'
  targetColor: '#4CAF50'
  selectionColor1: '#FFB74D'
  selectionColor2: '#FF5722'
app.constant 'chartTemplates',
  lineChart:
    options:
      chart:
        type: 'lineChart'
        x: (data) -> data.x
        y: (data) -> data.y
        valueFormat: d3.format '.3g'
        xAxis:
          tickFormat: d3.format '.3g'
        yAxis:
          tickFormat: d3.format '.3g'
        margin:
          top: 20
          right: 20
          bottom: 45
          left: 60
  historicalBarChart:
    options:
      chart:
        type: 'historicalBarChart'
        x: (data) ->
          return (data.range[0] + data.range[1]) / 2
        y: (data) ->
          return data.count
        valueFormat: d3.format '.3g'
        xAxis:
          axisLabel: 'Value'
          tickFormat: d3.format '.3g'
        yAxis:
          axisLabel: 'Count'
          tickFormat: d3.format '.3g'
        margin:
          top: 20
          right: 20
          bottom: 45
          left: 60
  multiBarChart:
    options:
      chart:
        type: 'multiBarChart'
        x: (data) -> data.x
        y: (data) -> data.y
        valueFormat: d3.format '.3g'
        xAxis:
          tickFormat: d3.format '.3g'
        yAxis:
          tickFormat: d3.format '.3g'
        margin:
          top: 50
          right: 20
          bottom: 45
          left: 60
