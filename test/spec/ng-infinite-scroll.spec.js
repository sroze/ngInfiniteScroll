import fs from 'fs';
import mkdirp from 'mkdirp';

function retry(times, fn) {
  function doRetry() {
    for (let i = 0; i < (times - 1); i += 1) {
      try {
        return fn();
      } catch (e) {
        browser.restart();
      }
    }

    return fn();
  }

  return doRetry;
}

const containers = {
  window: {
    start: '',
    end: '',
    attr: '',
  },
  parent: {
    start: "<div id='parent' style='height: 50%; overflow: auto;'>",
    end: '</div>',
    attr: 'infinite-scroll-parent',
  },
  ancestor: {
    start: "<div id='ancestor' style='height: 50%; overflow: auto;'><div>",
    end: '</div></div>',
    attr: "infinite-scroll-container='\"#ancestor\"'",
  },
};

const getTemplate = (angularVersion, container, attrs, throttle) =>
  `<!doctype html>
<head>
  <style>
    html, body {
      height: 100%;
    }
  </style>
  <script src='http://ajax.googleapis.com/ajax/libs/angularjs/${angularVersion}/angular.min.js'></script>
  <script src="../../build/ng-infinite-scroll.js"></script>
  <script>
    angular.module('app', ['infinite-scroll'])
      .config(function ($provide) {
        $provide.value('THROTTLE_MILLISECONDS', ${throttle});
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
  ${containers[container].start}
    <div infinite-scroll="loadMore()" ${containers[container].attr} ${attrs}>
      <p ng-repeat='item in items track by $index'>
        {{$index}}
      </p>
    </div>
  ${containers[container].end}
</body>`
;

const getElementByIdScript = id => `document.getElementById('${id}')`;

const calculateChildrenHeightScript = id =>
  `[].concat.apply([], ${getElementByIdScript(id)}.childNodes)
  .map(function (el) { return el.offsetHeight ? el.offsetHeight : 0; })
  .reduce(function (cur, prev) { return prev + cur; }, 0)`
;

const scrollToBottomScript = function (container) {
  if (container === 'window') {
    return 'window.scrollTo(0, document.body.scrollHeight)';
  }
  const cont = getElementByIdScript(container);
  const height = calculateChildrenHeightScript(container);
  return `${cont}.scrollTop = ${height}`;
};

const scrollToLastScreenScript = function (container, offset) {
  // 2 * window.innerHeight means that the bottom of the screen should be
  // somewhere close to body height - window height. That means that the top of
  // the window is body height - 2 * window height.
  if (container === 'window') {
    return `window.scrollTo(0, document.body.scrollHeight - 2 * window.innerHeight + ${offset})`;
  }
  const cont = getElementByIdScript(container);
  const height = calculateChildrenHeightScript(container);
  return `${cont}.scrollTop = ${height} - 2 * ${cont}.offsetHeight + ${offset}`;
};

const collapseItemsScript =
  `var items = document.getElementsByTagName('p')
for (i = 0; i < items.length; ++i) {
  items[i].style.display = 'none'
}`;

const getItems = () => element.all(By.repeater('item in items'));

const tmpDir = '.tmp';
const pathToDocument = `${tmpDir}/index.html`;

const immediatelyOnBottom =
  'should be triggered immediately and when container is scrolled to the bottom';

const scrollCheckImmediateFalse =
  'does not trigger immediately when infinite-scroll-immediate-check is false';

