exports.User = (app) ->

  Crypto = require 'crypto'
  _ = require "underscore"

  {User} = app.get 'models'
  {Group} = app.get 'models'
  {Notification} = app.get 'models'

  create: (req, res, next)->
    id = req.body.id
    pass = req.body.pass || req.params.pass
    User.findOne id: id, (err, user)->
      throw err if err
      if user
        res.json
          status: false
          message: "already exist"
      else
        shasum = Crypto.createHash('sha256')
        user = new User()
        user.id = id
        user.password = shasum.update(pass).digest("hex")
        user.save (err)->
          throw err if err
          req.session.user = user
          res.json
            status: true

  read: (req, res, next)->
    id = req.params.id
    User.findOne({id: id}).populate('devices groups').exec (err, user)->
      throw err if err
      res.json user

  allRead: (req, res, next)->
    User.find({}).populate('devices groups').exec (err, user)->
      throw err if err
      res.json user

  remove: (req, res, next)->
    id = req.body.id
    User.findOne {id: id}, (err, user)->
      throw err if err
      if user
        user.remove()
      res.json {status: "removed"}

  addGroup: (req, res, next)->
    res.json {}

  Search:
    perfectMatch: (req, res, next)->
      id = req.params.id
      User.findOne {id: id}, (err, user)->
        throw err if err
        res.json user

  Group:
    read: (req, res, next)->
      id = req.params.id
      q = User.findOne({id: id})
      q.populate("groups")
      q.exec (err, user)->
        names = _.pluck user.groups, "name"
        g = Group.find({name: {$in: names}})
        g.populate("users")
        g.exec (err, groups)->
          throw err if err
          res.json groups

  DEBUG:
    createUser:(req, res, next) ->
      a = ["a", "b", "c", "d", "e", "f", "g"]
      shusum = Crypto.createHash('sha256')
      pass = shusum.update("pass").digest("hex")
      users = []
      for i in a
        for k in a
          name = "#{i}_#{k}"
          console.log name
          user = new User()
          user.id = name
          user.password = pass
          users.push user
          user.save (err)->
            throw err if err
      res.json user
    
  # create: (req, res, next)->
  #   uuid = req.body.uuid
  #   registrationId = req.body.registrationId.replace(/\s|<|>/g, "")
  #   deviceType = req.body.deviceType
  #   User.findOne uuid: uuid, (err, user)=>
  #     if !user
  #       user = new User()
  #       user.uuid = uuid
  #       user.registrationId = registrationId
  #       user.deviceType = deviceType
  #       user.name = req.params.name || "takumibaba"
  #     user.save (err, data)=>
  #       aws = app.get "aws"
  #       sns = new aws.SNS()
  #       Notification.create sns, uuid, deviceType, registrationId, (err)->
  #         res.json data

  # read: (req, res, next)->
  #   User.findOne(uuid: req.params.uuid).populate("groups").exec (err, user)->
  #     throw err if err
  #     res.json user

  # addGroup: (req, res, next)->
  #   User.findOne uuid: req.params.uuid, (err, user)->
  #     throw err if err
  #     Group.findOne name: req.body.name, (err, group)->
  #       throw err if err
  #       user.groups.push group._id
  #       user.save (err)->
  #         throw err if err
  #         res.json user

  # allRead: (req, res, next)->
  #   console.log "all"
  #   User.find({}).populate("groups").exec (err, users)->
  #     res.json users

  # update: (req, res, next)->
  #   next()

  # delete: (req, res, next)->
  #   User.findOne {uuid: req.body.uuid}, (err, user)->
  #     throw err if err
  #     user.remove()
  #     res.json {status: "success"}

  # allDelete: (req, res, next)->
  #   User.find {}, (err, users)->
  #     for u in users
  #       u.remove()
  #     res.json "delete"

  # getGroups: (req, res, next)->
  #   next()
    
  # createGroup: (req, res, next)->
  #   next()
