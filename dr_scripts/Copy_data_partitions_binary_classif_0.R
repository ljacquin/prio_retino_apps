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
all_image_labels_data <- as.data.frame(fread('../DR_LABELS/Image_labels_data.csv'))
all_image_labels_data$image <- paste0(all_image_labels_data$image, '.jpg')
quality_image_labels_data <- as.data.frame(fread('../DR_LABELS/New_image_labels_binary_data_1.csv'))
dim(all_image_labels_data)
dim(quality_image_labels_data)

# Set all quality_status to non_quality
all_image_labels_data$quality_status <- 'non_quality'
index_quality <- match(quality_image_labels_data$image_id, all_image_labels_data$image)
length(na.omit(unique(index_quality)))
all_image_labels_data$quality_status[index_quality] <- 'quality'

# Resize quality data
resize <- FALSE
nb_img <- 30000
if ( resize ){
  all_image_labels_data <- all_image_labels_data[sample(1:nrow(all_image_labels_data), 
                                                        size = nb_img, replace = FALSE), ]
}
table(all_image_labels_data$quality_status)

# Save new labels for classifier 0
fwrite(all_image_labels_data, file='../DR_LABELS/New_image_labels_binary_data_0.csv')


# Define proportions for training, validation and test sets
Prop_train=0.85
Prop_valid=0.10
floor(nrow(all_image_labels_data)*Prop_train)
floor(nrow(all_image_labels_data)*Prop_valid)
nrow(all_image_labels_data) - (floor(nrow(all_image_labels_data)*Prop_train) + floor(nrow(all_image_labels_data)*Prop_valid))

## Create a list of partitions for each disease type
List_partitions<-Create_partitions_train_valid_test( Prop_train = Prop_train, Prop_valid = Prop_valid, Vect_classes = all_image_labels_data$quality_status )


setwd('../DR_DATA/PROCESSED_DATA/')
#------------------------------------------#
# Build training, validation and test data #
#------------------------------------------#
vect_class_<-names(table(all_image_labels_data$quality_status))
vect_class_

## Clean directories for new partitions 
Clean_dir=TRUE
if ( Clean_dir )
{
  for ( class_ in vect_class_ )
  {
    train_dir_class_<-paste0('../CNN_BINARY_DATA_0/train_dir/train_',class_,'/')
    valid_dir_class_<-paste0('../CNN_BINARY_DATA_0/valid_dir/valid_',class_,'/')
    test_dir_class_<-'../CNN_BINARY_DATA_0/test_dir/'
    
    file.remove( file.path( train_dir_class_, list.files(train_dir_class_) ) ) 
    file.remove( file.path( valid_dir_class_, list.files(valid_dir_class_) ) )
    file.remove( file.path( test_dir_class_, list.files(test_dir_class_) ) ) 
    
  }
}

## Copy to training, validation and test directories according to partitions
for ( class_ in vect_class_ )
{
  Vect_files_class_<-all_image_labels_data$image[which(all_image_labels_data$quality_status==class_)]
  
  Train_files_class_<-Vect_files_class_[ List_partitions[[which(vect_class_==class_)]]$Train ]
  Valid_files_class_<-Vect_files_class_[ List_partitions[[which(vect_class_==class_)]]$Valid ]
  Test_files_class_<-Vect_files_class_[ List_partitions[[which(vect_class_==class_)]]$Test ]
  
  file.copy(Train_files_class_, overwrite=TRUE, paste0('../CNN_BINARY_DATA_0/train_dir/train_',class_,'/'))
  file.copy(Valid_files_class_, overwrite=TRUE, paste0('../CNN_BINARY_DATA_0/valid_dir/valid_',class_,'/'))
  file.copy(Test_files_class_, overwrite=TRUE, '../CNN_BINARY_DATA_0/test_dir/')
  
  print(class_)
}
length(list.files(paste0('../CNN_BINARY_DATA_0/train_dir/train_non_quality/')))
length(list.files(paste0('../CNN_BINARY_DATA_0/train_dir/train_quality/')))

length(list.files(paste0('../CNN_BINARY_DATA_0/valid_dir/valid_non_quality/')))
length(list.files(paste0('../CNN_BINARY_DATA_0/valid_dir/valid_quality/')))

length(list.files(paste0('../CNN_BINARY_DATA_0/test_dir/')))

Test_image_labels_data<-all_image_labels_data[match(list.files('../CNN_BINARY_DATA_0/test_dir/'), all_image_labels_data$image), ]
fwrite(Test_image_labels_data, file='../../DR_LABELS/Test_image_labels_binary_data_0.csv')

 
# files_cnn_1 <- list.files(path = "../DR_DATA/CNN_BINARY_DATA_1/", full.names = FALSE, recursive = TRUE)
# files_cnn_1 <- str_replace_all(files_cnn_1, 
#                 pattern = 'test_dir/|valid_dir/valid_rDR/|valid_dir/valid_non_rDR/|train_dir/train_rDR/|train_dir/train_non_rDR/|',
#                 replacement = '')
# # length(files_cnn_1) - nrow(all_image_labels_data)
# # which(!(files_cnn_1%in%all_image_labels_data$image))
# 
# files_cnn_test <- list.files(path = "../DR_DATA/CNN_BINARY_DATA_1/test_dir/")


