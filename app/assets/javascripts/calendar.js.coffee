# Month
class Month
  constructor: (year, month) ->
    if month < 1 || month > 12
      month = 1
    @year = year
    @month = month
    @months = year * 12 + month

  refresh: ->
    @month = @months % 12
    @year = (@months - (@months % 12)) / 12
    if @month == 0
      @month = 12
      @year--

  next: ->
    @months++
    @refresh()

  prev: ->
    @months--;
    @refresh()

  set: (month) ->
    @year = month.year
    @month = month.month
    @months = month.months

  add: (months) ->
    @months += months
    @refresh()

  subtract: (months) ->
    @months -= months
    @refresh()

  minus: (month) ->
    return @months - month.months

  equals: (month) ->
    return @months == month.months

# Calendar
class @Calendar
  constructor: (callback) ->
    @selectedMonth = null
    @startMonth = null
    @callback = callback
    @leftMargin = 7

  selectMonth: (year, month, call) ->
    @selectedMonth = new Month(year, month)

    @startMonth = new Month(year, month)
    @startMonth.subtract(@leftMargin)

    current = new Month(@startMonth.year, @startMonth.month)

    # year の変わり目を検査する
    # 1開始なら変わらない 2月以降なら変わる
    colspan = 12
    if current.month >= 2
      colspan = 12 - (current.month - 1)
    yearClass = if current.year % 2 then 'odd_year' else 'even_year'

    str = "<table>"
    str += "<tr>"
    str += "<td rowspan='2' id='prev_year' class='year_nav calendar_selector'" +
      "' data-year='"  + (@selectedMonth.year - 1) +
      "' data-month='" + @selectedMonth.month + "'>&lt;&lt;</td>"
    str += "<td class='year " + yearClass + "' colspan='" + colspan + "'>" + current.year + "</td>"
    if colspan < 12
      nextYear = current.year + 1
      yearClass = if nextYear % 2 then 'odd_year' else 'even_year'
      secondColspan = 12 - colspan
      str += "<td class='year " + yearClass + "' colspan='"
      str += secondColspan
      str += "'>" + nextYear + "</td>"
    str += "<td rowspan='2' id='next_year' class='year_nav calendar_selector'" +
      "' data-year='"  + (@selectedMonth.year + 1) +
      "' data-month='" + @selectedMonth.month + "'>&gt;&gt;</td>"
    str += "</tr>"
    str += "<tr>"
    for i in [0..11]
      yearClass = if current.year % 2  then 'odd_year' else 'even_year'
      if @selectedMonth.equals(current)
        str += "<td class='selected_month month' id='month_" + current.year + "_" + current.month + "'><div class='" + yearClass + "'>"
      else
        str += "<td class='selectable_month month' id='month_" + current.year + "_" + current.month + "'>"
        str += "<div class='" + yearClass + "'>"
        str += "<a class='calendar_selector' data-year='" + current.year + "' data-month='" + current.month + "'>"
      str += current.month + "月"
      if !@selectedMonth.equals(current)
        str += '</a>'
      str += "</div>"
      str += '</td>'
      current.next()
    str += "</tr>"
    str += "</table>"

    $("#calendar").get(0).innerHTML = str

    $("#calendar_year").val(@selectedMonth.year)
    $("#calendar_month").val(@selectedMonth.month)

    # if call && @callback
      # @callback.call()
    if call
      $('#calendar').trigger('change', @selectedMonth)

$ ->
  if $('#calendar').length > 0
    @calendar = new Calendar()
    @calendar.selectMonth($('#calendar').data('initial-year'), $('#calendar').data('initial-month'), false)

  $(document).on('click', '#calendar .calendar_selector', ->
    document.calendar.selectMonth($(@).data('year'), $(@).data('month'), true)
  )
  $(document).on('change', '#calendar.switcher', (event, month) ->
    url = $(@).data('url-template').replace('_YEAR_', month.year).replace('_MONTH_', month.month)
    location.href = url
  )
