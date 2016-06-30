window.SangerSequencing = new Object()

class SangerSequencing.WellPlateBuilder

  class Util
    @flattenArray: (arrays) ->
      concatFunction = (total, submission) ->
        total.concat submission
      arrays.reduce(concatFunction, [])

  class OddFirstOrderingStrategy
    fillOrder: ->
      odds = (column for column, i in @_cellsByColumn() when i % 2 == 0)
      evens = (column for column, i in @_cellsByColumn() when i % 2 == 1)
      Util.flattenArray(odds.concat(evens))

    _cellsByColumn: ->
      cells = for num in ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
        for ch in "ABCDEFGH"
          "#{ch}#{num}"

  constructor: ->
    @submissions = []
    # This array maintains all of the submissions that have ever been added
    # in order to keep consistent colors when removing and adding samples.
    @allSubmissions = []
    @reservedCells = ["A01", "A02"]
    @orderingStrategy = new OddFirstOrderingStrategy
    @_render()

  addSubmission: (submission) ->
    @submissions.push(submission) unless @isInPlate(submission)
    @allSubmissions.push(submission) unless @hasBeenAddedBefore(submission)
    @_render()

  removeSubmission: (submission) ->
    index = @submissions.indexOf(submission)
    @submissions.splice(index, 1) if index > -1
    @_render()

  isInPlate: (submission) ->
    @submissions.indexOf(submission) >= 0

  hasBeenAddedBefore: (submission) ->
    @allSubmissions.indexOf(submission) >= 0

  sampleAtCell: (cell, plateIndex = 0) ->
    @plates[plateIndex][cell]

  samples: ->
    Util.flattenArray(@submissions.map (submission) ->
      submission.samples.map (s) ->
        if s instanceof SangerSequencing.Sample then s else new SangerSequencing.Sample(s)
    )

  plateCount: ->
    @_plateCount

  @grid: ->
    for ch in "ABCDEFGH"
      name: ch
      cells: for num in ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
        column: num
        name: "#{ch}#{num}"

  # Private

  _render: ->
    @_plateCount = Math.max(1, Math.ceil(@samples().length / @_fillOrder().length))

    samples = @samples()
    allPlates = []

    for plate in [0..@plateCount()]
      allPlates.push(@_renderPlate(samples))

    @plates = allPlates

  _renderPlate: (samples) ->
    plate = {}

    for cellName in @_fillOrder()
      plate[cellName] = if @reservedCells.indexOf(cellName) < 0
        if sample = samples.shift()
          sample
        else
          new SangerSequencing.Sample.Blank
      else
        # Reserved will actually take up a cell, while ReservedButUnused is
        # for when we have not actually reached that cell in the fill order,
        # so it will instead be treated as blank.
        if samples.length > 0
          new SangerSequencing.Sample.Reserved
        else
          new SangerSequencing.Sample.ReservedButUnused

       sample

    plate

  _fillOrder: ->
    @orderingStrategy.fillOrder()
