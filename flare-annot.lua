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



--- Annotations
-- @section annotations


--- Returns annotation array of current page.
-- @return pdfe annotation array
function Page:getAnnots()
   return pdfe.getpage(self.pdf, self.GinKV.page).Annots
end


--- Copies all annotations into the LaTeX document.
function Page:copyAnnots()
   local annots = self:getAnnots()
   if annots then
      for idx = 1, #annots do
         self.annotId = idx
         local annot = annots[idx]
         local objnum = luatex.getreference(annots, idx)
         if not self:getUserInput('remove', self.page, self.annotId) then
            self:insertAnnot(annot, objnum)
            self:writeToCache_AnnotObjOld(objnum)
         end
      end
   end
end


--- Inserts annotation `annot` into the LaTeX document.
-- @pdfe annot Annotation dictionary
-- @number objnum_old object number of annotation
function Page:insertAnnot(annot, objnum_old)
   local annotbox = self:rect2tab(annot.Rect)
   local mediabox = self:getMediaBox()
   local pos = self:getTeXPos(mediabox, annotbox)

   self.ctm = self:getCTM()
   local scale = 0.5 * (self.ctm.a + self.ctm.d)
   local data, objnum_new = self:formatAnnotation(annot, objnum_old)
   if data == nil then
      return
   end

   local annot = node.new(node.id('whatsit'), node.subtype('pdf_annot'))
   annot.width = self:bp2sp(pos.width) * scale
   annot.height = self:bp2sp(pos.height) * scale
   annot.depth = tex.sp('0bp')
   annot.data = data
   annot.objnum = objnum_new
   
   local hglue = node.new(node.id('glue'), node.subtype('userskip'))
   hglue.width = self:bp2sp(pos.hshift) * scale
   hglue.next = annot

   local hbox = node.new(node.id('hlist'), node.subtype('box'))
   hbox.dir = 'TLT'
   hbox.width = tex.sp('0bp')
   hbox.head = hglue

   local vglue = node.new(node.id('glue'), node.subtype('userskip'))
   vglue.width = self:bp2sp(pos.vshift) * scale * -1
   vglue.next = hbox

   local vbox = node.new(node.id('vlist'), node.subtype('box'))
   vbox.dir = 'TLT'
   vbox.width = tex.sp('0bp')
   vbox.head = vglue

   self.node_annot = annot
   self.node_hglue = hglue
   self.node_vglue = vglue

   node.write(vbox)

   self:writeToCache_AnnotObjNew(objnum_new)
end


--- Formats an arbitrary annotation.
-- Distributes work to more specialized formatting functions.
-- Returns a string to be used as the `data` field of a `pdf_annot` whatsit-node,
-- or `nil` if this annotation type is not supported.
-- @pdfe annot annotation dictionary
-- @number objnum object number of annotation
-- @return String
-- @return Object number
function Page:formatAnnotation(annot, objnum)
   if self:getUserInput('@@@') then
      return nil
   end
   local func = self:getAnnotFunc(annot)
   if func then
      local t, objnum = func(self, annot)
      return self:formatTable(t, false), objnum
   else
      pkg.warning(
         string.format("Annotations of type '%s' not supported", annot.Subtype))
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
-- @boolean delim dictionary delimiters
-- @return Formatted string
function Page:formatTable(t, delim)
   if delim == nil then
      delim = true
   end
   local spairs = pairs
   if _G._UNITTEST then
      spairs = sorted_pairs
   end
   if type(t) == 'table' then
      if t.type == 'array' then
         local str = ''
         for _, v in spairs(t) do
            str = str .. ' ' .. self:formatTable(v, true)
         end
         if delim then
            return '[' .. str .. ' ]'
         else
            return str:sub(2)
         end
      else
         local str = ''
         for k, v in spairs(t) do
            str = string.format('%s /%s %s', str, k, self:formatTable(v, true))
         end
         if delim then
            return '<<' .. str .. ' >>'
         else
            return str:sub(2)
         end
      end
   else
      return t
   end
end


