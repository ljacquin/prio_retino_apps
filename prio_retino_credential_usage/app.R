library(data.table)
library(shinymanager)

## data.frame with credentials info
credentials <- data.frame(
  user = c(
    "ljacquin@gaiha.org",
    "glevezouet@gaiha.org",
    "adrif@gaiha.org"
  ),
  password = c("F3P8gf", "Tb6sJe", "esRY18"),
  stringsAsFactors = FALSE
)

ui <- secure_app(
  fluidPage(
    tags$head(tags$style(".progress-bar{background-color:#FF0000;}")),
    titlePanel(title=div(img(src="Logo_GAIHA.PNG"), 
                         h1("Prio Retino credential and usage application"))),
    mainPanel(
          fileInput("file1",
            h4(p("Update or upload Prio Retino credential and usage file",
              style = "color:#FF0000"
            )),
            accept = c(
              "text/csv",
              "text/comma-separated-values,text/plain",
              ".csv"
            )
          ),
          tableOutput("create_credential_usage"),
          downloadButton("three_dr_cred_usage", "Get Prio Retino credential and total usage file",
            style = "color: #fff; background-color:#FF7F50; border-color: #fff"
          ),
          downloadButton("three_dr_usage", "Get Prio Retino total usage file only",
            style = "color: #fff; background-color:#27ae60; border-color: #fff"
          ),
          tags$hr()
        )
  )
)

server <- shinyServer(
  function(input, output) {
    result_auth <- secure_server(check_credentials = check_credentials(credentials))

    # Create credential & usage file
    output$create_credential_usage <- renderTable({
      inFile <- input$file1
      if (is.null(inFile)) {
        return(NULL)
      }
      three_dr_cred_usage_df <- fread(inFile$datapath)
      fwrite(three_dr_cred_usage_df, "prio_retino_credential_usage.csv")
    })

    # Make an output for updated credential and usage file
    output$three_dr_cred_usage <- downloadHandler(
      filename = function() {
        paste0("prio_retino_credential_usage_at_", as.character(Sys.Date()), ".csv")
      },
      content = function(file) {
        if (file.exists("prio_retino_credential_usage.csv")) {
          three_dr_cred_usage_df <- as.data.frame(fread("prio_retino_credential_usage.csv"))
          write.csv(three_dr_cred_usage_df, file, row.names = FALSE)
        } else {
          write.csv(data.frame(NULL), file, row.names = FALSE)
        }
      }
    )

    # Make an output for updated usage file
    output$three_dr_usage <- downloadHandler(
      filename = function() {
        paste0("prio_retino_usage_at_", as.character(Sys.Date()), ".csv")
      },
      content = function(file) {
        if (file.exists("prio_retino_credential_usage.csv")) {
          three_dr_cred_usage_df <- as.data.frame(fread("prio_retino_credential_usage.csv"))
          three_dr_cred_usage_df <- three_dr_cred_usage_df[, -match(
            "Password",
            colnames(three_dr_cred_usage_df)
          )]
          write.csv(three_dr_cred_usage_df, file, row.names = FALSE)
        } else {
          write.csv(data.frame(NULL), file, row.names = FALSE)
        }
      }
    )
  }
)

shinyApp(ui, server)
