mongoose = require 'mongoose'
debug = require('debug')('coah:models:user')
fs = require "fs"
path = require "path"
Schema = mongoose.Schema
Crypto = require("crypto")
# Shasum = require("crypto").createHash("sha256")

# UserModel = new Schema
#   uuid: type: String
#   registrationId: type: String
#   name: type: String
#   password: type: String
#   deviceType: type: String # APNs, GCM など
#   groups: type: [{type: Schema.Types.ObjectId, ref: "group"}]

UserModel = new Schema
  id: type: String
  password: type: String
  devices: [{type: Schema.Types.ObjectId, ref: "device"}]
  groups: type: [{type: Schema.Types.ObjectId, ref: "group"}]
  sid: type: String

DeviceModel = new Schema
  uuid: type: String
  type: type: String
  token: type: String
  endpoint: type: String
  owner: type: {type: Schema.Types.ObjectId, ref: "user"}

GroupModel = new Schema
  name: type: String
  users: type: [{type: Schema.Types.ObjectId, ref: "user"}]
  programs: type: [{type: Schema.Types.ObjectId, ref: "program"}]

NotificationModel = new Schema
  uuid: type: String
  endpoint: type: String

ProgramModel = new Schema
  name: type: String
  value: type: String

ActiveUser = new Schema
  id: type: String
  status: type: Boolean

ActiveTask = new Schema
  id: type: String
  tuplespace: type: String
  task: type: Schema.Types.Mixed

UserModel.methods.comparePassword = (password, callback)->
  shasum = Crypto.createHash "sha256"
  p = shasum.update(password).digest("hex")
  if @password is p
    return true
  else
    return false

NotificationModel.statics.send = (uuid, message)->
  @getOrCreateEndpoint uuid, (endpoint)->
    params =
      Message: JSON.stringify message
      TargetArn: endpoint
    sns.publish params, (err, data)->
      throw err if err
      res.json data

NotificationModel.statics.getOrCreateEndpoint = (uuid, done)->
  @find {uuid: uuid}, (err, n)->
    throw err if err
    if n?
      endpoint = n.endpoint
      done endpoint
    else
      # notification model が無いときは、ここで生成するようにする

NotificationModel.statics.create = (sns, uuid, platform, token, done)->
  awsConfig = JSON.parse fs.readFileSync path.resolve "config", "aws.json"
  if platform is "APNS" or platform is "APNS_SANDBOX"
    file = (fs.readFileSync(path.resolve("config", "private.key")))
    apiKey = file.toString()
    cer = fs.readFileSync path.resolve("config", "agent_cert.pem")
    sslCer = cer.toString()
  else
    apiKey = awsConfig.ApiKey.GCM
    sslCer = ""
  params =
    Name: "babascript"
    Platform: platform
    Attributes:
      PlatformCredential: apiKey
      PlatformPrincipal: sslCer
  @count uuid: uuid, (err, count)=>
    throw err if err
    if count > 0
      done { message: "already save" }
    else
      sns.createPlatformApplication params, (err, data)=>
        throw err if err
        params =
          PlatformApplicationArn: data.PlatformApplicationArn
          Token: token
        sns.createPlatformEndpoint params, (err, data)=>
          throw err if err
          endpoint = data.EndpointArn
          n = new @
          n.uuid = uuid
          n.endpoint = endpoint
          n.save done

NotificationModel.statics.getEndpoint = (uuid, done)->
  @findOne uuid: uuid, (err, n)->
    throw err if err
    endpoint = n.endpoint
    done(endpoint)

exports.User = mongoose.model 'user', UserModel
exports.Device = mongoose.model 'device', DeviceModel
exports.Group = mongoose.model 'group', GroupModel
exports.Notification = mongoose.model 'notifications', NotificationModel
exports.Program = mongoose.model 'program', ProgramModel
exports.ActiveTask = mongoose.model 'activeTask', ActiveTask
exports.ActiveUser = mongoose.model 'activeUser', ActiveUser