utils = require('./utils')

class ChartTimeInStateCalculator
  ###
  @class ChartTimeInStateCalculator

  Used to calculate how much time each uniqueID spent "in-state". You use this by querying a temporal data
  model (like Rally's Lookback API) with a predicate indicating the "state" of interest. You'll then have a list of
  snapshots where that predicate was true. You pass this in to the timeInState method of this previously instantiated
  ChartTimeInStateCalculator class to identify how many "ticks" of the timeline specified by the iterator you used
  to instantiate this class.
  
  Usage:
  
      charttime = require('../')
      {ChartTimeRange, ChartTime, ChartTimeIterator, ChartTimeInStateCalculator} = charttime

      snapshots = [ 
        { id: 1, from: '2011-01-06T15:10:00.000Z', to: '2011-01-06T15:30:00.000Z' }, # 20 minutes all within an hour
        { id: 2, from: '2011-01-06T15:50:00.000Z', to: '2011-01-06T16:10:00.000Z' }, # 20 minutes spanning an hour
        { id: 3, from: '2011-01-07T13:00:00.000Z', to: '2011-01-07T15:20:00.000Z' }, # start 2 hours before but overlap by 20 minutes of start
        { id: 4, from: '2011-01-06T16:40:00.000Z', to: '2011-01-06T19:00:00.000Z' }, # 20 minutes before end of day
        { id: 5, from: '2011-01-06T16:50:00.000Z', to: '2011-01-07T15:10:00.000Z' }, # 10 minutes before end of one day and 10 before the start of next
        { id: 6, from: '2011-01-06T16:55:00.000Z', to: '2011-01-07T15:05:00.000Z' }, # multiple cycles over several days for a total of 20 minutes of work time
        { id: 6, from: '2011-01-07T16:55:00.000Z', to: '2011-01-10T15:05:00.000Z' }, 
        { id: 7, from: '2011-01-06T16:40:00.000Z', to: '2011-01-20T19:00:00.000Z' }  # false beyond scope of iterator
      ]
      
      granularity = 'minute'
      timezone = 'America/Chicago'
      
      rangeSpec = 
        granularity: granularity
        start: new ChartTime(snapshots[0].from, granularity, timezone).decrement()
        pastEnd: '2011-01-11T00:00:00.000'
        startWorkTime: {hour: 9, minute: 0}  # 15:00 in Chicago
        pastEndWorkTime: {hour: 11, minute: 0}  # 17:00 in Chicago.
      
      r1 = new ChartTimeRange(rangeSpec)
      i1 = r1.getIterator('ChartTime')
      isc1 = i1.getChartTimeInStateCalculator(timezone)
      timeInState = isc1.timeInState(snapshots, 'from', 'to', 'id')
      console.log(timeInState)

      # [ { ticks: 20,
      #     finalState: false,
      #     finalEventAt: '2011-01-06T15:30:00.000Z',
      #     finalTickAt: '2011-01-06T15:29:00.000Z',
      #     id: '1' },
      #   { ticks: 20,
      #     finalState: false,
      #     finalEventAt: '2011-01-06T16:10:00.000Z',
      #     finalTickAt: '2011-01-06T16:09:00.000Z',
      #     id: '2' },
      #   { ticks: 20,
      #     finalState: false,
      #     finalEventAt: '2011-01-07T15:20:00.000Z',
      #     finalTickAt: '2011-01-07T15:19:00.000Z',
      #     id: '3' },
      #   { ticks: 20,
      #     finalState: false,
      #     finalEventAt: '2011-01-06T19:00:00.000Z',
      #     finalTickAt: '2011-01-06T16:59:00.000Z',
      #     id: '4' },
      #   { ticks: 20,
      #     finalState: false,
      #     finalEventAt: '2011-01-07T15:10:00.000Z',
      #     finalTickAt: '2011-01-07T15:09:00.000Z',
      #     id: '5' },
      #   { ticks: 20,
      #     finalState: false,
      #     finalEventAt: '2011-01-10T15:05:00.000Z',
      #     finalTickAt: '2011-01-10T15:04:00.000Z',
      #     id: '6' } ]

      
  The default supresses the ones that are still open at the end, but we can override that
  
      snapshots = [snapshots[7]]
      console.log(isc1.timeInState(snapshots, 'from', 'to', 'id', false))
      
      # [ { ticks: 260,
      #     finalState: true,
      #     finalEventAt: '2011-01-06T16:40:00.000Z',
      #     finalTickAt: '2011-01-10T16:59:00.000Z',
      #     id: '7' } ]
      
      
  We can adjust the granularity

      rangeSpec.granularity = 'hour'
      isc2 = new ChartTimeRange(rangeSpec).getIterator().getChartTimeInStateCalculator(timezone)
      timeInState = isc2.timeInState(snapshots, 'from', 'to', 'id', false)
      console.log(timeInState)
      
      # [ { ticks: 4,
      #     finalState: true,
      #     finalEventAt: '2011-01-06T16:40:00.000Z',
      #     finalTickAt: '2011-01-10T16:00:00.000Z',
      #     id: '7' } ]
  ###

  constructor: (@iterator, tz) ->
    ###
    @constructor
    @param {ChartTimeIterator} iterator You must pass in a ChartTimeIterator in the correct granularity and wide enough to cover any snapshots that you will analyze with this ChartTimeInStateCalculator
    @param {String} tz The timezone for analysis
    ###
    @granularity = @iterator.ctr.granularity
    # !TODO: If this approach of walking through each tick turns out to be slow, then refactor algorithm
    # if @granularity in ['minute', 'second', 'millisecond']
      # console.error('Warning: time-in-state calculations at granularities finer than hour can take a long time.')
    if tz?
      @tz = tz
    else
      @tz = @iterator.tz
    utils.assert(@tz?, 'Must specify a timezone `tz` if none specified by the iterator.')
    @iterator.emit = 'ChartTime'
    utils.assert(@tz, 'Must provide a timezone to the ChartTimeIterator used for in-state calculation')
    allCTs = @iterator.getAll()
    if @iterator.skip < 0
      allCTs.reverse()
    @ticks = []
    previousState = false
    allCTsLength = allCTs.length
    for ct, idx in allCTs
      ctPlus1 = ct.add(1)
      if previousState
        previousState = true
        @ticks.push({at: ct.getShiftedISOString(@tz), state: true})
        if idx + 1 == allCTsLength
          previousState = false
          @ticks.push({at: ctPlus1.getShiftedISOString(@tz), state: false})
        else
          unless ctPlus1.$eq(allCTs[idx + 1])
            previousState = false
            @ticks.push({at: ctPlus1.getShiftedISOString(@tz), state: false})
      else
        @ticks.push({at: ct.getShiftedISOString(@tz), state: true})
        previousState = true

  timeInState: (snapshotArray, validFromField, validToField, uniqueIDField, excludeStillInState = true) ->
    ###
    @method timeInState
    @param {Object[]} snapshotArray
    @param {String} validFromField What field in the snapshotArray indicates when the snapshot starts (inclusive)?
    @param {String} validToField What field in the snapshotArray indicates when the snapshot ends (exclusive)?
    @param {String} uniqueIDField What field in the snapshotArray holds the uniqueID
    @param {Boolean} [excludeStillInState] If false, even ids that are still active on the last tick are included

    @return {Object[]} An entry for each uniqueID.

    The fields in each row in the returned Array include:

    * ticks: The number of ticks of the iterator that intersect with the snapshots
    * finalState: true if the last snapshot for this uniqueID had not yet ended by the moment of the last tick
    * finalEventAt: the validFrom value for the final event
    * finalTickAt: the last tick that intersected with this uniqueID
    * |uniqueIDField|: The uniqueID value

    Assumptions about the snapshotArray that's passed in:
    
    * The snapshotArray includes all snapshots where the logical state you want
      to measure the "time in" is true. So, send the predicate you want to be true as part of the query to the snapshot service.
    * The `validFromField` and `validToField` in the `snapshotArray` contain strings in ISO-8601 canonical
      Zulu format (eg `'2011-01-01T12:34:56.789Z'`).
    ###
    
    # it's an error if the first snapshot array entry is before the first entry in the ticks stream.
    utils.assert(snapshotArray[0][validFromField] >= @ticks[0].at, """
      The iterator used must go back at least as far as the first entry in the snapshotArray.
      First entry:
        #{snapshotArray[0][validFromField]}
      Iterator start:
        #{@ticks[0].at}
    """)
    
    # expand the snapshotArray to `state: true` and `state: false` entries
    lastTickAt = @ticks[@ticks.length - 1].at
    snapshotEvents = []
    for s in snapshotArray
      eventRow = {at: s[validFromField], state: true}
      eventRow[uniqueIDField] = s[uniqueIDField]
      eventRow.type = 1
      snapshotEvents.push(eventRow)
      if s[validToField] < lastTickAt
        eventRow = {at: s[validToField], state: false}
        eventRow[uniqueIDField] = s[uniqueIDField]
        eventRow.type = 0
        snapshotEvents.push(eventRow)
        
    # sort the snapshotEvents array by the at field
    snapshotEvents.sort((a, b) ->
      if a.at > b.at
        return 1
      else if a.at == b.at
        if a.type > b.type
          return 1
        else if a.type == b.type
          return 0
        else
          return -1
      else
        return -1
    )
    
    # initialize output
    output = {}

    # initialize tick pointer
    tickLength = @ticks.length
    tickIndex = 0
    currentTick = @ticks[tickIndex]
    # initialize snapshot event pointer
    snapshotLength = snapshotEvents.length
    snapshotIndex = 0
    currentSnapshotEvent = snapshotEvents[snapshotIndex]
    
    # find the first tick right before the first snapshot event
    while currentTick.at < currentSnapshotEvent.at
      tickIndex++
      currentTick = @ticks[tickIndex]   
    tickIndex--
    currentTick = @ticks[tickIndex]
    currentTickState = currentTick.state
    
    # now we are ready to start counting
    while snapshotIndex < snapshotLength and tickIndex < tickLength
      if currentTick.at < currentSnapshotEvent.at
        if currentTickState
          for uniqueID, outputRow of output
            if outputRow.finalState
              outputRow.ticks++
              outputRow.finalTickAt = currentTick.at
        tickIndex++
        if tickIndex < tickLength 
          currentTick = @ticks[tickIndex]
          currentTickState = currentTick.state
      else
        unless output[currentSnapshotEvent[uniqueIDField]]?
          output[currentSnapshotEvent[uniqueIDField]] = {ticks: 0}
        output[currentSnapshotEvent[uniqueIDField]].finalState = currentSnapshotEvent.state
        output[currentSnapshotEvent[uniqueIDField]].finalEventAt = currentSnapshotEvent.at
        snapshotIndex++
        currentSnapshotEvent = snapshotEvents[snapshotIndex]
        
    # cleanup
    if excludeStillInState
      toDelete = []
      for uniqueID, outputRow of output
        if outputRow.finalState
          toDelete.push(uniqueID)
      for d in toDelete
        delete output[d]
    else
      # we've depleted all of the entries in the snapshot event array 
      # but we must deplete the entries in the ticks array for those uniqueIDs that are still "in-state"
      while tickIndex < tickLength
        if currentTickState
          for uniqueID, outputRow of output
            if outputRow.finalState
              outputRow.ticks++
              outputRow.finalTickAt = currentTick.at
        tickIndex++
        if tickIndex < tickLength 
          currentTick = @ticks[tickIndex]
          currentTickState = currentTick.state        
         
    # Squash the uniqueIDField into each row       
    finalOutput = []
    for uniqueID, row of output
      row[uniqueIDField] = uniqueID
      finalOutput.push(row)

    return finalOutput  
    

exports.ChartTimeInStateCalculator = ChartTimeInStateCalculator
