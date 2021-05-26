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


describe('Testing flare_format-obj.lua:', function()

            
setup(function()
      -- clear cached versions
      package.loaded['flare'] = nil

      local function getobj(obj, key, valType)
         local key = key
         if type(key) == 'number' then
            -- pdfe.getXXX() functions have zero-based indexing!
            -- But this is a mocking environment, where we use lua-arrays
            -- instead of c-arrays. Thus we need to convert to one-based indexing.
            key = key + 1
         end
         local val = obj[key]
         if type(val) == valType then
            return val
         else
            return nil
         end
      end

      function pdfe.getboolean(obj, key)
         return getobj(obj, key, 'boolean')
      end

      function pdfe.getinteger(obj, key)
         return getobj(obj, key, 'number')
      end
        
      function pdfe.getnumber(obj, key)
         return getobj(obj, key, 'number')
      end

      function pdfe.getname(obj, key)
         return getobj(obj, key, 'string')
      end

      function pdfe.getstring(obj, key, unencode)
         local str = getobj(obj, key, 'string')
         if str == nil then
            return nil
         else
            if str:sub(1, 1) == '<' then
               return str:sub(2, -2), true
            else
               return str:sub(2, -2), false
            end
         end
      end

      local function len_table(t)
         local i = 0
         for _ in pairs(t) do i = i + 1 end
         return i
      end
      
      local function getfromDictOrArray(obj, key)
         local val = obj[key]

         if type(val) == 'boolean' then
            return 2, val, nil
         elseif type(val) == 'number' then
            if val == math.floor(val) then
               return 3, val, nil
            else
               return 4, val, nil
            end
         elseif type(val) == 'string' then
            if val:sub(1, 1) == '(' then
               return 6, val, false
            else
               return 6, val, true
            end
         elseif type(val) == 'table' then
            if val[1] then
               return 7, val, #val
            else
               return 8, val, len_table(val)
            end
         else
            -- name? not possible
            -- stream?  not possible
            -- references?  not possible
            error('Error in mocking function getfromDictOrArray()')
         end
      end

      function pdfe.getfromdictionary(obj, key)
         return getfromDictOrArray(obj, key)
      end
      
      function pdfe.getfromarray(obj, key)
         return getfromDictOrArray(obj, key)
      end

      function pdfe.dictionarytotable(obj)
         return obj
      end
      
      
      
      local getStringFromArrayOrDict = function(obj, key)
         if type(key) == 'number' then
            key = key + 1 -- pdfe-arrays are zero-based
         end
         local str = obj[key]
         if str then
            local hex = str:sub(1, 1) == '<'
            return str, hex
         else
            return nil
         end
      end


      function pdfe.type(obj)
         if obj[1] ~= nil then
            return 'pdfe.array'
         else
            return 'pdfe.dictionary'
         end
      end
      
     
      -- reload package
      flare = require('flare')
end)


test('Page:formatBoolean()', function()
        local page = Page:new(Doc:new())
        func = function(obj, key)
           return page:formatBoolean(obj, key)
        end

        -- dictionary
        assert.same(nil,
                        func({ Foo = 'wrong type' }, 'Foo'))
        assert.same('true',
                        func({ Foo = true }, 'Foo'))
        assert.same('false',
                        func({ Foo = false }, 'Foo'))
        -- array
        assert.same(nil,
                        func({ nil }, 1))
        assert.same('true',
                        func({ true }, 1))
        assert.same('false',
                        func({ true, false, true }, 2))
end)

test('Page:formatInteger()', function()
        local page = Page:new(Doc:new())
        func = function(obj, key)
           return page:formatInteger(obj, key)
        end

        -- dictionary
        assert.same(nil,
                        func({ Foo = nil }, 'Foo'))
        assert.same(nil,
                        func({ Foo = 'wrong type' }, 'Foo'))
        assert.same('123',
                        func({ Foo = 123 }, 'Foo'))
        -- array
        assert.same(nil,
                        func({ nil }, 1))
        assert.same(nil,
                        func({ 'wrong type' }, 1))
        assert.same('456',
                        func({ 123, 456, 789 }, 2))
end)


test('Page:formatNumber()', function()
        local page = Page:new(Doc:new())
        func = function(obj, key)
           return page:formatNumber(obj, key)
        end

        -- dictionary
        assert.same(nil,
                        func({ Foo = nil }, 'Foo'))
        assert.same(nil,
                        func({ Foo = 'wrong type' }, 'Foo'))
        assert.same('1.23',
                        func({ Foo = 1.23 }, 'Foo'))
        -- array
        assert.same(nil,
                        func({ nil }, 1))
        assert.same(nil,
                        func({ 'wrong type' }, 1))
        assert.same('4.56',
                        func({ 1.23, 4.56, 7.89 }, 2))
end)


test('Page:formatName()', function()
        local page = Page:new(Doc:new())
        func = function(obj, key)
           return page:formatName(obj, key)
        end
        -- dictionary
        assert.same(nil,
                        func({ nil }, 'Foo'))
        assert.same(nil,
                        func({ 123 }, 'Foo'))
        assert.same('/Bar',
                        func({ Foo = 'Bar' }, 'Foo'))
        -- array
        assert.same(nil,
                        func({ nil }, 1))
        assert.same(nil,
                        func({ 123 }, 1))
        assert.same('/Bar',
                        func({ 'Foo', 'Bar', 'Baz' }, 2))
end)


test('Page:formatString()', function()
        local page = Page:new(Doc:new())
        func = function(obj, key)
           return page:formatString(obj, key)
        end
        -- dictionary
        assert.same(nil,
                        func({ Foo = nil }, 'Foo'))
        assert.same(nil,
                        func({ Foo = 123 }, 'Foo'))
        assert.same('(Bar)',
                        func({ Foo = '(Bar)' }, 'Foo'))
        assert.same('<Bar>',
                        func({ Foo = '<Bar>' }, 'Foo'))
        assert.same('<FEFF004200610072>',
                        func({ Foo = '(\xfe\xff\x00\x42\x00\x61\x00\x72)' }, 'Foo'))
        -- array
        assert.same(nil,
                        func({ nil }, 1))
        assert.same(nil,
                        func({ 123 }, 1))
        assert.same('(Bar)',
                        func({ '', '(Bar)' }, 2))
        assert.same('<Bar>',
                        func({ '', '<Bar>' }, 2))
        assert.same('<FEFF004200610072>',
                        func({ '', '(\xfe\xff\x00\x42\x00\x61\x00\x72)' }, 2))
end)


test('Page:formatObj()', function()
        local page = Page:new(Doc:new())
        func = function(obj, key)
           return page:formatObj(obj, key)
        end
        -- obj from dictionary
        assert.same('true',
                        func({ Foo = true }, 'Foo'))
        assert.same('4',
                        func({ Foo = 4 }, 'Foo'))
        assert.same('1.23',
                        func({ Foo = 1.23 }, 'Foo'))
        assert.same('(foo)',
                        func({ Foo = '(foo)' }, 'Foo'))
        assert.same('<foo>',
                        func({ Foo = '<foo>' }, 'Foo'))
        assert.same({'1', '2', '3'},
                        func({ Foo = {1, 2, 3} }, 'Foo'))
        assert.same(
           {A = '1', B = '2'},
           func({Foo = {A = 1, B = 2}}, 'Foo'))
        
        -- obj from array
        assert.same('true',
                        func({ true }, 1))
        assert.same('2',
                        func({ 1, 2, 3 }, 2))
        assert.same('3.45',
                        func({ 1.23, 3.45, 7.89 }, 2))
        assert.same('(foo)',
                        func({ '(foo)' }, 1))
        assert.same('<foo>',
                        func({ '<foo>' }, 1))
        assert.same({'3', '4'},
                        func({ {1, 2}, {3, 4} }, 2))
        assert.same(
           {A = '1', B = '2'},
           func({{A = 1, B = 2}}, 1))
end)

end) --describe
