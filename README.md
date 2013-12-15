# Slurpy

## S(outh)L(ake)U(nion)R(oute)P(lanner)(written in Rub)Y

This gem is a command line utility for http://www.slushuttle.com

## Installation

Install the gem using:

    $ gem install slurpy

## Usage

Use by doing the following:

    $ slurpy next "Day 1" "Convention"

to get the next stop time for any SLU shuttle going from "Day 1 North" to "Convention Seattle".

You can also set your defaults in ~/.slurpy like so

    $ slurpy config --origin 'Day 1 North' --destination 'Convention Center'

and then do

    $ slurpy next
    $ slurpy next --return
    $ slurpy next "Blackfoot"

* The first will search the times for the default route (Day 1 North -> Convention Center).
* The second will search the times for the default route, inverted (Day 1 North -> Convention Center)
* The third will search the times for the default origin (Prime) to Blackfoot

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
