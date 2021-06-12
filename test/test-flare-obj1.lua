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


describe('Testing flare-format-obj.lua:', function()


test('Page:is_utf16()',
     function()
        local p = Page:new(Doc:new())
        assert.same(false,
                        p:is_utf16('test'))
        assert.same(true,
                        p:is_utf16('\xFE\xFF\x00\x74'))
end)


test('Page:utf16_to_hex()', function()
        local p = Page:new(Doc:new())
        assert.same('FEFF0074',
                        p:utf16_to_hex('\xfe\xff\x00\x74'))
end)


test('Page:clean_utf16()',
     function()
        local p = Page:new(Doc:new())

        -- plain string
        local str, hex = p:clean_utf16('test', false)
        assert.same({'test', false}, {str, hex})

        -- hex string
        local str, hex = p:clean_utf16('FEFF0074', true)
        assert.same({'FEFF0074', true}, {str, hex})

        -- utf-16 string
        local str, hex = p:clean_utf16('\xfe\xff\x00\x74', false)
        assert.same({'FEFF0074', true}, {str, hex})
end)


test('Page:scaleNumber()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        p.ctm = p:makeCTM(2, 0, 0, 2, 0, 0)
        assert.same(6, p:scaleNumber(3, 2))
        assert.same(6, p:scaleNumber(3, true))
        assert.same(3, p:scaleNumber(3, false))
end)


test('Page:errorIfArray()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        assert.has_no.errors(function()
              local val
              _, val, _ = pdfe.getfromdictionary(pageDict, 'TestBoolean')
              p:errorIfArray(val)
              _, val, _ = pdfe.getfromdictionary(pageDict, 'TestInteger')
              p:errorIfArray(val)
              _, val, _ = pdfe.getfromdictionary(pageDict, 'TestNumber')
              p:errorIfArray(val)
              _, val, _ = pdfe.getfromdictionary(pageDict, 'TestName')
              p:errorIfArray(val)
              _, val, _ = pdfe.getfromdictionary(pageDict, 'TestString')
              p:errorIfArray(val)
              _, val, _ = pdfe.getfromdictionary(pageDict, 'TestStringHex')
              p:errorIfArray(val)
              _, val, _ = pdfe.getfromdictionary(pageDict, 'TestDictionary')
              p:errorIfArray(val)
        end)

        assert.has_error(function()
              local val
              _, val, _ = pdfe.getfromdictionary(pageDict, 'TestArray')
              p:errorIfArray(val)
        end)
end)


test('Page:zero_based_indexing()',
     function()
        local p = Page:new(Doc:new())
        assert.same(2, p:zero_based_indexing(nil, 3))
        assert.same('foo', p:zero_based_indexing(nil, 'foo'))
end)


test('Page:makeRef()',
     function()
        local d = Doc:new()
        local p = Page:new(d)
        assert.same('null', p:makeRef())
        assert.same('15 0 R', p:makeRef(15))
end)


test('Page:getUserInput()',
     function()
        local p = Page:new(Doc:new())
        p.GinKV.page, p.annotId = 2, 3

        p.FlareKV = {}
        local user = p:getUserInput('Foo')
        assert.is_nil(user)

        p.FlareKV = {}
        p:setFlareKV(2, 3, 'Foo', 'remove', true)
        local user = p:getUserInput('Foo')
        assert.same(user, '')

        p.FlareKV = {}
        p:setFlareKV(2, 3, 'Foo', 'remove', false)
        local user = p:getUserInput('Foo')
        assert.is_nil(user)

        p.FlareKV = {}
        p:setFlareKV('all', 3, 'Foo', 'remove', true)
        local user = p:getUserInput('Foo')
        assert.same(user, '')

        p.FlareKV = {}
        p:setFlareKV(2, 'all', 'Foo', 'remove', true)
        local user = p:getUserInput('Foo')
        assert.same(user, '')

        p.FlareKV = {}
        p:setFlareKV('all', 'all', 'Foo', 'remove', true)
        local user = p:getUserInput('Foo')
        assert.same(user, '')

        p.FlareKV = {}
        p:setFlareKV(2, 3, 'Foo', 'replace', '[1 2 3]')
        local user = p:getUserInput('Foo')
        assert.same(user, '[1 2 3]')

        p.FlareKV = {}
        p:setFlareKV('all', 3, 'Foo', 'replace', '[1 2 3]')
        local user = p:getUserInput('Foo')
        assert.same(user, '[1 2 3]')

        p.FlareKV = {}
        p:setFlareKV(2, 'all', 'Foo', 'replace', '[1 2 3]')
        local user = p:getUserInput('Foo')
        assert.same(user, '[1 2 3]')

        p.FlareKV = {}
        p:setFlareKV('all', 'all', 'Foo', 'replace', '[1 2 3]')
        local user = p:getUserInput('Foo')
        assert.same(user, '[1 2 3]')
end)


