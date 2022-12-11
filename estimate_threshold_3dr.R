#---------------------------------------------------------------------------------------------#
# Copyright (C) 2018,  Laval Yannis Julien Jacquin (i.e. Trust Data Science)                  #
#---------------------------------------------------------------------------------------------#
# This file is part of the PRIO_RETINO software                                                       #
#                                                                                             #
# PRIO_RETINO software suite can be redistributed and/or modified under the terms of the              #
# GNU General Public License as published by the Free Software Foundation; either version 2   #
# of the License, or (at your option) any later version.                                      #
#                                                                                             #
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;   #
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   #
# See the GNU General Public License for more details.                                        #
#                                                                                             #
# You should have received a copy of the GNU General Public License along with this program;  #
# if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,           #
# Boston, MA  02110-1301  USA                                                                 #
#---------------------------------------------------------------------------------------------#
library(data.table)
library(stringr)
library(rstudioapi)
setwd(dirname(getActiveDocumentContext()$path))

Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

df_img_score <- as.data.frame(fread('compute_image_quality/Image_brisque_score.csv'))
df_img_score$quality <- 0
hist(df_img_score$score)

score_thresh <- ceiling(quantile(df_img_score$score, probs = 0.97))
# score_thresh <- ceiling(quantile(df_img_score$score, probs = 0.92))
df_img_score$quality[df_img_score$score < score_thresh] <- 1
non_quality_img <- df_img_score$image[df_img_score$quality == 0]


list_test_img_prio_retino <- list.files('/media/laval/SAUVEGARDE_KERIA/KER_IA/GAIHA/GAIHA_APPS/PRIO_RETINO_GAIHA/DR_DATA/CNN_BINARY_DATA_1/test_dir/')
id_test_img <- match(list_test_img_prio_retino, df_img_score$image)
df_img_score_test <- df_img_score[id_test_img, ]

writeLines(df_img_score_test$image[df_img_score_test$quality==1], paste0('test_img_quality_',score_thresh))

# file.copy(from = paste0('/media/laval/SAUVEGARDE_KERIA/KER_IA/GAIHA/GAIHA_APPS/PRIO_RETINO_GAIHA/DR_DATA/ORIGINAL_DATA/',non_quality_img),
          # to = '/media/laval/SAUVEGARDE_KERIA/KER_IA/GAIHA/GAIHA_APPS/PRIO_RETINO_GAIHA/DR_DATA/NON_QUALITY_DATA/')
# list_img_prio_retino <- list.files('/media/laval/SAUVEGARDE_KERIA/KER_IA/GAIHA/GAIHA_APPS/PRIO_RETINO_GAIHA/DR_DATA/ORIGINAL_DATA')



create_prio_retino_image_status <- FALSE
if ( create_prio_retino_image_status && !('img_prio_retino' %in% colnames(df_img_score)) ){

  list_img_prio_retino <- list.files('/media/laval/SAUVEGARDE_KERIA/KER_IA/GAIHA/GAIHA_APPS/PRIO_RETINO_GAIHA/DR_DATA/CNN_BINARY_DATA_1', recursive = TRUE)
  length(list_img_prio_retino)
  list_img_prio_retino <- str_replace_all(list_img_prio_retino, pattern = 'test_dir/', replacement = '')
  list_img_prio_retino <- str_replace_all(list_img_prio_retino, pattern = 'train_dir/', replacement = '')
  list_img_prio_retino <- str_replace_all(list_img_prio_retino, pattern = 'valid_dir/', replacement = '')
  list_img_prio_retino <- str_replace_all(list_img_prio_retino, pattern = 'train_rDR/', replacement = '')
  list_img_prio_retino <- str_replace_all(list_img_prio_retino, pattern = 'train_non_rDR/', replacement = '')
  list_img_prio_retino <- str_replace_all(list_img_prio_retino, pattern = 'valid_rDR/', replacement = '')
  list_img_prio_retino <- str_replace_all(list_img_prio_retino, pattern = 'valid_non_rDR/', replacement = '')
  length(list_img_prio_retino)
  idx_prio_retino <-  df_img_score$image %in% list_img_prio_retino
  sum(idx_prio_retino)
  
  df_img_score$img_prio_retino <- FALSE
  df_img_score$img_prio_retino[idx_prio_retino] <- TRUE
  sum(df_img_score$img_prio_retino)
  tail(list_img_prio_retino, 1000)
}



