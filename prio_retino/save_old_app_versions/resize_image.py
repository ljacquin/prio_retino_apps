import cv2
import numpy as np
import matplotlib.cm as cm
import tensorflow as tf
from tensorflow.keras.models import load_model, Model
from tensorflow.keras.utils import load_img, img_to_array, array_to_img


def resize_image(image, target_size=299):
    arr_ = img_to_array(image)
    img_ = array_to_img(cv2.resize(arr_, tuple([int(target_size), int(target_size)])))
    return img_
