exports['loglevel'] = 'verbose'

exports.server =
    redis_port: 6379
    redis_host: 'localhost'
    # redis_socket: '/var/run/redis/redis.sock'
    # redis_auth: 'password'
    tcp_port: 7894
    access_log: yes
#    acl:
        # restrict publish access to private networks
#        publish: ['127.0.0.1', '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16']
#    auth:
#        # require HTTP basic authentication, username is 'admin' and
#        # password is 'password'
#        #
#        # HTTP basic authentication overrides IP-based authentication
#        # if both acl and auth are defined.
#        admin:
#            password: 'password'
#            realms: ['register', 'publish']

exports['event-source'] =
    enabled: yes

exports['apns'] =
    enabled: no
    class: require('./lib/pushservices/apns').PushServiceAPNS
    # Convert cert.cer and key.p12 using:
    # $ openssl x509 -in cert.cer -inform DER -outform PEM -out apns-cert.pem
    # $ openssl pkcs12 -in key.p12 -out apns-key.pem -nodes
    cert: 'apns-cert.pem'
    key: 'apns-key.pem'
    cacheLength: 100
    # Selects data keys which are allowed to be sent with the notification
    # Keep in mind that APNS limits notification payload size to 256 bytes
    payloadFilter: ['messageFrom']
    # uncommant for dev env
    #gateway: 'gateway.sandbox.push.apple.com'
    #address: 'feedback.sandbox.push.apple.com'


exports['xmpp'] = 
  enabled: yes
  class: require('./lib/pushservices/xmpp').PushServiceXMPP
  user: 'admin@hoho3'
  password: 'admin123456'
  host: '210.76.97.31'
  hostname: 'hoho3'

exports['http'] =
    enabled: yes
    class: require('./lib/pushservices/http').PushServiceHTTP
