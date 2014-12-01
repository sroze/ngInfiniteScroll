module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-protractor-runner'

  sauceUser = 'pomerantsevp'
  sauceKey = '497ab04e-f31b-4a7b-9b18-ae3fbe023222'

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    meta:
      banner: '/* <%= pkg.name %> - v<%= pkg.version %> - <%= grunt.template.today("yyyy-mm-dd") %> */\n'
    coffeelint:
      src: 'src/**/*.coffee'
      options:
        max_line_length:
          level: 'ignore'
        line_endings:
          value: 'unix'
          level: 'error'
        no_stand_alone_at:
          level: 'error'
    clean:
      options:
        force: true
      build: ["compile/**", "build/**"]
    coffee:
      compile:
        files: [
          {
            expand: true
            cwd: 'src/'
            src: '**/*.coffee'
            dest: 'compile/'
            ext: '.js'
          }
        ],
        options:
          bare: true
    concat:
      options:
        banner: '<%= meta.banner %>'
      dist:
        src: 'compile/**/*.js'
        dest: 'build/ng-infinite-scroll.js'
    uglify:
      options:
        banner: '<%= meta.banner %>'
      dist:
        src: ['build/ng-infinite-scroll.js']
        dest: 'build/ng-infinite-scroll.min.js'
    connect:
      testserver:
        options:
          port: 8000
          hostname: '0.0.0.0'
          middleware: (connect, options) ->
            base = if Array.isArray(options.base) then options.base[options.base.length - 1] else options.base
            [connect.static(base)]
    protractor:
      local:
        options:
          configFile: 'test/protractor-local.conf.js'
          args:
            params:
              testThrottleValue: 500
      travis:
        options:
          configFile: 'test/protractor-travis.conf.js'
          args:
            params:
              # When using Sauce Connect, we should use a large timeout
              # since everything is generally much slower than when testing locally.
              testThrottleValue: 10000
            sauceUser: sauceUser
            sauceKey: sauceKey

  grunt.registerTask 'webdriver', () ->
    done = this.async()
    p = require('child_process').spawn('node', ['node_modules/protractor/bin/webdriver-manager', 'update'])
    p.stdout.pipe(process.stdout)
    p.stderr.pipe(process.stderr)
    p.on 'exit', (code) ->
      if code isnt 0 then grunt.fail.warn('Webdriver failed to update')
      done()

  grunt.registerTask 'sauce-connect', () ->
    done = this.async()
    require('sauce-connect-launcher')({username: sauceUser, accessKey: sauceKey}, (err, sauceConnectProcess) ->
      if err then console.error(err.message)
      else done()
    )

  grunt.registerTask 'default', ['coffeelint', 'clean', 'coffee', 'concat', 'uglify']
  grunt.registerTask 'test:protractor-local', [
    'default',
    'webdriver',
    'connect:testserver',
    'protractor:local'
  ]

  grunt.registerTask 'test:protractor-travis', [
    'connect:testserver',
    'sauce-connect',
    'protractor:travis'
  ]
