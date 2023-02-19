--
-- Copyright 2021-2023 Andreas MATTHIAS
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


--- Destinations
-- @section Destinations
--
-- In PDF 1.2 all named destinations are stored in a name tree in
-- `/Catalog/Names/Dests` which maps destination names to destination
-- objects. Flare arranges this data differently to simplify
-- mapping from page objects to destination data. This data structure
-- is called a `destination table` and has the following form:
-- 
-- * __Destination table__:
--
--        {
--           [page-obj-old-1] = {
--               { name = 'section.1',
--                 type = 'XYZ',
--                 data = { 100, 200, 1 }
--               },
--               { name = 'section.2',
--                 type = 'FitH',
--                 data = { 100 },
--               },
--           },
--           [page-obj-old-2] = {
--               ...
--           },
--           ...
--        }


--- Copies all destinations of the current PDF page into
-- the new LaTeX document.
function Page:copyDests()
   self:saveDests()
   self:insertDestNodes()
end


--- Stores destinations.
-- Collects all named destination of the current PDF and
-- forwards them to @{Doc} to be stored in the destination bucket.
function Page:saveDests()
   local doc = self.doc
   local destTable = doc:getDestTable(self.GinKV.filename)
   if not destTable then
      destTable = self:makeDestTable()
      doc:addDestTable(self.GinKV.filename, destTable)
   end
end


