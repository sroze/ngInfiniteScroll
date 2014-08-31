should = chai.should()

describe 'Infinite Scroll', ->
  [$rootScope, $compile, $document, $timeout, fakeWindow] = [undefined]

  beforeEach ->
    module('infinite-scroll')

  beforeEach ->
    inject (_$rootScope_, _$compile_, _$window_, _$document_, _$timeout_) ->
      $rootScope = _$rootScope_
      $compile = _$compile_
      $window = _$window_
      $document = _$document_
      $timeout = _$timeout_
      fakeWindow = angular.element($window)
      # sinon.stub(fakeWindow, 'last').returns(fakeWindow)

  scroll = (container) ->
    event = $document[0].createEvent 'UIEvent'
    event.initUIEvent 'scroll', true, true, fakeWindow[0], 1

    container[0].dispatchEvent(event)

  tests =
    'triggers on scrolling': (scroller, container, injScope) ->
      el = angular.element(scroller)
      $document.append(el)

      isWindow = true unless container?
      if not isWindow
        container[0].style.height = '1000px'
      else
        fakeWindow[0].resizeTo(1000, 1000)
        container = fakeWindow

      scope = $rootScope.$new(true)
      for k, v of injScope
        scope[k] = v
      scope.scroll = sinon.spy()
      $compile(el)(scope)
      $timeout.flush() # 'immediate' call is with $timeout ..., 0

      scroll(container)

      scope.scroll.should.have.been.calledOnce

      el.remove()
      scope.$destroy()

    'triggers immediately by default': (scroller, container, injScope) ->
      el = angular.element(scroller)
      $document.append(el)

      isWindow = true unless container?
      if not isWindow
        container[0].style.height = '1000px'
      else
        fakeWindow[0].resizeTo(1000, 1000)
        container = fakeWindow

      scope = $rootScope.$new(true)
      for k, v of injScope
        scope[k] = v
      scope.scroll = sinon.spy()
      $compile(el)(scope)
      $timeout.flush() # 'immediate' call is with $timeout ..., 0

      scope.scroll.should.have.been.called

      el.remove()
      scope.$destroy()

    'does not trigger immediately when infinite-scroll-immediate-check is false': (scroller, container, injScope) ->
      el = angular.element(scroller)
      $document.append(el)

      isWindow = true unless container?
      if not isWindow
        container[0].style.height = '1000px'
      else
        fakeWindow[0].resizeTo(1000, 1000)
        container = fakeWindow

      scope = $rootScope.$new(true)
      for k, v of injScope
        scope[k] = v
      scope.scroll = sinon.spy()
      $compile(el)(scope)
      $timeout.flush() # 'immediate' call is with $timeout ..., 0
      scope.scroll.should.not.have.been.called
      scroll(container)
      scope.scroll.should.have.been.called

      el.remove()
      scope.$destroy()

    'does not trigger when disabled': (scroller, container, injScope) ->
      el = angular.element(scroller)
      $document.append(el)

      isWindow = true unless container?
      if not isWindow
        container[0].style.height = '1000px'
      else
        fakeWindow[0].resizeTo(1000, 1000)
        container = fakeWindow

      scope = $rootScope.$new(true)
      for k, v of injScope
        scope[k] = v
      scope.scroll = sinon.spy()
      scope.busy = true
      $compile(el)(scope)
      scope.$digest()

      scroll(container)
      scope.scroll.should.not.have.been.called

      el.remove()
      scope.$destroy()

    're-triggers after being re-enabled': (scroller, container, injScope) ->
      el = angular.element(scroller)
      $document.append(el)

      isWindow = true unless container?
      if not isWindow
        container[0].style.height = '1000px'
      else
        fakeWindow[0].resizeTo(1000, 1000)
        container = fakeWindow

      scope = $rootScope.$new(true)
      for k, v of injScope
        scope[k] = v
      scope.scroll = sinon.spy()
      scope.busy = true
      $compile(el)(scope)
      scope.$digest()

      scroll(container)
      scope.scroll.should.not.have.been.called

      scope.busy = false
      scope.$digest()
      scope.scroll.should.have.been.called

      el.remove()
      scope.$destroy()

    'only triggers when the container has been sufficiently scrolled down': (scroller, container, injScope) ->
      el = angular.element(scroller)
      $document.append(el)

      isWindow = true unless container?
      if not isWindow
        container[0].style.height = '1000px'
        container.style.position = 'relative'
        container.style.top = '7999px'
      else
        fakeWindow[0].resizeTo 1000, 1000
        fakeWindow[0].scroll 0, 7998
        container = fakeWindow

      scope = $rootScope.$new(true)
      for k, v of injScope
        scope[k] = v
      scope.scroll = sinon.spy()
      $compile(el)(scope)
      scope.$digest()
      scroll(fakeWindow)
      scope.scroll.should.not.have.been.called

      if not isWindow
        el.pageYOffset = 800
      else
        fakeWindow.scroll 0, 8000
        container = fakeWindow

      scroll(container)
      scope.scroll.should.have.been.calledOnce

      el.remove()
      scope.$destroy()

    'respects the infinite-scroll-distance attribute': (scroller, container, injScope) ->
      el = angular.element(scroller)
      $document.append(el)

      isWindow = true unless container?
      if not isWindow
        container.height 1000
        container.scrollTop = 3999
      else
        sinon.stub(fakeWindow, 'height').returns(1000)
        sinon.stub(fakeWindow, 'scrollTop').returns(3998)
        container = fakeWindow

      scope = $rootScope.$new(true)
      for k, v of injScope
        scope[k] = v
      scope.scroll = sinon.spy()
      $compile(el)(scope)
      scope.$digest()
      container.scroll()
      scope.scroll.should.not.have.been.called

      if not isWindow
        container.scrollTop = -> 4000
      else
        fakeWindow.scrollTop.returns(4000)
        container = fakeWindow

      container.scroll()
      scope.scroll.should.have.been.calledOnce

      el.remove()
      scope.$destroy()

  scrollers =
    'triggers on scrolling': ->
      """
      <div infinite-scroll='scroll()' style='height: 1000px'
        infinite-scroll-immediate-check='false'></div>
      """

    'triggers immediately by default': -> """
      <div infinite-scroll='scroll()' style='height: 1000px'></div>
      """

    'does not trigger immediately when infinite-scroll-immediate-check is false': -> """
      <div infinite-scroll='scroll()' infinite-scroll-distance='1'
        infinite-scroll-immediate-check='false' style='height: 500px;'></div>
      """

    'does not trigger when disabled': -> """
      <div infinite-scroll='scroll()' infinite-scroll-distance='1'
        infinite-scroll-disabled='busy' style='height: 500px;'></div>
      """

    're-triggers after being re-enabled': -> """
      <div infinite-scroll='scroll()' infinite-scroll-distance='1'
        infinite-scroll-disabled='busy' style='height: 500px;'></div>
      """

    'only triggers when the container has been sufficiently scrolled down': -> """
      <div infinite-scroll='scroll()'
        infinite-scroll-distance='1' style='height: 10000px'></div>
      """

    'respects the infinite-scroll-distance attribute': ->
      """
      <div infinite-scroll='scroll()' infinite-scroll-distance='5' style='height: 10000px;'></div>
      """

  for test, scroller of scrollers
    ((scroller, test) ->
      it "#{test}", -> tests[test](scroller(), null, {})

      # TODO: Those two tests are broken for container and parent because
      # I can't manage to properly simulate scrolling on the tests, but they
      # seem to work fine in practice.
      # brokenTests = [
      #   'respects the infinite-scroll-distance attribute'
      #   'only triggers when the container has been sufficiently scrolled down'
      # ]
      # if test in brokenTests
      #   return

      it "container: #{test}", ->
        cont = angular.element """
            <div id="parent" style="overflow: scroll;"></div>
          """
        sc = angular.element scroller()

        sc.attr "infinite-scroll-container", "elem"
        cont.append sc

        tests[test](cont, cont, {elem: cont})

      it "parent: #{test}", ->
        cont = angular.element """
            <div id="parent" style="overflow: scroll;"></div>
          """
        sc = angular.element scroller()

        sc.attr "infinite-scroll-parent", ""
        cont.append sc

        tests[test](cont, cont, {})
    ) scroller, test

