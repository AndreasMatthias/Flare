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


--- This class represents a certain page of a PDF file.
-- @classmod Page
local Page = {}

-- Loading of sub-modules.
local function require_sub(mod, name)
   local m = require(name)
   for k, v in pairs(m) do
      mod[k] = v
   end
end

require_sub(Page, 'flare-keyval')
require_sub(Page, 'flare-obj')
require_sub(Page, 'flare-annot')
require_sub(Page, 'flare-dest')
require_sub(Page, 'flare-action')

local pkg = require('flare-pkg')
local types = require('flare-types')
local pdfarray = types.pdfarray
local pdfdictionary = types.pdfdictionary
local luatex = require ('flare-luatex')


--- Constructor
-- @section Constructor

--- Creates a `Page` object.
-- A `Page` object represents a certain PDF page and is connected
-- to a LaTeX document via `doc.
-- @table doc LaTeX document (@{Doc})
-- @return New `Page` object
function Page:new (doc)
   local t = {}
   setmetatable(t, self)
   self.__index = self

   t.doc = doc
   t.pictureId = doc:addPdfPage(t)
   t.page = t.doc.LaTeXPageCounter

   t.GinKV = {}
   t.FlareKV = {}
   t.IdentityCTM = self:makeCTM(1, 0, 0, 1, 0, 0)
   t.ctm = t.IdentityCTM

   return t
end


--- File I/O
-- @section fileIO

--- Opens a PDF file for reading.
-- @string filename File name
function Page:openFile()
   self.pdf = pdfe.open(self:findFile())
   pdfe.unencrypt(self.pdf, self.userpassword, nil)
   local status = pdfe.getstatus(self.pdf)
   if status < 0 then
      pkg.error(
         string.format('PDF is password protected'))
   end
end


--- Returns the full path of a PDF file using `kpse` library.
-- File name may be specified with or without file name extension `.pdf`.
-- @string filename File name
-- @return File name
function Page:findFile()
   local kpse_type = 'graphic/figure'
   local filename_kpse =
      kpse.find_file(self.GinKV.filename, kpse_type) or
      kpse.find_file(self.GinKV.filename .. '.pdf', kpse_type)
   if not filename_kpse then
      pkg.error(string.format("File '%s' not found", self.GinKV.filename))
   end
   return filename_kpse
end


--- CTM and Positioning
-- @section CTM

--- Returns the current CTM.
-- This is the CTM being active just before inserting the PDF image.
--
-- Note that scaling of a PDF image can be done in two different ways:
--
--   * Using `pdf.setmatrix()`.
--   * Using options `width`, `height`, and `depth` of `\useimageresource`.
--
-- Both methods are used by LaTeX: The very first `scale` option of
-- `\includegraphics` is implemented using the second method while
-- all further `scale` options are implemented using the first method.
--
-- LuaTeX provides `pdf.getmatrix()` to get the CTM. But this works only
-- when using the first method for scaling. The second method of scaling
-- is not reachable by `pdf.getmatrix()`.
--
-- Therefore we need to catch the very first `scale` option of
-- `\includegraphics` manually, define the transformation matrix of this scaling
-- operation, and add it to the CTM. Eventually this calculated CTM can be used
-- to transform coordinate points given in any PDF annotation of this page.
--
-- This is the calculation of the CTM:
--
--     ⎡ s  0  0 ⎤ ⎡ a  b  0 ⎤   ⎡ sa  sb  0 ⎤
--     ⎢ 0  s  0 ⎥ ⎢ c  d  0 ⎥ = ⎢ sc  sd  0 ⎥
--     ⎣ 0  0  1 ⎦ ⎣ h  v  1 ⎦   ⎣  h   v  1 ⎦
--
--     a, b, c, d ... returned by `pdf.getmatrix()`
--     h, v       ... returned by `pdf.getpos()`
--     s          ... very first `scale` option of `\includegraphics`
--
-- **Note:** This implementation is flawed and doesn't work correctly
-- because `h` and `v` are the current TeX coordinates which do not
-- always coincide with the current PDF coordinates.
--
-- However, it seems to work correctly under following conditions:
--
--   * Using option `scale` of `\includegraphics` zero or more times.
--   * Using option `angle` of `\includegraphics` zero or one(!) time.
--
-- Everything else fails. Especially:
--
--   * Using options `width`, `height`, `x`, `y`, `origin`, ... of `\includegraphics`.
--   * Using `\scalebox`.
--   * Using `\rotatebox`.
--
-- @return CTM dictionary
function Page:getCTM()
   local a, b, c, d  = pdf.getmatrix()
   local h, v = pdf.getpos()
   h, v = self:sp2bp(h), self:sp2bp(v)
   local s = self.GinKV.scale or 1
   return { a = a*s, b = b*s,
            c = c*s, d = d*s,
            e = h, f = v }
end


--- Sets CTM.
-- @number a
-- @number b
-- @number c
-- @number d
-- @number e
-- @number f
function Page:makeCTM(a, b, c, d, e, f)
   return {a = a, b = b, c = c, d = d, e = e, f = f}
end


--- Applies CTM on point `(x, y)`.
--            ⎡ a  b  0 ⎤
--    [x y 1] ⎢ c  d  0 ⎥ = [ax+cy+e  bx+dy+f  1]
--            ⎣ e  f  1 ⎦
-- @table ctm CTM
-- @number x X-coordinate
-- @number y Y-coordinate
-- @return Transformed x-coordinate
-- @return Transformed y-coordinate
function Page:applyCTM(ctm, x, y)
   local xn = ctm.a * x + ctm.c * y + ctm.e
   local yn = ctm.b * x + ctm.d * y + ctm.f
   return xn, yn
end


--- Converts a pdfe rectangle into a lua table.
-- @pdfe rect Pdfe rectangle
-- @return Table
function Page:rect2tab(rect)
   return {
      ['llx'] = rect[1],
      ['lly'] = rect[2],
      ['urx'] = rect[3],
      ['ury'] = rect[4],
   }
end


--- Returns the MediaBox of the current PDF page.
-- @return Table (rectangle of mediabox)
function Page:getMediaBox()
   local mediabox = pdfe.getpage(self.pdf, self.GinKV.page).MediaBox
   return self:rect2tab(mediabox)
end


--- Returns a table to be used for creating TeX nodes.
-- @table mediabox Rectangle of mediabox
-- @table annotbox Rectangle of annotation
-- @return Table
function Page:getTeXPos(mediabox, annotbox)
   local scale = self.scale or 1
   local angle = self.angle or 0
   angle = angle % 360
   local phi = math.rad(angle)
   local cosphi, sinphi = math.cos(phi), math.sin(phi)

   if angle % 90 ~= 0 then
      pkg.warning(
         string.format(
            'Warning: Rotation by %s degree not supported.', self.angle))
   end

   local x1 = annotbox.llx - mediabox.llx
   local y1 = annotbox.lly - mediabox.lly
   local x2 = annotbox.urx - mediabox.llx
   local y2 = annotbox.ury - mediabox.lly

   local mh = mediabox.ury - mediabox.lly
   local mw = mediabox.urx - mediabox.llx

   local L, nx1, nx2
   L = 0
   if angle == 0 then
      nx1, ny1 = x1, y1
      nx2, ny2 = x2, y2
   elseif angle == 90 then
      nx1, ny1 = -y2 + mh, x1
      nx2, ny2 = -y1 + mh, x2
   elseif angle == 180 then
      nx1, ny1 = -x2 + mw, -y2 + mh
      nx2, ny2 = -x1 + mw, -y1 + mh
   elseif angle == 270 then
      nx1, ny1 = y1, -x2 + mw
      nx2, ny2 = y2, -x1 + mw
   end

   return {
      ['width'] = (nx2 - nx1) * scale,
      ['height'] = (ny2 - ny1) * scale,
      ['hshift'] = nx1 * scale,
      ['vshift'] = ny1 * scale,
   }
end


--- Cache
-- @section Cache


--- Writes data to the cache.
-- @string key key
-- @param val value
function Page:writeToCache(key, val)
   self.doc:writeToCache(self.pictureId, key, val)
end


--- Reads data from the cache.
-- @string key key
-- @return Value
function Page:readFromCache(key)
   return self.doc:readFromCache(self.pictureId, key)
end


--- Returns data from the cache for page object with number `page_obj_old`.
-- @string key key
-- @number page_obj_old page object number
-- @return Value
function Page:readFromCacheWithPageObj(key, page_obj_old)
   return self.doc:readFromCacheWithPageObj(key, page_obj_old)
end


--- Writes an object number of an annotation to the cache.
-- The object number is one from the existing (old) PDF file.
-- @number objnum object number
function Page:writeToCache_AnnotObjOld(objnum)
   self.doc:writeToCache_AnnotObjOld(self.annotId, objnum)
end


--- Writes an object number of an annotation to the cache.
-- The object number is one from the newly created PDF file.
-- @number objnum object number
function Page:writeToCache_AnnotObjNew(objnum)
   self.doc:writeToCache_AnnotObjNew(self.annotId, objnum)
end


--- Returns the new object number of an annotation from the cache.
-- The new object number corresponds to `annot_obj_old`
-- of the existing (old) PDF file.
-- @number annot_obj_old old annotation object number
-- @return New annotation object number
function Page:getFromCache_AnnotObjNew(annot_obj_old)
   return self.doc:getFromCache_AnnotObjNew(annot_obj_old)
end


--- Caches all relevant data. To be called during TeX shipout.
function Page:cacheData()
   self:writeToCache('ctm', self:getCTM())
   self:writeToCache('filename', self.GinKV.filename)
   self:writeToCache('page', self.GinKV.page)
   self:writeToCache('page_obj_old', self:getPageObjNum(self.GinKV.page))
   self:writeToCache('page_obj_new', pdf.getpageref(self.page))
end


--- Auxiliary 
-- @section Auxiliary


--- Removes trailing and leading whitespace.
-- @string str String
-- @return String
function Page:trim(str)
   if type(str) == 'string' then
      return str:match("^%s*(.-)%s*$")
   else
      return str
   end
end


--- Converts from `sp` (scaled points) to `bp` (big points).
-- @number num Number
-- @return Number
function Page:sp2bp(num)
   return num / 65536 * 72 / 72.27
end


--- Converts from `bp` (big points) to `sp` (scaled points).
-- @number num Number
-- @return Number
function Page:bp2sp(num)
   return num * 65536 / 72 * 72.27
end


return Page
