# BetteR [![Build Status](https://travis-ci.org/at1as/BetteR.svg?branch=master)](https://travis-ci.org/at1as/BetteR) [![Gem Version](https://badge.fury.io/rb/better_rest.svg)](http://badge.fury.io/rb/better_rest)

BetteR is a a REST test client written in Ruby and served by Sinatra.

BetteR emphasises both a clean and easy to use interface, as well as allowing users to have a very granuler control over their requests (things like following redirects, verbosity of response and timeout intervals are all configurable). The current feature set is modest, but what it does, it aims to do well.

### Screenshot

![Screenshot](http://at1as.github.io/github_repo_assets/better-rest-client.jpg)

### Usage

The easiest way to use BetteR is to install it using the [Ruby Gem](http://rubygems.org/gems/better_rest) (note that this usually lags a few commits behind):
```bash
$ gem install better_rest
```
Or download the repository here for the latest version and launch via:
```bash
$ ./bin/better_rest
```
To try BetteR, without installing the Gem, it's also hosted on [Heroku](http://better-rest.herokuapp.com/). Note that when run on Heroku, some of functionality won't work due to lack of access to the filesystem (saving logs, etc.). Also note that this is likely to be from an older commit.

### Dependencies

Requires a ruby installation with the following gems installed:
- sinatra
- typhoeus
- vegas
- json

### TODO

* POSTMAN import
* OAuth/OAuth2 support
* Update current deprecated Basic/Digest Auth method
* Download to file
* Support more than one variable
* Delete logs
