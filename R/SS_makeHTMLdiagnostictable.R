#' Make html diagnostic tables
#'
#' Creates html tables that show diagnostic outputs, including status checks, gradients, and correlations.
#'
#' @param replist List item representing stock assessment model output list (\code{SS_output})
#' @param plotdir Directory where the text files containing the tables will be written.
#' By default it will be the directory where the model was run.
#' @param gradmax the largest gradient value for estimated parameter; the default is 1E-3
#' @return a three-element vector; the first element is the name of the html table file, the second is the table caption, and the third is the category of output type
#' @author Christine Stawitz
#' @export
#' @seealso \code{\link{SS_plots}}, \code{\link{SS_output}, \code{\link{SS_html}}}
SS_makeHTMLdiagnostictable <- function(replist,
                                       plotdir = NULL,
                                       gradmax = 1E-3) {
  #Filter out parameters with NA gradients
  parchecks <- replist$estimated_non_dev_parameters
  cormin <- replist$inputs$cormin
  cormax <- replist$inputs$cormax

  # set default directory (following convention in other plot functions,
  # not bothering to create "plots" subfolder if called indepenently of SS_plots)
  if(is.null(plotdir)){
    plotdir <- replist$inputs$dir
  }

  #Filter out columns related to priors if there aren't any
  if (all(parchecks$Pr_type == "No_prior")) {
    parchecks$Prior <- NULL
    parchecks$Pr_SD <- NULL
    parchecks$Pr_Like <- NULL
  }
  cors <- replist$corstats

  #Sort by highest gradient
  if(!is.null(parchecks$Gradient)){
    parchecks <- parchecks[!is.na(parchecks$Gradient), ]
    parchecks <- parchecks[order(-parchecks$Gradient), ]
    parchecks$Gradient <- cell_spec(parchecks$Gradient,
                                    "html",
                                    color = ifelse(abs(parchecks$Gradient) >
                                                     gradmax, "red", "black"))
  }
  #Format table with parameter checks so high gradients or parameters on bounds are shown in red
  parchecks$Afterbound <-
    cell_spec(parchecks$Afterbound,
              "html",
              color = ifelse(parchecks$Afterbound == "OK", "black", "red"))
  parchecks$Status <-
    cell_spec(parchecks$Status,
              "html",
              color = ifelse(parchecks$Status == "OK", "black", "red"))

  #Write out table
  the_table <- kable(parchecks,
                     format = "html",
                     escape = F)
  the_table <- kable_styling(the_table)
  the_table <-
    scroll_box(the_table, width = "100%", height = "200px")
  filename <- caption <- NULL
  filename = c(filename,"parameterchecks.html")

  write(the_table,
        file = file.path(plotdir,filename[1]))
  caption = c(caption,paste(
      "Table of estimated parameters sorted by parameters with the largest gradients; any parameter with a gradient value with an absolute value above",
      gradmax,
      "(for SS 3.30 models) or a parameter on bounds is colored in red."
  ))

  #Format high correlations table
  if(!is.null(cors$cormessage3)){
    high_cor_table <- cors$cormessage3

    high_cor_table <- high_cor_table[order(high_cor_table$corr), ]
    high_cor_table$corr <- cell_spec(high_cor_table$corr,
                                     "html",
                                     color = ifelse(abs(high_cor_table$corr) >
                                                      cormax, "red", "black"))
    the_table2 <- kable(high_cor_table,
                        format = "html",
                        escape = F)
    the_table2 <- kable_styling(the_table2)
    filename = c(filename,"correlationcheck.html")
    write(the_table2,
          file = file.path(plotdir,"correlationcheck.html"))
    caption = c(caption, paste(
        "Table of estimated parameters with the ten highest correlation rates, sorted by highest correlations; any parameter with an absolute value of correlation above",
        cormax,
        "is colored in red."
    ))
  }
  #Select and format low correlations table
  if(!is.null(cors$cormessage10)){
    low_cor_table <- cors$cormessage10

    low_cor_table <- low_cor_table[order(low_cor_table$max), ]
    low_cor_table$max <- cell_spec(low_cor_table$max,
                                   "html",
                                   color = ifelse(abs(low_cor_table$max) <
                                                    cormin, "purple", "black"))
    the_table3 <- kable(low_cor_table,
                        format = "html",
                        escape = F)
    the_table3 <- kable_styling(the_table3)
    filename = c(filename,"lowcorrelationcheck.html")
    write(the_table3,
          file = file.path(plotdir,"lowcorrelationcheck.html"))
    caption = c(caption,paste(
        "Table of estimated parameters with the ten lowest correlation rates, sorted by lowest correlations; any parameter with an absolute value of correlation below",
        cormin,
        "is colored in purple"
    ))
  }

  #Create data frame to add to PlotInfoTable
  outtable_df <- data.frame(
      "file" = filename,
      "caption" = caption,
      "category" = rep("DiagnosticTables", length(filename))
  )

  return(outtable_df)
}
