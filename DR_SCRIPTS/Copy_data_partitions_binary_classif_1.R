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

Image_labels_data$level[I_non_rDR]<-'non_rDR'
Image_labels_data$level[I_rDR]<-'rDR'

Image_labels_data<-Image_labels_data[Image_labels_data$level%in%c('non_rDR','rDR'), ]
fwrite(Image_labels_data, file='../DR_LABELS/New_image_labels_binary_data_1.csv')
dim(Image_labels_data)
# sum(Image_labels_data$level%in%c('non_rDR','rDR'))
# For memory: c(4,3,4,7,1,7,2,7,8,30,78,56,9787,2,56)%in%c(1,2)

## Define proportions for training, validation and test sets
Prop_train=0.866
Prop_valid=0.026
# Prop_train=0.43
# Prop_valid=0.02
floor(nrow(Image_labels_data)*Prop_train)
floor(nrow(Image_labels_data)*Prop_valid)
nrow(Image_labels_data) - (floor(nrow(Image_labels_data)*Prop_train) + floor(nrow(Image_labels_data)*Prop_valid))

## Create a list of partitions for each disease type
List_partitions<-Create_partitions_train_valid_test( Prop_train = Prop_train, Prop_valid = Prop_valid, Vect_classes = Image_labels_data$level )

setwd('../DR_DATA/PROCESSED_DATA/')
# length(list.files())
# length(list.files('../ORIGINAL_DATA/'))
#------------------------------------------#
# Build training, validation and test data #
#------------------------------------------#
Vect_disease_classes<-names(table(Image_labels_data$level))
Vect_disease_classes

## Clean directories for new partitions 
Clean_dir=TRUE
if ( Clean_dir )
{
  for ( disease_class in Vect_disease_classes )
  {
    train_dir_disease_class<-paste0('../CNN_BINARY_DATA/train_dir/train_',disease_class,'/')
    valid_dir_disease_class<-paste0('../CNN_BINARY_DATA/valid_dir/valid_',disease_class,'/')
    test_dir_disease_class<-'../CNN_BINARY_DATA/test_dir/'
    
    file.remove( file.path( train_dir_disease_class, list.files(train_dir_disease_class) ) ) 
    file.remove( file.path( valid_dir_disease_class, list.files(valid_dir_disease_class) ) )
    file.remove( file.path( test_dir_disease_class, list.files(test_dir_disease_class) ) ) 
    
  }
}

## Copy to training, validation and test directories according to partitions
for ( disease_class in Vect_disease_classes )
{
  Vect_files_disease_class<-Image_labels_data$image_id[which(Image_labels_data$level==disease_class)]
  
  Train_files_disease_class<-Vect_files_disease_class[ List_partitions[[which(Vect_disease_classes==disease_class)]]$Train ]
  Valid_files_disease_class<-Vect_files_disease_class[ List_partitions[[which(Vect_disease_classes==disease_class)]]$Valid ]
  Test_files_disease_class<-Vect_files_disease_class[ List_partitions[[which(Vect_disease_classes==disease_class)]]$Test ]
  
  file.copy(Train_files_disease_class, overwrite=TRUE, paste0('../CNN_BINARY_DATA/train_dir/train_',disease_class,'/'))
  file.copy(Valid_files_disease_class, overwrite=TRUE, paste0('../CNN_BINARY_DATA/valid_dir/valid_',disease_class,'/'))
  file.copy(Test_files_disease_class, overwrite=TRUE, '../CNN_BINARY_DATA/test_dir/')
  
  print(disease_class)
}
length(list.files(paste0('../CNN_BINARY_DATA/train_dir/train_rDR/')))
length(list.files(paste0('../CNN_BINARY_DATA/train_dir/train_non_rDR/')))

length(list.files(paste0('../CNN_BINARY_DATA/valid_dir/valid_rDR/')))
length(list.files(paste0('../CNN_BINARY_DATA/valid_dir/valid_non_rDR/')))

length(list.files(paste0('../CNN_BINARY_DATA/test_dir/')))

Test_image_labels_data<-Image_labels_data[match(list.files('../CNN_BINARY_DATA/test_dir/'), Image_labels_data$image_id), ]
fwrite(Test_image_labels_data, file='../../DR_LABELS/Test_image_labels_binary_data_1.csv')

