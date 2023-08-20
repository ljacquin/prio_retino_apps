library(RSQLite)
library(data.table)
library(shinymanager)
# library(rstudioapi)
# setwd(dirname(getActiveDocumentContext()$path))

# source custom function for concurrent writing in SQLite database
source("dbWriteTable_.R")

# set db_name
dbname_ <- "../../prio_suite_db"

# data.frame with credentials info
credentials <- data.frame(
  user = c(
    "ljacquin@gaiha.org",
    "glevezouet@gaiha.org",
    "adrif@gaiha.org"
  ),
  password = c("******", "******", "******"),
  stringsAsFactors = FALSE
)

ui <- secure_app(
  tags_top = tags$img(src = "Gaiha_prio_retino_plus_login.png", width = 300),
  fluidPage(
    tags$head(tags$style(".progress-bar{background-color:#FF0000;}")),
    titlePanel(title = div(
      titlePanel("", windowTitle = "Gaiha | Prio Retino+ credential current month usage"),
      img(src = "Gaiha_prio_retino_plus_login.png", width = 400),
      h1("Prio Retino+ credential and current month usage application")
    )),
    mainPanel(
      fileInput("file1",
                h4(p("Update or upload Prio Retino+ credential and current month usage file",
                     style = "color:#FF0000"
                )),
                accept = c(
                  "text/csv",
                  "text/comma-separated-values,text/plain",
                  ".csv"
                )
      ),
      tableOutput("create_credential_current_month_usage"),
      downloadButton("prio_retino_cred_current_month_usage", "Get Prio Retino+ credential and current month usage file",
                     style = "color: #fff; background-color:#FF0000; border-color: #fff"
      ),
      downloadButton("prio_retino_current_month_usage", "Get Prio Retino+ current month usage file",
                     style = "color: #fff; background-color:#27ae60; border-color: #fff"
      ),
      downloadButton("prio_retino_previous_month_usage", "Get Prio Retino+ previous month usage file",
                     style = "color: #fff; background-color:#0074B7; border-color: #fff"
      ),
      tags$hr()
    )
  )
)

server <- shinyServer(
  function(input, output) {
    result_auth <- secure_server(check_credentials = check_credentials(credentials))
    
    # create credential & current month usage file
    output$create_credential_current_month_usage <- renderTable({
      # create a connection to prio suite db and disconnect on exit
      db_connect <- dbConnect(SQLite(), dbname = dbname_)
      on.exit(DBI::dbDisconnect(db_connect))
      
      # connect to table to test current month change
      prio_retino_cred_current_month_usage_df <- dbReadTable(
        db_connect,
        "prio_retino_credential_current_month_usage"
      )
      # get current month and next month
      current_month <- unique(prio_retino_cred_current_month_usage_df$Current_month)
      next_month <- as.numeric(format(as.Date(Sys.time(), format = "%Y-%m-%d"), "%m"))
      
      # detect month change
      if (abs(next_month - current_month) != 0) {
        # modify previous month table
        if (dbExistsTable(db_connect, "prio_retino_credential_previous_month_usage")) {
          dbRemoveTable(db_connect, "prio_retino_credential_previous_month_usage")
        }
        dbWriteTable_(db_connect, "prio_retino_credential_previous_month_usage",
                      prio_retino_cred_current_month_usage_df,
                      overwrite_ = TRUE
        )
        # modify current month table
        prio_retino_cred_current_month_usage_df$Last_analysis_timestamp <- ''
        prio_retino_cred_current_month_usage_df$Current_month <- next_month
        prio_retino_cred_current_month_usage_df$Count <- 0
        if (dbExistsTable(db_connect, "prio_retino_credential_current_month_usage")) {
          dbRemoveTable(db_connect, "prio_retino_credential_current_month_usage")
        }
        dbWriteTable_(db_connect, "prio_retino_credential_current_month_usage",
                      prio_retino_cred_current_month_usage_df,
                      overwrite_ = TRUE
        )
      }
      
      # test if a file has been uploaded
      inFile <- input$file1
      if (is.null(inFile)) {
        return(NULL)
      } else {
        prio_retino_cred_current_month_usage_df <- as.data.frame(fread(inFile$datapath))
        if (dbExistsTable(db_connect, "prio_retino_credential_current_month_usage")) {
          dbRemoveTable(db_connect, "prio_retino_credential_current_month_usage")
        }
        dbWriteTable_(db_connect, "prio_retino_credential_current_month_usage",
                      prio_retino_cred_current_month_usage_df,
                      overwrite_ = TRUE
        )
      }
      
    })
    
    # make an output for downloading updated credential and current month usage file
    output$prio_retino_cred_current_month_usage <- downloadHandler(
      filename = function() {
        paste0("prio_retino_credential_current_month_usage_at_", as.character(Sys.Date()), ".csv")
      },
      content = function(file) {
        # create a connection to prio suite db and disconnect on exit
        db_connect <- dbConnect(SQLite(), dbname = dbname_)
        on.exit(DBI::dbDisconnect(db_connect))
        if (dbExistsTable(db_connect, "prio_retino_credential_current_month_usage")) {
          prio_retino_cred_current_month_usage_df <- as.data.frame(dbReadTable(
            db_connect,
            "prio_retino_credential_current_month_usage"
          ))
          write.csv(prio_retino_cred_current_month_usage_df, file, row.names = FALSE)
        } else {
          write.csv(data.frame(NULL), file, row.names = FALSE)
        }
      }
    )
    
    # make an output for downloading updated current month usage file
    output$prio_retino_current_month_usage <- downloadHandler(
      filename = function() {
        paste0("prio_retino_current_month_usage_at_", as.character(Sys.Date()), ".csv")
      },
      content = function(file) {
        # create a connection to prio suite db and disconnect on exit
        db_connect <- dbConnect(SQLite(), dbname = dbname_)
        on.exit(DBI::dbDisconnect(db_connect))
        if (dbExistsTable(db_connect, "prio_retino_credential_current_month_usage")) {
          prio_retino_cred_current_month_usage_df <- as.data.frame(dbReadTable(
            db_connect,
            "prio_retino_credential_current_month_usage"
          ))
          prio_retino_cred_current_month_usage_df <- prio_retino_cred_current_month_usage_df[, -match(
            "Password",
            colnames(prio_retino_cred_current_month_usage_df)
          )]
          write.csv(prio_retino_cred_current_month_usage_df, file, row.names = FALSE)
        } else {
          write.csv(data.frame(NULL), file, row.names = FALSE)
        }
      }
    )
    
    # make an output for downloading previous month usage file
    output$prio_retino_previous_month_usage <- downloadHandler(
      filename = function() {
        paste0("prio_retino_previous_month_usage_at_", as.character(Sys.Date()), ".csv")
      },
      content = function(file) {
        # create a connection to prio suite db and disconnect on exit
        db_connect <- dbConnect(SQLite(), dbname = dbname_)
        on.exit(DBI::dbDisconnect(db_connect))
        if (dbExistsTable(db_connect, "prio_retino_credential_previous_month_usage")) {
          prio_retino_cred_previous_month_usage_df <- as.data.frame(dbReadTable(
            db_connect,
            "prio_retino_credential_previous_month_usage"
          ))
          prio_retino_cred_previous_month_usage_df <- prio_retino_cred_previous_month_usage_df[, -match(
            "Password",
            colnames(prio_retino_cred_previous_month_usage_df)
          )]
          write.csv(prio_retino_cred_previous_month_usage_df, file, row.names = FALSE)
        } else {
          write.csv(data.frame(NULL), file, row.names = FALSE)
        }
      }
    )
  }
)

shinyApp(ui, server)
