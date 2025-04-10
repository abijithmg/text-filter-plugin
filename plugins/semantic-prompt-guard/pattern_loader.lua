local cjson = require "cjson.safe"

local function load_patterns(file_path)
  local file, err = io.open(file_path, "r")
  if not file then
    ngx.log(ngx.ERR, "Failed to load pattern file: ", err)
    return nil
  end

  local content = file:read("*a")
  file:close()

  local decoded, err = cjson.decode(content)
  if not decoded then
    ngx.log(ngx.ERR, "Failed to decode pattern JSON: ", err)
    return nil
  end

  return decoded
end

return {
  load_patterns = load_patterns
}
