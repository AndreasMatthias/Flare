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
pkg = require('flare-pkg')
pp = pkg.pp

stringio = require('pl.stringio')
nt = require('nodetree')


describe('Testing flare-page.lua:', function()

test('Page:new()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        assert.equal(d, p.doc)
        assert.same({}, p.GinKV)
        assert.same({}, p.FlareKV)
        assert.same(1, d.pictureCounter)
        assert.same({a=1, b=0, c=0, d=1, e=0, f=0}, p.ctm)
        local p = Page:new(d)
        assert.same(2, d.pictureCounter)
end)

            
test('Page:openFile()',
     function()
        local p = Page:new(Doc:new())
        local func = function() p:openFile() end

        -- Do not user p:setGinKV() here, because `filename` is
        -- set only once.
        p.GinKV.filename = 'example-image.pdf' -- image from mwe.sty
        assert.has_no.errors(func)

        p.GinKV.filename = 'thisFileDoesNotExist.pdf'
        assert.has_error(
           func,
           "\nModule Flare Error: File 'thisFileDoesNotExist.pdf' " ..
           "not found on input line 5\n")

        p.GinKV.filename = 'pdf/encrypted.pdf'
        assert.has_error(
           func,
           '\nModule Flare Error: PDF is password ' ..
           'protected on input line 5\n')

        p.userpassword = 'foobar'
        assert.has_no.error(func)
end)


test('Page:findFile()',
     function()
        local p = Page:new(Doc:new())

        p.GinKV.filename = 'example-image.pdf' -- from mwe.sty
        local filename = p:findFile()
        assert.is_not_nil(
           filename:find('tex/latex/mwe/example%-image.pdf$'))

        p.GinKV.filename = 'thisFileDoesNotExist.pdf'
        assert.has_error(function()
              p:findFile()
        end)
end)


test('Page:applyCTM()',
     function()
        local p = Page:new(Doc:new())
        local ctm = { a = 1, b = 2, c = 3, d = 4, e = 5, f = 6 }
        local xn, yn = p:applyCTM(ctm, 1, 2)
        assert.same(12, xn)
        assert.same(16, yn)
end)


test('Page:rect2tab()',
     function()
        local p = Page:new(Doc:new())

        assert.same(
           p:rect2tab({100, 200, 300, 400}),
           {llx = 100, lly = 200, urx = 300, ury = 400})

        local pdf = pdfe.open('pdf/circle-01.pdf')
        local annot = pdfe.getpage(pdf, 1).Annots[1]
        assert.same(
           p:rect2tab(annot.Rect),
           {llx = 100, lly = 600, urx = 300, ury = 700})
end)


test('Page:getMediaBox()',
     function()
        local p = Page:new(Doc:new())
        p.GinKV.filename = 'pdf/circle-01.pdf'
        p.GinKV.page = 1
        p:openFile()
        local mb = p:getMediaBox()
        assert.near(0, mb.llx, 0.001)
        assert.near(0, mb.lly, 0.001)
        assert.near(595.276, mb.urx, 0.001)
        assert.near(841.89, mb.ury, 0.001)
end)


test('Page:trim()',
     function()
        local p = Page:new(Doc:new())
        assert.same(nil, p:trim())
        assert.same(1, p:trim(1))
        assert.same({}, p:trim({}))
        assert.same('', p:trim(''))
        assert.same('foo', p:trim('foo'))
        assert.same('foo', p:trim(' foo '))
        assert.same('foo', p:trim('  foo  '))
        assert.same('foo bar', p:trim(' foo bar '))
        assert.same('foo bar', p:trim('  foo bar  '))
end)

test('Page:sp2bp()',
     function()
        local p = Page:new(Doc:new())
        assert.near(p:sp2bp(100000), 1.520178,  0.000001)
end)


test('Page:bp2sp()',
     function()
        local p = Page:new(Doc:new())
        assert.near(p:bp2sp(1), 65781.76, 0.0000001)
end)


test('Page:cacheData()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        p:setGinKV('filename', 'pdf/link-02.pdf')
        p:setGinKV('page', 1)
        p:openFile()
        p:cacheData()
end)


test('Page:writeToCache()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        d.pictureCounter = 3
        
        p:writeToCache('foo', 123)
        assert.same(123,
                        d.cacheNew[3]['foo'])
        assert.True(d.dirtyCache)

        d.dirtyCache = false
        d.cacheOld = d.cacheNew
        p:writeToCache('foo', 123)
        assert.same(123,
                        d.cacheNew[3]['foo'])
        assert.False(d.dirtyCache)
end)


test('Page:readFromCache()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        d.pictureCounter = 3
        d.cacheOld[3] = {}
        d.cacheOld[3]['foo'] = 123

        assert.same(123,
                        p:readFromCache('foo'))
        assert.same(nil,
                        p:readFromCache('bar'))

        d.pictureCounter = 4
        assert.same(nil,
                        p:readFromCache('foo'))
end)


test('Page:readFromCacheWithPageObj()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        d.cacheOld[1] = {}
        d.cacheOld[2] = {}
        d.cacheOld[3] = {}
        d.cacheOld[3]['page_obj_old'] = 55
        d.cacheOld[3]['foo'] = 123

        assert.same(123,
                        p:readFromCacheWithPageObj('foo', 55))
        assert.same(nil,
                        p:readFromCacheWithPageObj('foo', 33))
end)


test('Page:writeToCache_AnnotObjOld()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        d.pictureCounter = 2
        p.annotId = 3
        p:writeToCache_AnnotObjOld(33)
        assert.same(33, d.cacheNew[2]['annots'][3]['annot_obj_old'])

        d.cacheOld = d.cacheNew
        p:writeToCache_AnnotObjOld(33)
        assert.False(d.dirtyCache)
end)


test('Page:writeToCache_AnnotObjNew()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        d.pictureCounter = 2
        p.annotId = 3
        p:writeToCache_AnnotObjNew(33)
        assert.same(33, d.cacheNew[2]['annots'][3]['annot_obj_new'])

        d.cacheOld = d.cacheNew
        p:writeToCache_AnnotObjNew(33)
        assert.True(d.dirtyCache)
end)


test('Page:findFromCache_AnnotObjNew()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        d.pictureCounter = 1
        p.annotId = 1
        p:writeToCache_AnnotObjOld(11)
        p:writeToCache_AnnotObjNew(22)
        p.annotId = 2
        p:writeToCache_AnnotObjOld(33)
        p:writeToCache_AnnotObjNew(44)
        d.cacheOld = d.cacheNew
        assert.same(22, p:findFromCache_AnnotObjNew(11))
        assert.same(44, p:findFromCache_AnnotObjNew(33))
end)


test('Page:makeCTM()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        assert.same(
           {a=1, b=2, c=3, d=4, e=5, f=6},
           p:makeCTM(1, 2, 3, 4, 5, 6))
end)


test('Page:getCTM()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        assert.same({a=1, b=0, c=0, d=1, e=0, f=0}, p:getCTM())
        p:setGinKV('scale', 5)
        assert.same({a=5, b=0, c=0, d=5, e=0, f=0}, p:getCTM())
end)


end) -- describe
