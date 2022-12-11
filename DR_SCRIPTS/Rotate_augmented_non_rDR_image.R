# =========================================#
# Load packages and set working directory #
# =========================================#
library(rstudioapi)
library(data.table)
library(OpenImageR)
library(stringr)
# setwd(dirname(getActiveDocumentContext()$path))
wd = "/home/deep-learning/Documents/TDS_PROJECTS/DR_PROJECT/DR_DATA/DATA_AUGMENTATION/non_rDR/"
setwd(wd)
set.seed(123)
vect_files_non_rDR = list.files()
vect_rot_files_non_rDR = sample(vect_files_non_rDR, size = floor(0.92*length(vect_files_non_rDR)), replace = FALSE) 
for (f_name in vect_rot_files_non_rDR){
  rot_img <- rotateImage(readImage(f_name), angle = sample(10:350,1), method = 'bilinear')
  writeImage(rot_img, file_name = f_name)
}

