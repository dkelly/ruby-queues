require 'bunny'
require 'faker'
require 'multi_json'

puts '# loading dummy orgs and apps'
orgs = MultiJson.decode(IO.read('apps.json'))

puts '# connecting to the rabbit'
conn = Bunny.new(
  user: ENV.fetch('RABBITMQ_USER', 'rabbit'),
  pass: ENV.fetch('RABBITMQ_USER', 'rabbit'))
conn.start

ch = conn.create_channel

puts '# channel is created'

exchange = 'hive.exchanges.global.core'

ex = ch.topic(exchange)

puts "# created #{exchange}"

q = ch.queue('', exclusive: true)

rks = orgs.inject([]) do |arr, (org_id, apps)|
  arr + apps.map { |app_id| "#{org_id}.#{app_id}" }
end

rks.each do |rk|
  puts "# binding (rk=#{rk})"
  q.bind(ex, routing_key: rk)
end

begin
  q.subscribe(block: true) do |di, props, body|
    puts "< ex=#{di[:exchange]}; rk=#{di[:routing_key]}"
    o = MultiJson.decode(body)
    puts "< body=#{body}"
  end
rescue Interrupt => _
#  puts "! interrupted"
  ch.close
  conn.close
end
