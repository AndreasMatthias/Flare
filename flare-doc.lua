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


--- This class represents a LaTeX document.
-- @classmod Doc
local Doc = {}

local pkg = require('flare-pkg')
local types = require('flare-types')
local pdfarray = types.pdfarray
local pdfdictionary = types.pdfdictionary
local luatex = require('flare-luatex')


--- Constructor
-- @section Constructor

--- Creates a `Doc` object.
-- @return New object
function Doc:new ()
   local t = {}
   setmetatable(t, self)
   self.__index = self

   self.pictureCounter = 0
   self.pageCounter = 1

   luatexbase.add_to_callback(
      'finish_pdfpage',
      function ()
         self:newPage()
      end,
      'Flare callback')
   
   self.cacheOld = {} -- old cache from latest LaTeX run
   self.cacheNew = {} -- new cache from current LaTeX run
   self.dirtyCache = false
   self.destBucket = {} -- bucket of destination tables indexed by filename
   return t
end


--- Prepare for a new picture.
function Doc:newPicture()
   self.pictureCounter = self.pictureCounter + 1
end

--- Prepare for a new page.
function Doc:newPage()
   self.pageCounter = self.pageCounter + 1
end


--- Cache
-- @section Cache
--
-- The cache is a large table storing data from the current LaTeX
-- run. At the end of the current LaTeX run, the cache is written to file
-- `<jobname>.flr`. At the beginning of the next LaTeX run this file is
-- read back in. The cache of Flare serves the same purpose as the aux
-- file for LaTeX.
--
-- The cache table is an array, in which each element represents one
-- PDF page imported by `\includegraphics`. Each element is a table itself
-- with a structure like this:
--
--    {
--       filename = 'file.pdf',
--       page = 5,
--       page_obj_new = 34,
--       page_obj_old = 12,
--       ctm = {
--                a = 1, b = 0, c = 0, d = 1,
--                e = 140, f = 295,
--       },
--       annot = {
--          {
--             annot_obj_new = 23,
--             annot_obj_old = 56,
--          },
--          {
--             annot_obj_new = 45,
--             annot_obj_old = 67,
--          },
--          ...
--       }
--    }


--- Saves cache to file `<jobname>.flr`.
function Doc:saveCache()
   local filename = tex.jobname .. '.flr'
   fh = io.open(filename, 'w')
   local data = self:serialize(self.cacheNew)
   fh:write(data)
   fh:close()
end


--- Loads cache from file `<jobname>.flr`.
function Doc:loadCache()
   local filename = tex.jobname .. '.flr'
   local fh = io.open(filename, 'r')
   if fh then
      local data = fh:read('*a')
      fh:close()
      self.cacheOld = loadstring('return' .. data)()
   else
      self.cacheOld = {}
   end
end


--- Writes data to the cache.
-- @string key key
-- @param val value
function Doc:writeToCache(key, val)
   if not self:areEqual(self:readFromCache(key), val) then
      self.dirtyCache = true
   end
   local pc = self.pictureCounter
   local t = self.cacheNew
   t[pc] = t[pc] or {}
   t[pc][key] = val
end


--- Returns data from the cache.
-- @string key key
-- @return Value
function Doc:readFromCache(key)
   local pc = self.pictureCounter
   local t = self.cacheOld
   if t[pc] then
      return t[pc][key]
   else
      return nil
   end
end


--- Returns data from the cache for page object with number `page_obj_old`.
-- @string key key
-- @number page_obj_old page object number
-- @return Value
function Doc:readFromCacheWithPageObj(key, page_obj_old)
   for i, v in ipairs(self.cacheOld) do
      if v.page_obj_old == page_obj_old then
         return v[key]
      end
   end
   return nil
end


--- Writes an object number of an annotation to the cache.
-- The object number is one from the existing (old) PDF file.
-- @number annotId annotation Id
-- @number objnum object number
function Doc:writeToCache_AnnotObjOld(annotId, objnum)
   self:writeToCache_AnnotObj(annotId, 'annot_obj_old', objnum)
end


--- Writes an object number of an annotation to the cache.
-- The object number is one from the newly created PDF file.
-- @number annotId annotation Id
-- @number objnum object number
function Doc:writeToCache_AnnotObjNew(annotId, objnum)
   if not self:areEqual(self:readFromCache_AnnotObj(annotId, 'annot_obj_new'),
                        objnum) then
      self.dirtyCache = true
   end
   self:writeToCache_AnnotObj(annotId, 'annot_obj_new', objnum)
end


