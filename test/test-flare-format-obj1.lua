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


test('Page:formatUserInput()',
     function()
        local p = Page:new(Doc:new())
        p.GinKV.page, p.annotId = 2, 3

        p.FlareKV = {}
        local user = p:formatUserInput('Foo')
        assert.is_nil(user)

        p.FlareKV = {}
        p:setFlareKV(2, 3, 'Foo', 'remove', true)
        local user = p:formatUserInput('Foo')
        assert.same(user, '')

        p.FlareKV = {}
        p:setFlareKV(2, 3, 'Foo', 'remove', false)
        local user = p:formatUserInput('Foo')
        assert.is_nil(user)

        p.FlareKV = {}
        p:setFlareKV('all', 3, 'Foo', 'remove', true)
        local user = p:formatUserInput('Foo')
        assert.same(user, '')

        p.FlareKV = {}
        p:setFlareKV(2, 'all', 'Foo', 'remove', true)
        local user = p:formatUserInput('Foo')
        assert.same(user, '')

        p.FlareKV = {}
        p:setFlareKV('all', 'all', 'Foo', 'remove', true)
        local user = p:formatUserInput('Foo')
        assert.same(user, '')

        p.FlareKV = {}
        p:setFlareKV(2, 3, 'Foo', 'replace', '[1 2 3]')
        local user = p:formatUserInput('Foo')
        assert.same(user, '[1 2 3]')

        p.FlareKV = {}
        p:setFlareKV('all', 3, 'Foo', 'replace', '[1 2 3]')
        local user = p:formatUserInput('Foo')
        assert.same(user, '[1 2 3]')

        p.FlareKV = {}
        p:setFlareKV(2, 'all', 'Foo', 'replace', '[1 2 3]')
        local user = p:formatUserInput('Foo')
        assert.same(user, '[1 2 3]')

        p.FlareKV = {}
        p:setFlareKV('all', 'all', 'Foo', 'replace', '[1 2 3]')
        local user = p:formatUserInput('Foo')
        assert.same(user, '[1 2 3]')
end)


