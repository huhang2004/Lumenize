ChartTime = require('./ChartTime').ChartTime
utils = require('./utils')
    
csvStyleArray_To_ArrayOfMaps = (csvStyleArray, rowKeys) ->
  ###
  @method csvStyleArray_To_ArrayOfMaps
  @param {Array[]} csvStyleArray The first row is usually the list of column headers but if not, you can
    provide your own such list in the second parameter
  @param {String[]} [rowKeys] specify the column headers like `['column1', 'column2']`. If not provided, it will use
    the first row of the csvStyleArray
  @return {Object[]}

  `csvStyleArry_To_ArryOfMaps` is a convenience function that will convert a csvStyleArray like:
  
      {csvStyleArray_To_ArrayOfMaps} = require('../')

      csvStyleArray = [
        ['column1', 'column2'],
        [1         , 2       ],
        [3         , 4       ],
        [5         , 6       ]
      ]
  
  to an Array of Maps like this:
  
      console.log(csvStyleArray_To_ArrayOfMaps(csvStyleArray))
  
      # [ { column1: 1, column2: 2 },
      #   { column1: 3, column2: 4 },
      #   { column1: 5, column2: 6 } ]
  `
  ###
  arrayOfMaps = []
  if rowKeys?
    i = 0
  else
    rowKeys = csvStyleArray[0]
    i = 1
  tableLength = csvStyleArray.length
  while i < tableLength
    inputRow = csvStyleArray[i]
    outputRow = {}
    for key, index in rowKeys
      outputRow[key] = inputRow[index]
    arrayOfMaps.push(outputRow)
    i++
  return arrayOfMaps
  
snapshotArray_To_AtArray = (snapshotArray, listOfAtCTs, validFromField, uniqueIDField, tz, validToField) ->  
  ###
  @method snapshotArray_To_AtArray
  @param {Object[]} snapshotArray Array of snapshots sorted by validFromField # !TODO: Add the sort. Borrow from TimeInState.
  @param {Array[]} atArray Array of ChartTime objects representing the moments we want the snapshots at
  @param {String} validFromField Specifies the field that holds a date string in ISO-8601 canonical format (eg `2011-01-01T12:34:56.789Z`)
  @param {String} validToField Same except for the end of the snapshot's active time.
    Defaults to '_ValidTo' for backward compatibility reasons.
  @param {String} uniqueIDField Specifies the field that holds the unique ID. Note, no matter the input type, they will come
     out the other side as Strings. I could fix this if it ever became a problem.
  @param {String} tz
  @return {Array[]}

  If you have a list of snapshots representing the changes in a set of work items over time, this function will return the state of
  each item at each moments of interest. It's useful for time-series charts where you have snapshot or change records but you need to know
  the values at particular moments in time (the times in listOfAtCTs).
  
  Since this transformation is timezone dependent, you'll need to initialize ChartTime with the path to the tz files.
  Note, that if you use the browserified version of Lumenize, you still need to call setTZPath with some dummy path.
  I'm hoping to fix this at some point.

      {snapshotArray_To_AtArray, ChartTime} = require('../')

  It will convert an snapshotArray like:

      snapshotArray = [
        {_ValidFrom: '1999-01-01T12:00:00.000Z', _ValidTo:'2010-01-02T12:00:00.000Z', ObjectID: 0, someColumn: 'some value'},
        {_ValidFrom: '2011-01-01T12:00:00.000Z', _ValidTo:'2011-01-02T12:00:00.000Z', ObjectID: 1, someColumn: 'some value'},
        {_ValidFrom: '2011-01-02T12:00:00.000Z', _ValidTo:'9999-01-01T12:00:00.000Z', ObjectID: 2, someColumn: 'some value 2'},      
        {_ValidFrom: '2011-01-02T12:00:00.000Z', _ValidTo:'2011-01-03T12:00:00.000Z', ObjectID: 3, someColumn: 'some value'},
        {_ValidFrom: '2011-01-05T12:00:00.000Z', _ValidTo:'9999-01-01T12:00:00.000Z', ObjectID: 1, someColumn: 'some value'},
        {_ValidFrom: '2222-01-05T12:00:00.000Z', _ValidTo:'9999-01-01T12:00:00.000Z', ObjectID: 99, someColumn: 'some value'},
      ]
      
  And a listOfAtCTs like:
  
      listOfAtCTs = [new ChartTime('2011-01-02'), new ChartTime('2011-01-03'), new ChartTime('2011-01-07')]
      
  To an atArray with the value of each ObjectID at each of the points in the listOfAtCTs like:
  
      a = snapshotArray_To_AtArray(snapshotArray, listOfAtCTs, '_ValidFrom', 'ObjectID', 'America/New_York', '_ValidTo')
      
      console.log(a)
  
      # [ [ { _ValidFrom: '2011-01-01T12:00:00.000Z',
      #       _ValidTo: '2011-01-02T12:00:00.000Z',
      #       ObjectID: '1',
      #       someColumn: 'some value' } ],
      #   [ { _ValidFrom: '2011-01-02T12:00:00.000Z',
      #       _ValidTo: '9999-01-01T12:00:00.000Z',
      #       ObjectID: '2',
      #       someColumn: 'some value 2' },
      #     { _ValidFrom: '2011-01-02T12:00:00.000Z',
      #       _ValidTo: '2011-01-03T12:00:00.000Z',
      #       ObjectID: '3',
      #       someColumn: 'some value' } ],
      #   [ { _ValidFrom: '2011-01-05T12:00:00.000Z',
      #       _ValidTo: '9999-01-01T12:00:00.000Z',
      #       ObjectID: '1',
      #       someColumn: 'some value' },
      #     { _ValidFrom: '2011-01-02T12:00:00.000Z',
      #       _ValidTo: '9999-01-01T12:00:00.000Z',
      #       ObjectID: '2',
      #       someColumn: 'some value 2' } ] ]
  ###
  unless validToField?
    validToField = '_ValidTo'
  atLength = listOfAtCTs.length
  snapshotLength = snapshotArray.length
  preOutput = []
  if (atLength <= 0 or snapshotLength <= 0)
    return preOutput
  atPointer = 0
  granularity = listOfAtCTs[0].granularity
  snapshotPointer = 0
  currentSnapshot = snapshotArray[snapshotPointer]
  currentRow = {}
  
  # Convert listOfAtCTs to Strings
  listOfAtStrings = []
  for atCT in listOfAtCTs
    listOfAtStrings.push(atCT.getShiftedISOString(tz))

  currentAtString = listOfAtStrings[atPointer]
  currentSnapshotValidFrom = currentSnapshot[validFromField]
  
  while snapshotPointer < snapshotLength
    if currentSnapshotValidFrom >= currentAtString
      preOutput.push(currentRow)
      currentRow = utils.clone(currentRow)
      atPointer++
      if atPointer < atLength 
        currentAtString = listOfAtStrings[atPointer]
      else
        break
    else
      unless currentRow[uniqueIDField]?
        currentRow[currentSnapshot[uniqueIDField]] = {}
      for key, value of currentSnapshot
        currentRow[currentSnapshot[uniqueIDField]][key] = value
      snapshotPointer++
      if snapshotPointer < snapshotLength
        currentSnapshot = snapshotArray[snapshotPointer]
        currentSnapshotValidFrom = currentSnapshot[validFromField]
      else
        while atPointer < atLength
          preOutput.push(currentRow)
          atPointer++
          
  # If the validToField is less than the corresponding atCT, then remove it because that means
  # it was either deleted or fell out of the selection filter prior to this atCT

  for atRow, index in preOutput
    toDelete = []
    atString = listOfAtStrings[index]
    for uniqueID, atValue of atRow
      validToString = atValue[validToField]
      if validToString < atString
        toDelete.push(uniqueID)
    for d in toDelete
      delete atRow[d]        
          
  # Squash the uniqueIDField into each sub row       
  output = []
  for atRow in preOutput
    outputRow = []
    for key, value of atRow
      value[uniqueIDField] = key
      outputRow.push(value)
    output.push(outputRow)
  return output

groupByAtArray_To_HighChartsSeries = (groupByAtArray, nameField, valueField, nameFieldValues, returnPreOutput = false) ->  # !TODO: Move to RallyAnalytics
  ###
  @method groupByAtArray_To_HighChartsSeries
  @param {Array[]} groupByAtArray result of calling groupByAt()
  @param {String} nameField
  @param {String} valueField
  @pararm {String[]} nameFieldValues
  @param {Boolean} [returnPreOutput] if true, this function returns the map prior to squishing the name into the rows
  @return {Array/Object}

  Takes an array of arrays that came from groupByAt and looks like this:

      {groupByAtArray_To_HighChartsSeries} = require('../')

      groupByAtArray = [
        [
          { 'CFDField': 8, KanbanState: 'Ready to pull' },
          { 'CFDField': 5, KanbanState: 'In progress' },
          { 'CFDField': 9, KanbanState: 'Accepted' },
        ],
        [
          { 'CFDField': 2, KanbanState: 'Ready to pull' },
          { 'CFDField': 3, KanbanState: 'In progress' },
          { 'CFDField': 17, KanbanState: 'Accepted' },
        ]
      ]
  
  and optionally a list of nameFieldValues
  
      nameFieldValues = ['Ready to pull', 'In progress']  # Note, Accepted is missing
      
  and extracts the `valueField` under nameField to give us this
  
      console.log(groupByAtArray_To_HighChartsSeries(groupByAtArray, 'KanbanState', 'CFDField', nameFieldValues))
      # [ { name: 'Ready to pull', data: [ 8, 2 ] },
      #   { name: 'In progress', data: [ 5, 3 ] } ]
      
  ###
  preOutput = {}
  unless nameFieldValues?
    nameFieldValues = []
    for f in groupByAtArray[0]
      nameFieldValues.push(f[nameField])
  for groupByRow in groupByAtArray
    for perNameValueRow in groupByRow
      unless preOutput[perNameValueRow[nameField]]?
        preOutput[perNameValueRow[nameField]] = []
      preOutput[perNameValueRow[nameField]].push(perNameValueRow[valueField])
  if returnPreOutput
    return preOutput
  # Squash the nameField into each sub row       
  output = []
  for name in nameFieldValues
    outputRow = {name: name, data: preOutput[name]}
    output.push(outputRow)
  return output


aggregationAtArray_To_HighChartsSeries = (aggregationAtArray, aggregationSpec) ->  # !TODO: Move to RallyAnalytics
  ###
  @method aggregationAtArray_To_HighChartsSeries
  @param {Array[]} aggregationAtArray
  @param {Object} aggregationSpec You can use the same spec you useed to call aggregateAt() as long as it includes
    any yAxis specifications
  @return {Object[]} in HighCharts form

  Takes an array of arrays that came from a call to aggregateAt() and looks like this:

      {aggregationAtArray_To_HighChartsSeries} = require('../')

      aggregationAtArray = [
        {"Series 1": 8, "Series 2": 5, "Series3": 10},
        {"Series 1": 2, "Series 2": 3, "Series3": 20}
      ]
  
  and a list of series configurations
  
      aggregationSpec = [
        {name: "Series 1", yAxis: 1},
        {name: "Series 2"}
      ]
      
  and extracts the data into seperate series
  
      console.log(aggregationAtArray_To_HighChartsSeries(aggregationAtArray, aggregationSpec))
      # [ { name: 'Series 1', data: [ 8, 2 ], yAxis: 1 },
      #   { name: 'Series 2', data: [ 5, 3 ] } ]
      
  Notice how the extra fields from the series array are included in the output.
  ###
  
  preOutput = {}
  
  seriesNames = []
  for a in aggregationSpec
    seriesNames.push(a.name)

  for aggregationRow in aggregationAtArray
    for s in seriesNames
      unless preOutput[s]?
        preOutput[s] = []
      preOutput[s].push(aggregationRow[s])

  # Squash the nameField into each sub row       
  output = []
  for s, idx in seriesNames
    outputRow = {name: s, data: preOutput[s]}
    seriesRow = aggregationSpec[idx]
    for key, value of seriesRow
      unless key in ['name', 'data']
        outputRow[key] = value
    output.push(outputRow)
  return output


exports.csvStyleArray_To_ArrayOfMaps = csvStyleArray_To_ArrayOfMaps
exports.snapshotArray_To_AtArray = snapshotArray_To_AtArray
exports.groupByAtArray_To_HighChartsSeries = groupByAtArray_To_HighChartsSeries
exports.aggregationAtArray_To_HighChartsSeries = aggregationAtArray_To_HighChartsSeries
