# =========================================#
# Load packages and set working directory #
# =========================================#
library(rstudioapi)
library(data.table)
library(stringr)
setwd(dirname(getActiveDocumentContext()$path))
set.seed(123)

# =========================================#
# Create data frame for images with labels #
# =========================================#
fundus_df <- as.data.frame(fread("../dr_labels/new_image_labels_binary_data_1.csv"))
rDR_index <- which(fundus_df$level == "rDR")
non_rDR_index <- sample(which(fundus_df$level == "non_rDR"),
  size = table(fundus_df$level)[2]
)
fundus_df <- fundus_df[c(rDR_index, non_rDR_index), ]

setwd("../dr_data/original_data/")
#------------------------------------------------------------#
# Build training, validation and test data for fundus images #
#------------------------------------------------------------#
train_dir_fundus <- "../cnn_binary_data_0/train_dir/train_fundus/"
valid_dir_fundus <- "../cnn_binary_data_0/valid_dir/valid_fundus/"
test_dir_fundus <- "../cnn_binary_data_0/test_dir/test_fundus/"

## Clean directories for new partitions
Clean_dir <- FALSE
if (Clean_dir) {
  file.remove(file.path(train_dir_fundus, list.files(train_dir_fundus)))
  file.remove(file.path(valid_dir_fundus, list.files(valid_dir_fundus)))
  file.remove(file.path(test_dir_fundus, list.files(test_dir_fundus)))
}

train_files <- sample(fundus_df$image_id, size = 20000, replace = FALSE)
test_files <- sample(fundus_df$image_id[-match(train_files, fundus_df$image_id)],
  size = 2000, replace = FALSE
)
valid_files <- fundus_df$image_id[-match(
  c(train_files, test_files),
  fundus_df$image_id
)]

file.copy(train_files, overwrite = TRUE, train_dir_fundus)
file.copy(valid_files, overwrite = TRUE, valid_dir_fundus)
file.copy(test_files, overwrite = TRUE, test_dir_fundus)

#------------------------------------------------------------#
# Build training, validation and test data for others images #
#------------------------------------------------------------#
setwd("../random_data/")
list_files_others <- list.files()
train_dir_others <- "../cnn_binary_data_0/train_dir/train_others/"
valid_dir_others <- "../cnn_binary_data_0/valid_dir/valid_others/"
test_dir_others <- "../cnn_binary_data_0/test_dir/test_others/"

## Clean directories for new partitions
Clean_dir <- FALSE
if (Clean_dir) {
  file.remove(file.path(train_dir_others, list.files(train_dir_others)))
  file.remove(file.path(valid_dir_others, list.files(valid_dir_others)))
  file.remove(file.path(test_dir_others, list.files(test_dir_others)))
}

train_files <- sample(list_files_others, size = 20000, replace = FALSE)
test_files <- sample(list_files_others[-match(train_files, list_files_others)],
                     size = 2000, replace = FALSE
)
valid_files <- sample(list_files_others[-match(
  c(train_files, test_files),
  list_files_others
)], size = 1234 , replace = FALSE)

file.copy(train_files, overwrite = TRUE, train_dir_others)
file.copy(valid_files, overwrite = TRUE, valid_dir_others)
file.copy(test_files, overwrite = TRUE, test_dir_others)



