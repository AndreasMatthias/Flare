local M = {}

--- Removes TeX-related command line arguments which are
-- unknown to lua-busted.
function M.remove_unknown_args()
   local len = #arg
   for i = 1, len do
      if arg[i]:match('^test') or -- file name of TeX file
         arg[i]:match('^%-%-shell%-escape') or
         arg[i]:match('^%-%-interaction') then
         arg[i] = nil
      end
      if arg[i] == '-lluacov' then
         arg[i] = nil
         --require_luacov = true
         require('luacov')
      end
   end

   local j = 0
   for i = 1, len do
      if arg[i] ~= nil then
         j = j + 1
         arg[j] = arg[i]
      end
   end

   for i = j + 1, len do
      arg[i] = nil
   end
end

return M
