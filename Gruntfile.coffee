module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-jshint'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-testacular'

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    meta:
      banner: '/* <%= pkg.name %> - v<%= pkg.version %> - <%= grunt.template.today("yyyy-mm-dd") %> */\n'
    coffeelint:
      src: 'src/**/*.coffee'
      options:
        line_endings:
          value: 'unix'
          level: 'error'
        no_stand_alone_at:
          level: 'error'
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
        dest: 'build/lib.js'
    jshint:
      beforeconcat: ['compile/**/*.js']
      afterconcat: 'build/lib.js'
    uglify:
      options:
        banner: '<%= meta.banner %>'
      dist:
        src: ['build/lib.js']
        dest: 'build/lib.min.js'
    testacularServer:
      local:
        configFile: 'test/testacular.conf.js'
        autoWatch: true
        browsers: ['Chrome', 'PhantomJS']
        reporters: ['dots']
        runnerPort: 9101
        options:
          keepalive: true

  grunt.registerTask 'default', ['coffeelint', 'coffee', 'jshint:beforeconcat', 'concat', 'jshint:afterconcat', 'uglify']
  grunt.registerTask 'test', ['testacularServer']
