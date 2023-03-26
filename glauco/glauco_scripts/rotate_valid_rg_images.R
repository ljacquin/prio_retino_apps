# =========================================#
# Load packages and set working directory #
# =========================================#
library(rstudioapi)
library(data.table)
library(OpenImageR)
library(stringr)
setwd(dirname(getActiveDocumentContext()$path))

# specify folder where augmentation by rotation will be done
valid_rg_dir <- "../glauco_data/cnn_binary_data_5/valid_dir/valid_RG/"
vect_valid_rg_files_ <- list.files(valid_rg_dir)
length(vect_valid_rg_files_)

# perform rotation for rg validation images
for (f_name in vect_valid_rg_files_) {
  set.seed(123)
  vect_angles_ <- sample(10:350, 30, replace = FALSE)
  for (angle_ in vect_angles_) {
    rot_img <- rotateImage(readImage(paste0(valid_rg_dir, f_name)), angle = angle_, method = "bilinear")
    writeImage(rot_img, file_name = str_replace(paste0(valid_rg_dir, f_name), ".jpg", paste0("_angle_", angle_, ".jpg")))
  }
}
