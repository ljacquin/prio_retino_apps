#---------------------------------------------------------------------------------------------#
# Copyright (C) 2022, Gaiha, Author:  Laval Yannis Julien Jacquin                             #
#---------------------------------------------------------------------------------------------#
# This file is part of the Prio Retino software                                               #
#                                                                                             #
# Prio Retino software suite can be redistributed and/or modified under the terms of the      #
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
options(rlib_downstream_check = FALSE)
library(devtools)
library(reticulate)
install_tensorflow_python_packages <- FALSE
if (install_tensorflow_python_packages) {
  install_miniconda(path = miniconda_path(), update = TRUE, force = FALSE)
  conda_create("prio_retino", python_version = "3.10")
  use_condaenv(condaenv = "prio_retino")
  library(tensorflow)
  install_tensorflow(version = "2.11.0", envname = "prio_retino")
  py_install("image-quality-1.2.7/", envname = "prio_retino", pip = TRUE)
  # if command above does not work use the following in shell
  # sudo /home/shiny/.local/share/r-miniconda/envs/prio_retino/bin/python -m pip install -e image-quality-1.2.7/
  py_install("matplotlib", envname = "prio_retino", pip = TRUE)
  py_install("opencv-python~=3.4.2", envname = "prio_retino", pip = TRUE)
  py_install("h5py~=3.7.0", envname = "prio_retino", pip = TRUE)
  py_config()
  py_available()
  py_module_available("cv2")
  py_module_available("imquality")
}
use_condaenv(condaenv = "prio_retino")
cv2 <- import("cv2")
imquality <- import("imquality")
library(tensorflow)
library(keras)
library(shiny)
library(shinyjs)
library(V8)
library(magick)
library(imager)
library(viridis)
library(data.table)
library(png)
library(stringr)
library(shinymanager)
library(shinycustomloader)
library(shiny.i18n)
library(shinyWidgets)
library(rstudioapi)
setwd(dirname(getActiveDocumentContext()$path))
options(encoding = "UTF-8")
source_python("resize_image.py")
source_python("grad_cam_2.py")
source_python("compute_image_brisque_score.py")
source_python("compute_image_brisque_score_2.py")

# desired_size <<- 1024
# blur_factor <<- 100
img_size_cnn <<- 150
resize_img = TRUE

dir_ = '../../../random_test_images/'
file_names = paste0(dir_, list.files(dir_))
vect_dist <- rep(0, length(file_names))
vect_time <- rep(0, length(file_names))

for (i in 1:length(vect_dist)) {
  print(i)
  file_name <- file_names[i]
  print(file_name)
  begin <- Sys.time()
  if (resize_img) {
    resized_cropped_target_image <- image_read(file_name)
    # save and resize transformed target image
    tmpF_orig_img <- tempfile(fileext = ".png")
    save.image(
      magick2cimg(resized_cropped_target_image),
      tmpF_orig_img,
      quality = 1
    )
    resized_cropped_target_image <- image_load(tmpF_orig_img,
      target_size = c(img_size_cnn, img_size_cnn)
    )
    vect_dist[i] = compute_image_brisque_score_2(resized_cropped_target_image)
  }else{
    vect_dist[i] = compute_image_brisque_score(file_name)
  }
  vect_time[i] = as.numeric(Sys.time() - begin)
}
vect_dist

# if ( !resize_img ){
#   vect_dist_orig = vect_dist
#   mean_time_orig = signif(mean(vect_time),2)
# }
# vect_dist_orig
# mean_time_orig
# 
# if ( img_size_cnn == 512 ){
#   vect_dist_512 = vect_dist
#   mean_time_512 = signif(mean(vect_time),2)
# }
# 
# if ( img_size_cnn == 299 ){
#   vect_dist_299 = vect_dist
#   mean_time_299 = signif(mean(vect_time),2)
# }
# 
# if ( img_size_cnn == 150 ){
#   vect_dist_150 = vect_dist
#   mean_time_150 = signif(mean(vect_time),2)
# }
# 
# if ( img_size_cnn == 100 ){
#   vect_dist_100 = vect_dist
#   mean_time_100 = signif(mean(vect_time),2)
# }
# 
# cor(vect_dist_orig, vect_dist_512)
# cor(vect_dist_orig, vect_dist_299)
# cor(vect_dist_orig, vect_dist_150)
# cor(vect_dist_orig, vect_dist_100)
# 
# mean_time_512
# mean_time_299
# mean_time_150
# mean_time_100


