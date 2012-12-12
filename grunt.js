module.exports = function(grunt) {
  grunt.loadNpmTasks('grunt-coffeelint');
  grunt.loadNpmTasks('grunt-coffee');
  grunt.loadNpmTasks('grunt-testacular');

  grunt.initConfig({
    pkg: '<json:package.json>',
    meta: {
      banner: '/*! <%= pkg.name %> - v<%= pkg.version %> - <%= grunt.template.today("yyyy-mm-dd") %> */'
    },
    coffeelint: {
      dist: {
        files: ['src/**/*.coffee'],
        options: {
          line_endings: {
            value: 'unix',
            level: 'error'
          },
          no_stand_alone_at: {
            level: 'error'
          }
        }
      }
    },
    coffee: {
      dist: {
        src: ['src/**/*.coffee'],
        dest: 'compile',
        options: {
          preserve_dirs: true,
          base_path: 'src'
        }
      }
    },
    lint: {
      all: ['grunt.js', 'compile/**/*.js']
    },
    concat: {
      dist: {
        src: ['<banner>', '<file_strip_banner:compile/test.js>', 'compile/other.js'],
        dest: 'build/lib.js'
      }
    },
    min: {
      dist: {
        src: ['<banner>', 'build/lib.js'],
        dest: 'build/lib.min.js'
      }
    },
    testacularServer: {
      local: {
        configFile: 'test/testacular.conf.js',
        autoWatch: true,
        browsers: ['Chrome', 'PhantomJS'],
        reporters: ['dots'],
        runnerPort: 9101,
        options: {
          keepalive: true
        }
      }
    }
  });

  grunt.registerTask('default', 'coffeelint coffee lint concat min');
  grunt.registerTask('test', 'testacularServer');
};
