(* vim: set sw=8 ts=8 et: *)
open Parser
open Tex
open Util


let tex_part = function
    HTMLABLE (_,t,_) -> t
  | HTMLABLEM (_,t,_) -> t
  | HTMLABLEC (_,t,_) -> t
  | MHTMLABLEC (_,t,_,_,_) -> t
  | HTMLABLE_BIG (t,_) -> t
  | TEX_ONLY t -> t

let rec render_tex = function
    TEX_FQ (a,b,c) -> (render_tex a) ^ "_{" ^ (render_tex  b) ^ "}^{" ^ (render_tex  c) ^ "}"
  | TEX_DQ (a,b) -> (render_tex a) ^ "_{" ^ (render_tex  b) ^ "}"
  | TEX_UQ (a,b) -> (render_tex a) ^ "^{" ^ (render_tex  b) ^ "}"
  | TEX_FQN (a,b) -> "_{" ^ (render_tex  a) ^ "}^{" ^ (render_tex  b) ^ "}"
  | TEX_DQN (a) -> "_{" ^ (render_tex  a) ^ "}"
  | TEX_UQN (a) -> "^{" ^ (render_tex  a) ^ "}"
  | TEX_LITERAL s -> tex_part s
  | TEX_FUN1 (f,a) -> "{" ^ f ^ " " ^ (render_tex a) ^ "}"
  | TEX_FUN1nb (f,a) -> f ^ " " ^ (render_tex a)
  | TEX_FUN1hl (f,_,a) -> "{" ^ f ^ " " ^ (render_tex a) ^ "}"
  | TEX_FUN1hf (f,_,a) -> "{" ^ f ^ " " ^ (render_tex a) ^ "}"
  | TEX_DECLh (f,_,a) -> "{" ^ f ^ "{" ^ (mapjoin render_tex a) ^ "}}"
  | TEX_FUN2 (f,a,b) -> "{" ^ f ^ " " ^ (render_tex a) ^ (render_tex b) ^ "}"
  | TEX_FUN2nb (f,a,b) -> f ^ (render_tex a) ^ (render_tex b)
  | TEX_FUN2h (f,_,a,b) -> "{" ^ f ^ " " ^ (render_tex a) ^ (render_tex b) ^ "}"
  | TEX_FUN2sq (f,a,b) -> "{" ^ f ^ "[ " ^ (render_tex a) ^ "]" ^ (render_tex b) ^ "}"
  | TEX_CURLY (tl) -> "{" ^ (mapjoin render_tex tl) ^ "}"
  | TEX_INFIX (s,ll,rl) -> "{" ^ (mapjoin render_tex ll) ^ " " ^ s ^ "" ^ (mapjoin render_tex rl) ^ "}"
  | TEX_INFIXh (s,_,ll,rl) -> "{" ^ (mapjoin render_tex ll) ^ " " ^ s ^ "" ^ (mapjoin render_tex rl) ^ "}"
  | TEX_BOX (bt,s) -> "{"^bt^"{" ^ s ^ "}}"
  | TEX_BIG (bt,d) -> "{"^bt^(tex_part d)^"}"
  | TEX_MATRIX (t,rows) -> "{\\begin{"^t^"}"^(mapjoine "\\\\" (mapjoine "&" (mapjoin render_tex)) rows)^"\\end{"^t^"}}"
  | TEX_LR (l,r,tl) -> "\\left "^(tex_part l)^(mapjoin render_tex tl)^"\\right "^(tex_part r)


(* Turn that into hash table lookup *)
exception Illegal_tex_function of string

