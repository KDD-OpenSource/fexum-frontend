app.directive 'sliceChart', ['$timeout', ($timeout) ->
  return {
    restrict: 'E'
    scope:
      chartRange: '='
      slices: '='
      onSliceClick: '&onSliceClick'
      selectedSlice: '='
    link: (scope, element, attrs) ->
      svg = angular.element(document.createElementNS('http://www.w3.org/2000/svg', 'svg'))
      element.append svg

      # Slice chart
      chart = angular.element(document.createElementNS('http://www.w3.org/2000/svg', 'svg'))
                .addClass 'chart'
      svg.append chart

      # Scores
      scoreTitle = angular.element(document.createElementNS('http://www.w3.org/2000/svg', 'text'))
      scoreTitle.addClass 'scoreTitle'
        .text 'Scores'
        .attr 'x', -25
        .attr 'y', -8
      svg.append scoreTitle

      scoreList = angular.element(document.createElementNS('http://www.w3.org/2000/svg', 'svg'))
      svg.append scoreList

      render = ->

        # Offset from one slice to the other
        Y_OFFSET = 15

        chartLength = scope.chartRange[1] - scope.chartRange[0]

        containedSlices = scope.slices.filter (slice) ->
          return slice.range[0] < scope.chartRange[1] and
                  slice.range[1] > scope.chartRange[0]
        containedSlices.sort (a, b) -> b.significance - a.significance

        # set height of container
        containerHeight = Y_OFFSET * containedSlices.length
        chart.attr 'x', 0
            .attr 'viewBox', "0 0 100 #{containerHeight}"
            .attr 'preserveAspectRatio', 'none'
        svg.attr 'height', "#{containerHeight}px"

        getSliceWidth = (slice, idx) ->
          sliceLength = slice.range[1] - slice.range[0]
          inPercent = sliceLength / chartLength * 100

          # Set slice length to a minimum of 3% in order to still be clickable
          inPercent = Math.max 3, inPercent

          return inPercent

        getSliceXPosition = (slice, idx) ->
          sliceOffset = slice.range[0] - scope.chartRange[0]
          return sliceOffset / chartLength * 100

        getSliceYPosition = (slice, idx) ->
          return idx * Y_OFFSET

        rects = d3.select chart[0]
                  .selectAll 'rect'
                  .data containedSlices
        rects.enter().append 'rect'
              .on 'click', (slice) ->
                scope.$apply ->
                  scope.selectedSlice = slice
                  scope.onSliceClick { slice: slice }
                return
        rects.attr 'width', getSliceWidth
              .attr 'x', getSliceXPosition
              .attr 'y', getSliceYPosition
              .classed 'selected', (slice) ->
                return slice == scope.selectedSlice
        rects.exit().remove()

        # Initialize score list
        scoreList.addClass 'scoreList'
          .attr 'x', -4
          .attr 'y', 10

        getScoreYPosition = (slice, idx) ->
          return idx * (1.0 * containerHeight / containedSlices.length)

        scores = d3.select scoreList[0]
          .selectAll 'text'
          .data containedSlices
        scores.enter()
          .append 'text'
        scores.attr 'y', getScoreYPosition
              .text (slice) -> return d3.format('.3g')(slice.significance)
              .classed 'score', true
              .classed 'selected', (slice) ->
                return slice == scope.selectedSlice
        scores.exit().remove()

        return

      # Initial d3 rendering
      render()

      # Rerender when variables change
      scope.$watchGroup ['chartRange', 'slices', 'selectedSlice'], render
      return
  }
]
