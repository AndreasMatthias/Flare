# Flare – LaTeX package
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


## Requirements
Flare is designed for LuaTeX. Other TeX engines are not supported.


## Installation
Unpack the TDS-ZIP file in the TDS tree.


## Feedback
Bug reports and feedback are welcome and should be made at
<https://github.com/AndreasMatthias/Flare>.


## Copyright
© 2021 Andreas MATTHIAS


## License
LaTeX Project Public License, version 1.3c or later.
