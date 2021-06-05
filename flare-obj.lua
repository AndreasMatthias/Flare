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


--- Basic types
-- @section basic types


--- Returns a boolean value.
-- @pdfe obj dictionary or Array
-- @keyidx key key or index (one-based indexing)
-- @return Boolean or user string
function Page:getBoolean(obj, key)
   local user = self:getUserInput(key)
   if type(user) == 'string' then
      return user
   else
      key = self:zero_based_indexing(obj, key)
      return pdfe.getboolean(obj, key)
   end
end


--- Returns an integer.
-- @pdfe obj dictionary or array
-- @keyidx key key or index (one-based indexing)
-- @number scale scaling factor
-- @return Integer or user string
function Page:getInteger(obj, key, scale)
   local user = self:getUserInput(key)
   if type(user) == 'string' then
      return user
   else
      key = self:zero_based_indexing(obj, key)
      return self:scaleNumber(pdfe.getinteger(obj, key), scale)
   end
end


--- Returns a number.
-- @pdfe obj dictionary or array
-- @keyidx key key or index (one-based indexing)
-- @number scale scaling factor
-- @return Number or user string
function Page:getNumber(obj, key, scale)
   local user = self:getUserInput(key)
   if type(user) == 'string' then
      return user
   else
      key = self:zero_based_indexing(obj, key)
      return self:scaleNumber(pdfe.getnumber(obj, key), scale)
   end
end


--- Returns a formatted pdf name object, eg: `/Bar`.
-- @pdfe obj dictionary or array
-- @keyidx key key or index (one-based indexing)
-- @return Formatted string
function Page:getName(obj, key)
   local user = self:getUserInput(key)
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


--- Returns a pdf string, eg: `(test)`.
-- @pdfe obj dictionary or array
-- @keyidx key key or index (one-based indexing)
-- @return Formatted string
function Page:getString(obj, key)
   local user = self:getUserInput(key)
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
-- @string str string
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


--- Scales a number.
-- If `scale` is a number it acts as a scaling factor. If it is
-- `true` then the scaling factor of the page (image) is used
-- for scaling. If it is `false` no scaling is applied.
-- @numbool num number
-- @number scale scaling factor
-- @return Scaled number
function Page:scaleNumber(num, scale)
   if tonumber(scale) then
      return num * scale
   elseif scale == true then
      return num * 0.5 * (self.ctm.a + self.ctm.d)
   else
      return num
   end
end


--- Returns a @{Types:pdfarray}.
-- @pdfe obj dictionary or array
-- @keyidx key key or index (one-based indexing)
-- @number scale scaling factor
-- @return @{Types:pdfarray}
function Page:getArray(obj, key, scale)
   local user = self:getUserInput(key)
   if type(user) == 'string' then
      return user
   else
      local array = obj[key]
      if array then
         local t = pdfarray:new()
         for idx = 1, #array do
            t[#t + 1] = self:getObj(array, idx, scale)
         end
         return t
      else
         return nil
      end
   end
end


--- Returns a @{Types:pdfdictionary}.
-- @pdfe obj dictionary or array
-- @keyidx key key or index (one-based indexing)
-- @number scale scaling factor
-- @return @{Types:pdfdictionary}
function Page:getDictionary(obj, key, scale)
   local user = self:getUserInput(key)
   if type(user) == 'string' then
      return user
   else
      local dict = obj[key]
      if dict then
         local t = pdfdictionary:new()
         for k, _ in pairs(pdfe.dictionarytotable(dict)) do
            t[k] = self:getObj(dict, k, scale)
         end
         return t
      else
         return nil
      end
   end
end


--- Returns a @{Types:pdfdictionary}.
-- Contrary to most other functions which use an indirect object
-- reference (`obj[key]`), this function uses the object directly (`dict`).
-- @pdfe dict dicionary
-- @number scale scaling factor
-- @return @{Types:pdfdictionary}
function Page:getDictionary2(dict, scale)
   local t = pdfdictionary:new()
   for k, _ in pairs(pdfe.dictionarytotable(dict)) do
      t[k] = self:getObj(dict, k, scale)
   end
   return t
end


--- Copies a stream and returns a reference to it.
-- @pdfe obj dictionary
-- @string key key
-- @return Formatted pdf reference, eg `9 0 R`
function Page:getStream(obj, key)
   local user = self:getUserInput(key)
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


--- Returns a reference, eg: `3 0 R`.
-- As a side effect it copies the referenced pdf object.
-- @pdfe obj dictionary
-- @string key key
-- @return Formatted string
function Page:getReference(obj, key)
   local user = self:getUserInput(key)
   if type(user) == 'string' then
      return user
   else
      local _, ref, _ = luatex.getfromobj(obj, key)
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
         return self:getStream(obj, key)

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


--- Returns a string or a reference to a stream.
-- Distributes work to @{Page:getString} and @{Page:getStream}.
-- @pdfe obj dictionary
-- @string key key
-- @return String or reference to stream
function Page:getStringOrStream(obj, key)
   if ignoredKeys[key] then
      return nil
   end
   local user = self:getUserInput(key)
   if type(user) == 'string' then
      return user
   else
      local val = pdfe.getstring(obj, key)
      if val ~= nil then
         return self:getString(obj, key)
      end
      local val =pdfe.getstream(obj, key)
      if val ~= nil then
         return self:getStream(obj, key)
      end
      return nil
   end
end


--- Returns a pdf object.
-- @pdfe obj dictionary or array
-- @keyidx key key or index (one-based indexing)
-- @number scale scaling factor
-- @return Pdf object
function Page:getObj(obj, key, scale)
   local ptype, _, _ = luatex.getfromobj(obj, key)

   if ptype == nil or
      ptype == luatex.pdfeObjType.none or
      ptype == luatex.pdfeObjType.null then
      return ''

   elseif ptype == luatex.pdfeObjType.boolean then
      return self:getBoolean(obj, key)

   elseif ptype == luatex.pdfeObjType.integer then
      return self:getInteger(obj, key, scale)

   elseif ptype == luatex.pdfeObjType.number then
      return self:getNumber(obj, key, scale)

   elseif ptype == luatex.pdfeObjType.name then
      return self:getName(obj, key)

   elseif ptype == luatex.pdfeObjType.string then
      return self:getString(obj, key)

   elseif ptype == luatex.pdfeObjType.array then
      return self:getArray(obj, key)

   elseif ptype == luatex.pdfeObjType.dictionary then
      return self:getDictionary(obj, key)

   elseif ptype == luatex.pdfeObjType.stream then
      return self:getStream(obj, key)

   elseif ptype == luatex.pdfeObjType.reference then
      return self:getReference(obj, key)

   else
      pkg.error('Not a valid pdfe type: ' .. ptype)
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
-- @pdfe obj dictionary or array
-- @keyidx key key or index (one-based indexing)
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
-- @string key key
-- @return Formatted string or `nil`
function Page:getUserInput(key)
   local page = self.GinKV.page
   local annotId = self.annotId
   local trails = {
      {page, annotId},
      {page, 'all'},
      {'all', annotId},
      {'all', 'all'}
   }
   local user = nil
   for _, v in pairs(trails) do
      local page = v[1]
      local annotId = v[2]
      if self:checkUserInput(page, annotId, key) then
         user = self.FlareKV[page][annotId][key]
      end
   end

   -- local user = self:getUserInput(key)
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


--- Returns `true` if user input available.
-- @numstr page page number or `'all'`
-- @numstr annotId annotation ID or `'all'`
-- @string key key
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
