exports.http = (app) ->

  Content = (app.get 'events').Content app
  User = (app.get 'events').User app
  Notification = (app.get 'events').Notification app
  Group = (app.get 'events').Group app
  Login = (app.get 'events').Login app
  View = (app.get 'events').View app
  Linda = (app.get 'events').Linda app
  Program = (app.get 'events').Program app


## API
# login系
  
  app.get "/api/islogin", Login.isLogin
  app.post "/api/signup", User.create
  app.post "/api/login", Login.login

# Device系
  app.post "/api/device/login", Login.device.login

# User系
  app.get "/api/user/new", User.create
  app.post "/api/user/new", User.create
  app.get  "/api/user/all", User.allRead
  app.delete "/api/user", User.remove
  app.get  "/api/user/:id", User.read
  app.post "/api/user/:uuid/addgroup", User.addGroup

# Group系
  app.post "/api/group/new", Group.create
  app.post "/api/group/", Group.createe
  app.get  "/api/group/all", Group.allRead
  app.get  "/api/group/:name", Group.read
  app.put  "/api/group/:name", Group.update
  app.delete "/api/group/:name", Group.delete
  # app.put  "/api/group/:name/add", Group.addMember
  # app.put  "/api/group/:name/remove", Group.removeMember
  app.get "/api/group/:name/member", Group.Member.read
  app.put "/api/group/:name/member", Group.Member.update

# 通知系
  app.get "/api/notification/all", Notification.allRead
  app.delete "/api/notification/alldelete", Notification.allDelete
  app.delete "/api/notification", Notification.delete
  app.post "/api/notification/new",   Notification.create
  app.post "/api/notification/name/:name", Notification.sendByUserName
  app.post "/api/notification/:uuid", Notification.send

# 検索系
  app.get "/api/search/user/:id", User.Search.perfectMatch

# Program
  app.get "/api/group/:name/programs", Program.read
  app.get "/api/program/:id", Program.read

# Noraml Routing
  app.get "/(groups|login)/(*)", View.index
  app.get "/", View.index

# LindaWrite
  app.post "/api/linda/:name", Linda.write
  app.get "/api/linda/:name", Linda.read

# DEBUG
  app.get "/debug/user/initialize", User.DEBUG.createUser

exports.ws = (app, io)->
  Content = (app.get 'events').Content app
  User = (app.get 'events').User app
  Notification = (app.get 'events').Notification app
  Group = (app.get 'events').Group app
  Login = (app.get 'events').Login app
  View = (app.get 'events').View app
  Program = (app.get 'events').Program app


  io.sockets.on "connection", (socket)=>
    # ここでwebsocketでのRoutingを書く。
    # もう全部Weboscketで通信させるとかでいいんじゃないだろうか
    socket.on "group/new", Group.ws.create

    socket.on "active/task/:id", Program.ws.setActiveTask
    # socket.on ""