test('Page:checkUserInput()',
     function()
        local p = Page:new(Doc:new())
        assert.is_false(p:checkUserInput(2, 3, 'foo'))

        p.FlareKV = {}
        p:setFlareKV(2, 3, 'foo', 'xxx')
        assert.is_true(p:checkUserInput(2, 3, 'foo'))
        assert.is_false(p:checkUserInput('all', 3, 'foo'))
        assert.is_false(p:checkUserInput(2, 'all', 'foo'))
        assert.is_false(p:checkUserInput('all', 'all', 'foo'))

        p.FlareKV = {}
        p:setFlareKV(2, 'all', 'foo', 'xxx')
        assert.is_false(p:checkUserInput(2, 3, 'foo'))
        assert.is_false(p:checkUserInput('all', 3, 'foo'))
        assert.is_true(p:checkUserInput(2, 'all', 'foo'))
        assert.is_false(p:checkUserInput('all', 'all', 'foo'))

        p.FlareKV = {}
        p:setFlareKV('all', 3, 'foo', 'xxx')
        assert.is_false(p:checkUserInput(2, 3, 'foo'))
        assert.is_true(p:checkUserInput('all', 3, 'foo'))
        assert.is_false(p:checkUserInput(2, 'all', 'foo'))
        assert.is_false(p:checkUserInput('all', 'all', 'foo'))

        p.FlareKV = {}
        p:setFlareKV('all', 'all', 'foo', 'xxx')
        assert.is_false(p:checkUserInput(2, 3, 'foo'))
        assert.is_false(p:checkUserInput('all', 3, 'foo'))
        assert.is_false(p:checkUserInput(2, 'all', 'foo'))
        assert.is_true(p:checkUserInput('all', 'all', 'foo'))
end)


test('Page:getBoolean()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- copy from pdf
        assert.same(true, p:getBoolean(pageDict, 'TestBoolean'))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestBoolean', 'replace', 'false')
        assert.same('false', p:getBoolean(pageDict, 'TestBoolean'))
end)


test('Page:getInteger()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- copy from pdf
        assert.same(4, p:getInteger(pageDict, 'TestInteger'))
        assert.same(8, p:getInteger(pageDict, 'TestInteger', 2))
        p.ctm = p:makeCTM(3, 0, 0, 3, 0, 0)
        assert.same(12, p:getInteger(pageDict, 'TestInteger', true))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestInteger', 'replace', '99')
        assert.same('99', p:getInteger(pageDict, 'TestInteger'))
end)


test('Page:getNumber()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- copy from pdf
        assert.same(1.23, p:getNumber(pageDict, 'TestNumber'))
        assert.same(2.46, p:getNumber(pageDict, 'TestNumber', 2))
        p.ctm = p:makeCTM(3, 0, 0, 3, 0, 0)
        assert.same(3.69, p:getNumber(pageDict, 'TestNumber', true))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestNumber', 'replace', '7.89')
        assert.same('7.89', p:getNumber(pageDict, 'TestNumber'))
end)


test('Page:getName()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- copy from pdf
        assert.same('/Foo', p:getName(pageDict, 'TestName'))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestName', 'replace', '/Bar')
        assert.same('/Bar', p:getName(pageDict, 'TestName'))
end)


test('Page:getString()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- copy from pdf
        assert.same('(foo)', p:getString(pageDict, 'TestString'))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestString', 'replace', '(testing)')
        assert.same('(testing)', p:getString(pageDict, 'TestString'))
end)


test('Page:getString()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- copy from pdf
        assert.same('<FEFF0066006F006F>',
                    p:getString(pageDict, 'TestStringHex'))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestString', 'replace', '<FEFF006200610072>')
        assert.same('<FEFF006200610072>',
                    p:getString(pageDict, 'TestString'))
end)


test('Page:getArray()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())
        p.ctm = p:makeCTM(0.5, 0, 0, 0.5, 0, 0)

        -- copy from pdf
        assert.same(
           {1, 2, 3},
           p:getArray(pageDict, 'TestArray'))

        assert.same(
           {2, 4, 6},
           p:getArray(pageDict, 'TestArray', 2))

        assert.same(
           {0.5, 1, 1.5},
           p:getArray(pageDict, 'TestArray', true))

        assert.same(
           {true, 4, 1.23, '/Foo', '(foo)', '<FEFF0066006F006F>',
            {1, 2, 3}, {AAA = 1, BBB = 2}},
           p:getArray(pageDict, 'TestArray2'))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestArray', 'replace', '[(aaa) (bbb)]')
        assert.same(
           '[(aaa) (bbb)]',
           p:getArray(pageDict, 'TestArray'))
end)


test('Page:getArray2()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())
        p.ctm = p:makeCTM(0.5, 0, 0, 0.5, 0, 0)

        -- copy from pdf
        assert.same(
           {1, 2, 3},
           p:getArray2(pageDict['TestArray']))

end)


test('Page:getDictionary()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())
        local dict = p:getDictionary(pageDict, 'TestDictionary')

        -- copy from pdf
        assert.same(
           {AAA = 1, BBB = '(test)'},
           p:getDictionary(pageDict, 'TestDictionary'))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestDictionary', 'replace', '<</XXX 123>>')
        assert.same(
           '<</XXX 123>>',
           p:getDictionary(pageDict, 'TestDictionary'))
end)


