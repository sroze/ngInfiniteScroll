fs = require "fs"
mkdirp = require "mkdirp"

getTemplate = (angularVersion, container, attrs, throttle) ->
  """
    <!doctype html>
    <head>
      <style>
        html, body {
          height: 100%;
        }
      </style>
      <script src='http://ajax.googleapis.com/ajax/libs/angularjs/#{angularVersion}/angular.min.js'></script>
      <script src="../../build/ng-infinite-scroll.js"></script>
      <script>
        angular.module('app', ['infinite-scroll'])
          .config(function ($provide) {
            $provide.value('THROTTLE_MILLISECONDS', #{throttle});
          })
          .run(function ($rootScope) {
            $rootScope.items = [];
            $rootScope.loadMore = function () {
              [].push.apply($rootScope.items, new Array(100));
            };

            $rootScope.busy = true;

            $rootScope.enable = function () {
              $rootScope.busy = false;
            };

            $rootScope.triggerEvent = function () {
              $rootScope.$emit('anEvent');
            };
          });
      </script>
    </head>
    <body ng-app="app">
      <a id="action" ng-click="enable()">Enable</a>
      <a id="force" ng-click="loadMore()">Force</a>
      <a id="trigger" ng-click="triggerEvent()">Trigger</a>
      #{containers[container].start}
        <div infinite-scroll="loadMore()" #{containers[container].attr} #{attrs}>
          <p ng-repeat='item in items track by $index'>
            {{$index}}
          </p>
        </div>
      #{containers[container].end}
    </body>
  """

containers =
  window:
    start: ""
    end: ""
    attr: ""
  parent:
    start: "<div id='parent' style='height: 50%; overflow: auto;'>"
    end: "</div>"
    attr: "infinite-scroll-parent"
  ancestor:
    start: "<div id='ancestor' style='height: 50%; overflow: auto;'><div>"
    end: "</div></div>"
    attr: "infinite-scroll-container='\"#ancestor\"'"

getElementByIdScript = (id) ->
  "document.getElementById('#{id}')"

calculateChildrenHeightScript = (id) ->
  """
    [].concat.apply([], #{getElementByIdScript(id)}.childNodes)
      .map(function (el) { return el.offsetHeight ? el.offsetHeight : 0; })
      .reduce(function (cur, prev) { return prev + cur; }, 0)
  """

scrollToBottomScript = (container) ->
  if container is "window"
    "window.scrollTo(0, document.body.scrollHeight)"
  else
    "#{getElementByIdScript(container)}.scrollTop = #{calculateChildrenHeightScript(container)}"

scrollToLastScreenScript = (container, offset) ->
  # 2 * window.innerHeight means that the bottom of the screen should be somewhere close to
  # body height - window height. That means that the top of the window is body height - 2 * window height.
  if container is "window"
    "window.scrollTo(0, document.body.scrollHeight - 2 * window.innerHeight + #{offset})"
  else
    """
      #{getElementByIdScript(container)}.scrollTop =
        #{calculateChildrenHeightScript(container)} - 2 * #{getElementByIdScript(container)}.offsetHeight + #{offset}
    """

collapseItemsScript = (container) ->
  """
  var items = document.getElementsByTagName('p')
  for (i = 0; i < items.length; ++i) {
    items[i].style.display = 'none'
  }
  """

getItems = ->
  element.all(By.repeater "item in items")

tmpDir = ".tmp"
pathToDocument = "#{tmpDir}/index.html"

