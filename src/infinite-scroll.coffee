mod = angular.module('infinite-scroll', [])

mod.value('THROTTLE_MILLISECONDS', null)

mod.directive 'infiniteScroll', ['$rootScope', '$window', '$timeout', 'THROTTLE_MILLISECONDS', \
                                  ($rootScope, $window, $timeout, THROTTLE_MILLISECONDS) ->
  scope:
    infiniteScroll: '&'
    infiniteScrollContainer: '='
    infiniteScrollDistance: '='
    infiniteScrollDisabled: '='
    infiniteScrollUseDocumentBottom: '='

  link: (scope, elem, attrs) ->
    $window = angular.element($window)

    scrollDistance = null
    scrollEnabled = null
    checkWhenEnabled = null
    container = null
    immediateCheck = true
    useDocumentBottom = false

    # infinite-scroll specifies a function to call when the window,
    # or some other container specified by infinite-scroll-container,
    # is scrolled within a certain range from the bottom of the
    # document. It is recommended to use infinite-scroll-disabled
    # with a boolean that is set to true when the function is
    # called in order to throttle the function call.
    handler = ->
      if container == $window
        containerBottom = container.height() + container.scrollTop()
        elementBottom = elem.offset().top + elem.height()
      else
        containerBottom = container.height()
        containerTopOffset = 0
        if container.offset() != undefined
          containerTopOffset = container.offset().top
        elementBottom = elem.offset().top - containerTopOffset + elem.height()

      if(useDocumentBottom)
        elementBottom = $(document).height()

      remaining = elementBottom - containerBottom
      shouldScroll = remaining <= container.height() * scrollDistance + 1

      if shouldScroll
        checkWhenEnabled = true

        if scrollEnabled
          if scope.$$phase || $rootScope.$$phase
            scope.infiniteScroll()
          else
            scope.$apply(scope.infiniteScroll)
      else
        checkWhenEnabled = false

    # The optional THROTTLE_MILLISECONDS configuration value specifies
    # a minimum time that should elapse between each call to the
    # handler. N.b. the first call the handler will be run
    # immediately, and the final call will always result in the
    # handler being called after the `wait` period elapses.
    # A slimmed down version of underscore's implementation.
    throttle = (func, wait) ->
      timeout = null
      previous = 0
      later = ->
        previous = new Date().getTime()
        $timeout.cancel(timeout)
        timeout = null
        func.call()
        context = null

      return ->
        now = new Date().getTime()
        remaining = wait - (now - previous)
        if remaining <= 0
          clearTimeout timeout
          $timeout.cancel(timeout)
          timeout = null
          previous = now
          func.call()
        else timeout = $timeout(later, remaining) unless timeout

    if THROTTLE_MILLISECONDS?
      handler = throttle(handler, THROTTLE_MILLISECONDS)

    scope.$on '$destroy', ->
      container.off 'scroll', handler

    # infinite-scroll-distance specifies how close to the bottom of the page
    # the window is allowed to be before we trigger a new scroll. The value
    # provided is multiplied by the container height; for example, to load
    # more when the bottom of the page is less than 3 container heights away,
    # specify a value of 3. Defaults to 0.
    handleInfiniteScrollDistance = (v) ->
      scrollDistance = parseInt(v, 10) or 0

    scope.$watch 'infiniteScrollDistance', handleInfiniteScrollDistance
    # If I don't explicitly call the handler here, tests fail. Don't know why yet.
    handleInfiniteScrollDistance scope.infiniteScrollDistance

    # infinite-scroll-disabled specifies a boolean that will keep the
    # infnite scroll function from being called; this is useful for
    # debouncing or throttling the function call. If an infinite
    # scroll is triggered but this value evaluates to true, then
    # once it switches back to false the infinite scroll function
    # will be triggered again.
    handleInfiniteScrollDisabled = (v) ->
      scrollEnabled = !v
      if scrollEnabled && checkWhenEnabled
        checkWhenEnabled = false
        handler()

    scope.$watch 'infiniteScrollDisabled', handleInfiniteScrollDisabled
    # If I don't explicitly call the handler here, tests fail. Don't know why yet.
    handleInfiniteScrollDisabled scope.infiniteScrollDisabled

    # use the bottom of the document instead of the element's bottom.
    # This useful when the element does not have a height due to its
    # children being absolute positioned.
    handleInfiniteScrollUseDocumentBottom = (v) ->
      useDocumentBottom = v

    scope.$watch 'infiniteScrollUseDocumentBottom', handleInfiniteScrollUseDocumentBottom
    handleInfiniteScrollUseDocumentBottom scope.infiniteScrollUseDocumentBottom

    # infinite-scroll-container sets the container which we want to be
    # infinte scrolled, instead of the whole window. Must be an
    # Angular or jQuery element, or, if jQuery is loaded,
    # a jQuery selector as a string.
    changeContainer = (newContainer) ->
      if container?
        container.off 'scroll', handler

      container = if typeof newContainer.last is 'function' && newContainer != $window then newContainer.last() else newContainer
      if newContainer?
        container.on 'scroll', handler

    changeContainer $window

    handleInfiniteScrollContainer = (newContainer) ->
      # TODO: For some reason newContainer is sometimes null instead
      # of the empty array, which Angular is supposed to pass when the
      # element is not defined
      # (https://github.com/sroze/ngInfiniteScroll/pull/7#commitcomment-5748431).
      # So I leave both checks.
      if (not newContainer?) or newContainer.length == 0
        return
      newContainer = angular.element newContainer
      if newContainer?
        changeContainer newContainer
      else
        throw new Exception("invalid infinite-scroll-container attribute.")

    scope.$watch 'infiniteScrollContainer', handleInfiniteScrollContainer
    handleInfiniteScrollContainer(scope.infiniteScrollContainer or [])

    # infinite-scroll-parent establishes this element's parent as the
    # container infinitely scrolled instead of the whole window.
    if attrs.infiniteScrollParent?
      changeContainer angular.element elem.parent()

    # infinte-scoll-immediate-check sets whether or not run the
    # expression passed on infinite-scroll for the first time when the
    # directive first loads, before any actual scroll.
    if attrs.infiniteScrollImmediateCheck?
      immediateCheck = scope.$eval(attrs.infiniteScrollImmediateCheck)

    $timeout (->
      if immediateCheck
        handler()
    ), 0
]
