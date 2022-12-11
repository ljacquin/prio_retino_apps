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
Image_labels_data[1:5, ]
dim(Image_labels_data)

Image_labels_data$image_id <- paste0(Image_labels_data$image,'.jpg')
Image_labels_data<-Image_labels_data[ ,-match('image',colnames(Image_labels_data))]
Image_labels_data$level<-as.character(Image_labels_data$level)
Image_labels_data[1:5, ]
dim(Image_labels_data)

## Convert levels here for binary data and save test binary data into a csv in folder project
I_non_rDR<-which( Image_labels_data$level=="0"|Image_labels_data$level=="1" )
I_rDR<-which( Image_labels_data$level=="2"|Image_labels_data$level=="3"|Image_labels_data$level=="4" )
I_non_rDR<-sample(I_non_rDR, size=3*length(I_rDR), replace=FALSE)
length(I_non_rDR)+length(I_rDR)

New_image_labels_data<-Image_labels_data[c(I_non_rDR,I_rDR), ]
Vect_sort_index_img<-sort(New_image_labels_data$image_id, index.return=TRUE)$ix
New_image_labels_data<-New_image_labels_data[Vect_sort_index_img, ]
dim(New_image_labels_data)
fwrite(New_image_labels_data, file='../DR_LABELS/Image_ICDR_labels_0_1_2_3_4.csv')

Image_labels_data$level[I_non_rDR]<-'non_rDR'
Image_labels_data$level[I_rDR]<-'rDR'

New_image_binary_labels_data<-Image_labels_data[ Image_labels_data$level%in%c('non_rDR','rDR'), ]
Vect_sort_index_img<-sort(New_image_binary_labels_data$image_id, index.return=TRUE)$ix
New_image_binary_labels_data<-New_image_binary_labels_data[Vect_sort_index_img, ]
dim(New_image_binary_labels_data)
fwrite(New_image_binary_labels_data, file='../DR_LABELS/Image_rDR_non_rDR_labels.csv')

identical(New_image_labels_data$image_id, New_image_binary_labels_data$image_id)

ICDR_label_freq<-as.data.frame(table(New_image_labels_data$level))
colnames(ICDR_label_freq)<-c('DR grade','Frequency')
fwrite(ICDR_label_freq, file='../DR_LABELS/ICDR_label_frequencies.csv')

ICDR_label_relative_freq<-as.data.frame(table(New_image_labels_data$level)/nrow(New_image_labels_data))
colnames(ICDR_label_relative_freq)<-c('DR grade','Relative frequency')
fwrite(ICDR_label_relative_freq, file='../DR_LABELS/ICDR_label_relative_frequencies.csv')
