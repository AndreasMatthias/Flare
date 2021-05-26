-- New assertion: one_of
assert = require('luassert')
say = require('say')
local util = require('luassert.util')

--
-- one_of
--
function one_of(state, args)
   local elem = args[1]
   local array = args[2]
   for _, val in pairs(array) do
      if val == elem then
         return true
      end
   end
   return false
end

assert:register('assertion', 'one_of',
                one_of,
                'assertion.one_of.positive',
                'assertion.one_of.negative')

say:set('assertion.one_of.positive', 
        '\nExpected:\n%s\n' ..
        'To be one of:\n%s\n')

say:set('assertion.one_of.negative', 
        '\nExpected:\n%s\n' ..
        'Not to be one of:\n%s\n')

--
-- is_pdf_ref
--
function is_pdf_ref(state, args)
   local str = args[1]
   if str:find('^%d+ 0 R$') then
      return true
   else
      return false
   end
end

assert:register('assertion', 'is_pdf_ref',
                is_pdf_ref,
                'assertion.is_pdf_ref.positive',
                'assertion.is_pdf_ref.negative')

say:set('assertion.is_pdf_ref.positive',
        '\nExpected:\nPDF Reference' ..
        '\nPassed in:\n%s\n')

say:set('assertion.is_pdf_ref.negative',
        '\nExpected:\nNo PDF Refernce' ..
        '\nPassed in:\n%s\n')


--
-- is_pdf_ref_entry
--
function is_pdf_ref_entry(state, args)
   local str = args[1]
   if str:find('^/%w+ %d+ 0 R$') then
      return true
   else
      return false
   end
end

assert:register('assertion', 'is_pdf_ref_entry',
                is_pdf_ref_entry,
                'assertion.is_pdf_ref_entry.positive',
                'assertion.is_pdf_ref_entry.negative')

say:set('assertion.is_pdf_ref_entry.positive',
        '\nExpected:\nPDF Reference' ..
        '\nPassed in:\n%s\n')

say:set('assertion.is_pdf_ref_entry.negative',
        '\nExpected:\nNo PDF Refernce' ..
        '\nPassed in:\n%s\n')


--
-- This is a copy of util.deepcompare() which compares numbers
-- like this:
--     |t1 - t2| <= eps
--
function my_deepcompare(t1,t2,ignore_mt,cycles,thresh1,thresh2)
   local ty1 = type(t1)
   local ty2 = type(t2)
   -- non-table types can be directly compared
   if ty1 ~= 'table' or ty2 ~= 'table' then
      if ty1 == 'number' and
         ty2 == 'number' then
         local eps = 0.01
         return t1 <= t2 + eps and t1 >= t2 - eps 
      else
         return t1 == t2
      end
   end
   local mt1 = debug.getmetatable(t1)
   local mt2 = debug.getmetatable(t2)
   -- would equality be determined by metatable __eq?
   if mt1 and mt1 == mt2 and mt1.__eq then
      -- then use that unless asked not to
      if not ignore_mt then return t1 == t2 end
   else -- we can skip the deep comparison below if t1 and t2 share identity
      if rawequal(t1, t2) then return true end
   end

   -- handle recursive tables
   cycles = cycles or {{},{}}
   thresh1, thresh2 = (thresh1 or 1), (thresh2 or 1)
   cycles[1][t1] = (cycles[1][t1] or 0)
   cycles[2][t2] = (cycles[2][t2] or 0)
   if cycles[1][t1] == 1 or cycles[2][t2] == 1 then
      thresh1 = cycles[1][t1] + 1
      thresh2 = cycles[2][t2] + 1
   end
   if cycles[1][t1] > thresh1 and cycles[2][t2] > thresh2 then
      return true
   end

   cycles[1][t1] = cycles[1][t1] + 1
   cycles[2][t2] = cycles[2][t2] + 1

   for k1,v1 in next, t1 do
      local v2 = t2[k1]
      if v2 == nil then
         return false, {k1}
      end

      local same, crumbs = my_deepcompare(v1,v2,nil,cycles,thresh1,thresh2)
      if not same then
         crumbs = crumbs or {}
         table.insert(crumbs, k1)
         return false, crumbs
      end
   end
   for k2,_ in next, t2 do
      -- only check whether each element has a t1 counterpart, actual comparison
      -- has been done in first loop above
      if t1[k2] == nil then return false, {k2} end
   end

   cycles[1][t1] = cycles[1][t1] - 1
   cycles[2][t2] = cycles[2][t2] - 1

   return true
end

local function set_failure_message(state, message)
   if message ~= nil then
      state.failure_message = message
   end
end

local function nearly_same(state, arguments, level)
   local level = (level or 1) + 1
   local argcnt = arguments.n
   assert(argcnt > 1, say("assertion.internal.argtolittle", { "near", 2, tostring(argcnt) }), level)
   if type(arguments[1]) == 'table' and type(arguments[2]) == 'table' then
      local result, crumbs = my_deepcompare(arguments[1], arguments[2], true)
      -- switch arguments for proper output message
      util.tinsert(arguments, 1, util.tremove(arguments, 2))
      arguments.fmtargs = arguments.fmtargs or {}
      arguments.fmtargs[1] = { crumbs = crumbs }
      arguments.fmtargs[2] = { crumbs = crumbs }
      set_failure_message(state, arguments[3])
      return result
   end
   local result = arguments[1] == arguments[2]
   -- switch arguments for proper output message
   util.tinsert(arguments, 1, util.tremove(arguments, 2))
   set_failure_message(state, arguments[3])
   return result
end


assert:register('assertion', 'nearly_same', nearly_same,
                'assertion.same.positive', 'assertion.same.negative')
