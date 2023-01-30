import cv2
import imquality.brisque as brisque


def compute_image_brisque_score_2(img):
    img_score = brisque.score(img)
    return img_score
