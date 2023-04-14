# ========================================#
# Load packages and set working directory #
# ========================================#
library(rstudioapi)
library(stringr)
library(ROCR)
library(pROC)
library(PRROC)
library(verification)
library(data.table)
library(tensorflow)
library(keras)
library(caret)
setwd(dirname(getActiveDocumentContext()$path))

paths <- c("../dr_data/cnn_binary_data_2/train_dir/train_moderate_DR/",
           "../dr_data/cnn_binary_data_2/train_dir/train_severe_prolif_DR/",
           "../dr_data/cnn_binary_data_2/valid_dir/valid_moderate_DR/",
           "../dr_data/cnn_binary_data_2/valid_dir/valid_severe_prolif_DR/",
           "../dr_data/cnn_binary_data_2/test_dir/all_test_data/",
           "../dr_data/cnn_binary_data_2/test_dir/test_severe_prolif_DR/",
           "../dr_data/cnn_binary_data_2/test_dir/test_moderate_DR/"
           )

# get bad quality images which create bias in sensitivity and specificity computations
bad_qual_img <- unique(c(
  readLines("../dr_results/moderate_rDR_bad_qual_img"),
  readLines("../dr_results/severe_prolif_rDR_bad_qual_img")
))
pattern_bad_qual_img <- paste0(str_remove(bad_qual_img, ".jpg"), collapse = "|")

for ( path in paths ){
  detected_files_ = list.files(path)[str_detect(
    pattern = pattern_bad_qual_img,
    string = list.files(path)
  )]
  files_to_remove_ = paste0(path,detected_files_) 
  file.remove(files_to_remove_)
}
