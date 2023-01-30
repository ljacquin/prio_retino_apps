#=========================================#
# Load packages and set working directory #
#=========================================#
library(rstudioapi)
library(ROCR)
library(pROC)
library(PRROC)
library(verification)
library(data.table)
library(tensorflow)
library(keras)
library(caret)
setwd(dirname(getActiveDocumentContext()$path))

img_size=299
img_path='../DR_DATA/MACULOPATHY/'
model=load_model_hdf5('../DR_APPS/PRIO_RETINO_MODELS/xception_binary_classifier_full_arch_avg_pool.h5')

Maculo_image_names<-list.files(img_path)
Vect_pred_class<-rep('None', length(Maculo_image_names))
Vect_pred_class_prob<-rep(Inf, length(Maculo_image_names))

for ( i in 1:length(Maculo_image_names) )
{
  img <- image_load( paste0(img_path,Maculo_image_names[i]), target_size = c(img_size,img_size))
  x <- image_to_array(img)
  x <- array_reshape(x, c(1, dim(x)))
  x<-x/255
  Vect_pred_class_prob[i]<-as.numeric(model %>% predict(x))
  ifelse( (Vect_pred_class_prob[i] > 0.5), Vect_pred_class[i]<-'rDR', Vect_pred_class[i]<-'non_rDR' )
}

Non_detected_maculopathy =  Maculo_image_names[which(Vect_pred_class=='non_rDR')]

for ( i in 1:length(Non_detected_maculopathy) )
{
 file.copy(from = paste0('../DR_DATA/ORIGINAL_DATA/',Non_detected_maculopathy[i]),
           to = paste0('../DR_RESULTS/NON_DETECTED_MACULOPATHY/',Non_detected_maculopathy[i])) 
}

