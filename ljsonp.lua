-- LJSONP ( a simple Lpeg JSON Parser)
-- Copyright (c) 2016, Ralph Augé
-- All rights reserved.
-- 
-- Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
-- 
-- 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-- 
-- 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-- 
-- 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
--

local g_nullt = {"*null*kind*"}
local g_object_mt = {__len = function () return -2 end}

local format = string.format

function json_encode_object(tt, indent, pp)
	local sb = {}
	local e = 0
	local k
	local value

	sb[#sb+1] = "{";
	for k, value in pairs(tt) do
		e = e + 1
		if pp ~= 0 then
			sb[#sb+1] = "\n"
			sb[#sb+1] = string.rep(" ", indent*pp)
		end

		if type(value) == "table" then
			sb[#sb+1] = format("%s:%s",
				to_string(k, true), json_stringify(value, pp, indent + 2))
		else
			sb[#sb+1] = format("%s:%s",
				to_string(k, true), to_string(value))
		end
		sb[#sb+1] = ","
	end
	if sb[#sb] == ',' then
		sb[#sb] = nil
	end
	if pp ~= 0 then
		sb[#sb+1] = "\n"
		sb[#sb+1] = string.rep(" ", (indent-2)*pp)
	end
	sb[#sb+1] = "}"

	return e, sb
end

function json_encode_array(tt, indent, pp)
	local sb = {}
	local k
	local value

	sb[#sb+1] = "[";

	for k = 1, #tt do
		value = tt[k]

		if type (value) == "table" then
			sb[#sb+1] = json_stringify(value, pp, indent + 2)
		else
			if pp ~= 0 then
				sb[#sb+1] = "\n"
				sb[#sb+1] = string.rep(" ", (indent)*pp)
			end
			sb[#sb+1] = to_string(value)
		end
		sb[#sb+1] = ","
	end

	if sb[#sb] == ',' then
		sb[#sb] = nil
	end
	if pp ~= 0 then
		sb[#sb+1] = "\n"
		sb[#sb+1] = string.rep(" ", (indent-2)*pp)
	end
	table.insert(sb, "]");

	return sb
end

function json_stringify(tt, pp, indent)
	pp = pp or 0
	indent = indent or 0

	local sb = {}

	if type(tt) == "table" then
		if #tt == -1 then
			return "null"
		end

		local e, sb = json_encode_object(tt, indent, pp)

		if e == #tt then
			sb = json_encode_array(tt, indent, pp)
		end

		return table.concat(sb)
	else
		return to_string(tt)
	end
end

function fixUTF8(s, replacement)
	local p, len, invalid = 1, #s, {}
	while p <= len do
	  if     p == s:find("[%z\1-\127]", p) then p = p + 1
	  elseif p == s:find("[\194-\223][\128-\191]", p) then p = p + 2
	  elseif p == s:find("\224[\160-\191][\128-\191]", p)
	      or p == s:find("[\225-\236][\128-\191][\128-\191]", p)
	      or p == s:find("\237[\128-\159][\128-\191]", p)
	      or p == s:find("[\238-\239][\128-\191][\128-\191]", p) then p = p + 3
	  elseif p == s:find("\240[\144-\191][\128-\191][\128-\191]", p)
	      or p == s:find("[\241-\243][\128-\191][\128-\191][\128-\191]", p)
	      or p == s:find("\244[\128-\143][\128-\191][\128-\191]", p) then p = p + 4
	  else
	    s = s:sub(1, p-1)..replacement..s:sub(p+1)
	    table.insert(invalid, p)
	  end
	end
	return s, invalid
end

function to_string(v, cast_to_string)
	if type(v) == "nil" then
		return "null"

	elseif type(v) == "number" then
		if cast_to_string then
			return '"' .. to_string(v) .. '"'
		end
		return tostring(v)

	elseif type(v) == "string" then
		return table.concat({'"',
			(fixUTF8(v, '.')):gsub('["%\\\000-\031]',function (c)
			if c == '\n' then return '\\n' end
			if c == '\t' then return '\\t' end
			if c == '\r' then return '\\r' end
			if c == '\v' then return '\\v' end
			if c == '\f' then return '\\f' end
			if c == '\\' then return '\\\\' end
			if c == '"' then return '\\"' end
			return string.format("\\u%04x", c:byte()) end)
			--v:gsub('["%\\\000-\031\127-\255]',function (c)
			--if c == '\n' then return '\\n' end
			--if c == '\t' then return '\\t' end
			--if c == '\r' then return '\\r' end
			--if c == '\v' then return '\\v' end
			--if c == '\f' then return '\\f' end
			--if c == '\\' then return '\\\\' end
			--if c == '"' then return '\\"' end
			--return string.format("\\u%04x", c:byte()) end)
			,
			'"'})

	elseif type(v) == "boolean" then
		if v == true then
			return "true"
		end
		return "false"

	elseif type(v) == "table" then
		if  g_nullt == v or #v == -1 then
			return "null"
		end

		return json_stringify(v)
	else
		return "*" .. type(v) .. "*"
	end
end


local lpeg = require("lpeg")

local P = lpeg.P
local Cs = lpeg.Cs
local Ct = lpeg.Ct
local C = lpeg.C
local S = lpeg.S
local V = lpeg.V

local white = S" \t\r\n" ^ 0
local colon = white * P':' * white
local comma = white * P',' * white

local digit = lpeg.R("09")
local integer = P'-' ^ -1 * digit ^ 1

local frac = P'.' *  digit ^ 1
local exp = S'eE' * S'+-' ^ -1 * digit ^ 1

local anumber =
		white * (C(integer * frac * exp) +
		C(integer * exp) +
		C(integer * frac) +
		integer) / function (n,b)
			return tonumber(n)
		end

local leftBracket = white * '[' * white
local rightBracket = white * ']' * white
local leftBrace = white * '{' * white
local rightBrace = white * '}' * white


local utfcp

(function ()
local string_char = string.char
-- check for an utf8 lib
local loaded, utf8 = pcall(function () return require 'utf8' end)

if loaded then
	utfcp = utf8.char
	return
end

utfcp = function (cp)
	if cp < 128 then
		return string_char(cp)
	end
	local s = ""
	local prefix_max = 32
	while true do
		local suffix = cp % 64
		s = string_char(128 + suffix)..s
		cp = (cp - suffix) / 64
		if cp < prefix_max then
			return string_char((256 - (2 * prefix_max)) + cp)..s
		end
		prefix_max = prefix_max / 2
	end
end

end)()


local escape_map = {
	["t"] = '\t',
	["b"] = '\b',
	["f"] = '\f',
	["n"] = '\n',
	["r"] = '\r',
	["t"] = '\t',
	["/"] = '/',
	["\""] = '"',
	["\\"] = '\\',
}

local escape =
		(P"\\" * C(S'tbfnrt/"\\')) / function (e) return escape_map[e] end
local utfescape =
		P"\\" * P'u' *
		C((lpeg.R("09") + lpeg.R("af") + lpeg.R("AF"))^-4) / function (c)
			return (utfcp(tonumber('0x'..c)))
		end

local innerString = ((P(1) - S"\\\"") + escape + utfescape)^0

local quotedString = '"' * Cs(innerString) * '"' / '%1'

local g_obj = 0

local function a_key_value(p)
	return p / function(key, value)
		return { key, value }
	end
end

local function a_key_value_list(p)
	return p / function(a, b)
		if (#b < 1) then
			return a
		end

		local already_exist_map = {}
		already_exist_map[a[1]] = 1

		local t
		for i=1, #b do
			t = b[i]
			if already_exist_map[t[1]] == nil then
				a[#a+1] = t[1]
				a[#a+1] = t[2]
				already_exist_map[t[1]] = #a - 2
			end
		end

		return a
	end
end

local function a_json_object(p)
	return p / function(a)
		if #a == 0 then
			return {}
		end
		local ret = {}
		a = a[1]
		for i=1, #a, 2 do
			ret[a[i]] = a[i+1]
		end

		return ret
	end
end

local abool = C(P"true" + P"false") / function (b)
	if b == "true" then
		return true
	end
	return false
end


setmetatable(g_nullt, {
	__len=function () return -1 end,
	__index=function () return nil end,
	__tostring=function () return "null" end
})

local nullv = P'null' / function (b) return g_nullt end

local jsonp = P {
	"input",
	input = V("value")^1,
	object = a_json_object(leftBrace * Ct(V('members')^-1) * rightBrace),
	members = a_key_value_list(V('pair') * Ct((comma * V('pair'))^0)),
	pair = a_key_value(quotedString * colon * V("value")),
	value = quotedString + V("object") + V("array") + anumber + abool + nullv,
	array = leftBracket * (V('elements')^-1) * rightBracket,
	elements = Ct(V('value') * (comma * (V('value')))^0),
}

return {
	null = g_nullt,
	object = function (o)
		local ret = o or {}
		setmetatable(ret, g_object_mt)
		return ret
	end,
	stringify = json_stringify,
	parse = function (text)
	local _, ret =  pcall(function () return jsonp:match(text) end)
		return ret
	end
}

-- vim: set ts=2 sw=2 noet:
