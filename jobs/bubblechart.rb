#
#
require 'json'
require 'snmp'

def get_cores(hostlist)
  puts "Getting hostcores"
  hostcores = Hash.new

  hostlist.each do |host|
    manager = SNMP::Manager.new(:host => host)

    cores = 0
    manager.walk([ "1.3.6.1.2.1.25.3.3.1.2" ]) do |row|
      cores = cores + 1
    end

    manager.close

#    print "#{host} - #{cores} cores\n"

    hostcores[host] = cores
  end

  return hostcores
end

def get_loadavgs(hostlist, hostcores)
  data = Array.new
  puts "Getting 5-min load averages"
  hostlist.each do |host|
    #  puts host
    manager = SNMP::Manager.new(:host => host)

    # 1 min, 5 min, 15 min load averages
    # response = manager.get([ "1.3.6.1.4.1.2021.10.1.3.1", "1.3.6.1.4.1.2021.10.1.3.2", "1.3.6.1.4.1.2021.10.1.3.3" ])

    # 5 min load average
    response = manager.get([ "1.3.6.1.4.1.2021.10.1.3.2" ])
    avg = response.each_varbind.first.value.to_f

    manager.close

    cores = hostcores[host]
    ## Work out a guideline utilisation using the number of cores to weight the load average
    util = avg / cores
    util = util.round(2)
#    print "#{host} - #{avg} / #{cores} = #{util}\n"

    val = { :id => host, :value => util, :radius => cores + 20 }
    data.push(val)
  end

  #puts data

  #puts JSON.pretty_generate(data, {})

  send_event('loadavg', { data: data })
end

##
## Store hostcores in a global so we only get it the first time
##
SCHEDULER.every '1m', :first_in => 1 do

  hosts_str = "a b c d"
  hosts = hosts_str.split(' ')

  if (!$hostcores)
    $hostcores = get_cores(hosts)
  end

  get_loadavgs(hosts, $hostcores)
end


