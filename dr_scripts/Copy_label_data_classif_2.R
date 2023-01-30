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
Image_labels_data <- as.data.frame(fread('../DR_LABELS/Image_labels_data.csv'))
# New_vect_non_grad_img<-str_replace(Vect_non_grad_img, pattern = '.jpg', replacement = '')
# New_image_labels_data<-Image_labels_data[-match(New_vect_non_grad_img,Image_labels_data$image), ]
# fwrite(New_image_labels_data, file='../Image_labels_data.csv')

Image_labels_data$image_id <- paste0(Image_labels_data$image,'.jpg')
Image_labels_data<-Image_labels_data[ ,-match('image',colnames(Image_labels_data))]
Image_labels_data$level<-as.character(Image_labels_data$level)
dim(Image_labels_data)

## Convert levels here for binary data and save test binary data into a csv in folder project
I_moderate_DR<-which( Image_labels_data$level=="2" )
I_severe_prolif_DR<-which( Image_labels_data$level=="3"|Image_labels_data$level=="4" )

New_image_labels_data<-Image_labels_data[c(I_moderate_DR,I_severe_prolif_DR), ]
Vect_sort_index_img<-sort(New_image_labels_data$image_id, index.return=TRUE)$ix
New_image_labels_data<-New_image_labels_data[Vect_sort_index_img, ]
dim(New_image_labels_data)
fwrite(New_image_labels_data, file='../DR_LABELS/Image_ICDR_labels_2_3_4.csv')

Image_labels_data$level[I_moderate_DR]<-'moderate_DR'
Image_labels_data$level[I_severe_prolif_DR]<-'severe_prolif_DR'

New_image_categorical_labels_data<-Image_labels_data[ Image_labels_data$level%in%c('moderate_DR','severe_prolif_DR'), ]
Vect_sort_index_img<-sort(New_image_categorical_labels_data$image_id, index.return=TRUE)$ix
New_image_categorical_labels_data<-New_image_categorical_labels_data[Vect_sort_index_img, ]
dim(New_image_categorical_labels_data)
fwrite(New_image_categorical_labels_data, file='../DR_LABELS/Image_moderate_DR_severe_prolif_DR_labels.csv')

identical(New_image_labels_data$image_id, New_image_categorical_labels_data$image_id)

