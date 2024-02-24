############################################################ 
# Dockerfile to build image with 16s-ONT process
# Based on r-base 
############################################################ 

FROM  rocker/rstudio:4.3.2

MAINTAINER Kao,Chih-Hsin <kaochihhsin@gmail.com>

RUN  apt-get update && apt-get upgrade -y && apt-get install -y \
     libboost-all-dev libsodium-dev libxtst6 libpng-dev libxml2-dev libz-dev libfontconfig1-dev libglpk-dev libgsl-dev \
     libpcre2-dev libbz2-dev zlib1g-dev liblzma-dev libharfbuzz-dev libfribidi-dev libtiff5-dev libcairo2-dev wget gdebi-core 

RUN  R -e "install.packages('BiocManager')"
RUN  R -e "BiocManager::install(c('XVector','SummarizedExperiment', 'SingleCellExperiment', 'TreeSummarizedExperimen', 'MultiAssayExperiment', \ 
                                  'Biostrings', 'DECIPHER', 'DelayedArray', 'DelayedMatrixStats', 'scuttle', 'scater', 'DirichletMultinomial', 'bluster', \ 
                                  'mia','miaViz','pheatmap'))"
RUN  R -e "install.packages(c('ggplot2','dplyr','magrittr','argparse','RColorBrewer','ggvenn','vegan','GGally'))"
