## 数据结构

### subscribers

type: sorted set
desc: 用来保存device id

### subscribers:@id

type: hash
desc: 用来保存一个subscriber(device)的注册信息

	 1) "proto"
	 2) "apns"
	 3) "token"
	 4) "fe66489f304dc75b8d6e8200dff8a456e8daeacec428b427e9518741c92c6660"
	 5) "lang"
	 6) "fr"
	 7) "badge"
	 8) "0"
	 9) "updated"
	10) "1380860676"
	11) "created"
	12) "1380860676"

### subscribers:@id:evts

type: sorted set
desc: 用来保存一个subscriber都关注了哪些events, 保存的是event name

### events

type: set
desc: 用来保存所有的event name

### event:@event_name

type: hash
desc: 某一个event的基本信息

	1) "created"
	2) "1380860988"
	3) "total"
	4) "1"
	5) "last"
	6) "1380868937"


### event:@event_name:subs

type: zset
desc: 每个event的订阅用户列表, 里面保存的是device/subscriber id

### tokenmap

type: hash
desc: 保存的是device token到device id之间的映射

	1) "apns:fe66489f304dc75b8d6e8200dff8a456e8daeacec428b427e9518741c92c6660"
	2) "vrrcWx96oOA"

## 创建event

这个时候, 实际上做的事情是, 把一个device添加到一个event上面, 如果这个event还不存在, 则创建

这时候, xmpp需要做的事情是在xmpp server上创建一个pubsub node

在pushd中, 是通过下面的api来把一个device注册到一个event上的

	POST /subscriber/SUBSCRIBER_ID/subscriptions/EVENT_NAME
	
这个api是在_api.coffee_中定义的, 然后这个请求转发给 _subscriber.coffee_

	subscriber.addSubscription req.event, options, (added) ->
            if added? # added is null if subscriber doesn't exist
                res.send if added then 201 else 204
            else
                logger.error "No subscriber #{req.subscriber.id}"
                res.send 404
                
这个是coffee的语法, 转化成javascript则是

	subscriber.addSubscription(req.event, optioins, function(added){
		if(added?){
			res.send if added then 201 else 204
		}else {
			logger.error "No subscriber #{req.subscriber.id}"
	        res.send 404
		}                
	})                	

## 注册device