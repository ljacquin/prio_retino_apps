#---------------------------------------------------------------------------------------------#
# Copyright (C) 2018,  Laval Yannis Julien Jacquin (i.e. Trust Data Science)                  #
#---------------------------------------------------------------------------------------------#
# This file is part of the Prio Retino software                                               #
#                                                                                             #
# Prio Retino software suite can be redistributed and/or modified under the terms of the      #
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
use_python(python = "/home/shiny/.virtualenvs/r-reticulate/bin/python",
           required = TRUE )
use_virtualenv("r-reticulate", 
               required = TRUE)
cv2 <- import("cv2")
imquality <- import("imquality")
py_config()
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
library(shinymanager)
library(shinycustomloader)
library(shiny.i18n)
library(shinyWidgets)
options(encoding = "UTF-8")
source_python("resize_image.py")
source_python("compute_image_brisque_score.py")

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
    three_dr_credentials <<- as.data.frame(fread("../prio_retino_credential_usage/prio_retino_credential_usage.csv",
                                                 header = TRUE))
    fwrite(three_dr_credentials, file = "../prio_retino_credential_usage/prio_retino_credential_usage_save.csv")
  },
  error = function(err) {
    three_dr_credentials <<- as.data.frame(fread("../prio_retino_credential_usage/prio_retino_credential_usage_save.csv",
                                                 header = TRUE))
  }
)


## data.frame with credentials info
credentials <- data.frame(
  user = three_dr_credentials$Login,
  password = three_dr_credentials$Password,
  stringsAsFactors = FALSE
)

#########################################
### Prio Retino models and parameters ###
#########################################

## CNN model and parameters
if (!exists("cnn_binary_classifier_1") && !exists("cnn_binary_classifier_2") && !exists("cnn_binary_classifier_3") && !exists("cnn_binary_classifier_4")
) {
  cnn_binary_classifier_1 <<- load_model_hdf5("xception_binary_classifier_1_full_arch_avg_pool_ratio_10_1_epochs_11.h5")
  cnn_binary_classifier_2 <<- load_model_hdf5("xception_binary_classifier_2_full_arch_avg_pool.h5")
  cnn_binary_classifier_3 <<- load_model_hdf5("xception_binary_classifier_3_full_arch_avg_pool.h5")
  cnn_binary_classifier_4 <<- load_model_hdf5("xception_binary_classifier_4_full_arch_avg_pool.h5")
}
img_size_cnn <<- as.numeric(scan("img_size_cnn.txt"))

## Raw image parameters
desired_size <<- 1024
blur_factor <<- 100

## Output image parameters
width_img_size <<- 540
height_img_size <<- 450

