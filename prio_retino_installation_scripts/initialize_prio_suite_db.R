library(RSQLite)
library(rstudioapi)
setwd(dirname(getActiveDocumentContext()$path))

# Set the path to your SQLite database file
dbname_ <- "../../prio_suite_db"

# Connect to the SQLite database
db_connect <- dbConnect(RSQLite::SQLite(), dbname = dbname_)
dbDisconnect(db_connect)

# test
db_connect <- dbConnect(RSQLite::SQLite(), dbname = dbname_)
dbReadTable(db_connect,'prio_breast_cancer_credential_current_month_usage')
dbDisconnect(db_connect)
