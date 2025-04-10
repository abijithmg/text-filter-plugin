local typedefs = require "kong.db.schema.typedefs"

return {
  name = "semantic-prompt-guard",
  fields = {
    { consumer = typedefs.no_consumer },
    { config = {
        type = "record",
        fields = {
          { semantic_api_url = { type = "string" } },
          { semantic_api_key = { type = "string", required = false } },
          { enabled = { type = "boolean", default = true } },
        }
      }
    }
  }
}
