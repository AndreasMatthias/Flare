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


--- Processing Keyvals
-- @section processing_keyvals
--
-- The following functions process a keyval string representing optional
-- arguments of `\includegraphics`. The string originates from LaTeX and
-- should have the following form:
--
--     {{key = 'scale', val = '0.5'}, {key = 'replaceC', val = '[1 1 0]'}, ...}
--
-- After processing the string these keyvals are stored in two tables:
--
--   * `Page.FlareKV`: options of Flare
--   * `Page.GinKV`: options of graphicx


--- Processes string `kv_str` and creates tables `Page.FlareKV` and `Page.GinKV`.
-- String `kv_str` represents optional arguments of `\includegraphics`.
-- @string kv_str Keyval string
function Page:processKeyvals(kv_str)
   local status, kv = pcall(
      function ()
         return loadstring('return' .. kv_str)()
   end)

   if not status then
      -- internal error
      pkg.error("Argument 'kv_str' must be a string representing a Lua table")
   end

   -- processs keyvals in reversed order
   if kv then
      for idx = #kv, 1, -1 do
         local key = kv[idx].key
         local val = kv[idx].val
         if self:isFlareKey(key) then
            local key, page, id, op = self:splitFlareKey(key)
            self:setFlareKV(page, id, key, op, val)
         else
            self:setGinKV(key, val)
         end
      end
   end
   self:setDefaultGinKVs()
end


--- Non-strict setter function for `Page.FlareKV`.
-- A key is added only if it is not mutually exclusive to already
-- existing keys in table `self.FlareKV`. The truth table below
-- reflects whether or not to add a new key.
--
-- Note that keys are processed in reverse order. See @{Page:processKeyvals}.
--
--    ─────────────────────────────────────
--    new_key   existing_key
--              ───────────────────────────
--              repl   rmT   rmF  scale   0
--    ─────────────────────────────────────
--    repl        ✗     ✗     ✓     ✗     ✓
--    ref         ✗     ✗     ✓     ✗     ✓
--    scale       ✗     ✗     ✓     ✗     ✓
--    rmT         ✗     ✗     ✗     ✗     ✓
--    rmF         ✗     ✗     ✗     ✗     ✓
--    ─────────────────────────────────────
--
--    repl  ... replace<key>
--    scale ... scale<key>
--    rmT   ... remove<key> = true
--    rmF   ... remove<key> = false
--    0     ... none of the keys exists
--
-- @number page Page.
-- @number annotId Annotation ID
-- @string key Key.
-- @string op Operation
-- @strbool val Value.
function Page:setFlareKV(page, annotId, key, op, val)
   local val_old, op_old = self:getFlareKV(page, annotId, key)
   if op_old == nil then
      self:setFlareKVStrict(page, annotId, key, op, val)
   elseif (op == 'replace' or
           op == 'ref' or
           op == 'scale') and
           op_old == 'remove' and val_old == false then
      self:setFlareKVStrict(page, annotId, key, op, val)
   end
end


--- Setter function for `Page.FlareKV`.
-- @numstr page Page
-- @numstr annotId Annotation Id
-- @string key Key
-- @string op Operation
-- @param val Value
function Page:setFlareKVStrict(page, annotId, key, op, val)
   if key == '' then
      key = '@@@'
   end
   self.FlareKV[page] = self.FlareKV[page] or {}
   self.FlareKV[page][annotId] = self.FlareKV[page][annotId] or {}
   self.FlareKV[page][annotId][key] = {op = op,
                                  val = self:makeBoolean(self:trim(val))}
end


--- Non-strict getter function for `Page.FlareKV`.
-- Does a non-strict search. Replaces `page` and `annotId` with `'all'` if
-- a strict search retrieved `nil`.
-- @number page Page
-- @numstr annotId Annotation Id
-- @string key Key
-- @return Value
-- @return Operation
function Page:getFlareKV(page, annotId, key)
   local op, val
   val, op = self:getFlareKVStrict(page, annotId, key)
   if val ~= nil then
      return val, op
   else
      val, op = self:getFlareKVStrict(page, 'all', key)
      if val ~= nil then
         return val, op
      else
         val, op = self:getFlareKVStrict('all', 'all', key)
         return val, op
      end
   end
end


--- Getter function for `Page.FlareKV`.
-- @number page Page
-- @string annotId Annotation Id
-- @string key Key
-- @return Value
-- @return Operation
function Page:getFlareKVStrict(page, annotId, key)
   if self.FlareKV[page] ~= nil and
      self.FlareKV[page][annotId] ~= nil and
      self.FlareKV[page][annotId][key] ~= nil then
      return self.FlareKV[page][annotId][key]['val'],
         self.FlareKV[page][annotId][key]['op']
   else
      return nil, nil
   end
