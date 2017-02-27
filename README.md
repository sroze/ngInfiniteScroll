[**Alternative project**: Angular Material's md-virtual-repeat](https://material.angularjs.org/latest/api/directive/mdVirtualRepeat)

[**Maintainer help needed**: I'm looking for fellows that are willing to help me maintain and improve this project.](https://github.com/sroze/ngInfiniteScroll/issues/267)

---

![logo](http://sroze.github.com/ngInfiniteScroll/images/logo-resized.png)

[![Build Status](https://travis-ci.org/sroze/ngInfiniteScroll.png?branch=master)](https://travis-ci.org/sroze/ngInfiniteScroll)

ngInfiniteScroll is a directive for [AngularJS](http://angularjs.org/) to evaluate an expression when the bottom of the directive's element approaches the bottom of the browser window, which can be used to implement infinite scrolling.

Demos
-----

Check out the running demos [at the ngInfiniteScroll web site](http://sroze.github.com/ngInfiniteScroll/demos.html).

Version Numbers
---------------

ngInfinite Scroll follows [semantic versioning](http://semver.org/).

Getting Started
---------------

 * Install it with:
   * [npm](https://www.npmjs.com) via `npm install --save ng-infinite-scroll`
 * Import ng-infinite-scroll and angular.
 
    ```js
    import angular from 'angular';
    import ngInfiniteScroll from 'ng-infinite-scroll';
    ```

 * Ensure that your application module specifies ngInfiniteScroll as a dependency:

    ```js
    const MODULE_NAME = 'myApplication';
    angular.module(MODULE_NAME, [ngInfiniteScroll]);
    export default MODULE_NAME;
    ```

 * Use the directive by specifying an `infinite-scroll` attribute on an element.

    ```html
    <div infinite-scroll="$ctrl.myPagingFunction()" infinite-scroll-distance="3"></div>
    ```

Note that the directive does not use the `ng` prefix, as that prefix is reserved for the core Angular module.

Detailed Documentation
----------------------

ngInfiniteScroll accepts several attributes to customize the behavior of the directive; detailed instructions can be found [on the ngInfiniteScroll web site](http://sroze.github.com/ngInfiniteScroll/documentation.html).

Ports
-----

If you use [AngularDart](https://github.com/angular/angular.dart), Juha Komulainen has [a port of the project](http://pub.dartlang.org/packages/ng_infinite_scroll) you can use.

License
-------

ngInfiniteScroll is licensed under the MIT license. See the LICENSE file for more details.

Testing
-------

ngInfiniteScroll uses Protractor for testing.
Note that you will need to have Chrome browser.

    npm install
    npm run test

Thank you very much @pomerantsev for your work on these Protractor tests.

Bower
-----

While a Bower repo has been created for legacy use, it is still recommened to
use npm and a module bundler (webpack, rollup, SystemJS) to use
`ng-infinite-scroll`.

To install using bower:

```
bower install ngInfiniteScroll
```
