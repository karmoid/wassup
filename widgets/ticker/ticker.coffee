class Dashing.Ticker extends Dashing.Widget

  # pixels per second
  @SPEED:  70

  # easing function to use for the animation
  @EASING: "linear"

  # Whether to use CSS3 animations.  If false, jQuery animate() will be used.
  @CSS_ANIMATION: true

  # Number of milliseconds between jQuery animation frames.  The
  # default is 13, which causes this ticker to have pretty high cpu usage.
  # 40 is about the highest I've gone before animations start to look bad.
  # Lower numbers will cause smoother animations.
  # NOTE: this will cause a change to GLOBAL jQuery animations on the page.
  # Only used if CSS_ANIMATION is false.
  @FX_INTERVAL: 30

  # Used for vertical scrolling, the number of seconds to show an alert before
  # scrolling to the next one.
  @DELAY = 5

  getTicker: ->
    $("#news_ticker")

  # should be either "vertical" or "horizontal"
  getScrollOrientation: ->
    if $(@node).data('scroll_orientation')
      $(@node).data('scroll_orientation')
    else
      "vertical"

  initialize: ->
    return true if @initialized
    if not $(".gridster.ready").length or not @getTicker().length
      @log( "not ready yet..." )
      return false

    @log( "initializing..." )

    if not Ticker.CSS_ANIMATION and @getScrollOrientation() == 'horizontal'
      @log( "setting jQuery fx interval to #{Ticker.FX_INTERVAL}" )
      jQuery.fx.interval = Ticker.FX_INTERVAL
      $.fn.transition = $.fn.animate

    @ticker = @getTicker()
    # Set a width first based on the board size
    @log( "setting node width to " + $(".gridster.ready").width() )
    $(@node).width( $(".gridster.ready").width() )

    # Wrap the ticker in some extra divs
    @log( "adding wrapper divs" )
    @ticker.addClass('newsticker')
    @ticker.wrap('<div class="mask" />')
    @ticker.parent().wrap('<div class="tickercontainer" />')

    @initialized = true


  ready: ->
    # This is fired when the widget is done being rendered
    @log("ready")
    @doTicker()

  onData: (data) ->
    @log( "onData" )
    @doTicker()

  doTicker: ->
    @initialize() if not @initialized
    if @initialized
      if @hasChanged() and @hasItems()
        @resetTicker()
      else if not @hasItems()
        @stopTicker()

  startTicker: ->
    @log( "" )
    @log("starting ticker")
    @should_stop = false
    $(@node).show()

    if @getScrollOrientation() == "horizontal"
      @doHorizontalScroll()
    else
      @doVerticalScroll()


  doHorizontalScroll: ->
    @log( "doing horizontal scroll" )

    viewWidth = @ticker.parent().width()
    @log( "viewWidth: #{viewWidth}" )

    # Add a spacer between ticker elements so that only one of them is showing at once
    @insertSpacers( viewWidth )

    # calculate content width
    @log( "calculating content width..." )
    contentWidth = @contentWidth()

    # set ticker width to the sum of the viewport and the content
    tickerWidth = viewWidth + contentWidth
    @log( "setting ticker width to #{tickerWidth}" )
    @ticker.css('width', tickerWidth)
    # set ticker left value to viewWidth
    @ticker.css('left', viewWidth)

    # then animate the left value to -contentWidth
    animationSettings = { 'left': -contentWidth }
    @log( "animating 'left' value from #{viewWidth} to #{-contentWidth}" )
    duration = tickerWidth * 1000 / Ticker.SPEED
    console.log( "duration: #{duration} ms" )
    @ticker.transition animationSettings, duration, Ticker.EASING, =>
      if not @should_stop
        @log( "loop complete, do it again!" )
        @startTicker()

  doVerticalScroll: ->
    @log( "doing vertical scroll" )
    @itemHeight = @ticker.children('li').first().outerHeight()
    contentHeight = @itemHeight * @ticker.children('li').size()

    # set ticker height to the content height
    @ticker.css('height', contentHeight)

    # set ticker top value to @itemHeight
    @ticker.css('top', @itemHeight)

    @ticker.children('li').width('100%')

    @nextItem()

  nextItem: =>
    @log( "scrolling to next item" )
    animationSettings = { 'top': @ticker.position().top - @itemHeight }
    duration = 1000
    @ticker.transition animationSettings, duration, "linear", =>
      if not @should_stop
        @log( "comparing #{@ticker.position().top - 2} to #{-@ticker.outerHeight()}" )
        if @ticker.position().top - 2 > -@ticker.outerHeight()
          @log( "scheduling the next item" )
          @scrollNext = setTimeout( @nextItem, Ticker.DELAY * 1000 )
        else
          @log( "loop complete, do it again!" )
          @startTicker()

  stopTicker: ->
    @log("stopping ticker")
    @should_stop = true
    if @ticker
      @ticker.stop( true )
      clearTimeout( @scrollNext )
      @ticker.removeAttr('style')
    $(@node).hide()

  resetTicker: ->
    @stopTicker()
    @startTicker()

  contentWidth: ->
    contentWidth = 0
    for child in @ticker.children()
      contentWidth += $(child).outerWidth( true )
    return contentWidth

  hasItems: ->
    return @get('items' ) and @get('items').length > 0

  hasChanged: ->
    new_items = @get('items')
    changed = false
    if @old_items == new_items
      # short circuit, they're probably both null
      return false
    if @old_items and not new_items
      changed = true
    else if new_items and not @old_items
      changed = true
    else if @old_items.toString() != new_items.toString()
      changed = true
    if changed
      @log( "items changed" )
    else
      @log( "items the same" )
    @old_items = new_items
    return changed

  insertSpacers: (width) ->
    @log( "inserting spacers" )
    @ticker.children().not(':last-child').css('margin-right', width)

  log: (msg) ->
    # console.log( "[ticker] #{msg}" )
    return
