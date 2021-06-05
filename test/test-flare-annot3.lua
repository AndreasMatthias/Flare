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

local loader = require('luapackageloader')
loader.add_lua_searchers()

local bh = require('busted-helper')
bh.remove_unknown_args()

require('busted.runner')({output = 'utfTerminal'})
require('my_assertions')
assert:set_parameter('TableFormatLevel', -1)
print()

luatex = require('flare-luatex')
flare = require('flare')
Doc = flare.Doc
Page = flare.Page
types = flare.types
pkg = require('flare-pkg')
pp = pkg.pp

stringio = require('pl.stringio')
nt = require('nodetree')


function createTestFile(filename, body)
   infile = 'tmp_' .. filename .. '.tex'
   outfile = 'tmp_' .. filename .. '.pdf'
   logfile = 'tmp_' .. filename .. '.log'

   local fh = io.open('template.tex', 'r')
   local content = fh:read('a')
   content = content:gsub('<body>', body)
   fh:close()

   local fh =  io.open(infile, 'w')
   fh:write(content)
   fh:close()

   local cmd = string.format(
      'lualatex --interaction nonstopmode %s > /dev/null', infile)

   local ret = os.execute(cmd)
   if ret ~= 0 then
      os.execute(string.format('cat %s', logfile))
   end
   assert.same(0, ret)
   
   local ret = os.execute(cmd)
   if ret ~= 0 then
      os.execute(string.format('cat %', logfile))
   end
   assert.same(0, ret)
   
   return outfile
end


describe('Test flare-format-annot.lua:', function()

test('Page:getAnnotText()',
     function()
        local pdf_fn = createTestFile(
           'text',
           '\\fbox{\\includegraphics[scale=0.5]{pdf/text-01.pdf}}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local page_objnum = p:getPageObjNum(pagenum)

        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]
        
        assert.same('Annot', annot.Type)
        assert.same('Text', annot.Subtype)
        assert.same('annot-1', annot.NM)
        assert.same('test', annot.Contents)
        assert.same(28, annot.F)
        assert.same('D:20210427131639+02\'00', annot.M)
        assert.same('D:20210401000000', annot.CreationDate)
        assert.same('foo', annot.T)
        assert.same(true, annot.Open)
        assert.same('Help', annot.Name)
        assert.near(0.7, annot.CA, 0.01)
        assert.same(p:getPageObjNum(1), luatex.getreference(annot, 'P'))
        assert.same({0, 0, 1.5}, p:getArray(annot, 'Border'))
        assert.same({0, 1, 1}, p:getArray(annot, 'C'))
end)


test('Page:getAnnotFreeText()',
     function()
        local pdf_fn = createTestFile(
           'freetext',
           '\\fbox{\\includegraphics[scale=0.5]{pdf/freetext-01.pdf}}')

        local d = Doc:new()
        local p = Page:new(d)
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', 1)
        p:openFile()

        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]

        assert.same('Annot', annot.Type)
        assert.same('FreeText', annot.Subtype)
        assert.nearly_same(
           {100, 100, 0, 0},
           p:getAnnotFreeText_RD(annot, 'RD'), 0.1)
        assert.same('this is just a test', annot.Contents)
        assert.same('0 0 1 rg', annot.DA)
        assert.same(1, annot.Q)
        assert.nearly_same(
           {190.14, 494.74, 240.14, 607.24, 290.14, 607.24},
           p:getCoordinatesArray(annot, 'CL'), 0.1)
        assert.same('FreeTextCallout', annot.IT)
        assert.same(2, annot.BS.W)
        assert.same('D', annot.BS.S)
        assert.same({6, 3}, p:getArray(annot.BS, 'D'))
        assert.same('S', annot.BE.S)
        assert.same(1, annot.BE.I)

        assert.nearly_same({0.6}, {0.61})
end)


