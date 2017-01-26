app.constant 'chartColors',
  defaultColor: '#90A4AE'
  targetColor: '#4CAF50'
  selectionColor1: '#FFB74D'
  selectionColor2: '#FF5722'
  targetClassColors: [
    '#F44336',
    '#9C27B0',
    '#673AB7',
    '#2196F3',
    '#009688',
    '#4CAF50',
    '#FFEB3B',
    '#FF5722',
    '#795548',
    '#000000'
  ]
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
          top: 60
          right: 20
          bottom: 45
          left: 60
  scatterChart:
    options:
      chart:
        type: 'scatterChart'
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
          bottom: 40
          left: 60
