window.SangerSequencing = new Object()

class SangerSequencing.WellPlateBuilder

  class Util
    @flattenArray: (arrays) ->
      concatFunction = (total, submission) ->
        total.concat submission
      arrays.reduce(concatFunction, [])

  constructor: ->
    @submissions = []
    @reservedCells = ["A01", "A02"]
    @orderingStrategy = new OddFirstOrderingStrategy

  addSubmission: (submission) ->
    @submissions.push(submission) unless @hasBeenAdded(submission)

  hasBeenAdded: (submission) ->
    @submissions.indexOf(submission) >= 0

  samples: ->
    Util.flattenArray(@submissions.map (submission) ->
      submission.samples.map (s) ->
        if s instanceof SangerSequencing.Sample then s else new SangerSequencing.Sample(s)
    )

  sampleAtCell: (cell) ->
    @render()[cell]

  render: ->
    fillOrder = @orderingStrategy.fillOrder(@cellArray())

    samples = @samples()
    results = {}

    for cellName in fillOrder
      sample = null
      if @reservedCells.indexOf(cellName) < 0
        if sample = samples.shift()
          sample = sample
        else
          sample = new SangerSequencing.Sample.Blank
      else
        sample = new SangerSequencing.Sample.Reserved

      results[cellName] = sample

    results

  @rows: ->
    for ch in "ABCDEFGH"
      name: ch
      cells: for num in ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
        column: num
        name: "#{ch}#{num}"

  cellArray: ->
    cells = for num in ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
      for ch in "ABCDEFGH"
        "#{ch}#{num}"

  class OddFirstOrderingStrategy
    fillOrder: (cellsByColumn) ->
      odds = (column for column, i in cellsByColumn when i % 2 == 0)
      evens = (column for column, i in cellsByColumn when i % 2 == 1)
      Util.flattenArray(odds.concat(evens))
