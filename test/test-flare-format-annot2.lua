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


describe('Test flare-format-annot.lua:', function()


test('Page:getAnnotText()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        p:setGinKV('filename', 'pdf/text-01.pdf')
        p:setGinKV('page', 1)
        p:openFile()
        local annot = p:getAnnots()[1]
        local t = p:getAnnotText(annot)
        assert.same('/Text', t.Subtype)
        assert.same(true, t.Open)
        assert.same('/Help', t.Name)

        
        local p = Page:new(d)
        p:setGinKV('filename', 'pdf/text-02.pdf')
        p:setGinKV('page', 1)
        p:openFile()
        local annots = p:getAnnots()
        local t = p:getAnnotText(annots[1])
        assert.same('/Text', t.Subtype)
        local t = p:getAnnotText(annots[2])
        assert.same('/Text', t.Subtype)
        assert.same('(Review)', t.StateModel)
        assert.same('(Accepted)', t.State)
end)


test('Page:formatIRT()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        p:setGinKV('filename', 'pdf/text-99.pdf')
        p:setGinKV('page', 1)
        p:openFile()
        local annot = p:getAnnots()[1]

        p.annotId = 1
        p:writeToCache_AnnotObjOld(11)
        p:writeToCache_AnnotObjNew(22)

        p.annotId = 2
        p:writeToCache_AnnotObjOld(33)
        p:writeToCache_AnnotObjNew(44)

        d.cacheOld = d.cacheNew
        p.annotId = nil
        assert.same(nil, p:formatIRT(annot, 99))
        assert.same('22 0 R', p:formatIRT(annot, 11))
        assert.same('44 0 R', p:formatIRT(annot, 33))
end)

            
test('Page:getAnnotCircle()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        p:setGinKV('filename', 'pdf/circle-01.pdf')
        p:setGinKV('page', 1)
        p:openFile()
        local annot = p:getAnnots()[1]
        local t = p:getAnnotCircle(annot)
        assert.same('/Circle', t.Subtype)
        assert.same({0.9, 0.9, 0.1}, t.IC)

        -- circle with BS dict
        local p = Page:new(d)
        p:setGinKV('filename', 'pdf/circle-03.pdf')
        p:setGinKV('page', 1)
        p:openFile()
        local annot = p:getAnnots()[1]
        local t = p:getAnnotCircle(annot)
        assert.same('/Circle', t.Subtype)
        assert.same({0.9, 0.9, 0.1}, t.IC)
        assert.same({Type = '/Border', W = 8, S = '/D', D = {10, 4}}, t.BS)

        -- circle with BS and BE dict
        local p = Page:new(d)
        p:setGinKV('filename', 'pdf/circle-04.pdf')
        p:setGinKV('page', 1)
        p:openFile()
        local annot = p:getAnnots()[1]
        local t = p:getAnnotCircle(annot)
        assert.same('/Circle', t.Subtype)
        assert.same({0.9, 0.9, 0.1}, t.IC)
        assert.same({Type = '/Border', W = 8, S = '/D', D = {10, 4}}, t.BS)
        assert.same({S = '/C', I = 1}, t.BE)
end)


test('Page:getAnnotSquare()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        p:setGinKV('filename', 'pdf/square-01.pdf')
        p:setGinKV('page', 1)
        p:openFile()
        local annot = p:getAnnots()[1]
        local t = p:getAnnotCircle(annot)
        assert.same('/Square', t.Subtype)
        assert.same({0.9, 0.9, 0.1}, t.IC)
end)
     

test('Page:getAnnotHighlight()',
     function()
        local p = Page:new(Doc:new())
        p:setGinKV('filename', 'pdf/highlight-01.pdf')
        p:setGinKV('page', 1)
        p:openFile()
        local annot = p:getAnnots()[1]
        local t = p:getAnnotHighlight(annot)

        assert.same('/Highlight', t.Subtype)
        assert.nearly_same(
           {414.10496, 669.3421, 468.74415, 669.3421, 414.10496,
            655.68246, 468.74415, 655.68246, 125.09428, 657.83859,
            209.92826, 657.83859, 125.09428, 643.4599, 209.92826,
            643.4599},
           t.QuadPoints)

        assert.same('(D:20210429202216+02\'00)', t.M)
        assert.same('<FEFF0061006E00640072006500610073>', t.T)
        assert.same('<FEFF>', t.Contents)
        assert.same('(okular-{1c0dc025-7938-4ccf-8aea-bedc2827469d})', t.NM)
        assert.same(4, t.F)
        assert.nearly_same({0.96078, 0.47451, 0}, t.C)
        assert.same(1, t.CA)
        assert.same('[ 0 0 1 ]', t.Border)
end)


function createTestFile(filename, body)
   infile = 'tmp_' .. filename .. '.tex'
   outfile = 'tmp_' .. filename .. '.pdf'

   local fh = io.open('template.tex', 'r')
   local content = fh:read('a')
   content = content:gsub('<body>', body)
   fh:close()

   local fh =  io.open(infile, 'w')
   fh:write(content)
   fh:close()

   local cmd = string.format('lualatex %s > /dev/null', infile)
   os.execute(cmd)
   return outfile
end


end) -- describe
