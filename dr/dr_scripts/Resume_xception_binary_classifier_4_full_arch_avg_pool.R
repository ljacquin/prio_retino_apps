#=========================================#
# Load packages and set working directory #
#=========================================#
library(devtools)
library(data.table)
# library(rstudioapi)
library(reticulate)
library(tensorflow)
library(keras)
# library(magick)
library(stringr)
library(viridis)
library(caret)
# options(tensorflow.extract.one_based = FALSE)
use_session_with_seed(0, disable_gpu=FALSE, disable_parallel_cpu=FALSE)
# setwd(dirname(getActiveDocumentContext()$path))
# py_module_available('keras') # must return TRUE
# py_module_available('tensorflow') # must return TRUE
# py_discover_config("keras") # more info on the python env, tf and keras

#========================================================================#
# Resize image, instantiate the xception model and add new layers on top #
#========================================================================#
img_size_cnn=299
batch_size_val=10
num_epochs=5

model<-load_model_hdf5('../dr_models/xception_binary_classifier_4_full_arch_avg_pool.h5')

#=================================================#
# Augmenting train data with image data generator #
#=================================================#
train_dir='../dr_data/cnn_binary_data_4/train_dir/'

train_datagen = image_data_generator(
  rescale            = 1/255    ,
  rotation_range     = 5        ,
  width_shift_range  = 0.1      ,
  height_shift_range = 0.05     ,
  shear_range        = 0.1      ,
  zoom_range         = 0.15     ,
  horizontal_flip    = TRUE     ,
  vertical_flip      = FALSE    ,
  fill_mode          = "reflect"
)

train_generator <- flow_images_from_directory(
  train_dir,                            # Target directory  
  train_datagen,                        # Data generator
  target_size = c(img_size_cnn, img_size_cnn),  # Resizes all images to img_size_cnn x img_size_cnn 
  batch_size = batch_size_val,
  class_mode = "binary"            # binary for binary labels
)

#===========================================================================#
# Rescaling validation data without augmenting it with image data generator #
#===========================================================================#
valid_dir='../dr_data/cnn_binary_data_4/valid_dir/'

valid_datagen <- image_data_generator( rescale = 1/255 )  

validation_generator <- flow_images_from_directory(
  valid_dir,
  valid_datagen,
  target_size = c(img_size_cnn, img_size_cnn),
  batch_size = batch_size_val,
  class_mode = "binary")

model %>% compile(
  loss      = "binary_crossentropy",
  optimizer = optimizer_sgd(lr = 1e-5, decay = 0.01, momentum = 0.9),
  metrics   = c("accuracy")
)

#-------------------------------------------------------------------------------------------------#
# Some optimizer choices                                                                          #
# optimizer_sgd(lr = 0.01, decay = 0.01, momentum = 0.9)                                          #
# optimizer_rmsprop(lr = 1e-5)                                                                    #
# optimizer_rmsprop(lr=0.001, decay=4e-5)                                                         #
# keras.optimizers.Nadam(lr=0.002, beta_1=0.9, beta_2=0.999, epsilon=None, schedule_decay=0.004)  #
#-------------------------------------------------------------------------------------------------#

#============================#
# Set weights for each class #
#============================#
train_dir_folders<-list.files('../dr_data/cnn_binary_data_4/train_dir/')
Vect_nb_elem_per_class<-rep(0,length(train_dir_folders))
for ( i in 1:length(train_dir_folders) )
{
  Vect_nb_elem_per_class[i]<-length(list.files(paste0('../dr_data/cnn_binary_data_4/train_dir/',train_dir_folders[i])))
}
Vect_weight_per_class<-max(Vect_nb_elem_per_class)/Vect_nb_elem_per_class
Vect_weight_per_class

#======================================================================================================#
# Fit model with fit_generator applied to the augmented/rescaled train data set (i.e. train_generator) #  
# and rescaled validation data set (i.e. validation_generator)                                         #
#======================================================================================================#
# Note, according to keras documentation:
# steps_per_epoch = number of samples for whole dataset divided by batch_size 
# validation_steps = number of samples for validation dataset divided by the batch size

history <- model %>% fit_generator(
  train_generator,
  steps_per_epoch=floor(length(list.files('../dr_data/cnn_binary_data_4/train_dir/',recursive=TRUE))/batch_size_val),
  epochs=num_epochs,
  validation_data=validation_generator,
  validation_steps=floor(length(list.files('../dr_data/cnn_binary_data_4/valid_dir/',recursive=TRUE))/batch_size_val),
  callbacks = callback_reduce_lr_on_plateau( monitor = "val_acc", factor = 0.5, patience = 3, min_lr = 0.00001 ),
  class_weight = list( '0'=Vect_weight_per_class[1],'1'=Vect_weight_per_class[2] )
)

save_model_hdf5(model, filepath=paste0('../dr_models/xception_binary_classifier_4_full_arch_avg_pool.h5'))


