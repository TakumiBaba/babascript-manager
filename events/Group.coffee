exports.Group = (app) ->

  {Group} = app.get 'models'
  {User}  = app.get 'models'
  _ = require "underscore"

  createe: (req, res, next)->
    console.log req.body
    Group.findOne name: req.body.name, (err, group)->
      throw err if err
      if group?
        res.json
          status: false
          messag: "already exist"
      else
        User.findOne _id: req.body.users[0], (err, user)->
          throw err if err
          if !user?
            res.json
              status: false
              messge: "user not found"
          else
            group = new Group()
            group.name = req.body.name
            group.users = req.body.users
            group.save (err, data)->
              throw err if err
              console.log data
              user.groups.push data._id
              user.save (err, data)->
                throw err if err
                res.json data

  create: (req, res, next)->
    userid = req.body.userid
    Group.findOne name: req.body.name, (err, group)->
      throw err if err
      if group?
        res.json group
      else
        User.findOne id: userid, (err, user)->
          throw err if err
          res.json {error: "uuid is unavailable"} if !user
          if !group
            group = new Group()
            group.name = req.body.name
            group.users.push user._id
          group.save (err, data)->
            throw err if err
            console.log "gruop-save"
            console.log data
            console.log user
            hoge = _.contains user.groups, data._id
            if !_.contains user.groups, data._id
              user.groups.push data._id
            console.log "_contains is #{hoge}"
            user.save (err, data)->
              res.json
                status: true
                data: data

  read: (req, res, next)->
    console.log req.params
    console.log req.body
    Group.findOne(name: req.params.name).populate("users").exec (err, group)->
      throw err if err
      console.log group
      userIds = _.pluck group.users, 'id'
      console.log userIds
      q = User.find({id: {$in: userIds}})
      q.populate('devices', 'uuid')
      q.exec (err, users)->
        throw err if err
        list = {name: group.name, users: []}
        console.log 'read'
        console.log users
        _.each users, (user)->
          d = user.devices[0]
          console.log d
          if user.id? and d?
            u = {}
            u.id = user.id
            u.uuid = user.devices[0].uuid
            list.users.push u
        res.json list
        
  allRead: (req, res, next)->
    Group.find {}, (err, groups)->
      list = []
      _.each groups, (group)=>
        list.push _.filter group.users, (user)->
          return user.id?
      res.json list

