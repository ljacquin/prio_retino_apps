# =========================================#
# Load packages and set working directory #
# =========================================#
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

# set paths for training directories
train_rg_path_ <- "../glauco_data/cnn_binary_data_5/train_dir/train_RG/"
train_nrg_path_ <- "../glauco_data/cnn_binary_data_5/train_dir/train_NRG/"

# downsample images from train_NRG folder by removing randomly selected files
downsample_nrg <- FALSE
if (downsample_nrg) {
  # sample from folder
  vect_nrg_files_ <- list.files(train_nrg_path_)
  set.seed(123)
  vect_del_files_ <- sample(vect_nrg_files_, size = 38000, replace = FALSE)
  file.remove(file.path(train_nrg_path_, vect_del_files_))
}

# perform rotation for train RG images and save the new images in train_RG
vect_rg_files_ <- list.files(train_rg_path_)
out_foreach <- foreach(i = 1:length(vect_rg_files_)) %dopar% {
  f_name <- vect_rg_files_[i]
  set.seed(123)
  vect_angles_ <- sample(10:350, 16, replace = FALSE)
  for (angle_ in vect_angles_) {
    rot_img <- rotateImage(readImage(paste0(train_rg_path_, f_name)), angle = angle_, method = "bilinear")
    writeImage(rot_img, file_name = str_replace(paste0(train_rg_path_, f_name), ".jpg", paste0("_angle_", angle_, ".jpg")))
  }
}

# close cluster once all parallel task are done
parallel::stopCluster(cl = my.cluster)
