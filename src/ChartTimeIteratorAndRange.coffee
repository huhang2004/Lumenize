ChartTime = require('./ChartTime').ChartTime
ChartTimeInStateCalculator = require('./ChartTimeInStateCalculator').ChartTimeInStateCalculator
timezoneJS = require('./timezone-js.js').timezoneJS
utils = require('./utils')

class ChartTimeIterator
  ###
  @class ChartTimeIterator

  # ChartTimeIterator #
  
  Iterate through days, months, years, etc. skipping weekends and holidays that you 
  specify. It will also iterate over hours, minutes, seconds, etc. and skip times that are not
  between the specified work hours.
  
  ## Usage ##
  
      {ChartTimeIterator, ChartTimeRange, ChartTime} = require('../')
      
      cti = new ChartTimeIterator({
        startOn:new ChartTime({granularity: 'day', year: 2009, month:1, day: 1}),
        endBefore:new ChartTime({granularity: 'day', year: 2009, month:1, day: 8}),
        workDays: 'Monday, Tuesday, Wednesday, Thursday, Friday',
        holidays: [
          {month: 1, day: 1},  # New Years day was a Thursday in 2009
          {year: 2009, month: 1, day: 2}  # Also got Friday off in 2009
        ]
      })
  
      while (cti.hasNext())
        console.log(cti.next().toString())
  
      # 2009-01-05
      # 2009-01-06
      # 2009-01-07
  ###
  constructor: (ctr, @emit = 'ChartTime', @childGranularity = 'day', tz) ->
    ###
    @constructor
    @param {ChartTimeRange} ctr A ChartTimeRange or a raw Object with all the necessary properties to be a spec for a new ChartTimeRange.
       Using a ChartTimeRange is now the preferred method. The raw Object is supported for backward compatibility.
    @param {String} [emit] An optional String that specifies what should be emitted. Possible values are 'ChartTime' (default),
       'ChartTimeRange', and 'Date' (javascript Date Object). Note, to maintain backward compatibility with the time
       before ChartTimeRange existed, the default for emit when instantiating a new ChartTimeIterator directly is 
       'ChartTime'. However, if you request a new ChartTimeIterator from a ChartTimeRange object using getIterator(),
       the default is 'ChartTimeRange'.
    @param {String} [childGranularity] When emit is 'ChartTimeRange', this is the granularity for the startOn and endBefore of the
       ChartTimeRange that is emitted.
    @param {String} [tz] A Sting specifying the timezone in the standard form,`America/New_York` for example.
    ###
    utils.assert(@emit in ['ChartTime', 'ChartTimeRange', 'Date'], "emit must be 'ChartTime', 'ChartTimeRange', or 'Date'. You provided #{@emit}.")
    utils.assert(@emit != 'Date' or tz?, 'Must provide a tz (timezone) parameter when emitting Dates.')
    # if ctr.granularity in ['Minute','Second', 'Millisecond']
      # console.error("Warning: iterating at granularity #{ctr.granularity} can be very slow.")
    @tz ?= tz  # !TODO: Need to test tz and emitting Dates
    if ctr instanceof ChartTimeRange
      @ctr = ctr
    else
      @ctr = new ChartTimeRange(ctr)
    @startOver()

  StopIteration = if typeof(StopIteration) == 'undefined' then utils.StopIteration else StopIteration

  startOver: () ->
    ###
    @method startOver

    Will go back to the where the iterator started.
    ###
    if @ctr.skip > 0
      @current = new ChartTime(@ctr.startOn)
    else
      @current = new ChartTime(@ctr.endBefore)
      @current.decrement()
    @count = 0
    @_proceedToNextValid()

  hasNext: () ->
    ###
    @method hasNext
    @return {Boolean} Returns true if there are still things left to iterator over. Note that if there are holidays,
       weekends or non-workhours to skip, then hasNext() will take that into account. For example if the endBefore is a
       Sunday, hasNext() will return true the next time it is called after the Friday is emitted.
    ###
    return @ctr.contains(@current) and (@count < @ctr.limit)

  _shouldBeExcluded: () ->
    if @current._isGranularityCoarserThanDay()
      return false
      
    # Do everything below for granularies day and lower
    currentInDay = @current.inGranularity('day')
    unless @current.dowString() in @ctr.workDays
      return true
    for holiday in @ctr.holidays
      if (utils.match(holiday, currentInDay))
        return true            
    if @ctr.granularity in ['hour', 'minute',' second', 'millisecond']
      currentMinutes = @current.hour * 60
      if @current.minute?
        currentMinutes += @current.minute
      if @ctr.startOnWorkMinutes <= @ctr.endBeforeWorkMinutes
        if (currentMinutes < @ctr.startOnWorkMinutes) or (currentMinutes >= @ctr.endBeforeWorkMinutes)
          return true
      else
        if @ctr.startOnWorkMinutes >= currentMinutes > @ctr.endBeforeWorkMinutes
          return true
    return false

  _proceedToNextValid: () ->
    while @hasNext() and @_shouldBeExcluded()
      if @ctr.skip > 0
        @current.increment()
      else
        @current.decrement()

  next: () ->
    ###
    @method next
    @return {ChartTime/Date/ChartTimeRange} Emits the next value of the iterator. The start will be the first value emitted unless it should
       be skipped due to holiday, weekend, or workhour knockouts.
    ###
    if !@hasNext()
      throw new StopIteration('Cannot call next() past end.')
    currentCopy = new ChartTime(@current)
    @count++
    for i in [Math.abs(@ctr.skip)..1]
      if @ctr.skip > 0
        @current.increment()
      else
        @current.decrement()
      @_proceedToNextValid()
    switch @emit
      when 'ChartTime'
        return currentCopy
      when 'Date'
        return currentCopy.getJSDate(@tz)
      when 'ChartTimeRange'
        spec = {
          startOn: currentCopy.inGranularity(@childGranularity),
          endBefore: @current.inGranularity(@childGranularity),
          workDays: @ctr.workDays,
          holidays: @ctr.holidays,
          workDayStartOn: @ctr.workDayStartOn,
          workDayEndBefore: @ctr.workDayEndBefore
        }
        childCTR = new ChartTimeRange(spec)
        return childCTR
      else 

  getAll: () ->
    ###
    @method getAll
    @return {ChartTime[]/Date[]/ChartTimeRange[]}
    Returns all values as an array.
    ###
    @startOver()
    temp = []
    while @hasNext()
      temp.push(@next())
    return temp
    
  getChartTimeInStateCalculator: (tz) ->
    ctrisc = new ChartTimeInStateCalculator(this, tz)
    return ctrisc
    
