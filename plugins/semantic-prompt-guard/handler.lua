local http = require "resty.http"
local kong = kong
local cjson = require "cjson.safe"

local SemanticPromptGuard = {
  PRIORITY = 1000,
  VERSION = "1.0.2",
}

-- External Semantic Check
local function check_prompt_semantics(prompt, api_url, api_key)
  local httpc = http.new()
  local res, err = httpc:request_uri(api_url, {
    method = "POST",
    body = cjson.encode({ prompt = prompt }),
    headers = {
      ["Content-Type"] = "application/json",
      ["Authorization"] = api_key and ("Bearer " .. api_key) or nil
    }
  })

  if not res then
    kong.log.err("Failed to reach semantic API: ", err)
    return false
  end

  local body = cjson.decode(res.body)
  return body and body.safe == true
end

-- Main Access Phase Logic
function SemanticPromptGuard:access(conf)
  if not conf.enabled then return end

  local body, err = kong.request.get_raw_body()
  if err or not body then
    return kong.response.exit(400, { message = "Invalid request body" })
  end

  local lower_body = string.lower(body)

  for _, keyword in ipairs(conf.block_keywords or {}) do
    if string.find(lower_body, keyword:lower(), 1, true) then
      return kong.response.exit(403, { message = "Blocked: keyword match" })
    end
  end

  local ok = check_prompt_semantics(body, conf.semantic_api_url, conf.semantic_api_key)
  if not ok then
    return kong.response.exit(403, { message = "Blocked: semantic AI check failed" })
  end
end

return SemanticPromptGuard
