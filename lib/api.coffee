async = require 'async'
util = require 'util'
sys = require 'sys'
filterFields = (params) ->
    fields = {}
    fields[key] = val for own key, val of params when key in ['proto', 'token', 'lang', 'badge', 'version','jid','jiduser', 'appkey']
    return fields

exports.setupRestApi = (logger, app, createSubscriber, getEventFromId, testSubscriber, eventPublisher, createAndSubscribe) ->

    # subscriber registration
    app.post '/subscribers', (req, res) ->
        logger.verbose "Registering subscriber: " + JSON.stringify req.body
        try
            fields = filterFields(req.body)
            fields.appkey = req.application.id
            createSubscriber fields, (subscriber, created) ->
                subscriber.get (info) ->
                    info.id = subscriber.id
                    res.location "/subscriber/#{subscriber.id}"
                    delete info.appkey
                    delete info.proto
                    delete info.token
                    delete info.lang
                    res.json info, if created then 201 else 200
        catch error
            logger.error "Creating subscriber failed: #{error.message}"
            res.json error: error.message, 400

    # Get subscriber info
    app.get '/subscriber/:subscriber_id', (req, res) ->
        req.subscriber.get (info) ->
            if not info?
                logger.error "No subscriber #{req.subscriber.id}"
                res.send 404
            else
                logger.verbose "Subscriber #{req.subscriber.id} info: " + JSON.stringify(info)
                res.json info, 200

    # Edit subscriber info
    app.post '/subscriber/:subscriber_id', (req, res) ->
        logger.verbose "Setting new properties for #{req.subscriber.id}: " + JSON.stringify(req.body)
        fields = filterFields(req.body)
        req.subscriber.set fields, (edited) ->
            if not edited
                logger.error "No subscriber #{req.subscriber.id}"
                res.send 404
            else
                res.send 204

    # Unregister subscriber
    app.delete '/subscriber/:subscriber_id', (req, res) ->
        req.subscriber.delete (deleted) ->
            if not deleted
                logger.error "No subscriber #{req.subscriber.id}"
                res.send 404
            else
                res.send 204

    # Get subscriber subscriptions
    app.get '/subscriber/:subscriber_id/subscriptions', (req, res) ->
        req.subscriber.getSubscriptions (subs) ->
            if subs?
                subsAndOptions = {}
                for sub in subs
                    subsAndOptions[sub.event.name] = {ignore_message: (sub.options & sub.event.OPTION_IGNORE_MESSAGE) isnt 0}
                logger.verbose "Status of #{req.subscriber.id}: " + JSON.stringify(subsAndOptions)
                res.json subsAndOptions
            else
                logger.error "No subscriber #{req.subscriber.id}"
                res.send 404

    # Set subscriber subscriptions
    app.post '/subscriber/:subscriber_id/subscriptions', (req, res) ->
        subsToAdd = req.body
        logger.verbose "Setting subscriptions for #{req.subscriber.id}: " + JSON.stringify(req.body)
        for eventId, optionsDict of req.body
            try
                event = getEventFromId(eventId)
                options = 0
                if optionsDict? and typeof(optionsDict) is 'object' and optionsDict.ignore_message
                    options |= event.OPTION_IGNORE_MESSAGE
                subsToAdd[event.name] = event: event, options: options
            catch error
                logger.error "Failed to set subscriptions for #{req.subscriber.id}: #{error.message}"
                res.json error: error.message, 400
                return

        req.subscriber.getSubscriptions (subs) ->
            if not subs?
                logger.error "No subscriber #{req.subscriber.id}"
                res.send 404
                return

            tasks = []

            for sub in subs
                if sub.event.name of subsToAdd
                    subToAdd = subsToAdd[sub.event.name]
                    if subToAdd.options != sub.options
                        tasks.push ['set', subToAdd.event, subToAdd.options]
                    delete subsToAdd[sub.event.name]
                else
                    tasks.push ['del', sub.event, 0]

            for eventName, sub of subsToAdd
                tasks.push ['add', sub.event, sub.options]

            async.every tasks, (task, callback) ->
                [action, event, options] = task
                if action == 'add'
                    req.subscriber.addSubscription event, options, (added) ->
                        callback(added)
                else if action == 'del'
                    req.subscriber.removeSubscription event, (deleted) ->
                        callback(deleted)
                else if action == 'set'
                    req.subscriber.addSubscription event, options, (added) ->
                        callback(!added) # should return false
            , (result) ->
                if not result
                    logger.error "Failed to set properties for #{req.subscriber.id}"
                res.send if result then 200 else 400

    # Get subscriber subscription options
    app.get '/subscriber/:subscriber_id/subscriptions/:event_id', (req, res) ->
        req.subscriber.getSubscription req.event, (options) ->
            if options?
                res.json {ignore_message: (options & req.event.OPTION_IGNORE_MESSAGE) isnt 0}
            else
                logger.error "No subscriber #{req.subscriber.id}"
                res.send 404

    # Subscribe a subscriber to an event
    app.post '/subscriber/:subscriber_id/subscriptions/:event_id', (req, res) ->
        options = 0
        logger.verbose "----------------------- subscribe a subscriber to an event"
#        if parseInt req.body.ignore_message
#            options |= req.event.OPTION_IGNORE_MESSAGE
        req.subscriber.addSubscription req.event, options, (added, subscriber, event) =>
            if added? # added is null if subscriber doesn't exist
#                createAndSubscribe subscriber, event, options
                res.send if added then 201 else 204
            else
                logger.error "No subscriber #{req.subscriber.id}"
                res.send 404

    # Unsubscribe a subscriber from an event
    app.delete '/subscriber/:subscriber_id/subscriptions/:event_id', (req, res) ->
        req.subscriber.removeSubscription req.event, (err,deleted) ->
            if not deleted?
                logger.error "No subscriber #{req.subscriber.id}"
            else if not deleted
                logger.error "Subscriber #{req.subscriber.id} was not subscribed to #{req.event.name}"
            res.send if deleted then 204 else 404

    # Event stats
    app.get '/event/:event_id', (req, res) ->
        req.event.info (info) ->
            if not info?
                logger.error "No event #{req.event.name}"
            else
                logger.verbose "Event #{req.event.name} info: " + JSON.stringify info
            res.json info, if info? then 200 else 404

    # Publish an event
    app.post '/event/:event_id', (req, res) ->
        res.send 204
        eventPublisher.publish(req.event, req.body)

    app.post '/send/:subscriber_id', (req, res) ->
        res.send 204
        eventPublisher.send(req.subscriber, req.body)

    app.post '/sendmsg/:jid', (req, res) ->
        res.send 204
        eventPublisher.send(req.subscriber, req.body)

    # Delete an event
    app.delete '/event/:event_id', (req, res) ->
        req.event.delete (deleted) ->
            if not deleted
                logger.error "No event #{req.event.name}"
            if deleted
                res.send 204
            else
                res.send 404

    app.get '/id/:gen_key', (req, res) ->
        req.generator.gen (err, value)->
            if err
                res.json err, 400
            else
                res.json value, 200

