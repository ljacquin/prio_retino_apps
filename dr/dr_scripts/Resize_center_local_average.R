#=========================================#
# Load packages and set working directory #
#=========================================#
library(rstudioapi)
library(data.table)
library(jpeg)
library(png)
library(imager)
library(magick)
library(stringr)
library(OpenImageR)
setwd(dirname(getActiveDocumentContext()$path))
setwd('../dr_data/original_data/')

#============================================#
# Resize and center image with local average #
#============================================#
Resize_and_CLA=FALSE
Vect_file_names<-list.files()
desired_size=1024
blur_factor=100

if ( Resize_and_CLA & (length(Vect_file_names)>=1) )
{
  for (img_name in Vect_file_names )
  {
    img <- image_read(img_name)
    img <- image_scale(img, desired_size)
    img <- image_resize(img, desired_size)
    img <- magick2cimg(img)
    blur_img<-boxblur(img, blur_factor)
    new_img <- img - blur_img
    save.image(new_img,paste0('../processed_data/',img_name),quality=1)
  }  
}
