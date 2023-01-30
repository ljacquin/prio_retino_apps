#---------------------------------------------------------------------------------------------#
# Copyright (C) 2022, Gaiha, Author:  Laval Yannis Julien Jacquin                             #
#---------------------------------------------------------------------------------------------#
# This file is part of the Prio Retino+ software                                              #
#                                                                                             #
# Prio Retino+ software suite can be redistributed and/or modified under the terms of the     #
# GNU General Public License as published by the Free Software Foundation; either version 2   #
# of the License, or (at your option) any later version.                                      #
#                                                                                             #
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;   #
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   #
# See the GNU General Public License for more details.                                        #
#                                                                                             #
# You should have received a copy of the GNU General Public License along with this program;  #
# if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,           #
# Boston, MA  02110-1301  USA                                                                 #
#---------------------------------------------------------------------------------------------#
options(rlib_downstream_check = FALSE)
library(devtools)
library(reticulate)
install_tensorflow_python_packages <- FALSE
if (install_tensorflow_python_packages) {
  install_miniconda(path = miniconda_path(), update = TRUE, force = FALSE)
  conda_create("prio_retino", python_version = "3.10")
  use_condaenv(condaenv = "prio_retino")
  library(tensorflow)
  install_tensorflow(version = "2.11.0", envname = "prio_retino")
  py_install("image-quality-1.2.7/", envname = "prio_retino", pip = TRUE)
  # if command above does not work use the following in shell
  # sudo /home/shiny/.local/share/r-miniconda/envs/prio_retino/bin/python -m pip install -e image-quality-1.2.7/
  py_install("matplotlib", envname = "prio_retino", pip = TRUE)
  py_install("opencv-python~=3.4.2", envname = "prio_retino", pip = TRUE)
  py_install("h5py~=3.7.0", envname = "prio_retino", pip = TRUE)
  py_config()
  py_available()
  py_module_available("cv2")
  py_module_available("imquality")
}
use_condaenv(condaenv = "prio_retino")
cv2 <- import("cv2")
imquality <- import("imquality")
library(tensorflow)
library(keras)
library(shiny)
library(shinyjs)
library(V8)
library(magick)
library(imager)
library(viridis)
library(data.table)
library(png)
library(stringr)
library(shinymanager)
library(shinycustomloader)
library(shiny.i18n)
library(shinyWidgets)
# library(rstudioapi)
# setwd(dirname(getActiveDocumentContext()$path))
options(encoding = "UTF-8")
source_python("img_resize_quality_functions.py")
source_python("grad_cam_functions.py")


# Set countries languages
countries <- c(
  "English", "Français",
  "Português"
)
flags <- c(
  "us.png", "french.png",
  "portugal.png"
)

# File with translations
i18n <- Translator$new(translation_json_path = "prio_retino_translation.json")
i18n$set_translation_language("English")


#####################
#### Credentials ####
#####################
tryCatch(
  {
    prio_retino_credentials <<- as.data.frame(fread("../prio_retino_credential_usage/prio_retino_credential_usage.csv",
                                                    header = TRUE
    ))
    fwrite(prio_retino_credentials, file = "../prio_retino_credential_usage/prio_retino_credential_usage_save.csv")
  },
  error = function(err) {
    prio_retino_credentials <<- as.data.frame(fread("../prio_retino_credential_usage/prio_retino_credential_usage_save.csv",
                                                    header = TRUE
    ))
  }
)


# data.frame with credentials info
credentials <- data.frame(
  user = prio_retino_credentials$Login,
  password = prio_retino_credentials$Password,
  stringsAsFactors = FALSE
)

#########################################
### Prio Retino+ models and parameters ###
#########################################

