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
setwd('../DR_DATA/ORIGINAL_DATA/')


#====================================#
# Convert existing tif images to jpg #
#====================================#
Center_images_LAC=FALSE
Vect_file_names<-list.files()
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
    save.image(new_img,paste0('../PROCESSED_DATA/',img_name),quality=1)
  }  
}


























# img_name<-Vect_file_names[3]
# img <- image_read(img_name)
# img <- image_scale(img, desired_size)
# img <- image_resize(img, desired_size)
# img <- magick2cimg(img)
# blur_img<-boxblur(img, blur_factor)
# new_img <- img - blur_img
# dev.new()
# plot(new_img, main='blur=100')
# dev.new()
# plot(img, main='original image')

# img_name<-'../0cae727cf119.png'
# img_openIR<-readImage(img_name)
# img_openIR<-resizeImage(img_openIR, width=500, height=500, method = 'bilinear')
# img_openIR<-cropImage(img_openIR, new_width=350, new_height=350, type='equal_spaced')
# imageShow(img_openIR)

# img <- image_read(img_name)
# img <- image_scale(img, 500)
# img <- image_resize(img, 500)
# img <- magick2cimg(img)
# new_img <- img - boxblur(img, 15)

# dev.new()
# par(mfrow=c(1,2))
# plot()
# plot()

# dev.new()
# plot(boundaries(as.raster(new_img), type='inner'))
# ##
# img <- image_read("10_left.jpeg")
# img <- image_scale(img, 300)
# img <- image_resize(img, 300)
# img <- magick2cimg(img)
# 
# blur_img<-boxblur(img, 15)
# new_img <- img - blur_img
# plot(new_img)
# 
# save.image(new_img,"test.jpeg",quality=1)
# 
# 
# ##
# img_2 <- image_read("1024_left.jpeg")
# img_2 <- image_scale(img_2, 300)
# img_2 <- image_resize(img_2, 300)
# img_2 <- magick2cimg(img_2)
# 
# blur_img_2 <-boxblur(img_2, 15)
# new_img_2 <- img_2 - blur_img_2
# 
# dev.new()
# par(mfrow=c(2,2))
# plot(img)
# plot(new_img)
# plot(img_2)
# plot(new_img_2)



