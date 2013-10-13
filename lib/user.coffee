async = require 'async'
logger = require 'winston'

class User
  key_format: /^[a-zA-Z0-9:._-]{1,100}$/

  constructor: (@redis, @key) ->
    throw new Error("Missing redis connection") if not redis?
    throw new Error('Invalid app key ' + @key) if not App::key_format.test @key
    @id = "event:#{@key}"
    logger.verbose "new app #{id} constructor"

  info: (cb) ->
    return until cb
    @redis.multi()
    .hgetall(@id, cb)

  #check if this app is already exist in the DB or not
  exists: (cb) ->
    @redis.exists @id, (err, exists) =>
      cb(exists)

  # delete this app from DB
  delete: (cb) ->
    logger.verbose "Deleting app #{@key}"
    @redis.del(@id, cb if cb)
exports.User = User

