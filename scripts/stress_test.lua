--[[
Usage:
`wrk -s scripts/stress_test.lua --latency -c2 -t2 -d1s SERVICE_URL -- BASE_URL_TO_SHORTEN DEBUG`

SERVICE_URL represents the base address of the service itself.

BASE_URL_TO_SHORTEN represents the base URL you'd like to shorten.
Just make sure it doesn't already contain query parameters since stress test script appends ?q=RANDOM_NUMBER for each test thread.

DEBUG prints out shortened and long URLs, turned off by default.

The idea is that each test thread:
- constructs long URL from given BASE_URL_TO_SHORTEN and random query param (to make it unique)
- shortens that long URL
- runs against shortened URL

Custom stats are printed at the end, returning received HTTP statuses counts.
If all goes well, only 302 status is present (redirects from short to long URL).
--]]

-- Initialize the pseudo random number generator
-- Resource: http://lua-users.org/wiki/MathLibraryTutorial
math.randomseed(os.time())
math.random(); math.random(); math.random(); math.random(); math.random()

-- So we can track custom metrics
local threads = {}

function create_short_url(shorten_endpoint_url, long_url)
  local curl_command = "curl -s -X POST -H 'Content-type: application/json' -d '{\"url\":\"" .. long_url .. "\"}' " .. shorten_endpoint_url
  local handle = io.popen(curl_command)
  local curl_response = handle:read("*a")
  handle:close()
  local short_url_id = string.match(curl_response, '{"short_url":"http://.*/(.*)"}')
  return short_url_id
end

function setup(thread)
  thread:set("id", math.random())
  table.insert(threads, thread)
end

function init(args)
  local shorten_endpoint_url = string.format("%s://%s:%s/api/urls", wrk.scheme, wrk.host, wrk.port)
  local long_url = args[1] .. "?q=" .. id
  local debug = args[2] or false
  short_url_id = create_short_url(shorten_endpoint_url, long_url)
  statuses = {}
  if debug then
    print(short_url_id .. ": " .. long_url)
  end
end

function request()
  return wrk.format("GET", "/" .. short_url_id)
end

function response(status, _headers, _body)
  statuses[status] = (statuses[status] or 0) + 1
end

function done(_summary, _latency, _requests)
  statuses = {}

  for _index, thread in ipairs(threads) do
    for status, count in pairs(thread:get("statuses")) do
      statuses[status] = (statuses[status] or 0) + count
    end
  end

  print "Received HTTP statuses:"
  for status, count in pairs(statuses) do
    print("  -> " .. status .. ": " .. count)
  end
end
