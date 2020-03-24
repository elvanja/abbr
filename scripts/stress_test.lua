--[[
Usage:
`wrk -s scripts/stress_test.lua --latency -c2 -t2 -d1s HOST_URL BASE_SHORTEN_URL MAX_URL_COUNT`
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
  shorten_endpoint_url = string.format("%s://%s:%s/api/urls", wrk.scheme, wrk.host, wrk.port)
  long_url_base = args[1] .. "?q=" .. id
  max_url_count = args[2] or 100
  short_url_ids = {}
  statuses = {}
end

function request()
  local short_url_index = math.random(max_url_count)
  local short_url_id = short_url_ids[short_url_index]
  local long_url = long_url_base .. "-" .. short_url_index

  if short_url_id == nil then
    short_url_id = create_short_url(shorten_endpoint_url, long_url)
    short_url_ids[short_url_index] = short_url_id
  end

  if short_url_id then
    return wrk.format("GET", "/" .. short_url_id)
  end
end

function response(status, _headers, _body)
  statuses[status] = (statuses[status] or 0) + 1
end

function done(_summary, _latency, _requests)
  local statuses = {}

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
