# ========================================#
# Load packages and set working directory #
# ========================================#
library(rstudioapi)
library(data.table)
library(OpenImageR)
library(stringr)
setwd(dirname(getActiveDocumentContext()$path))
list_dir_paths <- c(
  "../dr_data/cnn_binary_data_2/train_dir/train_moderate_DR/",
  "../dr_data/cnn_binary_data_2/train_dir/train_severe_prolif_DR/",
  "../dr_data/cnn_binary_data_2/valid_dir/valid_moderate_DR/",
  "../dr_data/cnn_binary_data_2/valid_dir/valid_severe_prolif_DR/"
)
for (dir_path in list_dir_paths[-1]) {
  Sys.sleep(1)
  setwd(dirname(getActiveDocumentContext()$path))
  Sys.sleep(1)
  setwd(dir_path)
  vect_files_ <- list.files()
  nb_angle <- 3
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
}
setwd(dirname(getActiveDocumentContext()$path))
setwd("../dr_data/cnn_binary_data_2/test_dir/")
vect_files_ <- list.files()
test_img_labels <- as.data.frame(fread("../../../dr_labels/test_image_labels_binary_data_2.csv"))
list_dir_test <- c("test_moderate_DR/", "test_severe_prolif_DR/", "all_test_data/")
dir.create(list_dir_test[1])
dir.create(list_dir_test[2])
dir.create(list_dir_test[3])
nb_angle <- 3
set.seed(123)
for (f_name in vect_files_) {
  if (test_img_labels$level[match(f_name, test_img_labels$image_id)] == "moderate_DR") {
    target_dir <- list_dir_test[1]
  } else {
    target_dir <- list_dir_test[2]
  }
  vect_angle <- sample(10:350, nb_angle, replace = FALSE)
  for (angle_ in vect_angle) {
    rot_img <- rotateImage(readImage(f_name), angle = angle_, method = "bilinear")
    writeImage(rot_img, file_name = paste0(target_dir, paste0(
      str_replace(f_name, pattern = ".jpg", replacement = ""),
      "_rotated_", angle_, ".jpg"
    )))
  }
  file.rename(from = f_name , to = paste0(target_dir,f_name))
}
