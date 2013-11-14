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
logger = require 'winston'
sys = require 'sys'

if settings.loglevel?
    logger.remove(logger.transports.Console);
    logger.add(logger.transports.Console, { level: settings.loglevel });

if settings.server?.redis_auth?
    redis.auth(settings.server.redis_auth)

createSubscriber = (fields, cb) ->
    logger.verbose "creating subscriber proto = #{fields.proto}, token = #{fields.token}"
    throw new Error("Invalid value for `proto:#{fields.proto}'") unless service = pushServices.getService(fields.proto)
    throw new Error("Invalid value for `token:#{fields.token}'") unless fields.token = service.validateToken(fields.token)
    logger.verbose "-------------- create subscriber: app key: " + fields.appkey
    # Subscriber::create(redis, fields, cb)
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
eventPublisher = new EventPublisher(pushServices)

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

rest_server.configure ->
    rest_server.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
    rest_server.use(express.logger('[:date] :remote-addr :method :url :status :response-time')) if settings.server?.access_log
    rest_server.use(express.limit('1mb')) # limit posted data to 1MB
    rest_server.use(express.bodyParser())
    rest_server.use(rest_server.router)
    rest_server.enable('trust proxy')
    rest_server.disable('x-powered-by');
    rest_server.use(express.responseTime())
#    rest_server.use(App::auth())





getEventFromId = (appkey, id) ->
    return new Event(redis,appkey, id)

testSubscriber = (subscriber) ->
    pushServices.push(subscriber, null, new Payload({msg: "Test", "data.test": "ok"}))


getAppFromKey = (id) ->
    return new Application(redis, id)

rest_server.all '*', (req, res, next) ->
    try
#        if req.header.appkey?
        appkey = req.get('appkey' )
        throw new Error("missing app key in request header") if not appkey?
        # appkey = "performance-app"
        logger.verbose("------------------- " + appkey)
        req.application = getAppFromKey(appkey)
        next()
    catch error
        res.json error: error.message, 400
# set up subscriber instance from subscriber_id
rest_server.param 'subscriber_id', (req, res, next, id) ->
  try
    req.subscriber = new Subscriber(redis, req.params.subscriber_id)
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



createAndSubscribe = (subscriber, e, option, option) ->
    pushServices.createEvent(subscriber, e, option)

require('./lib/api').setupRestApi(rest_server, createSubscriber, getEventFromId, testSubscriber, eventPublisher, createAndSubscribe)
if eventSourceEnabled
    require('./lib/eventsource').setup(rest_server, eventPublisher)

port = settings?.server?.tcp_port ? 80
rest_server.listen port
logger.info "Listening on tcp port #{port}"