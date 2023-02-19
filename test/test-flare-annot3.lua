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


function createTestFile(filename, body, pdfmanagement)
   infile = 'tmp_' .. filename .. '.tex'
   outfile = 'tmp_' .. filename .. '.pdf'
   logfile = 'tmp_' .. filename .. '.log'

   local fh = io.open('template.tex', 'r')
   local content = fh:read('a')
   content = content:gsub('<body>', body)
   fh:close()

   if pdfmanagement then
      content = content:gsub('<pdfmanagement>',
                             '\\RequirePackage{pdfmanagement-testphase}\n' ..
                             '\\DeclareDocumentMetadata{}')
   else
      content = content:gsub('<pdfmanagement>', '')
   end

   local fh =  io.open(infile, 'w')
   fh:write(content)
   fh:close()

   local cmd = string.format(
      'lualatex --interaction nonstopmode %s > /dev/null', infile)

   local ret = os.execute(cmd)
   if ret ~= 0 then
      os.execute(string.format('cat %s', logfile))
   end
   assert.same(0, ret)

   local ret = os.execute(cmd)
   if ret ~= 0 then
      os.execute(string.format('cat %', logfile))
   end
   assert.same(0, ret)

   return outfile
end


describe('Test flare-format-annot.lua:', function()

test('Page:getAnnotText()',
     function()
        local pdf_fn = createTestFile(
           'text',
           '\\fbox{\\includegraphics[scale=0.5]{pdf/text-01.pdf}}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local page_objnum = p:getPageObjNum(pagenum)

        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]

        assert.same('Annot', annot.Type)
        assert.same('Text', annot.Subtype)
        assert.same('annot-1', annot.NM)
        assert.same('test', annot.Contents)
        assert.same(28, annot.F)
        assert.same('D:20210427131639+02\'00', annot.M)
        assert.same('D:20210401000000', annot.CreationDate)
        assert.same('foo', annot.T)
        assert.same(true, annot.Open)
        assert.same('Help', annot.Name)
        assert.near(0.7, annot.CA, 0.01)
        assert.same(p:getPageObjNum(1), luatex.getreference(annot, 'P'))
        assert.same({0, 0, 1.5}, p:getArray(annot, 'Border'))
        assert.same({0, 1, 1}, p:getArray(annot, 'C'))
end)


test('Page:getAnnotFreeText()',
     function()
        local pdf_fn = createTestFile(
           'freetext',
           '\\fbox{\\includegraphics[scale=0.5]{pdf/freetext-01.pdf}}')

        local d = Doc:new()
        local p = Page:new(d)
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', 1)
        p:openFile()

        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]

        assert.same('Annot', annot.Type)
        assert.same('FreeText', annot.Subtype)
        assert.nearly_same(
           {100, 100, 0, 0},
           p:getAnnotFreeText_RD(annot, 'RD'), 0.1)
        assert.same('this is just a test', annot.Contents)
        assert.same('0 0 1 rg', annot.DA)
        assert.same(1, annot.Q)
        assert.nearly_same(
           {190.14, 494.74, 240.14, 607.24, 290.14, 607.24},
           p:getCoordinatesArray(annot, 'CL'), 0.1)
        assert.same('FreeTextCallout', annot.IT)
        assert.same(1, annot.BS.W)
        assert.same('D', annot.BS.S)
        assert.same({3, 1.5}, p:getArray(annot.BS, 'D'))
        assert.same('S', annot.BE.S)
        assert.same(1, annot.BE.I)

        assert.nearly_same({0.6}, {0.61})
end)


test('Page:getAnnotLink()',
     function()
        local pdf_fn = createTestFile(
           'link',
           '\\fbox{\\includegraphics[scale=0.5, page=1]{pdf/link-01.pdf}}\n\z
            \\newpage\n\z
            \\fbox{\\includegraphics[scale=0.5, page=2]{pdf/link-01.pdf}}'
        )

        local d = Doc:new()
        local p = Page:new(d)
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', 1)
        p:openFile()
        local pdf = pdfe.open(pdf_fn)

        local annot = pdfe.getpage(pdf, 1).Annots[1]
        assert.same('Link', annot.Subtype)
        assert.same('GoTo', annot.A.S)
        assert.same('pdf/link-01.pdf-section.2', annot.A.D)

        local annot = pdfe.getpage(pdf, 1).Annots[2]
        assert.same('Link', annot.Subtype)
        assert.same('Action', annot.A.Type)
        assert.same('http://www.ctan.org', annot.A.URI)
        assert.same('URI', annot.A.S)
        assert.same('I', annot.H)

        local annot = pdfe.getpage(pdf, 2).Annots[1]
        assert.same('Link', annot.Subtype)
        assert.same('GoTo', annot.A.S)
        assert.same('pdf/link-01.pdf-section.1', annot.A.D)

        -- TODO: Check, if destinations were set.

        -- TODO: Link shall not be created, if the corresponding
        --       destination page is missing. This needs to be fixed
        --       in the source code.
end)


