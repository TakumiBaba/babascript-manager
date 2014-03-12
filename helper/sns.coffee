exports.AmazonSNS = (app) ->

  {User} = app.get "models"
  {Notification} = app.get "models"
  {Device} = app.get "models"
  path = require 'path'
  fs = require "fs"
  util = require "util"

  AWS = require "aws-sdk"
  configFile = path.resolve('config', 'aws.json')
  config = JSON.parse (fs.readFileSync configFile).toString()
  AWS.config.loadFromPath configFile
  cer = fs.readFileSync path.resolve "config", "agent_cert.pem"
  file = fs.readFileSync path.resolve "config", "private.key"
  sns = new AWS.SNS()

  test: (done)->
    console.log "test"
    done()

  send: (uuid, message, done)->
    console.log "send"
    Notification.findOne {uuid: uuid}, (err, n)=>
      throw err if err
      if n?
        console.log "exist"
        console.log n
        @publish n.endpoint, message, done
      else
        console.log "new"
        @createNotificationModel uuid, message, (data)=>
          console.log data
          @publish data.endpoint, message, done

  publish: (endpoint, message, done)->
    # json = {}
    # for key, value of message
    #   if typeof value is 'object'
    #     value = value.toString()
    #   json[key] = value
    # console.log message
    # params =
    #   Message: JSON.stringify(json)
    #   TargetArn: endpoint
    params =
      Message: "命令が来ています。#{message.key}"
      TargetArn: endpoint
    console.log params
    sns.publish params, done

  createNotificationModel: (uuid, message, done)->
    Device.findOne {uuid: uuid}, (err, device)->
      throw err if err
      if !device?
        return res.json
          status: false
          message: 'device not found'
      else
        if device.type is "APNS" or device.type is "APNS_SANDBOX"
          credentialKey = file.toString()
          principalKey = cer.toString()
        else if device.type is "GCM"
          credentialKey = config.ApiKey.GCM
          principalKey = ""
        params =
          Name: config.appName
          Platform: device.type
          Attributes:
            PlatformCredential: credentialKey
            PlatformPrincipal: principalKey
        sns.createPlatformApplication params, (err, data)->
          throw err if err
          token = device.token
          params =
            PlatformApplicationArn: data.PlatformApplicationArn
            Token: device.token.toString()
          sns.createPlatformEndpoint params, (err, data)->
            throw err if err
            endpoint = data.EndpointArn
            n = new Notification()
            n.uuid = uuid
            n.endpoint = endpoint
            done n
            n.save (err, data)->
              throw err if err
              done data