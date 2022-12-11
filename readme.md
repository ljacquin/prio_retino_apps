[<img src="prio_retino/www/AI_PRIO_RETINO.png"/>](https://gaiha.org/fr/)

# Gaiha Prio Retino Application for Diabetic Retinopathy Screening

## Setup

The setup is based on Ubuntu 22.04.1 LTS and can possibly work for much newer versions, even though this is not guaranteed. 

The Gaiha Prio Retino app.R script runs using Python~=3.10, R~=4.2.1 (or possibly much newer version), Tensorflow~=2.11 and other dependencies.

### 1. Installing Python and R

Ubuntu 22.04.1 LTS comes with Python 3.10, so there is no need to install it. On the other hand, R 4.2.1 can be installed using the following commands:

* sudo apt update
* sudo apt install r-base

### 2. Installing shiny server

Shiny server can be downloaded and installed using the following commands:

* sudo su - \ -c "R -e \"install.packages('shiny', repos='https://cran.rstudio.com/')\""

* sudo apt install gdebi-core

* wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.19.995-amd64.deb

* sudo gdebi shiny-server-1.5.19.995-amd64.deb

### 3. Installing Gaiha Prio Retino app dependencies (i.e. Tensorflow, Keras, OpenCV, etc.) :

In the shell, type the following command for user shiny:

* sudo su shiny

Then type the following command to install app.R dependencies:

* R -q --vanilla < r_requirements.R

Note, if some packages cannot be installed due do some missing dependencies then install these before launching the above command again. One can also open the R console and install the packages in the r_requirements.R file by copy-pasting its content.


### 4. Run Gaiha Prio Retino app locally:

The Gaiha Prio Retino app can be launched locally, from the prio_retino folder, using the following command in the R console :

* runApp()

### Example hosted on AWS: 

https://secured.gaiha.org/prio_retino/
