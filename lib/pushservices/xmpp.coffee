xmpp = require 'node-xmpp'
apns = require 'apn'
elements = require './xmpp-elements'
handler = require './xmpp-handler'
sys = require 'sys'
rand = require "generate-key"
class PushServiceXMPP
    tokenFormat: /^[0-9a-f]{8}$/i
    validateToken: (token) ->
        # if PushServiceXMPP::tokenFormat.test(token)
        return token.toLowerCase()

    constructor: (conf, @logger, tokenResolver, eventPublisher) ->
        conf.errorCallback = (errCode, note, device) =>
            @logger?.error("XMPP Error #{errCode} for subscriber #{device?.subscriberId}")
        @hostname = conf.hostname
        @driver = new xmpp.Client({jid: conf.user, password: conf.password, host: conf.host})
        @handler = new handler.Handler(@ )
        @handler.setup()

        eventPublisher.on 'publish_event', (event, payload) =>
            nodeName = "/#{event.eventkey}"

            @logger.verbose "publishing event #{nodeName} from xmpp with payload:"
            @logger.verbose sys.inspect payload
            id = rand.generateKey 7
            if(payload.event?)
                delete payload["event"]
            publishElement = elements.publish(id, nodeName, JSON.stringify(payload), @hostname)
            @logger.verbose 'the xml to be sent is'
            @logger.verbose publishElement
            @handler.send publishElement

    # what's subOptions? 
    # here we should only send to the xmpp pubsub node once based on the event name
    # then mark this envent to ignore the subscritianl push
    push: (subscriber, subOptions, payload) ->
        @logger.verbose "calling xmpp push service's push method, which will be ignored"
        @logger.verbose sys.inspect subOptions



    createEvent : (subscriber, event, options) ->
        nodeName = "/#{event.eventkey}"

        id = rand.generateKey 7
        createNodeElement = elements.create_node(id, nodeName, @hostname)
        @logger.verbose createNodeElement
        @handler.send createNodeElement
        @logger.verbose "now the pubsub node[#{nodeName}] existed, we need to subscribe the subscriber to the node"
        subscriber.get (info) =>
            @logger.verbose "pubsub node is #{nodeName}, subscriber info is"
            @logger.verbose sys.inspect info
            id = rand.generateKey 7
            subscribeElement = elements.subscribe(id, nodeName, "#{info.jiduser}", @hostname)
            @logger.verbose subscribeElement
            @handler.send subscribeElement


    createSubscriber : (subscriber, fields) =>
        if fields.jiduser?
            @logger.verbose 'there is already a jid attached, so ignore'
        else
            @logger.verbose "xmpp create subscriber"
            @logger.verbose sys.inspect fields
#            jid = fields.appkey +"_"+subscriber.id
            jid = "#{fields.appkey}_#{subscriber.id}"
            password = jid
            @logger.verbose "create new user[#{jid}] on xmpp"
            id = rand.generateKey 7
            register = elements.register id, jid, password, @hostname
            @logger.verbose "the xml is:"
            @logger.verbose register
            @handler.send register
            subscriber.set({jiduser: jid})
        


exports.PushServiceXMPP = PushServiceXMPP
