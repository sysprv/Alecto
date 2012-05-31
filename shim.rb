#! jruby
# vim:set ts=8 sts=4 sw=4 ai et:

require 'rubygems'
# require 'bundler/setup'
require 'sinatra/base'
require 'rules'
require 'shimrequest'
require 'resolver'

class Shim < Sinatra::Base

    get '/shim/rules' do
        # headers { 'Content-Type' => 'text/plain; charset=UTF-8' }
        rules = Rules.instance
        body rules.rules_as_json_string + "\r\n"
    end

    post '/shim/rules' do
        rules = Rules.instance
        rules.add_or_update(request.body.read).to_s + "\r\n"
    end

    delete '/shim/rules/:rulenum' do
        Rules.instance.delete(params[:rulenum].to_i).to_s + "\r\n"
    end

    get '/shim/hello' do
        'Hello World!'
    end

    post '/shim/run/*' do
        shimresponse = Resolver.resolve(ShimRequest.fromSinatraRequest(request))

        status shimresponse.status
        headers shimresponse.headers
        body shimresponse.body
    end

    run! if app_file == $0
end
