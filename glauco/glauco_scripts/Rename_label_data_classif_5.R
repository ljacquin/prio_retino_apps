#=========================================#
# Load packages and set working directory #
#=========================================#
library(rstudioapi)
library(data.table)
library(stringr)
setwd(dirname(getActiveDocumentContext()$path))
source('Create_partitions_train_valid_test.R')
set.seed(123)

#==========================================#
# Create data frame for images with labels #
#==========================================#
img_lab_df <- as.data.frame(fread('../glauco_labels/image_labels.csv'))
head(img_lab_df)
dim(img_lab_df)
table(img_lab_df$class)

add_ext = FALSE
if ( add_ext ){
  img_lab_df$image_id <- paste0(img_lab_df$image_id,'.jpg')
  fwrite(img_lab_df, file='../glauco_labels/image_labels.csv', sep=',')
}

vect_files = list.files('../glauco_data/processed_data/')
head(vect_files)
identical(img_lab_df$image_id, vect_files)