test('Page:getAnnotSquiggly()',
     function()
        local pdf_fn = createTestFile(
           'squiggly',
           '\\fbox{\\includegraphics[scale=0.5]{pdf/squiggly-01.pdf}}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local page_objnum = p:getPageObjNum(pagenum)

        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]
        
        assert.same('Annot', annot.Type)
        assert.same('Squiggly', annot.Subtype)
        assert.same('annot-1', annot.NM)
        assert.same('contents', annot.Contents)
        assert.same('text', annot.T)
        assert.same(4, annot.F)
        assert.same('D:202105010000+02\'00', annot.M)
        assert.same(1, annot.CA)
        assert.nearly_same(
           { 347.19, 629.42, 374.51, 629.42, 347.19, 622.59,
             374.51, 622.59, 202.69, 623.66, 245.10, 623.66,
             202.69, 616.47, 245.10, 616.47 },
           p:getCoordinatesArray(annot, 'QuadPoints'))
end)


test('Page:getAnnotUnderline()',
     function()
        local pdf_fn = createTestFile(
           'underline',
           '\\includegraphics[scale=0.5]{pdf/underline-01.pdf}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local page_objnum = p:getPageObjNum(pagenum)

        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]
        
        assert.same('Annot', annot.Type)
        assert.same('Underline', annot.Subtype)
        assert.same('annot-1', annot.NM)
        assert.same('contents', annot.Contents)
        assert.same('text', annot.T)
        assert.same(4, annot.F)
        assert.same('D:202105010000+02\'00', annot.M)
        assert.same(1, annot.CA)
        assert.nearly_same(
           {346.79, 629.81, 374.11, 629.81, 346.79, 622.98,
            374.11, 622.98, 202.29, 624.06, 244.71, 624.06,
            202.29, 616.87, 244.71, 616.87 },
           p:getCoordinatesArray(annot, 'QuadPoints'))
end)


test('Page:getAnnotStrikeOut()',
     function()
        local pdf_fn = createTestFile(
           'strikeout',
           '\\includegraphics[scale=0.5]{pdf/strikeout-01.pdf}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local page_objnum = p:getPageObjNum(pagenum)

        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]
        
        assert.same('Annot', annot.Type)
        assert.same('StrikeOut', annot.Subtype)
        assert.same('annot-1', annot.NM)
        assert.same('contents', annot.Contents)
        assert.same('text', annot.T)
        assert.same(4, annot.F)
        assert.same('D:202105010000+02\'00', annot.M)
        assert.same(1, annot.CA)
        assert.nearly_same(
           {346.79, 629.81, 374.11, 629.81, 346.79, 622.98,
            374.11, 622.98, 202.29, 624.06, 244.71, 624.06,
            202.29, 616.87, 244.71, 616.87 },
           p:getCoordinatesArray(annot, 'QuadPoints'))
end)


test('Page:getAnnotLine()',
     function()
        local pdf_fn = createTestFile(
           'line',
           '\\includegraphics[scale=0.5]{pdf/line-01.pdf}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local page_objnum = p:getPageObjNum(pagenum)

        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]
        
        assert.same('Annot', annot.Type)
        assert.same('Line', annot.Subtype)
        assert.same('annot-1', annot.NM)
        assert.same('123 m', annot.Contents)
        assert.same('text', annot.T)
        assert.same(4, annot.F)
        assert.same('D:202105010000+02\'00', annot.M)
        assert.same(1, annot.CA)

        assert.nearly_same(
           {372.95, 650.28, 202.62, 582.72},
           p:getCoordinatesArray(annot, 'L'))
        assert.same({'/OpenArrow', '/OpenArrow'}, p:getArray(annot, 'LE'))
        assert.same(25, annot.LL)
        assert.same(10, annot.LLE)
        assert.same(3, annot.LLO)
        assert.same('Top', annot.CP)
        assert.same(true, annot.Cap)
        assert.same({10, 5}, p:getArray(annot, 'CO'))
end)


end) -- describe