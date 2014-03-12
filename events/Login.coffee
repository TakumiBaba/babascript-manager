exports.Login = (app)->

  {User} = app.get 'models'
  {Device} = app.get 'models'
  {Notification} = app.get 'models'
  Crypto = require "crypto"

  _ = require "underscore"

  isLogin: (req, res, next)->
    console.log req.session
    if req.session.user?
      res.json
        status: true
        session: req.session
    else
      res.json
        status: false

  login: (req, res, next)->
    id = req.body.id
    shasum = Crypto.createHash("sha256")
    password = shasum.update(req.body.pass).digest("hex")
    fields = "id devices groups"
    params =
      id: id
      password: password
    User.findOne params, fields , (err, user)=>
      throw err if err
      if !user?
        res.json
          status: false
      else
        req.session.user = user
        return res.json
          status: true
          user: user

  hoge: (req, res, next)->
    console.log req
    res.json {}

  device:
    login: (req, res, next)->
      id = req.body.id
      pass = req.body.pass
      console.log id, pass
      password = Crypto.createHash("sha256").update(pass).digest("hex")
      deviceId = req.body.deviceId
      deviceType = req.body.deviceType
      token = req.body.token.replace(/\s|<|>/g, "")
      params =
        id: id
        password: password
      User.findOne(params).populate("devices").exec (err, user)->
        throw err if err
        if !user?
          res.json 401,
            status: false
            message: "id or pass isn't valid"
        else
          devices = user.devices
          d = _.find devices, (device)->
            return device.uuid is deviceId
          if d?
            res.json
              status: true
              message: "login success"
              id: id
              pass: pass
          else
            device = new Device()
            device.uuid = deviceId
            device.type = deviceType
            device.owner = user._id
            device.token = token
            device.save (err, data)->
              user.devices.push device._id
              user.save (err, data)->
                res.json
                  status: true
                  message: "login success & device regist"
                  id: id
                  pass: pass
                  device: device