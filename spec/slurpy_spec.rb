require 'spec_helper'

describe "slurpy" do

  before :each do
    #IO.any_instance.stub(:puts)
  end

  after :each do
    Slurpy.invalidate_cache
  end

  describe 'caching' do
    it "retrieves data from the cache instead of querying the service" do
      response = OpenStruct.new
      response.response_body = '{}'

      Typhoeus.should_receive(:get).once.and_return(response)

      Slurpy.get_times
      sleep 1
      Slurpy.get_times
    end
  end

  describe "get_stops" do

    before :each do
      Slurpy.should_receive(:request).with(:stops).and_return(
        [{'Description' => 'Day 1 North'},
         {'Description' => 'Day 1 South'},
         {'Description' => 'Convention'}])
    end

    it "returns the stops containing the query string" do
      Slurpy.get_stop('Day 1 North').should eql [[{'Description' => 'Day 1 North'}], 'Day 1 North']
    end

    it "errors if no stop matches" do
      Slurpy.should_receive(:error).once.with("No stop matches 'Unexisting', sorry.")

      Slurpy.get_stop('Unexisting')
    end

    it "errors if too many stops match" do
      Slurpy.should_receive(:error).once.with("Your request for stop 'Day 1' is not specific enough. " \
                                              "Pick one: [\"Day 1 North\", \"Day 1 South\"]")

      Slurpy.get_stop('Day 1')
    end
  end

  describe "get_route" do
    before :each do
      Slurpy.should_receive(:request).with(:routes).and_return(
        [{'Description' => '(R1) Route'}, 
         {'Description' => '(R2) Route'},
         {'Description' => '(R11) Route'}])
    end

    it "returns the routes containing the query string" do
      Slurpy.get_route('1').should eql [{'Description' => '(R1) Route'}]
    end

    it "errors if no route matches" do
      Slurpy.should_receive(:error).once.with("No route 'R22', sorry.")

      Slurpy.get_route('22')
    end
  end

  describe "next" do

    before :each do
      Slurpy.should_receive(:get_stop).at_least(:once).with('Day 1').and_return([[{'RouteStopID' => '1'}], 'Day 1 North'])
      Slurpy.should_receive(:get_stop).at_least(:once).with('Convention').and_return([[{'RouteStopID' => '2'}], 'Convention Center'])
    end

    it "returns the next shuttles between a and b" do

      Slurpy.should_receive(:get_route_by_id).at_least(:once).with('1').and_return({'Description' => 'Route R10'})
      Slurpy.should_receive(:get_route_by_id).at_least(:once).with('2').and_return({'Description' => 'Route R11'})  

      Slurpy.should_receive(:get_times).at_least(:once).times.and_return([
        {"RouteID" => "1", "RouteStopID" => "1", "StopTimes" =>
          [{"DepartureTime" => "\/Date\(0\)/"}, {"DepartureTime" => "\/Date\(10000\)/"}]},
        {"RouteID" => "1", "RouteStopID" => "2", "StopTimes" =>
          [{"DepartureTime" => "\/Date\(10000\)/"}, {"DepartureTime" => "\/Date\(30000\)/"}]},
        {"RouteID" => "2", "RouteStopID" => "1", "StopTimes" =>
          [{"DepartureTime" => "\/Date\(1000\)/"}, {"DepartureTime" => "\/Date\(11000\)/"}]},
        {"RouteID" => "2", "RouteStopID" => "2", "StopTimes" =>
          [{"DepartureTime" => "\/Date\(11000\)/"}, {"DepartureTime" => "\/Date\(30000\)/"}]}
      ])

      Slurpy.start(["next", "Day 1", "Convention"])

      expect(capture(:stdout) { Slurpy.start(["next", "Day 1", "Convention"]) })
        .to eq("Searching routes from 'Day 1 North' to 'Convention Center'...\n" \
               "Route R10 - Departure: 19:00 Arrival: 21:46\n" \
               "Route R11 - Departure: 19:16 Arrival: 22:03\n")
    end

    it "errors if no route between a and b exists" do
      Slurpy.should_receive(:error).once.with("No shuttles from 'Day 1 North' to 'Convention Center', sorry. " \
        "See http://www.slushuttle.com/ for more details.")

      Slurpy.should_receive(:get_times).at_least(:once).times.and_return([
        {"RouteID" => "1", "RouteStopID" => "1", "StopTimes" =>
          [{"DepartureTime" => "\/Date\(0\)/"}, {"DepartureTime" => "\/Date\(10000\)/"}]},
        {"RouteID" => "1", "RouteStopID" => "3", "StopTimes" =>
          [{"DepartureTime" => "\/Date\(10000\)/"}, {"DepartureTime" => "\/Date\(30000\)/"}]},
        {"RouteID" => "2", "RouteStopID" => "1", "StopTimes" =>
          [{"DepartureTime" => "\/Date\(1000\)/"}, {"DepartureTime" => "\/Date\(11000\)/"}]},
        {"RouteID" => "2", "RouteStopID" => "4", "StopTimes" =>
          [{"DepartureTime" => "\/Date\(11000\)/"}, {"DepartureTime" => "\/Date\(30000\)/"}]}
      ])

      Slurpy.start(["next", "Day 1", "Convention"])
    end
  end

  describe "extract_date" do
    it "converts an epoch date to time" do
      Slurpy.extract_date("\/Date\(10000\)/").should eql "21:46"
    end
  end
end