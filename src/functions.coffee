###
@class functions
###
functions = {}

###
@method sum
@static
@param {Number[]} values
@return {Number} The sum of the values
###
functions.sum = (values) ->
  temp = 0
  for v in values
    temp += v
  return temp

###
@method sumSquares
@static
@param {Number[]} values
@return {Number} The sum of the squares of the values
###
functions.sumSquares = (values) ->
  temp = 0
  for v in values
    temp += v * v
  return temp

###
@method count
@static
@param {Number[]} values
@return {Number} The length of the values Array
###
functions.count = (values) ->
  return values.length

###
@method min
@static
@param {Number[]} values
@return {Number} The minimum value or null if no values
###
functions.min = (values) ->
  if values.length == 0
    return null
  temp = values[0]
  for v in values
    if v < temp
      temp = v
  return temp

###
@method max
@static
@param {Number[]} values
@return {Number} The maximum value or null if no values
###
functions.max = (values) ->
  if values.length == 0
    return null
  temp = values[0]
  for v in values
    if v > temp
      temp = v
  return temp

###
@method values
@static
@param {Number[]} values
@return {Array} All values (allows duplicates). Can be used for drill down when you know they will be unique.
###
functions.values = (values) ->
  return values
#  temp = []
#  for v in values
#    temp.push(v)
#  return temp

###
@method uniqueValues
@static
@param {Number[]} values
@return {Array} Unique values. This is good for generating an OLAP dimension or drill down.
###
functions.uniqueValues = (values) ->
  temp = {}
  temp2 = []
  for v in values
    temp[v] = null
  for key, value of temp
    temp2.push(key)
  return temp2

###
@method average
@static
@param {Number[]} values
@return {Number} The arithmetic mean
###
functions.average = (values) ->
  count = values.length
  sum = 0
  for v in values
    sum += v
  return sum / count

###
@method variance
@static
@param {Number[]} values
@return {Number} The variance
###
functions.variance = (values) ->
  n = values.length
  sum = 0
  sumSquares = 0
  for v in values
    sum += v
    sumSquares += v * v
  return (n * sumSquares - sum * sum) / (n * (n - 1))

###
@method standardDeviation
@static
@param {Number[]} values
@return {Number} The standard deviation
###
functions.standardDeviation = (values) ->
  return Math.sqrt(functions.variance(values))

###
@method percentileCreator
@static
@param {Number} p The percentile for the resulting function (50 = median, 75, 99, etc.)
@return {Function} A funtion to calculate the percentile

When the user passes in `p<n>` as an aggregation function, this `percentileCreator` is called to return the appropriate
percentile function. The returned function will find the `<n>`th percentile where `<n>` is some number in the form of
`##[.##]`. (e.g. `p40`, `p99`, `p99.9`).

Note: `median` is an alias for `p50`.

There is no official definition of percentile. The most popular choices differ in the interpolation algorithm that they
use. The function returned by this `percentileCreator` uses the Excel interpolation algorithm which is close to the NIST
recommendation and makes the most sense to me.
###
functions.percentileCreator = (p) ->
  return (values) ->
    sortfunc = (a, b) ->
      return a - b
    vLength = values.length
    values.sort(sortfunc)
    n = (p * (vLength - 1) / 100) + 1
    k = Math.floor(n)
    d = n - k
    if n == 1
      return values[1 - 1]
    if n == vLength
      return values[vLength - 1]
    return values[k - 1] + d * (values[k] - values[k - 1])

exports.functions = functions