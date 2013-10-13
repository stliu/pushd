async = require 'async'
logger = require 'winston'

class Event
    OPTION_IGNORE_MESSAGE: 1
    name_format: /^[a-zA-Z0-9:._-]{1,100}$/

    constructor: (@redis,@applicationKey, @name) ->
        throw new Error("Missing redis connection") if not redis?
        throw new Error('Invalid event name ' + @name) if not Event::name_format.test @name
        @fullkey = "#{@applicationKey}:#{@name}"
        @eventkey = "event:#{@fullkey}"
        logger.verbose "new event #{@fullkey} constructor"
    
    # get the info of this event, including how many subscriptions and all of other event keys/values
    info: (cb) ->
        return until cb
        @redis.multi()
            # event info
            .hgetall(@eventkey)
            # subscribers total
            .zcard("#{@eventkey}:subs")
            .exec (err, results) =>
                if (f for own f of results[0]).length
                    info = {total: results[1]}
                    # transform numeric value to number type
                    for own key, value of results[0]
                        num = parseInt(value)
                        info[key] = if num + '' is value then num else value
                    cb(info)
                else
                    cb(null)
    #check if this event is already exist in the DB or not
    #'broadcast' is always existed
    exists: (cb) ->
        if @name is 'broadcast'
            cb(true)
        else
            @redis.sismember "events", @fullkey, (err, exists) =>
                cb(exists)
    # delete this event from DB
    # first, we need to unsubscribe from this event ( it's stored in the 'subscribers:@id:evts')
    # then delete the key of this event 'event:@event_name'
    # finally, remove this event name from 'events'
    delete: (cb) ->
        logger.verbose "Deleting event #{@fullkey}"

        subscriberCount = 0
        @forEachSubscribers (subscriber, subOptions, done) =>
            # action
            subscriber.removeSubscription(@, done)
            subscriberCount += 1
        , (total, ek)=>
            # finished
            logger.verbose "Unsubscribed #{subscriberCount} subscribers from #{@fullkey}"
            @redis.multi()
                # delete event's info hash
                .del(ek)
                # remove event from global event list
                .srem("events", @fullkey)
                .exec (err, results) ->
                    cb(results[1] > 0) if cb

    log: (cb) ->
        @redis.multi()
            # account number of sent notification since event creation
            .hincrby(@eventkey, "total", 1)
            # store last notification date for this event
            .hset(@eventkey, "last", Math.round(new Date().getTime() / 1000))
            .exec =>
                cb() if cb



    # Performs an action on each subscriber subsribed to this event
    forEachSubscribers: (action, finished) ->
        Subscriber = require('./subscriber').Subscriber
        if @name is 'broadcast'
            # if event is broadcast, do not treat score as subscription option, ignore it
            performAction = (subscriberId, subOptions) =>
                return (done) =>
                    action(new Subscriber(@redis, subscriberId), {}, done)
        else
            performAction = (subscriberId, subOptions) =>
                options = {ignore_message: (subOptions & Event::OPTION_IGNORE_MESSAGE) isnt 0}
                return (done) =>
                    action(new Subscriber(@redis, subscriberId), options, done)

        subscribersKey = if @name is 'broadcast' then 'subscribers' else "#{@eventkey}:subs"
        page = 0
        perPage = 100
        total = 0

        #synchronous truth test to perform before each execution of fn.
        condition_checker = () =>
          # test if we got less items than requested during last request
          # if so, we reached to end of the list
          return page * perPage == total

        #A function to call each time the test passes. The function is passed a callback(err) which must be called once it has completed with an optional error argument.
        fn = (done) =>
          # treat subscribers by packs of 100 with async to prevent from blocking the event loop
          # for too long on large subscribers lists
          @redis.zrange subscribersKey, (page * perPage), (page * perPage + perPage - 1), 'WITHSCORES', (err, subscriberIdsAndOptions) =>
            tasks = []
            for id, i in subscriberIdsAndOptions by 2
              tasks.push performAction(id, subscriberIdsAndOptions[i + 1])

            series_callback = (err, results)=>
              total += subscriberIdsAndOptions.length / 2
              done()
            async.series(tasks, series_callback)
          page++

        #A callback which is called after the test fails and repeated execution of fn has stopped.
        whist_callback = (err) =>
          finished(total, @eventkey) if finished

        async.whilst(condition_checker, fn, whist_callback)

exports.Event = Event