# CNN model and parameters
if (!exists("cnn_binary_classifier_1") && !exists("cnn_binary_classifier_2") && !exists("cnn_binary_classifier_3") &&
    !exists("cnn_binary_classifier_4") && !exists("cnn_binary_classifier_5")
) {
  cnn_binary_classifier_1 <<- load_model("xception_binary_classifier_1_full_arch_avg_pool_ratio_10_1_epochs_11.h5")
  cnn_binary_classifier_2 <<- load_model("xception_binary_classifier_2_full_arch_avg_pool_ratio_2_1_epochs_9.h5")
  cnn_binary_classifier_3 <<- load_model("xception_binary_classifier_3_full_arch_avg_pool.h5")
  cnn_binary_classifier_4 <<- load_model("xception_binary_classifier_4_full_arch_avg_pool.h5")
  cnn_binary_classifier_5 <<- load_model("xception_binary_classifier_5_full_arch_avg_pool_augment_new_data_ratio_10_1_epochs_7.h5")
}
img_size_cnn <<- as.numeric(scan("img_size_cnn.txt"))

# Raw image parameters
desired_size <<- 1024
img_size_qual <<- 150 
blur_factor <<- 100
img_qual_tresh <<- 32

# Output image parameters
width_img_size <<- 540
height_img_size <<- 450

# grad-cam parameter
last_conv_layer_name <<- "block14_sepconv2_act"

# compute quality
compute_quality <<- FALSE

# convert output images to low quality to increase rendering speed
convert_magick2cimg <<- TRUE
annotation_color_ <<- "none"  #render in white

# Loading CSS content
appCSS <- "
#loading-content {
  position: absolute;
  background: #000000;
  opacity: 0.9;
  z-index: 100;
  left: 0;
  right: 0;
  height: 100%;
  text-align: center;
  color: #FFFFFF;
}
"