class ChartTimeRange
  ###
  @class ChartTimeRange

  # ChartTimeRange #
  
  Allows you to specify a range for iterating over or identifying if it `contains()` some other date.
  This `contains()` comparision can be done in a timezone sensitive way.
  
  ## Usage ##
 
  Let's create the `spec` for our ChartTimeRange
  
      {ChartTimeIterator, ChartTimeRange, ChartTime} = require('../')
      
      r = new ChartTimeRange({
        startOn:new ChartTime('2011-01-02'),
        endBefore:new ChartTime('2011-01-07'),
        holidays: [
          {month: 1, day: 1},  # Notice the lack of a year specification
          {year: 2011, month: 1, day: 2}  # Got January 2 off also in 2011
        ]
      })
      
  `workDays` is already defaulted but you could have overridden it.
  
      console.log(r.workDays)
      # [ 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday' ]
      
  Now let's get an iterator over this range.
      
      i = r.getIterator('ChartTime')
      
      while i.hasNext()
        console.log(i.next().toString()) 
             
      # 2011-01-03
      # 2011-01-04
      # 2011-01-05
      # 2011-01-06
  
  Notice how 2011-01-02 was skipped because it was a holiday. Also notice how the endBefore is not included.
  Ranges are inclusive of the startOn and exclusive of the endBefore. This allows the endBefore of one to be
  the startOn of the next with no overlap or gap. This focus on precision pervades the design of the ChartTime library.
  
  Now, let's create a ChartTimeRange with `hour` granularity to elaborate on this inclusive/exclusive behavior.
      
      r2 = new ChartTimeRange({
        startOn:new ChartTime('2011-01-02T00'),
        endBefore:new ChartTime('2011-01-07T00'),
      })
      
  `startOn` is inclusive.
  
      console.log(r2.contains(new ChartTime('2011-01-02T00')))
      # true
      
  But `endBefore` is exclusive
  
      console.log(r2.contains(new ChartTime('2011-01-07T00')))
      # false
  
  But just before `endBefore` is OK
  
      console.log(r2.contains('2011-01-06T23'))
      # true
      
  In the above line, notice how we omitted the `new ChartTime(...)`. If you pass in a string without a timezone, 
  it will automatically create the ChartTime to do the comparison.
  
  All of the above comparisons assume that the `startOn`/`endBefore` boundaries are in the same timezone as the contains date.
  
  ## Timezone sensitive comparisions ##
  
  Now, let's look at how you do timezone sensitive comparisions.
  
  If you pass in a timezone, then it will shift the CharTimeRange boundaries to that timezone to compare to the 
  date/timestamp that you pass in. This system is optimized to the pattern where you first define your boundaries without regard 
  to timezone. Christmas day is a holiday in any timezone. Saturday and Sunday are non work days in any timezone. The iteration
  starts on July 10th; etc. THEN you have a bunch of data that you have stored in a database in GMT. Maybe you've pulled
  it down from an API but the data is represented with a GMT date/timestamp. You then want to decide if the GMT date/timestamp 
  is contained within the iteration as defined by a particular timezone, or is a Saturday, or is during workhours, etc. 
  The key concept to remember is that the timebox boundaries are shifted NOT the other way around. It says at what moment
  in time July 10th starts on in a particular timezone and internally represents that in a way that can be compared to a GMT
  date/timestamp.
  
  So, when it's 3am in GMT on 2011-01-02, it's still 2011-01-01 in New York. Using the above `r2` range, we say:
  
      console.log(r2.contains('2011-01-02T03:00:00.000Z', 'America/New_York'))
      # false
      
  But it's still 2011-01-06 in New York, when it's 3am in GMT on 2011-01-07
      
      console.log(r2.contains('2011-01-07T03:00:00.000Z', 'America/New_York'))
      # true
      
  Now, let's explore how ChartTimeRanges and ChartTimeIterators are used together. Here is a range spec.

      r3 = new ChartTimeRange({
        startOn:new ChartTime('2011-01-06'),
        endBefore:new ChartTime('2011-01-11'),
        workDayStartOn: {hour: 9, minute: 0},
        workDayEndBefore: {hour: 11, minute: 0}  # Very short work day for demo purposes
      })
          
  You can ask for an iterator to emit ChartTimeRanges rather than ChartTime values. On each call to `next()`, the
  iterator will give you a new ChartTimeRange with the `startOn` value set to what you would have gotten had you
  requested that it emit ChartTimes. The `endBefore' of the emitted ChartTimeRange will be set to the following value.
  This is how you drill-down from one granularity into a lower granularity.
  
  By default, the granularity of the iterator will equal the `startOn`/`endBefore` of the original ChartTimeRange.
  However, you can provide a different granularity (`hour` in the example below) for the iterator if you want 
  to drill-down at a lower granularity.
  
      i3 = r3.getIterator('ChartTimeRange', 'hour')
      
      while i3.hasNext()
        subRange = i3.next()
        console.log("Sub range goes from #{subRange.startOn.toString()} to #{subRange.endBefore.toString()}")
        subIterator = subRange.getIterator('ChartTime')
        while subIterator.hasNext()
          console.log('    Hour: ' + subIterator.next().hour)
          
      # Sub range goes from 2011-01-06T00 to 2011-01-07T00
      #     Hour: 9
      #     Hour: 10
      # Sub range goes from 2011-01-07T00 to 2011-01-10T00
      #     Hour: 9
      #     Hour: 10
      # Sub range goes from 2011-01-10T00 to 2011-01-11T00
      #     Hour: 9
      #     Hour: 10
          
  There is a lot going on here, so let's poke at it a bit. First, notice how the second sub-range goes from the 7th to the
  10th. That's because there was a weekend in there. We didn't get hours for the Saturday and Sunday.
      
  The above approach (`r3`/`i3`) is useful for some forms of hand generated analysis, but if you are using ChartTime with 
  Lumenize, it's overkill because Lumenize is smart enough to do rollups based upon the segments that are emitted from the
  lowest granularity ChartTime. So you can just iterate over the lower granularity and Lumenize will automatically manage 
  the drill up/down to day/month/year levels automatically.
  
      r4 = new ChartTimeRange({
        startOn:'2011-01-06T00',  # Notice how we include the hour now
        endBefore:'2011-01-11T00',
        workDayStartOn: {hour: 9, minute: 0},
        workDayEndBefore: {hour: 11, minute: 0}  # Very short work day for demo purposes
      })
          
  Notice how we are able to simply use strings to represent the startOn/endBefore dates. ChartTimeRange automatically constructs
  ChartTime objects from those strings. We could have done that in the earlier examples. I chose not to do so to illustrate
  how ChartTimes are used under the covers.

      i4 = r4.getIterator('ChartTime')
      
      while i4.hasNext()
        console.log(i4.next().toString())
        
      # 2011-01-06T09
      # 2011-01-06T10
      # 2011-01-07T09
      # 2011-01-07T10
      # 2011-01-10T09
      # 2011-01-10T10
      
  `r4`/`i4` covers the same ground as `r3`/`i3` but without the explicit nesting.

  ###
  
  constructor: (spec) ->
    ###
    @constructor
    @param {Object} spec

    spec can have the following properties:

    * **startOn** is a ChartTime object or a string. The first value that next() returns.
    * **endBefore** is a ChartTime object or string. Must match granularity. hasNext() returns false when current is here or later.
    * **skip** is an optional num. Defaults to 1 or -1. Use -1 to march backwards from endBefore - 1. Currently any
       values other than 1 and -1 give unexpected behavior.
    * **granularity** is used to determine the granularity that you will iterate over. Note, you can have granularity of say month 
       for the startOn and/or endBefore but have a finer granularity for the range. Let's say you want to iterate over all the days
       of the current month. In this case, endBefore would be 'next month', and startOn would be 'prior month'.
    * **limit** you can specify limit plus one of startOn/endBefore and only get back this many.
    * **workDays** list of days of the week that you work on. Either ['Monday', 'Tuesday', ...] or "Monday,Tuesday,..."
       Defaults to ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'].
    * **holidays** is an optional Array like: [{month: 12, day: 25}, {year: 2011, month: 11, day: 24}]. Notice how
       you can leave off the year if the holiday falls on the same day every year.
    * **workDayStartOn** is an optional object in the form {hour: 8, minute: 15}. Must include minute even when 0.
       If workDayStartOn is later than workDayEndBefore, then it assumes that you work the night shift and your work
       hours span midnight.
    * **workDayEndBefore** is an optional object in the form {hour: 17, minute: 0}. Must include minute even when 0.
       The use of workDayStartOn and workDayEndBefore only make sense when the granularity is "hour" or finer.
       Note: If the business closes at 5:00pm, you'll want to leave workDayEndBefore to 17:00, rather
       than 17:01. Think about it, you'll be open 4:59:59.999pm, but you'll be closed at 5:00pm. This also makes all of
       the math work. 9am to 5pm means 17 - 9 = an 8 hour work day.
    ###
    if spec.endBefore? 
      @endBefore = spec.endBefore
      if @endBefore != 'PAST_LAST'
        if utils.type(@endBefore) == 'string'
          @endBefore = new ChartTime(@endBefore)
        @granularity = @endBefore.granularity
    if spec.startOn?
      @startOn = spec.startOn
      if @startOn != 'BEFORE_FIRST'
        if utils.type(@startOn) == 'string'
          @startOn = new ChartTime(@startOn)
        @granularity = @startOn.granularity
    if spec.granularity?
      @granularity = spec.granularity
      if @startOn?
        @startOn = @startOn.inGranularity(@granularity)
      if @endBefore?
        @endBefore = @endBefore.inGranularity(@granularity)
    unless @granularity
      throw new Error('Cannot determine granularity for ChartTimeRange.')  
    if @startOn == 'BEFORE_FIRST'
      @startOn = new ChartTime(@startOn, @granularity)
    if @endBefore == 'PAST_LAST'
      @endBefore == new ChartTime(@endBefore, @granularity)
    if !@endBefore
      @endBefore = new ChartTime('PAST_LAST', @granularity)
    if !@startOn
      @startOn = new ChartTime('BEFORE_FIRST', @granularity)

    @limit = if spec.limit? then spec.limit else utils.MAX_INT
    
    if spec.workDays?
      @workDays = spec.workDays
    else if spec.workdays?
      @workDays = spec.workdays
    else
      @workDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    if utils.type(@workDays) == 'string'
      @workDays = (utils.trim(s) for s in @workDays.split(','))
    @holidays = if spec.holidays? then spec.holidays else []
    for holiday, idx in @holidays
      if utils.type(holiday) == 'string'
        @holidays[idx] = new ChartTime(holiday).getSegmentsAsObject()
    
    @workDayStartOn = if spec.workDayStartOn? then spec.workDayStartOn
    if @workDayStartOn?
      h = if @workDayStartOn.hour? then @workDayStartOn.hour else 0
      m = if @workDayStartOn.minute? then @workDayStartOn.minute else 0
      @startOnWorkMinutes = h * 60 + m
      if @startOnWorkMinutes < 0
        @startOnWorkMinutes = 0
    else
      @startOnWorkMinutes = 0

    @workDayEndBefore = if spec.workDayEndBefore? then spec.workDayEndBefore
    if @workDayEndBefore?
      h = if @workDayEndBefore.hour? then @workDayEndBefore.hour else 24
      m = if @workDayEndBefore.minute? then @workDayEndBefore.minute else 0
      @endBeforeWorkMinutes = h * 60 + m
      if @endBeforeWorkMinutes > 24 * 60
        @endBeforeWorkMinutes = 24 * 60
    else
      @endBeforeWorkMinutes = 24 * 60
    
    if spec.skip?
      @skip = spec.skip
    else if spec.endBefore? and @startOn?.gt(@endBefore)
      @skip = -1
    else if spec.endBefore? and not spec.startOn? and spec.limit?
      @skip = -1
    else
      @skip = 1
    utils.assert(
      (spec.startOn? and spec.endBefore?) or
      (spec.startOn? and spec.limit? and @skip > 0) or
      (spec.endBefore? and spec.limit? and @skip < 0),
      'Must provide two out of "startOn", "endBefore", or "limit" and the sign of skip must match.'
    )
    
  getIterator: (emit = 'ChartTimeRange', childGranularity = 'day', tz) ->
    ###
    @method getIterator
    @param {String} [emit]
    @param {String} [childGranularity]
    @param {String} [tz]
    @return {ChartTimeIterator}

    Returns a new ChartTimeIterator using this ChartTimeRange as the boundaries.
    
    Note, to maintain backward compatibility with the time before ChartTimeRange existed, the default for emit when 
    instantiating a new ChartTimeIterator directly is 'ChartTime'. However, if you request a new ChartTimeIterator 
    from a ChartTimeRange object using getIterator(), the default is 'ChartTimeRange'.
    ###
    return new ChartTimeIterator(this, emit, childGranularity, tz)
    
  # !TODO: getAll() should be smart enough to get the childGranularity from @granularity
  getAll: (emit = 'ChartTimeRange', childGranularity = 'day', tz) ->
    ###
    @method getAll
    @param {String} [emit]
    @param {String} [childGranularity]
    @param {String} [tz]
    @return {ChartTime[]/Date[]/ChartTimeRange[]}

    Returns all of the points in the timeline specified by this ChartTimeRange.
    
    Note, to maintain backward compatibility with the time before ChartTimeRange existed, the default for emit when 
    instantiating a new ChartTimeIterator directly is 'ChartTime'. However, if you request a new ChartTimeIterator 
    from a ChartTimeRange object using getIterator(), the default is 'ChartTimeRange'.
    ###
    return new ChartTimeIterator(this, emit, childGranularity, tz).getAll()
    
  getTimeline: () ->
    ###
    @method getTimeline
    @return {ChartTime[]}

    Returns all of the points in the timeline specified by this ChartTimeRange as ChartTime objects. This method also
    makes sure that the array that is returned is sorted chrologically.
    ###
    timeline = new ChartTimeIterator(this, 'ChartTime', @granularity).getAll()
    if timeline[0].gt(timeline[1])
      timeline.reverse()
    return timeline

  contains: (date, tz) ->
    ###
    @method contains
    @param {ChartTime/Date/String} date can be either a JavaScript date object or an ISO-8601 formatted string
    @param {String} [tz]
    @return {Boolean} true if the date provided is within this ChartTimeRange.

    ## Usage: ##
    
    We can create a range from May to July.
    
        r = new ChartTimeRange({
          startOn: '2011-05',
          endBefore: '2011-07'
        })
        
        console.log(r.contains('2011-06-15T12:00:00.000Z', 'America/New_York'))
        # true
    
    ###
    if date instanceof ChartTime
      return date.lt(@endBefore) and date.gte(@startOn)
    utils.assert(tz? or utils.type(date) != 'date', 'ChartTimeRange.contains() requires a second parameter (timezone) when the first parameter is a Date()')
    switch utils.type(date)
      when 'string'
        if tz?
          target = timezoneJS.parseISO(date)
        else
          target = new ChartTime(date)
          return target.lt(@endBefore) and target.gte(@startOn)
      when 'date'
        target = date.getTime()  # !TODO: A - Need to use my getJSDate to be sure this behaves as expected... or test the hell out of this
      else
        throw new Error('ChartTimeRange.contains() requires that the first parameter be of type ChartTime, String, or Date')
    startOn = @startOn.getJSDate(tz)
    endBefore = @endBefore.getJSDate(tz)
    return target < endBefore and target >= startOn

exports.ChartTimeRange = ChartTimeRange
exports.ChartTimeIterator = ChartTimeIterator
    
