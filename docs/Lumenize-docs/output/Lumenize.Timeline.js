Ext.data.JsonP.Lumenize_Timeline({"tagname":"class","name":"Lumenize.Timeline","extends":null,"mixins":[],"alternateClassNames":[],"aliases":{},"singleton":false,"requires":[],"uses":[],"enum":null,"override":null,"inheritable":null,"inheritdoc":null,"meta":{},"private":null,"id":"class-Lumenize.Timeline","members":{"cfg":[],"property":[],"method":[{"name":"constructor","tagname":"method","owner":"Lumenize.Timeline","meta":{},"id":"method-constructor"},{"name":"contains","tagname":"method","owner":"Lumenize.Timeline","meta":{},"id":"method-contains"},{"name":"getAll","tagname":"method","owner":"Lumenize.Timeline","meta":{},"id":"method-getAll"},{"name":"getAllRaw","tagname":"method","owner":"Lumenize.Timeline","meta":{},"id":"method-getAllRaw"},{"name":"getIterator","tagname":"method","owner":"Lumenize.Timeline","meta":{},"id":"method-getIterator"}],"event":[],"css_var":[],"css_mixin":[]},"linenr":9,"files":[{"filename":"Timeline.coffee.js","href":"Timeline.coffee.html#Lumenize-Timeline"}],"html_meta":{},"statics":{"cfg":[],"property":[],"method":[],"event":[],"css_var":[],"css_mixin":[]},"component":false,"superclasses":[],"subclasses":[],"mixedInto":[],"parentMixins":[],"html":"<div><pre class=\"hierarchy\"><h4>Files</h4><div class='dependency'><a href='source/Timeline.coffee.html#Lumenize-Timeline' target='_blank'>Timeline.coffee.js</a></div></pre><div class='doc-contents'><p>Allows you to specify a timeline with weekend, holiday and non-work hours knocked out and timezone precision.</p>\n\n<h2>Usage</h2>\n\n<p>Let's create a Timeline</p>\n\n<pre><code>{TimelineIterator, Timeline, Time} = require('../')\n\ntl = new Timeline({\n  startOn: '2011-01-02',\n  endBefore: '2011-01-07',\n  holidays: [\n    {month: 1, day: 1},  # Notice the lack of a year specification\n    '2011-01-02'  # Got January 2 off also in 2011. Allows ISO strings.\n  ]\n})\n</code></pre>\n\n<p><code>workDays</code> is already defaulted but you could have overridden it.</p>\n\n<pre><code>console.log(tl.workDays)\n# [ 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday' ]\n</code></pre>\n\n<p>Now let's get an TimelineIterator over this Timeline.</p>\n\n<pre><code>tli = tl.getIterator('Time')\n\nwhile tli.hasNext()\n  console.log(tli.next().toString())\n\n# 2011-01-03\n# 2011-01-04\n# 2011-01-05\n# 2011-01-06\n</code></pre>\n\n<p>Notice how 2011-01-02 was skipped because it was a holiday. Also notice how the endBefore is not included.\nTimelines are inclusive of the startOn and exclusive of the endBefore. This allows the endBefore to be\nthe startOn of the next with no overlap or gap. This focus on precision pervades the design of the Time library.</p>\n\n<p>Now, let's create a Timeline with <code>hour</code> granularity to elaborate on this inclusive/exclusive behavior.</p>\n\n<pre><code>tl2 = new Timeline({\n  startOn: '2011-01-02T00',\n  endBefore: '2011-01-07T00',\n})\n</code></pre>\n\n<p><code>startOn</code> is inclusive.</p>\n\n<pre><code>console.log(tl2.contains('2011-01-02T00'))\n# true\n</code></pre>\n\n<p>But <code>endBefore</code> is exclusive</p>\n\n<pre><code>console.log(tl2.contains('2011-01-07T00'))\n# false\n</code></pre>\n\n<p>But just before <code>endBefore</code> is OK</p>\n\n<pre><code>console.log(tl2.contains('2011-01-06T23'))\n# true\n</code></pre>\n\n<p>All of the above comparisons assume that the <code>startOn</code>/<code>endBefore</code> boundaries are in the same timezone as the contains date.</p>\n\n<h2>Timezone sensitive comparisions</h2>\n\n<p>Now, let's look at how you do timezone sensitive comparisions.</p>\n\n<p>If you pass in a timezone, then it will shift the Timeline boundaries to that timezone to compare to the\ndate/timestamp that you pass in. This system is optimized to the pattern where you first define your boundaries without regard\nto timezone. Christmas day is a holiday in any timezone. Saturday and Sunday are non work days in any timezone. The iteration\nstarts on July 10th; etc. THEN you have a bunch of data that you have stored in a database in GMT. Maybe you've pulled\nit down from an API but the data is represented with a GMT date/timestamp. You then want to decide if the GMT date/timestamp\nis contained within the iteration as defined by a particular timezone, or is a Saturday, or is during workhours, etc.\nThe key concept to remember is that the timebox boundaries are shifted NOT the other way around. It says at what moment\nin time July 10th starts on in a particular timezone and internally represents that in a way that can be compared to a GMT\ndate/timestamp.</p>\n\n<p>So, when it's 3am in GMT on 2011-01-02, it's still 2011-01-01 in New York. Using the above <code>tl2</code> timeline, we say:</p>\n\n<pre><code>console.log(tl2.contains('2011-01-02T03:00:00.000Z', 'America/New_York'))\n# false\n</code></pre>\n\n<p>But it's still 2011-01-06 in New York, when it's 3am in GMT on 2011-01-07</p>\n\n<pre><code>console.log(tl2.contains('2011-01-07T03:00:00.000Z', 'America/New_York'))\n# true\n</code></pre>\n\n<p>Now, let's explore how Timelines and TimelineIterators are used together.</p>\n\n<pre><code>tl3 = new Timeline({\n  startOn:new Time('2011-01-06'),\n  endBefore:new Time('2011-01-11'),\n  workDayStartOn: {hour: 9, minute: 0},\n  workDayEndBefore: {hour: 11, minute: 0}  # Very short work day for demo purposes\n})\n</code></pre>\n\n<p>You can ask for an iterator to emit Timelines rather than Time values. On each call to <code>next()</code>, the\niterator will give you a new Timeline with the <code>startOn</code> value set to what you would have gotten had you\nrequested that it emit Times. The `endBefore' of the emitted Timeline will be set to the following value.\nThis is how you drill-down from one granularity into a lower granularity.</p>\n\n<p>By default, the granularity of the iterator will equal the <code>startOn</code>/<code>endBefore</code> of the original Timeline.\nHowever, you can provide a different granularity (<code>hour</code> in the example below) for the iterator if you want\nto drill-down at a lower granularity.</p>\n\n<pre><code>tli3 = tl3.getIterator('Timeline', undefined, 'hour')\n\nwhile tli3.hasNext()\n  subTimeline = tli3.next()\n  console.log(\"Sub Timeline goes from #{subTimeline.startOn.toString()} to #{subTimeline.endBefore.toString()}\")\n  subIterator = subTimeline.getIterator('Time')\n  while subIterator.hasNext()\n    console.log('    Hour: ' + subIterator.next().hour)\n\n# Sub Timeline goes from 2011-01-06T00 to 2011-01-07T00\n#     Hour: 9\n#     Hour: 10\n# Sub Timeline goes from 2011-01-07T00 to 2011-01-10T00\n#     Hour: 9\n#     Hour: 10\n# Sub Timeline goes from 2011-01-10T00 to 2011-01-11T00\n#     Hour: 9\n#     Hour: 10\n</code></pre>\n\n<p>There is a lot going on here, so let's poke at it a bit. First, notice how the second sub-Timeline goes from the 7th to the\n10th. That's because there was a weekend in there. We didn't get hours for the Saturday and Sunday.</p>\n\n<p>The above approach (<code>tl3</code>/<code>tli3</code>) is useful for some forms of hand generated analysis, but if you are using Time with\nLumenize, it's overkill because Lumenize is smart enough to do rollups based upon the segments that are emitted from the\nlowest granularity Time. So you can just iterate over the lower granularity and Lumenize will automatically manage\nthe drill up/down to day/month/year levels automatically.</p>\n\n<pre><code>tl4 = new Timeline({\n  startOn:'2011-01-06T00',  # Notice how we include the hour now\n  endBefore:'2011-01-11T00',\n  workDayStartOn: {hour: 9, minute: 0},\n  workDayEndBefore: {hour: 11, minute: 0}  # Very short work day for demo purposes\n})\n\ntli4 = tl4.getIterator('ISOString', 'GMT')\n\nwhile tli4.hasNext()\n  console.log(tli4.next())\n\n# 2011-01-06T09:00:00.000Z\n# 2011-01-06T10:00:00.000Z\n# 2011-01-07T09:00:00.000Z\n# 2011-01-07T10:00:00.000Z\n# 2011-01-10T09:00:00.000Z\n# 2011-01-10T10:00:00.000Z\n</code></pre>\n\n<p><code>tl4</code>/<code>tli4</code> covers the same ground as <code>tl3</code>/<code>tli3</code> but without the explicit nesting.</p>\n</div><div class='members'><div class='members-section'><div class='definedBy'>Defined By</div><h3 class='members-title icon-method'>Methods</h3><div class='subsection'><div id='method-constructor' class='member first-child not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.Timeline'>Lumenize.Timeline</span><br/><a href='source/Timeline.coffee.html#Lumenize-Timeline-method-constructor' target='_blank' class='view-source'>view source</a></div><strong class='new-keyword'>new</strong><a href='#!/api/Lumenize.Timeline-method-constructor' class='name expandable'>Lumenize.Timeline</a>( <span class='pre'>config</span> ) : <a href=\"#!/api/Lumenize.Timeline\" rel=\"Lumenize.Timeline\" class=\"docClass\">Lumenize.Timeline</a></div><div class='description'><div class='short'> ...</div><div class='long'>\n<h3 class=\"pa\">Parameters</h3><ul><li><span class='pre'>config</span> : Object<div class='sub-desc'><p>config can have the following properties:</p>\n\n<ul>\n<li><strong>startOn</strong> is a Time object or a string. The first value that next() returns. Must specify 2 out of\n 3 of startOn, endBefore, and limit.</li>\n<li><strong>endBefore</strong> is a Time object or string. Must match granularity. hasNext() returns false when current is here or\n later. Must specify 2 out of 3 of startOn, endBefore, and limit.</li>\n<li><strong>limit</strong> you can specify limit and either startOn or endBefore and only get back this many. Must specify 2 out of\n 3 of startOn, endBefore, and limit.</li>\n<li><strong>step</strong> is an optional parameter. Defaults to 1 or -1. Use -1 to march backwards from endBefore - 1. Currently any\n values other than 1 and -1 may give unexpected behavior. It should be able to step by more but there are not\n good tests around it now.</li>\n<li><p><strong>granularity</strong> is used to determine the granularity that you will iterate over. Note, this is independent of the\n granularity you have used to specify startOn and endBefore. For example:</p>\n\n<pre><code> {startOn: '2012-01', # Month Granularity\n  endBefore: '2012-02', # Month Granularity\n  granularity: Time.DAY} # Day granularity}\n</code></pre></li>\n<li><p><strong>workDays</strong> list of days of the week that you work on. You can specify this as an Array of Strings\n (['Monday', 'Tuesday', ...]) or a single comma seperated String (\"Monday,Tuesday,...\").\n Defaults to ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'].</p></li>\n<li><p><strong>holidays</strong> is an optional Array of either ISOStrings or JavaScript Objects (and you can mix and match). Example:</p>\n\n<pre><code>[{month: 12, day: 25}, {year: 2011, month: 11, day: 24}, \"2012-12-24\"]\n</code></pre>\n\n<p> Notice how you can leave off the year if the holiday falls on the same day every year.</p></li>\n<li><strong>workDayStartOn</strong> is an optional object in the form {hour: 8, minute: 15}. If minute is zero it can be omitted.\n If workDayStartOn is later than workDayEndBefore, then it assumes that you work the night shift and your work\n hours span midnight.</li>\n<li><strong>workDayEndBefore</strong> is an optional object in the form {hour: 17, minute: 0}. If minute is zero it can be omitted.\n The use of workDayStartOn and workDayEndBefore only make sense when the granularity is \"hour\" or finer.\n Note: If the business closes at 5:00pm, you'll want to leave workDayEndBefore to 17:00, rather\n than 17:01. Think about it, you'll be open 4:59:59.999pm, but you'll be closed at 5:00pm. This also makes all of\n the math work. 9am to 5pm means 17 - 9 = an 8 hour work day.</li>\n</ul>\n\n</div></li></ul><h3 class='pa'>Returns</h3><ul><li><span class='pre'><a href=\"#!/api/Lumenize.Timeline\" rel=\"Lumenize.Timeline\" class=\"docClass\">Lumenize.Timeline</a></span><div class='sub-desc'>\n</div></li></ul></div></div></div><div id='method-contains' class='member  not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.Timeline'>Lumenize.Timeline</span><br/><a href='source/Timeline.coffee.html#Lumenize-Timeline-method-contains' target='_blank' class='view-source'>view source</a></div><a href='#!/api/Lumenize.Timeline-method-contains' class='name expandable'>contains</a>( <span class='pre'>date, [tz]</span> ) : Boolean</div><div class='description'><div class='short'> ...</div><div class='long'>\n<h3 class=\"pa\">Parameters</h3><ul><li><span class='pre'>date</span> : Time/Date/String<div class='sub-desc'><p>can be either a JavaScript date object or an ISO-8601 formatted string</p>\n</div></li><li><span class='pre'>tz</span> : String (optional)<div class='sub-desc'>\n</div></li></ul><h3 class='pa'>Returns</h3><ul><li><span class='pre'>Boolean</span><div class='sub-desc'><p>true if the date provided is within this Timeline.</p>\n\n<h2>Usage:</h2>\n\n<p>We can create a Timeline from May to just before July.</p>\n\n<pre><code>tl = new Timeline({\n  startOn: '2011-05',\n  endBefore: '2011-07'\n})\n\nconsole.log(tl.contains('2011-06-15T12:00:00.000Z', 'America/New_York'))\n# true\n</code></pre>\n</div></li></ul></div></div></div><div id='method-getAll' class='member  not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.Timeline'>Lumenize.Timeline</span><br/><a href='source/Timeline.coffee.html#Lumenize-Timeline-method-getAll' target='_blank' class='view-source'>view source</a></div><a href='#!/api/Lumenize.Timeline-method-getAll' class='name expandable'>getAll</a>( <span class='pre'>[emit], [tz], [childGranularity]</span> ) : Time[]/Date[]/Timeline[]/String[]</div><div class='description'><div class='short'> ...</div><div class='long'>\n<h3 class=\"pa\">Parameters</h3><ul><li><span class='pre'>emit</span> : String (optional)<div class='sub-desc'><p>An optional String that specifies what should be emitted. Possible values are 'Time' (default),\n   'Timeline', 'Date' (javascript Date Object), and 'ISOString'.</p>\n</div></li><li><span class='pre'>tz</span> : String (optional)<div class='sub-desc'><p>A Sting specifying the timezone in the standard form,<code>America/New_York</code> for example. This is\n   required if <code>emit</code> is 'Date' or 'ISOString'.</p>\n</div></li><li><span class='pre'>childGranularity</span> : String (optional)<div class='sub-desc'><p>When emit is 'Timeline', this is the granularity for the startOn and endBefore of the\n   Timeline that is emitted.</p>\n</div></li></ul><h3 class='pa'>Returns</h3><ul><li><span class='pre'>Time[]/Date[]/Timeline[]/String[]</span><div class='sub-desc'><p>Returns all of the points in the timeline in chronological order. If you want them in the order specified by <code>step</code>\nthen use getAllRaw().</p>\n</div></li></ul></div></div></div><div id='method-getAllRaw' class='member  not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.Timeline'>Lumenize.Timeline</span><br/><a href='source/Timeline.coffee.html#Lumenize-Timeline-method-getAllRaw' target='_blank' class='view-source'>view source</a></div><a href='#!/api/Lumenize.Timeline-method-getAllRaw' class='name expandable'>getAllRaw</a>( <span class='pre'>[emit], [tz], [childGranularity]</span> ) : Time[]/Date[]/Timeline[]/String[]</div><div class='description'><div class='short'> ...</div><div class='long'>\n<h3 class=\"pa\">Parameters</h3><ul><li><span class='pre'>emit</span> : String (optional)<div class='sub-desc'><p>An optional String that specifies what should be emitted. Possible values are 'Time' (default),\n   'Timeline', 'Date' (javascript Date Object), and 'ISOString'.</p>\n</div></li><li><span class='pre'>tz</span> : String (optional)<div class='sub-desc'><p>A Sting specifying the timezone in the standard form,<code>America/New_York</code> for example. This is\n   required if <code>emit</code> is 'Date' or 'ISOString'.</p>\n</div></li><li><span class='pre'>childGranularity</span> : String (optional)<div class='sub-desc'><p>When emit is 'Timeline', this is the granularity for the startOn and endBefore of the\n   Timeline that is emitted.</p>\n</div></li></ul><h3 class='pa'>Returns</h3><ul><li><span class='pre'>Time[]/Date[]/Timeline[]/String[]</span><div class='sub-desc'><p>Returns all of the points in the timeline. Note, this will come back in the order specified\nby step so they could be out of chronological order. Use getAll() if they must be in chronological order.</p>\n</div></li></ul></div></div></div><div id='method-getIterator' class='member  not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.Timeline'>Lumenize.Timeline</span><br/><a href='source/Timeline.coffee.html#Lumenize-Timeline-method-getIterator' target='_blank' class='view-source'>view source</a></div><a href='#!/api/Lumenize.Timeline-method-getIterator' class='name expandable'>getIterator</a>( <span class='pre'>[emit], [tz], [childGranularity]</span> ) : TimelineIterator</div><div class='description'><div class='short'> ...</div><div class='long'>\n<h3 class=\"pa\">Parameters</h3><ul><li><span class='pre'>emit</span> : String (optional)<div class='sub-desc'><p>An optional String that specifies what should be emitted. Possible values are 'Time' (default),\n   'Timeline', 'Date' (javascript Date Object), and 'ISOString'.</p>\n</div></li><li><span class='pre'>tz</span> : String (optional)<div class='sub-desc'><p>A Sting specifying the timezone in the standard form,<code>America/New_York</code> for example. This is\n   required if <code>emit</code> is 'Date' or 'ISOString'.</p>\n</div></li><li><span class='pre'>childGranularity</span> : String (optional)<div class='sub-desc'><p>When emit is 'Timeline', this is the granularity for the startOn and endBefore of the\n   Timeline that is emitted.</p>\n</div></li></ul><h3 class='pa'>Returns</h3><ul><li><span class='pre'>TimelineIterator</span><div class='sub-desc'><p>Returns a new TimelineIterator using this Timeline as the boundaries.</p>\n</div></li></ul></div></div></div></div></div></div></div>"});