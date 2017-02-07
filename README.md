# Cvprac - CloudVision Portal RESTful API Client

#### Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [Usage](#usage)
4. [Development](#development)
5. [Contributing](#contributing)
6. [Support](#support)

[![Gem Version](https://badge.fury.io/rb/cvprac)](https://badge.fury.io/rb/cvprac)
[![Unittest Status](https://revproxy.arista.com/eosplus/ci/buildStatus/icon?job=Pipeline_jerearista_test/cvprac-rb/initial-function&style=plastic)](https://revproxy.arista.com/eosplus/ci/job/Pipeline_jerearista_test/cvprac-rb/initial-function)

## Overview

The cvprac rubygem is a Ruby RESTful API Client for Arista CloudVision&reg;
Portal (CVP) which can be used for building applications that work with Arista
CVP. If you are looking for a Python version, see [cvprac on
PyPI](https://pypi.python.org/pypi/cvprac) or
[GitHub](https://pypi.python.org/pypi/cvprac).

When the class is instantiated the logging is configured. Either syslog,
file logging, both, or none can be enabled. If neither syslog nor
filename is specified then no logging will be performed.

This class supports creating a connection to a CVP node and then issuing
subsequent GET and POST requests to CVP. A GET or POST request will be
automatically retried on the same node if the request times out. A GET or POST
request will be automatically retried on the same node if the request receives
a CvpSessionLogOutError. For this case a login will be performed before the
request is retried. For either case, the maximum number of times a request will
be retried on the same node is specified by the class attribute
NUM\_RETRY\_REQUESTS.

If more than one CVP node is specified when creating a connection, and a GET or
POST request receives a ConnectionError, HTTPError, or TooManyRedirects it will
be retried on the next CVP node in the list. If a GET or POST request receives
a Timeout or CvpSessionLogOutError and the retries on the same node exceed
NUM\_RETRY\_REQUESTS, then the request will be retried on the next node on the
list.

If any of the errors persists across all nodes then the GET or POST
request will fail and the last error that occurred will be raised.

The class provides connect, get, and post methods that allow the user to
make RESTful API calls to CVP. See the example below using the get
method.

The class provides a wrapper function around the CVP RESTful API
operations. Each API method takes the RESTful API parameters as method
parameters to the operation method. The API class was added to the
client class because the API functions are required when using the CVP
RESTful API and placing them in this library avoids duplicating the
calls in every application that uses this class. See the examples below
using the API methods.

## Requirements

- Ruby 1.9.3 or later

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cvprac'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cvprac

## Usage

Basic usage:

```
require ‘cvprac’
cvp = CvpClient.new
cvp.connect(['192.0.2.101', '192.0.2.102, '192.0.2.103'],
            'cvpadmin', 'arista123')
result = { "version": "2016.1.1" }{ "version": "2016.1.1" icvp.get('/cvpInfo/getCvpInfo.do')
print result
{"version"=>"2016.1.1"}

result = cvp.get('/user/getUsers.do',
                 data: { queryparam: nil, startIndex: 0, endIndex: 0 })

cvp.post('/some/endpoint.do', body: '{"some":"data"}')
```

Modifying logging settings:

```
require ‘cvprac’

# Log to Syslog
cvp = CvpClient.new(syslog: true)

# Log to a file or ‘STDOUT’ and increase the logging level
cvp = CvpClient.new(filename: 'STDOUT', file_log_level: Logger::DEBUG)

```

API Class example:

Not Yet Implemented

### Notes for API Class Usage

#### Containers

With the API the containers are added for all cases. If you add the container
to the original root container ‘Tenant’ then you have to do a refresh from the
GUI to see the container after it is added or deleted. If the root container
has been renamed or the parent container is not the root container then an add
or delete will update the GUI without requiring a manual refresh.

## Development

See [CONTRIBUTING](CONTRUBUTING.md)

## Contributing

Bug reports and pull requests are welcome on
[GitHub](https://github.com/arista-aristanetworks/cvprac-rb). Pull-requests
must include relevant unittests and updated docstrings to be accepted.

This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the [Contributor
Covenant](http://contributor-covenant.org) code of conduct.

## Support

For support, please open an
[issue](https://github.com/arista-aristanetworks/cvprac-rb) on GitHub or
contact eosplus@arista.com.  Commercial support agreements are available
through your Arista account team.
