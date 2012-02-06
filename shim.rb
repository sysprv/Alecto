#! jruby
# vim:set ts=8 sts=4 sw=4 ai et:

require './shim_classes'
require 'rubygems'
require 'sinatra/base'

class Shim < Sinatra::Base
    get '/shim/hello' do
        'Hello World!'
    end

    post '/shim/run/*' do
        resolver = Resolver.new
        shimresponse = resolver.resolve(request)

        status shimresponse.status
        headers shimresponse.headers
        body shimresponse.body
    end

    run! if app_file == $0
end
