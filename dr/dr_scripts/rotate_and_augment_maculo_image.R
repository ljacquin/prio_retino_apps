# ========================================#
# Load packages and set working directory #
# ========================================#
library(rstudioapi)
library(data.table)
library(OpenImageR)
library(stringr)
# setwd(dirname(getActiveDocumentContext()$path))
wd <- "../dr_data/data_augmentation/maculopathy/"
setwd(wd)
vect_files_ <- list.files()
nb_angle <- floor(5500 / length(vect_files_))

set.seed(123)
for (f_name in vect_files_) {
  vect_angle <- sample(10:350, nb_angle, replace = FALSE)
  for (angle_ in vect_angle) {
    rot_img <- rotateImage(readImage(f_name), angle = angle_, method = "bilinear")
    writeImage(rot_img, file_name = paste0(
      str_replace(f_name, pattern = ".jpg", replacement = ""),
      "_rotated_", angle_, ".jpg"
    ))
  }
}
