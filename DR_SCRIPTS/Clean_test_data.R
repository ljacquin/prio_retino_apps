#=========================================#
# Load packages and set working directory #
#=========================================#
library(rstudioapi)
library(data.table)
library(caret)
library(stringr)
setwd(dirname(getActiveDocumentContext()$path))

Train_files <- c(list.files('../DR_DATA/CNN_BINARY_DATA_1/train_dir/train_non_rDR/'),
                 list.files('../DR_DATA/CNN_BINARY_DATA_1/train_dir/train_rDR/'))

Train_files = sub(pattern = ' - Copie.*', replacement = '.jpg', x=Train_files)
length(Train_files)
Test_files <- list.files('../DR_DATA/CNN_BINARY_DATA_1/test_dir/')
Test_files = sub(pattern = ' - Copie.*', replacement = '.jpg', x=Test_files)
length(Test_files)

setwd('../DR_DATA/CNN_BINARY_DATA_1/test_dir/')
Common_files <- c()

# Identify test files which might exist in training files
for ( i in 1:length(Test_files) )
{
  if ( Test_files[i] %in% Train_files ){
    if ( file.exists(paste0('../train_dir/train_non_rDR/',Test_files[i])) ){
      file.copy(from = paste0('../train_dir/train_non_rDR/',Test_files[i]), to=paste0('../test_dir/',Test_files[i]), overwrite = TRUE)
    }
    if ( file.exists(paste0('../train_dir/train_rDR/',Test_files[i])) ){
      file.copy(from = paste0('../train_dir/train_rDR/',Test_files[i]), to=paste0('../test_dir/',Test_files[i]), overwrite = TRUE)
    }
    print(i)
    Common_files <- c(Common_files, Test_files[i])
  }
}

# Remove test files, from binary labelling data,  which might exist in training files
Test_image_labels<-as.data.frame(fread('../../../DR_LABELS/Test_image_labels_binary_data.csv'))
Test_image_labels <- Test_image_labels[ -match(Common_files, Test_image_labels$image_id), ]
fwrite(Test_image_labels, '../../DR_LABELS/Test_image_labels_binary_data.csv')
dim(Test_image_labels)
length(list.files('../test_dir/'))
