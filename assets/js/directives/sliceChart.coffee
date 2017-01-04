app.directive 'sliceChart', ['$timeout', ($timeout) ->
  return {
    restrict: 'E'
    scope:
      chartRange: '='
      slices: '='
      onSliceClick: '&onSliceClick'
    link: (scope, element, attrs) ->
      svg = angular.element(document.createElementNS('http://www.w3.org/2000/svg', 'svg'))
      element.append svg

      render = ->

        # Offset from one slice to the other
        Y_OFFSET = 15

        chartLength = scope.chartRange[1] - scope.chartRange[0]

        containedSlices = scope.slices.filter (slice) ->
          return slice.range[0] < scope.chartRange[1] and
                  slice.range[1] > scope.chartRange[0]

        # set height of container
        containerHeight = Y_OFFSET * containedSlices.length
        svg.attr 'viewBox', "0 0 100 #{containerHeight}"
            .css 'height', "#{containerHeight}px"

        getSliceWidth = (slice, idx) ->
          sliceLength = slice.range[1] - slice.range[0]
          return sliceLength / chartLength * 100

        getSliceXPosition = (slice, idx) ->
          sliceOffset = slice.range[0] - scope.chartRange[0]
          return sliceOffset / chartLength * 100

        getSliceYPosition = (slice, idx) ->
          return idx * Y_OFFSET

        rects = d3.select svg[0]
                  .selectAll 'rect'
                  .data containedSlices
        rects.enter().append 'rect'
              .on 'click', (slice) ->
                scope.$apply ->
                  scope.onSliceClick { slice: slice }
                  scope.selectedSlice = slice
                  render()
                return
        rects.attr 'width', getSliceWidth
              .attr 'x', getSliceXPosition
              .attr 'y', getSliceYPosition
              .classed 'selected', (slice) ->
                return slice == scope.selectedSlice
        rects.exit().remove()
              
        return

      # Initial d3 rendering
      render()

      # Rerender when variables change
      scope.$watchGroup ['chartRange', 'slices'], render
      return
  }
]
