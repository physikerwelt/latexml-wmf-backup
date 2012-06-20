function load_examples(examples) {
examples['clc'] = ["Behold: $\\int_0^\\infty x\\,dx$ is an integral"];

examples['eqn'] = ['\\section{The Lorenz Equations}',
'\\[\\begin{aligned}',
'\\dot{x} & = \\sigma(y-x) \\\\',
'\\dot{y} & = \\rho x - y - xz \\\\',
'\\dot{z} & = -\\beta z + xy',
'\\end{aligned} \\]',
'','\\section{The Cauchy-Schwarz Inequality}',
'\\[ \\left( \\sum_{k=1}^n a_k b_k \\right)^2 \\leq \\left( \\sum_{k=1}^n a_k^2 \\right) \\left( \\sum_{k=1}^n b_k^2 \\right) \\]',
'\\section{A Cross Product Formula}',
'\\[\\mathbf{V}_1 \\times \\mathbf{V}_2 =  \\begin{vmatrix}',
'\\mathbf{i} & \\mathbf{j} & \\mathbf{k} \\\\',
'\\frac{\\partial X}{\\partial u} &  \\frac{\\partial Y}{\\partial u} & 0 \\\\',
'\\frac{\\partial X}{\\partial v} &  \\frac{\\partial Y}{\\partial v} & 0',
'\\end{vmatrix}  \\]','',
'The probability of getting $\\(k\\)$ heads when flipping $\\(n\\)$ coins is: ',
'\\[P(E) = {n \\choose k} p^k (1-p)^{ n-k} \\]',
'','\\section{An Identity of Ramanujan}',
'\\[ \\frac{1}{\\Bigl(\\sqrt{\\phi \\sqrt{5}}-\\phi\\Bigr) e^{\\frac25 \\pi}} =',
'1+\\frac{e^{-2\\pi}} {1+\\frac{e^{-4\\pi}} {1+\\frac{e^{-6\\pi}}',
'{1+\\frac{e^{-8\\pi}} {1+\\ldots} } } } \\]',
'','\\section{A Rogers-Ramanujan Identity}',
'\\[  1 +  \\frac{q^2}{(1-q)}+\\frac{q^6}{(1-q)(1-q^2)}+\\cdots =',
'\\prod_{j=0}^{\\infty}\\frac{1}{(1-q^{5j+2})(1-q^{5j+3})},',
'\\quad\\quad \\text{for} |q|<1. \\]',
'','\\section{Maxwell\'s Equations}',
'\\[  \\begin{aligned}',
'\\nabla \\times \\vec{\\mathbf{B}} -\\, \\frac1c\\, \\frac{\\partial\\vec{\\mathbf{E}}}{\\partial t} & = \\frac{4\\pi}{c}\\vec{\\mathbf{j}} \\\\',
'\\nabla \\cdot \\vec{\\mathbf{E}} & = 4 \\pi \\rho \\\\',
'\\nabla \\times \\vec{\\mathbf{E}}\\, +\\, \\frac1c\\, \\frac{\\partial\\vec{\\mathbf{B}}}{\\partial t} & = \\vec{\\mathbf{0}} \\\\',
'',
'\\nabla \\cdot \\vec{\\mathbf{B}} & = 0 \\end{aligned}\\]',
'','','Source: \\url{http://www.mathjax.org/demos/tex-samples/}'].join('\n');

examples['nar'] = ["\\section{One}",
                   "\\subsection{One-one}",
                   "\\paragraph{Para}Hello World!"].join('\n');
examples['tbl'] = ['\\section{First Example}','\\begin{tabular}{|c|ccc|r|}',
'	\\hline',
'$k$ &  $x_1^k$    &   $x_2^k$  & $x_3^k$   & remarks  \\\\',
'	\\hline',
'0   & -0.3 & 0.6 & 0.7  &  \\\\',
'1   & 0.47102965 & 0.04883157 & -0.53345964  & *\\\\',
'2   & 0.49988691 & 0.00228830 & -0.52246185 & $s_3$ \\\\',
'3   & 0.49999976 & 0.00005380 & -0.52365600  & \\\\',
'4   & 0.5 & 0.00000307 & -0.52359743  & $\\epsilon < 10^{-5}$ \\\\',
'7   & 0.5 & 0 & -0.52359878  & $\\epsilon < \\xi $ \\\\',
'	\\hline',
'\\end{tabular}',
'\\section{Second Example}',
'\\begin{tabular}{|c|r@{.}lr@{.}lr@{.}l||r|}',
'	\\hline',
'\\multicolumn{8}{|c|}',
'	{Iteration $k$ of $f(x_n)$} \\\\',
'\\textbf{\\em k}',
'	& \\multicolumn{2}{c}{$x_1^k$}',
'	& \\multicolumn{2}{c}{$x_2^k$}',
'	& \\multicolumn{2}{c||}{$x_3^k$}',
'	& remarks \\\\ \\hline \\hline',
'0   & -0&3                 & 0&6                 &  0&7   & - \\\\',
'1   &  0&47102965 & 0&04883157 & -0&53345964  & $\\delta<\\epsilon$ \\\\',
'2   &  0&49988691 & 0&00228830 & -0&52246185  & $\\delta < \\varepsilon$ \\\\',
'3   &  0&49999976 & 0&00005380 & -0&523656   &   $N$ \\\\',
'4   &  0&5                 & 0&00000307 & -0&52359743  & \\\\',
'$\\vdots$	& \\multicolumn{2}{c}{$\\vdots$}',
'	& \\multicolumn{2}{c}{$\\ddots$}',
'	& \\multicolumn{2}{c||}{$\\vdots$}  & \\\\',
'7   &  0&5   & 0&0    & \\textbf{-0}&\\textbf{52359878}',
'		 & $\\delta<10^{-8}$ \\\\ \\hline',
'\\end{tabular}',
'','Source: \\url{http://amath.colorado.edu/documentation/LaTeX/reference/tables/}'].join('\n');


examples['clr'] = [
'The 68 standard colors known to dvips\\vspace{0.5ex}',
'\\begin{center}\\begin{tabular}{|l|l|l|l|}',
'\\hline',
'{\\color{Apricot} Apricot}&',
'{\\color{Aquamarine} Aquamarine}&',
'{\\color{Bittersweet} Bittersweet}&',
'{\\color{Black} Black}\\\\ \\hline',
'{\\color{Blue} Blue}&',
'{\\color{BlueGreen} BlueGreen}&',
'{\\color{BlueViolet} BlueViolet}&',
'{\\color{BrickRed} BrickRed}\\\\ \\hline',
'{\\color{Brown} Brown}&',
'{\\color{BurntOrange} BurntOrange}&',
'{\\color{CadetBlue} CadetBlue}&',
'{\\color{CarnationPink} CarnationPink}\\\\ \\hline',
'{\\color{Cerulean} Cerulean}&',
'{\\color{CornflowerBlue} CornflowerBlue}&',
'{\\color{Cyan} Cyan}&',
'{\\color{Dandelion} Dandelion}\\\\ \\hline',
'{\\color{DarkOrchid} DarkOrchid}&',
'{\\color{Emerald} Emerald}&',
'{\\color{ForestGreen} ForestGreen}&',
'{\\color{Fuchsia} Fuchsia}\\\\ \\hline',
'{\\color{Goldenrod} Goldenrod}&',
'{\\color{Gray} Gray}&',
'{\\color{Green} Green}&',
'{\\color{GreenYellow} GreenYellow}\\\\ \\hline',
'{\\color{JungleGreen} JungleGreen}&',
'{\\color{Lavender} Lavender}&',
'{\\color{LimeGreen} LimeGreen}&',
'{\\color{Magenta} Magenta}\\\\ \\hline',
'{\\color{Mahogany} Mahogany}&',
'{\\color{Maroon} Maroon}&',
'{\\color{Melon} Melon}&',
'{\\color{MidnightBlue} MidnightBlue}\\\\ \\hline',
'{\\color{Mulberry} Mulberry}&',
'{\\color{NavyBlue} NavyBlue}&',
'{\\color{OliveGreen} OliveGreen}&',
'{\\color{Orange} Orange}\\\\ \\hline',
'{\\color{OrangeRed} OrangeRed}&',
'{\\color{Orchid} Orchid}&',
'{\\color{Peach} Peach}&',
'{\\color{Periwinkle} Periwinkle}\\\\ \\hline',
'{\\color{PineGreen} PineGreen}&',
'{\\color{Plum} Plum}&',
'{\\color{ProcessBlue} ProcessBlue}&',
'{\\color{Purple} Purple}\\\\ \\hline',
'{\\color{RawSienna} RawSienna}&',
'{\\color{Red} Red}&',
'{\\color{RedOrange} RedOrange}&',
'{\\color{RedViolet} RedViolet}\\\\ \\hline',
'{\\color{Rhodamine} Rhodamine}&',
'{\\color{RoyalBlue} RoyalBlue}&',
'{\\color{RoyalPurple} RoyalPurple}&',
'{\\color{RubineRed} RubineRed}\\\\ \\hline',
'{\\color{Salmon} Salmon}&',
'{\\color{SeaGreen} SeaGreen}&',
'{\\color{Sepia} Sepia}&',
'{\\color{SkyBlue} SkyBlue}\\\\ \\hline',
'{\\color{SpringGreen} SpringGreen}&',
'{\\color{Tan} Tan}&',
'{\\color{TealBlue} TealBlue}&',
'{\\color{Thistle} Thistle}\\\\ \\hline',
'{\\color{Turquoise} Turquoise}&',
'{\\color{Violet} Violet}&',
'{\\color{VioletRed} VioletRed}&',
'{\\color{White} White}\\\\ \\hline',
'{\\color{WildStrawberry} WildStrawberry}&',
'{\\color{Yellow} Yellow}&',
'{\\color{YellowGreen} YellowGreen}&',
'{\\color{YellowOrange} YellowOrange}\\\\ \\hline',
'\\end{tabular}',
'\\end{center}',
'Source: \\url{http://people.oregonstate.edu/~peterseb/tex/samples/color-package.html}'].join('\n');


examples['xii'] = ['Source: \\url{http://ctan.org/pkg/xii}','','',
'\\let~\\catcode~`76~`A13~`F1~`j00~`P2jdefA71F~`7113jdefPALLF',
'PA\'\'FwPA;;FPAZZFLaLPA//71F71iPAHHFLPAzzFenPASSFthP;A$$FevP',
'A@@FfPARR717273F737271P;ADDFRgniPAWW71FPATTFvePA**FstRsamP',
'AGGFRruoPAqq71.72.F717271PAYY7172F727171PA??Fi*LmPA&&71jfi',
'Fjfi71PAVVFjbigskipRPWGAUU71727374 75,76Fjpar71727375Djifx',
':76jelse&U76jfiPLAKK7172F71l7271PAXX71FVLnOSeL71SLRyadR@oL',
'RrhC?yLRurtKFeLPFovPgaTLtReRomL;PABB71 72,73:Fjif.73.jelse',
'B73:jfiXF71PU71 72,73:PWs;AMM71F71diPAJJFRdriPAQQFRsreLPAI',
'I71Fo71dPA!!FRgiePBt\'el@ lTLqdrYmu.Q.,Ke;vz vzLqpip.Q.,tz;',
';Lql.IrsZ.eap,qn.i. i.eLlMaesLdRcna,;!;h htLqm.MRasZ.ilk,%',
's$;z zLqs\'.ansZ.Ymi,/sx ;LYegseZRyal,@i;@ TLRlogdLrDsW,@;G',
'LcYlaDLbJsW,SWXJW ree @rzchLhzsW,;WERcesInW qt.\'oL.Rtrul;e',
'doTsW,Wk;Rri@stW aHAHHFndZPpqar.tridgeLinZpe.LtYer.W,:jbye'].join('\n');

examples['wik'] = [
'\\usepackage{wiki}',
'\\begin{document}',
'\\wikimarkup',
'','== Section One ==',
'An introduction to wiki.sty',
'=== A subsection ===',
'',
'==== And a subsubsection ====',
'',
'== Examples ==',
'',
'Font styling: \'\'italic\'\', \'\'\'bold\'\'\' it all works!',
'',
'* Future work: itemize',
'','* also enumerate',
'','* etc.',
'','Enjoy! % You need trailing text to close the implicit itemize',
'%No trailing whitespace or you get Fatals errors!!%',
'\\end{document}'].join('\n');

examples['met'] = ['\\usepackage{planetmath-specials}',
'\\begin{document}',
'%% BEGIN METADATA BLOCK',
'\\pmcanonicalname{ZipfsLaw}',
'\\pmrecord{3}{3422}',
'\\pmowner{akrowne}{2}',
'\\pmmodifier{akrowne}{2}',
'\\pmcreated{2002-09-05 14:18:48.912026-04}',
'\\pmmodified{2002-09-05 17:58:34.348745-04}',
'\\pmtitle{Zipf\'s law}',
'\\pmtype{Definition}',
'\\pmcomment{fixing LaTeX tabular-in-caption lockup}',
'\\pmauthor{akrowne}{2}',
'\\pmclassification{msc}{60E05}',
'\\pmclassification{msc}{68P20}',
'\\pmclassification{msc}{94A99}',
'%% END METADATA BLOCK',
'This example demonstrates embedding document metadata via {\\LaTeX} macros, using the vocabulary and syntax for the encyclopedia \\href{www.planetmath.org}{PlanetMath.org}.',
'The concrete example is taken from the \\href{http://planetmath.org/encyclopedia/ZipfsLaw.html}{Zipf\'s Law} article.',
'','',
'View the generated soure to explore the result metadata as {\\color{blue}HTML+RDFa}.',
'\\end{document}'].join('\n');

examples['wgr'] = [
'\\usepackage{webgraphic}',
'\\begin{document}',
'Welcome to \\\\',
'\\def\\w{450}',
'\\webgraphic[width=\\w]{img/external/raptor-black.png}',
'\\url{http://perl.org}',
'\\end{document}'].join('\n');

examples['tik'] = ['\\documentclass{article}\\usepackage{tikz}\\begin{document}',
'\\title{A TikZ gallery of basic examples}',
'\\section{Connecting squares}',
'\\begin{tikzpicture}',
'\\draw (0,0) -- +(1,0) -- +(1,1) -- +(0,1) -- cycle;',
'\\draw (2,0) -- +(1,0) -- +(1,1) -- +(0,1) -- cycle;',
'\\draw (1.5,1.5) -- +(1,0) -- +(1,1) -- +(0,1) -- cycle;',
'\\draw (0,0) -- (1,1) {[rounded corners] -- (2,0) -- (3,1)} -- (3,0) -- (2,1);',
'\\end{tikzpicture}',
'',
'\\section{A Trapezoid with rounded corners}',
'\\begin{tikzpicture}',
'\\draw (0,0) [rounded corners=10pt] -- (1,1) -- (2,1)',
'[sharp corners] -- (2,0)',
'[rounded corners=5pt] -- cycle;',
'\\end{tikzpicture}',
'',
'\\section{A Unit Circle}',
'\\begin{tikzpicture}',
'\\draw[clip] (0,0) circle (1cm);',
'\\end{tikzpicture}',
'',
'\\section{Plot of $\\sin(x)$}',
'\\begin{tikzpicture}',
'\\draw plot (\\x,{sin(\\x r)});',
'\\end{tikzpicture}',
'',
'\\section{Some plots}',
'\\begin{tikzpicture}',
'\\draw (0,0) grid (10,10);',
'\\pgfxycurve(0,0)(3,2)(1,4)(10,3)',
'\\pgfstroke',
'\\pgfxycurve(0,0)(1,3)(5,4)(7,9)',
'\\pgfxycurve(0,0)(1,3)(7,4)(0,9)',
'\\pgffill',
'\\end{tikzpicture}\\end{document}'].join('\n');
}