test('Page:getDictionary2()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())
        local dict = p:getDictionary2(pageDict['TestDictionary'])

        -- copy from pdf
        assert.same(
           {AAA = 1, BBB = '(test)'},
           p:getDictionary2(pageDict['TestDictionary']))
end)


test('Page:getStream()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- copy from pdf
        local str = p:getStream(pageDict, 'TestStream')
        assert.is_pdf_ref(str)

        -- user input
        local n = pdf.immediateobj('stream', 'just testing', '<<>>')
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestStream', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:getStream(pageDict, 'TestStream'))
end)


test('Page:getReference()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- boolean: copy from pdf
        local str = p:getReference(pageDict, 'TestRefBoolean')
        assert.is_pdf_ref(str)

        -- boolean: user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.immediateobj('false')
        p:setFlareKV(2, 3, 'TestRefBoolean', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:getReference(pageDict, 'TestRefBoolean'))

        -- integer: copy from pdf
        local str = p:getReference(pageDict, 'TestRefInteger')
        assert.is_pdf_ref(str)

        -- integer: user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.immediateobj('99')
        p:setFlareKV(2, 3, 'TestRefInteger', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:getReference(pageDict, 'TestRefInteger'))

        -- number: copy from pdf
        local str = p:getReference(pageDict, 'TestRefNumber')
        assert.is_pdf_ref(str)

        -- number: user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.immediateobj('7.89')
        p:setFlareKV(2, 3, 'TestRefNumber', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:getReference(pageDict, 'TestRefNumber'))

        -- name: copy from pdf
        local str = p:getReference(pageDict, 'TestRefName')
        assert.is_pdf_ref(str)

        -- name: user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.immediateobj('/Bar')
        p:setFlareKV(2, 3, 'TestRefName', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:getReference(pageDict, 'TestRefName'))

        -- string: copy from pdf
        local str = p:getReference(pageDict, 'TestRefString')
        assert.is_pdf_ref(str)

        -- string: user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.immediateobj('(testing)')
        p:setFlareKV(2, 3, 'TestRefString', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:getReference(pageDict, 'TestRefString'))

        -- array: copy from pdf
        local str = p:getReference(pageDict, 'TestRefArray')
        assert.is_pdf_ref(str)

        -- array: user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.immediateobj('[(aaa) (bbb)]')
        p:setFlareKV(2, 3, 'TestRefArray', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:getReference(pageDict, 'TestRefArray'))

        -- dictionary: copy from pdf
        local str = p:getReference(pageDict, 'TestRefDictionary')
        assert.is_pdf_ref(str)

        -- dictionary: user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.immediateobj('<</AAA (test)>>')
        p:setFlareKV(2, 3, 'TestRefDictionary', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:getReference(pageDict, 'TestRefDictionary'))


        -- stream: copy from pdf
        local str = p:getReference(pageDict, 'TestRefStream')
        assert.is_pdf_ref(str)

        -- stream: user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.immediateobj('stream', 'just testing', '<<>>')
        p:setFlareKV(2, 3, 'TestRefStream', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:getReference(pageDict, 'TestRefStream'))
end)


test('Page:getStringOrStream()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- string: copy from pdf
        assert.same(
           '(foo)',
           p:getStringOrStream(pageDict, 'TestString'))

        -- string: user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestString', 'replace', '(bar)')
        assert.same(
           '(bar)',
           p:getStringOrStream(pageDict, 'TestString'))

        -- stream: copy from pdf
        local str = p:getStringOrStream(pageDict, 'TestStream')
        assert.is_pdf_ref(str)

        -- stream: user input
        local n = pdf.immediateobj('stream', 'just testing', '<<>>')
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestStream', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:getStringOrStream(pageDict, 'TestStream'))
end)


test('Page:getP()',
     function()
        local p = Page:new(Doc:new())

        -- new reference
        local str = p:getP()
        assert.is.not_nil(str:find('^%d+ 0 R$'))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.getpageref(3)
        local user = string.format('%d 0 R', n)
        p:setFlareKV(2, 3, 'P', 'replace', user)
        assert.same(
           string.format('%d 0 R', n),
           p:getP())
end)


test('Page:getObj()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        assert.same(true, p:getObj(pageDict, 'TestBoolean'))
        assert.same(4, p:getObj(pageDict, 'TestInteger'))
        assert.same(1.23, p:getObj(pageDict, 'TestNumber'))
        assert.same('/Foo', p:getObj(pageDict, 'TestName'))
        assert.same('(foo)', p:getObj(pageDict, 'TestString'))
        assert.same(
           {1, 2, 3},
           p:getObj(pageDict, 'TestArray'))
        -- dictionary
        assert.same(
           {AAA = 1, BBB = '(test)'},
           p:getObj(pageDict, 'TestDictionary'))
        -- stream
        local str = p:getObj(pageDict, 'TestStream')
        assert.is_pdf_ref(str)
        -- reference
        local str = p:getObj(pageDict, 'TestRefInteger')
        assert.is_pdf_ref(str)
        -- invalid reference
        assert.same('', p:getObj(pageDict, 'TestRefInvalide'))
end)


end) -- describe
