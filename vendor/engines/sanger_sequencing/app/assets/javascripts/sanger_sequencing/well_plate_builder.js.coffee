#= require sanger_sequencing/odd_first_ordering_strategy
#= require sanger_sequencing/sequential_ordering_strategy

exports = exports ? @

class exports.SangerSequencing.WellPlateBuilder

  constructor: ->
    @submissions = []
    # This array maintains all of the submissions that have ever been added
    # in order to keep consistent colors when removing and adding samples.
    @allSubmissions = []
    @_reservedCells = ["A01", "A02"]
    @_orderingStrategy = new SangerSequencing.OddFirstOrderingStrategy
    @_orderingStrategy = new SangerSequencing.SequentialOrderingStrategy
    @_render()

  addSubmission: (submission) ->
    @submissions.push(submission) unless @isInPlate(submission)
    @allSubmissions.push(submission) unless @hasBeenAddedBefore(submission)
    @_render()

  removeSubmission: (submission) ->
    index = @submissions.indexOf(submission)
    @submissions.splice(index, 1) if index > -1
    @_render()

  setReservedCells: (cells) ->
    @_reservedCells = cells if cells?
    @_render()

  isInPlate: (submission) ->
    @submissions.indexOf(submission) >= 0

  hasBeenAddedBefore: (submission) ->
    @allSubmissions.indexOf(submission) >= 0

  sampleAtCell: (cell, plateIndex = 0) ->
    @plates[plateIndex][cell]

  samples: ->
    SangerSequencing.Util.flattenArray(@submissions.map (submission) ->
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
    wellsInPlate = @_fillOrder().length - @_reservedCells.length
    @_plateCount = Math.max(1, Math.ceil(@samples().length / wellsInPlate))

    samples = @samples()
    allPlates = []

    for plate in [0..@plateCount()]
      allPlates.push(@_renderPlate(samples))

    @plates = allPlates

  _renderPlate: (samples) ->
    plate = {}

    for cellName in @_fillOrder()
      plate[cellName] = if @_reservedCells.indexOf(cellName) < 0
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
    @_orderingStrategy.fillOrder()
