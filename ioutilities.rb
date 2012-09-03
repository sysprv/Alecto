require 'java'

module IoUtilities
    # Given a java.io.InputStream, read it until
    # the end, filling up a byte array with the
    # content.
    # Returns a Java byte array.
    def read_input_stream_fully(input_stream)
        baos = java.io.ByteArrayOutputStream.new
        buffer = Java::byte[512].new

        loop do
            n_read = input_stream.read(buffer, 0, buffer.length)
            if n_read < 0 then
                break
            end

            baos.write(buffer, 0, n_read)
        end

        return baos.toByteArray()
    end

    def byte_array_to_string(j_byte_array, char_encoding)
        # make a Java string, with the given encoding
        j = java.lang.String.new(j_byte_array, char_encoding)
        # convert it into a Ruby string
        return j.toString()

        # another way:
        # s = String.from_java_bytes j_byte_array
        # s.force_encoding char_encoding
        # return s
        #
        # Ideally from_java_bytes would take the encoding as a
        # parameter, but this part is still unfinished in
        # JRuby 1.7.0.preview2.
    end

    # Returns a Ruby String.
    # TODO: handle binary input data?
    def body_from_servlet_request(servlet_req)
        if servlet_req.getMethod().upcase() == 'POST' then
            req_content_length = servlet_req.getContentLength()
            if req_content_length.nil? then
                logger = Java::OrgSlf4j::LoggerFactory::getLogger(Request.name)
                logger.warning('No content length set in POST request')
            end

            input_stream = servlet_req.getInputStream()
            byte_array = read_input_stream_fully(input_stream)
            byte_array_to_string(byte_array, @character_encoding)
        else
            nil
        end
    end
end