--- Writes an object number of an annotation to the cache.
-- @number annotId annotation Id
-- @string key key
-- @number objnum object number
function Doc:writeToCache_AnnotObj(annotId, key, objnum)
   local pc = self.pictureCounter
   local t = self.cacheNew
   t[pc] = t[pc] or {}
   t[pc]['annots'] = t[pc]['annots'] or {}
   t[pc]['annots'][annotId] = t[pc]['annots'][annotId] or {}
   t[pc]['annots'][annotId][key] = objnum
end


--- Returns value of annotation item from the cache.
-- @number annotId annotation Id
-- @string key key
-- @return Object number
function Doc:readFromCache_AnnotObj(annotId, key)
   local pc = self.pictureCounter
   local t = self.cacheOld
   if t[pc] and
      t[pc]['annots'] and
      t[pc]['annots'][annotId] then
      return t[pc]['annots'][annotId][key]
   end
end


--- Returns `annot_obj_new` of an annotation item from the cache.
-- `annot_obj_new` is the object number of the newly created PDF file
-- which corresponds to `annot_obj_old`, the object number of the
-- existing (old) PDF file. 
-- @number annot_obj_old old annotation object number
-- @return New annotation object number
function Doc:findFromCache_AnnotObjNew(annot_obj_old)
   for _, pic in ipairs(self.cacheOld) do
      if pic['annots'] then
         for _, annot in ipairs(pic['annots']) do
            if annot['annot_obj_old'] == annot_obj_old then
               return annot['annot_obj_new']
            end
         end
      end
   end
   return nil
end


--- Checks if cache is dirty and displays a warning.
function Doc:warnIfCacheDirty()
   if self.dirtyCache then
      pkg.warning('Annotations may have changed. Rerun to get annotations right')
   end
end


--- Bucket of Destination Tables
-- @section Bucket
--
-- Each PDF has its own destination table, see @{Page.Destinations}.
-- Destination tables are created with @{Page:makeDestTable} and
-- the destination tables of all PDFs are stored in the @{Doc} class
-- in table `destBucket` which is indexed by the file name of the
-- respective PDFs:
--
-- * __Bucket of destination tables__:
--
--        {
--           [file-1.pdf] = { ... destination table ... },
--           [file-2.pdf] = { ... destination table ... },
--           ...
--        }


--- Puts a destinations table into the bucket.
-- @string filename file name
-- @table destTable destination table
function Doc:addDestTable(filename, destTable)
   self.destBucket[filename] = destTable
end


--- Returns a destination table from the bucket.
-- @string filename filename
-- @return Destination table
function Doc:getDestTable(filename)
   return self.destBucket[filename]
end


--- Auxiliary Functions
-- @section Auxiliary


--- Serializes `data`.
-- @param data data
-- @number level indentation level
-- @return String with serialized data
function Doc:serialize(data, level)
   return self:serialize_(data, 0) .. '\n'
end


-- Helper function for @{Doc:serialize}.
-- @param data data
-- @number level indentation level
-- @return String with serialized data
function Doc:serialize_(data, level)
   level = level or 0
   local res = ''
   if type(data) == 'number' then
      res = tostring(data)
   elseif type(data) == 'string' then
      res = string.format('%q', data)
   elseif type(data) == 'table' then
      res = '{\n'
      for key, val in pairs(data) do
         res = res .. self:indent(string.format('[%s] = %s,\n',
                                                self:serialize_(key),
                                                self:serialize_(val, level + 1)),
                                  level + 1)
      end
      res = res .. self:indent('}', level)
   else
      pkg.error('Cannot serialize data of type: ' .. type(data))
   end
   return res
end


--- Indents string `str` to level `level`.
-- @string str string
-- @number level indentation level
-- @return Indented string
function Doc:indent(str, level)
   level = level or 0
   return string.rep('  ', level) .. str
end


--- Deep comparision of `t1` and `t2`.
-- @param t1
-- @param t2
-- @number eps epsilon neighbourhood
-- @return Boolean
function Doc:areEqual(t1, t2, eps)
   eps = eps or 0.00001
   -- different types
   if type(t1) ~= type(t2) then
      return false
   end
   if type(t1) ~= 'table' then
      -- non-table types
      if type(t1) == 'number' then
         return math.abs(t1 - t2) < eps
      else
         return t1 == t2
      end
   else
      -- table
      for k1, v1 in pairs(t1) do
         local v2 = t2[k1]
         if v2 == nil or not self:areEqual(v1, v2, eps) then
            return false
         end
      end
      for k2, v2 in pairs(t2) do
         local v1 = t1[k2]
         if v1 == nil or not self:areEqual(v1, v2, eps) then
            return false
         end
      end
      return true
   end
end


--- Deep comparision of `t1` and `t2`.
-- @param t1
-- @param t2
-- @number eps epsilon neighbourhood
-- @return Boolean
function Doc:notEqual(t1, t2, eps)
   return not self:areEqual(t1, t2, eps)
end


return Doc
