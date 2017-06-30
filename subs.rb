require 'bunny'
require 'multi_json'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'uuid'

puts '# loading dummy orgs and apps'
orgs = MultiJson.decode(IO.read('apps.json'))

puts '# connecting to the rabbit'
conn = Bunny.new(
  user: ENV.fetch('RABBITMQ_USER', 'rabbit'),
  pass: ENV.fetch('RABBITMQ_USER', 'rabbit'))
conn.start

ch = conn.create_channel

puts '# channel is created'

subs = {}

post '/subscriptions' do
  args = MultiJson.decode(request.body.read)
  if args.key?('org') && args.key?('app')
    sub_id = UUID.generate
    exchange = "hive.exchanges.subscriptions.#{sub_id}"

    puts "# creating new exchange (exchange=#{exchange})"
    ex = ch.topic(exchange)

    org_id = args['org']
    app_id = args['app']

    args.fetch('categories', []).each do |cat|
      source = "hive.exchanges.categories.#{cat}"

      # TODO: let's everything through on org.app... decide if this is
      # correct or if it should be #
      puts "# binding to source (source=#{source}; org=#{org_id}; app=#{app_id})"
      ex.bind(source, routing_key: "#{org_id}.#{app_id}.#")
    end

    # single q for now
    rk = "#{org_id}.#{app_id}"
    puts "# binding queue (rk=#{rk})"
    q = ch.queue('', exclusive: true)
    q.bind(ex, routing_key: rk)

    q.subscribe(block: false) do |di, props, body|
      puts "< ex=#{di[:exchange]}; rk=#{di[:routing_key]}"
      o = MultiJson.decode(body)
      puts "< body=#{body}"
    end
    
    subs[sub_id] = {
      ex: ex,
      qs: [q]
    }
    
    {}
  else
    puts '! missing org and app'
  end
end