function describeTests(angularVersion, container) {
  describe(`with ${container} as container`, function () {
    function replaceIndexFile(attrs, throttle) {
      mkdirp.sync(tmpDir);
      const rendered = getTemplate(angularVersion, container, attrs, throttle);
      return fs.writeFileSync(pathToDocument, rendered);
    }

    describe('without throttling', function () {
      const throttle = null;

      it(immediatelyOnBottom, function () {
        replaceIndexFile('', throttle);
        browser.get(pathToDocument);
        expect(getItems().count()).toBe(100);
        browser.driver.executeScript(scrollToBottomScript(container));
        return expect(getItems().count()).toBe(200);
      }
      );

      it(scrollCheckImmediateFalse, function () {
        replaceIndexFile("infinite-scroll-immediate-check='false'", throttle);
        browser.get(pathToDocument);
        expect(getItems().count()).toBe(0);
        element(By.id('force')).click();
        expect(getItems().count()).toBe(100);
        browser.driver.executeScript(scrollToBottomScript(container));
        return expect(getItems().count()).toBe(200);
      }
      );

      it('respects the disabled attribute', function () {
        replaceIndexFile("infinite-scroll-disabled='busy'", throttle);
        browser.get(pathToDocument);
        expect(getItems().count()).toBe(0);
        element(By.id('action')).click();
        return expect(getItems().count()).toBe(100);
      }
      );

      it('respects the infinite-scroll-distance attribute', function () {
        replaceIndexFile("infinite-scroll-distance='1'", throttle);
        browser.get(pathToDocument);
        expect(getItems().count()).toBe(100);
        browser.driver.executeScript(scrollToLastScreenScript(container, -20));
        expect(getItems().count()).toBe(100);
        browser.driver.executeScript(scrollToLastScreenScript(container, 20));
        return expect(getItems().count()).toBe(200);
      }
      );

      return describe('with an event handler', () =>

        it('calls the event handler on an event', function () {
          replaceIndexFile("infinite-scroll-listen-for-event='anEvent'", throttle);
          browser.get(pathToDocument);
          expect(getItems().count()).toBe(100);
          browser.driver.executeScript(collapseItemsScript);
          expect(getItems().count()).toBe(100);
          element(By.id('trigger')).click();
          return expect(getItems().count()).toBe(200);
        }
        )

      );
    }
    );

    return describe('with throttling', function () {
      const throttle = browser.params.testThrottleValue;

      it(immediatelyOnBottom, function () {
        replaceIndexFile('', throttle);
        browser.get(pathToDocument);
        expect(getItems().count()).toBe(100);
        browser.driver.executeScript(scrollToBottomScript(container));
        expect(getItems().count()).toBe(100);
        browser.sleep(throttle);
        return expect(getItems().count()).toBe(200);
      }
      );

      it(scrollCheckImmediateFalse, function () {
        replaceIndexFile("infinite-scroll-immediate-check='false'", throttle);
        browser.get(pathToDocument);
        expect(getItems().count()).toBe(0);
        element(By.id('force')).click();
        return expect(getItems().count()).toBe(100);
      }
      );

      it('respects the disabled attribute and is throttled when page loads', retry(16, function () {
        replaceIndexFile("infinite-scroll-disabled='busy'", throttle);
        browser.get(pathToDocument);
        expect(getItems().count()).toBe(0);
        element(By.id('action')).click();
        expect(getItems().count()).toBe(0);
        browser.sleep(throttle);
        return expect(getItems().count()).toBe(100);
      }));

      it('is not throttled when re-enabled if the throttle time has already elapsed', function () {
        replaceIndexFile("infinite-scroll-disabled='busy'", throttle);
        browser.get(pathToDocument);
        expect(getItems().count()).toBe(0);
        browser.sleep(throttle);
        element(By.id('action')).click();
        return expect(getItems().count()).toBe(100);
      }
      );

      it('respects the infinite-scroll-distance attribute', function () {
        replaceIndexFile("infinite-scroll-distance='1'", throttle);
        browser.get(pathToDocument);
        expect(getItems().count()).toBe(100);
        browser.driver.executeScript(scrollToLastScreenScript(container, 20));
        expect(getItems().count()).toBe(100);
        browser.sleep(throttle);
        return expect(getItems().count()).toBe(200);
      }
      );

      return describe('with an event handler', () =>
        it('calls the event handler on an event', retry(16, function () {
          replaceIndexFile("infinite-scroll-listen-for-event='anEvent'", throttle);
          browser.get(pathToDocument);
          expect(getItems().count()).toBe(100);
          browser.driver.executeScript(collapseItemsScript);
          expect(getItems().count()).toBe(100);
          element(By.id('trigger')).click();
          expect(getItems().count()).toBe(100);
          browser.sleep(100);
          return expect(getItems().count()).toBe(200);
        }))
      );
    }
    );
  });
}

function withAngular(angularVersion) {
  describe(`with Angular ${angularVersion}`, function () {
    ['window', 'ancestor', 'parent'].forEach(function (container) {
      describeTests(angularVersion, container);
    });
  });
}

describe('ng-infinite-scroll', function () {
  ['1.2.29', '1.3.20', '1.4.12', '1.5.8'].forEach(withAngular);
});
