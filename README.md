initial setup

    $ bundle install

run the "cell"

    $ puma cell.ru -p 9000

run the "core"

    $ bundle exec ruby core.rb
	
run the subscribers

	$ puma cell.ru -p 8000

add "categories" to the cell:

    $ curl -XPOST -d'{"name" : "foo"}' http://localhost:9000/categories
    $ curl -XPOST -d'{"name" : "bar"}' http://localhost:9000/categories
    $ curl -XPOST -d'{"name" : "baz"}' http://localhost:9000/categories
	
add a "subscription"

    $ curl -XPOST -d'{"org" : "org0", "app" : "app0", "categories" : ["foo", "bar"] }' http://localhost:8000/subscriptions
	
send "reactions" from the cell

    $ curl -XPOST -d'{"org":"org0", "app" : "app0", "category" : "foo", "effect" : "created" }' http://localhost:9000/reactions
    $ curl -XPOST -d'{"org":"org0", "app" : "app1", "category" : "foo", "effect" : "created" }' http://localhost:9000/reactions
    $ curl -XPOST -d'{"org":"org0", "app" : "app0", "category" : "bar", "effect" : "created" }' http://localhost:9000/reactions

output that the "core" should show:

    < ex=hive.exchanges.categories.foo; rk=org0.app0
	< body={"category":"hive.exchanges.categories.foo","effect":"created","details":{}}

    < ex=hive.exchanges.categories.foo; rk=org0.app1
	< body={"category":"hive.exchanges.categories.foo","effect":"created","details":{}}

    < ex=hive.exchanges.categories.bar; rk=org0.app0
	< body={"category":"hive.exchanges.categories.bar","effect":"created","details":{}}

output that the "suscribers" should show:

    < ex=hive.exchanges.categories.foo; rk=org0.app0
	< body={"category":"hive.exchanges.categories.foo","effect":"created","details":{}}

	# 2nd reaction should be ignored b/c we didn't subscribe to org0.app1

    < ex=hive.exchanges.categories.bar; rk=org0.app0
	< body={"category":"hive.exchanges.categories.bar","effect":"created","details":{}}
