# Clean up the directory after a LaTeX build. Windows version
del *.aux
del *.bbl
del *.blg
del *.dvi
del *.log
del *.lof
del *.lot
del *.ps
del *.toc
del *.txt
del *.out
del *.synctex.gz*
del res-doc.tex
del res-doc.pdf
rmdir out-csv /S /Q
rmdir /S /Q knitr-cache