test('Page:getUserInput()',
     function()
        local p = Page:new(Doc:new())
        p.GinKV.page, p.annotId = 2, 3

        p.FlareKV = {}
        local user = p:getUserInput('Foo')
        assert.is_nil(user)

        p.FlareKV = {}
        p:setFlareKV(2, 3, 'Foo', 'replace', 'xxx')
        local user =  p:getUserInput('Foo')
        assert.is_not_nil(user)
        assert.same('replace', user.op)
        assert.same('xxx', user.val)

        p:setFlareKV('all', 3, 'Foo', 'replace', 'xxx')
        local user =  p:getUserInput('Foo')
        assert.is_not_nil(user)
        assert.same('replace', user.op)
        assert.same('xxx', user.val)

        p:setFlareKV(2, 'all', 'Foo', 'replace', 'xxx')
        assert.is_not_nil(user)
        assert.same('replace', user.op)
        assert.same('xxx', user.val)

        p:setFlareKV('all', 'all', 'Foo', 'replace', 'xxx')
        local user = p:getUserInput('Foo')
        assert.is_not_nil(user)
        assert.same('replace', user.op)
        assert.same('xxx', user.val)
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


test('Page:formatBoolean()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- copy from pdf
        assert.same('true', p:formatBoolean(pageDict, 'TestBoolean'))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestBoolean', 'replace', 'false')
        assert.same('false', p:formatBoolean(pageDict, 'TestBoolean'))
end)


test('Page:formatInteger()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- copy from pdf
        assert.same('4',
                        p:formatInteger(pageDict, 'TestInteger'))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestInteger', 'replace', '99')
        assert.same('99', p:formatInteger(pageDict, 'TestInteger'))
end)


test('Page:formatNumber()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- copy from pdf
        assert.same('1.23',
                        p:formatNumber(pageDict, 'TestNumber'))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestNumber', 'replace', '7.89')
        assert.same('7.89', p:formatNumber(pageDict, 'TestNumber'))
end)


test('Page:formatName()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- copy from pdf
        assert.same('/Foo',
                        p:formatName(pageDict, 'TestName'))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestName', 'replace', '/Bar')
        assert.same('/Bar', p:formatName(pageDict, 'TestName'))
end)


test('Page:formatString()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- copy from pdf
        assert.same('(foo)',
                        p:formatString(pageDict, 'TestString'))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestString', 'replace', '(testing)')
        assert.same('(testing)', p:formatString(pageDict, 'TestString'))
end)


test('Page:formatString()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- copy from pdf
        assert.same('<FEFF0066006F006F>',
                        p:formatString(pageDict, 'TestStringHex'))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestString', 'replace', '<FEFF006200610072>')
        assert.same('<FEFF006200610072>',
                        p:formatString(pageDict, 'TestString'))
end)


test('Page:getArray()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- copy from pdf
        x = p:getArray(pageDict, 'TestArray')

        assert.same(
           {'1', '2', '3'},
           p:getArray(pageDict, 'TestArray'))

        assert.same(
           {'true', '4', '1.23', '/Foo', '(foo)', '<FEFF0066006F006F>',
            {'1', '2', '3'}, {AAA = '1', BBB = '2'}},
           p:getArray(pageDict, 'TestArray2'))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestArray', 'replace', '[(aaa) (bbb)]')
        assert.same(
           '[(aaa) (bbb)]',
           p:getArray(pageDict, 'TestArray'))
end)


test('Page:getDictionary()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())
        local dict = p:getDictionary(pageDict, 'TestDictionary')

        -- copy from pdf
        assert.same(
           {AAA = '1', BBB = '(test)'},
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
           {AAA = '1', BBB = '(test)'},
           p:getDictionary2(pageDict['TestDictionary']))
end)


test('Page:formatStream()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- copy from pdf
        local str = p:formatStream(pageDict, 'TestStream')
        assert.is_pdf_ref(str)

        -- user input
        local n = pdf.immediateobj('stream', 'just testing', '<<>>')
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestStream', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:formatStream(pageDict, 'TestStream'))
end)


test('Page:formatReference()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- boolean: copy from pdf
        local str = p:formatReference(pageDict, 'TestRefBoolean')
        assert.is_pdf_ref(str)

        -- boolean: user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.immediateobj('false')
        p:setFlareKV(2, 3, 'TestRefBoolean', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:formatReference(pageDict, 'TestRefBoolean'))

        -- integer: copy from pdf
        local str = p:formatReference(pageDict, 'TestRefInteger')
        assert.is_pdf_ref(str)

        -- integer: user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.immediateobj('99')
        p:setFlareKV(2, 3, 'TestRefInteger', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:formatReference(pageDict, 'TestRefInteger'))

        -- number: copy from pdf
        local str = p:formatReference(pageDict, 'TestRefNumber')
        assert.is_pdf_ref(str)

        -- number: user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.immediateobj('7.89')
        p:setFlareKV(2, 3, 'TestRefNumber', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:formatReference(pageDict, 'TestRefNumber'))

        -- name: copy from pdf
        local str = p:formatReference(pageDict, 'TestRefName')
        assert.is_pdf_ref(str)

        -- name: user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.immediateobj('/Bar')
        p:setFlareKV(2, 3, 'TestRefName', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:formatReference(pageDict, 'TestRefName'))

        -- string: copy from pdf
        local str = p:formatReference(pageDict, 'TestRefString')
        assert.is_pdf_ref(str)

        -- string: user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.immediateobj('(testing)')
        p:setFlareKV(2, 3, 'TestRefString', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:formatReference(pageDict, 'TestRefString'))

        -- array: copy from pdf
        local str = p:formatReference(pageDict, 'TestRefArray')
        assert.is_pdf_ref(str)

        -- array: user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.immediateobj('[(aaa) (bbb)]')
        p:setFlareKV(2, 3, 'TestRefArray', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:formatReference(pageDict, 'TestRefArray'))

        -- dictionary: copy from pdf
        local str = p:formatReference(pageDict, 'TestRefDictionary')
        assert.is_pdf_ref(str)

        -- dictionary: user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.immediateobj('<</AAA (test)>>')
        p:setFlareKV(2, 3, 'TestRefDictionary', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:formatReference(pageDict, 'TestRefDictionary'))


        -- stream: copy from pdf
        local str = p:formatReference(pageDict, 'TestRefStream')
        assert.is_pdf_ref(str)

        -- stream: user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.immediateobj('stream', 'just testing', '<<>>')
        p:setFlareKV(2, 3, 'TestRefStream', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:formatReference(pageDict, 'TestRefStream'))
end)


test('Page:formatStringOrStream()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        -- string: copy from pdf
        assert.same(
           '(foo)',
           p:formatStringOrStream(pageDict, 'TestString'))

        -- string: user input
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestString', 'replace', '(bar)')
        assert.same(
           '(bar)',
           p:formatStringOrStream(pageDict, 'TestString'))

        -- stream: copy from pdf
        local str = p:formatStringOrStream(pageDict, 'TestStream')
        assert.is_pdf_ref(str)

        -- stream: user input
        local n = pdf.immediateobj('stream', 'just testing', '<<>>')
        p.GinKV.page, p.annotId = 2, 3
        p:setFlareKV(2, 3, 'TestStream', 'ref', n)
        assert.same(
           string.format('%d 0 R', n),
           p:formatStringOrStream(pageDict, 'TestStream'))
end)


test('Page:formatP()',
     function()
        local p = Page:new(Doc:new())

        -- new reference
        local str = p:formatP()
        assert.is.not_nil(str:find('^%d+ 0 R$'))

        -- user input
        p.GinKV.page, p.annotId = 2, 3
        local n = pdf.getpageref(3)
        local user = string.format('%d 0 R', n)
        p:setFlareKV(2, 3, 'P', 'replace', user)
        assert.same(
           string.format('%d 0 R', n),
           p:formatP())
end)


test('Page:getfromobj()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        local ptype, pval, pdetail = p:getfromobj(pageDict['TestDictionary'], 'AAA')
        assert.same(3, ptype)
        assert.same(1, pval)
        assert.same(nil, pdetail)

        local ptype, pval, pdetail = p:getfromobj(pageDict['TestArray'], 2)
        assert.same(3, ptype)
        assert.same(2, pval)
        assert.same(nil, pdetail)
end)


test('Page:formatObj()',
     function()
        local pageDict = pdfe.open('pdf/pdfTypes.pdf').Pages[1]
        local p = Page:new(Doc:new())

        assert.same('true', p:formatObj(pageDict, 'TestBoolean'))
        assert.same('4', p:formatObj(pageDict, 'TestInteger'))
        assert.same('1.23', p:formatObj(pageDict, 'TestNumber'))
        assert.same('/Foo', p:formatObj(pageDict, 'TestName'))
        assert.same('(foo)', p:formatObj(pageDict, 'TestString'))
        assert.same(
           {'1', '2', '3'},
           p:formatObj(pageDict, 'TestArray'))
        -- dictionary
        assert.same(
           {AAA = '1', BBB = '(test)'},
           p:formatObj(pageDict, 'TestDictionary'))
        -- stream
        local str = p:formatObj(pageDict, 'TestStream')
        assert.is_pdf_ref(str)
        -- reference
        local str = p:formatObj(pageDict, 'TestRefInteger')
        assert.is_pdf_ref(str)
        -- invalid reference
        assert.same('', p:formatObj(pageDict, 'TestRefInvalide'))
end)


end) -- describe
