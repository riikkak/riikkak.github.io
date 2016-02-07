module.exports = (grunt) ->
  grunt.initConfig
    bower:
      install:
        options:
          targetDir: './dist'
          layout: (type, component) ->
            type
          install: true
          verbose: false
          cleanup: true
    copy:
      bootstrap:
        files: [
          { expand: true, cwd: 'less/bootstrap', src: ['bootstrap.less'], dest: 'tmp/' }
        ]
    clean: ['tmp']
    concurrent:
      serve:
        options:
          logConcurrentOutput: true
        tasks: ['watch', 'exec:serve']
    exec:
      build:
        cmd: 'export LC_CTYPE="C_BINARY" && bundle exec jekyll build'
      serve:
        cmd: 'export LC_CTYPE="C_BINARY" && bundle exec jekyll serve --watch -I'
    less:
      blogTheme:
        options:
          compress: false
          paths: ['less/blog', 'tmp', 'less/bootstrap']
        files:
          'themes/blog/css/styles.css': ['less/blog/main.less']
      englishTheme:
        options:
          compress: false
          paths: ['less/english', 'tmp', 'less/bootstrap']
        files:
          'themes/english/css/styles.css': ['less/english/main.less']
      swedishTheme:
        options:
          compress: false
          paths: ['less/swedish', 'tmp', 'less/bootstrap']
        files:
          'themes/swedish/css/styles.css': ['less/swedish/main.less']
    recess:
      minifyBlog:
        options:
          compress: true
        src: 'themes/blog/css/styles.css'
        dest: 'themes/blog/css/styles.min.css'
      minifyEnglish:
        options:
          compress: true
        src: 'themes/english/css/styles.css'
        dest: 'themes/english/css/styles.min.css'
      minifySwedish:
        options:
          compress: true
        src: 'themes/swedish/css/styles.css'
        dest: 'themes/swedish/css/styles.min.css'
    watch:
      common:
        files: ['less/common.less']
        tasks: ['dist-css']
        options:
          livereload: true
      blogTheme:
        files: ['less/blog/*.less']
        tasks: ['build-blog']
        options:
          livereload: true
      englishTheme:
        files: ['less/english/*.less']
        tasks: ['build-english']
        options:
          livereload: true
      swedishTheme:
        files: ['less/swedish/*.less']
        tasks: ['build-swedish']
        options:
          livereload: true

  grunt.loadNpmTasks('grunt-bower-task')
  grunt.loadNpmTasks('grunt-concurrent')
  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks('grunt-contrib-less')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-exec')
  grunt.loadNpmTasks('grunt-recess')

  grunt.registerTask('build-blog', ['copy', 'less:blogTheme', 'recess:minifyBlog', 'clean'])
  grunt.registerTask('build-english', ['copy', 'less:englishTheme', 'recess:minifyEnglish', 'clean'])
  grunt.registerTask('build-swedish', ['copy', 'less:swedishTheme', 'recess:minifySwedish', 'clean'])
  grunt.registerTask('minify-css', ['recess:minifyBlog', 'recess:minifyEnglish', 'recess:minifySwedish'])
  grunt.registerTask('dist-css', ['copy', 'less', 'minify-css', 'clean'])
  grunt.registerTask('default', ['dist-css', 'exec:build'])
  grunt.registerTask('serve', ['concurrent'])