--- Returns common annotation entries.
-- @pdfe annot annotation dictionary
-- @number objnum object number of annotation
-- @return Table
function Page:getAnnotCommonEntries(annot, objnum)
   return {
      Subtype = self:getName(annot, 'Subtype'),
      Contents = self:getString(annot, 'Contents'),
      P = self:getP(annot, 'P'),
      NM = self:getString(annot, 'NM'),
      M = self:getString(annot, 'M'),
      F = self:getInteger(annot, 'F'),
      AP = self:getDictionary(annot, 'AP'),
      AS = self:getName(annot, 'AS'),
      Border = self:formatBorder(annot, true),
      C = self:getArray(annot, 'C'),
      StructParent = self:getInteger(annot, 'StructParent'),
      OC = self:getDictionary(annot, 'OC'),
   }
end


--- Returns markup annotation entries.
-- @pdfe annot annotation dictionary
-- @number objnum object number
-- @return Table
function Page:getAnnotMarkupEntries(annot, objnum)
   return {
      T = self:getString(annot, 'T'),
      Popup = self:getDictionary(annot, 'Popup'),
      CA = self:getNumber(annot, 'CA'),
      RC = self:getStringOrStream(annot, 'RC'),
      CreationDate = self:getString(annot, 'CreationDate'),
      IRT = self:formatIRT(annot, objnum),
      Subj = self:getString(annot, 'Subj'),
      RT = self:getName(annot, 'RT'),
      IT = self:getName(annot, 'IT'),
      ExData = self:getDictionary(annot, 'ExData'),
   }
end


--- Formats the value of a `/P` entry, eg: `4 0 R`
-- @return Formatted string
function Page:getP()
   -- Does it make sense to provide user input for /P at all?
   local user = self:getUserInput('P')
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
   local annot_obj_new = self:getFromCache_AnnotObjNew(objnum)
   if annot_obj_new == nil then
      return nil
   else
      return self:makeRef(annot_obj_new)
   end
end


