# =========================================#
# Load packages and set working directory #
# =========================================#
library(rstudioapi)
library(data.table)
library(stringr)
setwd(dirname(getActiveDocumentContext()$path))
source("Create_partitions_train_valid_test.R")
set.seed(123)
copy_data_partitions <- FALSE

if (copy_data_partitions && !file.exists("../dr_labels/new_image_labels_binary_data_1.csv")) {
  # ==========================================#
  # Create data frame for images with labels #
  # ==========================================#
  image_labels_data <- as.data.frame(fread("../dr_labels/image_labels_data.csv"))

  image_labels_data[1:5, ]
  dim(image_labels_data)

  image_labels_data$image_id <- paste0(image_labels_data$image, ".jpg")
  image_labels_data <- image_labels_data[, -match("image", colnames(image_labels_data))]
  image_labels_data$level <- as.character(image_labels_data$level)
  image_labels_data[1:5, ]
  dim(image_labels_data)

  ## Convert levels here for binary data and save test binary data into a csv in folder project
  I_non_rDR <- which(image_labels_data$level == "0" | image_labels_data$level == "1")
  I_rDR <- which(image_labels_data$level == "2" | image_labels_data$level == "3" | image_labels_data$level == "4")
  I_non_rDR <- sample(I_non_rDR, size = 3 * length(I_rDR), replace = FALSE)
  length(I_non_rDR) + length(I_rDR)

  image_labels_data$level[I_non_rDR] <- "non_rDR"
  image_labels_data$level[I_rDR] <- "rDR"

  image_labels_data <- image_labels_data[image_labels_data$level %in% c("non_rDR", "rDR"), ]
  fwrite(image_labels_data, file = "../dr_labels/new_image_labels_binary_data_1.csv")
  dim(image_labels_data)

  ## Define proportions for training, validation and test sets
  Prop_train <- 0.866
  Prop_valid <- 0.026
  floor(nrow(image_labels_data) * Prop_train)
  floor(nrow(image_labels_data) * Prop_valid)
  nrow(image_labels_data) - (floor(nrow(image_labels_data) * Prop_train) + floor(nrow(image_labels_data) * Prop_valid))

  ## Create a list of partitions for each disease type
  List_partitions <- Create_partitions_train_valid_test(Prop_train = Prop_train, Prop_valid = Prop_valid, Vect_classes = image_labels_data$level)

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
      train_dir_disease_class <- paste0("../cnn_binary_data_1/train_dir/train_", disease_class, "/")
      valid_dir_disease_class <- paste0("../cnn_binary_data_1/valid_dir/valid_", disease_class, "/")
      test_dir_disease_class <- "../cnn_binary_data_1/test_dir/"

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

    file.copy(Train_files_disease_class, overwrite = TRUE, paste0("../cnn_binary_data_1/train_dir/train_", disease_class, "/"))
    file.copy(Valid_files_disease_class, overwrite = TRUE, paste0("../cnn_binary_data_1/valid_dir/valid_", disease_class, "/"))
    file.copy(Test_files_disease_class, overwrite = TRUE, "../cnn_binary_data_1/test_dir/")

    print(disease_class)
  }
  length(list.files(paste0("../cnn_binary_data_1/train_dir/train_rDR/")))
  length(list.files(paste0("../cnn_binary_data_1/train_dir/train_non_rDR/")))

  length(list.files(paste0("../cnn_binary_data_1/valid_dir/valid_rDR/")))
  length(list.files(paste0("../cnn_binary_data_1/valid_dir/valid_non_rDR/")))

  length(list.files(paste0("../cnn_binary_data_1/test_dir/")))

  Test_image_labels_data <- image_labels_data[match(list.files("../cnn_binary_data_1/test_dir/"), image_labels_data$image_id), ]
  fwrite(Test_image_labels_data, file = "../../dr_labels/test_image_labels_binary_data_1.csv")
}

list_files_ = basename(list.files("../dr_data/cnn_binary_data_1/", recursive = TRUE, include.dirs = FALSE, full.names = FALSE))
list_files = as.data.frame(fread("../dr_labels/new_image_labels_binary_data_1.csv"))$image_id
identical(sort(list_files), sort(list_files_))