################################
### User interface component ###
################################
ui <- secure_app(
  choose_language = FALSE,
  tags_top = tags$img(src = "Gaiha_prio_retino_login.png", width = 300),
  
  # ui <- fluidPage(
  fluidPage(
    HTML('<meta name="viewport" content="width=1024">'),
    useShinyjs(),
    inlineCSS(appCSS),
    
    # Loading message
    div(
      id = "loading-content",
      h2(i18n$t("Loading Prio Retino+..."))
    ),
    
    # Language selection
    shiny.i18n::usei18n(i18n),
    div(
      style = "float: right;", class = "chooselang",
      pickerInput(
        inputId = "selected_language",
        label = i18n$t("Set Prio Retino+ language"),
        choices = i18n$get_languages(),
        selected = i18n$get_key_translation(),
        choicesOpt = list(
          content =
            mapply(countries, flags, FUN = function(country, flagUrl) {
              HTML(paste(
                tags$img(src = flagUrl, width = 20, height = 15),
                country
              ))
            }, SIMPLIFY = FALSE, USE.NAMES = FALSE)
        )
      )
    ),
    
    # The main app code goes here
    hidden(
      div(
        id = "app-content",
        titlePanel("", windowTitle = "Gaiha | Prio Retino+"),
        sidebarLayout(
          sidebarPanel(
            HTML('<center><img src="Logo_GAIHA.PNG" width="110"></header>'),
            column(width = 1, offset = 10, style = "padding:6px;"),
            #
            titlePanel(h5(p(strong(i18n$t("Do not refresh the page, press 'Reset' to clean up before each new analysis"))),
                          style = "color:red", align = "left"
            )),
            actionButton("reset", i18n$t("Reset")),
            titlePanel(h5(p(""), align = "left")),
            #
            textInput("patient_id", i18n$t("Insert patient identifier"), value = ""),
            fileInput(
              input = "file1",
              label = i18n$t("Upload fundus image"),
              accept = c(".png", ".jpeg", ".jpg")
            ),
            selectInput("element_id",
                        label = p(i18n$t("Display pre-diagnostic results for :"),
                                  style = "text-align:center;color:red;font-size:100%"
                        ),
                        c("Diabetic retinopathy and/or maculopathy", "Glaucoma")
            ),
            verbatimTextOutput("res_auth"),
            width = 3
          ),
          mainPanel(
            tags$style(
              type = "text/css", ".shiny-output-error { visibility: hidden; }",
              ".shiny-output-error:before { visibility: hidden; }"
            ),
            tags$head(
              tags$style("#text1{color: blue;
                             font-size: 50px;
                             font-style: italic;
                             }")
            ),
            conditionalPanel(
              'input.element_id=="Diabetic retinopathy and/or maculopathy"||
               input.element_id=="Rétinopathie et/ou maculopathie diabétique"||
               input.element_id=="Retinopatia diabética e/ou maculopatia"',
              h4(htmlOutput("output_dr_prio_retino_text"), align = "left")
            ),
            conditionalPanel(
              'input.element_id=="Glaucoma"||
               input.element_id=="Glaucome"||
               input.element_id=="Glaucoma"',
              h4(htmlOutput("output_glauco_prio_retino_text"), align = "left")
            ),
            withLoader(imageOutput("outputImage"),
                       type = "image", loader = "computation_loader_new.gif"
            )
          )
        ),
        useShinyjs(),
        extendShinyjs(text = "shinyjs.winprint = function(){ window.print(); }", functions = c("winprint")),
        actionButton("print", i18n$t("Print Prio Retino+ results to PDF")),
        titlePanel(h6(p(strong(i18n$t("Remarks, definitions and recommendations:"))), style = "color:#0c7683", align = "left")),
        titlePanel(h6(i18n$t("- Prio Retino+ results are given on an idicative basis, the diagnosis should be established by an ophthalmologist"),
                      style = "color:#0c7683", align = "left"
        )),
        titlePanel(h6(i18n$t("- The analyzed data is deleted and not stored by Prio Retino+ after each reset"),
                      style = "color:#0c7683", align = "left"
        )),
        titlePanel(h6(i18n$t("- ICDR: International Clinical Diabetic Retinopathy severity scale; AAO: American Academy of Ophthalmology"),
                      style = "color:#0c7683", align = "left"
        )),
        titlePanel(h6(i18n$t("- Non referable diabetic retinopathy (DR): mild or no visible signs of DR according to ICDR. AAO recommendations: repeat examination annually for non referable DR"),
                      style = "color:#0c7683", align = "left"
        )),
        titlePanel(h6(i18n$t("- Referable diabetic retinopathy (DR): moderate or superior signs of DR according to ICDR. AAO recommendations: repeat examination within 6 or 3 months for moderate or superior signs of DR respectively"),
                      style = "color:#0c7683", align = "left"
        )),
        titlePanel(h6(i18n$t("- Non referable glaucoma: no visible sign or low-risk suspect for glaucoma. AAO recommendations: repeat examination annually"),
                      style = "color:#0c7683", align = "left"
        )),
        titlePanel(h6(i18n$t("- Referable glaucoma: true glaucoma, pre-perimetric glaucoma or high-risk suspect. AAO recommendations: repeat examination every 1 to 2 months until disease stabilization"),
                      style = "color:#0c7683", align = "left"
        )),
        h5(HTML(paste0(
          "<center><a href='https://keria.io/' target='_blank'><u><font color=\"#000000\">", i18n$t("Gaiha is a trademark of KerIA"),
          "</font></u> <img src='kerIA_logo_black.svg' width='25'/></a></center>"
        )))
      )
    )
  )
)


