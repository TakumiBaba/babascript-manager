exports.Linda = (app) ->

  write: (req, res, next)->
    from = req.socket._peername.address
    name = req.params.name
    try
      tuple = JSON.parse req.body.tuple
    catch
      res.statusCode = 404
      res.end "invalid json"
    console.log tuple
    process.linda.tuplespace(name).write tuple, {from: from}
    res.end JSON.stringify tuple

  read: (req, res, next)->
    