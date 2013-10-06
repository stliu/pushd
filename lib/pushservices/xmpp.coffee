xmpp = require 'node-xmpp'
apns = require 'apn'
elements = require './xmpp-elements'
handler = require './xmpp-handler'
sys = require 'sys'
class PushServiceXMPP
    tokenFormat: /^[0-9a-f]{8}$/i
    validateToken: (token) ->
        if PushServiceXMPP::tokenFormat.test(token)
            return token.toLowerCase()

    constructor: (conf, @logger, tokenResolver, eventPublisher) ->
        conf.errorCallback = (errCode, note, device) =>
            @logger?.error("XMPP Error #{errCode} for subscriber #{device?.subscriberId}")

        @driver = new xmpp.Client({jid: conf.user, password: conf.password, host: conf.host})
        new handler.Handler(@ ).setup()

        eventPublisher.on 'publish_event', (event, playload) =>
            @logger.verbose "publishing event #{event.key} from xmpp with payload:"
            @logger.verbose sys.inspect playload
            publishElement = elements.publish(event.name, event.name, playload.msg)
            @logger.verbose 'the xml to be sent is'
            @logger.verbose publishElement
            @driver.send publishElement

    # what's subOptions? 
    # here we should only send to the xmpp pubsub node once based on the event name
    # then mark this envent to ignore the subscritianl push
    push: (subscriber, subOptions, payload) ->
        @logger.verbose "calling xmpp push service's push method, which will be ignored"
        @logger.verbose sys.inspect subOptions



    createEvent : (subscriber, event, options) ->
        if event.exists is 1
            @logger.debug "pubsub node #{event.name} is not existed yet, about to create"
            createNodeElement = elements.create_node(event.name, event.name)
            @logger.verbose createNodeElement
            @driver.send createNodeElement
        @logger.verbose "now the pubsub node[#{event.name}] existed, we need to subscribe the subscriber to the node"
        subscriber.get (info) =>
            @logger.verbose "pubsub node is #{event.name}, subscriber info is"
            @logger.verbose sys.inspect info
            subscribeElement = elements.subscribe(info.jid, event.name, info.jid)
            @logger.verbose subscribeElement
            @driver.send subscribeElement


    createSubscriber : (subscriber, fields) ->
        if fields.jid?
            @logger.verbose 'there is already a jid attached, so ignore'
        else
            jid = subscriber.id
            password = subscriber.id
            @logger.verbose "create new user[#{jid}] on xmpp"
            register = elements.register subscriber.id, jid, password
            @logger.verbose "the xml is:"
            @logger.verbose register
            @driver.send register
            subscriber.set({jid: jid})
        


exports.PushServiceXMPP = PushServiceXMPP
