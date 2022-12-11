# =========================================#
# Load packages and set working directory #
# =========================================#
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
img_path <- "../DR_DATA/CNN_BINARY_DATA_2/test_dir/"
model <- load_model_hdf5("../DR_APPS/PRIO_RETINO_MODELS/xception_binary_classifier_2_full_arch_avg_pool_ratio_2_1_epochs_9.h5")

Test_image_names <- list.files(img_path)
Test_image_labels <- as.data.frame(fread("../DR_LABELS/Test_image_labels_binary_data_2.csv"))

Vect_true_class <- Test_image_labels$level
Vect_pred_class <- rep("None", length(Test_image_names))
Vect_pos_class_prob <- rep(Inf, length(Test_image_names))

for (i in 1:length(Test_image_names))
{
  img <- image_load(paste0(img_path, Test_image_names[i]), target_size = c(img_size, img_size))
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

Vect_id_moderate <- Test_image_labels$image_id[which((Vect_true_class == "moderate_DR") & (Vect_pred_class == "moderate_DR"))]
Vect_id_severe <- Test_image_labels$image_id[which((Vect_true_class == "severe_prolif_DR") & (Vect_pred_class == "severe_prolif_DR"))]
writeLines(Vect_id_moderate, "../DR_RESULTS/Moderate_DR_images.txt")
writeLines(Vect_id_severe, "../DR_RESULTS/Severe_prolif_DR_images.txt")
