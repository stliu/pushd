xmpp = require 'node-xmpp'

exports.register = (id, jid, password, hostname='ac2') ->
    return new xmpp.Element('iq', {id:id, to:hostname, type:'set'})
    .c('query', {xmlns:'jabber:iq:register'})
    .c('username').t("#{jid}")
    .up()
    .c('password').t(password)
    .up()
    .c('email')
    .up()
    .c('registered')
    .up()
    .c('name')
    .root()
exports.presence = () ->
  return new xmpp.Element('presence', {}).c('show').t('chat').up().c('status').t('this is the push server, enjoy')

exports.publish = (id, node, message, hostname="ac2") ->
    return new xmpp.Element('iq', {
        id: id,
        to: "pubsub.#{hostname}",
        type: 'set'
    }).c('pubsub', {
        xmlns: 'http://jabber.org/protocol/pubsub'
    }).c('publish', {
        node: node
    }).c('item').c('entry', {
        xmlns: 'easemob:pubsub'
    }).t(message).root()

exports.subscribe = (id, node, jid, hostname="ac2") ->
  return new xmpp.Element('iq', {
    id: id,
    to: "pubsub.#{hostname}",
    type: 'set',
    from: "admin@#{hostname}"
  } ).c('pubsub', {
    xmlns: 'http://jabber.org/protocol/pubsub#owner'
  }).c('subscriptions', {
    node: node
  })
  .c('subscription',{jid: jid, subscription:'subscribed'})
  .root()
#exports.subscribe = (id, node, jid) ->
#    return new xmpp.Element('iq', {
#        id: id,
#        to: 'pubsub.ac2',
#        type: 'set',
#        from: 'admin@ac2'
#    } ).c('pubsub', {
#        xmlns: 'http://jabber.org/protocol/pubsub'
#    }).c('subscribe', {
#        node: node,
#        jid: jid
#    }).root()

exports.create_node = (id, node_name, hostname="ac2") ->
    return new xmpp.Element('iq', {
        id: id,
        to: "pubsub.#{hostname}",
        type: 'set'
    }).c('pubsub', {
        xmlns: 'http://jabber.org/protocol/pubsub'
    }).c('create', {
        node: node_name
    }).up()
    .c('configure', {})
    .c('x', {
        xmlns: 'jabber:x:data',
        type: 'submit'
    })
        .c('field', {
        'var': 'pubsub#persit_items', type: 'boolean'
    }).c('value').t('0')
        .up()
    .up()
        .c('field', {
        'var': 'pubsub#presence_based_delivery', type: 'boolean'
    }).c('value').t('0')
        .up().up()
        .c('field', {
        'var': 'pubsub#deliver_payloads', type: 'boolean'
    }).c('value').t('1')
        .up().up()
        .c('field', {
          'var': 'pubsub#persist_items', type: 'boolean'
          }).c('value').t('0')
          .up().up()    
        .c('field', {
        'var': 'pubsub#access_model', type: 'list-single'
    }).c('value').t('open')
        .up().up()
        .c('field', {
        'var': 'pubsub#publish_model', type: 'list-single'
    }).c('value').t('open')
        .up().up()
#        .c('field', {
#        'var': 'pubsub#max_items', type: 'list-single'
#    }).c('value').t('-1')
#        .up().up()
        .c('field', {
        'var': 'pubsub#subscribe', type: 'boolean'
    }).c('value').t('1')
        .up().up()
        .c('field', {
        'var': 'pubsub#notify_config', type: 'boolean'
    }).c('value').t('0')
        .up().up()
        .c('field', {
        'var': 'pubsub#notify_delete', type: 'boolean'
    }).c('value').t('0')
        .up().up()
        .c('field', {
        'var': 'pubsub#notify_retract', type: 'boolean'
    }).c('value').t('0')
    .root()

