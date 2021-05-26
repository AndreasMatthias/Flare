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
-- @number objnum object number of annotation
function Page:insertAnnot(annot, objnum)
   local annotbox = self:rect2tab(annot.Rect)
   local mediabox = self:getMediaBox()
   local pos = self:getTeXPos(mediabox, annotbox)

   self.ctm = self:getCTM()
   local scale = 0.5 * (self.ctm.a + self.ctm.d)
   local data = self:formatAnnotation(annot, objnum)
   if data == nil then
      return
   end

   local annot = node.new(node.id('whatsit'), node.subtype('pdf_annot'))
   local objnum_new = pdf.reserveobj('annot')
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


return Page
