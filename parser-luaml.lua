-- luaml.lua
-- ml parser with lua-like syntax
-- comments are lowercase

local luaml = {}

------

local parseValue, parseBraceBlock, parseAssignments

------

function parseBraceBlock(tokens, pos)
	-- parse { ... } block as list or object
	pos = pos + 1 -- skip '{'
	local block = {}
	local isObject = nil -- detect later

	while true do
		local t = tokens[pos]
		if not t then error("unexpected end inside { }") end

		if t.type == "rbrace" then
			return block, pos + 1
		end

		local key, val

		-- detect object entry
		if t.type == "ident" and tokens[pos + 1] and tokens[pos + 1].type == "eq" then
			isObject = true
			key = t.value
			pos = pos + 2

			val, pos = parseValue(tokens, pos)
			block[key] = val

		else
			-- list entry
			if isObject == nil then isObject = false end
			if isObject then
				error("cannot mix list values with object fields")
			end

			val, pos = parseValue(tokens, pos)
			table.insert(block, val)
		end

		t = tokens[pos]
		if not t then error("unexpected end after value") end

		if t.type == "comma" then
			pos = pos + 1
		elseif t.type ~= "rbrace" then
			error("expected ',' or '}'")
		end
	end
end

------

function parseValue(tokens, pos)
	local t = tokens[pos]
	if not t then error("unexpected end when reading value") end

	if t.type == "string" or t.type == "number" or t.type == "bool" or t.type == "nil" then
		return t.value, pos + 1

	elseif t.type == "lbrace" then
		return parseBraceBlock(tokens, pos)

	elseif t.type == "ident" then
		return t.value, pos + 1

	else
		error("unexpected token in value: " .. t.type)
	end
end

------
function parseAssignments(tokens)
	-- result table
	local result = {}
	local pos = 1

	-- top-level { ... } shortcut
	if tokens[1] and tokens[1].type == "lbrace" then
		return (parseBraceBlock(tokens, 1))
	end

	while pos <= #tokens do
		local t = tokens[pos]

		-- if "ident =" → normal field
		if t.type == "ident"
		   and tokens[pos + 1]
		   and tokens[pos + 1].type == "eq" then

			local key = t.value
			pos = pos + 2 -- skip key and '='

			local val
			val, pos = parseValue(tokens, pos)
			result[key] = val

		else
			-- otherwise → list value
			local val
			val, pos = parseValue(tokens, pos)
			table.insert(result, val)
		end
	end

	return result
end



------

