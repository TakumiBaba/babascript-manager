exports.Notification = (app) ->

  {User} = app.get "models"
  path = require "path"
  fs = require 'fs'

  send: (req, res, next)->
    console.log req.body
    uuid = req.params.uuid
    AWS = app.get 'aws'
    sns = new AWS.SNS()
    awsConfig = JSON.parse fs.readFileSync path.resolve 'config', 'aws.json'
    User.findOne uuid: uuid, (err, user)->
      throw err if err
      res.json {message: "not found"} if !user
      sendMessage = req.body.message
      params =
        Name: "babascript"
        Platform: "GCM"
        Attributes:
          PlatformCredential: awsConfig.GcmApiKey
      sns.createPlatformApplication params, (err, data)->
        throw err if err
        params =
          PlatformApplicationArn: data.PlatformApplicationArn
          Token: user.registrationId
        sns.createPlatformEndpoint params, (err, data)->
          throw err if err
          endpoint = data.EndpointArn
          params =
            Message: JSON.stringify sendMessage
            TargetArn: endpoint
          sns.publish params, (err, data)->
            throw err if err
            res.json data