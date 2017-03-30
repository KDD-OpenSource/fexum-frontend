# Shuffles array in place
Array.prototype.shuffle = ->
  for i in [@length...0] by -1
    j = Math.floor(Math.random() * i)
    [@[i - 1], @[j]] = [@[j], @[i - 1]]

# Calculates the sum
Array.prototype.sum = ->
  sumOp = (ac, val) -> ac + val
  return @reduce sumOp, 0

# Calculates the mean
Array.prototype.mean = ->
  return @sum() / @length

Array.prototype.removeObject = (obj) ->
  idx = @indexOf obj
  if idx >= 0
    @splice idx, 1
    return true
  return false

objectMap = (object, callback) ->
  mappedValues = []
  for k, v of object
    result = callback k, v
    mappedValues.push result
  return mappedValues