describe "ng-infinite-scroll", ->
  for angularVersion in ["1.2.0", "1.3.4"]
    describe "with Angular #{angularVersion}", ->
      for container in ["window", "ancestor", "parent"]
        describe "with #{container} as container", ->

          replaceIndexFile = (attrs, throttle) ->
            mkdirp tmpDir
            fs.writeFileSync(pathToDocument, getTemplate(angularVersion, container, attrs, throttle))

          describe "without throttling", ->

            throttle = null

            it "should be triggered immediately and when container is scrolled to the bottom", ->
              replaceIndexFile "", throttle
              browser.get pathToDocument
              expect(getItems().count()).toBe 100
              browser.driver.executeScript(scrollToBottomScript(container))
              expect(getItems().count()).toBe 200

            it "does not trigger immediately when infinite-scroll-immediate-check is false", ->
              replaceIndexFile "infinite-scroll-immediate-check='false'", throttle
              browser.get pathToDocument
              expect(getItems().count()).toBe 0
              element(By.id("force")).click()
              expect(getItems().count()).toBe 100
              browser.driver.executeScript(scrollToBottomScript(container))
              expect(getItems().count()).toBe 200

            it "respects the disabled attribute", ->
              replaceIndexFile "infinite-scroll-disabled='busy'", throttle
              browser.get pathToDocument
              expect(getItems().count()).toBe 0
              element(By.id("action")).click()
              expect(getItems().count()).toBe 100

            it "respects the infinite-scroll-distance attribute", ->
              replaceIndexFile "infinite-scroll-distance='1'", throttle
              browser.get pathToDocument
              expect(getItems().count()).toBe 100
              browser.driver.executeScript(scrollToLastScreenScript(container, -20))
              expect(getItems().count()).toBe 100
              browser.driver.executeScript(scrollToLastScreenScript(container, 20))
              expect(getItems().count()).toBe 200

            describe "with an event handler", ->

              it "calls the event handler on an event", ->
                replaceIndexFile "infinite-scroll-listen-for-event='anEvent'", throttle
                browser.get pathToDocument
                expect(getItems().count()).toBe 100
                browser.driver.executeScript(collapseItemsScript(container))
                expect(getItems().count()).toBe 100
                element(By.id("trigger")).click()
                expect(getItems().count()).toBe 200

          describe "with throttling", ->

            throttle = browser.params.testThrottleValue

            it "should be triggered immediately and when container is scrolled to the bottom", ->
              replaceIndexFile "", throttle
              browser.get pathToDocument
              expect(getItems().count()).toBe 100
              browser.driver.executeScript(scrollToBottomScript(container))
              expect(getItems().count()).toBe 100
              browser.sleep(throttle)
              expect(getItems().count()).toBe 200

            it "does not trigger immediately when infinite-scroll-immediate-check is false", ->
              replaceIndexFile "infinite-scroll-immediate-check='false'", throttle
              browser.get pathToDocument
              expect(getItems().count()).toBe 0
              element(By.id("force")).click()
              expect(getItems().count()).toBe 100

            it "respects the disabled attribute and is throttled when page loads", ->
              replaceIndexFile "infinite-scroll-disabled='busy'", throttle
              browser.get pathToDocument
              expect(getItems().count()).toBe 0
              element(By.id("action")).click()
              expect(getItems().count()).toBe 0
              browser.sleep(throttle)
              expect(getItems().count()).toBe 100

            it "is not throttled when re-enabled if the throttle time has already elapsed", ->
              replaceIndexFile "infinite-scroll-disabled='busy'", throttle
              browser.get pathToDocument
              expect(getItems().count()).toBe 0
              browser.sleep(throttle)
              element(By.id("action")).click()
              expect(getItems().count()).toBe 100

            it "respects the infinite-scroll-distance attribute", ->
              replaceIndexFile "infinite-scroll-distance='1'", throttle
              browser.get pathToDocument
              expect(getItems().count()).toBe 100
              browser.driver.executeScript(scrollToLastScreenScript(container, 20))
              expect(getItems().count()).toBe 100
              browser.sleep(throttle)
              expect(getItems().count()).toBe 200

            describe "with an event handler", ->

              it "calls the event handler on an event", ->
                replaceIndexFile "infinite-scroll-listen-for-event='anEvent'", throttle
                browser.get pathToDocument
                expect(getItems().count()).toBe 100
                browser.driver.executeScript(collapseItemsScript(container))
                expect(getItems().count()).toBe 100
                element(By.id("trigger")).click()
                expect(getItems().count()).toBe 100
                browser.sleep(throttle)
                expect(getItems().count()).toBe 200
