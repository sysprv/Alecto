#! jruby

require './shim_classes'
require 'rubygems'
require 'sinatra/base'

class Shim < Sinatra::Base
    @@resolver = Resolver.new

    get '/shim/hello' do
        'Hello World!'
    end

    post '/shim/run' do
        shimresponse = @@resolver.resolve(request)

        status shimresponse.status
        headers shimresponse.headers
        body shimresponse.body
    end

    run! if app_file == $0
end
