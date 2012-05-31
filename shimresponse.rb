class ShimResponse
    # status -> int
    # content_encoding -> string
    # headers -> map
    # body -> string
    attr_reader :status, :content_encoding, :headers, :body

    def initialize(status, content_encoding, headers, body)
        @status = status
        @headers = headers
        @body = body
    end
end

