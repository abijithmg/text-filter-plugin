local http = require "resty.http"
local kong = kong
local cjson = require "cjson.safe"
local pattern_loader = require "kong.plugins.guard.pattern_loader"


local Guard = {
  PRIORITY = 1000,
  VERSION = "1.0",
}

local patterns = pattern_loader.load_patterns("/usr/local/share/lua/5.1/kong/plugins/guard/patterns.json")

function Guard:access(conf)

  local body, err = kong.request.get_raw_body()
  if err then
    return kong.response.exit(400, { message = "Invalid request body" })
  end

  local json = cjson.decode(body)
  local prompt = (json and json.prompt) and json.prompt:lower() or ""
  if prompt == "" then
    return kong.response.exit(400, { message = "Missing prompt" })
  end

  local function match_category(category, list)
    for _, pattern in ipairs(list) do
      if ngx.re.find(prompt, pattern, "ijo") then
        ngx.log(ngx.WARN, "[PromptGuard] Rejected (", category, ") → Pattern: ", pattern)
        return true, category, pattern
      end
    end
    return false
  end

  -- Check safety categories
  for category, patterns_list in pairs(patterns.safety_patterns or {}) do
    local matched, cat, pat = match_category(category, patterns_list)
    if matched then
      return kong.response.exit(403, {
        message = "Prompt rejected due to safety violation: " .. cat,
        pattern = pat
      })
    end
  end

  -- Check protected material
  local matched, cat, pat = match_category("protected_material", patterns.protected_patterns or {})
  if matched then
    return kong.response.exit(403, {
      message = "Prompt rejected: protected content detected",
      pattern = pat
    })
  end

  -- Check prompt shield
  matched, cat, pat, score = match_category("prompt_shield", patterns.shield_patterns or {})
  if matched then
    return kong.response.exit(403, {
      message = "Prompt rejected: possible prompt injection",
      pattern = pat
    })
  end
end

return Guard


-- -- External Semantic Check
-- local function check_prompt_semantics(prompt, api_url, api_key)
--   local httpc = http.new()
--   local res, err = httpc:request_uri(api_url, {
--     method = "POST",
--     body = cjson.encode({ prompt = prompt }),
--     headers = {
--       ["Content-Type"] = "application/json",
--       ["Authorization"] = api_key and ("Bearer " .. api_key) or nil
--     }
--   })

--   if not res then
--     kong.log.err("Failed to reach semantic API: ", err)
--     return false
--   end

--   local body = cjson.decode(res.body)
--   return body and body.safe == true
-- end

-- -- Main Access Phase Logic
-- function SemanticPromptGuard:access(conf)
--   if not conf.enabled then return end

--   local body, err = kong.request.get_raw_body()
--   if err or not body then
--     return kong.response.exit(400, { message = "Invalid request body" })
--   end

--   local lower_body = string.lower(body)

--   for _, keyword in ipairs(conf.block_keywords or {}) do
--     if string.find(lower_body, keyword:lower(), 1, true) then
--       return kong.response.exit(403, { message = "Blocked: keyword match" })
--     end
--   end

--   local ok = check_prompt_semantics(body, conf.semantic_api_url, conf.semantic_api_key)
--   if not ok then
--     return kong.response.exit(403, { message = "Blocked: semantic AI check failed" })
--   end
-- end

-- return SemanticPromptGuard
