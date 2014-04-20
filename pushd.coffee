express = require 'express'
dgram = require 'dgram'
zlib = require 'zlib'
url = require 'url'
Netmask = require('netmask').Netmask
settings = require './settings'
redis = require('redis').createClient(settings.server.redis_socket or settings.server.redis_port, settings.server.redis_host)
Subscriber = require('./lib/subscriber').Subscriber
EventPublisher = require('./lib/eventpublisher').EventPublisher
Event = require('./lib/event').Event
Application = require('./lib/app').App
PushServices = require('./lib/pushservices').PushServices
Payload = require('./lib/payload').Payload
Generator = require('./lib/idgenerator').Generator
logger = require 'winston'
sys = require 'sys'

if settings.loglevel?
    logger.remove(logger.transports.Console);
    logger.add(logger.transports.Console, {level: settings.loglevel});
#    logger.add(logger.transports.File, { level: settings.loglevel, filename: 'pushd.log', maxsize : 1024 * 1024 * 5 });
#    logger.handleExceptions(new logger.transports.File({ level: settings.loglevel, filename: 'pushd-exception.log', maxsize : 1024 * 1024 * 5 }));


if settings.server?.redis_auth?
    redis.auth(settings.server.redis_auth)

createSubscriber = (fields, cb) ->
    logger.verbose "creating subscriber proto = #{fields.proto}, token = #{fields.token}"
    throw new Error("Invalid value for `proto:#{fields.proto}'") unless service = pushServices.getService(fields.proto)
    throw new Error("Invalid value for `token:#{fields.token}'") unless fields.token = service.validateToken(fields.token)
    logger.verbose "-------------- create subscriber: app key: " + fields.appkey
    Subscriber::create redis, fields, (subscriber, created, tentatives) =>
        logger.verbose "-------------- subscriber.create: app key: " + fields.appkey
        # give push services a chance
        if created and service.createSubscriber?
          service.createSubscriber subscriber, fields
        cb subscriber, fields, tentatives

tokenResolver = (proto, token, cb) ->
    Subscriber::getInstanceFromToken redis, proto, token, cb

eventSourceEnabled = no
pushServices = new PushServices()
eventPublisher = new EventPublisher(pushServices, logger)

for name, conf of settings when conf.enabled
    logger.info "Registering push service: #{name}"
    if name is 'event-source'
        # special case for EventSource which isn't a pluggable push protocol
        eventSourceEnabled = yes
    else
        pushServices.addService(name, new conf.class(conf, logger, tokenResolver, eventPublisher))

checkUserAndPassword = (username, password) =>
    if settings.server?.auth?
        if not settings.server.auth[username]?
            logger.error "Unknown user #{username}"
            return false
        passwordOK = password is settings.server.auth[username].password
        if not passwordOK
            logger.error "Invalid password for #{username}"
        return passwordOK
    return false

rest_server = express()

allowCrossDomain = (req, res, next) =>
    res.header('Access-Control-Allow-Origin', '*')
    res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE')
    res.header('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type')
    next()

rest_server.configure ->
    rest_server.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
    rest_server.use(express.logger('[:date] :remote-addr :method :url :status :response-time')) if settings.server?.access_log
    rest_server.use(express.limit('1mb')) # limit posted data to 1MB
    rest_server.use(express.bodyParser())
    rest_server.use(allowCrossDomain)
    rest_server.use(rest_server.router)
    rest_server.enable('trust proxy')
    rest_server.disable('x-powered-by');
    rest_server.use(express.responseTime())

getSubscriber = (appkey, subscriber_id) ->
    return new Subscriber(redis, subscriber_id)

getSubscriberFromJid = (appkey, jid, cb) ->
    redis.get "jid:#{jid}", (err, subscriber_id) ->
        if not subscriber_id? or err?
            return cb(null)
        subscriber = getSubscriber(appkey, subscriber_id)
        cb(subscriber)


getEventFromId = (appkey, id) ->
    return new Event(redis,"#{appkey}:#{id}")

testSubscriber = (subscriber) ->
    pushServices.push(subscriber, null, new Payload({msg: "Test", "data.test": "ok"}))


getAppFromKey = (id) ->
    return new Application(redis, id)

rest_server.all '*', (req, res, next) ->
    try
        appkey = req.get('appkey' )
        throw new Error("missing app key in request header") if not appkey? and not (/^\/id\//).test(req.path)
        logger.verbose("------------------- " + appkey)
        req.application = getAppFromKey(appkey)
        next()
    catch error
        res.json error: error.message, 400

# set up subscriber instance from subscriber_id
rest_server.param 'subscriber_id', (req, res, next, id) ->
  try
    req.subscriber = getSubscriber(req.application.id, req.params.subscriber_id)
    delete req.params.subscriber_id
    next()
  catch error
    res.json error: error.message, 400

# set up event instance from event_id
rest_server.param 'event_id', (req, res, next, id) ->
    try
        req.event = getEventFromId(req.application.id, req.params.event_id)
        delete req.params.event_id
        next()
    catch error
        res.json error: error.message, 400

rest_server.param 'gen_key', (req, res, next, id) ->
    try
        req.generator = new Generator(redis, "generator:#{req.params.gen_key}")
        delete req.params.gen_key
        next()
    catch error
        res.json error: error.message, 400

rest_server.param 'jid', (req, res, next, id) ->
    try
        getSubscriberFromJid req.application.id, req.params.jid, (subscriber)->
            if not subscriber?
                return res.json error: "can't find subscriber from jid[#{req.params.jid}]", 400
            req.subscriber = subscriber
            logger.verbose "found subscriber[#{subscriber.id}] by jid[#{req.params.jid}]"
            delete req.params.jid
            next()
    catch error
        logger.error("run into error: " + error.message)
        res.json error: error.message, 400

#createAndSubscribe = (subscriber, e, option) ->
#    pushServices.createEvent(subscriber, e, option)

require('./lib/api').setupRestApi(logger, rest_server, createSubscriber, getEventFromId, testSubscriber, eventPublisher)

if eventSourceEnabled
    require('./lib/eventsource').setup(rest_server, eventPublisher)

port = settings?.server?.tcp_port ? 80
rest_server.listen port
logger.info "Listening on tcp port #{port}"