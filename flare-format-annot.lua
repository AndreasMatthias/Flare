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


--- Formatting Annotations
-- @section formatting_annotations


--- Formats an arbitrary annotation.
-- Distributes work to more specialized formatting functions.
-- Returns a string to be used as the `data` field of a `pdf_annot` whatsit-node,
-- or `nil` if this annotation type is not supported.
-- @pdfe annot annotation dictionary
-- @number objnum object number of annotation
-- @return String
function Page:formatAnnotation(annot, objnum)
   if self:getUserInput('@@@') then
      return nil
   end
   local func = self:getAnnotFunc(annot)
   if func then
      local t = func(self, annot)
      return self:formatTable(t)
   else
      pkg.warning(
         string.format("Annotation of type '%s' not supported.", annot.Subtype))
      return nil
   end
end


function Page:getAnnotFunc(annot)
   return load('return getAnnot' .. annot.Subtype, nil, 't', self)()
end


--- Converts a Lua table into _one_ string.
-- Functions like `getAnnotText()`, `getAnnotCircle()`, ... return tables
-- whose keys are PDF dictionary keys and whose values are formatted strings.
-- This function converts such a table into a long string to be used
-- as the `data` field of a `pdf_annot` whatsit node.
-- @table t table
-- @boolean dict_tags internal flag, `nil` for initial call
-- @return Formatted string
function Page:formatTable(t, dict_tags)
   local spairs = pairs
   if _G._UNITTEST then
      spairs = sorted_pairs
   end
   dict_tags = dict_tags or false
   if type(t) == 'table' then
      if t.type == 'array' then
         local str = ''
         for _, v in spairs(t) do
            str = str .. ' ' .. self:formatTable(v, true)
         end
         return '[' .. str .. ' ]'
      else
         local str = ''
         for k, v in spairs(t) do
            str = string.format('%s /%s %s', str, k, self:formatTable(v, true))
         end
         if dict_tags then
            return '<<' .. str .. ' >>'
         else
            return str:sub(2)
         end
      end
   else
      return t
   end
end


--- Formats common annotation entries.
-- @pdfe annot annotation dictionary
-- @number objnum object number of annotation
-- @return Formatted String
function Page:getAnnotCommonEntries(annot, objnum)
   return {
      Subtype = self:formatName(annot, 'Subtype'),
      Contents = self:formatString(annot, 'Contents'),
      P = self:formatP(annot, 'P'),
      NM = self:formatString(annot, 'NM'),
      M = self:formatString(annot, 'M'),
      F = self:formatInteger(annot, 'F'),
      AP = self:getDictionary(annot, 'AP'),
      AS = self:formatName(annot, 'AS'),
      Border = self:formatBorder(annot, true),
      C = self:getArray(annot, 'C'),
      StructParent = self:formatInteger(annot, 'StructParent'),
      OC = self:getDictionary(annot, 'OC'),
   }
end


--- Formats markup annotation entries.
-- @pdfe annot annotation dictionary
-- @number objnum object number of annotation
-- @return Formatted String
function Page:getAnnotMarkupEntries(annot, objnum)
   return {
      T = self:formatString(annot, 'T'),
      Popup = self:getDictionary(annot, 'Popup'),
      CA = self:formatNumber(annot, 'CA'),
      RC = self:formatStringOrStream(annot, 'RC'),
      CreationDate = self:formatString(annot, 'CreationDate'),
      IRT = self:formatIRT(annot, objnum),
      Subj = self:formatString(annot, 'Subj'),
      RT = self:formatName(annot, 'RT'),
      IT = self:formatName(annot, 'IT'),
      ExData = self:getDictionary(annot, 'ExData'),
   }
end


--- Formats the value of a `/P` entry, eg: `4 0 R`
-- @return Formatted string
function Page:formatP()
   -- Does it make sense to provide user input for /P at all?
   local user = self:formatUserInput('P')
   if type(user) == 'string' then
      return user
   else
      return string.format('%s 0 R', pdf.getpageref(self.page))
   end
end