########################
### Server component ###
########################
server <- shinyServer(
  function(input, output, session) {
    options(shiny.maxRequestSize = 4 * 1024^2)
    
    # check credentials
    result_auth <- secure_server(check_credentials = check_credentials(credentials))
    output$res_auth <- renderPrint({
      reactiveValuesToList(result_auth)
    })
    
    # hide the loading message when the reset of the server function has executed
    hide(id = "loading-content", anim = TRUE, animType = "fade", time = 4)
    show("app-content")
    
    # create reactive values for input file and patient id
    rv <- reactiveValues(
      file1 = NULL,
      patient_id = NULL,
    )
    
    # reset input file and patient id
    observeEvent(input$reset, {
      rv$file1 <- NULL
      rv$patient_id <- NULL
      reset("file1")
      reset("patient_id")
    })
    
    # set patient id during non analysis state only
    observeEvent(input$patient_id, {
      non_analysis_state <- (list_out_prio_retino()$out_dr_prio_retino_txt == "")
      if (non_analysis_state
      ) {
        rv$patient_id <- input$patient_id
      }
    })
    
    # set input file during non analysis state only
    observeEvent(input$file1, {
      non_analysis_state <- (list_out_prio_retino()$out_dr_prio_retino_txt == "")
      if (non_analysis_state
      ) {
        rv$file1 <- input$file1
      }
    })
    
    # set language during non analysis state only
    observeEvent(input$selected_language, {
      non_analysis_state <- (list_out_prio_retino()$out_dr_prio_retino_txt == "")
      if (non_analysis_state
      ) {
        # Here is where we update language in session
        shiny.i18n::update_lang(session, input$selected_language)
      }
    })
    
    # translate analyzed diseases
    observe({
      updateSelectInput(session, "element_id",
                        label = i18n$t("Display pre-diagnostic results for :"),
                        choices = i18n$t(c("Diabetic retinopathy and/or maculopathy", "Glaucoma"))
      )
    })
    
    # print results
    observeEvent(input$print, {
      js$winprint()
    })
    
    # make prio computations and return results as a list
    list_out_prio_retino <- reactive({
      # initialize an empty list for prio retino results
      list_out_prio_retino <- list(
        resized_cropped_target_image = NULL,
        transformed_target_image = NULL,
        resized_transformed_target_image = NULL,
        out_orig_dr_img = NULL,
        out_orig_glauco_img = NULL,
        out_dr_prio_retino_txt = NULL,
        out_glauco_prio_retino_txt = NULL
      )
      
      if (!is.null(unlist(rv$file1)) && as.numeric(rv$file1$size) > 1) {
        if ((!is.null(unlist(rv$patient_id))) && (unlist(rv$patient_id) != "")) {
          # Update login usage
          auth_ind <- as.character(reactiveValuesToList(result_auth))
          tryCatch(
            {
              prio_retino_cred_use_df <<- as.data.frame(fread("../prio_retino_credential_usage/prio_retino_credential_usage.csv",
                                                              header = TRUE
              ))
              fwrite(prio_retino_cred_use_df, file = "../prio_retino_credential_usage/prio_retino_credential_usage_save.csv")
            },
            error = function(err) {
              prio_retino_cred_use_df <<- as.data.frame(fread("../prio_retino_credential_usage/prio_retino_credential_usage_save.csv",
                                                              header = TRUE
              ))
            }
          )
          current_count <- prio_retino_cred_use_df[match(auth_ind, prio_retino_cred_use_df$Login), ]$Count
          prio_retino_cred_use_df[match(auth_ind, prio_retino_cred_use_df$Login), ]$Count <- current_count + 1
          prio_retino_cred_use_df[match(auth_ind, prio_retino_cred_use_df$Login), ]$Last_analysis_timestamp <- paste0(as.character(Sys.time()), "sec")
          
          fwrite(prio_retino_cred_use_df, file = "../prio_retino_credential_usage/prio_retino_credential_usage.csv")
          fwrite(prio_retino_cred_use_df, file = "../prio_retino_credential_usage/prio_retino_credential_usage_save.csv")
          
          # resize and crop original target image
          out_resize_qual = compute_resize_quality_img(filename = rv$file1$datapath, img_size_qual=img_size_qual, desired_size=desired_size)
          list_out_prio_retino$resized_cropped_target_image <- image_read(out_resize_qual$temp_resize_img)
          file.remove(out_resize_qual$temp_resize_img)
          
          # convert original image to transformed target image
          transformed_target_image <- image_scale(list_out_prio_retino$resized_cropped_target_image, desired_size)
          transformed_target_image <- image_resize(transformed_target_image, desired_size)
          transformed_target_image <- magick2cimg(transformed_target_image)
          Blur_target_img <- boxblur(transformed_target_image, blur_factor)
          transformed_target_image <- transformed_target_image - Blur_target_img
          
          # save and resize transformed target image
          tmpF_trans_img <- tempfile(fileext=".png")
          save.image(
            transformed_target_image,
            tmpF_trans_img, quality = 1
          )
          list_out_prio_retino$transformed_target_image <- image_load(tmpF_trans_img)
          list_out_prio_retino$resized_transformed_target_image <- image_load(tmpF_trans_img,
                                                                              target_size = c(img_size_cnn, img_size_cnn)
          )
          
          # convert transformed image to array
          x_target <- image_to_array(list_out_prio_retino$resized_transformed_target_image)
          x_target <- array_reshape(x_target, c(1, dim(x_target)))
          x_target <- x_target / 255
          
          # make an output for original image
          out_orig_img <- image_scale(list_out_prio_retino$resized_cropped_target_image, "412x412!") %>%
            image_annotate(i18n$t("Original fundus image"),
                           font = "monospace",
                           color = "white", size = 12
            )
          
          # compute dr status
          proba_dr_status <- as.numeric(cnn_binary_classifier_1 %>% predict(x_target))
          ifelse((proba_dr_status <= 0.5), pred_dr_status <- 0, pred_dr_status <- 1)
          
          if (pred_dr_status == 0) {
            # make an img output for no dr
            out_dr_img <- image_scale(magick::image_read(
              image_array_resize(list_out_prio_retino$transformed_target_image,
                                 height = img_size_cnn, width = img_size_cnn
              ) / 255
            ), "412x412!")
            
            # make a txt output for no dr
            out_dr_txt <- paste0(
              i18n$t("Prio Retino+ results : mild or no visible signs of diabetic retinopathy (i.e. non referable DR) detected with a probability of "),
              (1 - trunc(100 * proba_dr_status) / 100), i18n$t(" for "), rv$patient_id, "."
            )
            dr_color <- "#49DC67"
            
            # make a txt and img output for no dr and maculo
            proba_maculo <- 1 - as.numeric(cnn_binary_classifier_3 %>% predict(x_target))
            ifelse((proba_maculo <= 0.5), Maculo_status <- 0, Maculo_status <- 1)
            if (Maculo_status) {
              out_dr_txt <- paste0(
                out_dr_txt, i18n$t("Warning: possible presence of maculopathy detected with a probability of "),
                (trunc(100 * proba_maculo) / 100)
              )
              dr_color <- "#FF5050"
              out_dr_img <- out_dr_img %>% image_annotate(i18n$t("Detected areas for maculopathy"),
                                                          font = "monospace", color = annotation_color_, size = 12
              )
            } else {
              out_dr_img <- out_dr_img %>% image_annotate(i18n$t("No detected areas for diabetic retinopathy and/or maculopathy"),
                                                          font = "monospace", color = annotation_color_, size = 12
              )
            }
          } else {
            proba_dr_level <- as.numeric(cnn_binary_classifier_2 %>% predict(x_target))
            ifelse((proba_dr_level <= 0.5), pred_dr_level <- 0, pred_dr_level <- 1)
            
            proba_maculo <- 1 - as.numeric(cnn_binary_classifier_4 %>% predict(x_target))
            ifelse((proba_maculo <= 0.5), Maculo_status <- 0, Maculo_status <- 1)
            
            ifelse((pred_dr_level == 0),
                   dr_level <- paste0(
                     i18n$t("potential signs of moderate DR detected with a probability of "),
                     (1 - trunc(100 * proba_dr_level) / 100)
                   ),
                   dr_level <- paste0(
                     i18n$t("potential signs of severe or superior DR detected with a probability of "),
                     (trunc(100 * proba_dr_level) / 100)
                   )
            )
            out_dr_txt <- paste0(
              i18n$t("Prio Retino+ results : referable diabetic retinopathy detected with a probability of "), (trunc(100 * proba_dr_status) / 100),
              i18n$t(" for "), rv$patient_id, ".", i18n$t(" Disease severity:  "), dr_level, ". "
            )
            if (Maculo_status) {
              out_dr_txt <- paste0(
                out_dr_txt, i18n$t("Warning: possible presence of maculopathy detected with a probability of "),
                (trunc(100 * proba_maculo) / 100)
              )
            }
            dr_color <- c("#FF5050", "#FF5050")[pred_dr_level + 1]
            
            # compute grad classification activation mapping for dr status
            out_dr_img <- image_scale(magick::image_read(
              compute_grad_cam(
                cnn_binary_classifier_1,
                list_out_prio_retino$transformed_target_image,
                list_out_prio_retino$resized_transformed_target_image,
                last_conv_layer_name
              ) / 255
            ), "412x412!") %>% image_annotate(i18n$t("Detected areas for diabetic retinopathy and/or maculopathy"),
                                              font = "monospace", color = annotation_color_, size = 12
            )
          } # end else for pred_dr_status test
          list_out_prio_retino$out_orig_dr_img <- image_append(c(out_orig_img, out_dr_img))
          if (convert_magick2cimg) {
            list_out_prio_retino$out_orig_dr_img <- magick2cimg(list_out_prio_retino$out_orig_dr_img,
                                                                alpha = "flatten")
          }
          
          # compute glauco status
          proba_glauco_status <- as.numeric(cnn_binary_classifier_5 %>% predict(x_target))
          
          ifelse((proba_glauco_status <= 0.5), glauco_status <- 0, glauco_status <- 1)
          if (glauco_status == 0) {
            out_glauco_txt <- paste0(
              i18n$t("Prio Retino+ results : no visible sign or low-risk suspect for glaucoma (i.e. non referable glaucoma) detected with a probability of "),
              (1 - trunc(100 * proba_glauco_status) / 100), i18n$t(" for "), rv$patient_id, "."
            )
            glauco_color <- "#49DC67"
            # make an img output for no glauco
            out_glauco_img <- image_scale(magick::image_read(
              image_array_resize(list_out_prio_retino$transformed_target_image,
                                 height = img_size_cnn, width = img_size_cnn
              ) / 255
            ), "412x412!") %>% image_annotate(i18n$t("No detected areas for glaucoma"),
                                              font = "monospace", color = annotation_color_, size = 12
            )
          } else {
            out_glauco_txt <- paste0(
              i18n$t("Prio Retino+ results : referable glaucoma (i.e. true glaucoma, pre-perimetric glaucoma or high-risk suspect) detected with a probability of "),
              trunc(100 * proba_glauco_status) / 100, i18n$t(" for "), rv$patient_id, "."
            )
            glauco_color <- "#FF5050"
            # compute grad classification activation mapping for glauco status
            out_glauco_img <- image_scale(magick::image_read(
              compute_grad_cam(
                cnn_binary_classifier_5,
                list_out_prio_retino$transformed_target_image,
                list_out_prio_retino$resized_transformed_target_image,
                last_conv_layer_name
              ) / 255
            ), "412x412!") %>% image_annotate(i18n$t("Detected areas for glaucoma"),
                                              font = "monospace", color = annotation_color_, size = 12
            )
          } # end glauco status computation
          list_out_prio_retino$out_orig_glauco_img <- image_append(c(out_orig_img, out_glauco_img))
          if (convert_magick2cimg) {
            list_out_prio_retino$out_orig_glauco_img <- magick2cimg(list_out_prio_retino$out_orig_glauco_img,
                                                                    alpha = "flatten")
          }
          
          # test image quality and add warning 
          ifelse(as.numeric(out_resize_qual$img_qual_score) < img_qual_tresh, img_qual <- 1, img_qual <- 0)
          if (!img_qual) {
            dr_color <- "#EE9F27"
            glauco_color <- "#EE9F27"
            img_qual_warning <- i18n$t("Warning: low quality image detected, Prio Retino+ results might be unreliable. ")
            out_dr_txt <- paste0(img_qual_warning, out_dr_txt)
            out_glauco_txt <- paste0(img_qual_warning, out_glauco_txt)
          }

          out_dr_prio_retino_txt <- HTML(paste0("<div style='background-color:", dr_color, "'>", out_dr_txt, "</div>"))
          out_glauco_prio_retino_txt <- HTML(paste0("<div style='background-color:", glauco_color, "'>", out_glauco_txt, "</div>"))
        } else {
          out_dr_prio_retino_txt <- HTML(paste0("<font color='#0c7683'>", i18n$t("Please reset Prio Retino+ first, then follow these instructions: 1. Select your language, 2. Insert patient identifier and 3. Upload a fundus image."), "</font>"))
          out_glauco_prio_retino_txt <- HTML(paste0("<font color='#0c7683'>", i18n$t("Please reset Prio Retino+ first, then follow these instructions: 1. Select your language, 2. Insert patient identifier and 3. Upload a fundus image."), "</font>"))
        }
        list_out_prio_retino$out_dr_prio_retino_txt <- out_dr_prio_retino_txt
        list_out_prio_retino$out_glauco_prio_retino_txt <- out_glauco_prio_retino_txt
      } else {
        list_out_prio_retino$out_dr_prio_retino_txt <- ""
        list_out_prio_retino$out_glauco_prio_retino_txt <- ""
      }
      list_out_prio_retino
    })
    
    # output image
    output$outputImage <- renderImage(
      {
        test_render_img <- (!is.null(unlist(rv$file1)) && as.numeric(rv$file1$size) > 1) &&
          ((!is.null(unlist(rv$patient_id))) && (unlist(rv$patient_id) != ""))
        list_out_prio_retino <- list_out_prio_retino()
        
        if (!test_render_img) {
          # Default image
          list(
            src = "www/AI_PRIO_RETINO.png", contentType = "image/png",
            width = 1150, height = 650, align = "left"
          )
        } else {
          # Return images for DR and/or maculopathy
          if (input$element_id == "Diabetic retinopathy and/or maculopathy" ||
              input$element_id == "Rétinopathie et/ou maculopathie diabétique" ||
              input$element_id == "Retinopatia diabética e/ou maculopatia") {
            if (convert_magick2cimg) {
              tmpF_orig_dr_img <- tempfile(fileext=".png")
              save.image(
                list_out_prio_retino$out_orig_dr_img,
                tmpF_orig_dr_img, quality = 1
              )
              list(
                src = tmpF_orig_dr_img,
                contentType = "image/png",
                width = 1200, height = 550
              )
            } else {
              list(
                src = image_write(list_out_prio_retino$out_orig_dr_img,
                                  tempfile(fileext = "png"),
                                  format = "png"
                ),
                contentType = "image/png",
                width = 1200, height = 550
              )
            }
            # Return images for glaucoma
          } else {
            if (convert_magick2cimg) {
              tmpF_orig_glauco_img <- tempfile(fileext=".png")
              save.image(
                list_out_prio_retino$out_orig_glauco_img,
                tmpF_orig_glauco_img, quality = 1
              )
              list(
                src = tmpF_orig_glauco_img,
                contentType = "image/png",
                width = 1200, height = 550
              )
            } else {
              list(
                src = image_write(list_out_prio_retino$out_orig_glauco_img,
                                  tempfile(fileext = "png"),
                                  format = "png"
                ),
                contentType = "image/png",
                width = 1200, height = 550
              )
            }
          }
        }
      },
      deleteFile = FALSE
    )
    
    output$output_dr_prio_retino_text <- renderText({
      if (!(!is.null(unlist(rv$file1)) && as.numeric(rv$file1$size) > 1)) {
        ""
      } else if (input$element_id == "Diabetic retinopathy and/or maculopathy" ||
                 input$element_id == "Rétinopathie et/ou maculopathie diabétique" ||
                 input$element_id == "Retinopatia diabética e/ou maculopatia") {
        list_out_prio_retino()$out_dr_prio_retino_txt
      }
    })
    
    output$output_glauco_prio_retino_text <- renderText({
      if (!(!is.null(unlist(rv$file1)) && as.numeric(rv$file1$size) > 1)) {
        ""
      } else if (input$element_id == "Glaucoma" ||
                 input$element_id == "Glaucome" ||
                 input$element_id == "Glaucoma") {
        list_out_prio_retino()$out_glauco_prio_retino_txt
      }
    })
    
  }
)

shinyApp(ui, server)
