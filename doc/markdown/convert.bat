echo ## Table of Contents > Introduction.md
echo ## Table of Contents > Getting-started.md
echo ## Table of Contents > Network-models.md
echo ## Table of Contents > Network-analysis.md
echo ## Table of Contents > Network-solvers.md
echo ## Table of Contents > Layered-networks.md
echo ## Table of Contents > Environments.md
echo ## Table of Contents > Examples.md

type Introduction-ToC.md >> Introduction.md
type Getting-started-ToC.md >> Getting-started.md
type Network-models-ToC.md >> Network-models.md
type Network-analysis-ToC.md >> Network-analysis.md
type Network-solvers-ToC.md >> Network-solvers.md
type Layered-networks-ToC.md >> Layered-networks.md
type Environments-ToC.md >> Environments.md
type Examples-ToC.md >> Examples.md

copy Introduction-ToC.md Home.md
type Getting-started-ToC.md >> Home.md
type Network-models-ToC.md >> Home.md
type Network-analysis-ToC.md >> Home.md
type Network-solvers-ToC.md >> Home.md
type Layered-networks-ToC.md >> Home.md
type Environments-ToC.md >> Home.md
type Examples-ToC.md >> Home.md

pandoc -F pandoc-crossref --from latex -t markdown+tex_math_single_backslash --to gfm ../latex/introduction.tex  >> Introduction.md
pandoc -F pandoc-crossref --from latex -t markdown+tex_math_single_backslash --to gfm ../latex/getstarted.tex  >> Getting-started.md
pandoc -F pandoc-crossref --from latex -t markdown+tex_math_single_backslash --to gfm ../latex/network.tex  >> Network-models.md
pandoc -F pandoc-crossref --from latex -t markdown+tex_math_single_backslash --to gfm ../latex/analysis.tex  >> Network-analysis.md
pandoc -F pandoc-crossref --from latex -t markdown+tex_math_single_backslash --to gfm ../latex/solvers.tex  >> Network-solvers.md
pandoc -F pandoc-crossref --from latex -t markdown+tex_math_single_backslash --to gfm ../latex/layered.tex  >> Layered-networks.md
pandoc -F pandoc-crossref --from latex -t markdown+tex_math_single_backslash --to gfm ../latex/env.tex  >> Environments.md
pandoc -F pandoc-crossref --from latex -t markdown+tex_math_single_backslash --to gfm ../latex/examples.tex  >> Examples.md

sed -i "s/\\forall/forall/g" *.md
sed -i "s/\\sum/sum/g" *.md
sed -i "s/lambda_/lambda/g" *.md
sed -i "s/mu_/mu/g" *.md
sed -i "s/gamma_/gamma/g" *.md
sed -i "s/phi_/phi/g" *.md
sed -i "s/rho_/rho/g" *.md
sed -i "s/\\rho/rho/g" *.md
sed -i "s/\\alpha/alpha/g" *.md
sed -i "s/\\lambda/lambda/g" *.md
sed -i "s/\\mu/mu/g" *.md
sed -i "s/\\gamma/gamma/g" *.md
sed -i "s/\\phi/phi/g" *.md
sed -i "s/\\texttt{Inf}/Inf/g" *.md
sed -i "s/\\texttt{st1}/st1/g" *.md
sed -i "s/\\texttt{st2}/st2/g" *.md
sed -i "s/\\geq/>=/g" *.md
sed -i "s/\\leq/>=/g" *.md
sed -i "s/\\[TABQN\\]//g" *.md
sed -i "s/\\[TABstatdistributions\\]//g" *.md
sed -i "s/\\[TABsolverfunctions\\]//g" *.md
sed -i "s/\\[TAB:nodes\\]//g" *.md
sed -i "s/\\(//g" *.md
sed -i "s/\\)//g" *.md
sed -i "s/\\[TAB.*\\]//g" *.md
sed -i "s/\\[FIG.*\\]//g" *.md
sed -i "s/@BolGMT06/[Bolch et al. 2006](https:\/\/dl.acm.org\/citation.cfm?id=289350)/g" *.md
sed -i "s/@LazZGS84/[Lazwoska et al. 1984](https:\/\/homes.cs.washington.edu\/~lazowska\/qsp\/)/g" *.md
sed -i "s/@Lav89/[Lavenberg 1989](https:\/\/dl.acm.org\/citation.cfm?id=88443)/g" *.md
sed -i "s/@Bal00/[Balsamo 2000](http:\/\/www.dsi.unive.it\/~balsamo\/pub\/pfwhite99.pdf)/g" *.md
sed -i "s/@lqns12/[LQNSUserMan](http:\/\/www.sce.carleton.ca\/rads\/lqns\/LQNSUserMan.pdf)/g" *.md
sed -i "s/@lqntut/[Woodside 2013](http:\/\/www.sce.carleton.ca\/rads\/lqns\/lqn-documentation\/tutorialh.pdf)/g" *.md
sed -i "s/@BerCS07/[Bertoli et al. 2006](http:\/\/jmt.sourceforge.net\/Papers\/qest06jmt.pdf)/g" *.md
sed -i "s/@pere.casa13/[Perez et al. 2013](https:\/\/dl.acm.org\/citation.cfm?id=2624969)/g" *.md
sed -i "s/@PerC17/[Perez et al. 2017](https:\/\/ieeexplore.ieee.org\/document\/7843645\/)/g" *.md
sed -i "s/@Hor17/[Horvath et al. 2017](https:\/\/doi.org\/10.4108\/eai.25-10-2016.2266400)/g" *.md
sed -i "s/@roli.sevc95/[Rolia et al. 1995](https:\/\/dl.acm.org\/citation.cfm?id=631178)/g" *.md
sed -i "s/@CasTH14/[Casale et al. 2014](https:\/\/dl.acm.org\/citation.cfm?id=2943698)/g" *.md
sed -i "s/@GastH16/[Gast et al. 2014](https:\/\/dl.acm.org\/citation.cfm?id=2745850)/g" *.md

del sed*
xcopy Home.md ..\..\..\line-solver.wiki\ /Y
xcopy Introduction.md ..\..\..\line-solver.wiki\ /Y
xcopy Getting-started.md ..\..\..\line-solver.wiki\ /Y
xcopy Network-models.md ..\..\..\line-solver.wiki\ /Y
xcopy Network-analysis.md ..\..\..\line-solver.wiki\ /Y
xcopy Network-solvers.md ..\..\..\line-solver.wiki\ /Y
xcopy Layered-networks.md ..\..\..\line-solver.wiki\ /Y
xcopy Environments.md ..\..\..\line-solver.wiki\ /Y
xcopy Examples.md ..\..\..\line-solver.wiki\ /Y
