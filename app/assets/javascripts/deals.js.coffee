
# 残高編集時に金額を計算する
class MoneyCounter
  fields: ['man', 'gosen', 'nisen', 'sen', 'gohyaku', 'hyaku', 'gojyu', 'jyu', 'go', 'ichi']
  amounts: [10000, 5000, 2000, 1000, 500, 100, 50, 10, 5, 1]
  count: ->
    amount = 0
    for i in [0..@fields.length-1]
      v = $('#' + @fields[i]).val()
      if v != ''
        amount += parseInt(v) * @amounts[i]
    $('#deal_balance').val(amount)

# 更新された行のスタイリング

addClassToUpdatedline = ->
  if location.hash.match(/^#d[0-9]+$/)
    id = location.hash.replace('#', '')
    $("." + id).not(".detail_row").addClass("updated_line")

clearUpdateLine = ->
  $("tr").removeClass("updated_line")

# 最近の記入パターン欄の内容の更新
@loadRecentDealPatterns = ->
  $frame = $('#deal_pattern_frame')
  $frame.load($frame.data('url'))

# 最近の記入パターン欄を表示する（常に表示モードならなにもしない）
showRecentDealPatterns = ->
  return if $('#deal_pattern_frame').data('mode') == 'always'
  $('#deal_pattern_frame').show()

# 最近の記入パターン欄を隠す（常に表示モードならなにもしない）
hideRecentDealPatterns = ->
  return if $('#deal_pattern_frame').data('mode') == 'always'
  $('#deal_pattern_frame').hide()

dealHasAccountId = (deal, account_id)->
  return false unless account_id && deal
  for entry in deal.readonly_entries
    return true if entry.account_id == account_id
  return false

$ ->
  # hide notice
  hideNotice = ->
    $('#notice').hide()

  # 登録フォーム一式のidを編集フォームと重複しないように加工し、無効化して、見えなくする
  disableCreateWindow = ->
    $new_deal_window = $("#new_deal_window")
    return if $new_deal_window.hasClass('disabled') # 二重に走らないようにする
    $new_deal_window.hide()
    $('#edit_mode_explanation').show()
    $new_deal_window.find('#errorExplanation').remove() # 検証エラーメッセージが出ていたら削除する
    $new_deal_window.addClass('disabled')
    $new_deal_window.find("*").each ->
      if @id
        @id = "disabled_new_deal_" + @id
      if @tagName == "A"
        $(@).addClass('disabled')
      if @tagName == "INPUT" || @tagName == "SELECT"
        @disabled = 'disabled'

  # 登録フォーム一式のidや無効化状態を戻して表示する
  enableCreateWindow = ->
    $new_deal_window = $("#new_deal_window")
    $new_deal_window.removeClass('disabled')
    $new_deal_window.find("*").each ->
      if @.id
        @.id = @.id.replace("disabled_new_deal_", "")
      if @tagName == "A"
        $(@).removeClass('disabled')
      if @tagName == "INPUT" || @tagName == "SELECT"
        $(@).prop('disabled', null)
    $('#edit_mode_explanation').hide()
    $new_deal_window.show()

  # 無効化されたリンクを封じる
  $(document).on('click', "a.disabled", (event) ->
    event.preventDefault()
  )

  # 編集windowを閉じる
  closeEditWindow = (event) ->
    $(@).closest('tr.edit_deal_row').remove()
    enableCreateWindow()
    hideRecentDealPatterns()
    event.preventDefault()

  $(document).on('click', '#edit_window button.close', closeEditWindow)
  $(document).on('click', 'a.close_edit_window', ->
    $('#edit_window button.close').click()
  )

  # deal_tab
  $(document).on('click', '#deal_forms .tabbuttons a.btn', ->
    return false if $(@).hasClass('active')
    hideNotice()
    $('#deal_forms').load(this.href)
    return false
  )

# deal_form
  # click (submitでreturn false すると disabled にされてしまうので submit イベントが送られないように先に処理する)
  $(document).on('click', '#deal_form [type=submit]', (event)->
    # 日付のチェック
    if $('#date_day').val() == '' || $('#date_month').val() == '' || $('#date_year').val() == ''
      alert('日付を入れてください。')
      return false

    # 金額のチェック
    amounts = $('#deal_form input.amount')
    if amounts.size() > 0 && $.grep(amounts.get(), (amount, index)-> $(amount).val() != '').length == 0
      alert('金額を入力してください。')
      return false
  )

  # submit
  $(document).on('submit', '#deal_form', (event)->
    # 日付の読み取り
    $('#deal_year').val($('#date_year').val())
    $('#deal_month').val($('#date_month').val())
    $('#deal_day').val($('#date_day').val())

    # 記入登録/更新を試みる
    $.post(@action, $(@).serializeArray(), (result)->
      if result.error_view
        $('#deal_forms').empty()
        $('#deal_forms').append(result.error_view)
      else
        resultUrl = null
        resultUrlWithHash = null
        if result.redirect_to
          resultUrlWithHash = result.redirect_to
          resultUrl = resultUrlWithHash.split('#')[0]
        else
          if dealHasAccountId(result.deal, $('#deal_form_option').data("condition-account-id")) # 遷移先に条件がついていて適合していればそちらのURLにする
            resultUrl = $('#deal_form_option').data("condition-match-url").replace(/_YEAR_/, result.year).replace(/_MONTH_/, result.month)
          else
            resultUrl = $('#deal_form_option').data("result-url").replace(/_YEAR_/, result.year).replace(/_MONTH_/, result.month)
          resultUrlWithHash = resultUrl + "#recent"
        prevUrl = location.pathname
        prevSearch = location.search
        if prevSearch && prevSearch != ""
          prevUrl += "?" + prevSearch
        location.assign(resultUrlWithHash)
        # NOTE: assign しても location.pathname などが古いケースがあるため、resultUrlベースで用意して比較している
        if resultUrl == prevUrl
          location.reload()
    , 'JSON')
    return false # 通常の Form 動作は行わない
  )

  # 編集リンクのクリック
  $(document).on('click', 'a.edit_deal', (event)->
    $tr = $(@).closest('tr')
    if $tr.hasClass('edit_deal_row')
      $tr = $tr.prev()
    $('.edit_deal_row').remove()
    while !$tr.hasClass('last_entry') && $tr.size() > 0
      $tr = $tr.next()
    disableCreateWindow()
    $tr.after("<tr class='edit_deal_row'><td colspan='12' data-deal-id='" + $(@).data('deal-id') + "'></td></tr>")
    $(".edit_deal_row td").load(@href, null, ->
      location.hash = 'd' + $(@).data("deal-id") # コールバックで変えたほうが編集フォームが見やすい位置にスクロールされる
    )
    showRecentDealPatterns()
    event.preventDefault()
  )

  # a.add_entry_fields
  $(document).on('click', 'a.add_entry_fields', ->
    $('#deal_forms').load(@href, $(@).closest('form').serializeArray())
    return false
  )

  $(document).on('click', 'a.split_summary', ->
    $('#deal_summary_frame').hide()
    $('.entry_summary').show()
    $('#deal_summary_mode, #deal_pattern_summary_mode').val('split')
    false
  )

  $(document).on('click', 'a.unify_summary', ->
    $('.entry_summary').hide()
    $('#deal_summary_frame').show()
    $('#deal_summary_mode, #deal_pattern_summary_mode').val('unify')
    false
  )

  $(document).on('click', '#count_money_button', ->
    moneyCounter = new MoneyCounter
    moneyCounter.count()
    return false
  )

  $(document).on('click', 'a.end_of_month_button', ->
    day = endOfMonth($('#date_year').val(), $('#date_month').val())
    $('#date_day').val(day) if (day)
    return false
  )

  addClassToUpdatedline()

  $(window).hashchange ->
    clearUpdateLine()
    addClassToUpdatedline()

  # 登録日時などの表示

  $(document).on('mouseover', 'td.number', -> $('.timestamps', this).show())

  $(document).on('mouseout', 'td.number', -> $('.timestamps', this).hide())

  # 口座情報の表示
  $(document).on('mouseover', '.account-memo-trigger', -> $('.account-memo', this).show())
  $(document).on('mouseout',  '.account-memo-trigger',-> $('.account-memo', this).hide())

  # 日ナビゲーション

  $('.for_deal_editor').on('click', '#day_navigator td.day a', (event)->
    $(".body_tab_link[data=monthly]").click()
    $('input#date_day').val($(@).data('day'))
  )

  # 記入パターンのロード（リターンキーが押されたとき）
  $(document).on('keypress', 'input#pattern_keyword', (event) ->
    if event.which && event.which == 13
      $('#pattern_search_result').empty()
      code = $('input#pattern_keyword').val()
      if code != ''
        # try to load that pattern
        $('#notice').hide()
        url = $('#load_pattern_url').text().replace('template_pattern_code', encodeURIComponent(code))

        # 指定したコードがないときは 'Code not found' が返る
        $.get(url, (data) ->
          if data == 'Code not found'
            $('#pattern_search_result')[0].innerHTML = 'コード「' + code + '」の記入パターンは登録されていません。'
          else
            update_area = $('input#pattern_keyword').data('update-area')
            $(update_area).empty()
            $(update_area).append(data)
            # focus on submit button
            $(update_area).find("input[type='submit']").focus()
            loadRecentDealPatterns()
        )
      event.preventDefault()
  )

  # 記入の削除
  $(document).on('click', 'a.deal_deletion_link', (event)->
    $.post(@href, {_method: 'delete'}, (data) ->
      $('#content').find(".alert").remove()
      $('#content').prepend("<div class='alert alert-success alert-dismissable'><button class='close' type='button' data-dismiss='alert' area-hidden='true'>&times;</button>" + data.success_message + "</div>")
      $("tr.d" + data.deal.id).remove()
      location.hash = "top" # '#' もなしで取るのは難しいのでひとまずこのようにする
    )
    event.preventDefault()
  )

  # 記入の確認
  $(document).on('click', 'a.deal_confirmation_link', (event)->
    $.post(@href, {_method: 'put'}, (data) ->
      $('#content').find(".alert").remove()
      $('#content').prepend("<div class='alert alert-success alert-dismissable'><button class='close' type='button' data-dismiss='alert' area-hidden='true'>&times;</button>" + data.success_message + "</div>")
      $("tr.d" + data.deal.id + " a.deal_confirmation_link").remove()
      $("tr.d" + data.deal.id).removeClass('unconfirmed')
      location.hash = "d" + data.deal.id
    )
    event.preventDefault()
  )

  # ナビゲーター内の口座選択の変更
  $('#account_selector #account_id').change (event)->
    account_id = $(@).val()
    if account_id == ''
      # TODO: あとで実装する
      document.location.href = $('#deal_form_option').data('all-url')
    else
      document.location.href = $('#deal_form_option').data('account-url').replace('_ACCOUNT_ID_', account_id)


  # 口座選択状態などで情報ボタンを押したとき
  $(document).on('click', 'td.open_detail', (event)->
    $tr = $(@).closest('tr')

    while !$tr.hasClass('last_entry') && $tr.size() > 0
      $tr = $tr.next()

    # 自分のところがすでに開いていたらそれを閉じるだけ
    if $tr.next('.detail_row').is(':visible')
      $tr.next('.detail_row').hide()
    else # 新しく開くリクエストがきたらいったん全部閉じてから開く
      $('tr.detail_row').hide()
      $tr.next('.detail_row').show()
      location.hash = $(@).closest('tr').attr('id')
  )

  # monthlyページのボディタブ切り替え
  $(document).on('click', '.body_tab_link', (event)->
    $('.body_tab li').removeClass('active')
    $(@).closest('li').addClass('active')

    $('.body_tab_area').hide()
    $('#' + $(@).attr('data') + "_area").show()
  )

  # ロード時、#recent, #monthly というロケーションハッシュがあればリンククリック状態にする
  if $('#monthly_deals_body_tab').size() > 0
    if (window.location.hash == '#recent' || window.location.hash == '#monthly')
      $(".body_tab_link[data=" + window.location.hash.slice(1) + "]").click()
