# =========================================#
# Load packages and set working directory #
# =========================================#
library(rstudioapi)
library(data.table)
library(OpenImageR)
library(stringr)


## =============================##
## 2. Set path for directories ##
## =============================##
cwd = "/home/deep-learning/Documents/TDS_PROJECTS/DR_PROJECT/DR_DATA/CNN_BINARY_DATA_2/train_dir/"
setwd(cwd)
path_augment <- "/home/deep-learning/Documents/TDS_PROJECTS/DR_PROJECT/DR_DATA/CNN_BINARY_DATA_2/train_dir/"
img_dir <- c("train_moderate_DR/", "train_severe_prolif_DR/")
set.seed(123)
nb_min_elem_per_class = 30000

for (dir in img_dir) {
  print(dir)
  nb_rot <- ceiling(nb_min_elem_per_class/length(list.files(dir)))
  vect_rot_angle <- floor(seq(10,350,length.out = nb_rot))
  
  for (file_name in list.files(dir)) {
    img <- readImage(paste0(cwd, dir, file_name))
    
    for (angle in vect_rot_angle ){
      rot_img <- rotateImage(img, angle = angle, method = "bilinear")
      writeImage(rot_img, file_name = paste0(
        path_augment,
        dir, str_replace(file_name, pattern = ".jpg", replacement = paste0("_rotated_", angle, ".jpg"))
      ))
    }
  }
}
