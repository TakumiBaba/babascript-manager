'use strict'

fs = require 'fs'
os = require 'os'
path = require 'path'
async = require 'async'
cluster = require 'cluster'

module.exports = (grunt) ->

  pkg = grunt.file.readJSON 'package.json'

  require 'coffee-script'
  require 'coffee-errors'

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-stylus'
  grunt.loadNpmTasks 'grunt-contrib-jade'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-csslint'
  grunt.loadNpmTasks 'grunt-contrib-imagemin'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-htmlhint'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-simple-mocha'
  grunt.loadNpmTasks 'grunt-notify'

  grunt.registerTask "all", [
    'build',
    'test',
    'server',
    'watch'
  ]

  grunt.registerTask 'build', [
    'buildjs'
    'buildcss'
    'buildhtml'
    'buildstatic'
  ]

  grunt.registerTask 'default', [
    'build', 'test', 'watch'
  ]

  grunt.registerTask 'test', [
    'coffeelint:server'
    'simplemocha'
  ]

  grunt.registerTask 'buildjs', [
    'coffee:dist'
    'coffeelint:client'
    'uglify'
  ]

  grunt.registerTask 'buildcss', [
    'stylus:dist'
    'csslint:client'
    'stylus:release'
  ]

  grunt.registerTask 'buildhtml', [
    'jade:dist'
    'htmlhint:client'
    'jade:release'
  ]

  grunt.registerTask 'buildstatic', [
    'copy'
    'imagemin'
  ]

  grunt.registerTask 'restart', 'Graceful restart', ->
    done = @async()
    pids = JSON.parse fs.readFileSync (path.resolve './.pids'), 'utf-8'
    
    # if pids.length < os.cpus().length
    #   pids.push no for i in [pids.length...cpus]

    async.eachSeries pids, (pid, next) ->
      setTimeout ->
        try
          process.kill pid if pid
        catch e
          grunt.log.error e.message
        finally
          next()
      , grunt.config 'restart.interval'
    , done

  grunt.registerTask 'server', 'Start web server.', ->
    done = @async()
    pids = []

    if cluster.isMaster
      envs = grunt.config 'server.env'
      cpus = os.cpus().length

      process.on 'SIGINT', ->
        fs.unlinkSync grunt.config 'server.pid'
        process.exit 130

      cluster.on 'exit', (worker) ->
        for pid, i in pids when worker.process.pid is pid by -1
          pids.splice i, 1
          worker = cluster.fork envs
          pids.push worker.process.pid
          break
        fs.writeFileSync (grunt.config 'server.pid'), JSON.stringify pids

      # for i in [0...cpus]
      worker = cluster.fork envs
      pids.push worker.process.pid
      fs.writeFileSync (grunt.config 'server.pid'), JSON.stringify pids

    else
      process.env.PORT or= 3000
      process.env.NODE_ENV or= 'development'
      {server} = require grunt.config 'server.app'
      server.listen process.env.PORT, ->
        grunt.log.write "#{pkg.name} listening"
        grunt.log.write " on port #{process.env.PORT}"
        grunt.log.write " with mode #{process.env.NODE_ENV}"
        grunt.log.writeln " ##{process.pid}"

  grunt.initConfig

    pkg: pkg

    server:
      pid: path.resolve './.pids'
      app: path.resolve 'config', 'app'
      env: grunt.file.readJSON 'config/env.json'

    restart:
      interval: 600

    clean:
      dist: [ 'dist' ]
      release: [ 'public' ]

    copy:
      dist:
        files: [{
          expand: yes
          cwd: 'assets'
          src: [ '**/*', '!**/*.{coffee,styl,jade}' ]
          dest: 'dist'
        }]
      release:
        files: [{
          expand: yes
          cwd: 'assets'
          src: [ '**/*', '!**/*.{jpg,png,gif,coffee,styl,jade}' ]
          dest: 'public'
        }]

    imagemin:
      dist:
        files: [{
          expand: yes
          cwd: 'assets'
          src: [ '**/*.{jpg,png,gif}' ]
          dest: 'public'
        }]

    coffeelint:
      options:
        max_line_length:
          value: 79
        indentation:
          value: 2
        newlines_after_classes:
          level: 'error'
        no_empty_param_list:
          level: 'error'
        no_unnecessary_fat_arrows:
          level: 'ignore'
      client: 'assets/**/*.coffee'
      server: '{events,helper,models,config,tests}/**/*.coffee'

    csslint:
      options:
        import: 2
        'adjoining-classes': off
        'box-sizing': off
        'box-model': off
        'compatible-vendor-prefixes': off
        'floats': off
        'font-sizes': off
        'gradients': off
        'important': off
        'known-properties': off
        'outline-none': off
        'qualified-headings': off
        'regex-selectors': off
        'text-indent': off
        'unique-headings': off
        'universal-selector': off
        'unqualified-attributes': off
      client:
        files: [
          { expand: yes, cwd: 'dist', src: [ '**/*.styl' ] }
        ]

    htmlhint:
      options:
        'tag-pair': on
      client:
        files: [
          { expand: yes, cwd: 'dist', src: [ '**/*.html' ] }
        ]

    coffee:
      dist:
        options:
          sourceMap: no
          sourceMapDir: 'assets/'
        files: [{
          expand: yes
          cwd: 'assets'
          src: [ '**/*.coffee' ]
          dest: 'dist'
          ext: '.js'
        }]

    stylus:
      dist:
        options:
          compress: no
        files: [{
          expand: yes
          cwd: 'assets'
          src: [ '**/*.styl' ]
          dest: 'dist'
          ext: '.css'
        }]
      release:
        options:
          compress: yes
        files: [{
          expand: yes
          cwd: 'assets'
          src: [ '**/*.styl' ]
          dest: 'public'
          ext: '.css'
        }]

    jade:
      dist:
        options:
          pretty: yes
        files: [{
          expand: yes
          cwd: 'assets'
          src: [ '**/*.jade' ]
          dest: 'dist'
          ext: '.html'
        }]
      release:
        options:
          pretty: no
        files: [{
          expand: yes
          cwd: 'assets'
          src: [ '**/*.jade' ]
          dest: 'public'
          ext: '.html'
        }]

    uglify:
      release:
        files: [{
          expand: yes
          cwd: 'dist'
          src: [ '**/*.js', '!**/*.min.js' ]
          dest: 'public'
          ext: '.js'
        }]

    simplemocha:
      options:
        ui: 'bdd'
        reporter: 'spec'
        compilers: 'coffee:coffee-script'
        ignoreLeaks: no
      all:
        src: [ 'tests/**/*.coffee' ]

    watch:
      options:
        livereload: yes
        interrupt: yes
      static:
        tasks: [ 'buildstatic' ]
        files: [ 'assets/**/*', '!assets/**/*.{coffee,styl,jade}' ]
      coffee:
        tasks: [ 'buildjs' ]
        files: [ 'assets/**/*.coffee' ]
      stylus:
        tasks: [ 'buildcss' ]
        files: [ 'assets/**/*.styl' ]
      jade:
        tasks: [ 'buildhtml' ]
        files: [ 'assets/**/*.jade' ]
      test:
        tasks: [ 'test', 'restart' ]
        files: [
          '{events,helper,models,config,tests}/**/*.{js,coffee}'
        ]
