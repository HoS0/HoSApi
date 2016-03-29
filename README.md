# HoSApi

HoS API is in charge of translating HTTP and HTTPS calls into the HoS environment, it listens to the calls on the web API and sends the call into the appropriate service, after which it will send the reply back into the caller.

## Example

Currently API supports "GET", "PUT", "POST" and "DELETE" calls. you can specify your calls as following:

### url

`http://{YOURSERVER}/{SERVICE}/{TASK}/{ID}?{QUERYSTRING}`

- `YOURSERVER`: server address
- `SERVICE`: destination HoS service
- `TASK`: required task from that service
- `ID` (optional): can be used to specify id of resource in specific task
- `QUERYSTRING` (optional): can be used for an query statement recommend to be written as `con1=val1&con2=val2...` destination service specify the requirement.

### headers

- sid (optional): instance of destination service unique id.
- token (optional): user token of the caller, should be provided to authorize the call if needed.

### body

JSON request for destination service, depends on service documentation.

## Time out

For each calls the timeout of 5 sec has been define which will end up in returning 404 if the call does not have a reply in requested time.

This software is licensed under the MIT License.
