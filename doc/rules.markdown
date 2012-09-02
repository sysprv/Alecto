Rules written in JSON are interpreted at runtime by instances of the Rule
class. See `rule.rb` for more information.

JSON rules are validated at load-time by the `valid_json_rulespec`
method in `rulesupport.rb`.

Here are the elements which must/may be present in a rule.

## number
The number should be an an integer, and is used for applying
rules in order to requests. However, numbers need not be consecutive.
That is, it is perfectly valid to only have to rules, numbered 50 and 100.
The rules are kept in a map, keyed by the numbers.

## description
This should be a string documenting the rule.

## content\_type
The content type of the response of the rule.
Example: `"content_type": "application/xml; charset=UTF-8"`
Example: `"content_type": "image/jpeg"`


# Matching

## strings
This should be a non-empty array of strings. In the most common case,
this list of strings will be matched, in order, to the body of the
request.
For example, if `"strings": [ "a", "b", "c" ]`, then the request
body must contain "a", "b" and "c" in order for a successful match.
Request bodies such as "abc", "a#b#c", "a c b a c" will all match,
while "cab", "a b a b a b" will not match.

## query\_strings
This should be a non-empty array of strings, similar to `strings`.
However, these strings will be matched, in order, against the
query string of the request.

# Actions

## response
This is how you can include the response of the rule inline with the
rule itself.
Example: `"response": "Hello, World!"` will cause the rule to return
the string "Hello, World!", when it matches.

`response` can also be an array of strings. In this case, all array
elements will be concatenated and sent to the client as one string.
This is convenient for embedding long strings in the rule, still
keeping sane line lengths.

Example:
	"response": [
		"This is a long response. ",
		"It's a really long response. ",
		"So long, that it's making me thirsty. ",
		"Yep, positively pining for a beverage here."
	]


## response\_base64
Like response, but the contents of `response` will be Base64-decoded.
Convenient for including binary data.
Just as in `response`, `response_base64` can be an array. In this case,
all array elements will be concatenated together before decoding.


## file
Another common action. This instructs Alecto to read the response from
the file. The file will be read without any encoding, as a byte array.
There is no caching - the file will be re-read upon every match of the
rule.

## service
Work as a proxy, standing in front of another http service.

This is not very sophisticated at the moment - the rule will initiate
a http POST or GET request to the URI given in the `service` element, with
the request body of the input to the rule as the request body of the
POST request - case of a POST request. The response will be returned
back to the client, minus any http headers. They will be added to the
response prefixed with the string 'X-Alecto-Backend-'.

If any query string is present in the Alecto request, that will be
appended to the `service` URI.

# Other Instructions

## path\_info
`path_info` is used when constructing proxy rules (delegating
to a `service`) or to bind a a rule to a particular URI path.

Each `service` rule must have `path_info` element defined. The URI
used to invoke Alecto must end with this configured `path_info`.
Example:

Rule:
	{
		"number": 2,
		"description": "Invoke myself",
		"path_info": "/invoke-myself",
		"content_type": "text/plain; charset=UTF-8",
		"strings": [ "default" ],
		"service": "http://192.168.56.11:4567/foo/bar/quux"
	}

A http GET or POST to /invoke-myself will match this rule and cause
a corresponding GET or POST to http://192.168.56.11:4567/foo/bar/quux.


