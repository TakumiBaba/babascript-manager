mongoose = require 'mongoose'
debug = require('debug')('coah:models:user')

UserModel = new mongoose.Schema
  uuid: type: String
  registrationId: type: String
  name: type: String
  deviceType: type: String # APNs, GCM など
  groups: type: [GroupModel]

GroupModel = new mongoose.Schema
  id: type: Number, unique: yes
  name: type: String
  users: type: [UserModel]

UserModel.statics.findOrCreateByTwitter = (token, secret, profile, done) ->
  now = new Date
  @findOne id: profile.id, (err, user) =>
    return done no if err
    unless user
      user = new @ { id: profile.id, created: now }
      user.service = []
    user.name = profile.username
    user.icon = profile.photos[0].value
    user.updated = nowf
    for service in user.service
      return user.save done if service.name is 'twitter'
    console.log user
    user.service.push
      name: 'twitter'
      token: token
      secret: secret
    user.save done

exports.User = mongoose.model 'user', UserModel
exports.Group = mongoose.model 'groups', GroupModel