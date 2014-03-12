exports.FluentdLinda = (app) ->
  logger = require "fluent-logger"
  logger.configure "mongo.babascript.test", {host: "localhost", port: "24224"}
  linda = app.get "linda"
  Client = require("linda-socket.io").Client
  client = new Client()
  {ActiveTask} = app.get "models"
  {User} = app.get "models"
  groups = {}
  activeTask = linda.tuplespace("active_task")
  activeUser = linda.tuplespace("active_user")
  users = {}

  linda.io.on "connection", (socket)=>
    console.log "connect!"
    console.log socket.id
    socket.on "disconnect", (data)=>
      console.log "disconnect"
      name = users[socket.id]
      linda.tuplespace(name).write
        type: "status"
        status: "mobile"
      users[socket.id] = null
      # User.findOne {sid: socket.id} , (err, user)->
      #   throw err if err
      #   if user?
      #     user.sid = ""
      #     user.save (err)->
      #       throw err if err
      #       console.log groups[socket.id]
      #       groups[socket.id].write
      #         type: "status"
      #         id: user.id
      #         status: "mobile"
      #       groups[socket.id] = null

    socket.on "__linda_write", (data)=>
      console.log data
      if data.tuple.type is "connect"
        name = data.tuple.name
        users[socket.id] = name
        linda.tuplespace(name).write
          type: "status"
          status: "web"
      else
        json =
          tuplespace: data.tuplespace
          cid: data.tuple.cid
          type: data.tuple.type
          key: data.tuple.key
        logger.emit "babascript", data
        if data.tuple.type is "eval"
          json =
            group: data.tuplespace
            status: "eval"
            key: data.tuple.key
            cid: data.tuple.cid
          activeTask.write json, {}
        else if data.tuple.type is "return"
        # 元命令のkeyを把握する仕組み
        # hoge[cid] = key
        # とかしてみて。
          console.log "return"
          console.log data
          json =
            group: data.tuplespace
            status: "return"
            key: data.tuple._task.key
            value: data.tuple.value
            id: data.tuple.worker
            cid: data.tuple.cid
          activeTask.write json

    socket.on "__linda_take", (data)=>
      # take発行時になってしまう。
      # takeで実際に値を取得した時を得たい。
      # if data.tuple.baba is "script"
      #   task =
      #     status: "eval"
      #     group: data.tuplespace
      #   activeTask.take task, (err, t)->
      #     console.log t
      #     json =
      #       group: t.data.group
      #       status: "running"
      #       task:
      #         id: t.data.task.cid
      #         tuple: t.data.tuple
      #     activeTask.write json
      json =
        tuplespace: data.tuplespace
        cid: data.tuple.cid
        type: data.tuple.type
        key: data.tuple.key
      logger.emit "babascript", json
      # task =
      #   tuplespace: data.tuplespace
      #   cid: data.tuple.cid
      # linda.tuplespace("active_task").take task, (t)->
      #   t.status = "running"
      #   linda.tuplespace("active_task").write t
      # task =
      #   tuplespace: data.tuplespace
      #   cid: data.tuple.cid
      # _task =
      #   group: data.tuplespace
      #   status: "active"
      #   task:
      #     id: data.tuple.cid
      #     task: data.tuple
      #     tuplespace: data.tuplespace
      # linda.tuplespace("active_task").take task, ->
      #   linda.tuplespace("active_task").write _task, {}
    # socket.on "__linda_read", (data)=>
    #   logger.emit "__linda_read", data
    # socket.on "__linda_watch", (data)=>
    #   logger.emit "__linda_watch", data
    # socket.on "__linda_cancel", (data)=>
    #   logger.emit "__linda_cancel", data
    # socket.on "disconnect", (data)=>
    #   logger.emit "disconnect", data