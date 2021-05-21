# Chord
remove single cells Doublets by integrating tools! 
Chord uses the AdBoost algorithm to integrate different methods for stable and accurate doublets filtered results. 

## Install:
```R
remotes::install_github('chris-mcginnis-ucsf/DoubletFinder') 

devtools::install_github('kostkalab/scds',ref="master")

if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install(version='devel')
BiocManager::install("scran")

install.packages("adabag")

devtools::install_github("13308204545/Chord") 
   
```
## Quick start:
```R
chord（seu="input seurat object",doubletrat="estimated doubletrate",overkill=T,outname="the name you want"）
```
Q:how to estimate doubletrate? 

A:It depends on the number of cells in the sample. 10X can be referred：doubletrate = ~0.9% per 1,000 cells.  

Q:how to remove doublets 

A:The doublets' barcodes are in the file "outname_doublets.csv" 

## Boost more methods:
1.Using any method to evaluate the dataset "overkilled.robj", adding the results of socres to "simulated_data.scores.csv".

![image](https://github.com/13308204545/Chord/blob/main/pictures/readme1.png)

2.Using any method to evaluate the dataset "seu.robj", adding the results of socres to "simulated_data.scores.csv".

![image](https://github.com/13308204545/Chord/blob/main/pictures/readme2.png)

3.In the same dir, run the codes:
```R
load("seu.robj")
load("sce.robj")
chord(seu = seu,sce=sce,doubletrat="estimated doubletrate 2",overkill=T,outname="the name you want 2",addmethods1 ="real_data.scores.csv",addmethods2 = "simulated_data.scores.csv" )
```

4.The doublets' barcodes are in the file "outname_doublets.csv" 

## References
McGinnis, C. S., Murrow, L. M. & Gartner, Z. J. DoubletFinder: Doublet Detection in Single-Cell RNA Sequencing Data Using Artificial Nearest Neighbors. Cell Systems 8, 329-337.e324, doi:10.1016/j.cels.2019.03.003 (2019). 

Lun, A. T., McCarthy, D. J. & Marioni, J. C. A step-by-step workflow for low-level analysis of single-cell RNA-seq data with Bioconductor. F1000Res 5, 2122, doi:10.12688/f1000research.9501.2 (2016). 

Bais, A. S. & Kostka, D. scds: computational annotation of doublets in single-cell RNA sequencing data. Bioinformatics 36, 1150-1158, doi:10.1093/bioinformatics/btz698 (2020). 

