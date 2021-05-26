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

require('busted.runner')()
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


describe('Testing flare-annot.lua:', function()

test('Page:getAnnots()',            
     function()
        local d = Doc:new()
        local p = Page:new(d)
        p:setGinKV('filename', 'pdf/circle-01.pdf')
        p:setGinKV('page', 1)
        p:openFile()
        local annots = p:getAnnots()
        assert.same(1, #annots)
        local pt, pv, pd = pdfe.getfromarray(annots, 1)
        assert.same(10, pt)
        assert.same('pdfe.reference', pdfe.type(pv))
        assert.same(6, pd)
end)

end) --describe


describe('Testing flare-annot.lua:', function()

before_each(function()
      orig_node_write = _G.node.write
      _G.flare_box = nil
      _G.node.write = function(val) _G.flare_box = val end

      orig_io_write = _G.io.write
      _G.flare_stream = stringio.create()
      _G.io.write = function(val) _G.flare_stream:write(val) end
end)

after_each(function()
      _G.node.write = orig_node_write
      _G.io.write = orig_io_write
end)

local function sanitize_node_str(str)
   str = str:gsub(' objnum: %d+,', '')
   str = str:gsub(', data: .*', '')
   return str
end


test('Page:insertAnnot()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        p:setGinKV('filename', 'pdf/circle-01.pdf')
        p:setGinKV('page', 1)
        p:openFile()
        local annot = pdfe.getpage(p.pdf, 1).Annots[1]
        p.annotId = 1
        p:insertAnnot(annot)

        local nt = require('nodetree')
        nt.print(_G.flare_box,
                 {verbosity=0, color='no', unit='bp', decimalplaces=0})

        assert.same('\n' ..
                    '└─VLIST \n' ..
                    '  ╚═head:\n' ..
                    '    ├─GLUE width: -600bp\n' ..
                    '    └─HLIST \n' ..
                    '      ╚═head:\n' ..
                    '        ├─GLUE width: 100bp\n' ..
                    '        └─WHATSIT subtype: pdf_annot, width: 200bp, height: 100bp',
                    sanitize_node_str(_G.flare_stream:value()))
end)


test('Page:copyAnnots()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        p:setGinKV('filename', 'pdf/circle-01.pdf')
        p:setGinKV('page', 1)
        p:openFile()
        p:copyAnnots()

        local nt = require('nodetree')
        nt.print(_G.flare_box,
                 {verbosity=0, color='no', unit='bp', decimalplaces=0})

        assert.same('\n' ..
                    '└─VLIST \n' ..
                    '  ╚═head:\n' ..
                    '    ├─GLUE width: -600bp\n' ..
                    '    └─HLIST \n' ..
                    '      ╚═head:\n' ..
                    '        ├─GLUE width: 100bp\n' ..
                    '        └─WHATSIT subtype: pdf_annot, width: 200bp, height: 100bp',
                    sanitize_node_str(_G.flare_stream:value()))
        
end)

end) -- describe
