import angular from 'angular';

const MODULE_NAME = 'infinite-scroll';

angular.module(MODULE_NAME, [])
  .value('THROTTLE_MILLISECONDS', null)
  .directive('infiniteScroll', [
    '$rootScope', '$window', '$interval', 'THROTTLE_MILLISECONDS',
    ($rootScope, $window, $interval, THROTTLE_MILLISECONDS) =>
  ({
    scope: {
      infiniteScroll: '&',
      infiniteScrollContainer: '=',
      infiniteScrollDistance: '=',
      infiniteScrollDisabled: '=',
      infiniteScrollUseDocumentBottom: '=',
      infiniteScrollListenForEvent: '@',
    },

    link(scope, elem, attrs) {
      const windowElement = angular.element($window);

      let scrollDistance = null;
      let scrollEnabled = null;
      let checkWhenEnabled = null;
      let container = null;
      let immediateCheck = true;
      let useDocumentBottom = false;
      let unregisterEventListener = null;
      let checkInterval = false;

      const height = function (elem) {
        elem = elem[0] || elem;

        if (isNaN(elem.offsetHeight)) { return elem.document.documentElement.clientHeight; } else { return elem.offsetHeight; }
      };

      const offsetTop = function (elem) {
        if (!elem[0].getBoundingClientRect || elem.css('none')) {
          return;
        }

        return elem[0].getBoundingClientRect().top + pageYOffset(elem);
      };

      var pageYOffset = function (elem) {
        elem = elem[0] || elem;

        if (isNaN(window.pageYOffset)) { return elem.document.documentElement.scrollTop; } else { return elem.ownerDocument.defaultView.pageYOffset; }
      };

      // infinite-scroll specifies a function to call when the window,
      // or some other container specified by infinite-scroll-container,
      // is scrolled within a certain range from the bottom of the
      // document. It is recommended to use infinite-scroll-disabled
      // with a boolean that is set to true when the function is
      // called in order to throttle the function call.
      let handler = function () {
        if (container === windowElement) {
          var containerBottom = height(container) + pageYOffset(container[0].document.documentElement);
          var elementBottom = offsetTop(elem) + height(elem);
        } else {
          var containerBottom = height(container);
          let containerTopOffset = 0;
          if (offsetTop(container) !== undefined) {
            containerTopOffset = offsetTop(container);
          }
          var elementBottom = offsetTop(elem) - containerTopOffset + height(elem);
        }

        if (useDocumentBottom) {
          var elementBottom = height((elem[0].ownerDocument || elem[0].document).documentElement);
        }

        const remaining = elementBottom - containerBottom;
        const shouldScroll = remaining <= height(container) * scrollDistance + 1;

        if (shouldScroll) {
          checkWhenEnabled = true;

          if (scrollEnabled) {
            if (scope.$$phase || $rootScope.$$phase) {
              return scope.infiniteScroll();
            } else {
              return scope.$apply(scope.infiniteScroll);
            }
          }
        } else {
          if (checkInterval) { $interval.cancel(checkInterval); }
          return checkWhenEnabled = false;
        }
      };

      // The optional THROTTLE_MILLISECONDS configuration value specifies
      // a minimum time that should elapse between each call to the
      // handler. N.b. the first call the handler will be run
      // immediately, and the final call will always result in the
      // handler being called after the `wait` period elapses.
      // A slimmed down version of underscore's implementation.
      const throttle = function (func, wait) {
        let timeout = null;
        let previous = 0;
        const later = function () {
          previous = new Date().getTime();
          $interval.cancel(timeout);
          timeout = null;
          return func.call();
        };

        return (function () {
          const now = new Date().getTime();
          const remaining = wait - (now - previous);
          if (remaining <= 0) {
            $interval.cancel(timeout);
            timeout = null;
            previous = now;
            return func.call();
          } else if (!timeout) {
            return timeout = $interval(later, remaining, 1);
          }
        });
      };

      if (THROTTLE_MILLISECONDS != null) {
        handler = throttle(handler, THROTTLE_MILLISECONDS);
      }

      scope.$on('$destroy', function () {
        container.unbind('scroll', handler);
        if (unregisterEventListener != null) {
          unregisterEventListener();
          unregisterEventListener = null;
        }
        if (checkInterval) {
          return $interval.cancel(checkInterval);
        }
      });

      // infinite-scroll-distance specifies how close to the bottom of the page
      // the window is allowed to be before we trigger a new scroll. The value
      // provided is multiplied by the container height; for example, to load
      // more when the bottom of the page is less than 3 container heights away,
      // specify a value of 3. Defaults to 0.
      const handleInfiniteScrollDistance = v => scrollDistance = parseFloat(v) || 0;

      scope.$watch('infiniteScrollDistance', handleInfiniteScrollDistance);
      // If I don't explicitly call the handler here, tests fail. Don't know why yet.
      handleInfiniteScrollDistance(scope.infiniteScrollDistance);

      // infinite-scroll-disabled specifies a boolean that will keep the
      // infnite scroll function from being called; this is useful for
      // debouncing or throttling the function call. If an infinite
      // scroll is triggered but this value evaluates to true, then
      // once it switches back to false the infinite scroll function
      // will be triggered again.
      const handleInfiniteScrollDisabled = function (v) {
        scrollEnabled = !v;
        if (scrollEnabled && checkWhenEnabled) {
          checkWhenEnabled = false;
          return handler();
        }
      };

      scope.$watch('infiniteScrollDisabled', handleInfiniteScrollDisabled);
      // If I don't explicitly call the handler here, tests fail. Don't know why yet.
      handleInfiniteScrollDisabled(scope.infiniteScrollDisabled);

      // use the bottom of the document instead of the element's bottom.
      // This useful when the element does not have a height due to its
      // children being absolute positioned.
      const handleInfiniteScrollUseDocumentBottom = v => useDocumentBottom = v;

      scope.$watch('infiniteScrollUseDocumentBottom', handleInfiniteScrollUseDocumentBottom);
      handleInfiniteScrollUseDocumentBottom(scope.infiniteScrollUseDocumentBottom);

      // infinite-scroll-container sets the container which we want to be
      // infinte scrolled, instead of the whole window. Must be an
      // Angular or jQuery element, or, if jQuery is loaded,
      // a jQuery selector as a string.
      const changeContainer = function (newContainer) {
        if (container != null) {
          container.unbind('scroll', handler);
        }

        container = newContainer;
        if (newContainer != null) {
          return container.bind('scroll', handler);
        }
      };

      changeContainer(windowElement);

      if (scope.infiniteScrollListenForEvent) {
        unregisterEventListener = $rootScope.$on(scope.infiniteScrollListenForEvent, handler);
      }

      const handleInfiniteScrollContainer = function (newContainer) {
        // TODO: For some reason newContainer is sometimes null instead
        // of the empty array, which Angular is supposed to pass when the
        // element is not defined
        // (https://github.com/sroze/ngInfiniteScroll/pull/7#commitcomment-5748431).
        // So I leave both checks.
        if ((!(newContainer != null)) || newContainer.length === 0) {
          return;
        }

        if (newContainer.nodeType && newContainer.nodeType === 1) {
          newContainer = angular.element(newContainer);
        } else if (typeof newContainer.append === 'function') {
          newContainer = angular.element(newContainer[newContainer.length - 1]);
        } else if (typeof newContainer === 'string') {
          newContainer = angular.element(document.querySelector(newContainer));
        }

        if (newContainer != null) {
          return changeContainer(newContainer);
        } else {
          throw new Error('invalid infinite-scroll-container attribute.');
        }
      };

      scope.$watch('infiniteScrollContainer', handleInfiniteScrollContainer);
      handleInfiniteScrollContainer(scope.infiniteScrollContainer || []);

      // infinite-scroll-parent establishes this element's parent as the
      // container infinitely scrolled instead of the whole window.
      if (attrs.infiniteScrollParent != null) {
        changeContainer(angular.element(elem.parent()));
      }

      // infinte-scoll-immediate-check sets whether or not run the
      // expression passed on infinite-scroll for the first time when the
      // directive first loads, before any actual scroll.
      if (attrs.infiniteScrollImmediateCheck != null) {
        immediateCheck = scope.$eval(attrs.infiniteScrollImmediateCheck);
      }

      return checkInterval = $interval((function () {
        if (immediateCheck) {
          handler();
        }
        return $interval.cancel(checkInterval);
      }));
    },
  }),

  ]);

export default MODULE_NAME;
