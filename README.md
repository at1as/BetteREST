# BetteR [![Gem Version](https://badge.fury.io/rb/better_rest.svg)](http://badge.fury.io/rb/better_rest)

BetteR is a a REST testing client written in Ruby and served by Sinatra.

BetteR emphasises both a clean and easy to use interface, as well as allowing users to have a very granuler control over their requests (things like following redirects, verbosity of response and timeout intervals are all configurable). The current feature set is modest, but what it does, it aims to do well.

## Screenshot

![Screenshot](http://at1as.github.io/github_repo_assets/BetteR-reqeust.jpg)

## Usage

The easiest way to use BetteR is to install it using the gem (see - http://rubygems.org/gems/better_rest):
```bash
$ gem install better_rest
```
Or download the repository here for the latest version and launch BetteR via:
```bash
$ ./bin/better_rest
```
## Logs

Logs (if enabled from the Settings menu in the UI) will be stored in the following location
```bash
./log/YYYY-MM-DD.log
```
## Dependencies

Requires a ruby installation with the following gems installed (installation via the gem will eventually take care of these dependencies, but currently does not):
- sinatra
- typhoeus
- vegas
- json

## TODO

* Add OAuth/OAuth2 support
* Update current deprecated Basic/Digest Auth method
* Add ability to save requests
* Add download to file
* Add support for more than one variable
* Add a horizontal page layout
