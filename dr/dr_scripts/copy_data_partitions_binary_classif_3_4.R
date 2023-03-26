# ========================================#
# Load packages and set working directory #
# ========================================#
library(rstudioapi)
library(data.table)
library(stringr)
setwd(dirname(getActiveDocumentContext()$path))
setwd("../dr_data/data_augmentation/")
set.seed(123)
prop_train <- 0.95
prop_valid <- 0.04
prop_test <- 0.01
# dir_names <- list.dirs(full.names = FALSE)[-1]
dir_name = 'rDR' #  "maculopathy" "non_rDR" "rDR" 
wd = getwd()

# Set wd and split indexes into training, validation and test sets
setwd(paste0(wd,'/',dir_name,'/'))
vect_files <- list.files()
whole_index <- 1:length(vect_files)
train_index <- sample(whole_index, replace = FALSE, size = floor(prop_train * length(vect_files)))
valid_index <- sample(whole_index[-train_index], replace = FALSE, size = floor(prop_valid * length(vect_files)))
test_index <- whole_index[-c(train_index, valid_index)]

# Copy to training data set folders
if (dir.exists(paste0("../../cnn_binary_data_3/train_dir/train_", dir_name, "/"))) {
  file.copy(vect_files[train_index], overwrite = TRUE, paste0("../../cnn_binary_data_3/train_dir/train_", dir_name, "/"))
}
if (dir.exists(paste0("../../cnn_binary_data_4/train_dir/train_", dir_name, "/"))) {
  file.copy(vect_files[train_index], overwrite = TRUE, paste0("../../cnn_binary_data_4/train_dir/train_", dir_name, "/"))
}
# Copy to validation data set folders
if (dir.exists(paste0("../../cnn_binary_data_3/valid_dir/valid_", dir_name, "/"))) {
  file.copy(vect_files[valid_index], overwrite = TRUE, paste0("../../cnn_binary_data_3/valid_dir/valid_", dir_name, "/"))
}
if (dir.exists(paste0("../../cnn_binary_data_4/valid_dir/valid_", dir_name, "/"))) {
  file.copy(vect_files[valid_index], overwrite = TRUE, paste0("../../cnn_binary_data_4/valid_dir/valid_", dir_name, "/"))
}
# Copy to test data set folders
if (dir.exists(paste0("../../cnn_binary_data_3/test_dir/test_", dir_name, "/"))) {
  file.copy(vect_files[test_index], overwrite = TRUE, paste0("../../cnn_binary_data_3/test_dir/test_", dir_name, "/"))
}
if (dir.exists(paste0("../../cnn_binary_data_4/test_dir/test_", dir_name, "/"))) {
  file.copy(vect_files[test_index], overwrite = TRUE, paste0("../../cnn_binary_data_4/test_dir/test_", dir_name, "/"))
}

# length(train_index)
# length(valid_index)
# length(test_index)
# length(whole_index)
# identical(whole_index, sort(c(train_index,valid_index,test_index)))
