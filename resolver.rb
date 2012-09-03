# vim:set ts=8 sts=4 sw=4 et ai:

require 'java'
require 'rules'
require 'rubygems'
require 'htmlentities'
require 'mimeheaders'

# This class is what actually runs all the rules against each request.
class Resolver
    @@logger = Java::OrgSlf4j::LoggerFactory::getLogger(Resolver.name)

    @@default_error_code = 417 # code 417 means execution failed
    @@default_error_headers = MimeHeaders.text_html_utf8
    @@default_error_body = "<!DOCTYPE html>\n<html>\n<head>\n<title>Error handling request</title>\n</head>\n<body>\n"

    @@default_error_response = Response.new(
        417,    # response code. http code 417 == "Expectation Failed"
        {   # any response headers
            'Content-Type' => 'application/xml;charset=UTF-8'
        },
        "<?xml version='1.0'?><error>No matchers for request</error>\r\n")

    def Resolver.resolve(req)
        # go through each function, and return the response from the first one that matches.
        resp = nil

        Rules.instance.rule_numbers.each do |rulenum|
            # for each rule in rules, in order, call the lambda
            @@logger.info("Checking request against rule number {}", rulenum)
            rule = Rules.instance.rules[rulenum]
            if rule.nil? then
                @@logger.info("Got null rule for number {}", rulenum)
                next
            end

            matchresult = rule.process(req)
            if not matchresult.nil? and matchresult.matched then
                # unwinding
                @@logger.info("Finished processing rule number {}", rulenum)
                resp = matchresult.response
                break
            end
        end

        if resp.nil? then
            @@logger.info("No match found for request {}", req.inspect)
            resp_body = HTMLEntities.new.encode(req.inspect, :named)
            resp = Response.new(@@default_error_code, @@default_error_headers,
                                @@default_error_body +
                                "No rule matched the request: <br/>\n<code>" +
                                resp_body + "\n</code>\n" +
                                "<p><a href='/rules'>Current set of rules</a></p>\n" +
                                "</body>\n</html>\n")
        end

        resp
    end

    def Resolver.no_route(uri_path)
        Response.new(@@default_error_code, @@default_error_headers,
                     @@default_error_body +
                     "No route matched the request: <br/>\n<code>" +
                     HTMLEntities.new.encode(uri_path, :named) +
                     "\n</code>\n" +
                     "<p><a href='/rules'>Current set of rules</a></p>\n" +
                     "</body>\n</html>\n")
    end
end