let find cmd = match cmd with
  "\\AA"
  | "\\aleph"
  | "\\alpha"
  | "\\amalg"
  | "\\And"
  | "\\angle"
  | "\\approx"
  | "\\approxeq"
  | "\\ast"
  | "\\asymp"
  | "\\backepsilon"
  | "\\backprime"
  | "\\backsim"
  | "\\backsimeq"
  | "\\barwedge"
  | "\\Bbbk"
  | "\\because"
  | "\\beta"
  | "\\beth"
  | "\\between"
  | "\\bigcap"
  | "\\bigcirc"
  | "\\bigcup"
  | "\\bigodot"
  | "\\bigoplus"
  | "\\bigotimes"
  | "\\bigsqcup"
  | "\\bigstar"
  | "\\bigtriangledown"
  | "\\bigtriangleup"
  | "\\biguplus"
  | "\\bigvee"
  | "\\bigwedge"
  | "\\blacklozenge"
  | "\\blacksquare"
  | "\\blacktriangle"
  | "\\blacktriangledown"
  | "\\blacktriangleleft"
  | "\\blacktriangleright"
  | "\\bot"
  | "\\bowtie"
  | "\\Box"
  | "\\boxdot"
  | "\\boxminus"
  | "\\boxplus"
  | "\\boxtimes"
  | "\\bullet"
  | "\\bumpeq"
  | "\\Bumpeq"
  | "\\cap"
  | "\\Cap"
  | "\\cdot"
  | "\\cdots"
  | "\\centerdot"
  | "\\checkmark"
  | "\\chi"
  | "\\circ"
  | "\\circeq"
  | "\\circlearrowleft"
  | "\\circlearrowright"
  | "\\circledast"
  | "\\circledcirc"
  | "\\circleddash"
  | "\\circledS"
  | "\\clubsuit"
  | "\\colon"
  | "\\color"
  | "\\complement"
  | "\\cong"
  | "\\coprod"
  | "\\cup"
  | "\\Cup"
  | "\\curlyeqprec"
  | "\\curlyeqsucc"
  | "\\curlyvee"
  | "\\curlywedge"
  | "\\curvearrowleft"
  | "\\curvearrowright"
  | "\\dagger"
  | "\\daleth"
  | "\\dashv"
  | "\\ddagger"
  | "\\ddots"
  | "\\definecolor"
  | "\\delta"
  | "\\Delta"
  | "\\diagdown"
  | "\\diagup"
  | "\\diamond"
  | "\\Diamond"
  | "\\diamondsuit"
  | "\\digamma"
  | "\\displaystyle"
  | "\\div"
  | "\\divideontimes"
  | "\\doteq"
  | "\\doteqdot"
  | "\\dotplus"
  | "\\dots"
  | "\\dotsb"
  | "\\dotsc"
  | "\\dotsi"
  | "\\dotsm"
  | "\\dotso"
  | "\\doublebarwedge"
  | "\\downdownarrows"
  | "\\downharpoonleft"
  | "\\downharpoonright"
  | "\\ell"
  | "\\emptyset"
  | "\\epsilon"
  | "\\eqcirc"
  | "\\eqsim"
  | "\\eqslantgtr"
  | "\\eqslantless"
  | "\\equiv"
  | "\\eta"
  | "\\eth"
  | "\\exists"
  | "\\fallingdotseq"
  | "\\Finv"
  | "\\flat"
  | "\\forall"
  | "\\frown"
  | "\\Game"
  | "\\gamma"
  | "\\Gamma"
  | "\\geq"
  | "\\geqq"
  | "\\geqslant"
  | "\\gets"
  | "\\gg"
  | "\\ggg"
  | "\\gimel"
  | "\\gnapprox"
  | "\\gneq"
  | "\\gneqq"
  | "\\gnsim"
  | "\\gtrapprox"
  | "\\gtrdot"
  | "\\gtreqless"
  | "\\gtreqqless"
  | "\\gtrless"
  | "\\gtrsim"
  | "\\gvertneqq"
  | "\\hbar"
  | "\\heartsuit"
  | "\\hline"
  | "\\hookleftarrow"
  | "\\hookrightarrow"
  | "\\hslash"
  | "\\iff"
  | "\\iiiint"
  | "\\iiint"
  | "\\iint"
  | "\\Im"
  | "\\imath"
  | "\\implies"
  | "\\in"
  | "\\infty"
  | "\\injlim"
  | "\\int"
  | "\\intercal"
  | "\\iota"
  | "\\jmath"
  | "\\kappa"
  | "\\lambda"
  | "\\Lambda"
  | "\\land"
  | "\\lbrack"
  | "\\ldots"
  | "\\leftarrow"
  | "\\Leftarrow"
  | "\\leftarrowtail"
  | "\\leftharpoondown"
  | "\\leftharpoonup"
  | "\\leftleftarrows"
  | "\\leftrightarrow"
  | "\\Leftrightarrow"
  | "\\leftrightarrows"
  | "\\leftrightharpoons"
  | "\\leftrightsquigarrow"
  | "\\leftthreetimes"
  | "\\leq"
  | "\\leqq"
  | "\\leqslant"
  | "\\lessapprox"
  | "\\lessdot"
  | "\\lesseqgtr"
  | "\\lesseqqgtr"
  | "\\lessgtr"
  | "\\lesssim"
  | "\\limits"
  | "\\ll"
  | "\\Lleftarrow"
  | "\\lll"
  | "\\lnapprox"
  | "\\lneq"
  | "\\lneqq"
  | "\\lnot"
  | "\\lnsim"
  | "\\longleftarrow"
  | "\\Longleftarrow"
  | "\\longleftrightarrow"
  | "\\Longleftrightarrow"
  | "\\longmapsto"
  | "\\longrightarrow"
  | "\\Longrightarrow"
  | "\\looparrowleft"
  | "\\looparrowright"
  | "\\lor"
  | "\\lozenge"
  | "\\Lsh"
  | "\\ltimes"
  | "\\lVert"
  | "\\lvertneqq"
  | "\\mapsto"
  | "\\measuredangle"
  | "\\mho"
  | "\\mid"
  | "\\mod"
  | "\\models"
  | "\\mp"
  | "\\mu"
  | "\\multimap"
  | "\\nabla"
  | "\\natural"
  | "\\ncong"
  | "\\nearrow"
  | "\\neg"
  | "\\neq"
  | "\\nexists"
  | "\\ngeq"
  | "\\ngeqq"
  | "\\ngeqslant"
  | "\\ngtr"
  | "\\ni"
  | "\\nleftarrow"
  | "\\nLeftarrow"
  | "\\nleftrightarrow"
  | "\\nLeftrightarrow"
  | "\\nleq"
  | "\\nleqq"
  | "\\nleqslant"
  | "\\nless"
  | "\\nmid"
  | "\\nolimits"
  | "\\not"
  | "\\notin"
  | "\\nparallel"
  | "\\nprec"
  | "\\npreceq"
  | "\\nrightarrow"
  | "\\nRightarrow"
  | "\\nshortmid"
  | "\\nshortparallel"
  | "\\nsim"
  | "\\nsubseteq"
  | "\\nsubseteqq"
  | "\\nsucc"
  | "\\nsucceq"
  | "\\nsupseteq"
  | "\\nsupseteqq"
  | "\\ntriangleleft"
  | "\\ntrianglelefteq"
  | "\\ntriangleright"
  | "\\ntrianglerighteq"
  | "\\nu"
  | "\\nvdash"
  | "\\nVdash"
  | "\\nvDash"
  | "\\nVDash"
  | "\\nwarrow"
  | "\\odot"
  | "\\oint"
  | "\\omega"
  | "\\Omega"
  | "\\ominus"
  | "\\oplus"
  | "\\oslash"
  | "\\otimes"
  | "\\overbrace"
  | "\\overleftarrow"
  | "\\overleftrightarrow"
  | "\\overline"
  | "\\overrightarrow"
  | "\\P"
  | "\\pagecolor"
  | "\\parallel"
  | "\\partial"
  | "\\perp"
  | "\\phi"
  | "\\Phi"
  | "\\pi"
  | "\\Pi"
  | "\\pitchfork"
  | "\\pm"
  | "\\prec"
  | "\\precapprox"
  | "\\preccurlyeq"
  | "\\preceq"
  | "\\precnapprox"
  | "\\precneqq"
  | "\\precnsim"
  | "\\precsim"
  | "\\prime"
  | "\\prod"
  | "\\projlim"
  | "\\propto"
  | "\\psi"
  | "\\Psi"
  | "\\qquad"
  | "\\quad"
  | "\\rbrack"
  | "\\Re"
  | "\\rho"
  | "\\rightarrow"
  | "\\Rightarrow"
  | "\\rightarrowtail"
  | "\\rightharpoondown"
  | "\\rightharpoonup"
  | "\\rightleftarrows"
  | "\\rightrightarrows"
  | "\\rightsquigarrow"
  | "\\rightthreetimes"
  | "\\risingdotseq"
  | "\\Rrightarrow"
  | "\\Rsh"
  | "\\rtimes"
  | "\\rVert"
  | "\\S"
  | "\\scriptscriptstyle"
  | "\\scriptstyle"
  | "\\searrow"
  | "\\setminus"
  | "\\sharp"
  | "\\shortmid"
  | "\\shortparallel"
  | "\\sigma"
  | "\\Sigma"
  | "\\sim"
  | "\\simeq"
  | "\\smallfrown"
  | "\\smallsetminus"
  | "\\smallsmile"
  | "\\smile"
  | "\\spadesuit"
  | "\\sphericalangle"
  | "\\sqcap"
  | "\\sqcup"
  | "\\sqsubset"
  | "\\sqsubseteq"
  | "\\sqsupset"
  | "\\sqsupseteq"
  | "\\square"
  | "\\star"
  | "\\subset"
  | "\\Subset"
  | "\\subseteq"
  | "\\subseteqq"
  | "\\subsetneq"
  | "\\subsetneqq"
  | "\\succ"
  | "\\succapprox"
  | "\\succcurlyeq"
  | "\\succeq"
  | "\\succnapprox"
  | "\\succneqq"
  | "\\succnsim"
  | "\\succsim"
  | "\\sum"
  | "\\supset"
  | "\\Supset"
  | "\\supseteq"
  | "\\supseteqq"
  | "\\supsetneq"
  | "\\supsetneqq"
  | "\\surd"
  | "\\swarrow"
  | "\\tau"
  | "\\textstyle"
  | "\\textvisiblespace"
  | "\\therefore"
  | "\\theta"
  | "\\Theta"
  | "\\thickapprox"
  | "\\thicksim"
  | "\\times"
  | "\\to"
  | "\\top"
  | "\\triangle"
  | "\\triangledown"
  | "\\triangleleft"
  | "\\trianglelefteq"
  | "\\triangleq"
  | "\\triangleright"
  | "\\trianglerighteq"
  | "\\underbrace"
  | "\\underline"
  | "\\upharpoonleft"
  | "\\upharpoonright"
  | "\\uplus"
  | "\\upsilon"
  | "\\Upsilon"
  | "\\upuparrows"
  | "\\varepsilon"
  | "\\varinjlim"
  | "\\varkappa"
  | "\\varliminf"
  | "\\varlimsup"
  | "\\varnothing"
  | "\\varphi"
  | "\\varpi"
  | "\\varprojlim"
  | "\\varpropto"
  | "\\varrho"
  | "\\varsigma"
  | "\\varsubsetneq"
  | "\\varsubsetneqq"
  | "\\varsupsetneq"
  | "\\varsupsetneqq"
  | "\\vartheta"
  | "\\vartriangle"
  | "\\vartriangleleft"
  | "\\vartriangleright"
  | "\\vdash"
  | "\\Vdash"
  | "\\vDash"
  | "\\vdots"
  | "\\vee"
  | "\\veebar"
  | "\\vline"
  | "\\Vvdash"
  | "\\wedge"
  | "\\widehat"
  | "\\widetilde"
  | "\\wp"
  | "\\wr"
  | "\\xi"
  | "\\Xi"
  | "\\zeta"
  -> LITERAL ( TEX_ONLY( cmd ^ " " ) )

  | "\\big"
  | "\\Big"
  | "\\bigg"
  | "\\Bigg"
  | "\\biggl"
  | "\\Biggl"
  | "\\biggr"
  | "\\Biggr"
  | "\\bigl"
  | "\\Bigl"
  | "\\bigr"
  | "\\Bigr"
  -> BIG (  cmd ^ " " )

  | "\\backslash"
  | "\\downarrow"
  | "\\Downarrow"
  | "\\langle"
  | "\\lbrace"
  | "\\lceil"
  | "\\lfloor"
  | "\\llcorner"
  | "\\lrcorner"
  | "\\rangle"
  | "\\rbrace"
  | "\\rceil"
  | "\\rfloor"
  | "\\rightleftharpoons"
  | "\\twoheadleftarrow"
  | "\\twoheadrightarrow"
  | "\\ulcorner"
  | "\\uparrow"
  | "\\Uparrow"
  | "\\updownarrow"
  | "\\Updownarrow"
  | "\\urcorner"
  | "\\Vert"
  | "\\vert"
  -> DELIMITER( TEX_ONLY( cmd ^ " ") )

  | "\\acute"
  | "\\bar"
  | "\\bcancel"
  | "\\bmod"
  | "\\boldsymbol"
  | "\\breve"
  | "\\cancel"
  | "\\check"
  | "\\ddot"
  | "\\dot"
  | "\\emph"
  | "\\grave"
  | "\\hat"
  | "\\mathbb"
  | "\\mathbf"
  | "\\mathbin"
  | "\\mathcal"
  | "\\mathclose"
  | "\\mathfrak"
  | "\\mathit"
  | "\\mathop"
  | "\\mathopen"
  | "\\mathord"
  | "\\mathpunct"
  | "\\mathrel"
  | "\\mathrm"
  | "\\mathsf"
  | "\\mathtt"
  | "\\operatorname"
  | "\\pmod"
  | "\\sqrt"
  | "\\textbf"
  | "\\textit"
  | "\\textrm"
  | "\\textsf"
  | "\\texttt"
  | "\\tilde"
  | "\\vec"
  | "\\xcancel"
  | "\\xleftarrow"
  | "\\xrightarrow"
  -> FUN_AR2( cmd ^ " " )

  | "\\binom"
  | "\\cancelto"
  | "\\cfrac"
  | "\\dbinom"
  | "\\dfrac"
  | "\\frac"
  | "\\overset"
  | "\\stackrel"
  | "\\tbinom"
  | "\\tfrac"
  | "\\underset"
  -> FUN_AR1( cmd ^ " " )

  | "\\atop"
  | "\\choose"
  | "\\over"
  -> FUN_INFIX( cmd ^ " " )

  | "\\Coppa"
  | "\\coppa"
  | "\\Digamma"
  | "\\euro"
  | "\\geneuro"
  | "\\geneuronarrow"
  | "\\geneurowide"
  | "\\Koppa"
  | "\\koppa"
  | "\\officialeuro"
  | "\\Sampi"
  | "\\sampi"
  | "\\Stigma"
  | "\\stigma"
  | "\\varstigma"
  -> LITERAL ( TEX_ONLY( "\\mbox{" ^ cmd ^ "} " ) )

  | "\\C"
  | "\\H"
  | "\\N"
  | "\\Q"
  | "\\R"
  | "\\Z"
  -> LITERAL ( TEX_ONLY( "\\mathbb{" ^ cmd ^ "} " ) )

  | "\\rm"
  | "\\it"
  | "\\cal"
  | "\\bf" 
  -> DECL (cmd ^ " ")

  | "\\sideset"         -> FUN_AR2nb "\\sideset "
  | "\\left"             -> LEFT
  | "\\right"            -> RIGHT

