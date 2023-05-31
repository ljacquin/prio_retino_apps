[<img src="Gaiha_prio_retino_plus.png" width=250/>](https://gaiha.org/fr/prioretino/)

# Data management

## Data collection

### Diabetic retinopathy and maculopathy

The collected data correspond to 80039 fundus images provided by the EyePACS screening platform and Asia Pacific Tele-Ophthalmology Society (APTOS). 

The 80039 images were obtained from EyePACS and APTOS, who provided 88702 and 3662 images respectively, after manually excluding bad quality images.  Bad quality images were defined as dark or blurred or low resolution images.

The links of the original datasets are given below :

* https://www.kaggle.com/competitions/diabetic-retinopathy-detection/overview

* https://www.kaggle.com/competitions/aptos2019-blindness-detection/overview

The 53576 labels of the EyePACS test dataset is available through the link below:

* https://www.kaggle.com/datasets/benjaminwarner/resized-2015-2019-blindness-detection-images

The 53576 and 35126 labels of the EyePACS test and train datasets respectively, and the 3662 APTOS train labels, were concatenated into a unique dataset with 92364 labels.  

Hence a total of 12325 (= 92364 - 80039) images were excluded after quality inspection in order to obtain our base dataset corresponding to 80039 images.

Voets et al. (2019) found that approximately 20% of the EyePACS images were ungradable, which is higher but consistent with the number of images that we excluded (https://pubmed.ncbi.nlm.nih.gov/31170223/).  

Note that the EyePACS dataset was designed for ethnic diversity and does not have any inherent issues with diversity or bias (https://arxiv.org/pdf/2004.13515.pdf).

### Glaucoma

The collected data correspond to 101442 color fundus images, from 54274 subjects and approximately 500 different sites with a heterogeneous ethnicity, provided by the  EyePACS AIROGS (https://airogs.grand-challenge.org/data-and-challenge/).  

Only one image from the collected data did not correspond to a fundus image and was excluded, the remaining 101441 images were all gradable and used as our base dataset. 

