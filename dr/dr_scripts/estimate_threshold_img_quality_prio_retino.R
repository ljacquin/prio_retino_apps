library(data.table)
library(stringr)
library(rstudioapi)
setwd(dirname(getActiveDocumentContext()$path))

Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}
df_img_score <- as.data.frame(fread('../dr_data/image_size_150_brisque_score.csv'))
df_img_score$quality <- 0
dev.new()
hist(df_img_score$score, xlim = c(-20,100))

score_thresh <- ceiling(quantile(df_img_score$score, probs = 0.97))
score_thresh
