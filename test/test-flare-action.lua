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


describe('Testing flare-action.lua:', function()

test('Page:getAction()',
     function()
        local p = Page:new(Doc:new())

        -- GoTo action
        p:setGinKV('filename', 'pdf/link-02.pdf')
        local annots = pdfe.open('pdf/link-02.pdf').Pages[1].Annots
        local action = annots[1].A
        assert.same(
           { S = '/GoTo', D = '(pdf/link-02.pdf-destOne)'},
           p:getAction(action))
end)


test('Page:getAction_Goto()',
     function()
        local p = Page:new(Doc:new())
        p:setGinKV('filename', 'pdf/link-02.pdf')
        local annots = pdfe.open('pdf/link-02.pdf').Pages[1].Annots

        local action = annots[1].A
        assert.same(
           { S = '/GoTo', D = '(pdf/link-02.pdf-destOne)'},
           p:getAction_Goto(action))

        local action = annots[7].A
        assert.same(
           { S = '/GoTo', D = {'null', '/Fit'}},
           p:getAction_Goto(action))
end)


test('Page:getAction_Goto_NamedDest()',
     function()
        local p = Page:new(Doc:new())

        p:setGinKV('filename', 'aaa.pdf')
        assert.same(
           { S = '/GoTo', D = '(aaa.pdf-foo)'},
           p:getAction_Goto_NamedDest('foo'))

        p:setFlareKV(2, 'all', 'linkPrefix', nil, '111-')
        assert.same(
           { S = '/GoTo', D = '(aaa.pdf-foo)'},
           p:getAction_Goto_NamedDest('foo'))
        p.page = 2
        assert.same(
           { S = '/GoTo', D = '(111-foo)'},
           p:getAction_Goto_NamedDest('foo'))

        p:setFlareKV('all', 'all', 'linkPrefix', nil, '222-')
        p.page = 1
        assert.same(
           { S = '/GoTo', D = '(222-foo)'},
           p:getAction_Goto_NamedDest('foo'))
        p.page = 2
        assert.same(
           { S = '/GoTo', D = '(111-foo)'},
           p:getAction_Goto_NamedDest('foo'))

end)


test('Page:getAction_Goto_DirectDest()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        local annots = pdfe.open('pdf/link-02.pdf').Pages[1].Annots
        -- /Fit
        local dest = annots[7].A.D
        assert.same({ S = '/GoTo', D = {'null', '/Fit'}},
                        p:getAction_Goto_DirectDest(dest))
        -- /XYZ
        local dest = annots[8].A.D
        assert.nearly_same(
           { S = '/GoTo',
             D = {'null', '/XYZ', 124.802, 718.084, 2.0}},
           p:getAction_Goto_DirectDest(dest))
        -- /XYZ
        local dest = annots[9].A.D
        assert.nearly_same(
           { S = '/GoTo',
             D = {'null', '/XYZ', 124.802, 718.084, 4.0}},
           p:getAction_Goto_DirectDest(dest))
        -- /FitH
        local dest = annots[10].A.D
        assert.nearly_same(
           { S = '/GoTo',
             D = {'null', '/FitH', 718.084}},
           p:getAction_Goto_DirectDest(dest))
        -- /FitV
        local dest = annots[11].A.D
        assert.nearly_same(
           { S = '/GoTo',
             D = {'null', '/FitV', 124.802}},
           p:getAction_Goto_DirectDest(dest))
        -- /FitR
        local dest = annots[12].A.D
        assert.nearly_same(
           { S = '/GoTo',
             D = {'null', '/FitR', 124.802, 495.085, 324.802, 595.085}},
           p:getAction_Goto_DirectDest(dest))
end)


test('Page:makeRef()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        assert.same('null', p:makeRef())
        assert.same('15 0 R', p:makeRef(15))
end)


test('Page:getRefPageObjNew()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        assert.same('null',
                    p:getRefPageObjNew(15))

        p:writeToCache('page_obj_old', 15)
        p:writeToCache('page_obj_new', 9)
        d.cacheOld = d.cacheNew
        assert.same('9 0 R',
                    p:getRefPageObjNew(15))
end)


test('Page:getAction_Goto_XYZ_DirectDest()',
     function()
        -- see test `Page:getAction_Goto_DirectDest()`
end)

test('Page:getAction_Goto_Fit_DirectDest()',
     function()
        -- see test `Page:getAction_Goto_DirectDest()`
end)


test('Page:getAction_Goto_FitH_DirectDest()',
     function()
        -- see test `Page:getAction_Goto_DirectDest()`
end)


test('Page:getAction_Goto_FitV_DirectDest()',
     function()
        -- see test `Page:getAction_Goto_DirectDest()`
end)


test('Page:getAction_Goto_FitR_DirectDest()',
     function()
        -- see test `Page:getAction_Goto_DirectDest()`
end)


end)
