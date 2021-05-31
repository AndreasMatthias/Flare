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


describe('Testing flare-dest.lua:', function()


test('Page:saveDests()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        p:setGinKV('filename', 'pdf/link-03.pdf')
        p:openFile()
        p:saveDests()
        assert.same(
           {
              ["pdf/link-03.pdf"] = {
                 [11] = {
                    {
                       data = {124.802, 716.092},
                       name = "section.1",
                       type = "XYZ",
                    }
                 },
                 [23] = {
                    {
                       data = {124.802, 716.092},
                       name = "section.2",
                       type = "XYZ",
                    }
                 }
              }
           },
           d.destBucket)
end)


test('Page:readDestNameTree()',
     function()
        local p = Page:new(Doc:new())
        local doc = pdfe.open('pdf/link-02.pdf')
        local names = pdfe.getcatalog(doc).Names.Dests

        assert.nearly_same(
           {
              {
                 name = 'Doc-Start',
                 pageobj = 9,
                 type = 'XYZ',
                 data = {124.802, 716.092},
              },
              {
                 name = 'destFive',
                 pageobj = 44,
                 type = 'FitV',
                 data = {124.802},
              },
              {
                 name = 'destFour',
                 pageobj = 44,
                 type = 'FitH',
                 data = {718.084},
              },
              {
                 name = 'destOne',
                 pageobj = 44,
                 type = 'Fit',
                 data = {},
              },
              {
                 name = 'destSix',
                 pageobj = 44,
                 type = 'FitR',
                 data = {124.802, 495.085, 324.802, 595.085},
              },
              {
                 name = 'destThree',
                 pageobj = 44,
                 type = 'XYZ',
                 data = {124.802, 718.084, 4.0},
              },
              {
                 name = 'destTwo',
                 pageobj = 44,
                 type = 'XYZ',
                 data = {124.802, 718.084, 2.0},
              },
              {
                 name = 'page.1',
                 pageobj = 9,
                 type = 'XYZ',
                 data = {123.802, 753.953},
              },
              {
                 name = 'page.2',
                 pageobj = 44,
                 type = 'XYZ',
                 data = {124.798, 753.953},
              },
              {
                 name = 'page.3',
                 pageobj = 48,
                 type = 'XYZ',
                 data = {123.802, 753.953},
              }
           },
           p:readDestNameTree(names))
end)


test('Page:getDestArray()',
     function()
        local p = Page:new(Doc:new())
        local doc = pdfe.open('pdf/link-02.pdf')
        local action = pdfe.getpage(doc, 1).Annots[8].A

        assert.equal(
           string.format('%s', action.D),
           string.format('%s', p:getDestArray(action)))

        assert.equal(
           string.format('%s', action.D),
           string.format('%s', p:getDestArray(action.D)))

end)


test('Page:splitDestArray()',
     function()
        local p = Page:new(Doc:new())
        local doc = pdfe.open('pdf/link-02.pdf')

        local dest = pdfe.getpage(doc, 1).Annots[7].A.D
        assert.nearly_same(
           {
              pageobj = 44,
              type = 'Fit',
              data = {}
           },
           p:splitDestArray(dest))

        local dest = pdfe.getpage(doc, 1).Annots[8].A.D
        assert.nearly_same(
           {
              pageobj = 44,
              type = 'XYZ',
              data = {124.802, 718.084, 2.0}
           },
           p:splitDestArray(dest))
end)


test('Page:makeDestTable()',
     function()
        local p = Page:new(Doc:new())
        p:setGinKV('filename', 'pdf/link-02.pdf')
        p:openFile()
        
        assert.nearly_same(
           {
              [9] = {
                 {
                    name = 'Doc-Start',
                    type = 'XYZ',
                    data = {124.802, 716.092},
                 },
                 {
                    name = 'page.1',
                    type = 'XYZ',
                    data = {123.802, 753.953},
                 },
              },
              [44] = {
                 {
                    name = 'destFive',
                    type = 'FitV',
                    data = {124.802},
                 },
                 {
                    name = 'destFour',
                    type = 'FitH',
                    data = {718.084},
                 },
                 {
                    name = 'destOne',
                    type = 'Fit',
                    data = {},
                 },
                 {
                    name = 'destSix',
                    type = 'FitR',
                    data = {124.802, 495.085, 324.802, 595.085},
                 },
                 {
                    name = 'destThree',
                    type = 'XYZ',
                    data = {124.802, 718.084, 4.0},
                 },
                 {
                    name = 'destTwo',
                    type = 'XYZ',
                    data = {124.802, 718.084, 2.0},
                 },
                 {
                    name = 'page.2',
                    type = 'XYZ',
                    data = {124.798, 753.953},
                 },
              },
              [48] = {
                 {
                    name = 'page.3',
                    type = 'XYZ',
                    data = {123.802, 753.953},
                 }
              },
           },
           p:makeDestTable(names))
end)


test('Page:getDestLinkPrefix()',
     function()
        -- see test `Page:getDestPrefix()`
        -- see test `Page:getLinkPrefix()`
end)


test('Page:getDestPrefix()',
     function()
        local p = Page:new(Doc:new())
        p:setGinKV('filename', 'aaa.pdf')
        assert.same('aaa.pdf-', p:getDestPrefix())

        p:setFlareKV('all', 'all', 'destPrefix', nil, 'foo')
        p:setFlareKV(2, 3, 'destPrefix', nil, 'bar')
        p.annotId = 1
        assert.same('foo', p:getDestPrefix())

        p.page = 2
        p.annotId = 3
        assert.same('bar', p:getDestPrefix())

end)


test('Page:getLinkPrefix()',
     function()
        local p = Page:new(Doc:new())
        p:setGinKV('filename', 'aaa.pdf')
        assert.same('aaa.pdf-', p:getLinkPrefix())

        p:setFlareKV('all', 'all', 'linkPrefix', nil, 'foo')
        p:setFlareKV(2, 3, 'linkPrefix', nil, 'bar')
        p.annotId = 1
        assert.same('foo', p:getLinkPrefix())
        p.page = 2
        p.annotId = 3
        assert.same('bar', p:getLinkPrefix())
end)


test('Page:sanitizeString()',
     function()
        local p = Page:new(Doc:new())
        assert.same('', p:sanitizeString(''))
        assert.same('foo', p:sanitizeString('foo'))
        assert.same('\\(foo\\)', p:sanitizeString('(foo)'))
end)


test('Page:getPageObjNum()',
     function()
        -- simple page tree
        local p = Page:new(Doc:new())
        p:setGinKV('filename', 'pdf/link-02.pdf')
        p:openFile()
        assert.same(9, p:getPageObjNum(1))
        assert.same(44, p:getPageObjNum(2))
        assert.same(48, p:getPageObjNum(3))

        -- more sophisticated page tree
        local p = Page:new(Doc:new())
        p:setGinKV('filename', 'pdf/pagetree.pdf')
        p:openFile()
        assert.same(3, p:getPageObjNum(1))
        assert.same(7, p:getPageObjNum(2))
        assert.same(8, p:getPageObjNum(3))
        assert.same(6, p:getPageObjNum(4))
end)


test('Page:isPage()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        
        local pdf = pdfe.open('pdf/pagetree.pdf')
        local page = pdfe.getcatalog(pdf).Pages.Kids[1]
        assert.True(p:isPage(page))

        local treenode = pdfe.getcatalog(pdf).Pages.Kids[2]
        assert.False(p:isPage(treenode))
end)


test('Page:makeDestNode_XYZ()',
     function()
        local p = Page:new(Doc:new())
        p:setGinKV('filename', 'pdf/link-02.pdf')
        p:openFile()
        local dest = { name = 'page.2',
                       type = 'XYZ',
                       data = {111, 222, 3.0}}
        local ctm = p.IdentityCTM
        local whatsit, h, v = p:makeDestNode_XYZ(dest, ctm)
        
        assert.same(whatsit.id, node.id('whatsit'))
        assert.same(whatsit.subtype, node.subtype('pdf_dest'))
        assert.same(whatsit.named_id, 1)
        assert.same(whatsit.dest_id, 'pdf/link-02.pdf-page.2')
        assert.same(whatsit.dest_type, luatex.pdfeDestType.xyz)
        assert.same(whatsit.xyz_zoom, 3000)
        assert.same(h, 111)
        assert.same(v, 222)
end)


test('Page:makeDestNode_Fit()',
     function()
        local p = Page:new(Doc:new())
        p:setGinKV('filename', 'pdf/link-02.pdf')
        p:openFile()
        local dest = { name = 'page.2',
                       type = 'Fit'}
        local ctm = p.IdentityCTM
        local whatsit, h, v = p:makeDestNode_Fit(dest, ctm)
        
        assert.same(whatsit.id, node.id('whatsit'))
        assert.same(whatsit.subtype, node.subtype('pdf_dest'))
        assert.same(whatsit.named_id, 1)
        assert.same(whatsit.dest_id, 'pdf/link-02.pdf-page.2')
        assert.same(whatsit.dest_type, luatex.pdfeDestType.fit)
        assert.same(h, 0)
        assert.same(v, 0)
end)


test('Page:makeDestNode_FitH()',
     function()
        local p = Page:new(Doc:new())
        p:setGinKV('filename', 'pdf/link-02.pdf')
        p:openFile()
        local dest = { name = 'page.2',
                       type = 'FitH',
                       data = {111}}
        local ctm = p.IdentityCTM
        local whatsit, h, v = p:makeDestNode_FitH(dest, ctm)
        
        assert.same(whatsit.id, node.id('whatsit'))
        assert.same(whatsit.subtype, node.subtype('pdf_dest'))
        assert.same(whatsit.named_id, 1)
        assert.same(whatsit.dest_id, 'pdf/link-02.pdf-page.2')
        assert.same(whatsit.dest_type, luatex.pdfeDestType.fith)
        assert.same(h, 0)
        assert.same(v, 111)
end)


test('Page:makeDestNode_FitV()',
     function()
        local p = Page:new(Doc:new())
        p:setGinKV('filename', 'pdf/link-02.pdf')
        p:openFile()
        local dest = { name = 'page.2',
                       type = 'FitV',
                       data = {111}}
        local ctm = p.IdentityCTM
        local whatsit, h, v = p:makeDestNode_FitV(dest, ctm)
        
        assert.same(whatsit.id, node.id('whatsit'))
        assert.same(whatsit.subtype, node.subtype('pdf_dest'))
        assert.same(whatsit.named_id, 1)
        assert.same(whatsit.dest_id, 'pdf/link-02.pdf-page.2')
        assert.same(whatsit.dest_type, luatex.pdfeDestType.fitv)
        assert.same(h, 111)
        assert.same(v, 0)
end)


test('Page:makeDestNode_FitR()',
     function()
        local p = Page:new(Doc:new())
        p:setGinKV('filename', 'pdf/link-02.pdf')
        p:openFile()
        local dest = { name = 'page.2',
                       type = 'FitR',
                       data = {111, 222, 333, 444}}
        local ctm = p.IdentityCTM
        local whatsit, h, v = p:makeDestNode_FitR(dest, ctm)
        
        assert.same(whatsit.id, node.id('whatsit'))
        assert.same(whatsit.subtype, node.subtype('pdf_dest'))
        assert.same(whatsit.named_id, 1)
        assert.same(whatsit.dest_id, 'pdf/link-02.pdf-page.2')
        assert.same(whatsit.dest_type, luatex.pdfeDestType.fitr)

        assert.same(h, 111)
        assert.same(v, 222)
        assert.near(whatsit.width, p:bp2sp(333-111), 1)
        assert.near(whatsit.height, p:bp2sp(444-222), 1)
        
end)


end) -- describe


