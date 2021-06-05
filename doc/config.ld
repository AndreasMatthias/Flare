project = 'Flare'
title = 'Flare – Reference Documentation' -- html title

description = 'Flare – A plugin for `\\includegraphics`'
full_description=[[

Flare is a LaTeX package and an extension to `\includegraphics`. While
`\includegraphics` copies the content stream of a PDF page, Flare copies all
annotations belonging to this PDF page.

[Github Project Page](https://github.com/AndreasMatthias/Flare)
]]

file = {
   '../flare.lua',
   
   '../flare-pkg.lua',
   '../flare-types.lua',
   '../flare-luatex.lua',
   
   '../flare-doc.lua',
   '../flare-page.lua',

   '../flare-keyval.lua',
   '../flare-obj.lua',
   '../flare-annot.lua',
   '../flare-dest.lua',
   '../flare-action.lua',
}


all = true
merge = true
not_luadoc = true
no_lua_ref = true

--format = 'discount'
format = 'markdown'
style = true
template = true
backtick_references=false
topics = {'../README.md', }

-- Parameter types
tparam_alias('boolean', 'boolean')
tparam_alias('number', 'number')
tparam_alias('string', 'string')
tparam_alias('func',  'func')
tparam_alias('table', 'table')
tparam_alias('thread', 'thread')
tparam_alias('userdata', 'userdata')

tparam_alias('numstr', 'number|string')
tparam_alias('numbool', 'number|bool')
tparam_alias('strbool', 'string|boolean')
tparam_alias('keyidx', 'string|number')
tparam_alias('pdfe', 'pdfe')
tparam_alias('luatexnode','luatex_node')


--- Local Variables:
--- mode: lua
--- End:
