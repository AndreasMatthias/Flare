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


describe('Testing flare-luatex.lua:', function()
            
test('Luatex:getreference()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        assert.same(3,
                        luatex.getreference(pageDict.TestArrayWithRef, 1))
        assert.same(4,
                        luatex.getreference(pageDict.TestArrayWithRef, 2))
        assert.same(3,
                        luatex.getreference(pageDict.TestDictionaryWithRef, 'AAA'))
        assert.same(4,
                        luatex.getreference(pageDict.TestDictionaryWithRef, 'BBB'))
end)


end) -- describe