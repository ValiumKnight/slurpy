# Ruby things
require 'pp'
require 'json'
require 'date'
require 'yaml'

# Ruby gems
require 'typhoeus'
require 'thor'
require 'api_cache'
require 'moneta'

class Slurpy <  Thor
  DEFAULTS_FILE = "#{Dir.home}/.slurpy"
  CACHE_FOLDER = '/tmp/slurpy/cache'

  BASE_URL = 'http://www.slushuttle.com/Services/JSONPRelay.svc/'

  RESOURCES = {
    times: 'GetScheduleFutureStopTimes?TimesPerStopString=2',
    stops: 'GetStops',
    routes: 'GetRoutes'
  }

  def initialize *args
    super
    APICache.store = Moneta.new(:File, dir: CACHE_FOLDER)
  end

  option :return, :type => :boolean

  desc 'next origin destination', 'Returns the next routes from origin to destination'
  def next(origin = defaults['origin'], destination = defaults['destination'])

    origin, destination = destination, origin if options[:return]

    to_origin_shuttles, origin_name = Slurpy.shuttles_for_stop origin
    to_destination_shuttles, destination_name = Slurpy.shuttles_for_stop destination

    puts "Searching routes from '#{origin_name}' to '#{destination_name}'..."

    Slurpy.error 'Do you really want to go in circles?' if origin_name == destination_name

    origin_to_destination_shuttles = 
      to_origin_shuttles
        .select do |route_id, time|
          to_destination_shuttles[route_id] &&
            to_origin_shuttles[route_id] < to_destination_shuttles[route_id]
        end

    Slurpy.error "No shuttles from '#{origin_name}' to '#{destination_name}' right now, sorry. " \
                 "See http://www.slushuttle.com/ for more details." \
                   if origin_to_destination_shuttles.empty?

    origin_to_destination_shuttles.each do |route_id, time|
      puts "#{Slurpy.get_route_by_id(route_id)['Description']} " \
           "- Departure: #{to_origin_shuttles[route_id]} " \
           "Arrival: #{to_destination_shuttles[route_id]}"
    end
  end

  method_option :origin, :type => :string, :required => true
  method_option :destination, :type => :string, :required => true

  desc 'config', 'Sets the defaults origin and destination'
  def config

    settings = { 
      'origin' => options[:origin],
      'destination' => options[:destination]
    }

    File.open(DEFAULTS_FILE, "w") do |file|
      file.write settings.to_yaml
    end
  end

  private #####################################################################

  def defaults
    Slurpy.error 'Slurpy needs params unless .slurpy exists' unless 
      File.exists?(DEFAULTS_FILE)

    @defaults ||= ::YAML::load_file(DEFAULTS_FILE)

    Slurpy.error 'Invalid default origin' unless @defaults['origin']
    Slurpy.error 'Invalid default destination' unless @defaults['destination']

    @defaults
  end

  def self.error(message)
    puts "ERROR: #{message}"
    exit 1
  end

  def self.shuttles_for_stop(stop)
    stops_info, stop_name = get_stop(stop)

    stop_ids = stops_info.map { |stop_info| stop_info['RouteStopID'] }

    shuttles = get_times
      .select do |time|
        stop_ids.include? time['RouteStopID']
      end
      .inject({}) do |route_to_stop_times, times|
        route_to_stop_times.update(
          times['RouteID'] => extract_date(times['StopTimes']
                                            .first['DepartureTime'])
        )
      end

    return shuttles, stop_name
  end

  def self.from_cache(resource, lambda)
    APICache.get(resource, period: 1, cache: 10) do
      lambda.call
    end
  end

  def self.invalidate_cache
    Moneta.new(:File, dir: CACHE_FOLDER).clear
  end

  def self.request(resource)
    Slurpy.from_cache "res::#{resource}", lambda {
      JSON.parse(
        Typhoeus.get("#{BASE_URL}#{RESOURCES[resource]}")
          .response_body)
    }
  end

  def self.get_times
    request(:times)
  end

  def self.get_route(route_num)
    Slurpy.from_cache "route::#{route_num}", lambda {
      infos = request(:routes)
        .select {|route| route['Description'].include? "(R#{route_num})" }

      Slurpy.error "No route 'R#{route_num}', sorry." unless infos.size == 1

      infos
    }
  end

  def self.get_stop(query)
    Slurpy.from_cache "stop::#{query}", lambda {
      infos = request(:stops)
        .select { |stop| stop['Description'].downcase.include? query.downcase }

      stops = infos.map{ |stop| stop['Description']}.to_set.to_a

      error = "No stop matches '#{query}', sorry." if stops.empty?

      error = "Your request for stop '#{query}' is not specific enough. " \
              "Pick one: #{stops.inspect}" if stops.size > 1

      Slurpy.error error if error

      return infos, stops.first
    }
  end

  def self.get_route_by_id(route_id)
    request(:routes)
      .select { |route| route['RouteID'] == route_id.to_i }.first
  end

  def self.extract_date(date)
    epoch_time_in_seconds = date
        .to_s 
        .scan(%r(/Date\((\d+)\)/))
        .flatten.first

    Slurpy.error 'Failed to retrieve date from #{date}' unless epoch_time_in_seconds
        
    Time.at(epoch_time_in_seconds.to_i).strftime('%R')
  end
end

Slurpy.start(ARGV)