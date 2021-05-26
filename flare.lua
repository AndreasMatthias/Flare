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


---
-- Main module.
-- This module shall be required by LaTeX.
--
-- All other modules belonging to package ___Flare___ are loaded automatically.
-- @module Flare
local Flare = {}

Flare.Doc = require('flare-doc')
Flare.Page = require('flare-page')

return Flare
