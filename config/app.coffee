# Dependency

fs = require 'fs'
path = require 'path'
http = require 'http'
debug = require('debug')('coah')
express = require 'express'
mongoose = require 'mongoose'
MongoStore = (require "connect-mongo") express
direquire = require 'direquire'
AWS = require 'aws-sdk'


# Database

if process.env.MONGO
  mongoose.connect process.env.MONGO
  debug "mongo connect to #{process.env.MONGO}"

AWS.config.loadFromPath path.resolve 'config', 'aws.json'

# Application

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

app.use (req, res, next)->
  res.setHeader "Access-Control-Allow-Origin", "*"
  next()

app.use express.session
  secret: path.resolve("config", "env.json").secret || "hogefuga"
  store: new MongoStore
    db: 'session'
    host: 'localhost'
    clear_interval: 60*60*10
  cookie:
    httpOnly: false
    maxAge: new Date(Date.now() + 60 * 60 * 1000)
    # maxAge: new Date(Date.now() + 1)
    # maxAge: new Date(Date.now() + 60 * 60 * 1000)
    
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

