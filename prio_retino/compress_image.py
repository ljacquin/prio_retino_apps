import os
from PIL import Image
os.chdir('/home/laval/Documents/gaiha/prio_retino_apps')
os.listdir()

import cv2


# from keras import backend as K
# import pandas as pd
# import numpy as np

def resize_image(name, desired_size=1024):
    img = cv2.imread(f"{name}")

    img = cv2.copyMakeBorder(img, 10, 10, 10, 10, cv2.BORDER_CONSTANT, value=[0, 0, 0])
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    ret, gray = cv2.threshold(gray, 10, 255, cv2.THRESH_BINARY)

    image, contours, hierarchy = cv2.findContours(gray, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    contours = max(contours, key=cv2.contourArea)
    x, y, w, h = cv2.boundingRect(contours)

    if w > 200 and h > 200:
        new_img = img[y:y + h, x:x + w]
        height, width, _ = new_img.shape

        if max([height, width]) > desired_size:
            ratio = float(desired_size / max([height, width]))
            new_img = cv2.resize(new_img,
                                 tuple([int(width * ratio), int(height * ratio)]),
                                 interpolation=cv2.INTER_CUBIC)

        cv2.imwrite(f'www/resized_cropped_target_image.jpg', new_img)
    else:
        cv2.imwrite(f'www/resized_cropped_target_image.jpg', img)



foo = Image.open('image_test_1.JPG')  # My image is a 200x374 jpeg that is 102kb large
foo.size  # (200, 374)

# downsize the image with an ANTIALIAS filter (gives the highest quality)
# foo = foo.resize((1024, 1024), Image.ANTIALIAS)

foo.save('image_test_1_opt.jpg', optimize=True)
# The saved downsized image size is 22.9kb


resize_image('image_test_1.JPG', 1024)