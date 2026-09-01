; extends

; Render inline `$...$` and display `$$...$$` LaTeX math as images.
;
; snacks.image ships a markdown query, but it only matches ```math fenced
; blocks -- plain `$...$` in markdown is not captured at all. This adds it.
;
; `image.lang` rather than `injection.language`: snacks picks its transform
; with `M.transforms[ctx.lang]` (snacks/image/doc.lua), and `image.lang` is
; the snacks-specific key it checks first. Using `injection.language` would
; also work, but it asks treesitter to parse a latex injection, and the
; latex parser is not installed here.
;
; The whole `latex_block` is captured as the content, delimiters included --
; the same shape as snacks' own typst query. Its latex transform strips the
; leading/trailing `$`/`$$` itself and rewraps the body in `\[ ... \]`.
(latex_block
  (#set! image.lang "latex")
  (#set! image.ext "math.tex")
) @image.content @image
