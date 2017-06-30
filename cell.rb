require 'bunny'
require 'multi_json'
require 'sinatra'
require 'sinatra/reloader' if development?

puts '# connecting to the rabbit'
conn = Bunny.new(
  user: ENV.fetch('RABBITMQ_USER', 'rabbit'),
  pass: ENV.fetch('RABBITMQ_USER', 'rabbit'))
conn.start

ch = conn.create_channel

puts '# channel is created'

exchanges = {}

post '/categories' do
  args = MultiJson.decode(request.body.read)

  if args.key?('name')
    name = args['name']
    exchange = "hive.exchanges.categories.#{name}"

    puts "> creating new exchange (name=#{name}; exchange=#{exchange}"
    ex = ch.topic(exchange, auto_delete: true)

    # bind to core with core as destination
    puts "binding to core (rk=#)"
    ch.exchange_bind(exchange, 'hive.exchanges.global.core', routing_key: '#')
    
    exchanges[exchange] = ex
  end
  MultiJson.encode(exchanges.keys)
end

post '/reactions' do
  args = MultiJson.decode(request.body.read)
  if args.key?('org') && args.key?('app') && args.key?('category')
    org_id = args['org']
    app_id = args['app']
    category = "hive.exchanges.categories.#{args['category']}"

    p args
    p exchanges.keys
    if exchanges.key?(category)
      m = {
        category: category,
        effect: args.fetch('effect', 'neutral'),
        details: args.fetch('details', {}),
      }

      puts "> publish: #{m}"
      exchanges[category].publish(MultiJson.encode(m), routing_key: "#{org_id}.#{app_id}")
    else
      puts "! unknown category (category=#{category})"
    end
  end
end
