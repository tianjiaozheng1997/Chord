#' Chord
#'
#' remove doublet with scds,bcds,DoubletFinder.
#' @param method the boost method ("adaboost" or "gbm")
#' @param seu the input seurat object
#' @param seu the input sce object
#' @param seed an integer, random seed
#' @param k an integer,k-means param k
#' @param overkill if True,use overkill
#' @param overkillrate an integer,remove the top ?% doublet-liked cells of any methods' results.(0-1)
#' @param outname The prefix of the output file
#' @param addmethods2 the table merged with other method's scores2
#' @param addmethods1 the table merged with other method's scores1
#' @param mfinal an integer, the number of iterations for which boosting is run or the number of trees to use. Defaults to mfinal=40 iterations.(only works when method="adaboost")
#' @param overkilllist a vector of cells to be remove in overkill
#' @param adddoublt doubletrate of cells to be simulate
#' @param cxds.ntop integer, indimessageing number of top variance genes to consider. Default: 500
#' @param cxds.binThresh integer, minimum counts to consider a gene "present" in a cell. Default: 0
#' @param bcds.ntop integer, indicating number of top variance genes to consider. Default: 500
#' @param bcds.srat numeric, indicating ratio between orginal number of "cells" and simulated doublets; Default: 1
#' @param dbf.PCs Number of statistically-significant principal components (e.g., as estimated from PC elbow plot); Default: 1:10
#' @param dbf.pN  The number of generated artificial doublets, expressed as a proportion of the merged real-artificial data. Default is set to 0.25, based on observation that DoubletFinder performance is largely pN-invariant (see McGinnis, Murrow and Gartner 2019, Cell Systems).
#' @param dbf.pK  The PC neighborhood size used to compute pANN, expressed as a proportion of the merged real-artificial data. No default is set, as pK should be adjusted for each scRNA-seq dataset. Optimal pK values can be determined using mean-variance-normalized bimodality coefficient.
#' @import Seurat
#' @import scds
#' @import scater
#' @import rsvd
#' @import Rtsne
#' @import cowplot
#' @import DoubletFinder
#' @import adabag
#' @import gbm
#' @export
#' @examples chord(seu=NA,doubletrate=NA,k=20,overkill=T,overkillrate=1,outname="out",seed=1)


#Chord------
chord<-function(
  seu=NA,
  sce=NA,
  doubletrate=NA,
  mfinal=40,
  k=20,
  method="gbm",
  overkill=T,
  overkillrate=1,
  outname="out",
  seed=1,
  addmethods1=NA,
  addmethods2=NA,
  overkilllist=NA,
  adddoublt=NA,
  cxds.ntop=NA,
  cxds.binThresh=NA,
  bcds.ntop=NA,
  bcds.srat=NA,
  dbf.PCs=1:10,
  dbf.pN=0.25,
  dbf.pK=NA
  ){

  require(Seurat)
  require(scds)
  require(scater)
  require(rsvd)
  require(Rtsne)
  require(cowplot)
  require(DoubletFinder)
  require(adabag)

  if (!(is.na(addmethods1)&is.na(addmethods2))) {

    addmethods2<-read.csv(addmethods2,row.names = 1)
    addmethods1<-read.csv(addmethods1,row.names = 1)
    DBboost<-DBboostTrain(mattest=addmethods2,mfinal=mfinal)
    mattestout<-DBboostPre2(DBboost=DBboost,mattest=addmethods1,seu=seu,sce=sce,outname=paste0(outname,mfinal))
    write.csv(mattestout,file=paste0(outname,"real_score.csv"))
    d<-rownames(mattestout)[order(mattestout$chord,decreasing = T)[1:round(doubletrate*ncol(seu))]]
    write.csv(d,file=paste0(outname,"_doublet.csv"))
    return(d)
  }

  if (is.na(doubletrate)) {
    stop("You need to specify the percentage of cells you want to remove.（0<doubletrate<1）
         for example~ 0.9% per 1000 cells (10X)")
  }
  if (is.na(seu)) {
    stop("You need to input the seurat object")
  }

  set.seed(seed)
  seu@meta.data<-seu@meta.data[,-grep("pANN",colnames(seu@meta.data))]  #Avoid errors resulting from previous results 2021.06.22  ps:adviced doubletrate=0.009*ncol(seu)/1000
  sce<-creatSCE(seu=seu)
  sce<-scds(sce=sce,
            cxds.ntop=cxds.ntop,
            cxds.binThresh=cxds.binThresh,
            bcds.ntop=bcds.ntop,
            bcds.srat=bcds.srat)
  seu<-DBF(seu=seu,ground_truth = F,doubletrate=doubletrate,dbf.PCs=dbf.PCs,
           dbf.pN=dbf.pN,
           dbf.pK=dbf.pK)

  mattrain<-testroc(seu=seu,sce=sce,outname = "train")
  write.csv(mattrain,file = "real_data.scores.csv")

  seu2<-overkillDB2(seu=seu,sce=sce,doubletrate=doubletrate,seed=seed,k=k,overkill=overkill,overkillrate=overkillrate,overkilllist=overkilllist,adddoublt=adddoublt)
  doubletrate2=sum(seu2$label_scds=="Doublet")/ncol(seu2)
  sce2<-creatSCE(seu=seu2)
  sce2<-scds(sce=sce2,
             cxds.ntop=cxds.ntop,
             cxds.binThresh=cxds.binThresh,
             bcds.ntop=bcds.ntop,
             bcds.srat=bcds.srat)
  seu2<-DBF(seu=seu2,ground_truth = F,doubletrate=doubletrate2,dbf.PCs=dbf.PCs,
            dbf.pN=dbf.pN,
            dbf.pK=dbf.pK)
  mattrain2<-testroc2(seu=seu2,sce=sce2,outname = "train with createdDB")
  write.csv(mattrain2,file = "simulated_data.scores.csv")

  DBboost<-DBboostTrain(mattest=mattrain2,mfinal=40,method = method)
  mattestout<-DBboostPre(DBboost=DBboost,mattest=mattrain,outname=40,method = method)

  seu$chord<-mattestout$chord
  seu$bcds_s<-mattestout$bcds_s
  seu$cxds_s<-mattestout$cxds_s
  seu$dbf_s<-mattestout$dbf_s

  pdf(paste0(outname,"score.pdf"))
  print(FeaturePlot(seu,features = c("bcds_s","cxds_s","dbf_s","chord")))
  dev.off()

  write.csv(mattestout,file=paste0(outname,"real_score.csv"))
  d<-rownames(mattestout)[order(mattestout$chord,decreasing = T)[1:round(doubletrate*ncol(seu))]]
  write.csv(d,file=paste0(outname,"_doublet.csv"))
  save(seu,file="seu.robj")
  save(sce,file="sce.robj")
  return(d)
}

#chord(seu=seu,doubletrate = doubletrate,seed = 3)
#xx<-read.csv("outreal_score.csv",row.names = 1)
#xxx<-read.csv("../A/finalScore.40.csv",row.names = 1)

#roc(response = lab,predictor =mattestout$chord)

