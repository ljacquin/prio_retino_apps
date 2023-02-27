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
img_path='../dr_data/cnn_binary_data_1/test_dir/'
model=load_model_hdf5('../dr_models/xception_binary_classifier_1_full_arch_avg_pool_ratio_10_1_epochs_11.h5')

Test_image_names<-list.files(img_path)
Test_image_labels<-as.data.frame(fread('../dr_labels/test_image_labels_binary_data_1.csv'))
print(identical(Test_image_labels$image_id, Test_image_names))

Vect_true_class<-Test_image_labels$level
Vect_pred_class<-rep('None', length(Test_image_names))
Vect_pos_class_prob<-rep(Inf, length(Test_image_names))
# Vect_true_class_pred_prob<-rep(Inf, length(Test_image_names))

for ( i in 1:length(Test_image_names) )
{
  img <- image_load( paste0(img_path,Test_image_names[i]), target_size = c(img_size,img_size))
  x <- image_to_array(img)
  x <- array_reshape(x, c(1, dim(x)))
  x<-x/255
  Vect_pos_class_prob[i]<-as.numeric(model %>% predict(x))
  ifelse( (Vect_pos_class_prob[i] > 0.5), Vect_pred_class[i]<-'rDR', Vect_pred_class[i]<-'non_rDR' )
}

df_class_pred_prob<-data.frame('True_class'=as.factor(Vect_true_class), 'Pred_class'=as.factor(Vect_pred_class), 'Pos_class_prob'=as.numeric(Vect_pos_class_prob) )

lvs <- c("non_rDR", "rDR")
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

# Vect_id_non_rDR<-Test_image_labels$image_id[ which( (Vect_true_class=='non_rDR')&(Vect_pred_class=='non_rDR') ) ]
# writeLines(sample(Vect_id_non_rDR,size=500,replace=FALSE), '../dr_results/true_negative_non_rDR')

# Vect_id_rDR_false_pred<-Test_image_labels$image_id[ which( (Vect_true_class=='rDR')&(Vect_pred_class=='non_rDR') ) ]
# writeLines(Vect_id_rDR_false_pred, '../dr_results/false_negative_rDR')



