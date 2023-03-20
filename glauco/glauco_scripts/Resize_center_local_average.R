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
## library(OpenImageR)
setwd(dirname(getActiveDocumentContext()$path))
setwd('../glauco_data/original_data/')


#====================================#
# Convert existing tif images to jpg #
#====================================#
Center_images_LAC=TRUE
Vect_file_names<-setdiff(list.files(),list.files('../processed_data/'))
desired_size=1024
blur_factor=100

if ( Center_images_LAC & (length(Vect_file_names)>=1) )
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

