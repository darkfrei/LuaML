# LuaML - Declarative Markup Language

## Description
LuaML uses Lua syntax for describing structured data. This is **not executable Lua code**, but a declarative markup format processed by a special parser.

## Advantages
- Familiar syntax for Lua developers
- Support for comments (single-line `--` and multi-line `--[[ ]]`)
- Flexible data structures
- Readable and concise
- Support for expressions with computed values

---

## Data Types

Definition flat (global):
```lua
app = {name = "MyApp"} -- no comma!
server = {port = 8080}
```

Definition table:
```lua
return {
  app = {name = "MyApp"},
  server = {port = 8080}
}
```


### Primitive Types

```lua
-- strings
title = "Hello, world!"
path = 'C:\\Users\\path\\file.txt'
path2 = 'C:/Users/path/file.txt'
multiline = [[Multi-line text
with line breaks]]

-- numbers
integer = 42
float = 3.14159
negative = -17
hex = 0x2A
exponential = 1.5e10

-- booleans
enabled = true
disabled = false

-- nil (null)
empty = nil
```

### Tables (Objects)

```lua
-- simple object
person = {
  name = "John",
  age = 30,
  active = true
}

-- nested objects
database = {
  connection = {
    host = "localhost",
    port = 5432,
    credentials = {
      user = "admin",
      password = "secret"
    }
  }
}
```

### Arrays (Lists)

```lua
-- indexed array
numbers = {1, 2, 3, 4, 5}

-- array of strings
colors = {"red", "green", "blue"}

-- array of objects
users = {
  {id = 1, name = "Anna", role = "admin"},
  {id = 2, name = "Peter", role = "user"},
  {id = 3, name = "Maria", role = "user"}
}

-- multi-line array
fruits = {
  "apple",
  "banana",
  "orange",
  "pear"
}
```

### Mixed Structures

```lua
-- table with indexes and keys
config = {
  "first",      -- [1]
  "second",     -- [2]
  key = "value",
  nested = {
    "item",     -- [1]
    param = 100
  }
}
```

---

## Complete Configuration Example

```lua
--[[
  web application configuration
  format: LuaML v1.0
]]

-- basic settings
app = {
  name = "MyWebApp",
  version = "1.0.0",
  environment = "production",
  debug = false
}

-- server
server = {
  host = "0.0.0.0",
  port = 8080,
  workers = 4,
  timeout = 30,
  
  ssl = {
    enabled = true,
    cert = "/path/to/cert.pem",
    key = "/path/to/key.pem"
  }
}

-- database
database = {
  driver = "postgresql",
  
  primary = {
    host = "db1.example.com",
    port = 5432,
    name = "myapp_prod",
    user = "dbuser",
    password = "dbpass",
    pool_size = 20,
    timeout = 5000
  },
  
  replica = {
    host = "db2.example.com",
    port = 5432,
    name = "myapp_prod",
    user = "dbuser_ro",
    password = "dbpass_ro"
  }
}

-- cache
cache = {
  driver = "redis",
  host = "localhost",
  port = 6379,
  ttl = 3600,
  prefix = "myapp:"
}

-- logging
logging = {
  level = "info",
  format = "json",
  
  outputs = {
    {
      type = "file",
      path = "/var/log/myapp/app.log",
      max_size = "100MB",
      max_files = 10
    },
    {
      type = "console",
      colored = true
    }
  }
}

-- users (array)
users = {
  {
    id = 1,
    username = "admin",
    email = "admin@example.com",
    roles = {"admin", "user"},
    active = true,
    created_at = "2024-01-15T10:00:00Z"
  },
  {
    id = 2,
    username = "john_doe",
    email = "john@example.com",
    roles = {"user"},
    active = true,
    created_at = "2024-02-20T14:30:00Z"
  }
}

-- modules and plugins
modules = {
  auth = {
    enabled = true,
    provider = "jwt",
    secret = "your-secret-key",
    expiration = 86400
  },
  
  email = {
    enabled = true,
    smtp = {
      host = "smtp.example.com",
      port = 587,
      user = "noreply@example.com",
      password = "smtp_pass",
      tls = true
    },
    templates_path = "/app/templates/emails"
  },
  
  storage = {
    enabled = true,
    driver = "s3",
    bucket = "myapp-uploads",
    region = "us-east-1",
    allowed_extensions = {".jpg", ".png", ".pdf", ".docx"}
  }
}

-- API routes
routes = {
  {
    path = "/api/users",
    methods = {"GET", "POST"},
    handler = "UserController",
    middleware = {"auth", "rate_limit"}
  },
  {
    path = "/api/users/:id",
    methods = {"GET", "PUT", "DELETE"},
    handler = "UserController",
    middleware = {"auth", "admin"}
  },
  {
    path = "/api/public/status",
    methods = {"GET"},
    handler = "StatusController",
    middleware = {}
  }
}

-- application constants
constants = {
  MAX_UPLOAD_SIZE = 10485760,  -- 10MB in bytes
  SESSION_LIFETIME = 7200,      -- 2 hours in seconds
  API_VERSION = "v1",
  SUPPORTED_LANGUAGES = {"en", "ru", "de", "fr"}
}

-- computed values
computed = {
  base_url = "https://" .. server.host .. ":" .. server.port,
  upload_limit_mb = constants.MAX_UPLOAD_SIZE / 1024 / 1024,
  is_production = app.environment == "production"
}
```

---

## Syntax Features

### Comments
```lua
-- single-line comment

--[[multi-line
comment]]


--[[
other multi-line
comment
]]

--[[
my favorite multi-line
comment
--]]
```

### String Concatenation

No  string concatenation!

### Numeric Operations (optional, if parser supports)

No numeric operations!

---

## Comparison with JSON and TOML

| Feature | JSON | TOML | LuaML |
|---------|------|------|-------|
| Comments | No | Yes | Yes |
| Readability | 3 | 4 | 4 |
| Nesting | Yes | Yes (harder) | Yes |
| Trailing comma | No | No | Yes |
| Multi-line strings | No | Yes | Yes |
| Numbers in different formats | No | Yes | Yes |
| Expressions | No | No | Yes (optional) |


---

## Usage

### Parsing Example (pseudocode)
```python
import luaml

# load from file
config = luaml.load_file("config.luaml")

# access data
print(config.app.name)  # "MyWebApp"
print(config.server.port)  # 8080
print(config.users[0].username)  # "admin"

# load from string
data = luaml.loads("""
person = {
  name = "John",
  age = 30
}
""")
```

---

## Usage Recommendations

**Suitable for:**
- Application configuration files
- Data structure descriptions in Lua projects
- Replacing JSON/YAML where more flexibility is needed
- DSL (Domain Specific Languages) based on Lua syntax

**Not suitable for:**
- API interactions (use JSON)
- Cases requiring standardization
- Projects without Lua developers on the team