--- Returns a `Square` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Table
function Page:getAnnotSquare(annot)
   local t = {
      BS = self:getBorderStyle(annot, 'BS'),
      IC = self:getArray(annot, 'IC'),
      BE = self:getDictionary(annot, 'BE'),
      RD = self:getArray(annot, 'RD'),
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   self:appendTable(t, self:getAnnotMarkupEntries(annot))
   return t, pdf.reserveobj('annot')
end


--- Returns a `Circle` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Table
-- @return Object number
function Page:getAnnotCircle(annot)
   return self:getAnnotSquare(annot)
end


--- Returns a a `Text` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Table
-- @return Object number
function Page:getAnnotText(annot)
   local t = {
      Open = self:getBoolean(annot, 'Open'),
      Name = self:getName(annot, 'Name'),
      State = self:getString(annot, 'State'),
      StateModel = self:getString(annot, 'StateModel'),
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   self:appendTable(t, self:getAnnotMarkupEntries(annot))
   return t, pdf.reserveobj('annot')
end


--- Return an array of coordinates, eg. `QuadPoints`.
-- @pdfe annot annotation dictionary
-- @string key key
-- @return Table
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


--- Return an array of array of coordinates, eg. `InkList`.
-- @pdfe annot annotation dictionary
-- @string key key
-- @return Table
function Page:getCoordinatesArrayArray(annot, key)
   if annot[key] then
      local ctm = self:readFromCache('ctm')
      ctm = ctm or self.IdentityCTM

      local t = types.pdfarray:new()
      for _, coords in ipairs(annot[key]) do
         local newcoords = types.pdfarray:new()
         local idx = 1
         while idx <= #coords do
            local x, y = coords[idx], coords[idx + 1]
            local xn, yn = self:applyCTM(ctm, x, y)
            newcoords[#newcoords + 1] = xn
            newcoords[#newcoords + 1] = yn
            idx = idx + 2
         end
         t[#t + 1] = newcoords
      end
      return t
   else
      return nil
   end
end


--- Returns a `Text Markup` annotion dictionary.
-- @pdfe annot annotation dictionary.
-- @return Table
-- @return Object number
function Page:getAnnotTextMarkup(annot)
   local t = {
      QuadPoints = self:getCoordinatesArray(annot, 'QuadPoints')
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   self:appendTable(t, self:getAnnotMarkupEntries(annot))
   return t, pdf.reserveobj('annot')
end


--- Returns a `FreeText` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Table
-- @return Object number
function Page:getAnnotFreeText(annot)
   local t = {
      DA = self:getString(annot, 'DA'),
      Q = self:getInteger(annot, 'Q'),
      RC = self:getStringOrStream(annot, 'RC'),
      DS = self:getString(annot, 'DS'),
      CL = self:getCoordinatesArray(annot, 'CL'),
      IT = self:getName(annot, 'IT'),
      BE = self:getDictionary(annot, 'BE'),
      RD = self:getAnnotFreeText_RD(annot, 'RD'),
      BS = self:getBorderStyle(annot, 'BS'),
      LE = self:getDictionary(annot, 'LE'),
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   self:appendTable(t, self:getAnnotMarkupEntries(annot))
   return t, pdf.reserveobj('annot')
end


--- Returns the `RD` rectangle of a `FreeText` annotation.
-- @pdfe obj dictionary
-- @string key key
-- @return Table
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


--- Returns a `Link` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Table
-- @return Object number
function Page:getAnnotLink(annot)
   local t = {
      A = self:getAction(annot['A']),
      -- Dest
      H = self:getName(annot, 'H'),
      PA = self:getDictionary(annot, 'PA'),
      QuadPoints = self:getCoordinatesArray(annot, 'QuadPoints'),
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   return t, pdf.reserveobj('annot')
end


--- Returns a `Line` annotation dicationary.
-- @pdfe annot annotation dictionary
-- @return Table
-- @return Object number
function Page:getAnnotLine(annot)
   local t = {
      L = self:getCoordinatesArray(annot, 'L'),
      BS = self:getBorderStyle(annot, 'BS'),
      LE = self:getArray(annot, 'LE'),
      IC = self:getArray(annot, 'IC'),
      LL = self:getNumber(annot, 'LL', true),
      LLE = self:getNumber(annot, 'LLE', true),
      Cap = self:getBoolean(annot, 'Cap'),
      IT = self:getName(annot, 'IT'),
      LLO = self:getNumber(annot, 'LLO', true),
      CP = self:getName(annot, 'CP'),
      -- TODO: Measure dictionary must be adjusted by the scaling factor
      Measure = self:getDictionary(annot, 'Measure'),
      CO = self:getArray(annot, 'CO', true),
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   self:appendTable(t, self:getAnnotMarkupEntries(annot))
   return t, pdf.reserveobj('annot')
end


--- Returns a `Highlight` annotation dictionary.
-- @pdfe annot annotation dictionary.
-- @return Table
-- @return Object number
function Page:getAnnotHighlight(annot)
   return self:getAnnotTextMarkup(annot)
end


--- Returns an `Underline` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Table
-- @return Object number
function Page:getAnnotUnderline(annot)
   return self:getAnnotTextMarkup(annot)
end


--- Returns a `StrikeOut` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Table
-- @return Object number
function Page:getAnnotStrikeOut(annot)
   return self:getAnnotTextMarkup(annot)
end


--- Returns a `Squiggly` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Table
-- @return Object number
function Page:getAnnotSquiggly(annot)
   return self:getAnnotTextMarkup(annot)
end


--- Returns a `Polygon` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Table
-- @return Object number
function Page:getAnnotPolygon(annot)
   local t = {
      Vertices = self:getCoordinatesArray(annot, 'Vertices'),
      LE = self:getArray(annot, 'LE'),
      BS = self:getBorderStyle(annot, 'BS'),
      IC = self:getArray(annot, 'IC'),
      BE = self:getDictionary(annot, 'BE', true),
      IT = self:getName(annot, 'IT'),
      -- TODO: Scaling of measure dicionary necessary.
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   self:appendTable(t, self:getAnnotMarkupEntries(annot))
   return t, pdf.reserveobj('annot')
end


--- Returns a `PolyLine` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Table
-- @return Object number
function Page:getAnnotPolyLine(annot)
   return self:getAnnotPolygon(annot)
end


--- Returns a `Stamp` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Table
-- @return Object number
function Page:getAnnotStamp(annot)
   local t = {
      Name = self:getName(annot, 'Name'),
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   self:appendTable(t, self:getAnnotMarkupEntries(annot))
   return t, pdf.reserveobj('annot')
end


--- Returns an `Ink` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Table
-- @return Object number
function Page:getAnnotInk(annot)
   local t = {
      InkList = self:getCoordinatesArrayArray(annot, 'InkList'),
      BS = self:getBorderStyle(annot, 'BS'),
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   self:appendTable(t, self:getAnnotMarkupEntries(annot))
   return t, pdf.reserveobj('annot')
end


--- Returns a `FileAttachment` annotation table.
-- @pdfe annot annotation dictionary
-- @return Table.
-- @return Object number
function Page:getAnnotFileAttachment(annot)
   local t = {
      FS = self:getFileSpecification(annot, 'FS'),
      Name = self:getName(annot, 'Name'),
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   self:appendTable(t, self:getAnnotMarkupEntries(annot))
   return t, pdf.reserveobj('annot')
end


--- Returns an `FS` (file specification) dicationary.
-- @pdfe dict dictionary
-- @string key key
-- @return Table
function Page:getFileSpecification(dict, key)
   -- file spec string
   local str = pdfe.getstring(dict, key)
   if str then
      return str
   end
   -- file spec dictionary
   local dict = pdfe.getdictionary(dict, key)
   local t = {
      Type = '/Filespec',
      FS = self:getName(dict, 'FS'),
      F = self:getString(dict, 'F'),
      UF = self:getString(dict, 'UF'),
      DOS = self:getString(dict, 'DOS'),
      Mac = self:getString(dict, 'Mac'),
      Unix = self:getString(dict, 'Unix'),
      ID = self:getArray(dict, 'ID'),
      V = self:getBoolean(dict, 'V'),
      EF = self:getEmbeddedFileDict(dict, 'EF'),
      RF = self:getRelatedFileDict(dict, 'RF'),
      Desc = self:getString(dict, 'Desc'),
      CI = self:getDictionary(dict, 'CI'),
   }
   return t
end


--- Returns an `EF` (embedded file) dicionary
-- @pdfe dict dictionary
-- @string key key
-- @return Table
function Page:getEmbeddedFileDict(dict, key)
   dict = pdfe.getdictionary(dict, key)
   if dict == nil then
      return nil
   end
   local t = {
      F = self:getEmbeddedFileStreamDict(dict, 'F'),
      UF = self:getEmbeddedFileStreamDict(dict, 'UF'),
      DOS = self:getEmbeddedFileStreamDict(dict, 'DOS'),
      Mac= self:getEmbeddedFileStreamDict(dict, 'Mac'),
      Unix = self:getEmbeddedFileStreamDict(dict, 'Unix'),
   }
   return t
end


--- Returns an embedded file stream dictionary.
-- @pdfe dict dictionary
-- @string key key
-- @return Table
function Page:getEmbeddedFileStreamDict(dict, key)
   if pdfe.type(dict[key]) == 'pdfe.stream' then
      -- TODO: do not return an arbitrary stream, but a stream
      -- with the special stream dictionary of Page:getEmbeddedFileParams()
      return self:getStream(dict, key)
   else
      return nil
   end
end


--- Returns an embedded file parameter dictionary.
-- @pdfe dict dictionary
-- @string key key
-- @return table
function Page:getEmbeddedFileParams(dict, key)
   dict = pdfe.getdictionary(dict, key)
   if dict == nil then
      return nil
   end
   local t = {
      Size = self:getInteger(dict, 'Size'),
      CreationDate = self:getString(dict, 'CreationDate'),
      ModDate = self:getString(dict, 'ModDate'),
      Mac = self:getMacFileInfo(dict, 'Mac'),
      CheckSum = self:getString(dict, 'CheckSum'),
   }
   return t
end


--- Returns a Mac file info dictionary.
-- @pdfe dict dictionary
-- @string key key
-- @return Table
function Page:getMacFileInfo(dict, key)
   dict = pdfe.getdictionary(dict, key)
   if dict == nil then
      return nil
   end
   local t = {
      Subtype = self:getInteger(dict, 'Subtype'),
      Creator = self:getInteger(dict, 'Creator'),
      ResFork = self:getStream(dict, 'ResFork'),
   }
   return t
end


--- Returns an `RF` (related files) dictionary.
-- @pdfe dict dictionary
-- @string key key
-- @return Table
function Page:getRelatedFileDict(dict, key)
   dict = pdfe.getdictionary(dict, key)
   if dict == nil then
      return nil
   end
   local t = {
      F = self:getRelatedFileArray(dict['F']),
      UF = self:getRelatedFileArray(dict['UF']),
      DOS = self:getRelatedFileArray(dict['DOS']),
      Mac= self:getRelatedFileArray(dict['Mac']),
      Unix = self:getRelatedFileArray(dict['Unix']),
   }
   return t
end


--- Returns a file array (an entry of an `RF` dictionary).
-- @pdfe array array
-- @return table
function Page:getRelatedFileArray(array)
   local t = types.pdfarray:new()
   for idx = 1, #array, 2 do
      t[#t + 1] = self:getString(array, idx)
      t[#t + 1] = self:getStream(array, idx + 1)
   end
end


--- Returns a `Widget` annotation dictionary.
-- @pdfe annot annotation dictionary
-- @return Table
-- @return Object number
function Page:getAnnotWidget(annot)
   local objnum = pdf.reserveobj('annot')
   local t = {
      H = self:getName(annot, 'H'),
      MK = self:getAppearanceCharacteristicsDict(annot, 'MK'),
      A = self:getDictionary(annot, 'A'),
      AA = self:getDictionary(annot, 'AA'),
      BS = self:getDictionary(annot, 'BS'),
      Parent = self:createField(annot.Parent, objnum),
   }
   self:appendTable(t, self:getAnnotCommonEntries(annot))
   return t, objnum
end


--- Creates a field object.
-- @pdfe field field dictionary
-- @number objnum_kid object number of kid
-- @return Reference
function Page:createField(field, objnum_kid)
   if field == nil then
      return nil
   end
   local t = self:getField(field, objnum_kid)
   local objnum_field = pdf.immediateobj(self:formatTable(t))
   self:addFieldToAcroForm(objnum_field)
   return self:makeRef(objnum_field)
end


--- Add a field to the `Fields` entry of an `AcroForm` dictionary.
-- @number objnum object number of field
function Page:addFieldToAcroForm(objnum)
   local str = string.format(
      '\\ExplSyntaxOn' ..
      '\\FLR_AddFieldToAcroForm:n{%d}', objnum)
   tex.print(str)
end


--- Returns a field ('FT') dictionary.
-- @pdfe field field dictionary
-- @number objnum_kid object number of kid
-- @return Table
function Page:getField(field, objnum_kid)
   return {
      FT = self:getName(field, 'FT'),
      Kids = types.pdfarray:new({self:makeRef(objnum_kid)}),
      T = self:getString(field, 'T'),
      TU = self:getString(field, 'TU'),
      TM = self:getString(field, 'TM'),
      Ff = self:getInteger(field, 'Ff'),
      V = self:getObj(field, 'V'),
      DV = self:getObj(field, 'DV'),
      AA = self:getDictionary(field, 'AA'),
   }
end


function Page:getAppearanceCharacteristicsDict(obj, key)
   local annot = obj[key]
   if annot == nil then
      return nil
   end
   local t = {
      R = self:getInteger(annot, 'R'),
      BC = self:getArray(annot, 'BC'),
      GB = self:getArray(annot, 'BG'),
      CA = self:getString(annot, 'CA'),
      RC = self:getString(annot, 'RC'),
      AC = self:getString(annot, 'AC'),
      I = self:getStream(annot, 'I'),
      RI = self:getStream(annot, 'RI'),
      IX = self:getStream(annot, 'IX'),
      IF = self:getIconFitDict(annot, 'IF'),
      TP = self:getInteger(annot, 'TP'),
   }
   return t
end


function Page:getIconFitDict(obj, key)
   local annot = obj[key]
   if annot == nil then
      return nil
   end
   local t = {
      SW = self:getName(annot, 'SW'),
      S = self:getName(annot, 'S'),
      A = self:getArray(annot, 'A'),
      FB = self:getBoolean(annot, 'FB'),
   }
   return t
end


--- Formats a `/Border` item.
-- @pdfe annot annotation dictionary
-- @numbool scale scaling factor
-- @return Formatted string
function Page:formatBorder(annot, scale)
   scale = scale or false
   local user = self:getUserInput('Border')
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
   local user = self:getUserInput('BorderDash')
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


function Page:getBorderStyle(annot, key)
   local bs = annot[key]
   if bs == nil then
      return nil
   end
   local t = types.pdfdictionary:new({
         Type = '/Border',
         W = self:getNumber(bs, 'W', true),
         S = self:getName(bs, 'S'),
         D = self:getArray(bs, 'D', true),
   })
   return t
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
