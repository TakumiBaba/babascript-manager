exports.Session = (app) ->

  {User, Device} = app.get "models"
  Crypto = require "crypto"
  passport = require "passport"
  LocalStrategy = require("passport-local").Strategy

  login: (req, res, next)->
    if req.isAuthenticated()
      res.json
        status: true
    else
      res.json
        status: false

  logout: (req, res, next)->
    req.logout()
    res.redirect "/"

  isLogin: (req, res, next)->
    res.send req.isAuthenticated()

  success: (req, res, next)->
    console.log req.sessionID
    res.json
      sessionID: req.session.id
      status: true

  failure: (req, res, next)->
    console.log req.sessionID
    res.json
      status: false

  serializeUser: (user, done)->
    done null, user.id
  deserializeUser: (id, done)->
    User.findOne {id: id}, (err, user)->
      done err, user

  localStrategy: ->
    return new LocalStrategy (username, password, done)->
      console.log "username: #{username}"
      console.log "password: #{password}"
      User.findOne {id: username}, (err, user)->
        return done err if err
        if !user
          console.log "user not found"
          return done null, false, {message: "invalid username"}
        else if !user.comparePassword password
          console.log "password is not valid"
          return done null, false, {message: "invalid password"}
        else
          console.log "else"
          return done null, user