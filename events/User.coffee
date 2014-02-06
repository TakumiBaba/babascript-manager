exports.User = (app) ->

  {User} = app.get 'models'

  create: (req, res, next)->
    uuid = req.body.uuid
    registrationId = req.body.registrationId
    deviceType = req.body.deviceType
    User.findOne uuid: uuid, (err, user)=>
      if !user
        user = new User()
        user.uuid = uuid
        user.registrationId = registrationId
        user.deviceType = deviceType
        user.name = req.params.name || "takumibaba"
      user.save (err, data)=>
        res.json data

  read: (req, res, next)->
    User.findOne uuid: req.params.uuid, (err, user)->
      res.json user
    # User.findOne name: req.params.id, {}, {}, (err, User)->
    #   console.error err if err
    #   return User

  allRead: (req, res, next)->
    console.log "all"
    User.find {}, (err, users)->
      res.json users

  update: (req, res, next)->
    next()

  delete: (req, res, next)->
    next()

  getGroups: (req, res, next)->
    next()
    
  createGroup: (req, res, next)->
    next()
