loadGruntTasks = require 'load-grunt-tasks'
module.exports = (grunt) ->
  loadGruntTasks(grunt)

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    meta:
      banner: '/* <%= pkg.name %> - v<%= pkg.version %> - <%= grunt.template.today("yyyy-mm-dd") %> */\n'
    eslint:
      target: ['src', 'test']
    clean:
      options:
        force: true
      build: ["compile/**", "build/**"]
    babel:
      compile:
        files: [
          {
            expand: true
            cwd: 'src/'
            src: '**/*.js'
            dest: 'compile/'
            ext: '.js'
          }
        ]
        options:
          presets: ["es2015", "es2016", "stage-1"]
          plugins: ["add-module-exports", "transform-es2015-modules-umd"]
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
          configFile: 'test/protractor.conf.js'
          args:
            params:
              testThrottleValue: 500

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

  grunt.registerTask 'default', ['eslint', 'clean', 'babel', 'concat', 'uglify']
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
