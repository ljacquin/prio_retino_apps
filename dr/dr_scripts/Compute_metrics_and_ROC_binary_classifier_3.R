# ========================================#
# Load packages and set working directory #
# ========================================#
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

img_size <- 299
img_path <- "../dr_data/cnn_binary_data_3/test_dir/all_test_data/"
maculo_data_path <- "../dr_data/cnn_binary_data_3/test_dir/test_maculopathy/"
non_rDR_data_path <- "../dr_data/cnn_binary_data_3/test_dir/test_non_rDR/"
model <- load_model_hdf5("../dr_models/xception_binary_classifier_3_full_arch_avg_pool_epochs_5.h5")

Test_image_labels <- rbind(
  data.frame("level" = "maculo", "image_id" = list.files(maculo_data_path)),
  data.frame("level" = "non_rDR", "image_id" = list.files(non_rDR_data_path))
)

Vect_true_class <- Test_image_labels$level
Vect_pred_class <- rep("None", nrow(Test_image_labels))
Vect_pos_class_prob <- rep(Inf, nrow(Test_image_labels))

for (i in 1:nrow(Test_image_labels))
{
  img <- image_load(paste0(img_path, Test_image_labels$image_id[i]), target_size = c(img_size, img_size))
  x <- image_to_array(img)
  x <- array_reshape(x, c(1, dim(x)))
  x <- x / 255
  Vect_pos_class_prob[i] <- 1 - as.numeric(model %>% predict(x))
  ifelse((Vect_pos_class_prob[i] > 0.5), Vect_pred_class[i] <- "maculo", Vect_pred_class[i] <- "non_rDR")
}

df_class_pred_prob <- data.frame("True_class" = as.factor(Vect_true_class), "Pred_class" = as.factor(Vect_pred_class), "Pos_class_prob" = as.numeric(Vect_pos_class_prob))

lvs <- c("non_rDR", "maculo")
truth <- factor(df_class_pred_prob$True_class, levels = rev(lvs))
pred <- factor(df_class_pred_prob$Pred_class, levels = rev(lvs))

conf_mat <- confusionMatrix(reference = truth, pred)
conf_mat


pROC_obj <- roc(
  response = as.factor(df_class_pred_prob$True_class), predictor = df_class_pred_prob$Pos_class_prob, smoothed = TRUE,
  # arguments for ci
  ci = TRUE, ci.alpha = 0.9, stratified = FALSE,
  # arguments for plot
  plot = TRUE, auc.polygon = TRUE, max.auc.polygon = TRUE, grid = TRUE,
  print.auc = TRUE, show.thres = TRUE
)
sens.ci <- ci.se(pROC_obj)
plot(sens.ci, type = "shape", col = "lightblue")

# Vect_id_false_neg <- Test_image_labels$image_id[which((Vect_true_class == "maculo") & (Vect_pred_class == "non_rDR"))]
# writeLines(Vect_id_moderate, '../dr_results/false_negative_severe_prolif_DR')
