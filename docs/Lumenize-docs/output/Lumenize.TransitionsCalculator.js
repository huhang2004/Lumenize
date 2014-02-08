Ext.data.JsonP.Lumenize_TransitionsCalculator({"tagname":"class","name":"Lumenize.TransitionsCalculator","autodetected":{},"files":[{"filename":"TransitionsCalculator.coffee.js","href":"TransitionsCalculator.coffee.html#Lumenize-TransitionsCalculator"}],"members":[{"name":"asterixToDateTimePeriod","tagname":"cfg","owner":"Lumenize.TransitionsCalculator","id":"cfg-asterixToDateTimePeriod","meta":{}},{"name":"fieldsToSum","tagname":"cfg","owner":"Lumenize.TransitionsCalculator","id":"cfg-fieldsToSum","meta":{}},{"name":"granularity","tagname":"cfg","owner":"Lumenize.TransitionsCalculator","id":"cfg-granularity","meta":{}},{"name":"tz","tagname":"cfg","owner":"Lumenize.TransitionsCalculator","id":"cfg-tz","meta":{}},{"name":"uniqueIDField","tagname":"cfg","owner":"Lumenize.TransitionsCalculator","id":"cfg-uniqueIDField","meta":{}},{"name":"validFromField","tagname":"cfg","owner":"Lumenize.TransitionsCalculator","id":"cfg-validFromField","meta":{}},{"name":"validToField","tagname":"cfg","owner":"Lumenize.TransitionsCalculator","id":"cfg-validToField","meta":{}},{"name":"constructor","tagname":"method","owner":"Lumenize.TransitionsCalculator","id":"method-constructor","meta":{}},{"name":"addSnapshots","tagname":"method","owner":"Lumenize.TransitionsCalculator","id":"method-addSnapshots","meta":{"chainable":true}},{"name":"getResults","tagname":"method","owner":"Lumenize.TransitionsCalculator","id":"method-getResults","meta":{}},{"name":"getStateForSaving","tagname":"method","owner":"Lumenize.TransitionsCalculator","id":"method-getStateForSaving","meta":{}},{"name":"newFromSavedState","tagname":"method","owner":"Lumenize.TransitionsCalculator","id":"static-method-newFromSavedState","meta":{"static":true}}],"alternateClassNames":[],"aliases":{},"id":"class-Lumenize.TransitionsCalculator","short_doc":"Used to accumlate counts and sums about transitions. ...","component":false,"superclasses":[],"subclasses":[],"mixedInto":[],"mixins":[],"parentMixins":[],"requires":[],"uses":[],"html":"<div><pre class=\"hierarchy\"><h4>Files</h4><div class='dependency'><a href='source/TransitionsCalculator.coffee.html#Lumenize-TransitionsCalculator' target='_blank'>TransitionsCalculator.coffee.js</a></div></pre><div class='doc-contents'><p>Used to accumlate counts and sums about transitions.</p>\n\n<p>Let's say that you want to create a throughput or velocity chart where each column on the chart represents the\nnumber of work items that cross over from one state into another state in a given month/week/quarter/etc. You would\nsend a transitions to a temporal data store like Rally's Lookback API specifying both the current values and the\nprevious values. For instance, the work items crossing from \"In Progress\" to \"Completed\" could be found\nwith this query clause <code>\"_PreviousValues.ScheduleState\": {\"$lte\": \"In Progress\"}, \"ScheduleState\": {\"$gt\": \"In Progress\"}</code></p>\n\n<pre><code>{TransitionsCalculator, Time} = require('../')\n\nsnapshots = [\n  { id: 1, from: '2011-01-03T00:00:00.000Z', PlanEstimate: 10 },\n  { id: 1, from: '2011-01-05T00:00:00.000Z', PlanEstimate: 10 },\n  { id: 2, from: '2011-01-04T00:00:00.000Z', PlanEstimate: 20 },\n  { id: 3, from: '2011-01-10T00:00:00.000Z', PlanEstimate: 30 },\n  { id: 4, from: '2011-01-11T00:00:00.000Z', PlanEstimate: 40 },\n  { id: 5, from: '2011-01-17T00:00:00.000Z', PlanEstimate: 50 },\n  { id: 6, from: '2011-02-07T00:00:00.000Z', PlanEstimate: 60 },\n  { id: 7, from: '2011-02-08T00:00:00.000Z', PlanEstimate: 70 },\n]\n</code></pre>\n\n<p>But that's not the entire story. What if something crosses over into \"Completed\" and beyond but crosses back. It could\ndo this several times and get counted multiple times. That would be bad. The way we deal with this is to also\nlook for the list of snapshots that pass backwards across the boundary and subract thier impact on the final calculations.</p>\n\n<p>One can think of alternative aproaches for avoiding this double counting. You could, for instance, only count the last\ntransition for each unique work item. The problem with this approach is that the backward moving transition might\noccur in a different time period from the forward moving one. A later snapshot could invalidate an earlier calculation\nwhich is bad for incremental calculation and caching. To complicate matters, the field values being summed by the\ncalculator might have changed between subsequent forward/backward transitions. The chosen algorithm is the only way I know to\npreserve the idempotency and cachable incremental calculation properties.</p>\n\n<pre><code>snapshotsToSubtract = [\n  { id: 1, from: '2011-01-04T00:00:00.000Z', PlanEstimate: 10 },\n  { id: 7, from: '2011-02-09T00:00:00.000Z', PlanEstimate: 70 },\n]\n</code></pre>\n\n<p>The calculator will keep track of the count of items automatically (think throughput), but if you want to sum up a\nparticular field (think velocity), you can specify that with the 'fieldsToSum' config property.</p>\n\n<pre><code>fieldsToSum = ['PlanEstimate']\n</code></pre>\n\n<p>Now let's build our config object.</p>\n\n<pre><code>config =\n  asOf: '2011-02-10'  # Leave this off if you want it to continuously update to today\n  granularity: Time.MONTH\n  tz: 'America/Chicago'\n  validFromField: 'from'\n  validToField: 'to'\n  uniqueIDField: 'id'\n  fieldsToSum: fieldsToSum\n  asterixToDateTimePeriod: true  # Set to false or leave off if you are going to reformat the timePeriod\n</code></pre>\n\n<p>In most cases, you'll want to leave off the <code>asOf</code> configuration property so the data can be continuously updated\nwith new snapshots as they come in. We include it in this example so the output stays stable. If we hadn't, then\nthe rows would continue to grow to encompass today.</p>\n\n<pre><code>startOn = '2011-01-02T00:00:00.000Z'\nendBefore = '2011-02-27T00:00:00.000Z'\n\ncalculator = new TransitionsCalculator(config)\ncalculator.addSnapshots(snapshots, startOn, endBefore, snapshotsToSubtract)\n\nconsole.log(calculator.getResults())\n# [ { timePeriod: '2011-01', count: 5, PlanEstimate: 150 },\n#   { timePeriod: '2011-02*', count: 1, PlanEstimate: 60 } ]\n</code></pre>\n\n<p>The asterix on the last row in the results is to indicate that it is a to-date value. As more snapshots come in, this\nlast row will change. The caching and incremental calcuation capability of this Calculator are designed to take\nthis into account.</p>\n\n<p>Now, let's use the same data but aggregate in granularity of weeks.</p>\n\n<pre><code>config.granularity = Time.WEEK\ncalculator = new TransitionsCalculator(config)\ncalculator.addSnapshots(snapshots, startOn, endBefore, snapshotsToSubtract)\n\nconsole.log(calculator.getResults())\n# [ { timePeriod: '2010W52', count: 1, PlanEstimate: 10 },\n#   { timePeriod: '2011W01', count: 2, PlanEstimate: 50 },\n#   { timePeriod: '2011W02', count: 2, PlanEstimate: 90 },\n#   { timePeriod: '2011W03', count: 0, PlanEstimate: 0 },\n#   { timePeriod: '2011W04', count: 0, PlanEstimate: 0 },\n#   { timePeriod: '2011W05', count: 1, PlanEstimate: 60 },\n#   { timePeriod: '2011W06*', count: 0, PlanEstimate: 0 } ]\n</code></pre>\n\n<p>Remember, you can easily convert weeks to other granularities for display.</p>\n\n<pre><code>weekStartingLabel = 'week starting ' + new Time('2010W52').inGranularity(Time.DAY).toString()\nconsole.log(weekStartingLabel)\n# week starting 2010-12-27\n</code></pre>\n\n<p>If you want to display spinners while the chart is rendering, you can read this calculator's upToDateISOString property and\ncompare it directly to the getResults() row's timePeriod property using code like this. Yes, this works eventhough\nupToDateISOString is an ISOString.</p>\n\n<pre><code>row = {timePeriod: '2011W07'}\nif calculator.upToDateISOString &lt; row.timePeriod\n  console.log(\"#{row.timePeriod} not yet calculated.\")\n# 2011W07 not yet calculated.\n</code></pre>\n</div><div class='members'><div class='members-section'><div class='definedBy'>Defined By</div><h3 class='members-title icon-cfg'>Config options</h3><div class='subsection'><div id='cfg-asterixToDateTimePeriod' class='member first-child not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.TransitionsCalculator'>Lumenize.TransitionsCalculator</span><br/><a href='source/TransitionsCalculator.coffee.html#Lumenize-TransitionsCalculator-cfg-asterixToDateTimePeriod' target='_blank' class='view-source'>view source</a></div><a href='#!/api/Lumenize.TransitionsCalculator-cfg-asterixToDateTimePeriod' class='name expandable'>asterixToDateTimePeriod</a> : Boolean<span class=\"signature\"></span></div><div class='description'><div class='short'>If set to true, then the still-in-progress last time period will be asterixed ...</div><div class='long'><p>If set to true, then the still-in-progress last time period will be asterixed</p>\n<p>Defaults to: <code>false</code></p></div></div></div><div id='cfg-fieldsToSum' class='member  not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.TransitionsCalculator'>Lumenize.TransitionsCalculator</span><br/><a href='source/TransitionsCalculator.coffee.html#Lumenize-TransitionsCalculator-cfg-fieldsToSum' target='_blank' class='view-source'>view source</a></div><a href='#!/api/Lumenize.TransitionsCalculator-cfg-fieldsToSum' class='name expandable'>fieldsToSum</a> : String[]<span class=\"signature\"></span></div><div class='description'><div class='short'>It will track the count automatically but it can keep a running sum of other fields also ...</div><div class='long'><p>It will track the count automatically but it can keep a running sum of other fields also</p>\n<p>Defaults to: <code>[]</code></p></div></div></div><div id='cfg-granularity' class='member  not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.TransitionsCalculator'>Lumenize.TransitionsCalculator</span><br/><a href='source/TransitionsCalculator.coffee.html#Lumenize-TransitionsCalculator-cfg-granularity' target='_blank' class='view-source'>view source</a></div><a href='#!/api/Lumenize.TransitionsCalculator-cfg-granularity' class='name expandable'>granularity</a> : String<span class=\"signature\"></span></div><div class='description'><div class='short'>'month', 'week', 'quarter', etc. ...</div><div class='long'><p>'month', 'week', 'quarter', etc. Use Time.MONTH, Time.WEEK, etc.</p>\n</div></div></div><div id='cfg-tz' class='member  not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.TransitionsCalculator'>Lumenize.TransitionsCalculator</span><br/><a href='source/TransitionsCalculator.coffee.html#Lumenize-TransitionsCalculator-cfg-tz' target='_blank' class='view-source'>view source</a></div><a href='#!/api/Lumenize.TransitionsCalculator-cfg-tz' class='name expandable'>tz</a> : String<span class=\"signature\"></span></div><div class='description'><div class='short'><p>The timezone for analysis in the form like <code>America/New_York</code></p>\n</div><div class='long'><p>The timezone for analysis in the form like <code>America/New_York</code></p>\n</div></div></div><div id='cfg-uniqueIDField' class='member  not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.TransitionsCalculator'>Lumenize.TransitionsCalculator</span><br/><a href='source/TransitionsCalculator.coffee.html#Lumenize-TransitionsCalculator-cfg-uniqueIDField' target='_blank' class='view-source'>view source</a></div><a href='#!/api/Lumenize.TransitionsCalculator-cfg-uniqueIDField' class='name expandable'>uniqueIDField</a> : String<span class=\"signature\"></span></div><div class='description'><div class='short'>Not used right now but when drill-down is added it will be ...</div><div class='long'><p>Not used right now but when drill-down is added it will be</p>\n<p>Defaults to: <code>&quot;ObjectID&quot;</code></p></div></div></div><div id='cfg-validFromField' class='member  not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.TransitionsCalculator'>Lumenize.TransitionsCalculator</span><br/><a href='source/TransitionsCalculator.coffee.html#Lumenize-TransitionsCalculator-cfg-validFromField' target='_blank' class='view-source'>view source</a></div><a href='#!/api/Lumenize.TransitionsCalculator-cfg-validFromField' class='name expandable'>validFromField</a> : String<span class=\"signature\"></span></div><div class='description'><div class='short'> ...</div><div class='long'>\n<p>Defaults to: <code>&quot;_ValidFrom&quot;</code></p></div></div></div><div id='cfg-validToField' class='member  not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.TransitionsCalculator'>Lumenize.TransitionsCalculator</span><br/><a href='source/TransitionsCalculator.coffee.html#Lumenize-TransitionsCalculator-cfg-validToField' target='_blank' class='view-source'>view source</a></div><a href='#!/api/Lumenize.TransitionsCalculator-cfg-validToField' class='name expandable'>validToField</a> : String<span class=\"signature\"></span></div><div class='description'><div class='short'> ...</div><div class='long'>\n<p>Defaults to: <code>&quot;_ValidTo&quot;</code></p></div></div></div></div></div><div class='members-section'><h3 class='members-title icon-method'>Methods</h3><div class='subsection'><div class='definedBy'>Defined By</div><h4 class='members-subtitle'>Instance methods</h3><div id='method-constructor' class='member first-child not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.TransitionsCalculator'>Lumenize.TransitionsCalculator</span><br/><a href='source/TransitionsCalculator.coffee.html#Lumenize-TransitionsCalculator-method-constructor' target='_blank' class='view-source'>view source</a></div><strong class='new-keyword'>new</strong><a href='#!/api/Lumenize.TransitionsCalculator-method-constructor' class='name expandable'>Lumenize.TransitionsCalculator</a>( <span class='pre'>config</span> ) : <a href=\"#!/api/Lumenize.TransitionsCalculator\" rel=\"Lumenize.TransitionsCalculator\" class=\"docClass\">Lumenize.TransitionsCalculator</a><span class=\"signature\"></span></div><div class='description'><div class='short'> ...</div><div class='long'>\n<h3 class=\"pa\">Parameters</h3><ul><li><span class='pre'>config</span> : Object<div class='sub-desc'>\n</div></li></ul><h3 class='pa'>Returns</h3><ul><li><span class='pre'><a href=\"#!/api/Lumenize.TransitionsCalculator\" rel=\"Lumenize.TransitionsCalculator\" class=\"docClass\">Lumenize.TransitionsCalculator</a></span><div class='sub-desc'>\n</div></li></ul></div></div></div><div id='method-addSnapshots' class='member  not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.TransitionsCalculator'>Lumenize.TransitionsCalculator</span><br/><a href='source/TransitionsCalculator.coffee.html#Lumenize-TransitionsCalculator-method-addSnapshots' target='_blank' class='view-source'>view source</a></div><a href='#!/api/Lumenize.TransitionsCalculator-method-addSnapshots' class='name expandable'>addSnapshots</a>( <span class='pre'>snapshots, startOn, endBefore</span> ) : TransitionsCalculator<span class=\"signature\"><span class='chainable' >chainable</span></span></div><div class='description'><div class='short'>Allows you to incrementally add snapshots to this calculator. ...</div><div class='long'><p>Allows you to incrementally add snapshots to this calculator.</p>\n<h3 class=\"pa\">Parameters</h3><ul><li><span class='pre'>snapshots</span> : Object[]<div class='sub-desc'><p>An array of temporal data model snapshots.</p>\n</div></li><li><span class='pre'>startOn</span> : String<div class='sub-desc'><p>A ISOString (e.g. '2012-01-01T12:34:56.789Z') indicating the time start of the period of\n  interest. On the second through nth call, this should equal the previous endBefore.</p>\n</div></li><li><span class='pre'>endBefore</span> : String<div class='sub-desc'><p>A ISOString (e.g. '2012-01-01T12:34:56.789Z') indicating the moment just past the time\n  period of interest.</p>\n</div></li></ul><h3 class='pa'>Returns</h3><ul><li><span class='pre'>TransitionsCalculator</span><div class='sub-desc'>\n</div></li></ul></div></div></div><div id='method-getResults' class='member  not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.TransitionsCalculator'>Lumenize.TransitionsCalculator</span><br/><a href='source/TransitionsCalculator.coffee.html#Lumenize-TransitionsCalculator-method-getResults' target='_blank' class='view-source'>view source</a></div><a href='#!/api/Lumenize.TransitionsCalculator-method-getResults' class='name expandable'>getResults</a>( <span class='pre'></span> ) : Object[]<span class=\"signature\"></span></div><div class='description'><div class='short'>Returns the current state of the calculator ...</div><div class='long'><p>Returns the current state of the calculator</p>\n<h3 class='pa'>Returns</h3><ul><li><span class='pre'>Object[]</span><div class='sub-desc'><p>Returns an Array of Maps like <code>{timePeriod: '2012-12', count: 10, otherField: 34}</code></p>\n</div></li></ul></div></div></div><div id='method-getStateForSaving' class='member  not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.TransitionsCalculator'>Lumenize.TransitionsCalculator</span><br/><a href='source/TransitionsCalculator.coffee.html#Lumenize-TransitionsCalculator-method-getStateForSaving' target='_blank' class='view-source'>view source</a></div><a href='#!/api/Lumenize.TransitionsCalculator-method-getStateForSaving' class='name expandable'>getStateForSaving</a>( <span class='pre'>[meta]</span> ) : Object<span class=\"signature\"></span></div><div class='description'><div class='short'>Enables saving the state of this calculator. ...</div><div class='long'><p>Enables saving the state of this calculator. See TimeInStateCalculator documentation for a detailed example.</p>\n<h3 class=\"pa\">Parameters</h3><ul><li><span class='pre'>meta</span> : Object (optional)<div class='sub-desc'><p>An optional parameter that will be added to the serialized output and added to the meta field\n  within the deserialized calculator.</p>\n</div></li></ul><h3 class='pa'>Returns</h3><ul><li><span class='pre'>Object</span><div class='sub-desc'><p>Returns an Ojbect representing the state of the calculator. This Object is suitable for saving to\n  to an object store. Use the static method <code>newFromSavedState()</code> with this Object as the parameter to reconstitute\n  the calculator.</p>\n</div></li></ul></div></div></div></div><div class='subsection'><div class='definedBy'>Defined By</div><h4 class='members-subtitle'>Static methods</h3><div id='static-method-newFromSavedState' class='member first-child not-inherited'><a href='#' class='side expandable'><span>&nbsp;</span></a><div class='title'><div class='meta'><span class='defined-in' rel='Lumenize.TransitionsCalculator'>Lumenize.TransitionsCalculator</span><br/><a href='source/TransitionsCalculator.coffee.html#Lumenize-TransitionsCalculator-static-method-newFromSavedState' target='_blank' class='view-source'>view source</a></div><a href='#!/api/Lumenize.TransitionsCalculator-static-method-newFromSavedState' class='name expandable'>newFromSavedState</a>( <span class='pre'>p</span> ) : TransitionsCalculator<span class=\"signature\"><span class='static' >static</span></span></div><div class='description'><div class='short'>Deserializes a previously saved calculator and returns a new calculator. ...</div><div class='long'><p>Deserializes a previously saved calculator and returns a new calculator. See TimeInStateCalculator for a detailed example.</p>\n<h3 class=\"pa\">Parameters</h3><ul><li><span class='pre'>p</span> : String/Object<div class='sub-desc'><p>A String or Object from a previously saved state</p>\n</div></li></ul><h3 class='pa'>Returns</h3><ul><li><span class='pre'>TransitionsCalculator</span><div class='sub-desc'>\n</div></li></ul></div></div></div></div></div></div></div>","meta":{}});