test('Page:getAnnotHighlight()',
     function()
        local pdf_fn = createTestFile(
           'highlight',
           '\\fbox{\\includegraphics[scale=0.5]{pdf/highlight-01.pdf}}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local page_objnum = p:getPageObjNum(pagenum)

        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]

        assert.same('Annot', annot.Type)
        assert.same('Highlight', annot.Subtype)
        assert.same('annot-1', annot.NM)
        assert.same('contents', annot.Contents)
        assert.same('text', annot.T)
        assert.same(4, annot.F)
        assert.same('D:20210429202216+02\'00', annot.M)
        assert.same(1, annot.CA)
        assert.nearly_same(
           { 347.196, 629.420, 374.516, 629.420, 347.196, 622.590,
             374.516, 622.590, 202.691, 623.668, 245.108, 623.668,
             202.691, 616.478, 245.108, 616.478 },
           p:getCoordinatesArray(annot, 'QuadPoints'))
end)


test('Page:getAnnotSquiggly()',
     function()
        local pdf_fn = createTestFile(
           'squiggly',
           '\\fbox{\\includegraphics[scale=0.5]{pdf/squiggly-01.pdf}}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local page_objnum = p:getPageObjNum(pagenum)

        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]

        assert.same('Annot', annot.Type)
        assert.same('Squiggly', annot.Subtype)
        assert.same('annot-1', annot.NM)
        assert.same('contents', annot.Contents)
        assert.same('text', annot.T)
        assert.same(4, annot.F)
        assert.same('D:202105010000+02\'00', annot.M)
        assert.same(1, annot.CA)
        assert.nearly_same(
           { 347.19, 629.42, 374.51, 629.42, 347.19, 622.59,
             374.51, 622.59, 202.69, 623.66, 245.10, 623.66,
             202.69, 616.47, 245.10, 616.47 },
           p:getCoordinatesArray(annot, 'QuadPoints'))
end)


test('Page:getAnnotUnderline()',
     function()
        local pdf_fn = createTestFile(
           'underline',
           '\\includegraphics[scale=0.5]{pdf/underline-01.pdf}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local page_objnum = p:getPageObjNum(pagenum)

        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]

        assert.same('Annot', annot.Type)
        assert.same('Underline', annot.Subtype)
        assert.same('annot-1', annot.NM)
        assert.same('contents', annot.Contents)
        assert.same('text', annot.T)
        assert.same(4, annot.F)
        assert.same('D:202105010000+02\'00', annot.M)
        assert.same(1, annot.CA)
        assert.nearly_same(
           {346.79, 629.81, 374.11, 629.81, 346.79, 622.98,
            374.11, 622.98, 202.29, 624.06, 244.71, 624.06,
            202.29, 616.87, 244.71, 616.87 },
           p:getCoordinatesArray(annot, 'QuadPoints'))
end)


test('Page:getAnnotStrikeOut()',
     function()
        local pdf_fn = createTestFile(
           'strikeout',
           '\\includegraphics[scale=0.5]{pdf/strikeout-01.pdf}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local page_objnum = p:getPageObjNum(pagenum)

        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]

        assert.same('Annot', annot.Type)
        assert.same('StrikeOut', annot.Subtype)
        assert.same('annot-1', annot.NM)
        assert.same('contents', annot.Contents)
        assert.same('text', annot.T)
        assert.same(4, annot.F)
        assert.same('D:202105010000+02\'00', annot.M)
        assert.same(1, annot.CA)
        assert.nearly_same(
           {346.79, 629.81, 374.11, 629.81, 346.79, 622.98,
            374.11, 622.98, 202.29, 624.06, 244.71, 624.06,
            202.29, 616.87, 244.71, 616.87 },
           p:getCoordinatesArray(annot, 'QuadPoints'))
end)


test('Page:getAnnotLine()',
     function()
        local pdf_fn = createTestFile(
           'line',
           '\\includegraphics[scale=0.5]{pdf/line-01.pdf}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local page_objnum = p:getPageObjNum(pagenum)

        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]

        assert.same('Annot', annot.Type)
        assert.same('Line', annot.Subtype)
        assert.same('annot-1', annot.NM)
        assert.same('123 m', annot.Contents)
        assert.same('text', annot.T)
        assert.same(4, annot.F)
        assert.same('D:202105010000+02\'00', annot.M)
        assert.same(1, annot.CA)

        assert.nearly_same(
           {372.95, 650.28, 202.62, 582.72},
           p:getCoordinatesArray(annot, 'L'))
        assert.same({'/OpenArrow', '/OpenArrow'}, p:getArray(annot, 'LE'))
        assert.same(25, annot.LL)
        assert.same(10, annot.LLE)
        assert.same(3, annot.LLO)
        assert.same('Top', annot.CP)
        assert.same(true, annot.Cap)
        assert.same({10, 5}, p:getArray(annot, 'CO'))
end)


