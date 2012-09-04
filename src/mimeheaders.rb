# vim:set ts=8 sts=4 sw=4 ai et:

# Some hash objects signifying various http content type headers.
# Useful when building up http responses to send back to the client.
# For usage, see dispatcher.rb.
class MimeHeaders
    @@c_t = 'Content-Type'
    @@text_plain_utf8       = { @@c_t => 'text/plain; charset=utf-8' }
    @@application_json_utf8 = { @@c_t => 'application/json; charset=utf-8' }
    @@text_html_utf8        = { @@c_t => 'text/html; charset=utf-8' }

    def self.text_plain_utf8
        @@text_plain_utf8
    end

    def self.application_json_utf8
        @@application_json_utf8
    end

    def self.text_html_utf8
        @@text_html_utf8
    end
end
