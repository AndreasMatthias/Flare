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


---
-- Assisting type and definitions.
-- @module Types

local Types = {}

---
-- @type pdfarray
Types.pdfarray = {}

--- Creates a pdfarray.
-- It is an alias for a Lua table with its `type` field set to `array`.
-- @table t Initial table
function Types.pdfarray:new(t)
   t = t or {}
   setmetatable(t, self)
   self.__index = self
   self.type = 'array'
   return t
end


---
-- @type pdfdictionary
Types.pdfdictionary = {}

--- Creates a pdfdictionary.
-- It is an alias for a Lua table with its `type` field set to `dictionary`.
-- @table t Initial table
function Types.pdfdictionary:new(t)
   t = t or {}
   setmetatable(t, self)
   self.__index = self
   self.type = 'dictionary'
   return t
end


return Types

