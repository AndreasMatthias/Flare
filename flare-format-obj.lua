--
-- Copyright 2021 Andreas MATTHIAS
--
-- This work may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License, either version 1.3c
-- of this license or (at your option) any later version.
-- The latest version of this license is in
--   http://www.latex-project.org/lppl.txt
-- and version 1.3c or later is part of all distributions of LaTeX
-- version 2008 or later.
--
-- This work has the LPPL maintenance status `maintained'.
-- 
-- The Current Maintainer of this work is Andreas MATTHIAS.
--


---
-- @classmod Page
local Page = {}

local pkg = require('flare-pkg')
local types = require('flare-types')
local pdfarray = types.pdfarray
local pdfdictionary = types.pdfdictionary
local luatex = require('flare-luatex')


--- Keys which are ignored and not copied.
local ignoredKeys = {
   Length = true,
   P = true,
}


--- Formatting Objects
-- @section formatting_objects


--- Formats a pdf boolean, eg: `true`.
-- @pdfe obj Dictionary or Array
-- @keyidx key Key or index (one-based indexing)
-- @return Formatted string
function Page:formatBoolean(obj, key)
   local user = self:formatUserInput(key)
   if type(user) == 'string' then
      return user
   else
      key = self:zero_based_indexing(obj, key)
      local val = pdfe.getboolean(obj, key)
      if val == true or val == false then
         return string.format('%s', val)
      else
         return nil
      end
   end
end


---Formats a pdf integer, eg: `1`.
-- @pdfe obj Dictionary or array
-- @keyidx key Key or index (one-based indexing)
-- @return Formatted string or nil
function Page:formatInteger(obj, key)
   local user = self:formatUserInput(key)
   if type(user) == 'string' then
      return user
   else
      key = self:zero_based_indexing(obj, key)
      local val = pdfe.getinteger(obj, key)
      if val then
         return string.format('%d', val)
      else
         return nil
      end
   end
end


---Formats a pdf number, eg: `1.23`.
-- @pdfe obj Dictionary or array
-- @keyidx key Key or index (one-based indexing)
-- @return Formatted string or nil
function Page:formatNumber(obj, key)
   local user = self:formatUserInput(key)
   if type(user) == 'string' then
      return user
   else
      key = self:zero_based_indexing(obj, key)
      local val = pdfe.getnumber(obj, key)
      if val then
         return string.format('%.5g', val)
      else
         return nil
      end
   end
end


---Formats an pdf name, eg: `/Bar`.
-- @pdfe obj Dictionary or array
-- @keyidx key Key or index (one-based indexing)
-- @return Formatted string or nil
function Page:formatName(obj, key)
   local user = self:formatUserInput(key)
   if type(user) == 'string' then
      return user
   else
      key = self:zero_based_indexing(obj, key)
      local val = pdfe.getname(obj, key)
      if val then
         return string.format('/%s', val)
      else
         return nil
      end
   end
end


---Formats an pdf string, eg: `(test)`.
-- @pdfe obj Dictionary or array
-- @keyidx key Key or index (one-based indexing)
-- @return Formatted string or nil
function Page:formatString(obj, key)
   local user = self:formatUserInput(key)
   if type(user) == 'string' then
      return user
   else
      key = self:zero_based_indexing(obj, key)
      local str, hex = pdfe.getstring(obj, key, false)
      if str then
         str, hex = self:clean_utf16(str, hex)
         if hex then
            return string.format('<%s>', str)
         else
            return string.format('(%s)', str)
         end
      else
         return nil
      end
   end
end


--- Checks if string is utf-16 encoded.
-- @string str String
-- @return Boolean
function Page:is_utf16(str)
   if str:sub(1, 2) == '\xFE\xFF' then
      return true
   else
      return false
   end
end


--- Converts a utf-16 string into a hex string.
-- @string str UTF-16 string
-- @return Hex-string
function Page:utf16_to_hex(str)
   t = {}
   for c in str:gmatch('.') do
      t[#t + 1] = string.format('%02X', string.byte(c))
   end
   return table.concat(t)
end


--- Checks, if string `str` is a utf-16 string and converts it into
-- a hex string. Otherwise return the string unmodified.
-- Parameter `str` and `hex` have the same meaning as in
-- `pdfe.getstring()`.
-- @string str
-- @boolean hex
-- @return String
-- @return Boolean
function Page:clean_utf16(str, hex)
   if self:is_utf16(str) then
      return self:utf16_to_hex(str), true
   else
      return str, hex
   end
end


--- Returns a @{Types:pdfarray} of formatted items, eg: `{'1', '2', '3'}`.
-- @pdfe obj Dictionary or array
-- @keyidx key Key or index (one-based indexing)
-- @return @{Types:pdfarray}
function Page:getArray(obj, key)
   local user = self:formatUserInput(key)
   if type(user) == 'string' then
      return user
   else
      local array = obj[key]
      if array then
         local t = pdfarray:new()
         for idx = 1, #array do
            -- TODO: no conversion to string if type is number or integer.
            -- Easier for unit testing.
            -- Maybe it should return a special type, similar to pdfarray
            -- and pdfdictionary, for all types? Then string conversion is
            -- not necessary here at all.
            t[#t + 1] = self:formatObj(array, idx)
         end
         return t
      else
         return nil
      end
   end
end


function Page:getArrayScaled(obj, key, scale)
   local user = self:formatUserInput(key)
   if type(user) == 'string' then
      return user
   else
      local array = obj[key]
      if array then
         local t = pdfarray:new()
         for idx = 1, #array do
            local val = pdfe.getnumber(array, idx - 1)
            t[#t + 1] = self:scaleNumber(val, scale)
         end
         pkg.pp(t)
         return t
      else
         return nil
      end
   end
end


--- Returns a @{Types:pdfdictionary} with formatted items,
-- eg: `{ A = '1', B = '2'}`.
-- @pdfe obj Dictionary or array
-- @keyidx key Key or index (one-based indexing)
-- @return @{Types:pdfdictionary}
function Page:getDictionary(obj, key)
   local user = self:formatUserInput(key)
   if type(user) == 'string' then
      return user
   else
      local dict = obj[key]
      if dict then
         local t = pdfdictionary:new()
         for k, _ in pairs(pdfe.dictionarytotable(dict)) do
            t[k] = self:formatObj(dict, k)
         end
         return t
      else
         return nil
      end
   end
end


--- Returns a @{Types:pdfdictionary} with formatted items,
-- eg: `{ A = '1', B = '2'}`.
-- Contrary to other format-functions which use an indirect object
-- reference (`obj[key]`), this function uses the object directly (`dict`).
-- @pdfe dict Dicionary
-- @return @{Types:pdfdictionary}
function Page:getDictionary2(dict)
   local t = pdfdictionary:new()
   for k, _ in pairs(pdfe.dictionarytotable(dict)) do
      t[k] = self:formatObj(dict, k)
   end
   return t
end


--- Formats a pdf stream object as dictionary entry, eg `/Foo 23 0 R`.
-- Note that stream objects are always indirect objects. Thus this
-- function returns a reference to the stream. The actual stream object
-- is created internally, but is not exposed outside this function.
-- @pdfe obj Dictionary
-- @string key Key
function Page:formatStream(obj, key)
   local user = self:formatUserInput(key)
   if type(user) == 'string' then
      return user
   else
      local stream, dict = pdfe.getstream(obj, key)
      local content = pdfe.readwholestream(stream)
      local dict = self:getDictionary2(dict)
      local n = pdf.immediateobj('stream', content, self:formatTable(dict))
      return string.format('%d 0 R', n)
   end
end


---Formats an pdf reference, eg: `3 0 R`.
-- As a side effect it copies the referenced pdf object.
-- @pdfe obj Dictionary
-- @string key Key
-- @return Formatted string
function Page:formatReference(obj, key)
   local user = self:formatUserInput(key)
   if type(user) == 'string' then
      return user
   else
      local _, ref, _ = self:getfromobj(obj, key)
      local ptype, pvalue, pdetail = pdfe.getfromreference(ref)
      if ptype == luatex.pdfeObjType.none or
         ptype == luatex.pdfeObjType.null then
         return nil
      elseif
         ptype == luatex.pdfeObjType.boolean or
         ptype == luatex.pdfeObjType.integer or
         ptype == luatex.pdfeObjType.number or
         ptype == luatex.pdfeObjType.name or
         ptype == luatex.pdfeObjType.string or
         ptype == luatex.pdfeObjType.array or
         ptype == luatex.pdfeObjType.dictionary then
         local n = pdf.immediateobj(string.format('%s', pvalue))
         return string.format('%d 0 R', n)

      elseif ptype == luatex.pdfeObjType.stream then
         return self:formatStream(obj, key)

      elseif ptype == luatex.pdfeObjType.reference then
         -- Note, that getfromreference() never returns a reference.
         -- If there are nested references, getfromreference() will
         -- always return the final pdf object.
         pkg.error('Internal error: Page:formatRefrence(), reference of reference')
      else
         pkg.error('Internal error: Page:formatRefrence(), type unknown:' .. ptype)
      end
   end
end


--- Formats a pdf string or pdf stream as dictionary entry.
-- @pdfe obj Dictionary
-- @string key Key
-- @return Formatted string
function Page:formatStringOrStream(obj, key)
   if ignoredKeys[key] then
      return nil
   end
   local user = self:formatUserInput(key)
   if type(user) == 'string' then
      return user
   else
      local val = pdfe.getstring(obj, key)
      if val ~= nil then
         return self:formatString(obj, key)
      end
      local val =pdfe.getstream(obj, key)
      if val ~= nil then
         return self:formatStream(obj, key)
      end
      return nil
   end
end


--- Formats an arbitrary pdf object.
-- @pdfe obj Dictionary or array
-- @keyidx key Key or index (one-based indexing)
-- @return Formatted string
function Page:formatObj(obj, key)
   local ptype, _, _ = self:getfromobj(obj, key)

   if ptype == nil or
      ptype == luatex.pdfeObjType.none or
      ptype == luatex.pdfeObjType.null then
      return ''

   elseif ptype == luatex.pdfeObjType.boolean then
      return self:formatBoolean(obj, key)

   elseif ptype == luatex.pdfeObjType.integer then
      return self:formatInteger(obj, key)

   elseif ptype == luatex.pdfeObjType.number then
      return self:formatNumber(obj, key)

   elseif ptype == luatex.pdfeObjType.name then
      return self:formatName(obj, key)

   elseif ptype == luatex.pdfeObjType.string then
      return self:formatString(obj, key)

   elseif ptype == luatex.pdfeObjType.array then
      return self:getArray(obj, key)

   elseif ptype == luatex.pdfeObjType.dictionary then
      return self:getDictionary(obj, key)

   elseif ptype == luatex.pdfeObjType.stream then
      return self:formatStream(obj, key)

   elseif ptype == luatex.pdfeObjType.reference then
      return self:formatReference(obj, key)

   else
      pkg.error('Not a valid pdfe type: ' .. ptype)
   end
end


--- Distributes work to `pdfe.getfromdictionary()` or `pdfe.getfromarray()`.
-- @pdfe obj Dictionary or array
-- @keyidx key Key or index (one-based indexing)
-- @return Type, value, detail
function Page:getfromobj(obj, key)
   local t = pdfe.type(obj)
   if t == 'pdfe.array' then
      return pdfe.getfromarray(obj, key)
   elseif t == 'pdfe.dictionary' then
      return pdfe.getfromdictionary(obj, key)
   else
      pkg.error('Internal error: Page:getfromobj()')
   end
end


--- Auxiliary 
-- @section auxiliary 

--- Throws an error if `obj` is a pdfe-array.
-- This is an internal error which can happen only if a developer added new
-- annotations incorrectly. It is not an end-user error.
-- @pdfe obj
function Page:errorIfArray(obj)
   if pdfe.type(obj) == 'pdfe.array' then
      pkg.error('Type pdfe.array not allowed')
   end
end


--- Converts from one- to zero-based indexing.
-- Return `key` as a zero-based index if `key` is a `number`
-- (ie. `obj` is a `pdfe-array`). Otherwise (ie. `obj` is a
-- dictionary) returns `key` unmodified.
-- @pdfe obj Dictionary or array
-- @keyidx key Key or index (one-based indexing)
-- @return Key or index (zero-based indexing)
function Page:zero_based_indexing(obj, key)
   if type(key) == 'number' then
      return key - 1
   else
      return key
   end
end



--- User input
-- @section user_input


--- Formats user input.
-- Normally returns a formatted string representing user input or
-- `nil` if no user input is available. But it might return a table
-- of type `{op = <op>, val = <val>}` if user input cannot be represented
-- as a formatted string, eg. the `scale` parameter.
-- @string key Key
-- @return Formatted string or `nil`
function Page:formatUserInput(key)
   local user = self:getUserInput(key)
   if user == nil then
      return nil
   elseif user.op == 'replace' then
      return string.format('%s', user.val)
   elseif user.op == 'ref' then
      return string.format('%s 0 R', user.val)
   elseif user.op == 'remove' then
      if user.val == true then
         return ''
      else
         return nil
      end
   else
      return user
   end
end


--- Returns user input if available.
-- The returned value is a table of type `{op = <op>, val = <val>}`
-- corresponding to the specified `key`, the current PDF page, and
-- the current annotation ID.
-- @string key Key
-- @return User input or `nil`
function Page:getUserInput(key)
   local page = self.GinKV.page
   local annotId = self.annotId
   local trails = {
      {page, annotId},
      {page, 'all'},
      {'all', annotId},
      {'all', 'all'}
   }
   for _, v in pairs(trails) do
      local page = v[1]
      local annotId = v[2]
      if self:checkUserInput(page, annotId, key) then
         return self.FlareKV[page][annotId][key]
      end
   end
   return nil
end


--- Returns `true` if user input available.
-- @numstr page Page number or `'all'`
-- @numstr annotId Annotation ID or `'all'`
-- @string key Key
-- @return Boolean
function Page:checkUserInput(page, annotId, key)
   if self.FlareKV[page] and
      self.FlareKV[page][annotId] and
      self.FlareKV[page][annotId][key] ~= nil then
      return true
   else
      return false
   end
end


return Page
