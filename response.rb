# vim:set ts=8 sts=4 sw=4 ai et:

# Used to hide details of various http containers
# from Alecto.
#
# Objects of this class would be very close to the
# final response sent out from "us" to the client.
#
# Does not support streaming.
#
# Sets Cross-Origin Resource Shading (CORS) headers on
# each response so that any client will be able
# to access us without getting stopped by cross-origin
# policies in the browser.
#
class Response
    # status -> int
    # content_encoding -> string
    # headers -> map
    # body -> string
    attr_reader :status, :headers, :body

    # CORS - Cross-Origin Resource Sharing
    # https://developer.mozilla.org/en-US/docs/HTTP_access_control
    @@cors_headers = {
        # allow access from any origin
        'Access-Control-Allow-Credentials' => 'true',
        'Access-Control-Allow-Headers' => 'X-Requested-With',
            # Ajax requests usually set the X-Requested-With header.
        'Access-Control-Allow-Methods' => 'GET, POST, DELETE, PUT, OPTIONS',
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Max-Age' => '604800'
    }

    def initialize(status, headers, body)
        @status = status
        @headers = headers || {}

        # Set the CORS headers
        #
        @headers.merge! @@cors_headers

        @body = body
    end
end