end


--- Checks if `key` is a Flare-key.
-- @string key Key
-- @return Boolean
function Page:isFlareKey(key)
   if key:find('^flare') then
      return true
   else
      return false
   end
end


--- Splits a compound key name as deliverd by LaTeX into separate parts.
--
-- A compound key consists of a prefix, an operation string, a raw key
-- name, a page number, and an annotation ID.
-- For example the compound key name `annotReplaceFoo@3!1`
-- is split into:
--
-- * prefix: `annot`
-- * operation: `replace`
-- * key: `Foo`
-- * page number: `3`
-- * annot id: `1`
--
-- @string key Key
-- @return Raw key name
-- @return Page number or `all`
-- @return Annotation ID or `all`
-- @return Operation
function Page:splitFlareKey(key)
   key = self:removeFlareKeyPrefix(key)
   key = key:sub(1, 1):lower() .. key:sub(2)
   local op, key = self:getFlareKeyOperation(key)
   local page = self:getFlareKeyPage(key)
   local id = self:getFlareKeyId(key)
   key = self:removeFlareKeyPageId(key)
   return key, page, id, op
end


--- Returns operation of compound key name.
-- @string key Key
-- @return Operation
function Page:getFlareKeyOperation(key)
   for _, op in pairs({'replace', 'ref', 'remove', 'scale'}) do
      local _, idx = key:find('^' .. op)
      if idx then
         return op, key:sub(#op + 1)
      end
   end
   return nil, key
end


--- Returns page of compound key name.
-- @string key Key
-- @return Page
function Page:getFlareKeyPage(key)
   local _, _, page = key:find('.*(@%d+)')
   if page then
      return tonumber(page:sub(2))
   else
      return 'all'
   end
end


--- Returns annotation ID of coumpound key name.
-- @string key Key
-- @return Annot id.
function Page:getFlareKeyId(key)
   local _, _, id = key:find('.*(!%d+)')
   if id then
      return tonumber(id:sub(2))
   else
      return 'all'
   end
end


--- Removes prefix `annot` of compound key name.
-- @string key Key
function Page:removeFlareKeyPrefix(key)
   return key:sub(6)
end


--- Removes prefixes for page and annotation id.
-- @string key Key
-- @return Raw key name
function Page:removeFlareKeyPageId(key)
   idx1 = key:find('@%d+')
   idx2 = key:find('!%d+')
   if idx1 and idx2 then
      if idx1 < idx2 then
         return key:sub(0, idx1 - 1)
      else
         return key:sub(0, idx2 - 1)
      end
   elseif idx1 then
      return key:sub(0, idx1 - 1)
   elseif idx2 then
      return key:sub(0, idx2 - 1)
   else
      return key
   end
end


--- Setter function for `Page.GinKV`.
-- This function is called once for each non-Flare keyval of `\includegraphics`.
-- If it is called with the same `key` several times, it depdends on `key`
-- whether the first or the last keyval is set.
-- @string key Key
-- @string val Value
function Page:setGinKV(key, val)
   -- Note that processing of keyvals is still in reverse order,
   -- see processKeyvals().

   -- last one wins
   if key == 'filename' and not self.GinKV.filename then
      self.GinKV.filename = val

   elseif key == 'page' and not self.GinKV.page then
      self.GinKV.page = self:checkNumber('page', val)

   elseif key == 'userpassword' and not self.GinKV.userpassword then
      self.GinKV.userpassword = val
   end

   -- first one wins
   if key == 'scale' then
      self.GinKV.scale = self:checkNumber('scale', val)
   end
end


--- Sets default keyvals of `\includegraphics` in table `Page.GinKV`.
function Page:setDefaultGinKVs()
   if not self.GinKV.page then
      self.GinKV.page = 1
   end
end


--- Auxiliary 
-- @section auxiliary

--- Converts strings `true` and `false` into boolean values.
-- @string str String
-- @return String
function Page:makeBoolean(str)
   if str == 'true' then
      return true
   elseif str == 'false' then
      return false
   end
   return str
end


--- Checks, if string `val` can be converted into a number.
-- Returns the number or throws an error.
-- @string key Key
-- @string val Value
-- @return Number
function Page:checkNumber(key, val)
   num = tonumber(val)
   if num then
      return num
   else
      pkg.error("Invalid number '%s' for parameter '%s'", val, key)
   end
end


return Page
