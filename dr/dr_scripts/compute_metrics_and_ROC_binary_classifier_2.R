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
img_qual_tresh <- 32

img_path <- "../dr_data/cnn_binary_data_2/test_dir/"
model <- load_model_hdf5("../dr_models/xception_binary_classifier_2_full_arch_avg_pool_ratio_2_1_epochs_9.h5")

img_qual_score_df <- as.data.frame(fread('../dr_data/image_size_150_brisque_score.csv')) 
bad_qual_img <- c(readLines('../dr_results/moderate_rDR_test_data_bad_qual_img'), 
                  readLines('../dr_results/severe_prolif_rDR_test_data_bad_qual_img'))

Test_image_labels <- as.data.frame(fread("../dr_labels/test_image_labels_binary_data_2.csv"))
Test_image_labels$qual_score <- img_qual_score_df$score[match(Test_image_labels$image_id, 
                                                              img_qual_score_df$image)]

# keep images with acceptable quality based on threshold and visual inspection
Test_image_labels <- Test_image_labels[Test_image_labels$qual_score < img_qual_tresh, ]
Test_image_labels <- Test_image_labels[-match(bad_qual_img,Test_image_labels$image_id), ]

Vect_true_class <- Test_image_labels$level
Vect_pred_class <- rep("None", nrow(Test_image_labels))
Vect_pos_class_prob <- rep(Inf, nrow(Test_image_labels))

for (i in 1:nrow(Test_image_labels))
{
  img <- image_load(paste0(img_path, Test_image_labels$image_id[i]), target_size = c(img_size, img_size))
  x <- image_to_array(img)
  x <- array_reshape(x, c(1, dim(x)))
  x <- x / 255
  Vect_pos_class_prob[i] <- as.numeric(model %>% predict(x))
  ifelse((Vect_pos_class_prob[i] > 0.5), Vect_pred_class[i] <- "severe_prolif_DR", Vect_pred_class[i] <- "moderate_DR")
}

df_class_pred_prob <- data.frame("True_class" = as.factor(Vect_true_class), "Pred_class" = as.factor(Vect_pred_class), "Pos_class_prob" = as.numeric(Vect_pos_class_prob))

lvs <- c("moderate_DR", "severe_prolif_DR")
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

# vect_id_false_neg <- Test_image_labels$image_id[which((Vect_true_class == "severe_prolif_DR") & (Vect_pred_class == "moderate_DR"))]
# vect_id_false_pos <- Test_image_labels$image_id[which((Vect_true_class == "moderate_DR") & (Vect_pred_class == "severe_prolif_DR"))]
# 
# file.copy(paste0("../dr_data/original_data/",vect_id_false_neg),
#           overwrite = TRUE, "../dr_results/severe_prolif_rDR_pred_as_moderate_rDR_IE_FN/")
# 
# file.copy(paste0("../dr_data/original_data/",vect_id_false_pos),
#           overwrite = TRUE, "../dr_results/moderate_rDR_pred_as_false_severe_prolif_rDR_IE_FP/")
