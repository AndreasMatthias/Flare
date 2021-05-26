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


describe('Testing flare-keyval.lua:', function()


test('Page:processKeyvals()',
     function()
        local function setGinKV(t, key, val)
           t[key] = val
        end

        local function setFlareKV(t, page, id, key, op, val)
           t[page] = t[page] or {}
           t[page][id] = t[page][id] or {}
           t[page][id][key] = {op = op, val = val}
        end

        local p = Page:new(Doc:new())
        local GinKV = {}
        local FlareKV = {}
        p:processKeyvals('{}')
        setGinKV(GinKV, 'page', 1)
        assert.same(GinKV, p.GinKV)
        assert.same(FlareKV, p.FlareKV)


        local p = Page:new(Doc:new())
        local GinKV = {}
        local FlareKV = {}
        p:processKeyvals("{{key = 'filename', val = 'foo.pdf'}}")
        setGinKV(GinKV, 'filename', 'foo.pdf')
        setGinKV(GinKV, 'page', 1)
        assert.same(GinKV, p.GinKV)
        assert.same(FlareKV, p.FlareKV)


        local p = Page:new(Doc:new())
        local GinKV = {}
        local FlareKV = {}
        p:processKeyvals("{{key = 'filename', val = 'foo.pdf'}," ..
                         " {key = 'page', val = '3'}}")
        setGinKV(GinKV, 'filename', 'foo.pdf')
        setGinKV(GinKV, 'page', 3)
        assert.same(GinKV, p.GinKV)
        assert.same(FlareKV, p.FlareKV)


        local p = Page:new(Doc:new())
        local GinKV = {}
        local FlareKV = {}
        p:processKeyvals("{{key = 'flareReplaceFoo', val = 'aaa'}}")
        setGinKV(GinKV, 'page', 1)
        setFlareKV(FlareKV, 'all', 'all', 'Foo', 'replace', 'aaa')
        assert.same(GinKV, p.GinKV)
        assert.same(FlareKV, p.FlareKV)


        local p = Page:new(Doc:new())
        local GinKV = {}
        local FlareKV = {}
        p:processKeyvals("{{key = 'flareReplaceFoo@2!3', val = 'aaa'}}")
        setGinKV(GinKV, 'page', 1)
        setFlareKV(FlareKV, 2, 3, 'Foo', 'replace', 'aaa')
        assert.same(GinKV, p.GinKV)
        assert.same(FlareKV, p.FlareKV)

        local p = Page:new(Doc:new())
        local GinKV = {}
        local FlareKV = {}
        p:processKeyvals("{{key = 'flareReplaceFoo', val = 'aaa'}," ..
                         " {key = 'flareReplaceFoo', val = 'bbb'}}")
        setGinKV(GinKV, 'page', 1)
        setFlareKV(FlareKV, 'all', 'all', 'Foo', 'replace', 'bbb')
        assert.same(GinKV, p.GinKV)
        assert.same(FlareKV, p.FlareKV)


        local p = Page:new(Doc:new())
        local GinKV = {}
        local FlareKV = {}
        p:processKeyvals("{{key = 'flareReplaceFoo', val = 'aaa'}," ..
                         " {key = 'flareReplaceFoo@2!3', val = 'bbb'}}")
        setGinKV(GinKV, 'page', 1)
        setFlareKV(FlareKV, 'all', 'all', 'Foo', 'replace', 'aaa')
        setFlareKV(FlareKV, 2, 3, 'Foo', 'replace', 'bbb')
        assert.same(GinKV, p.GinKV)
        assert.same(FlareKV, p.FlareKV)


        local p = Page:new(Doc:new())
        local GinKV = {}
        local FlareKV = {}
        p:processKeyvals("{{key = 'flareReplaceFoo', val = 'aaa'}," ..
                         " {key = 'flareRemoveFoo', val = 'true'}}")
        setGinKV(GinKV, 'page', 1)
        setFlareKV(FlareKV, 'all', 'all', 'Foo', 'remove', true)
        assert.same(GinKV, p.GinKV)
        assert.same(FlareKV, p.FlareKV)


        local p = Page:new(Doc:new())
        local GinKV = {}
        local FlareKV = {}
        p:processKeyvals("{{key = 'flareReplaceFoo', val = 'aaa'}," ..
                         " {key = 'flareRemoveFoo', val = 'false'}}")
        setGinKV(GinKV, 'page', 1)
        setFlareKV(FlareKV, 'all', 'all', 'Foo', 'replace', 'aaa')
        assert.same(GinKV, p.GinKV)
        assert.same(FlareKV, p.FlareKV)
end)


test('Page:setGinKV()',
     function()
        local p = Page:new(Doc:new())

        p.GinKV = {}
        p:setGinKV('filename', 'foo.pdf')
        assert.same(
           {filename = 'foo.pdf'},
           p.GinKV)

        -- do not overwrite existing 'filename'
        p:setGinKV('filename', 'bar.pdf')
        assert.same(
           {filename = 'foo.pdf'},
           p.GinKV)

        p:setGinKV('page', 3)
        assert.same(
           {filename = 'foo.pdf', page = 3},
           p.GinKV)

        -- do not overwrite existing 'page'
        p:setGinKV('page', 5)
        assert.same(
           {filename = 'foo.pdf', page = 3},
           p.GinKV)

        p:setGinKV('scale', 0.5)
        assert.same(
           {filename = 'foo.pdf', page = 3, scale = 0.5},
           p.GinKV)

        -- BUT: do overwrite existing 'scale'
        p:setGinKV('scale', 0.3)
        assert.same(
           {filename = 'foo.pdf', page = 3, scale = 0.3},
           p.GinKV)

        p.GinKV = {}
        p:setGinKV('userpassword', 'xox')
        assert.same(
           {userpassword = 'xox'},
           p.GinKV)

end)

test('Page:setFlareKV()',
     function()
        local function set(t, key, page, id, op, val)
           t[key] = t[key] or {}
           t[key][page] = t[key][page] or {}
           t[key][page][id] = val
        end

        -- no one overrides `replace`
        local p = Page:new(Doc:new())
        p:setFlareKV(2, 3, 'Foo', 'replace', 'xxx')
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('replace', op)
        assert.same('xxx', val)

        p:setFlareKV(2, 3, 'Foo', 'replace', 'yyy')
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('replace', op)
        assert.same('xxx', val)

        p:setFlareKV(2, 3, 'Foo', 'remove', true)
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('replace', op)
        assert.same('xxx', val)

        p:setFlareKV(2, 3, 'Foo', 'remove', false)
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('replace', op)
        assert.same('xxx', val)

        p:setFlareKV(2, 3, 'Foo', 'scale', .5)
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('replace', op)
        assert.same('xxx', val)

        -- no one overrides `scale`
        local p = Page:new(Doc:new())
        p:setFlareKV(2, 3, 'Foo', 'scale', .5)
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('scale', op)
        assert.same(.5, val)

        p:setFlareKV(2, 3, 'Foo', 'replace', 'xxx')
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('scale', op)
        assert.same(.5, val)
        
        p:setFlareKV(2, 3, 'Foo', 'remove', true)
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('scale', op)
        assert.same(.5, val)

        p:setFlareKV(2, 3, 'Foo', 'remove', false)
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('scale', op)
        assert.same(.5, val)

        p:setFlareKV(2, 3, 'Foo', 'scale', .5)
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('scale', op)
        assert.same(.5, val)
        
        -- no one overrides `remove = true`
        local p = Page:new(Doc:new())
        p:setFlareKV(2, 3, 'Foo', 'remove', true)
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('remove', op)
        assert.same(true, val)

        p:setFlareKV(2, 3, 'Foo', 'remove', false)
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('remove', op)
        assert.same(true, val)

        p:setFlareKV(2, 3, 'Foo', 'replace', 'xxx')
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('remove', op)
        assert.same(true, val)

        p:setFlareKV(2, 3, 'Foo', 'scale', .5)
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('remove', op)
        assert.same(true, val)

        
        -- `remove = true` overrides `remove = false`
        local p = Page:new(Doc:new())
        p:setFlareKV(2, 3, 'Foo', 'remove', false)
        p:setFlareKV(2, 3, 'Foo', 'remove', true)
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('remove', op)
        assert.same(false, val)

        -- `replace` overrides `remove = false`
        local p = Page:new(Doc:new())
        p:setFlareKV(2, 3, 'Foo', 'remove', false)
        p:setFlareKV(2, 3, 'Foo', 'replace', 'xxx')
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('replace', op)
        assert.same('xxx', val)

        -- `scale` overrides `remove = false`
        local p = Page:new(Doc:new())
        p:setFlareKV(2, 3, 'Foo', 'remove', false)
        p:setFlareKV(2, 3, 'Foo', 'scale', .5)
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('scale', op)
        assert.same(.5, val)
end)


test('Page:setFlareKVStrict()',
     function()
        -- This function is called within `Page:setFlareKV()`.
        -- See tests there.
end)


test('Page:getFlareKV()',
     function()
        local p = Page:new(Doc:new())
        p:setFlareKV(2, 3, 'Foo', 'replace', 'xxx')
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('replace', op)
        assert.same('xxx', val)

        local p = Page:new(Doc:new())
        p:setFlareKV(2, 'all', 'Foo', 'replace', 'xxx')
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('replace', op)
        assert.same('xxx', val)

        local p = Page:new(Doc:new())
        p:setFlareKV('all', 'all', 'Foo', 'replace', 'xxx')
        local val, op = p:getFlareKV(2, 3, 'Foo')
        assert.same('replace', op)
        assert.same('xxx', val)
end)


test('Page:getFlareKVStrict()',
     function()
        local p = Page:new(Doc:new())
        p:setFlareKV(2, 3, 'Foo', 'replace', 'xxx')
        local val, op = p:getFlareKVStrict(2, 3, 'Foo')
        assert.same('replace', op)
        assert.same('xxx', val)

        local p = Page:new(Doc:new())
        p:setFlareKV('Foo', 2, 'all', 'replace', 'xxx')
        local val, op = p:getFlareKVStrict(2, 3, 'Foo')
        assert.same(nil, op)
        assert.same(nil, val)

        local p = Page:new(Doc:new())
        p:setFlareKV('Foo', 'all', 'all', 'replace', 'xxx')
        local val, op = p:getFlareKVStrict(2, 3, 'Foo')
        assert.same(nil, op)
        assert.same(nil, val)
end)


test('Page:setDefaultGinKVs()',
     function()
        local p = Page:new(Doc:new())
        p:setDefaultGinKVs()

        assert.same(
           p.GinKV,
           {page = 1})
end)


test('Page:isFlareKey()',
     function()
        local p = Page:new(Doc:new())

        assert.same(
           true,
           p:isFlareKey('flare'))

        assert.same(
           true,
           p:isFlareKey('flarexxx'))

        assert.same(
           false,
           p:isFlareKey('xflare'))

        assert.same(
           false,
           p:isFlareKey(''))
end)


test('Page:splitFlareKey()',
     function()
        local p = Page:new(Doc:new())

        local key, page, id, op = p:splitFlareKey('flareReplaceFoo')
        assert.same('Foo', key)
        assert.same('all', page)
        assert.same('all', id)
        assert.same('replace', op)

        local key, page, id, op = p:splitFlareKey('flareReplaceFoo@22')
        assert.same('Foo', key)
        assert.same(22, page)
        assert.same('all', id)
        assert.same('replace', op)
        
        local key, page, id, op = p:splitFlareKey('flareReplaceFoo!33')
        assert.same('Foo', key)
        assert.same('all', page)
        assert.same(33, id)
        assert.same('replace', op)

        local key, page, id, op = p:splitFlareKey('flareReplaceFoo@22!33')
        assert.same('Foo', key)
        assert.same(22, page)
        assert.same(33, id)
        assert.same('replace', op)

        local key, page, id, op = p:splitFlareKey('flareReplaceFoo!33@22')
        assert.same('Foo', key)
        assert.same(22, page)
        assert.same(33, id)
        assert.same('replace', op)

        local key, page, id, op = p:splitFlareKey('flareReplaceFoo!33@22!44@55')
        assert.same('Foo', key)
        assert.same(55, page)
        assert.same(44, id)
        assert.same('replace', op)
end)


test('Page:removeFlareKeyPrefix()',
     function()
        local p = Page:new(Doc:new())
        assert.same('Foo', p:removeFlareKeyPrefix('flareFoo'))
end)


test('Page:getFlareKeyOperation()',
     function()
        local p = Page:new(Doc:new())
        assert.same('replace', p:getFlareKeyOperation('replaceFoo'))
        assert.same('remove', p:getFlareKeyOperation('removeFoo'))
        assert.same('ref', p:getFlareKeyOperation('refFoo'))
        assert.same('scale', p:getFlareKeyOperation('scaleFoo'))
end)


test('Page:getFlareKeyPage()',
     function()
        local p = Page:new(Doc:new())
        assert.same('all', p:getFlareKeyPage('Foo'))
        assert.same('all', p:getFlareKeyPage('Foo!3'))
        assert.same(2, p:getFlareKeyPage('Foo@2'))
        assert.same(2, p:getFlareKeyPage('Foo@2!3'))
        assert.same(2, p:getFlareKeyPage('Foo!3@2'))
        assert.same(4, p:getFlareKeyPage('Foo@2@3@4'))
end)


test('Page:getFlareKeyId()',
     function()
        local p = Page:new(Doc:new())
        assert.same('all', p:getFlareKeyId('Foo'))
        assert.same('all', p:getFlareKeyId('Foo@2'))
        assert.same(3, p:getFlareKeyId('Foo!3'))
        assert.same(3, p:getFlareKeyId('Foo@2!3'))
        assert.same(3, p:getFlareKeyId('Foo!3@2'))
        assert.same(4, p:getFlareKeyId('Foo!2!3!4'))
end)


test('Page:removeFlareKeyPageId()',
     function()
        local p = Page:new(Doc:new())
        assert.same('Foo', p:removeFlareKeyPageId('Foo'))
        assert.same('Foo', p:removeFlareKeyPageId('Foo@2'))
        assert.same('Foo', p:removeFlareKeyPageId('Foo@2!3'))
        assert.same('Foo', p:removeFlareKeyPageId('Foo!3'))
        assert.same('Foo', p:removeFlareKeyPageId('Foo!3@2'))
        assert.same('Foo', p:removeFlareKeyPageId('Foo@2!3@4@5!8!1'))
end)


test('Page:trim()',
     function()
        local p = Page:new(Doc:new())
        assert.same(nil, p:trim(nil))
        assert.same(3, p:trim(3))
        assert.same(true, p:trim(true))
        assert.same(false, p:trim(false))

        assert.same('', p:trim(''))
        assert.same('foo', p:trim('foo'))
        assert.same('foo', p:trim(' foo'))
        assert.same('foo', p:trim('  foo'))
        assert.same('foo', p:trim('foo '))
        assert.same('foo', p:trim('foo  '))
        assert.same('foo', p:trim(' foo '))
        assert.same('foo bar', p:trim(' foo bar '))
        assert.same('foo  bar', p:trim(' foo  bar '))
end)


test('Page:makeBoolean()',
     function()
        local p = Page:new(Doc:new())

        assert.same(
           '',
           p:makeBoolean(''))

        assert.same(
           'foo',
           p:makeBoolean('foo'))

        assert.same(
           33,
           p:makeBoolean(33))

        assert.same(
           '33',
           p:makeBoolean('33'))


        assert.same(
           true,
           p:makeBoolean('true'))

        assert.same(
           false,
           p:makeBoolean('false'))
end)

test('Page:checkNumber()',
     function()
        local p = Page:new(Doc:new())

        assert.same(
           3,
           p:checkNumber('page', '3'))

        assert.same(
           3,
           p:checkNumber('page', 3))

        assert.has_error(
           function() p:checkNumber('page', '') end)

        assert.has_error(
           function() p:checkNumber('page', 'x') end)

        assert.has_error(
           function() p:checkNumber('page', true) end)

        assert.has_error(
           function() p:checkNumber('page', false) end)

        assert.has_error(
           function() p:checkNumber('page', nil) end)
end)


end) -- describe
