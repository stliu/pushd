async = require 'async'
logger = require 'winston'

class App
  key_format: /^[a-zA-Z0-9:._-]{1,100}$/

  constructor: (@redis, @id) ->
    throw new Error("Missing redis connection") if not redis?
    throw new Error('Invalid app key ' + id) if not App::key_format.test id
    @key = "app:#{id}"
    logger.verbose "new app #{@id} constructor"

  get:() ->
    logger.verbose "App.get is called"

  info: (cb) ->
    return until cb
    @redis.multi()
      .hgetall(@key, cb)
      # subscribers total
#      .zcard("#{@id}:subs")
#      .exec (err, results) =>
#        if (f for own f of results[0]).length
#          info = {total: results[1]}
          # transform numeric value to number type
#          for own key, value of results[0]
#            num = parseInt(value)
#            info[key] = if num + '' is value then num else value
#          cb(info)
#        else
#          cb(null)

  #check if this app is already exist in the DB or not
  exists: (cb) ->
    @redis.exists @key, (err, exists) =>
      cb(exists)

  # delete this app from DB
  delete: (cb) ->
    logger.verbose "Deleting app #{@id}"
    @redis.del(@key, cb if cb)
#    subscriberCount = 0
#    @forEachSubscribers (subscriber, subOptions, done) =>
#                          # action
#                          subscriber.removeSubscription(@, done)
#                          subscriberCount += 1
#                        , =>
#      # finished
#      logger.verbose "Unsubscribed #{subscriberCount} subscribers from #{@name}"
#
#      @redis.multi()
#      # delete event's info hash
#      .del(@key)
#      # remove event from global event list
#      .srem("events", @name)
#      .exec (err, results) ->
#          cb(results[1] > 0) if cb

#  log: (cb) ->
#    @redis.multi()
#    # account number of sent notification since event creation
#    .hincrby(@key, "total", 1)
#    # store last notification date for this event
#    .hset(@key, "last", Math.round(new Date().getTime() / 1000))
#    .exec =>
#        cb() if cb
#
#  # Performs an action on each subscriber subsribed to this event
#  forEachSubscribers: (action, finished) ->
#    Subscriber = require('./subscriber').Subscriber
#    if @name is 'broadcast'
#      # if event is broadcast, do not treat score as subscription option, ignore it
#      performAction = (subscriberId, subOptions) =>
#        return (done) =>
#          action(new Subscriber(@redis, subscriberId), {}, done)
#    else
#      performAction = (subscriberId, subOptions) =>
#        options = {ignore_message: (subOptions & Event::OPTION_IGNORE_MESSAGE) isnt 0}
#        return (done) =>
#          action(new Subscriber(@redis, subscriberId), options, done)
#
#    subscribersKey = if @name is 'broadcast' then 'subscribers' else "#{@key}:subs"
#    page = 0
#    perPage = 100
#    total = 0
#    async.whilst =>
#                   # test if we got less items than requested during last request
#                   # if so, we reached to end of the list
#                   return page * perPage == total
#                 , (done) =>
#      # treat subscribers by packs of 100 with async to prevent from blocking the event loop
#      # for too long on large subscribers lists
#      @redis.zrange subscribersKey, (page * perPage), (page * perPage + perPage - 1), 'WITHSCORES', (err, subscriberIdsAndOptions) =>
#        tasks = []
#        for id, i in subscriberIdsAndOptions by 2
#          tasks.push performAction(id, subscriberIdsAndOptions[i + 1])
#        async.series tasks, =>
#          total += subscriberIdsAndOptions.length / 2
#          done()
#      page++
#                 , =>
#      # all done
#      finished(total) if finished

exports.App = App
