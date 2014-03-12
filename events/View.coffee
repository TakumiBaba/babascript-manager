exports.View = (app) ->

  index: (req, res, next)->
    return res.render "index"