--- Formats the value of an `/IRT` entry, eg: `4 0 R`
-- @pdfe annot annotation dictionary
-- @number objnum object number of annotation
-- @return Formatted string
function Page:formatIRT(annot, objnum)
   local ptype, pval, objnum_orig = pdfe.getfromdictionary(annot, 'IRT')
   if ptype == nil then
      return nil
   end
   if ptype ~= luatex.pdfeObjType.reference then
      -- PDF spec says that /IRT is a dictionary! Really? Hmm ...
      -- Let's suppose that /IRT is a reference, wait for
      -- real world PDFs, and issue a warning for now:
      pkg.warning(
         string.format('/IRT shall be a reference, but is type %s', ptype))
      pkg.bugs()
      return nil
   end
   local annot_obj_new = self:findFromCache_AnnotObjNew(objnum)
   if annot_obj_new == nil then
      return nil
   else
      return string.format('%d 0 R', annot_obj_new)
   end
end


--- Formats a `Square` annotation dictionary
-- @pdfe annot annotation dictionary
-- @return Formatted string
function Page:getAnnotSquare(annot)
   local t = {
      BS = self:getDictionary(annot, 'BS'),
      IC = self:getArray(annot, 'IC'),
      BE = self:getDictionary(annot, 'BE'),
      RD = self:getArray(annot, 'RD'),
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   self:appendTable(t, self:getAnnotMarkupEntries(annot))
   return t
end


--- Formats a `Circle` annotation dictionary
-- @pdfe annot annotation dictionary
-- @return Formatted string
function Page:getAnnotCircle(annot)
   return self:getAnnotSquare(annot)
end


--- Formats a `Text` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Formatted string
function Page:getAnnotText(annot)
   local t = {
      Open = self:formatBoolean(annot, 'Open'),
      Name = self:formatName(annot, 'Name'),
      State = self:formatString(annot, 'State'),
      StateModel = self:formatString(annot, 'StateModel'),
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   self:appendTable(t, self:getAnnotMarkupEntries(annot))
   return t
end


--- Formats an array of coordinates, eg. `QuadPoints`.
-- @pdfe annot annotation dictionary
-- @string key key
-- @return Formatted string
function Page:getCoordinatesArray(annot, key)
   if annot[key] then
      local ctm = self:readFromCache('ctm')
      ctm = ctm or self.IdentityCTM

      local coords = annot[key]
      local newcoords = types.pdfarray:new()
      local idx = 1
      while idx <= #coords do
         local x, y = coords[idx], coords[idx + 1]
         local xn, yn = self:applyCTM(ctm, x, y)
         newcoords[#newcoords + 1] = xn
         newcoords[#newcoords + 1] = yn
         idx = idx + 2
      end
      return newcoords
   else
      return nil
   end
end


--- Formats a `Text Markup` annotion dictionary.
-- @pdfe annot annotation dictionary.
-- @return Formatted string.
function Page:getAnnotTextMarkup(annot)
   local t = {
      QuadPoints = self:getCoordinatesArray(annot, 'QuadPoints')
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   self:appendTable(t, self:getAnnotMarkupEntries(annot))
   return t
end


function Page:getAnnotFreeText_RD(obj, key)
   local array = obj[key]
   if not array then
      return nil
   end
   local ctm = self:readFromCache('ctm')
   ctm = ctm or self.IdentityCTM
   local scale = 0.5 * (ctm.a + ctm.d)
   local t = pdfarray:new()
   for idx = 1, #array do
      t[#t + 1] = array[idx] * scale
   end
   return t
end

function Page:getAnnotFreeText(annot)
   local t = {
      DA = self:formatString(annot, 'DA'),
      Q = self:formatInteger(annot, 'Q'),
      RC = self:formatStringOrStream(annot, 'RC'),
      DS = self:formatString(annot, 'DS'),
      CL = self:getCoordinatesArray(annot, 'CL'),
      IT = self:formatName(annot, 'IT'),
      BE = self:getDictionary(annot, 'BE'),
      RD = self:getAnnotFreeText_RD(annot, 'RD'),
      BS = self:getDictionary(annot, 'BS'),
      LE = self:getDictionary(annot, 'LE'),
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   self:appendTable(t, self:getAnnotMarkupEntries(annot))
   return t
end


function Page:getAnnotLink(annot)
   local t = {
      A = self:getAction(annot['A']),
      -- Dest
      H = self:formatName(annot, 'H'),
      PA = self:getDictionary(annot, 'PA'),
      QuadPoints = self:getCoordinatesArray(annot, 'QuadPoints'),
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   return t
end


function Page:getAnnotLine(annot)
   local t = {
      L = self:getCoordinatesArray(annot, 'L'),
      BS = self:getDictionary(annot, 'BS'),
      LE = self:getArray(annot, 'LE'),
      IC = self:getArray(annot, 'IC'),
      LL = self:formatNumberScaled(annot, 'LL', true),
      LLE = self:formatNumberScaled(annot, 'LLE', true),
      Cap = self:formatBoolean(annot, 'Cap'),
      IT = self:formatName(annot, 'IT'),
      LLO = self:formatNumberScaled(annot, 'LLO', true),
      CP = self:formatName(annot, 'CP'),
      -- TODO: Measure dictionary must be adjusted by the scaling factor
      Measure = self:getDictionary(annot, 'Measure'),
      CO = self:getArrayScaled(annot, 'CO', true),
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   self:appendTable(t, self:getAnnotMarkupEntries(annot))
   return t
end


--- Formats a `Highlight` annotation dictionary
-- @pdfe annot annotation dictionary.
-- @return Formatted string.
function Page:getAnnotHighlight(annot)
   return self:getAnnotTextMarkup(annot)
end


--- Formats an `Underline` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Formatted string
function Page:getAnnotUnderline(annot)
   return self:getAnnotTextMarkup(annot)
end


--- Formats an `StrikeOut` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Formatted string
function Page:getAnnotStrikeOut(annot)
   return self:getAnnotTextMarkup(annot)
end


--- Formats an `Squiggly` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Formatted string
function Page:getAnnotSquiggly(annot)
   return self:getAnnotTextMarkup(annot)
end


--- Formats a `/Border` item.
-- @pdfe annot annotation dictionary
-- @numbool scale scaling factor
-- @return Formatted string
function Page:formatBorder(annot, scale)
   scale = scale or false
   local user = self:formatUserInput('Border')
   if type(user) == 'string' then
      return user
   end
   if type(user) == 'table' and user.op == 'scale' then
      scale = user.val
   end
   return self:formatBorder_hlp(annot, scale)
end


--- Helper function for @{Page:formatBorder} which scales
-- a `/Border` array.
-- @pdfe annot aAnnotation dictionary
-- @numbool scale scaling factor
-- @return Formatted string
function Page:formatBorder_hlp(annot, scale)
   local border = annot.Border
   if border then
      local hradius = pdfe.getnumber(border, 0)
      local vradius = pdfe.getnumber(border, 1)
      local width = pdfe.getnumber(border, 2)
      local dash = pdfe.getarray(border, 3)
      dash = self:formatBorderDash(dash, scale)
      return string.format('[ %.5g %.5g %.5g %s]',
                           self:scaleNumber(hradius, scale),
                           self:scaleNumber(vradius, scale),
                           self:scaleNumber(width, scale),
                           dash)
   else
      return nil
   end
end


--- Formats a border dash item.
-- @pdfe dash pdfe array of dash
-- @numbool scale scaling factor
-- @return Formated string
function Page:formatBorderDash(dash, scale)
   local user = self:formatUserInput('BorderDash')
   if type(user) == 'string' then
      return user
   end
   if type(user) == 'table' and user.op == 'scale' then
      scale = user.val
   end
   if dash then
      local val1 = pdfe.getnumber(dash, 0)
      local val2 = pdfe.getnumber(dash, 1)
      return string.format('[ %.5g %.5g ]',
                           self:scaleNumber(val1, scale),
                           self:scaleNumber(val2, scale))
   else
      return ''
   end
end


--- Scales value `val`.
-- If `scale` is a number it acts as a scaling factor. If it is
-- `true` then the scaling factor of the page (image) is used
-- for scaling. If it is `false` no scaling is applied.
-- @numbool val Value
-- @number scale Scaling factor
-- @return Scaled value
function Page:scaleNumber(val, scale)
   if tonumber(scale) then
      return val * scale
   elseif scale == true then
      return val * 0.5 * (self.ctm.a + self.ctm.d)
   else
      return val
   end
end


--- Scales and formats a number.
-- @pdfe obj pdfe dictionary or array
-- @keyidx key key or index (one-based)
-- @number scale scaling factor
-- @return Formatted string.
function Page:formatNumberScaled(obj, key, scale)
   local user = self:formatUserInput(key)
   if type(user) == 'string' then
      return user
   else
      key = self:zero_based_indexing(obj, key)
      local val = pdfe.getnumber(obj, key)
      if val then
         return string.format('%.5g', self:scaleNumber(val, scale))
      else
         return nil
      end
   end
end


--- Auxiliary 
-- @section Auxiliary 


--- Appends table `tab2` to table `tab1`.
-- @table tab1
-- @table tab2
function Page:appendTable(tab1, tab2)
   for k, v in pairs(tab2) do
      tab1[k] = v
   end
end


return Page
