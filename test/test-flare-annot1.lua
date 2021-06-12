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
types = require('flare-types')
pkg = require('flare-pkg')
pp = pkg.pp

stringio = require('pl.stringio')
nt = require('nodetree')
require('helper')

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

end) -- describe


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


describe('Testing flare-annot.lua:', function()


test('Page:formatAnnotation()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        stub(pkg, 'warning')

        p:formatAnnotation({Subtype = 'DoesNotExist'})
        assert.stub(pkg.warning).was_called()

        -- TODO: further tests needed
end)


test('Page:getAnnotFunc()',
     function()
        local d = Doc:new()
        local p = Page:new(d)

        assert.same(Page.getAnnotCircle, p:getAnnotFunc({Subtype = 'Circle'}))
        assert.same(Page.getAnnotSquare, p:getAnnotFunc({Subtype = 'Square'}))
        assert.same(Page.getAnnotLine, p:getAnnotFunc({Subtype = 'Line'}))

        assert.same(nil, p:getAnnotFunc({Subtype = 'doesNotExist'}))
end)


test('Page:getAnnotCommonEntries()',
     function()
        local p = Page:new(Doc:new())
        p:setGinKV('filename', 'pdf/circle-01.pdf')
        p:setGinKV('page', 1)
        p:openFile()
        local annot = p:getAnnots()[1]
        local t = p:getAnnotCommonEntries(annot)
        assert.same('/Circle', t.Subtype)
        assert.same('<FEFF0074006500730074>', t.Contents)
        assert.same('(annot-1)', t.NM)
        assert.same('(D:20210101000000)', t.M)
        assert.same(28, t.F)
        -- AP
        -- AS
        assert.same('[ 0 0 3 ]', t.Border)
        assert.same({0, 0.9, 0.9}, t.C)
        -- StructParent
        -- OC
end)


-- test('Page:getAnnotMarkupEntries()',
--      function()
--         local p = Page:new(Doc:new())
--         p:setGinKV('filename', 'pdf/text-01.pdf')
--         p:setGinKV('page', 1)
--         p:openFile()
--         local annot = p:getAnnots()[1]
--         local t = p:getAnnotMarkupEntries(annot)

--         assert.same('(foo)', t.T)
--         -- Popup
--         assert.same('0.7', t.CA)
--         assert.same('(<body><p>foo<b>bar</b></p></body>)', t.RC)
--         assert.same('(D:20210401000000)', t.CreationDate)
--         assert.same(nil, t.IRT) -- is nil at first run
--         assert.same('(subject)', t.Subj)
--         assert.same('/R', t.RT)
--         assert.same('/Whatever', t.IT)
--         assert.same({Type = '/ExData',
--                          Subtype = '/Foo',
--                          AAA = '123',
--                          BBB = '(test)'
--                         }, t.ExData)
-- end)


test('Page:getP()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        assert.same('1 0 R', p:getP())
end)


test('Page:formatBorderDash()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        p.ctm = p:makeCTM(2, 0, 0, 2, 0, 0)
        local page, annotId = 1, 1
        p:setGinKV('page', page)
        p.annotId = annotId

        local pdf = pdfe.open('pdf/circle-02.pdf')
        local border = pdfe.getpage(pdf, 1).Annots[1].Border
        local dash = pdfe.getarray(border, 3)

        assert.same('[ 30 12 ]', p:formatBorderDash(dash, 3))
        assert.same('[ 20 8 ]', p:formatBorderDash(dash, true))
        assert.same('[ 10 4 ]', p:formatBorderDash(dash, false))

        p.FlareKV = {}
        p:setFlareKV(page, annotId, 'BorderDash', 'replace', '[ 1 2 ]')
        assert.same('[ 1 2 ]', p:formatBorderDash(dash, 2))

        p.FlareKV = {}
        p:setFlareKV(page, annotId, 'BorderDash', 'replace', '')
        assert.same('', p:formatBorderDash(dash, 2))

        p.FlareKV = {}
        p:setFlareKV(page, annotId, 'BorderDash', 'remove', true)
        assert.same('', p:formatBorderDash(dash, 2))

        p.FlareKV = {}
        p:setFlareKV(page, annotId, 'BorderDash', 'remove', false)
        assert.same('[ 20 8 ]', p:formatBorderDash(dash, 2))

        p.FlareKV = {}
        p:setFlareKV(page, annotId, 'BorderDash', 'scale', 3)
        assert.same('[ 30 12 ]', p:formatBorderDash(dash, 2))
end)


test('Page:formatBorder()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        p.ctm = p:makeCTM(2, 0, 0, 2, 0, 0)
        local page, annotId = 1, 1
        p:setGinKV('page', page)
        p.annotId = annotId

        local pdf = pdfe.open('pdf/circle-02.pdf')
        local annot = pdfe.getpage(pdf, 1).Annots[1]

        assert.same('[ 0 0 9 [ 30 12 ]]', p:formatBorder(annot, 3))
        assert.same('[ 0 0 6 [ 20 8 ]]', p:formatBorder(annot, true))
        assert.same('[ 0 0 3 [ 10 4 ]]', p:formatBorder(annot, false))

        p.FlareKV = {}
        p:setFlareKV(page, annotId, 'Border', 'replace', '[ 1 2 3 [ 4 5 ] ]')
        assert.same( '[ 1 2 3 [ 4 5 ] ]', p:formatBorder(annot, 2))

        p.FlareKV = {}
        p:setFlareKV(page, annotId, 'Border', 'replace', '')
        assert.same( '', p:formatBorder(annot, 2))

        p.FlareKV = {}
        p:setFlareKV(page, annotId, 'Border', 'remove', true)
        assert.same( '', p:formatBorder(annot, 2))

        p.FlareKV = {}
        p:setFlareKV(page, annotId, 'Border', 'remove', false)
        assert.same( '[ 0 0 6 [ 20 8 ]]', p:formatBorder(annot, 2))

        p.FlareKV = {}
        p:setFlareKV(page, annotId, 'Border', 'scale', 3)
        assert.same( '[ 0 0 9 [ 30 12 ]]', p:formatBorder(annot, 2))

        p.FlareKV = {}
        p:setFlareKV(page, annotId, 'Border', 'scale', 3)
        p:setFlareKV(page, annotId, 'BorderDash', 'remove', true)
        assert.same( '[ 0 0 9 ]', p:formatBorder(annot, 2))

        p.FlareKV = {}
        p:setFlareKV(page, annotId, 'Border', 'scale', 3)
        p:setFlareKV(page, annotId, 'BorderDash', 'scale', false)
        assert.same( '[ 0 0 9 [ 10 4 ]]', p:formatBorder(annot, 2))

        p.FlareKV = {}
        p:setFlareKV(page, annotId, 'Border', 'scale', 3)
        p:setFlareKV(page, annotId, 'BorderDash', 'scale', 2)
        assert.same( '[ 0 0 9 [ 20 8 ]]', p:formatBorder(annot, 2))
end)


test('Page:formatBorder_hlp()',
     function()
        -- see test `Page:formatBorder()`
end)


test('Page:appendTable()',
     function()
        local d = Doc:new()
        local p = Page:new(d)

        t1 = {}
        t2 = {}
        p:appendTable(t1, t2)
        assert.same({}, t1)
        assert.same({}, t2)

        t1 = {}
        t2 = {a=1, b=2}
        p:appendTable(t1, t2)
        assert.same({a=1, b=2}, t1)
        assert.same({a=1, b=2}, t2)


        t1 = {a=1, b=2}
        t2 = {c=3, d=4}
        p:appendTable(t1, t2)
        assert.same({a=1, b=2, c=3, d=4}, t1)
        assert.same({c=3, d=4}, t2)
end)


test('Page:formatTable()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        assert.same(
           nil,
           p:formatTable(nil))
        assert.same(
           '<< /bar xox /foo 123 >>',
           p:formatTable({ foo = 123, bar = 'xox'}))
        assert.same(
           '<< /bar xox /foo 123 >>',
           p:formatTable({ foo = 123, bar = 'xox'}, true))
        assert.same(
           '/bar xox /foo 123',
           p:formatTable({ foo = 123, bar = 'xox'}, false))
        assert.same(
           '<< /bar [ a b c ] /foo 123 >>',
           p:formatTable({ foo = 123, bar = types.pdfarray:new({'a', 'b', 'c'})}))
        assert.same(
           '<< /bar [ a b c ] /foo 123 >>',
           p:formatTable({ foo = 123, bar = types.pdfarray:new({'a', 'b', 'c'})}, true))
        assert.same(
           '/bar [ a b c ] /foo 123',
           p:formatTable({ foo = 123, bar = types.pdfarray:new({'a', 'b', 'c'})}, false))
        assert.same(
           '<< /bar << /a 1 /b 2 >> /foo 123 >>',
           p:formatTable({ foo = 123, bar = types.pdfdictionary:new({a=1, b=2})}))
        assert.same(
           '<< /bar << /a 1 /b 2 >> /foo 123 >>',
           p:formatTable({ foo = 123, bar = types.pdfdictionary:new({a=1, b=2})}, true))
        assert.same(
           '/bar << /a 1 /b 2 >> /foo 123',
           p:formatTable({ foo = 123, bar = types.pdfdictionary:new({a=1, b=2})}, false))
end)


