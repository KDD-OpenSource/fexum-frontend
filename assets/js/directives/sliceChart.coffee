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
        .attr 'overflow', 'visible'
      element.append svg

      # Slice chart
      chart = angular.element(document.createElementNS('http://www.w3.org/2000/svg', 'svg'))
      svg.append chart

      # Scores
      scoreTitle = angular.element(document.createElementNS('http://www.w3.org/2000/svg', 'text'))
         .attr 'x', -25
         .attr 'y', -8
         .css 'font-size', 14
         .attr 'text-anchor', 'middle'
         .text 'Scores'
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

        # set height of container
        containerHeight = Y_OFFSET * containedSlices.length
        chart.attr 'x', 0
            .attr 'viewBox', "0 0 100 #{containerHeight}"
            .attr 'preserveAspectRatio', 'none'
            #.css 'height', "#{containerHeight}px"
        svg.attr 'height', "#{containerHeight}px"

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
        scoreList.attr 'x', -4
            .attr 'y', 10
            .attr 'overflow', 'visible'
            .css 'height', '100%'


        getScoreYPosition = (slice, idx) ->
          return idx * (1.0*containerHeight/containedSlices.length)

        scores = d3.select scoreList[0]
                   .selectAll 'text'
                   .data containedSlices
        scores.enter().append 'text'
        scores.attr 'y', getScoreYPosition
              .attr 'text-anchor', 'end'
              .attr 'fill', '#FFB74D'
              .text (slice) -> return ""+slice.score
              .classed 'selected', (slice) ->
                return slice == scope.selectedSlice
        scores.exit().remove()

        console.log scope.slices

        return

      # Initial d3 rendering
      render()

      # Rerender when variables change
      scope.$watchGroup ['chartRange', 'slices', 'selectedSlice'], render
      return
  }
]
