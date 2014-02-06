exports.Group = (app) ->

  {Group} = app.get 'models'
  {User}  = app.get 'models'
  _ = require "underscore"

  create: (req, res, next)->
    console.log req.body
    id = req.params.id
    Group.findOne name: req.body.name, (err, group)->
      throw err if err
      User.findOne uuid: req.body.uuid, (err, user)->
        res.json {error: "uuid is unavailable"} if !user
        if !group
          group = new Group()
          group.name = req.body.name
          group.users.push user
        group.save (err, data)=>
          res.json data

  read: (req, res, next)->
    Group.findOne name: req.params.name, {}, {}, (err, group)->
      console.error err if err
      res.json group

  allRead: (req, res, next)->
    Group.find {}, (err, groups)->
      res.json groups

  update: (req, res, next)->
    next()

  delete: (req, res, next)->
    next()

  addMember: (req, res, next)->
    name = req.params.name
    Group.findOne name: name, (err, group)->
      throw err if err
      User.findOne uuid: req.body.uuid, (err, user)->
        throw err if err
        uu = _.find group.users, (u)=>
          return user.uuid is u.uuid
        if !uu
          group.users.push user
          group.save (err, data)->
            throw err if err
            res.json data
        else
          res.json group

  removeMember: (req, res, next)->
    name = req.params.name
    Group.findOne name: name, (err, group)->
      throw err if err
      User.findOne uuid: req.body.uuid, (err, user)->
        throw err if err
        uu = _.find group.users, (u)=>
          return user.uuid is u.uuid
        if uu
          _.each group.users, (u, index)=>
            if u.uuid is uu.uuid
              group.users[index].remove()
          group.save (err, data)->
            res.json data
        else
          res.json group