--- Reads a PDF name tree.
-- It returns a Lua array in which each element represents one leaf
-- of the name tree and has the format:
--
--    {
--       name = 'page.1',
--       type = 'XYZ',
--       data = {120, 700, 2},
--       pageobj = 25,
--    }
--
-- @pdfe treenode node in a name tree
-- @table nameTree `nil` for initial call
-- @return Table
function Page:readDestNameTree(treenode, nameTree)
   nameTree = nameTree or {}
   local kids = pdfe.getarray(treenode, 'Kids')
   if kids and #kids > 1 then
      for idx = 0, #kids - 1 do
         -- zero-based indexing
         local subkid = pdfe.getdictionary(kids, idx)
         self:readDestNameTree(subkid, nameTree)
      end
   end
   local names = pdfe.getarray(treenode, 'Names')
   if names and #names > 1 then
      for idx = 0, #names - 1, 2 do
         -- zero-based indexing
         local name = pdfe.getstring(names, idx)
         local dest = pdfe.getdictionary(names, idx + 1)
         dest = self:getDestArray(dest)

         local nameTreeItem = self:splitDestArray(dest)
         nameTreeItem['name'] = name
         nameTree[#nameTree + 1] = nameTreeItem
      end
   end
   return nameTree
end


--- Returns a destination array.
-- A destination array looks like `[11 0 R /FitH 100]`.
-- @pdfe obj dictionary or array
-- @return Destination array
function Page:getDestArray(obj)
   if pdfe.type(obj) == 'pdfe.dictionary' then
      return pdfe.getarray(obj, 'D')
   else
      return obj
   end
end


-- Splits destination array.
-- @pdfe destArray destination array
-- @return Table with destination data
function Page:splitDestArray(destArray)
   local _, _, objnum = pdfe.getfromarray(destArray, 1)
   local name = pdfe.getname(destArray, 1)
   local data = {}
   for idx = 2, #destArray - 1 do
      data[#data + 1] = pdfe.getnumber(destArray, idx)
   end
   return {pageobj = objnum,
           type = name,
           data = data}
end


--- Returns a destination table for the current PDF.
-- See @{Page:Destinations} for a description of destination tables.
-- @pdfe dests `/Catalog/Names/Dests` dictionary
-- @return Destination table
function Page:makeDestTable()
   local catalog = pdfe.getcatalog(self.pdf)
   if not catalog.Names then
      return nil
   end
   local dests = pdfe.getdictionary(catalog.Names, 'Dests')
   if not dests then
      return nil
   end
   local nameTree = self:readDestNameTree(dests)
   local destTable = {}
   for _, item in ipairs(nameTree) do
      destTable[item.pageobj] = destTable[item.pageobj] or {}
      local t = destTable[item.pageobj]

      local prefix = self:getDestPrefix()
      
      t[#t + 1] = {name = item.name,
                   type = item.type,
                   data = item.data}
   end
   return destTable
end


--- Returns the prefix for `key`.
-- @string key key
-- @return String
function Page:getDestLinkPrefix(key)
   local prefix = self:getFlareKV(self.page, self.annotId, key)
   if prefix == nil then
      prefix = self.GinKV.filename .. '-'
   end
   prefix = self:sanitizeString(prefix)
   return prefix
end


--- Returns the prefix for destination names.
-- @return String
function Page:getDestPrefix()
   return self:getDestLinkPrefix('destPrefix')
end


--- Returns the prefix for link names.
-- @return String
function Page:getLinkPrefix()
   return self:getDestLinkPrefix('linkPrefix')
end


--- Sanitizes string for use as a PDF string.
-- @string str string
-- @return Sanitized string
function Page:sanitizeString(str)
   str = str:gsub('%(', '\\(')
   str = str:gsub('%)', '\\)')
   return str
end


--- Returns object number of page.
-- @number pagenum page number
-- @number counter counter (initial value: nil)
-- @pdfe treenode node in page tree (initial value: nil)
-- @number objnum object number (initial value: nil)
-- @return Object number
function Page:getPageObjNum(pagenum, counter, treenode, objnum)
   counter = counter or 0
   treenode = treenode or pdfe.getcatalog(self.pdf).Pages
   objnum = objnum or luatex.getreference(pdfe.getcatalog(self.pdf), 'Pages')
   if self:isPage(treenode) then
      counter = counter + 1
      if pagenum == counter then
         return objnum, counter
      else
         return nil, counter
      end
   end
   local c = pdfe.getinteger(treenode, 'Count')
   if pagenum <= counter + c then
      local kids = pdfe.getarray(treenode, 'Kids')
      for i, kid in ipairs(kids) do
         local objnum = luatex.getreference(kids, i)
         objnum, counter = self:getPageObjNum(pagenum, counter, kid, objnum)
         if objnum then
            return objnum
         end
      end
   else
      counter = counter + c
      return nil, counter
   end
end


--- Return true if `treenode` is a `/Page` object.
function Page:isPage(treenode)
   if treenode.Type == 'Page' then
      return true
   else
      return false
   end
end


--- Inserts all destination nodes into the LaTeX document.
function Page:insertDestNodes()
   local objnum = self:getPageObjNum(self.GinKV.page)
   local doc = self.doc
   local destTable = doc:getDestTable(self.GinKV.filename)
   if destTable then
      local dests = destTable[objnum]
      if dests then
         for i, dest in ipairs(dests) do
            self:insertDestNode(dest, objnum)
         end
      end
   end
end


--- Inserts a destination node into the LaTeX document.
-- @table dest destination (item of a destination table)
-- @number page_objnum object number of `dest`
function Page:insertDestNode(dest, page_objnum)
   local ctm = self:readFromCacheWithPageObj('ctm', page_objnum)
   ctm = ctm or self.IdentityCTM
   
   if dest.type == 'XYZ' then
      destNode, h, v = self:makeDestNode_XYZ(dest, ctm)

   elseif dest.type == 'Fit' or dest.type == 'FitB' then
      destNode, h, v = self:makeDestNode_Fit(dest, ctm)
      
   elseif dest.type == 'FitH' or dest.type == 'FitBH' then
      destNode, h, v = self:makeDestNode_FitH(dest, ctm)
      
   elseif dest.type == 'FitV' or dest.type == 'FitBV' then
      destNode, h, v = self:makeDestNode_FitV(dest, ctm)
      
   elseif dest.type == 'FitR' then
      destNode, h, v = self:makeDestNode_FitR(dest, ctm)
   end

   node.write(self:pushTo(destNode, h, v))
end


--- Creates a whatsit node of type `XYZ`.
-- @table dest destination (item of a destination table)
-- @table ctm CTM
function Page:makeDestNode_XYZ(dest, ctm)
   local x = dest.data[1]
   local y = dest.data[2]
   local z = dest.data[3] or 0
   local xn, yn = self:applyCTM(ctm, x, y)
   local zoom = 0.5 * (ctm.a + ctm.d)
   local zn = z / zoom
   local whatsit = node.new('whatsit', 'pdf_dest')
   whatsit.named_id = 1
   whatsit.dest_id = self:getDestPrefix() .. dest.name
   whatsit.dest_type = luatex.pdfeDestType.xyz
   whatsit.xyz_zoom = math.floor(1000 * zn)
   local h, v = xn - ctm.e, yn - ctm.f
   return whatsit, h, v
end


--- Creates a whatsit node of type `Fit`.
-- @table dest destination (item of a destination table)
-- @table ctm CTM
function Page:makeDestNode_Fit(dest, ctm)
   local whatsit = node.new('whatsit', 'pdf_dest')
   whatsit.named_id = 1
   whatsit.dest_id = self:getDestPrefix() .. dest.name
   whatsit.dest_type = luatex.pdfeDestType.fit
   return whatsit, 0, 0
end


--- Creates a whatsit node of type `FitH`.
-- @table dest destination (item of a destination table)
-- @table ctm CTM
function Page:makeDestNode_FitH(dest, ctm)
   local y = dest.data[1]
   local xn, yn = self:applyCTM(ctm, 0, y)
   local whatsit = node.new('whatsit', 'pdf_dest')
   whatsit.named_id = 1
   whatsit.dest_id = self:getDestPrefix() .. dest.name
   whatsit.dest_type = luatex.pdfeDestType.fith
   local h, v = xn - ctm.e, yn - ctm.f
   return whatsit, h, v
end


--- Creates a whatsit node of type `FitV`.
-- @table dest destination (item of a destination table)
-- @table ctm CTM
function Page:makeDestNode_FitV(dest, ctm)
   local x = dest.data[1]
   local xn, yn = self:applyCTM(ctm, x, 0)
   local whatsit = node.new('whatsit', 'pdf_dest')
   whatsit.named_id = 1
   whatsit.dest_id = self:getDestPrefix() .. dest.name
   whatsit.dest_type = luatex.pdfeDestType.fitv
   local h, v = xn - ctm.e, yn - ctm.f
   return whatsit, h, v
end


--- Creates a whatsit node of type `FitR`.
-- @table dest destination (item of a destination table)
-- @table ctm CTM
function Page:makeDestNode_FitR(dest, ctm)
   local llx = dest.data[1]
   local lly = dest.data[2]
   local urx = dest.data[3]
   local ury = dest.data[4]
   local llxn, llyn = self:applyCTM(ctm, llx, lly)
   local urxn, uryn = self:applyCTM(ctm, urx, ury)
   local whatsit = node.new('whatsit', 'pdf_dest')
   whatsit.named_id = 1
   whatsit.dest_id = self:getDestPrefix() .. dest.name
   whatsit.dest_type = luatex.pdfeDestType.fitr
   whatsit.width = self:bp2sp(urxn - llxn)
   whatsit.height = self:bp2sp(uryn - llyn)
   local h, v = llxn - ctm.e, llyn - ctm.f
   return whatsit, h, v
end


--- Pushes node `content` to position `(hpos, vpos)`.
-- @luatexnode content luatex node
-- @number hpos horizontal position
-- @number vpos vertical position
-- @return luatex node
function Page:pushTo(content, hpos, vpos)
   local hglue = node.new(node.id('glue'), node.subtype('userskip'))
   hglue.width = self:bp2sp(hpos)
   hglue.next = content

   local hbox = node.new(node.id('hlist'), node.subtype('box'))
   hbox.dir = 'TLT'
   hbox.width = tex.sp('0bp')
   hbox.head = hglue

   local vglue = node.new(node.id('glue'), node.subtype('userskip'))
   vglue.width = self:bp2sp(vpos) * -1
   vglue.next = hbox

   local vbox = node.new(node.id('vlist'), node.subtype('box'))
   vbox.dir = 'TLT'
   vbox.width = tex.sp('0bp')
   vbox.head = vglue

   return vbox
end


return Page