test('Page:getAnnotPolygon()',
     function()
        local pdf_fn = createTestFile(
           'polygon',
           '\\includegraphics[scale=0.5]{pdf/polygon-01.pdf}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]
        local page_objnum = p:getPageObjNum(pagenum)

        assert.same('Annot', annot.Type)
        assert.same('Polygon', annot.Subtype)
        assert.nearly_same({189.74, 595.14, 239.74, 620.14,
                            214.74, 645.14, 204.74, 645.14},
                           p:getArray(annot, 'Vertices'))
        assert.same({'/ClosedArrow', '/Circle'}, p:getArray(annot, 'LE'))
        assert.same('PolygonCloud', annot.IT)
        assert.nearly_same({0.9, 0.9, 0.1}, p:getArray(annot, 'IC'))
end)


test('Page:getAnnotPolyLine()',
     function()
        local pdf_fn = createTestFile(
           'polyline',
           '\\includegraphics[scale=0.5]{pdf/polyline-01.pdf}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]
        local page_objnum = p:getPageObjNum(pagenum)

        assert.same('Annot', annot.Type)
        assert.same('PolyLine', annot.Subtype)
        assert.nearly_same({189.74, 595.14, 239.74, 620.14,
                            214.74, 645.14, 204.74, 645.14},
                           p:getArray(annot, 'Vertices'))
        assert.same({'/ClosedArrow', '/Circle'}, p:getArray(annot, 'LE'))
        assert.same('PolygonCloud', annot.IT)
        assert.nearly_same({0.9, 0.9, 0.1}, p:getArray(annot, 'IC'))
end)


test('Page:getAnnotStamp()',
     function()
        local pdf_fn = createTestFile(
           'stamp',
           '\\includegraphics[scale=0.5]{pdf/stamp-01.pdf}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]
        local page_objnum = p:getPageObjNum(pagenum)

        assert.same('Annot', annot.Type)
        assert.same('Stamp', annot.Subtype)
        assert.same('Approved', annot.Name)
end)


test('Page:getAnnotInk()',
     function()
        local pdf_fn = createTestFile(
           'ink',
           '\\includegraphics[scale=0.5]{pdf/ink-01.pdf}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]
        local page_objnum = p:getPageObjNum(pagenum)

        assert.same('Annot', annot.Type)
        assert.same('Ink', annot.Subtype)
        assert.nearly_same(
           {{221.32, 637.97, 224.69, 643.27, 229.98, 651.47,
             233.91, 656.76, 237.75, 660.86, 241.67, 663.89,
             246.70, 666.28, 252.29, 667.43, 258.61, 667.36,
             265.77, 666.07, 271.62, 664.29, 276.23, 662.18,
             279.54, 659.77, 281.53, 657.08, 282.36, 653.89,
             282.05, 650.36, 280.59, 646.59, 278.15, 643.03,
             275.92, 640.23, 271.77, 635.53, 269.20, 633.83,
             266.34, 632.91, 262.31, 632.96, 257.35, 634.23,
             252.61, 636.39, 248.98, 639.07, 247.15, 641.38,
             246.42, 643.72, 246.82, 646.00, 248.34, 648.20,
             249.46, 649.21, 249.82, 649.30, 250.57, 649.20,
             251.32, 649.09, 251.71, 649.21}},
           p:getObj(annot, 'InkList'))
end)


test('Page:getAnnotFileAttachment()',
     function()
        --
        -- pdf/fileattachment-01.pdf
        --
        local pdf_fn = createTestFile(
           'fileattachment-01',
           '\\includegraphics[scale=0.5]{pdf/fileattachment-01.pdf}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]
        local page_objnum = p:getPageObjNum(pagenum)

        assert.same('Annot', annot.Type)
        assert.same('FileAttachment', annot.Subtype)
        assert.same(page_objnum, luatex.getreference(annot, 'P'))
        assert.same('PushPin', annot.Name)

        assert.same('Filespec', annot.FS.Type)
        assert.same('fileattachment.txt', annot.FS.F)

        --
        -- pdf/fileattachment-02.pdf
        --
        local pdf_fn = createTestFile(
           'fileattachment-02',
           '\\includegraphics[scale=0.5]{pdf/fileattachment-02.pdf}')

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]
        local page_objnum = p:getPageObjNum(pagenum)

        assert.same('Annot', annot.Type)
        assert.same('FileAttachment', annot.Subtype)
        assert.same(page_objnum, luatex.getreference(annot, 'P'))
        assert.same('PushPin', annot.Name)

        assert.same('Filespec', annot.FS.Type)
        assert.same('foo.txt', annot.FS.F)

        local stream, len = pdfe.readwholestream(annot.FS.EF.F)
        assert.same('This is an embedded file.\n' ..
                    'Just testing.\n\n',
                    stream)
        assert.same(41, len)

end)


test('Page:getAnnotWidget()',
     function()
        local pdf_fn = createTestFile(
           'widget',
           '\\includegraphics[scale=0.5]{pdf/widget-01.pdf}',
           true)

        local d = Doc:new()
        local p = Page:new(d)
        local pagenum = 1
        p:setGinKV('filename', pdf_fn)
        p:setGinKV('page', pagenum)
        p:openFile()
        local pdf = pdfe.open(pdf_fn)
        local annot = pdfe.getpage(pdf, 1).Annots[1]

        assert.same('Widget', annot.Subtype)
        assert.same('Off', annot.AS)

end)


end) -- describe
