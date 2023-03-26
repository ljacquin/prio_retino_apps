#=========================================#
# Load packages and set working directory #
#=========================================#
library(rstudioapi)
library(data.table)
library(stringr)
setwd(dirname(getActiveDocumentContext()$path))
source('create_partitions_train_valid_test.R')
set.seed(123)

#==========================================#
# Create data frame for images with labels #
#==========================================#
img_lab_df <- as.data.frame(fread('../glauco_labels/image_labels.csv'))

## Define proportions for training, validation and test sets
Prop_train=0.80
Prop_valid=0.10
# Prop_train=0.43
# Prop_valid=0.02
floor(nrow(img_lab_df)*Prop_train)
floor(nrow(img_lab_df)*Prop_valid)
nrow(img_lab_df) - (floor(nrow(img_lab_df)*Prop_train) + floor(nrow(img_lab_df)*Prop_valid))

## Create a list of partitions for each disease type
List_partitions<-create_partitions_train_valid_test( Prop_train = Prop_train, Prop_valid = Prop_valid, Vect_classes = img_lab_df$class )

setwd('../glauco_data/processed_data/')
# length(list.files())
# length(list.files('../ORIGINAL_DATA/'))
#------------------------------------------#
# Build training, validation and test data #
#------------------------------------------#
Vect_disease_classes<-names(table(img_lab_df$class))
Vect_disease_classes

## Clean directories for new partitions 
Clean_dir=TRUE
if ( Clean_dir )
{
  for ( disease_class in Vect_disease_classes )
  {
    train_dir_disease_class<-paste0('../cnn_binary_data_5/train_dir/train_',disease_class,'/')
    valid_dir_disease_class<-paste0('../cnn_binary_data_5/valid_dir/valid_',disease_class,'/')
    test_dir_disease_class<-'../cnn_binary_data_5/test_dir/'
    
    file.remove( file.path( train_dir_disease_class, list.files(train_dir_disease_class) ) ) 
    file.remove( file.path( valid_dir_disease_class, list.files(valid_dir_disease_class) ) )
    file.remove( file.path( test_dir_disease_class, list.files(test_dir_disease_class) ) ) 
    
  }
}

## Copy to training, validation and test directories according to partitions
for ( disease_class in Vect_disease_classes )
{
  Vect_files_disease_class<-img_lab_df$image_id[which(img_lab_df$class==disease_class)]
  
  Train_files_disease_class<-Vect_files_disease_class[ List_partitions[[which(Vect_disease_classes==disease_class)]]$Train ]
  Valid_files_disease_class<-Vect_files_disease_class[ List_partitions[[which(Vect_disease_classes==disease_class)]]$Valid ]
  Test_files_disease_class<-Vect_files_disease_class[ List_partitions[[which(Vect_disease_classes==disease_class)]]$Test ]
  
  file.copy(Train_files_disease_class, overwrite=TRUE, paste0('../cnn_binary_data_5/train_dir/train_',disease_class,'/'))
  file.copy(Valid_files_disease_class, overwrite=TRUE, paste0('../cnn_binary_data_5/valid_dir/valid_',disease_class,'/'))
  file.copy(Test_files_disease_class, overwrite=TRUE, '../cnn_binary_data_5/test_dir/')
  
  print(disease_class)
}

length(list.files(paste0('../cnn_binary_data_5/train_dir/train_RG/')))
length(list.files(paste0('../cnn_binary_data_5/train_dir/train_NRG/')))

length(list.files(paste0('../cnn_binary_data_5/valid_dir/valid_RG/')))
length(list.files(paste0('../cnn_binary_data_5/valid_dir/valid_NRG/')))

length(list.files(paste0('../cnn_binary_data_5/test_dir/')))

test_img_lab_df<-img_lab_df[match(list.files('../cnn_binary_data_5/test_dir/'), img_lab_df$image_id), ]
fwrite(test_img_lab_df, file='../../glauco_labels/test_image_labels_binary_data_5.csv')

