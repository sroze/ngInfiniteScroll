should = chai.should()

describe 'Testing with Angular and Mocha', ->
  it 'injects', inject ($rootScope, $compile) ->
    el = angular.element('<p>{{myvar}}</p>')
    $compile(el)($rootScope)
    $rootScope.myvar = 'test'
    el.html().should.equal '{{myvar}}'
    $rootScope.$apply()
    el.html().should.equal 'test'