(* Non Standard TeX Syntax! Mediawiki Specific Syntax follows:*)

  | "\\darr" -> DELIMITER( TEX_ONLY( "\\downarrow" ^ " " ) )
  | "\\dArr" -> DELIMITER( TEX_ONLY( "\\Downarrow" ^ " " ) )
  | "\\Darr" -> DELIMITER( TEX_ONLY( "\\Downarrow" ^ " " ) )
  | "\\lang" -> DELIMITER( TEX_ONLY( "\\langle" ^ " " ) )
  | "\\rang" -> DELIMITER( TEX_ONLY( "\\rangle" ^ " " ) )
  | "\\uarr" -> DELIMITER( TEX_ONLY( "\\uparrow" ^ " " ) )
  | "\\uArr" -> DELIMITER( TEX_ONLY( "\\Uparrow" ^ " " ) )
  | "\\Uarr" -> DELIMITER( TEX_ONLY( "\\Uparrow" ^ " " ) )

  | "\\Bbb" -> FUN_AR2( "\\mathbb" ^ " " )
  | "\\bold" -> FUN_AR2( "\\mathbf" ^ " " )

  | "\\alef" -> LITERAL ( TEX_ONLY( "\\aleph" ^ " " ) )
  | "\\alefsym" -> LITERAL ( TEX_ONLY( "\\aleph" ^ " " ) )
  | "\\Alpha" -> LITERAL ( TEX_ONLY( "\\mathrm{A}" ^ " " ) )
  | "\\and" -> LITERAL ( TEX_ONLY( "\\land" ^ " " ) )
  | "\\ang" -> LITERAL ( TEX_ONLY( "\\angle" ^ " " ) )
  | "\\Beta" -> LITERAL ( TEX_ONLY( "\\mathrm{B}" ^ " " ) )
  | "\\bull" -> LITERAL ( TEX_ONLY( "\\bullet" ^ " " ) )
  | "\\Chi" -> LITERAL ( TEX_ONLY( "\\mathrm{X}" ^ " " ) )
  | "\\clubs" -> LITERAL ( TEX_ONLY( "\\clubsuit" ^ " " ) )
  | "\\cnums" -> LITERAL ( TEX_ONLY( "\\mathbb{C}" ^ " " ) )
  | "\\Complex" -> LITERAL ( TEX_ONLY( "\\mathbb{C}" ^ " " ) )
  | "\\Dagger" -> LITERAL ( TEX_ONLY( "\\ddagger" ^ " " ) )
  | "\\diamonds" -> LITERAL ( TEX_ONLY( "\\diamondsuit" ^ " " ) )
  | "\\Doteq" -> LITERAL ( TEX_ONLY( "\\doteqdot" ^ " " ) )
  | "\\doublecap" -> LITERAL ( TEX_ONLY( "\\Cap" ^ " " ) )
  | "\\doublecup" -> LITERAL ( TEX_ONLY( "\\Cup" ^ " " ) )
  | "\\empty" -> LITERAL ( TEX_ONLY( "\\emptyset" ^ " " ) )
  | "\\Epsilon" -> LITERAL ( TEX_ONLY( "\\mathrm{E}" ^ " " ) )
  | "\\Eta" -> LITERAL ( TEX_ONLY( "\\mathrm{H}" ^ " " ) )
  | "\\exist" -> LITERAL ( TEX_ONLY( "\\exists" ^ " " ) )
  | "\\ge" -> LITERAL ( TEX_ONLY( "\\geq" ^ " " ) )
  | "\\gggtr" -> LITERAL ( TEX_ONLY( "\\ggg" ^ " " ) )
  | "\\hAar" -> LITERAL ( TEX_ONLY( "\\Leftrightarrow" ^ " " ) )
  | "\\harr" -> LITERAL ( TEX_ONLY( "\\leftrightarrow" ^ " " ) )
  | "\\Harr" -> LITERAL ( TEX_ONLY( "\\Leftrightarrow" ^ " " ) )
  | "\\hearts" -> LITERAL ( TEX_ONLY( "\\heartsuit" ^ " " ) )
  | "\\image" -> LITERAL ( TEX_ONLY( "\\Im" ^ " " ) )
  | "\\infin" -> LITERAL ( TEX_ONLY( "\\infty" ^ " " ) )
  | "\\Iota" -> LITERAL ( TEX_ONLY( "\\mathrm{I}" ^ " " ) )
  | "\\isin" -> LITERAL ( TEX_ONLY( "\\in" ^ " " ) )
  | "\\Kappa" -> LITERAL ( TEX_ONLY( "\\mathrm{K}" ^ " " ) )
  | "\\larr" -> LITERAL ( TEX_ONLY( "\\leftarrow" ^ " " ) )
  | "\\Larr" -> LITERAL ( TEX_ONLY( "\\Leftarrow" ^ " " ) )
  | "\\lArr" -> LITERAL ( TEX_ONLY( "\\Leftarrow" ^ " " ) )
  | "\\le" -> LITERAL ( TEX_ONLY( "\\leq" ^ " " ) )
  | "\\lrarr" -> LITERAL ( TEX_ONLY( "\\leftrightarrow" ^ " " ) )
  | "\\Lrarr" -> LITERAL ( TEX_ONLY( "\\Leftrightarrow" ^ " " ) )
  | "\\lrArr" -> LITERAL ( TEX_ONLY( "\\Leftrightarrow" ^ " " ) )
  | "\\Mu" -> LITERAL ( TEX_ONLY( "\\mathrm{M}" ^ " " ) )
  | "\\natnums" -> LITERAL ( TEX_ONLY( "\\mathbb{N}" ^ " " ) )
  | "\\ne" -> LITERAL ( TEX_ONLY( "\\neq" ^ " " ) )
  | "\\Nu" -> LITERAL ( TEX_ONLY( "\\mathrm{N}" ^ " " ) )
  | "\\O" -> LITERAL ( TEX_ONLY( "\\emptyset" ^ " " ) )
  | "\\omicron" -> LITERAL ( TEX_ONLY( "\\mathrm{o}" ^ " " ) )
  | "\\Omicron" -> LITERAL ( TEX_ONLY( "\\mathrm{O}" ^ " " ) )
  | "\\or" -> LITERAL ( TEX_ONLY( "\\lor" ^ " " ) )
  | "\\part" -> LITERAL ( TEX_ONLY( "\\partial" ^ " " ) )
  | "\\plusmn" -> LITERAL ( TEX_ONLY( "\\pm" ^ " " ) )
  | "\\rarr" -> LITERAL ( TEX_ONLY( "\\rightarrow" ^ " " ) )
  | "\\Rarr" -> LITERAL ( TEX_ONLY( "\\Rightarrow" ^ " " ) )
  | "\\rArr" -> LITERAL ( TEX_ONLY( "\\Rightarrow" ^ " " ) )
  | "\\real" -> LITERAL ( TEX_ONLY( "\\Re" ^ " " ) )
  | "\\reals" -> LITERAL ( TEX_ONLY( "\\mathbb{R}" ^ " " ) )
  | "\\Reals" -> LITERAL ( TEX_ONLY( "\\mathbb{R}" ^ " " ) )
  | "\\restriction" -> LITERAL ( TEX_ONLY( "\\upharpoonright" ^ " " ) )
  | "\\Rho" -> LITERAL ( TEX_ONLY( "\\mathrm{P}" ^ " " ) )
  | "\\sdot" -> LITERAL ( TEX_ONLY( "\\cdot" ^ " " ) )
  | "\\sect" -> LITERAL ( TEX_ONLY( "\\S" ^ " " ) )
  | "\\spades" -> LITERAL ( TEX_ONLY( "\\spadesuit" ^ " " ) )
  | "\\sub" -> LITERAL ( TEX_ONLY( "\\subset" ^ " " ) )
  | "\\sube" -> LITERAL ( TEX_ONLY( "\\subseteq" ^ " " ) )
  | "\\supe" -> LITERAL ( TEX_ONLY( "\\supseteq" ^ " " ) )
  | "\\Tau" -> LITERAL ( TEX_ONLY( "\\mathrm{T}" ^ " " ) )
  | "\\thetasym" -> LITERAL ( TEX_ONLY( "\\vartheta" ^ " " ) )
  | "\\varcoppa" -> LITERAL ( TEX_ONLY( "\\mbox{coppa}" ^ " " ) )
  | "\\weierp" -> LITERAL ( TEX_ONLY( "\\wp" ^ " " ) )
  | "\\Zeta" -> LITERAL ( TEX_ONLY( "\\mathrm{Z}" ^ " " ) )

  | "\\text"
  | "\\mbox"
  | "\\vbox"
  | "\\hbox"
  -> raise (Failure ("malformatted " ^ cmd))

  | s -> raise (Illegal_tex_function s)
