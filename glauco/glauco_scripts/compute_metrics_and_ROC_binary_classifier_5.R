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
img_path='../glauco_data/cnn_binary_data_5/test_dir/'
model=load_model_hdf5('../glauco_model/xception_binary_classifier_5_full_arch_avg_pool_augment_new_data_ratio_10_1_epochs_7.h5')

test_images<-list.files(img_path)
test_image_labels<-as.data.frame(fread('../glauco_labels/test_image_labels_binary_data_5.csv'))
print(identical(test_images, test_image_labels$image_id))

Vect_true_class<-test_image_labels$class
Vect_pred_class<-rep('None', length(test_images))
Vect_pos_class_prob<-rep(Inf, length(test_images))

for ( i in 1:length(test_images) )
{
  img <- image_load( paste0(img_path,test_images[i]), target_size = c(img_size,img_size))
  x <- image_to_array(img)
  x <- array_reshape(x, c(1, dim(x)))
  x<-x/255
  Vect_pos_class_prob[i]<-as.numeric(model %>% predict(x))
  ifelse( (Vect_pos_class_prob[i] > 0.5), Vect_pred_class[i]<-'RG', Vect_pred_class[i]<-'NRG' )
}

df_class_pred_prob<-data.frame('True_class'=as.factor(Vect_true_class), 'Pred_class'=as.factor(Vect_pred_class), 'Pos_class_prob'=as.numeric(Vect_pos_class_prob) )

lvs <- c("NRG", "RG")
truth<-factor(df_class_pred_prob$True_class, levels = rev(lvs))
pred<-factor(df_class_pred_prob$Pred_class, levels = rev(lvs))

conf_mat<-confusionMatrix(reference=truth, pred)
conf_mat

pROC_obj <- roc( response=as.factor(df_class_pred_prob$True_class), predictor=df_class_pred_prob$Pos_class_prob, smoothed = TRUE,
                 # arguments for ci
                 ci=TRUE, ci.alpha=0.9, stratified=FALSE,
                 # arguments for plot
                 plot=TRUE, auc.polygon=TRUE, max.auc.polygon=TRUE, grid=TRUE,
                 print.auc=TRUE, show.thres=TRUE
                 )
sens.ci <- ci.se(pROC_obj)
plot(sens.ci, type="shape", col="lightblue")

Vect_id_NRG_false_pos<-test_image_labels$image_id[ which( (Vect_true_class=='NRG')&(Vect_pred_class=='RG') ) ]
writeLines(Vect_id_NRG_false_pos, '../glauco_results/Vect_id_NRG_false_pos')

Vect_id_RG_false_neg<-test_image_labels$image_id[ which( (Vect_true_class=='RG')&(Vect_pred_class=='NRG') ) ]
writeLines(Vect_id_RG_false_neg, '../glauco_results/Vect_id_RG_false_neg')



