# =========================================#
# Load packages and set working directory #
# =========================================#
library(data.table)
library(foreach)
library(doParallel)
library(jpeg)
library(png)
library(imager)
library(magick)
library(stringr)
## library(OpenImageR)
# library(rstudioapi)
# setwd(dirname(getActiveDocumentContext()$path))
setwd("../glauco_data/original_data/")
parallel::detectCores()
n.cores <- parallel::detectCores() - 2
#create the cluster
my.cluster <- parallel::makeCluster(
  n.cores, 
  type = "FORK"
)
#check cluster definition (optional)
print(my.cluster)
#register it to be used by %dopar%
doParallel::registerDoParallel(cl = my.cluster)
#check if it is registered (optional)
foreach::getDoParRegistered()
#how many workers are available? (optional)
foreach::getDoParWorkers()


# ====================================#
# Convert existing tif images to jpg #
# ====================================#
Center_images_LAC <- TRUE
file_names <- setdiff(list.files(), list.files("../processed_data/"))
desired_size <- 1024
blur_factor <- 100

list_vect_file_names <- split(file_names, ceiling(seq_along(file_names) / 1000))

if (Center_images_LAC & (length(file_names) >= 1)) {
  out_foreach <- foreach(i = 1:length(list_vect_file_names)) %dopar% {
    vect_file_names <- list_vect_file_names[[i]]
    for (img_name in vect_file_names)
    {
      img <- image_read(img_name)
      img <- image_scale(img, desired_size)
      img <- image_resize(img, desired_size)
      img <- magick2cimg(img)
      blur_img <- boxblur(img, blur_factor)
      new_img <- img - blur_img
      save.image(new_img, paste0("../processed_data/", img_name), quality = 1)
    }
  }
}
# close cluster once all parallel task are done
parallel::stopCluster(cl = my.cluster)

