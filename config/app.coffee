# Dependency

fs = require 'fs'
AWS = require 'aws-sdk'
path = require 'path'
http = require 'http'
debug = require('debug')('coah')
express = require 'express'
passport = require "passport"
mongoose = require 'mongoose'
direquire = require 'direquire'
MongoStore = (require "connect-mongo") express
RedisStore = (require "connect-redis") express
LocalStrategy = require("passport-local").Strategy
redis = require("redis").createClient()

# Database

if process.env.MONGO
  mongoose.connect process.env.MONGO
  debug "mongo connect to #{process.env.MONGO}"

AWS.config.loadFromPath path.resolve 'config', 'aws.json'

app = exports.app = express()
app.disable 'x-powerd-by'
app.set 'events', direquire path.resolve 'events'
app.set 'models', direquire path.resolve 'models'
app.set 'helper', direquire path.resolve 'helper'
app.set 'aws', AWS
app.set 'views', path.resolve 'views'
app.set 'view engine', 'jade'

app.use express.favicon()
app.use express.logger 'dev' unless process.env.NODE_ENV is 'test'
app.use express.json()
app.use express.urlencoded()
app.use express.cookieParser()
app.use express.methodOverride()

Session = app.get("events").Session(app)
passport.serializeUser Session.serializeUser
passport.deserializeUser Session.deserializeUser
passport.use Session.localStrategy()

app.use (req, res, next)->
  url = "http://client.manager.localhost"
  res.setHeader "Access-Control-Allow-Origin", url
  res.setHeader "Access-Control-Allow-Credentials", true
  res.setHeader "Access-Control-Request-Method", "*"
  next()

app.use express.session
  store: new RedisStore
    host: "localhost"
    client: redis
    db: 1
    prefix: "session:"
  cookie:
    httpOnly: false
    maxAge: 1000*60*60*24*7
  secret: "cat"
# app.use express.session
#   secret: "hogefuga"
#   store: new MongoStore
#     db: 'session'
#     host: 'localhost'
#     clear_interval: 60*60*1000
#   cookie:
#     httpOnly: false
#     maxAge: new Date(Date.now() + 60 * 60 * 1000)

app.use passport.initialize()
app.use passport.session()
app.use app.router

if process.env.NODE_ENV is 'development'
  app.use express.static path.resolve 'dist'
  app.use (req, res) ->
    express.static(path.resolve './')(req, res) if /^\/assets\//.test req.url
  app.use express.errorHandler()
else
  app.use express.static path.resolve 'public'

if process.env.NODE_ENV isnt 'production'
  debug "using error handler"

# Server
  
server = exports.server = http.createServer app
io     = require("socket.io").listen server
linda  = require("linda-socket.io").Linda.listen {io: io, server: server}
app.set 'linda', linda
process.linda = linda
fluentd = app.get("helper").FluentdLinda app

# Routes

route = require path.resolve 'config', 'routes'

route.http app
route.ws app, io

