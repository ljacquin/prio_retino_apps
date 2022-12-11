#=========================================#
# Load packages and set working directory #
#=========================================#
library(rstudioapi)
library(data.table)
library(caret)
library(stringr)
setwd(dirname(getActiveDocumentContext()$path))

Maculopathy_files <- list.files('../DR_DATA/MACULOPATHY/')
Test_image_labels <- as.data.frame(fread('../DR_LABELS/Test_image_labels_binary_data.csv'))

rDR_file=c()
for ( i in 1:length(Maculopathy_files) )
{
  file_name = sub(pattern = ' - Copie.*', replacement = '.jpg', x=Maculopathy_files[i])
  if ( file_name %in% Test_image_labels$image_id && Test_image_labels$level[match(file_name, Test_image_labels$image_id)]=='rDR'){
    rDR_file=c(rDR_file,file_name)
  }
}
