############################### NOTE ################################
# Angular 1.2 allows us to be a lot more sophisticated about        #
# testing timeouts, waiting specific periods rather than just       #
# running all pending calls. However, we're using Angular 1.1, so   #
# we'll have to do with this limited set for now...                 #
# For more info, see: http://stackoverflow.com/questions/17541381   #
#####################################################################

should = chai.should()

describe 'Infinite Scroll Throttled to 200ms', ->
  [$rootScope, $compile, docWindow, $document, $timeout, fakeWindow, THROTTLE_MILLISECONDS, origJq] = [undefined]

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
      sinon.stub(fakeWindow, 'last').returns(fakeWindow)

      THROTTLE_MILLISECONDS = _THROTTLE_MILLISECONDS_

      origJq = angular.element
      angular.element = (first, args...) ->
        if first == $window
          fakeWindow
        else
          origJq(first, args...)

  afterEach ->
    angular.element = origJq

  it 'waits correct interval between calls to handler', ->
    scroller = """
    <div infinite-scroll='scroll()' style='height: 1000px'
      infinite-scroll-immediate-check='false'></div>
    """
    el = angular.element(scroller)
    $document.append(el)

    sinon.stub(fakeWindow, 'height').returns(1000)
    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    $compile(el)(scope)
    
    for i in [0..2] # so, three times
      fakeWindow.scroll()

    $timeout.flush()

    scope.scroll.should.have.been.calledTwice

    el.remove()
    scope.$destroy()

  it "doesn't duplicate calls", ->
    scroller = """
    <div infinite-scroll='scroll()' style='height: 1000px'
      infinite-scroll-immediate-check='false'></div>
    """
    el = angular.element(scroller)
    $document.append(el)

    sinon.stub(fakeWindow, 'height').returns(1000)
    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    $compile(el)(scope)
    
    fakeWindow.scroll()

    $timeout.flush()

    scope.scroll.should.have.been.called.twice

    el.remove()
    scope.$destroy()

  it 'triggers immediately by default', ->
    scroller = """
    <div infinite-scroll='scroll()' style='height: 1000px'></div>
    """
    el = angular.element(scroller)
    $document.append(el)

    sinon.stub(fakeWindow, 'height').returns(1000)
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
    $document.append(el)

    sinon.stub(fakeWindow, 'height').returns(1000)
    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    $compile(el)(scope)
    $timeout.flush() # 'immediate' call is with $timeout ..., 0
    scope.scroll.should.not.have.been.called
    fakeWindow.scroll()
    scope.scroll.should.have.been.calledOnce

    el.remove()
    scope.$destroy()

  it 'does not trigger when disabled', ->
    scroller = """
    <div infinite-scroll='scroll()' infinite-scroll-distance='1'
      infinite-scroll-disabled='busy' style='height: 500px;'></div>
    """
    el = angular.element(scroller)
    $document.append(el)

    sinon.stub(fakeWindow, 'height').returns(1000)
    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    scope.busy = true
    $compile(el)(scope)
    scope.$digest()

    fakeWindow.scroll()
    scope.scroll.should.not.have.been.called

    el.remove()
    scope.$destroy()

  it 're-triggers after being re-enabled', ->
    scroller = """
    <div infinite-scroll='scroll()' infinite-scroll-distance='1'
      infinite-scroll-disabled='busy' style='height: 500px;'></div>
    """
    el = angular.element(scroller)
    $document.append(el)

    sinon.stub(fakeWindow, 'height').returns(1000)
    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    scope.busy = true
    $compile(el)(scope)
    scope.$digest()

    fakeWindow.scroll()

    $timeout.flush()
    scope.scroll.should.not.have.been.called

    scope.busy = false
    scope.$digest()

    $timeout.flush()
    scope.scroll.should.have.been.calledOnce

    el.remove()
    scope.$destroy()

  it 'only triggers when the page has been sufficiently scrolled down', ->
    scroller = """
    <div infinite-scroll='scroll()'
      infinite-scroll-distance='1' style='height: 10000px'></div>
    """
    el = angular.element(scroller)
    $document.append(el)

    sinon.stub(fakeWindow, 'height').returns(1000)
    sinon.stub(fakeWindow, 'scrollTop').returns(7998)

    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    $compile(el)(scope)
    scope.$digest()
    fakeWindow.scroll()

    $timeout.flush()
    scope.scroll.should.not.have.been.called

    fakeWindow.scrollTop.returns(8000)
    fakeWindow.scroll()

    $timeout.flush()
    scope.scroll.should.have.been.calledOnce

    el.remove()
    scope.$destroy()

  it 'respects the infinite-scroll-distance attribute', ->
    scroller = """
    <div infinite-scroll='scroll()' infinite-scroll-distance='5' style='height: 10000px;'></div>
    """
    el = angular.element(scroller)
    $document.append(el)

    sinon.stub(fakeWindow, 'height').returns(1000)
    sinon.stub(fakeWindow, 'scrollTop').returns(3998)

    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    $compile(el)(scope)
    scope.$digest()
    fakeWindow.scroll()

    $timeout.flush()
    scope.scroll.should.not.have.been.called

    fakeWindow.scrollTop.returns(4000)
    fakeWindow.scroll()

    $timeout.flush()
    scope.scroll.should.have.been.calledOnce

    el.remove()
    scope.$destroy()