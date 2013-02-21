should = chai.should()

describe 'Infinite Scroll', ->
  beforeEach ->
    module 'infinite-scroll'

  it 'triggers on scrolling', inject ($rootScope, $compile, docWindow, $document) ->
    scroller = """
    <div infinite-scroll='scroll()' infinite-scroll-distance='1'></div>
    """
    el = angular.element(scroller)
    $document.append(el)

    sinon.stub(docWindow, 'height').returns(1000)
    sinon.stub($document, 'height').returns(500)
    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    $compile(el)(scope)
    docWindow.scroll()
    scope.scroll.should.have.been.called

    el.remove()
    scope.$destroy()

  it 'triggers right away when infinite-scroll-immediate-check is on', inject ($rootScope, $compile, docWindow, $document) ->
    scroller = """
    <div infinite-scroll='scroll()' infinite-scroll-distance='1'
      infinite-scroll-immediate-check='true'></div>
    """
    el = angular.element(scroller)
    $document.append(el)

    sinon.stub(docWindow, 'height').returns(1000)
    sinon.stub($document, 'height').returns(500)
    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    $compile(el)(scope)
    scope.scroll.should.have.been.called

    el.remove()
    scope.$destroy()

  it 'does not trigger when disabled', inject ($rootScope, $compile, docWindow, $document) ->
    scroller = """
    <div infinite-scroll='scroll()' infinite-scroll-distance='1'
      infinite-scroll-disabled='busy'></div>
    """
    el = angular.element(scroller)
    $document.append(el)

    sinon.stub(docWindow, 'height').returns(1000)
    sinon.stub($document, 'height').returns(500)
    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    scope.busy = true
    $compile(el)(scope)
    scope.$digest()

    docWindow.scroll()
    scope.scroll.should.not.have.been.called

    el.remove()
    scope.$destroy()

  it 're-triggers after being re-enabled', inject ($rootScope, $compile, docWindow, $document) ->
    scroller = """
    <div infinite-scroll='scroll()' infinite-scroll-distance='1'
      infinite-scroll-disabled='busy'></div>
    """
    el = angular.element(scroller)
    $document.append(el)

    sinon.stub(docWindow, 'height').returns(1000)
    sinon.stub($document, 'height').returns(500)
    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    scope.busy = true
    $compile(el)(scope)
    scope.$digest()

    docWindow.scroll()
    scope.scroll.should.not.have.been.called

    scope.busy = false
    scope.$digest()
    scope.scroll.should.have.been.called

    el.remove()
    scope.$destroy()

  it 'only triggers when the page has been sufficiently scrolled down', inject ($rootScope, $compile, docWindow, $document) ->
    scroller = """
    <div infinite-scroll='scroll()' infinite-scroll-distance='1'></div>
    """
    el = angular.element(scroller)
    $document.append(el)

    sinon.stub(docWindow, 'height').returns(1000)
    sinon.stub($document, 'height').returns(10000)
    sinon.stub(docWindow, 'scrollTop').returns(7999)

    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    $compile(el)(scope)
    scope.$digest()
    docWindow.scroll()
    scope.scroll.should.not.have.been.called

    docWindow.scrollTop.returns(8000)
    docWindow.scroll()
    scope.scroll.should.have.been.called

    el.remove()
    scope.$destroy()

  it 'respects the infinite-scroll-distance attribute', inject ($rootScope, $compile, docWindow, $document) ->
    scroller = """
    <div infinite-scroll='scroll()' infinite-scroll-distance='5'></div>
    """
    el = angular.element(scroller)
    $document.append(el)

    sinon.stub(docWindow, 'height').returns(1000)
    sinon.stub($document, 'height').returns(10000)
    sinon.stub(docWindow, 'scrollTop').returns(3999)

    scope = $rootScope.$new(true)
    scope.scroll = sinon.spy()
    $compile(el)(scope)
    scope.$digest()
    docWindow.scroll()
    scope.scroll.should.not.have.been.called

    docWindow.scrollTop.returns(4000)
    docWindow.scroll()
    scope.scroll.should.have.been.called

    el.remove()
    scope.$destroy()
