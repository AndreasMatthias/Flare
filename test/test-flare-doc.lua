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

pkg = require('flare-pkg')

describe('Testing flare-doc.lua:', function()


setup(function()
      mock_io = {}
      mock_io.open = function()
         _G.fh = _G.test_file_stream
         return _G.fh
      end
      saved_io = _G.io
      _G.io = mock_io
end)


teardown(function()
      _G.io = saved_io
end)


test('Doc:saveCache()',
     function()
        local d = Doc:new()

        _G.test_file_stream = stringio.create()
        local data = {'a', 'b', 'c'}
        d.cacheNew = data
        d:saveCache()
        assert.same(
           d:serialize(data),
           _G.fh:value())
end)


test('Doc:loadCache()',
     function()
        local d = Doc:new()

        -- Cache file doesn't exist.
        _G.test_file_stream = nil
        d:loadCache()
        assert.same(
           {},
           d.cacheOld)

        -- Cache file exists.
        _G.test_file_stream = stringio.open("{'a', 'b', 'c'}")
        d:loadCache()
        assert.same(
           {'a', 'b', 'c'},
           d.cacheOld)
end)


end) -- describe


describe('Testing flare-doc.lua:', function()


test('Doc:new()',
     function()
        local d = Doc:new()
        assert.same(false, d.dirtyCache)
        assert.same({}, d.cacheOld)
        assert.same({}, d.cacheNew)
        assert.same({}, d.destBucket)
end)


test('Doc:newPicture()',
     function()
        local d = Doc:new()
        assert.same(0, d.pictureCounter)
        d:newPicture()
        assert.same(1, d.pictureCounter)
        d:newPicture()
        assert.same(2, d.pictureCounter)
end)


test('Doc:newPage()',
     function()
        local d = Doc:new()
        assert.same(1, d.pageCounter)
        d:newPage()
        assert.same(2, d.pageCounter)
        d:newPage()
        assert.same(3, d.pageCounter)
end)


test('Doc:writeToCache()',
     function()
        local d = Doc:new()
        d.pictureCounter = 3

        -- check value
        d:writeToCache('foo', 123)
        assert.same(123, d.cacheNew[3]['foo'])
        assert.True(d.dirtyCache)

        -- check dirty cache false
        d.dirtyCache = false
        d.cacheOld = d.cacheNew
        d:writeToCache('foo', 123)
        assert.same(123, d.cacheNew[3]['foo'])
        assert.False(d.dirtyCache)

        -- check dirty cache true
        d:writeToCache('foo', 456)
        assert.same(456, d.cacheNew[3]['foo'])
        assert.True(d.dirtyCache)
end)


test('Doc:readFromCache()',
     function()
        local d = Doc:new()
        d.pictureCounter = 3
        d.cacheOld[3] = {}
        d.cacheOld[3]['foo'] = 123

        assert.same(123,
                        d:readFromCache('foo'))
        assert.same(nil,
                        d:readFromCache('bar'))

        d.pictureCounter = 4
        assert.same(nil,
                        d:readFromCache('foo'))
end)


test('Doc:readFromCacheWithPageObj()',
     function()
        local d = Doc:new()
        d.cacheOld[1] = {}
        d.cacheOld[2] = {}
        d.cacheOld[3] = {}
        d.cacheOld[3]['page_obj_old'] = 55
        d.cacheOld[3]['foo'] = 123

        assert.same(123,
                        d:readFromCacheWithPageObj('foo', 55))
        assert.same(nil,
                        d:readFromCacheWithPageObj('foo', 33))
end)


test('Doc:writeToCache_AnnotObj()',
     function()
        local d = Doc:new()
        d.pictureCounter = 2
        local annotId = 3
        d:writeToCache_AnnotObj(annotId, 'annot_obj_old', 33)
        assert.same(33, d.cacheNew[2]['annots'][3]['annot_obj_old'])
end)


test('Doc:writeToCache_AnnotObjOld()',
     function()
        local d = Doc:new()
        d.pictureCounter = 2
        local annotId = 3
        d:writeToCache_AnnotObjOld(annotId, 33)
        assert.same(33, d.cacheNew[2]['annots'][3]['annot_obj_old'])

        d.cacheOld = d.cacheNew
        d:writeToCache_AnnotObjOld(annotId, 33)
        assert.False(d.dirtyCache)
end)


test('Doc:writeToCache_AnnotObjNew()',
     function()
        local d = Doc:new()
        d.pictureCounter = 2
        local annotId = 3
        d:writeToCache_AnnotObjNew(annotId, 33)
        assert.same(33, d.cacheNew[2]['annots'][3]['annot_obj_new'])

        d.cacheOld = d.cacheNew
        d:writeToCache_AnnotObjNew(annotId, 33)
        assert.True(d.dirtyCache)
end)


test('Doc:readFromCache_AnnotObj()',
     function()
        local d = Doc:new()
        d.pictureCounter = 2
        local annotId = 3
        d:writeToCache_AnnotObj(annotId, 'foo', 33)
        d.cacheOld = d.cacheNew
        assert.same(33, d:readFromCache_AnnotObj(annotId, 'foo'))
end)


test('Doc:findFromCache_AnnotObjNew()',
     function()
        local d = Doc:new()
        d.pictureCounter = 1
        d:writeToCache_AnnotObj(1, 'annot_obj_old', 11)
        d:writeToCache_AnnotObj(1, 'annot_obj_new', 22)
        d:writeToCache_AnnotObj(2, 'annot_obj_old', 33)
        d:writeToCache_AnnotObj(2, 'annot_obj_new', 44)
        d.cacheOld = d.cacheNew
        assert.same(22, d:findFromCache_AnnotObjNew(11))
        assert.same(44, d:findFromCache_AnnotObjNew(33))
end)


test('Doc:warnIfCacheDirty()',
     function()
        local d = Doc:new()
        stub(pkg, 'warning')

        d.dirtyCache = false
        d:warnIfCacheDirty()
        assert.stub(pkg.warning).was_not_called()

        d.dirtyCache = true
        d:warnIfCacheDirty()
        assert.stub(pkg.warning).was_called()
end)


test('Doc:addDestTable()',
     function()
        local d = Doc:new()
        local filename = 'aaa.pdf'
        local data = {}
        d:addDestTable(filename, data)
        assert.same(data,
                        d.destBucket[filename])
        assert.same(nil,
                        d.destBucket['invalid_file_name'])

        local data = {'a', 'b', 'c'}
        d:addDestTable(filename, data)
        assert.same(data,
                        d.destBucket[filename])
end)


test('Doc:getDestTable()',
     function()
        local d = Doc:new()
        local filename = 'aaa.pdf'
        local data = {}
        d:addDestTable(filename, data)
        assert.same(data,
                        d:getDestTable(filename))
        assert.same(nil,
                        d:getDestTable('invalid_file_name'))

        local data = {'a', 'b', 'c'}
        d:addDestTable(filename, data)
        assert.same(data,
                        d:getDestTable(filename))
end)


test('Doc:serialize_()',
     function()
        local d = Doc:new()

        assert.same('""', d:serialize_(''))
        assert.same('"foo"', d:serialize_('foo'))
        assert.same('3', d:serialize_(3))
        assert.same(
           '{\n' ..
           '  [1] = "a",\n' ..
           '  [2] = "b",\n' ..
           '  [3] = "c",\n' ..
           '}',
           d:serialize_({'a', 'b', 'c'}))

        assert.same(
           '{\n' ..
           '  ["foo"] = {\n' ..
           '    [1] = "a",\n' ..
           '    [2] = "b",\n' ..
           '    [3] = "c",\n' ..
           '  },\n' ..
           '}',
           d:serialize_({foo = {'a', 'b', 'c'}}))

        assert.same(
           '{\n' ..
           '  ["foo"] = {\n' ..
           '    [1] = {\n' ..
           '      [1] = "a",\n' ..
           '      [2] = "b",\n' ..
           '      [3] = "c",\n' ..
           '    },\n' ..
           '    [2] = {\n' ..
           '      [1] = "u",\n' ..
           '      [2] = "v",\n' ..
           '      [3] = "w",\n' ..
           '    },\n' ..
           '  },\n' ..
           '}',
           d:serialize_({foo = { {'a', 'b', 'c'},
                                {'u', 'v', 'w'}}}))


        -- Type not implemented.
        assert.has_error(function() d:serialize_() end)
        assert.has_error(function() d:serialize_(true) end)
end)


test('Doc:indent()',
     function()
        local d = Doc:new()

        assert.same('foo', d:indent('foo'))
        assert.same('foo', d:indent('foo', 0))
        assert.same('  foo', d:indent('foo', 1))
        assert.same('    foo', d:indent('foo', 2))
end)


test('Doc:areEqual()',
     function()
        local d = Doc:new()

        assert.True(d:areEqual(nil, nil))
        assert.True(d:areEqual(true, true))
        assert.True(d:areEqual(false, false))
        assert.True(d:areEqual(1.23, 1.23))
        assert.True(d:areEqual('', ''))
        assert.True(d:areEqual('foo', 'foo'))
        assert.True(d:areEqual({'a', 'b', 'c'}, {'a', 'b', 'c'}))
        assert.True(d:areEqual({a = 1, b = 2}, {a = 1, b = 2}))
        assert.True(d:areEqual(
                       {a = {'a', 'b'}, b = { x = 1, y = { f = 1}}},
                       {a = {'a', 'b'}, b = { x = 1, y = { f = 1}}}))
        assert.False(d:areEqual(nil, 1))
        assert.False(d:areEqual(true, false))
        assert.False(d:areEqual(false, true))
        assert.False(d:areEqual(1.23, 4.56))
        assert.False(d:areEqual('', 'a'))
        assert.False(d:areEqual('foo', 'xxx'))
        assert.False(d:areEqual({'a', 'b', 'c'}, {'a', 'b', 'xx'}))
        assert.False(d:areEqual({'a', 'b', 'c'}, {'a', 'b'}))
        assert.False(d:areEqual({a = 1, b = 2}, {a = 1, b = 99}))
        assert.False(d:areEqual(
                       {a = {'a', 'b'}, b = { x = 1, y = { f = 1}}},
                       {a = {'a', 'b'}, b = { x = 1, y = { f = 99}}}))
end)


test('Doc:notEqual()',
     function()
        local d = Doc:new()
        
        assert.False(d:notEqual(nil, nil))
        assert.False(d:notEqual(true, true))
        assert.False(d:notEqual(false, false))
        assert.False(d:notEqual(1.23, 1.23))
        assert.False(d:notEqual('', ''))
        assert.False(d:notEqual('foo', 'foo'))
        assert.False(d:notEqual({'a', 'b', 'c'}, {'a', 'b', 'c'}))
        assert.False(d:notEqual({a = 1, b = 2}, {a = 1, b = 2}))
        assert.False(d:notEqual(
                       {a = {'a', 'b'}, b = { x = 1, y = { f = 1}}},
                       {a = {'a', 'b'}, b = { x = 1, y = { f = 1}}}))
        assert.True(d:notEqual(nil, 1))
        assert.True(d:notEqual(true, false))
        assert.True(d:notEqual(false, true))
        assert.True(d:notEqual(1.23, 4.56))
        assert.True(d:notEqual('', 'a'))
        assert.True(d:notEqual('foo', 'xxx'))
        assert.True(d:notEqual({'a', 'b', 'c'}, {'a', 'b', 'xx'}))
        assert.True(d:notEqual({'a', 'b', 'c'}, {'a', 'b'}))
        assert.True(d:notEqual({a = 1, b = 2}, {a = 1, b = 99}))
        assert.True(d:notEqual(
                       {a = {'a', 'b'}, b = { x = 1, y = { f = 1}}},
                       {a = {'a', 'b'}, b = { x = 1, y = { f = 99}}}))
end)


end) -- describe
