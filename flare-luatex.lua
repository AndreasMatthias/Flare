--
-- Copyright 2021-2023 Andreas MATTHIAS
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


--- Auxiliary functions for LuaTeX.
-- @module Luatex
local Luatex = {}

local pkg = require('flare-pkg')


--- Return the object number of a reference.
-- @pdfe t array or dictionary
-- @keyidx idx index (one-based) or key
-- @return Object number
function Luatex.getreference(t, idx)
   if pdfe.type(t) == 'pdfe.array' then
      local _, _, ref = pdfe.getfromarray(t, idx)
      return ref
   else
      local _, _, ref = pdfe.getfromdictionary(t, idx)
      return ref
   end
end


Luatex.pdfeObjType = {
   none = 0,
   null = 1,
   boolean = 2,
   integer = 3,
   number = 4,
   name = 5,
   string = 6,
   array = 7,
   dictionary = 8,
   stream = 9,
   reference = 10,
}


Luatex.pdfeDestType = {
   xyz   = 0,
   fit   = 1,
   fith  = 2,
   fitv  = 3,
   fitb  = 4,
   fitbh = 5,
   fitbv = 6,
   fitr  = 7,
}


--- Distributes work to `pdfe.getfromdictionary()` or `pdfe.getfromarray()`.
-- @pdfe obj Dictionary or array
-- @keyidx key Key or index (one-based indexing)
-- @return Type, value, detail
function Luatex.getfromobj(obj, key)
   local t = pdfe.type(obj)
   if t == 'pdfe.array' then
      return pdfe.getfromarray(obj, key)
   elseif t == 'pdfe.dictionary' then
      return pdfe.getfromdictionary(obj, key)
   else
      pkg.error('Internal error: Page:getfromobj()')
   end
end


return Luatex