-- lexer: splits into tokens, ignores comments starting with --
local function tokenize(str)
	local tokens = {}
	local i = 1
	local n = #str

	while i <= n do
		local ch = str:sub(i,i)

		-- ignore whitespace
		if ch:match("%s") then
			i = i + 1

			-- multi-line comment --[[ ... ]]
		elseif ch == "-" and str:sub(i,i+3) == "--[[" then
			i = i + 4
			while i <= n do
				if str:sub(i,i+1) == "]]" then
					i = i + 2
					break
				end
				i = i + 1
			end

			-- single-line comment --
		elseif ch == "-" and str:sub(i,i+1) == "--" then
			i = i + 2
			while i <= n and str:sub(i,i) ~= "\n" do
				i = i + 1
			end

		elseif ch == "{" then
			tokens[#tokens+1] = {type="lbrace"}
			i = i + 1

		elseif ch == "}" then
			tokens[#tokens+1] = {type="rbrace"}
			i = i + 1

		elseif ch == "," then
			tokens[#tokens+1] = {type="comma"}
			i = i + 1

		elseif ch == "=" then
			tokens[#tokens+1] = {type="eq"}
			i = i + 1

			-- multi-line string [[ ... ]]
		elseif ch == "[" and str:sub(i,i+1) == "[[" then
			local start = i + 2
			i = start
			while i <= n do
				if str:sub(i,i+1) == "]]" then
					break
				end
				i = i + 1
			end
			local raw = str:sub(start, i-1)
			tokens[#tokens+1] = {type="string", value=raw}
			i = i + 2

			-- single-quote string
		elseif ch == "'" then
			local start = i + 1
			i = start
			while i <= n and str:sub(i,i) ~= "'" do
				if str:sub(i,i) == "\\" then
					i = i + 1
				end
				i = i + 1
			end
			local raw = str:sub(start, i-1)
			-- unescape basic sequences
			raw = raw:gsub("\\n", "\n"):gsub("\\t", "\t"):gsub("\\'", "'"):gsub("\\\\", "\\")
			tokens[#tokens+1] = {type="string", value=raw}
			i = i + 1

			-- double-quote string
		elseif ch == '"' then
			local start = i + 1
			i = start
			while i <= n and str:sub(i,i) ~= '"' do
				if str:sub(i,i) == "\\" then
					i = i + 1
				end
				i = i + 1
			end
			local raw = str:sub(start, i-1)
			-- unescape basic sequences
			raw = raw:gsub("\\n", "\n"):gsub("\\t", "\t"):gsub('\\"', '"'):gsub("\\\\", "\\")
			tokens[#tokens+1] = {type="string", value=raw}
			i = i + 1

		elseif ch:match("[%a_]") then
			-- identifier, boolean, or nil
			local start = i
			i = i + 1
			while i <= n and str:sub(i,i):match("[%w_]") do
				i = i + 1
			end
			local word = str:sub(start,i-1)
			if word == "true" then
				tokens[#tokens+1] = {type="bool", value=true}
			elseif word == "false" then
				tokens[#tokens+1] = {type="bool", value=false}
			elseif word == "nil" then
				tokens[#tokens+1] = {type="nil", value=nil}
			else
				tokens[#tokens+1] = {type="ident", value=word}
			end

		elseif ch:match("[%+%-0-9]") then
			-- number (including hex 0x, exponential)
			local start = i

			-- check for hex
			if str:sub(i,i+1) == "0x" or str:sub(i,i+1) == "0X" then
				i = i + 2
				while i <= n and str:sub(i,i):match("[%da-fA-F]") do
					i = i + 1
				end
				local numstr = str:sub(start, i-1)
				local num = tonumber(numstr)
				if not num then
					-- try base 16
					num = tonumber(numstr:sub(3), 16)
				end
				if not num then error("invalid number format: " .. numstr) end
				tokens[#tokens+1] = {type="number", value=num}

			else
				-- decimal number
				i = i + 1
				while i <= n and str:sub(i,i):match("[%d%.eE%+%-]") do
					i = i + 1
				end
				local numstr = str:sub(start, i-1)
				local num = tonumber(numstr)
				if not num then error("invalid number format: " .. numstr) end
				tokens[#tokens+1] = {type="number", value=num}
			end

		else
			error("unexpected character: "..ch)
		end
	end

	return tokens
end

------

local function encodeValue(v, indent, out)
	local t = type(v)

	if t == "number" then
--		out[#out+1] = '\n-- number '..v..'\n'
		out[#out+1] = tostring(v)
	elseif t == "boolean" then
--		out[#out+1] = '-- boolean '..tostring(v)..'\n'
		out[#out+1] = v and "true" or "false"
	elseif t == "nil" then
		out[#out+1] = "nil"
	elseif t == "string" then
		-- use [[ ]] for multi-line strings
		if v:match("\n") then
			out[#out+1] = "[["
			out[#out+1] = v
			out[#out+1] = "]]"
		else
			out[#out+1] = string.format("%q", v)
		end

	elseif t == "table" then
		out[#out+1] = "{"
		out[#out+1] = "\n"

		local nextIndent = indent .. "  "

		-- array part
		local max = #v
		for i = 1, max do
			out[#out+1] = nextIndent
			encodeValue(v[i], nextIndent, out)
			out[#out+1] = ",\n"
		end

		-- key-value part
		for k,val in pairs(v) do
			if type(k) ~= "number" or k > max or k < 1 then
				out[#out+1] = nextIndent
				if type(k) == "string" and k:match("^[%a_][%w_]*$") then
					out[#out+1] = k
				else
					out[#out+1] = "[" .. string.format("%q", k) .. "]"
				end
				out[#out+1] = " = "
				encodeValue(val, nextIndent, out)
				out[#out+1] = ",\n"
			end
		end

		out[#out+1] = indent
		out[#out+1] = "}"
	else
		error("unsupported type: " .. t)
	end
end


------

function luaml.encode(tbl, tableMode)

	local out = {}

	-- prepend mode comment
	if tableMode then
		out[#out+1] = "-- mode: table\n"
		out[#out+1] = "return "
		encodeValue(tbl, "", out)
	else
		out[#out+1] = "-- mode: global\n"

		local indent = ""
		local max = #tbl

		-- array part
		out[#out+1] = "-- array part\n"
		for i = 1, max do
--			out[#out+1] = "-- array part".. i .."\n"
			encodeValue(tbl[i], indent, out)
			out[#out+1] = "\n"
		end
		out[#out+1] = "-- end of array part\n\n"

		-- object part
		out[#out+1] = "-- object part\n"
		for k, v in pairs(tbl) do
			if type(k) ~= "number" or k < 1 or k > max then
				out[#out+1] = k .. " = "
				encodeValue(v, indent, out)
				out[#out+1] = "\n"
			end
		end
		out[#out+1] = "-- end of object part\n"

	end

	return table.concat(out)
end



function luaml.decode(str)
	-- tokenize the input string
	local success, tokens = pcall(tokenize, str)
	if not success then
		return nil, "tokenization error: " .. tostring(tokens)
	end

	-- parse the token sequence into a lua table
	local success2, result = pcall(parseAssignments, tokens)
	if not success2 then
		return nil, "parse error: " .. tostring(result)
	end

	-- return the decoded table
	return result
end


-- alias for consistency
luaml.parse = luaml.decode
luaml.serialize = luaml.encode

-- load from file
function luaml.load(filename)
	local file, err = io.open(filename, "r")
	if not file then
		return nil, "cannot open file: " .. tostring(err)
	end

	local content = file:read("*all")
	file:close()

	return luaml.decode(content)
end

-- save to file
function luaml.save(filename, tbl)
	local file, err = io.open(filename, "w")
	if not file then
		return nil, "cannot create file: " .. tostring(err)
	end

	local content = luaml.encode(tbl)
	file:write(content)
	file:close()

	return true
end

return luaml