# TODO 実装
  update: (req, res, next)->
    console.log req.body
    status = req.body.status
    users = req.body.users
    name  = req.body.name
    q = Group.findOne({name: name})
    q.populate "users"
    q.exec (err, group)=>
      throw err if err
      # users と group.users の差分を取る
      u = _.pluck users, "id"
      uu = _.pluck group.users, "id"
      if u < uu
        diff = _.difference uu, u
        _.each group.users, (user)->
          if _.contains diff, user.id
            group.users.remove user
        res.json group.users
      else if u > uu
        res.json {}
      # if status is "remove"
      #   diff = _.difference uu, u
      #   _.each group.users, (user)->
      #     if _.contains diff, user.id
      #       group.users.remove user
      #   res.json group.users
      # else if status is "add"
      #   diff = _.difference u, uu
      # q = User.find().where("id").in()
      # if status is "add"
      #   newUsers = _.filter users, (user)->
      #     return user.isNew
      #   members = _.filter newUsers, (nu)->
      #     return _.find group.users, (user)->
      #       return user.name is nu.name
      #   membersId = _.pluck members, "id"
      #   q = User.find()
      #   q.where("id").in(membersId)
      #   q.exec (err, users)=>
      #     throw err if err
      #     console.log users
      #     _.each users, (u)=>
      #       group.users.push u._id
      #     console.log group
      #     group.save (err, data)->
      #       throw err if err
      #     res.json group
      # else if status is "remove"
      #   users = req.body.users
      #   name  = req.body.name
      #   q = Group.findOne({name: name})
      #   q.populate "users"
      #   q.exec (err, group)=>
      #     throw err if err
      #     u = _.pluck users, "id"
      #     uu = _.pluck group.users, "id"
      #     removedIds = []
      #     _.each u, (id)->
      #       if !_.contains uu, u
      #         removedIds.push id
      #     console.log removedIds
      #     res.json removedIds
      # else
      #   next()
    # users = req.body.users
    # name  = req.body.name
    # q = Group.findOne({name: name})
    # q.populate "users"
    # q.exec (err, group)=>
    #   throw err if err
    #   newUsers = _.filter users, (user)->
    #     return user.isNew
    #   members = _.filter newUsers, (nu)->
    #     return _.find group.users, (user)->
    #       return user.name is nu.name
    #   membersId = _.pluck members, "id"
    #   q = User.find()
    #   q.where("id").in(membersId)
    #   q.exec (err, users)=>
    #     throw err if err
    #     console.log users
    #     _.each users, (u)=>
    #       group.users.push u._id
    #     console.log group
    #     group.save (err, data)->
    #       throw err if err
    #       res.json group

  delete: (req, res, next)->
    name = req.params.name
    Group.findOne name: name, (err, group)->
      throw err if err
      group.remove()
      res.json {}

  # addMember: (req, res, next)->
  #   name = req.params.name
  #   Group.findOne name: name, (err, group)->
  #     throw err if err
  #     User.findOne id: req.body.id, (err, user)->
  #       throw err if err
  #       uu = _.find group.users, (u)=>
  #         return user.id is u.id
  #       if !uu
  #         group.users.push user._id
  #         group.save (err, data)->
  #           throw err if err
  #           res.json data
  #       else
  #         res.json group

  # removeMember: (req, res, next)->
  #   name = req.params.name
  #   Group.findOne name: name, (err, group)->
  #     throw err if err
  #     User.findOne id: req.body.id, (err, user)->
  #       throw err if err
  #       uu = _.find group.users, (u)=>
  #         return user.id is u.id
  #       if uu
  #         _.each group.users, (u, index)=>
  #           if u.uuid is uu.uuid
  #             group.users[index].remove()
  #         group.save (err, data)->
  #           res.json data
  #       else
  #         res.json group
  Member:
    read: (req, res, next)->
      q = Group.findOne(name: req.params.name)
      q.populate("users", "id sid")
      q.exec (err, group)->
        throw err if err
        res.json group.users

    deviceRead: (req, res, next)->
      q = Group.findOne(name: req.params.name)
      q.populate("users", "id devices")
      q.exec (err, group)->
        throw err if err
        console.log group
        members = _.filter group.users, (user)->
          return user.devices[0].length > 0
        res.json members

    update: (req, res, next)->
      members = req.body
      ids = _.pluck members, "id"
      console.log ids
      User.find {id: {$in: ids}}, (err, users)->
        throw err if err
        userIds = _.pluck users, "_id"
        console.log users
        Group.findOne {name: req.params.name}, (err, group)->
          throw err if err
          groupUserIds = _.map group.users, (user)->
            return user.toString()
          receivedUserIds = _.map userIds, (id)->
            return id.toString()
          if receivedUserIds.length < groupUserIds.length
            diff = _.difference groupUserIds, receivedUserIds
            console.log diff
            console.log "diff"
            group.users.remove diff
            group.save (err, data)->
              throw err if err
              res.json data
          else if receivedUserIds.length > groupUserIds.length
            diff = _.difference receivedUserIds, groupUserIds
            console.log receivedUserIds
            console.log groupUserIds
            console.log "diff"
            console.log diff
            group.users.push diff
            group.save (err, data)->
              throw err if err
              res.json data
          else
            next()

      # q = Group.findOne(name: req.params.name)
      # q.populate("users", "id")
      # q.exec (err, group)->
      #   throw err if err
      #   console.log group
      #   u = _.pluck group.users, "id"
      #   uu = _.pluck members, "id"
      #   console.log u.length, uu.length
      #   if u.length > uu.length
      #     diff = _.difference u, uu
      #     User.find {id: {$in: diff}}, (err, users)->
      #       throw err if err
      #       usersId = _.pluck users, "id"
      #       console.log usersId

      #       _.each group.users, (member, i)->
      #         if _.contains usersId, member.id
      #           group.users[i] = ''
      #       console.log group
      #       group.save (err, data)->
      #         throw err if err
      #         console.log data
      #         res.json group
      #   else if u.length < uu.length
      #     diff = _.difference uu, u
      #     User.find {id: {$in: diff}}, (err, users)->
      #       throw err if err
      #       _.each users, (user)->
      #         group.users.push user._id
      #       group.save (err, data)->
      #         throw err if err
      #         res.json group
        
      
    add: (req, res, next)->

    remove: (req, res, next)->
  ws:
    create: (data)->
      console.log data