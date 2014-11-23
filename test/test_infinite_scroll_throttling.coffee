############################### NOTE ################################
# Angular 1.2 allows us to be a lot more sophisticated about        #
# testing timeouts, waiting specific periods rather than just       #
# running all pending calls. However, we're using Angular 1.1, so   #
# we'll have to do with this limited set for now...                 #
# For more info, see: http://stackoverflow.com/questions/17541381   #
#####################################################################

should = chai.should()

describe 'Infinite Scroll Throttled to 200ms', ->
  [$rootScope, $compile, docWindow, $document, $timeout, fakeWindow, THROTTLE_MILLISECONDS] = [undefined]

  beforeEach ->
    module 'infinite-scroll', ($provide) ->
      $provide.value('THROTTLE_MILLISECONDS', 200)
      return

  beforeEach ->
    inject (_$rootScope_, _$compile_, _$window_, _$document_, _$timeout_, _THROTTLE_MILLISECONDS_) ->
      $rootScope = _$rootScope_
      $compile = _$compile_
      $window = _$window_
      $document = _$document_
      $timeout = _$timeout_
      fakeWindow = angular.element($window)

      THROTTLE_MILLISECONDS = _THROTTLE_MILLISECONDS_

  scroll = (container) ->
    event = $document[0].createEvent 'UIEvent'
    event.initUIEvent 'scroll', true, true, fakeWindow[0], 1

    container[0].dispatchEvent(event)

  it 'waits correct interval between calls to handler', ->
    scroller = """
    <div infinite-scroll='scroll()' style='height: #{fakeWindow[0].innerHeight}px'
      infinite-scroll-immediate-check='false'></div>
    """
    el = angular.element(scroller)
    angular.element($document[0].body).append(el)

    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    $compile(el)(scope)

    for i in [0..2] # so, three times
      scroll(fakeWindow)

    $timeout.flush()

    scope.scroll.should.have.been.calledTwice

    el.remove()
    scope.$destroy()

  it "doesn't duplicate calls", ->
    scroller = """
    <div infinite-scroll='scroll()' style='height: #{fakeWindow[0].innerHeight}px'
      infinite-scroll-immediate-check='false'></div>
    """
    el = angular.element(scroller)
    angular.element($document[0].body).append(el)

    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    $compile(el)(scope)

    scroll(fakeWindow)

    $timeout.flush()

    scope.scroll.should.have.been.called.twice

    el.remove()
    scope.$destroy()

  it 'triggers immediately by default', ->
    scroller = """
    <div infinite-scroll='scroll()' style='height: #{fakeWindow[0].innerHeight}px'></div>
    """
    el = angular.element(scroller)
    angular.element($document[0].body).append(el)

    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    $compile(el)(scope)
    $timeout.flush() # 'immediate' call is with $timeout ..., 0
    scope.scroll.should.have.been.calledOnce

    el.remove()
    scope.$destroy()

  it 'does not trigger immediately when infinite-scroll-immediate-check is false', ->
    scroller = """
    <div infinite-scroll='scroll()' infinite-scroll-distance='1'
      infinite-scroll-immediate-check='false' style='height: 500px;'></div>
    """
    el = angular.element(scroller)
    angular.element($document[0].body).append(el)

    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    $compile(el)(scope)
    $timeout.flush() # 'immediate' call is with $timeout ..., 0
    scope.scroll.should.not.have.been.called
    scroll(fakeWindow)
    scope.scroll.should.have.been.calledOnce

    el.remove()
    scope.$destroy()

  it 'does not trigger when disabled', ->
    scroller = """
    <div infinite-scroll='scroll()' infinite-scroll-distance='1'
      infinite-scroll-disabled='busy' style='height: 500px;'></div>
    """
    el = angular.element(scroller)
    angular.element($document[0].body).append(el)

    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    scope.busy = true
    $compile(el)(scope)
    scope.$digest()

    scroll(fakeWindow)
    scope.scroll.should.not.have.been.called

    el.remove()
    scope.$destroy()

  it 're-triggers after being re-enabled', ->
    scroller = """
    <div infinite-scroll='scroll()' infinite-scroll-distance='1'
      infinite-scroll-disabled='busy' style='height: 500px;'></div>
    """
    el = angular.element(scroller)
    angular.element($document[0].body).append(el)

    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    scope.busy = true
    $compile(el)(scope)
    scope.$digest()

    scroll(fakeWindow)

    $timeout.flush()
    scope.scroll.should.not.have.been.called

    scope.busy = false
    scope.$digest()

    $timeout.flush()
    scope.scroll.should.have.been.calledOnce

    el.remove()
    scope.$destroy()

  # Skipping the following two tests, because they don't work in PhantomJS
  # (we cannot set window size)
  it.skip 'only triggers when the page has been sufficiently scrolled down', ->
    scroller = """
    <div infinite-scroll='scroll()'
      infinite-scroll-distance='1' style='height: 10000px'></div>
    """
    el = angular.element(scroller)
    angular.element($document[0].body).append(el)

    fakeWindow[0].scroll 0, $document[0].body.offsetHeight - 2 * fakeWindow[0].innerHeight - 2

    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    $compile(el)(scope)
    scope.$digest()
    scroll(fakeWindow)

    $timeout.flush()
    scope.scroll.should.not.have.been.called

    fakeWindow[0].scroll 0, $document[0].body.offsetHeight - 2 * fakeWindow[0].innerHeight
    scroll(fakeWindow)

    $timeout.flush()
    scope.scroll.should.have.been.calledOnce

    el.remove()
    scope.$destroy()

  it.skip 'respects the infinite-scroll-distance attribute', ->
    scroller = """
    <div infinite-scroll='scroll()' infinite-scroll-distance='5' style='height: 10000px;'></div>
    """
    el = angular.element(scroller)
    angular.element($document[0].body).append(el)

    fakeWindow[0].scroll 0, $document[0].body.offsetHeight - 6 * fakeWindow[0].innerHeight - 2

    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    $compile(el)(scope)
    scope.$digest()
    scroll(fakeWindow)

    $timeout.flush()
    scope.scroll.should.not.have.been.called

    fakeWindow[0].scroll 0, $document[0].body.offsetHeight - 6 * fakeWindow[0].innerHeight
    scroll(fakeWindow)

    $timeout.flush()
    scope.scroll.should.have.been.calledOnce

    el.remove()
    scope.$destroy()
