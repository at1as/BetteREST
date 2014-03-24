# BetteR
======

BetteR is a a REST testing client written in Ruby and served by Sinatra. 

BetteR emphasises both a clean and easy to use interface, as well as allowing users to have a very granuler control over their requests (things like following redirects, verbosity of response, timeout intervals are all configurable). The current feature set is modest, but what it does, it aims to do well.

## Usage

    $cd BetteR
    $ruby rest.rb
    
Connect to Sinatra via your browser (swap for 4567 for listening port specified if not using the default)

    localhost:4567

Logs (if enabled from the Settings menu in the UI) will be stored in the following location

    ./logs/YYYY-MM-DD.log

## Dependencies

Requires a ruby installation with the following Gems:
- 'sinatra' (sudo gem install sinatra)
- 'typhoeus' (sudo gem install typhoeus)

## TODO

* Add OAuth/OAuth2 support
* Update current deprecated Basic/Digest Auth method
* Add ability to save requests
* Add file upload and download
