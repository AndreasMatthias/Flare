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


--- Miscellaneous functions.
-- @module Pkg
local Pkg = {}

info = {
   name = 'Flare',
   version = '0.1',
   date = '2023-02-19',
   author = 'Andreas Matthias',
   license = 'The LaTeX Project Public License (LPPL), version 1.3c',
   description = 'Plugin for \\includegraphics copying PDF annotations.',
}

Pkg.error, Pkg.warning, Pkg.info, Pkg.log = luatexbase.provides_module(info)


--- Prints a warning.
function Pkg.support()
   Pkg.warning('Feature not supported yet. Please report this and \z
                include a minimal example and the original PDF. \z
                Warning')
   print(debug.traceback())
end


--- Prints a warning.
function Pkg.bugs()
   Pkg.warning('Please report this issue and include a minimal example \z
                and the original PDF. Warning')
   print(debug.traceback())
end


--- Pretty printting of tables.
-- @table t
function Pkg.pp(t)
   serpent = require('serpent')
   if pdfe.type(t) == 'pdfe.dictionary' then
      io.write('pdfe.dictionary: ')
      t = pdfe.dictionarytotable(t)
   elseif pdfe.type(t) == 'pdfe.array' then
      io.write('pdfe.array: ')
      t = pdfe.arraytotable(t)
   end
   print(serpent.block(t))
end


return Pkg
