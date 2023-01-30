import cv2
import imquality.brisque as brisque


def compute_image_brisque_score(name):
    img = cv2.imread(f"{name}")
    img_score = brisque.score(img)
    return img_score
