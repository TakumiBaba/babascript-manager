exports.Program = (app) ->



  read: (req, res, next)->
    console.log "progmram return"
    json =
      name: "hoge"
      program: "function(){\nhogefuga\n}"
    res.json [json, json, json]
      
  ws:
    setActiveTask: (data)->
      console.log data