# BetteR

BetteR is a a REST testing client written in Ruby and served by Sinatra. 

BetteR emphasises both a clean and easy to use interface, as well as allowing users to have a very granuler control over their requests (things like following redirects, verbosity of response, timeout intervals are all configurable). The current feature set is modest, but what it does, it aims to do well.

## Usage

    $cd BetteR
    $./BetteR
    
BetteR will run rest.rb, which will content to a Sinatra session via your browser (browser should launch automatically, but otherwise the default location is localhost:5678)

Logs (if enabled from the Settings menu in the UI) will be stored in the following location

    ./logs/YYYY-MM-DD.log

## Dependencies

Requires a ruby installation with the following Gems:
- 'sinatra' (sudo gem install sinatra)
- 'typhoeus' (sudo gem install typhoeus)
- 'vegas' (sudo gem install vegas)

Note that the vegas gem is only necessary in order to use ./BetteR to call rest.rb. Launching rest.rb (via 'ruby rest.rb') will avoid the need for this gem.

## TODO

* Add OAuth/OAuth2 support
* Update current deprecated Basic/Digest Auth method
* Add ability to save requests
* Add download to file
* Add parallel requests