test('Page:getCoordinatesArray()',
     function()
        local d = Doc:new()
        local p = Page:new(d)

        local pdf = pdfe.open('pdf/line-01.pdf')
        local annot = pdfe.getpage(pdf, 1).Annots[1]

        assert.nearly_same(
           {466.41007, 710.2714, 125.75146, 575.1489},
           p:getCoordinatesArray(annot, 'L'))

        p:writeToCache('ctm', p:makeCTM(2, 0, 0, 2, 0, 0))
        d.cacheOld = d.cacheNew
        assert.nearly_same(
           {2 * 466.41007, 2 * 710.2714, 2 * 125.75146, 2 * 575.1489},
           p:getCoordinatesArray(annot, 'L'))
end)


test('Page:getCoordinatesArrayArray()',
     function()
        local d = Doc:new()
        local p = Page:new(d)

        local pdf = pdfe.open('pdf/ink-01.pdf')
        local annot = pdfe.getpage(pdf, 1).Annots[1]

        assert.nearly_same(
           {{ 163.166, 685.651, 169.891, 696.257, 180.475,
              712.651, 188.343, 723.243, 196.026, 731.441, 203.856,
              737.486, 213.922, 742.275, 225.106, 744.568, 237.737,
              744.428, 252.063, 741.852, 263.748, 738.294, 272.970,
              734.072, 279.595, 729.250, 283.571, 723.868, 285.230,
              717.496, 284.609, 710.433, 281.697, 702.903, 276.820,
              695.767, 272.348, 690.176, 264.056, 680.772, 258.915,
              677.367, 253.189, 675.535, 245.132, 675.641, 235.208,
              678.168, 225.745, 682.500, 218.469, 687.847, 214.812,
              692.484, 213.362, 697.157, 214.162, 701.724, 217.193,
              706.108, 219.430, 708.131, 220.164, 708.322, 221.667,
              708.111, 223.161, 707.901, 223.931, 708.131 }},
           p:getCoordinatesArrayArray(annot, 'InkList'))

        p:writeToCache('ctm', p:makeCTM(2, 0, 0, 2, 0, 0))
        d.cacheOld = d.cacheNew
        assert.nearly_same(
           {{ 2*163.166, 2*685.651, 2*169.891, 2*696.257, 2*180.475,
              2*712.651, 2*188.343, 2*723.243, 2*196.026, 2*731.441,
              2*203.856, 2*737.486, 2*213.922, 2*742.275, 2*225.106,
              2*744.568, 2*237.737, 2*744.428, 2*252.063, 2*741.852,
              2*263.748, 2*738.294, 2*272.970, 2*734.072, 2*279.595,
              2*729.250, 2*283.571, 2*723.868, 2*285.230, 2*717.496,
              2*284.609, 2*710.433, 2*281.697, 2*702.903, 2*276.820,
              2*695.767, 2*272.348, 2*690.176, 2*264.056, 2*680.772,
              2*258.915, 2*677.367, 2*253.189, 2*675.535, 2*245.132,
              2*675.641, 2*235.208, 2*678.168, 2*225.745, 2*682.500,
              2*218.469, 2*687.847, 2*214.812, 2*692.484, 2*213.362,
              2*697.157, 2*214.162, 2*701.724, 2*217.193, 2*706.108,
              2*219.430, 2*708.131, 2*220.164, 2*708.322, 2*221.667,
              2*708.111, 2*223.161, 2*707.901, 2*223.931, 2*708.131 }},
           p:getCoordinatesArrayArray(annot, 'InkList'))
end)


test('Page:getAnnotFreeText_RD()',
     function()
        local d = Doc:new()
        local p = Page:new(d)

        local pdf = pdfe.open('pdf/freetext-01.pdf')
        local annot = pdfe.getpage(pdf, 1).Annots[1]

        assert.nearly_same(
           {200, 200, 0, 0},
           p:getAnnotFreeText_RD(annot, 'RD'))
end)


end) -- describe
