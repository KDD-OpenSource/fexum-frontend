# Shuffles array in place
Array.prototype.shuffle = ->
  for i in [this.length...0] by -1
    j = Math.floor(Math.random() * i)
    [this[i - 1], this[j]] = [this[j], this[i - 1]]

# Calculates the sum
Array.prototype.sum = ->
  sumOp = (ac, val) -> ac + val
  return this.reduce sumOp, 0

# Calculates the mean
Array.prototype.mean = ->
  return this.sum() / this.length
