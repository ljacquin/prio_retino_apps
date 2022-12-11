import cv2


def resize_transformed_image_explanation(name, desired_size=1024):
    img = cv2.imread(f"{name}")

    img = cv2.copyMakeBorder(
        img, 10, 10, 10, 10, cv2.BORDER_CONSTANT, value=[0, 0, 0])
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    ret, gray = cv2.threshold(gray, 10, 255, cv2.THRESH_BINARY)

    image, contours, hierarchy = cv2.findContours(
        gray, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    contours = max(contours, key=cv2.contourArea)
    x, y, w, h = cv2.boundingRect(contours)

    if w > 100 and h > 100:
        new_img = img[y:y+h, x:x+w]
        height, width, _ = new_img.shape

        ratio = float(desired_size/max([height, width]))
        new_img = cv2.resize(new_img,
                             tuple([int(width*ratio), int(height*ratio)]),
                             interpolation=cv2.INTER_CUBIC)

        cv2.imwrite(
            f'www/resized_transformed_target_image_explanation.jpg', new_img)
