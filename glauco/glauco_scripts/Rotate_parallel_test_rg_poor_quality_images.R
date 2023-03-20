# ========================================#
# Load packages and set working directory #
# ========================================#
library(data.table)
library(OpenImageR)
library(stringr)
library(foreach)
library(doParallel)
library(rstudioapi)
setwd(dirname(getActiveDocumentContext()$path))
parallel::detectCores()
n.cores <- parallel::detectCores() - 2
# create the cluster
my.cluster <- parallel::makeCluster(
  n.cores,
  type = "FORK"
)
# check cluster definition (optional)
print(my.cluster)
# register it to be used by %dopar%
doParallel::registerDoParallel(cl = my.cluster)
# check if it is registered (optional)
foreach::getDoParRegistered()
# how many workers are available? (optional)
foreach::getDoParWorkers()

# set paths for test, poor quality and rotation directories, and test label data
test_dir_path_ <- "../glauco_data/cnn_binary_data_5/test_dir/"
test_label_path_ <- "../glauco_labels/test_image_labels_binary_data_5.csv"
test_rg_poor_qual_dir_ <- "../glauco_data/test_rg_images_poor_quality/"
rot_test_rg_poor_qual_dir_ <- "../glauco_data/rotate_test_rg_images_poor_quality/"

# get poor quality rg files
vect_rg_poor_qual_files_ <- list.files(test_rg_poor_qual_dir_)

# get and remove poor quality rg files from test dir directory and test image labels
get_and_remove_rg_poor_qual_files_ <- FALSE
if (get_and_remove_rg_poor_qual_files_) {
  # remove poor quality rg files from test_dir and test_image_labels_binary_data_5.csv
  file.remove(paste0(test_dir_path_, vect_rg_poor_qual_files_))

  # remove poor quality rg files from test_image_labels_binary_data_5.csv
  test_image_labels <- as.data.frame(fread(test_label_path_))
  test_image_labels <- test_image_labels[-match(vect_rg_poor_qual_files_, test_image_labels$image_id), ]
  fwrite(test_image_labels, file = test_label_path_)
}

# perform rotation for poor quality test rg and save new images in rot_test_rg_poor_qual_dir_
out_foreach <- foreach(i = 1:length(vect_rg_poor_qual_files_)) %dopar% {
  f_name <- vect_rg_poor_qual_files_[i]
  set.seed(123)
  vect_angles_ <- sample(10:350, 150, replace = FALSE)
  for (angle_ in vect_angles_) {
    rot_img <- rotateImage(readImage(paste0(test_rg_poor_qual_dir_, f_name)), angle = angle_, method = "bilinear")
    writeImage(rot_img, file_name = str_replace(
      paste0(rot_test_rg_poor_qual_dir_, f_name),
      ".jpg", paste0("_angle_", angle_, ".jpg")
    ))
  }
}

# copy images from rot_test_rg_poor_qual_dir_ to train_RG and valid_RG directories for data augmentation
copy_from_rot_2_train <- TRUE
if (copy_from_rot_2_train) {
  files_2_copy <- paste0(rot_test_rg_poor_qual_dir_, list.files(rot_test_rg_poor_qual_dir_))
  index_files_2_copy <- 1:length(files_2_copy)

  set.seed(123)
  index_files_2_copy_train <- sample(index_files_2_copy,
    size = floor(0.8 * length(index_files_2_copy)),
    replace = FALSE
  )
  index_files_2_copy_valid <- index_files_2_copy[-index_files_2_copy_train]

  file.copy(files_2_copy[index_files_2_copy_train],
    overwrite = TRUE, "train_dir/train_RG/"
  )
  file.copy(files_2_copy[index_files_2_copy_valid],
    overwrite = TRUE, "valid_dir/valid_RG/"
  )
}

# close cluster once all parallel task are done
parallel::stopCluster(cl = my.cluster)