## Loading CSS content
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
  
  choose_language = TRUE,
  tag_img = tags$img(src = "Gaiha_prio_retino_login.png", width = 300
  ),
  
  # ui <- fluidPage(
  fluidPage(
    HTML('<meta name="viewport" content="width=1024">'),
    useShinyjs(),
    inlineCSS(appCSS),
    
    # Loading message
    div(
      id = "loading-content",
      h2(i18n$t("Loading Prio Retino..."))
    ),
    
    # Language selection
    shiny.i18n::usei18n(i18n),
    div(
      style = "float: right;", class = "chooselang",
      pickerInput(
        inputId = "selected_language",
        label = i18n$t("Set Prio Retino language"),
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
        titlePanel('', windowTitle = "Gaiha | Prio Retino"),
        sidebarLayout(
          sidebarPanel(
            HTML('<center><img src="Logo_GAIHA.PNG" width="110"></header>'),
            column(width = 1, offset = 10, style = "padding:6px;"),
            #
            titlePanel(h5(p(strong(i18n$t("Do not refresh the page, press 'Reset' to clean up before each new analysis"))),
                          style = "color:red", align = "left"
            )),
            actionButton('reset', i18n$t("Reset")),
            
            titlePanel(h5(p(""), align = "left")),
            #
            textInput("patient_id", i18n$t("Patient identifier"), value = ""),
            textInput("eye_side", i18n$t("If known, insert 'left eye' or 'right eye'"), value = ""),
            fileInput(
              input = "file1",
              label = i18n$t("Upload retinal fundus image"),
              accept = c(".png", ".jpeg", ".jpg")
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
            h4(htmlOutput("outputText"), align = "left"),
            fluidRow(
              column(width = 6, withLoader(imageOutput("outputImage1"),
                                           type = "image", loader = "computation_loader.gif"
              )),
              #tags$style("div#outputImage1:hover {
              #transform: scale(1.5);
              #transform-origin: top left;
              #}"),
              column(width = 6, withLoader(imageOutput("outputImage2"),
                                           type = "image", loader = "computation_loader.gif"
              ))
              #tags$style("div#outputImage2:hover {
              #transform: scale(1.5);
              #transform-origin: top left;
              #}")
            )
          )
        ),
        
        #
        useShinyjs(),
        extendShinyjs(text = "shinyjs.winprint = function(){ window.print(); }", functions = c("winprint")),
        actionButton("print", i18n$t("Print Prio Retino results to PDF")),
        
        #
        titlePanel(h6(p(strong(i18n$t("Remarks and definitions:"))), style = "color:#0c7683", align = "left")),
        titlePanel(h6(i18n$t("- Prio Retino results are given on an idicative basis, the diagnosis should be established by an ophthalmologist"),
                      style = "color:#0c7683", align = "left"
        )),
        titlePanel(h6(i18n$t("- ICDR: International Clinical Diabetic Retinopathy severity scale; AAO: American Academy of Ophthalmology"),
                      style = "color:#0c7683", align = "left"
        )),
        titlePanel(h6(i18n$t("- Non referable diabetic retinopathy (DR): mild or no visible signs of DR according to ICDR. AAO recommendations: repeat retinal examination annually for non referable DR"),
                      style = "color:#0c7683", align = "left"
        )),
        titlePanel(h6(i18n$t("- Referable diabetic retinopathy (DR): moderate or superior signs of DR according to ICDR. AAO recommendations: repeat retinal examination within 6 or 3 months for moderate 
or superior signs of DR respectively"),
                      style = "color:#0c7683", align = "left"
        )),
        titlePanel(h6(i18n$t("- The analyzed data is deleted and not stored by Prio Retino after each reset"),
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
    
    observeEvent(input$selected_language, {
      # Here is where we update language in session
      shiny.i18n::update_lang(session, input$selected_language)
    })
    
    result_auth <- secure_server(check_credentials = check_credentials(credentials))
    
    output$res_auth <- renderPrint({
      reactiveValuesToList(result_auth)
    })
    
    # Hide the loading message when the reset of the server function has executed
    hide(id = "loading-content", anim = TRUE, animType = "fade", time = 3)
    show("app-content")
    
    rv <- reactiveValues( file1 = NULL,
                          patient_id = NULL,
                          eye_side = NULL )
    
    observeEvent(input$reset, {
      rv$file1 <- NULL
      rv$patient_id <- NULL
      rv$eye_side <- NULL
      reset('file1')
      reset('patient_id')
      reset('eye_side')
    })
    
    observeEvent(input$file1, {
      rv$file1 <- input$file1
      ## resize and crop image      
      resize_image(name = input$file1$datapath, desired_size = desired_size)
      ## transform target image
      target_image <- image_read("www/resized_cropped_target_image.jpg")
      target_image <- image_scale(target_image, desired_size)
      target_image <- image_resize(target_image, desired_size)
      target_image <- magick2cimg(target_image)
      Blur_target_img <- boxblur(target_image, blur_factor)
      transformed_target_image <- target_image - Blur_target_img
      save.image(transformed_target_image, "www/transformed_target_image.jpg", quality = 1)
    })
    
    observeEvent(input$patient_id, {
      rv$patient_id <- input$patient_id
    })
    
    observeEvent(input$eye_side, {
      rv$eye_side <- input$eye_side
    })
    
    observeEvent(input$print, {
      js$winprint()
    })
    
    output$outputText <- renderText({
      if (!is.null(unlist(rv$file1))) {
        
        # Update login usage
        auth_ind <- as.character(reactiveValuesToList(result_auth))
        tryCatch(
          {
            three_dr_cred_use_df <<- as.data.frame(fread("../prio_retino_credential_usage/prio_retino_credential_usage.csv",
                                                         header = TRUE
            ))
            fwrite(three_dr_cred_use_df, file = "../prio_retino_credential_usage/prio_retino_credential_usage_save.csv")
          },
          error = function(err) {
            three_dr_cred_use_df <<- as.data.frame(fread("../prio_retino_credential_usage/prio_retino_credential_usage_save.csv",
                                                         header = TRUE
            ))
          }
        )
        current_count <- three_dr_cred_use_df[match(auth_ind, three_dr_cred_use_df$Login), ]$Count
        three_dr_cred_use_df[match(auth_ind, three_dr_cred_use_df$Login), ]$Count <- current_count + 1
        three_dr_cred_use_df[match(auth_ind, three_dr_cred_use_df$Login), ]$Last_analysis_timestamp <- paste0(as.character(Sys.time()),'sec')
        
        fwrite(three_dr_cred_use_df, file = "../prio_retino_credential_usage/prio_retino_credential_usage.csv")
        fwrite(three_dr_cred_use_df, file = "../prio_retino_credential_usage/prio_retino_credential_usage_save.csv")
        
        ## compute image quality status 
        img_score <- as.numeric(compute_image_brisque_score("www/resized_cropped_target_image.jpg")/100)
        # print(img_score)
        ifelse((img_score < 0.48), img_quality <- 1, img_quality <- 0)
        
        ## read transformed target image with correct size
        transformed_target_image <- image_load("www/transformed_target_image.jpg", target_size = c(img_size_cnn, img_size_cnn))
        x_target <- image_to_array(transformed_target_image)
        x_target <- array_reshape(x_target, c(1, dim(x_target)))
        x_target <- x_target / 255
        
        ## compute disease status (i.e. DR status)
        proba_disease_status <- as.numeric(cnn_binary_classifier_1 %>% predict(x_target))
        ifelse((proba_disease_status <= 0.5), pred_disease_status <- 1, pred_disease_status <- 2)
        
        if (pred_disease_status == 1) {
          if (is.null(unlist(rv$eye_side))) {
            disease_diagnostic <- paste0(
              i18n$t("Prio Retino results : mild or no visible signs of diabetic retinopathy (i.e. non referable DR) detected with a probability of "),
              (1 - trunc(100 * proba_disease_status) / 100), i18n$t(" for "), input$patient_id, "."
            )
          } else {
            disease_diagnostic <- paste0(
              i18n$t("Prio Retino results : mild or no visible signs of diabetic retinopathy (i.e. non referable DR) detected with a probability of "),
              (1 - trunc(100 * proba_disease_status) / 100), i18n$t(" for "), input$patient_id, " [", input$eye_side, "]."
            )
          }
          background_color <- "#00FF00"
          proba_maculo <- 1 - as.numeric(cnn_binary_classifier_3 %>% predict(x_target))
          ifelse((proba_maculo <= 0.5), Maculo_status <- 0, Maculo_status <- 1)
          if (Maculo_status) {
            disease_diagnostic <- paste0(
              disease_diagnostic, i18n$t("Warning: possible presence of maculopathy detected with a probability of "),
              (trunc(100 * proba_maculo) / 100)
            )
            background_color <- "#FF5050"
          }
        } else {
          proba_disease_level <- as.numeric(cnn_binary_classifier_2 %>% predict(x_target))
          ifelse((proba_disease_level <= 0.5), pred_disease_level <- 1, pred_disease_level <- 2)
          
          proba_maculo <- 1 - as.numeric(cnn_binary_classifier_4 %>% predict(x_target))
          ifelse((proba_maculo <= 0.5), Maculo_status <- 0, Maculo_status <- 1)
          
          if (is.null(unlist(rv$eye_side))) {
            ifelse((pred_disease_level == 1),
                   disease_level <- paste0(
                     i18n$t("potential signs of moderate DR detected with a probability of "),
                     (1 - trunc(100 * proba_disease_level) / 100)
                   ),
                   disease_level <- paste0(
                     i18n$t("potential signs of severe or superior DR detected with a probability of "),
                     (trunc(100 * proba_disease_level) / 100)
                   )
            )
            disease_diagnostic <- paste0(
              i18n$t("Prio Retino results : referable diabetic retinopathy detected with a probability of "), (trunc(100 * proba_disease_status) / 100),
              i18n$t(" for "), input$patient_id, ".", i18n$t(" Disease severity:  "), disease_level, ". "
            )
            if (Maculo_status) {
              disease_diagnostic <- paste0(
                disease_diagnostic, i18n$t("Warning: possible presence of maculopathy detected with a probability of "),
                (trunc(100 * proba_maculo) / 100)
              )
            }
          } else {
            ifelse((pred_disease_level == 1),
                   disease_level <- paste0(
                     i18n$t("potential signs of moderate DR detected with a probability of "),
                     (1 - trunc(100 * proba_disease_level) / 100)
                   ),
                   disease_level <- paste0(
                     i18n$t("potential signs of severe or superior DR detected with a probability of "),
                     (trunc(100 * proba_disease_level) / 100)
                   )
            )
            disease_diagnostic <- paste0(
              i18n$t("Prio Retino results : referable diabetic retinopathy detected with a probability of "), (trunc(100 * proba_disease_status) / 100),
              i18n$t(" for "), input$patient_id, " [", input$eye_side, "].", i18n$t(" Disease severity:  "), disease_level, ". "
            )
            if (Maculo_status) {
              disease_diagnostic <- paste0(
                disease_diagnostic, i18n$t("Warning: possible presence of maculopathy detected with a probability of "),
                (trunc(100 * proba_maculo) / 100)
              )
            }
          }
          background_color <- c("#FF5050", "#FF5050")[pred_disease_level]
        }
        if ( !img_quality ){
          background_color <- "#EE9F27"
          disease_diagnostic <- paste0(i18n$t("Warning: low quality image detected, Prio Retino results might be unreliable. "),
                                       disease_diagnostic)
        }
        HTML(paste0("<div style='background-color:", background_color, "'>", disease_diagnostic, "</div>"))  
        
        
      } else {
        if (file.exists("www/resized_cropped_target_image.jpg")) {
          file.remove("www/resized_cropped_target_image.jpg")
        }
        if (file.exists("www/transformed_target_image.jpg")) {
          file.remove("www/transformed_target_image.jpg")
        }
        paste0("")
      }
    })
    
    ####################
    output$outputImage1 <- renderImage(
      {
        if (is.null(unlist(rv$file1))) {
          
          # Default image
          list(
            src = "www/AI_PRIO_RETINO.png", contentType = "image/png",
            width = 1150, height = 650, align = "left"
          )
        } else {
          
          list(
            src = "www/resized_cropped_target_image.jpg", contentType = "image/jpg",
            width = width_img_size, height = height_img_size, align = "left"
          )
        }
      },
      deleteFile = FALSE
    )
    
    #####################
    output$outputImage2 <- renderImage(
      {
        if (is.null(unlist(rv$file1))) {
          list(
            src = "www/BLANK.jpg", contentType = "image/jpg",
            width = 1, height = 1, align = "right"
          )
        } else {
          
          list(
            src = "www/transformed_target_image.jpg", contentType = "image/jpg",
            width = width_img_size, height = height_img_size, align = "right"
          )
        }
      },
      deleteFile = FALSE
    )
    
  }
)

shinyApp(ui, server)
