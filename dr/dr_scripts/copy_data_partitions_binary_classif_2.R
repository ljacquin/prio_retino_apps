# ========================================#
# Load packages and set working directory #
# ========================================#
library(rstudioapi)
library(data.table)
library(stringr)
setwd(dirname(getActiveDocumentContext()$path))
source("create_partitions_train_valid_test.R")
set.seed(123)
copy_data_partitions <- FALSE

if (copy_data_partitions && !file.exists("../dr_labels/new_image_labels_binary_data_2.csv")) {
  # ==========================================#
  # Create data frame for images with labels #
  # ==========================================#
  image_labels_data <- as.data.frame(fread("../dr_labels/image_labels_data.csv"))

  image_labels_data$image_id <- paste0(image_labels_data$image, ".jpg")
  image_labels_data <- image_labels_data[, -match("image", colnames(image_labels_data))]
  image_labels_data$level <- as.character(image_labels_data$level)
  dim(image_labels_data)

  ## Convert levels here for binary data and save test binary data into a csv in folder project
  I_moderate_DR <- which(image_labels_data$level == "2")
  I_severe_prolif_DR <- which(image_labels_data$level == "3" | image_labels_data$level == "4")

  image_labels_data$level[I_moderate_DR] <- "moderate_DR"
  image_labels_data$level[I_severe_prolif_DR] <- "severe_prolif_DR"

  image_labels_data <- image_labels_data[image_labels_data$level %in% c("moderate_DR", "severe_prolif_DR"), ]
  fwrite(image_labels_data, file = "../dr_labels/new_image_labels_binary_data_2.csv")
  dim(image_labels_data)


  ## Define proportions for training, validation and test sets
  Prop_train <- 0.866
  Prop_valid <- 0.045

  floor(nrow(image_labels_data) * Prop_train)
  floor(nrow(image_labels_data) * Prop_valid)
  nrow(image_labels_data) - (floor(nrow(image_labels_data) * Prop_train) + floor(nrow(image_labels_data) * Prop_valid))

  ## Create a list of partitions for each disease type
  List_partitions <- create_partitions_train_valid_test(Prop_train = Prop_train, Prop_valid = Prop_valid, Vect_classes = image_labels_data$level)

  setwd("../dr_data/processed_data/")

  #------------------------------------------#
  # Build training, validation and test data #
  #------------------------------------------#
  Vect_disease_classes <- names(table(image_labels_data$level))
  Vect_disease_classes

  ## Clean directories for new partitions
  Clean_dir <- TRUE
  if (Clean_dir) {
    for (disease_class in Vect_disease_classes)
    {
      train_dir_disease_class <- paste0("../cnn_binary_data_2/train_dir/train_", disease_class, "/")
      valid_dir_disease_class <- paste0("../cnn_binary_data_2/valid_dir/valid_", disease_class, "/")
      test_dir_disease_class <- "../cnn_binary_data_2/test_dir/"

      file.remove(file.path(train_dir_disease_class, list.files(train_dir_disease_class)))
      file.remove(file.path(valid_dir_disease_class, list.files(valid_dir_disease_class)))
      file.remove(file.path(test_dir_disease_class, list.files(test_dir_disease_class)))
    }
  }

  ## Copy to training, validation and test directories according to partitions
  for (disease_class in Vect_disease_classes)
  {
    Vect_files_disease_class <- image_labels_data$image_id[which(image_labels_data$level == disease_class)]

    Train_files_disease_class <- Vect_files_disease_class[List_partitions[[which(Vect_disease_classes == disease_class)]]$Train]
    Valid_files_disease_class <- Vect_files_disease_class[List_partitions[[which(Vect_disease_classes == disease_class)]]$Valid]
    Test_files_disease_class <- Vect_files_disease_class[List_partitions[[which(Vect_disease_classes == disease_class)]]$Test]

    file.copy(Train_files_disease_class, overwrite = TRUE, paste0("../cnn_binary_data_2/train_dir/train_", disease_class, "/"))
    file.copy(Valid_files_disease_class, overwrite = TRUE, paste0("../cnn_binary_data_2/valid_dir/valid_", disease_class, "/"))
    file.copy(Test_files_disease_class, overwrite = TRUE, "../cnn_binary_data_2/test_dir/")

    print(disease_class)
  }
  length(list.files(paste0("../cnn_binary_data_2/train_dir/train_severe_prolif_DR/")))
  length(list.files(paste0("../cnn_binary_data_2/train_dir/train_moderate_DR/")))

  length(list.files(paste0("../cnn_binary_data_2/valid_dir/valid_severe_prolif_DR/")))
  length(list.files(paste0("../cnn_binary_data_2/valid_dir/valid_moderate_DR/")))

  length(list.files(paste0("../cnn_binary_data_2/test_dir/")))

  Test_image_labels_data <- image_labels_data[match(list.files("../cnn_binary_data_2/test_dir/"), image_labels_data$image_id), ]
  fwrite(Test_image_labels_data, file = "../../dr_labels/Test_image_labels_binary_data_2.csv")
}

list_files_ = basename(list.files("../dr_data/cnn_binary_data_2/", recursive = TRUE, include.dirs = FALSE, full.names = FALSE))
list_files = as.data.frame(fread("../dr_labels/new_image_labels_binary_data_2.csv"))$image_id
identical(sort(list_files), sort(list_files_))
