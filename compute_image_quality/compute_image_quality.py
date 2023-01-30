import os
import pandas as pd
import math
import imquality.brisque as brisque
import logging
from tqdm import tqdm
import multiprocessing
from joblib import Parallel, delayed
from tensorflow.keras.utils import load_img

logger = logging.Logger('catch_all')
num_cores = math.floor(multiprocessing.cpu_count() / 1.5)
img_size_qual_ = 150


def get_img_brisque_score(image_, img_size_qual_):
    img = load_img(image_, target_size=(img_size_qual_, img_size_qual_))
    return brisque.score(img)


def get_img_brisque_score_df(list_image_, img_size_qual_, batch_size_):
    df_image_score = pd.DataFrame({'image': [], 'score': []})
    try:
        list_score_ = []
        for i in tqdm(range(0, len(list_image_), batch_size_)):
            list_image_batch_ = list_image_[i:i + batch_size_]
            list_score_batch_ = Parallel(n_jobs=num_cores)(delayed(get_img_brisque_score)(image_, img_size_qual_)
                                                           for image_ in list_image_batch_)
            list_score_ = list_score_ + list_score_batch_
        df_image_score['image'] = list_image_
        df_image_score['score'] = list_score_
    except Exception as e:
        logger.exception('Could not get the score of an image, here is the possible issue: ' + str(e))
        pass
    return df_image_score


input_dir = '/home/laval/Documents/GAIHA/GAIHA_APPS/PRIO_RETINO/DR_DATA/ORIGINAL_DATA'
os.chdir(input_dir)
list_images = os.listdir()

df_img_brisque_score = get_img_brisque_score_df(list_image_=list_images, img_size_qual_=150, batch_size_=100)

os.chdir('/home/laval/Documents/GAIHA/GAIHA_APPS/PRIO_RETINO/DR_APPS/prio_retino_apps/compute_image_quality/')
df_img_brisque_score.to_csv('image_size_'+str(img_size_qual_)+'_brisque_score.csv', sep=',', index=None)