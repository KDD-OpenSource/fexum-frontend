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
      chart = angular.element(document.createElementNS('http://www.w3.org/2000/svg', 'g'))
      svg.append chart

      # Scores
      svg.append 'text'
         .attr 'x', 30
         .attr 'y', -15
         .attr 'text-anchor', 'middle'
         .text 'Scores'
      scoreList = angular.element(document.createElementNS('http://www.w3.org/2000/svg', 'g'))
      svg.append scoreList

      render = ->

        # Offset from one slice to the other
        Y_OFFSET = 15        

        chartLength = scope.chartRange[1] - scope.chartRange[0]

        containedSlices = scope.slices.filter (slice) ->
          return slice.range[0] < scope.chartRange[1] and
                  slice.range[1] > scope.chartRange[0]

        # set height of container
        containerHeight = Y_OFFSET * containedSlices.length
        chart.attr 'x', 60
            .attr 'viewBox', "0 0 100 #{containerHeight}"
            .attr 'preserveAspectRatio', 'none'
            .css 'height', "#{containerHeight}px"

        getSliceWidth = (slice, idx) ->
          sliceLength = slice.range[1] - slice.range[0]
          inPercent = sliceLength / chartLength * 100

          # Set slice length to a minimum of 10% in order to still be clickable
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
        scoreList.attr 'width', 60

        scores = d3.select scroreList[0]
                   .selectAll 'text'
                   .data containedSlices
        scores.enter().append 'rect'
              .text (slice) -> slice.score
        scores.attr 'y', getSliceYPosition
              .classed 'selected', (slice) ->
                return slice == scope.selectedSlice

        return

      # Initial d3 rendering
      render()

      # Rerender when variables change
      scope.$watchGroup ['chartRange', 'slices', 'selectedSlice'], render
      return
  }
]
