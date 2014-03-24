BetteR
======

BetteR is a a REST testing client written in Ruby and served by Sinatra. 

BetteR emphasises a both a clean and easy to understand interface, as well as allowing users to have a very granuler control over their requests (things like following redirects, verbosity of response, timeout intervals are all configurable). 

## Usage

    $cd BetteR
    $ruby rest.rb
    
Connect to Sinatra via your browser (swap for 4567 for listening port specified if not using the default)

    localhost:4567

## Dependencies

Requires a ruby installation with the following Gems:
- 'sinatra' (sudo gem install sinatra)
- 'typhoeus' (sudo gem install typhoeus)

## TODO

* Add OAuth/OAuth2 support
* Add ability to save requests
* Add file upload and download
