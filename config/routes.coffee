exports.http = (app) ->

  Content = (app.get 'events').Content app
  User = (app.get 'events').User app
  Notification = (app.get 'events').Notification app
  Group = (app.get 'events').Group app

# login系

# User系
  app.post "/user/new", User.create
  app.get  "/user/all", User.allRead
  app.get  "/user/:uuid", User.read

# Group系
  app.post "/group/new", Group.create
  app.get  "/group/all", Group.allRead
  app.get  "/group/:name", Group.read
  app.put  "/group/:name", Group.update
  app.put  "/group/:name/add", Group.addMember
  app.put  "/group/:name/remove", Group.removeMember

# 通知系
  app.post "/notification/:uuid", Notification.send