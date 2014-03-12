exports.Notification = (app) ->

  {User} = app.get "models"
  {Notification} = app.get "models"
  AmazonSNS = (app.get('helper')).AmazonSNS app
  path = require "path"
  fs = require 'fs'


  send: (req, res, next)->
    uuid = req.params.uuid
    message = req.body.message
    AWS = app.get 'aws'
    sns = new AWS.SNS()
    Notification.getEndpoint uuid, (endpoint)->
      params =
        Message: JSON.stringify message
        TargetArn: endpoint
      sns.publish params, (err, data)->
        throw err if err
        res.json data

  sendByUserName: (req, res, next)->
    console.log "send by user name"
    userid = req.body.userid
    message = req.body.message
    User.findOne({id: userid}).populate('devices').exec (err, user)->
      throw err if err
      if !user.devices[0]?
        res.json {status: false}
      else
        device = user.devices[0]
        AmazonSNS.send device.uuid, message, (err, data)->
          throw err if err
          res.json data

  create: (req, res, next)->
    uuid = req.body.uuid
    platform = req.body.platform
    token = req.body.token
    AWS = app.get "aws"
    sns = new AWS.SNS()
    awsConfig = JSON.parse fs.readFileSync path.resolve "config", "aws.json"
    if platform is "APNS" or platform is "APNS_SANDBOX"
      token = token.replace(/\s|<|>/g, "")
      file = fs.readFileSync path.resolve "config", "private.key"
      cer = fs.readFileSync path.resolve "config", "agent_cer.key"
      credential = cer.toString()
      apikey = file.toString()
    else if platform is "GCM"
      apikey = awsConfig.ApiKey.GCM
      credential = ""
    params =
      Name: "babascript"
      Platform: platform
      Attributes:
        PlatformCredential: awsConfig.ApiKey[platform]
        PlatformPrincipal: credential
    sns.createPlatformApplication params, (err, data)->
      throw err if err
      params =
        PlatformApplicationArn: data.PlatformApplicationArn
        Token: token
      sns.createPlatformEndpoint params, (err, data)->
        throw err if err
        console.log data
        endpoint = data.EndpointArn
        n = new NotificationModel()
        n.uuid = uuid
        n.endpoint = endpoint
        res.json n

  allRead: (req, res, next)->
    Notification.find {}, (err, ns)->
      res.json ns

  allDelete: (req, res, next)->
    Notification.find {}, (err, nss)->
      for ns in nss
        ns.remove()
      res.json nss

  delete: (req, res, next)->
    Notification.findOne {uuid: req.body.uuid}, (err, ns)->
      throw err if err
      ns.remove()
      res.json "success"