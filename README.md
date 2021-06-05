# Flare – LaTeX package
[![Build Status](https://travis-ci.com/AndreasMatthias/Flare.svg?branch=main)](https://travis-ci.com/AndreasMatthias/Flare)

Flare is a LaTeX package and an extension to `\includegraphics`.
While `\includegraphics` copies the content stream of a PDF page,
Flare copies all annotations belonging to this PDF page.


## Status of the Package
This project is still in development and not yet recommended for the
average end user. 


## Usage
Including `flare.sty` is all you need to do. By default Flare hooks
into `\includegraphics` and copies all annotations. 

    \documentclass{article}
    \usepackage{flare}
    \begin{document}

    \includegraphics{file.pdf}

    \end{document}

In addition to copying all annotations by default, Flare provides many options
to customize the copying process, like modifying or removing certain annotations.
Flare specific options shall be given in the optional argument of
`\includegraphics`.

    \includegraphics[<flare options>]{file.pdf}

See [examples/](examples) for more advanced examples.

Following annotations are implemented so far:

- Square, Circle
- TextMarkup (Highlight, Underline, Squiggly, StrikeOut)
- Text, FreeText
- Link
- Line
- Polygon, PolyLine
- Stamp
- Ink
- FileAttachment

## Requirements
Flare is designed for LuaTeX. Other TeX engines are not supported.


## Installation
Download
[flare.tds.zip](https://github.com/AndreasMatthias/Flare/releases/latest/download/flare.tds.zip),
a TDS-packaged ZIP file, and unpack it in your TDS tree (aka TEXMF tree).


## Copyright
© 2021 Andreas MATTHIAS


## License
LaTeX Project Public License, version 1.3c or later.
