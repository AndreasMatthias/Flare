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


--- Actions
-- @section Actions


--- Returns an action dict as table.
-- @pdfe dict action dictionary
-- @return Table
function Page:getAction(dict)
   local subtype = dict['S']
   if subtype == 'GoTo' then
      return self:getAction_Goto(dict)
   else
      return self:getDictionary2(dict)
   end
end


--- Returns a `GoTo` action dict as table.
-- @pdfe dict `GoTo` action dictionary
-- @return Table
function Page:getAction_Goto(dict)
   local dest = dict['D']
   if type(dest) == 'string' then
      return self:getAction_Goto_NamedDest(dest)
   else
      return self:getAction_Goto_DirectDest(dest)
   end
end


--- Returns a `GoTo` action dict as table.
-- The table contains a named destination.
-- @string dest destination string
-- @return Table
function Page:getAction_Goto_NamedDest(dest)
   dest  = self:getLinkPrefix() .. dest
   return { S = '/GoTo',
            D = string.format('(%s)', dest)}
end


--- Returns a `GoTo` action dict as table.
-- The table contains a direct destination.
-- @pdfe dest destination array
-- @return Table
function Page:getAction_Goto_DirectDest(dest)
   local destType = pdfe.getname(dest, 1)

   if destType == 'XYZ' then
      return self:getAction_Goto_XYZ_DirectDest(dest)

   elseif destType == 'Fit' or destType == 'FitB' then
      return self:getAction_Goto_Fit_DirectDest(dest)
      
   elseif destType == 'FitH' or destType == 'FitBH' then
      return self:getAction_Goto_FitH_DirectDest(dest)

   elseif destType == 'FitV' or destType == 'FitBV' then
      return self:getAction_Goto_FitV_DirectDest(dest)

   elseif destType == 'FitR' then
      return self:getAction_Goto_FitR_DirectDest(dest)

   else
      pkg.support()
   end
   return nil
end


--- Returns a PDF reference.
-- @number objnum object number
-- @return String
function Page:makeRef(objnum)
   if objnum then
      return string.format('%d 0 R', objnum)
   else
      return 'null'
   end
end


--- Returns a PDF reference.
-- For each imported PDF page the cache contains a key `page_obj_old`, which is
-- the object number of the existing (old) PDF page, and a key `page_obj_new`,
-- which is the object number of the new PDF page. This function returns
-- `page_obj_new` formatted as a PDF reference.
-- @number page_obj_old object number
-- @return String
function Page:getRefPageObjNew(page_obj_old)
   local page_obj_new = self:readFromCacheWithPageObj('page_obj_new', page_obj_old)
   local pageref = self:makeRef(page_obj_new)
   return pageref
end


--- Returns a `XYZ`-`GoTo` action dict as table.
-- @pdfe dest destination array
-- @return Table
function Page:getAction_Goto_XYZ_DirectDest(dest)
   local page_obj_old = luatex.getreference(dest, 1)
   local pageref = self:getRefPageObjNew(page_obj_old)
   
   local ctm = self:readFromCacheWithPageObj('ctm', page_obj_old)
   ctm = ctm or self.IdentityCTM
   local zoom = 0.5 * (ctm.a + ctm.d)

   local x = pdfe.getnumber(dest, 2)
   local y = pdfe.getnumber(dest, 3)
   local z = pdfe.getnumber(dest, 4)
   local xn, yn = self:applyCTM(ctm, x, y)
   local zn = z / zoom

   local destarray = pdfarray:new({pageref, '/XYZ', xn, yn, zn})
   return { S = '/GoTo',
            D = destarray }
end


--- Returns a `Fit`-`GoTo` action dict as table.
-- @pdfe dest destination array
-- @return Table
function Page:getAction_Goto_Fit_DirectDest(dest)
   local page_obj_old = luatex.getreference(dest, 1)
   local pageref = self:getRefPageObjNew(page_obj_old)
   local destarray = pdfarray:new({pageref, '/Fit'})
   return { S = '/GoTo',
            D = destarray }
end


--- Returns a `FitH`-`GotTo` action dict as table.
-- @pdfe dest destination array
-- @return Table
function Page:getAction_Goto_FitH_DirectDest(dest)
   local page_obj_old = luatex.getreference(dest, 1)

   local ctm = self:readFromCacheWithPageObj('ctm', page_obj_old)
   ctm = ctm or self.IdentityCTM
   
   local y = pdfe.getnumber(dest, 2)
   local _, yn = self:applyCTM(ctm, 0, y)
   
   local pageref = self:getRefPageObjNew(page_obj_old)
   local destarray = pdfarray:new({pageref, '/FitH', yn})
   return { S = '/GoTo',
            D = destarray }
end


--- Returns a `FitV`-`GoTo` action dict as table.
-- @pdfe dest destination array
-- @return Table
function Page:getAction_Goto_FitV_DirectDest(dest)
   local page_obj_old = luatex.getreference(dest, 1)

   local ctm = self:readFromCacheWithPageObj('ctm', page_obj_old)
   ctm = ctm or self.IdentityCTM
   
   local x = pdfe.getnumber(dest, 2)
   local xn, _= self:applyCTM(ctm, x, 0)
   
   local pageref = self:getRefPageObjNew(page_obj_old)
   local destarray = pdfarray:new({pageref, '/FitV', xn})
   return { S = '/GoTo',
            D = destarray }
end


--- Returns a `FitR`-`GoTo` action dict as table.
-- @pdfe dest destination array
-- @return Table
function Page:getAction_Goto_FitR_DirectDest(dest)
   local page_obj_old = luatex.getreference(dest, 1)

   local ctm = self:readFromCacheWithPageObj('ctm', page_obj_old)
   ctm = ctm or self.IdentityCTM

   local llx = pdfe.getnumber(dest, 2)
   local lly = pdfe.getnumber(dest, 3)
   local urx = pdfe.getnumber(dest, 4)
   local ury = pdfe.getnumber(dest, 5)

   local llxn, llyn = self:applyCTM(ctm, llx, lly)
   local urxn, uryn = self:applyCTM(ctm, urx, ury)
   
   local pageref = self:getRefPageObjNew(page_obj_old)
   local destarray = pdfarray:new({pageref, '/FitR', llxn, llyn, urxn, uryn})
   return { S = '/GoTo',
            D = destarray }
end


return Page