describe('Testing flare-dest.lua:', function()

setup(function()
      orig_io_write = _G.io.write
      _G.flare_stream = stringio.create()
      _G.io.write = function(val) _G.flare_stream:write(val) end
end)

teardown(function()
      _G.flare_stream = nil
      _G.io.write = orig_io_write
end)
            
test('Page:pushTo()',
     function()
        local p = Page:new(Doc:new())
        local rule = node.new('rule', 'normal')
        rule.width = p:bp2sp(11)
        rule.depth = p:bp2sp(22)
        rule.height = p:bp2sp(33)
        local h, v = 100, 200
        local box = p:pushTo(rule, h, v)

        local nt = require('nodetree')
        nt.print(box, {verbosity=1, color='no', unit='bp'})
        
        assert.same('\n' ..
                    '└─VLIST \n' ..
                    '  ╚═head:\n' ..
                    '    ├─GLUE width: -200bp\n' ..
                    '    └─HLIST \n' ..
                    '      ╚═head:\n' ..
                    '        ├─GLUE width: 100bp\n' ..
                    '        └─RULE width: 11bp, depth: 22bp, height: 33bp\n' ..
                    '',
                    _G.flare_stream:value())
end)


end) -- describe


describe('Testing flare-dest.lua:', function()

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

test('Page:insertDestNode()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        p:setGinKV('filename', 'pdf/link-02.pdf')
        p:openFile()
        local dest = { name = 'page.2',
                       type = 'XYZ',
                       data = {111, 222, 3.0}}
        p:insertDestNode(dest, 1)

        local nt = require('nodetree')
        nt.print(_G.flare_box, {verbosity=1, color='no', unit='bp'})
        assert.same('\n' ..
                    '└─VLIST \n' ..
                    '  ╚═head:\n' ..
                    '    ├─GLUE width: -222bp\n' ..
                    '    └─HLIST \n' ..
                    '      ╚═head:\n' ..
                    '        ├─GLUE width: 111bp\n' ..
                    '        └─WHATSIT subtype: pdf_dest, named_id: 1, ' ..
                    'dest_id: pdf/link-02.pdf-page.2, xyz_zoom: 3000\n',
                    _G.flare_stream:value())
end)


test('Page:insertDestNodes()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        p:setGinKV('filename', 'pdf/link-03.pdf')
        p:setGinKV('page', 1)
        p:openFile()
        p:saveDests()
        p:insertDestNodes()

        local nt = require('nodetree')
        nt.print(_G.flare_box, {verbosity=1, color='no', unit='bp'})
        assert.same('\n' ..
                    '└─VLIST \n' ..
                    '  ╚═head:\n' ..
                    '    ├─GLUE width: -716.1bp\n' ..
                    '    └─HLIST \n' ..
                    '      ╚═head:\n' ..
                    '        ├─GLUE width: 124.8bp\n' ..
                    '        └─WHATSIT subtype: pdf_dest, named_id: 1, ' ..
                    'dest_id: pdf/link-03.pdf-section.1\n',
                    _G.flare_stream:value())
end)


test('Page:copyDests()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        p:setGinKV('filename', 'pdf/link-03.pdf')
        p:setGinKV('page', 1)
        p:openFile()
        p:copyDests()

        local nt = require('nodetree')
        nt.print(_G.flare_box, {verbosity=1, color='no', unit='bp'})
        assert.same('\n' ..
                    '└─VLIST \n' ..
                    '  ╚═head:\n' ..
                    '    ├─GLUE width: -716.1bp\n' ..
                    '    └─HLIST \n' ..
                    '      ╚═head:\n' ..
                    '        ├─GLUE width: 124.8bp\n' ..
                    '        └─WHATSIT subtype: pdf_dest, named_id: 1, ' ..
                    'dest_id: pdf/link-03.pdf-section.1\n',
                    _G.flare_stream:value())
end)


end) -- describe
