make.decision.table <- function(model,
                                digits = 3,
                                xcaption = "default",
                                xlabel   = "default",
                                font.size = 9,
                                space.size = 10,
                                placement = "H"){
  ## Returns an xtable
  ##
  ## digits - number of decimal places for the values
  ## xcaption - caption to appear in the calling document
  ## xlabel - the label used to reference the table in latex
  ## font.size - size of the font for the table
  ## space.size - size of the vertical spaces for the table
  ## placement - latex code for placement of the table in document

  if(class(model) == model.lst.class){
    model <- model[[1]]
    if(class(model) != model.class){
      stop("The structure of the model list is incorrect.")
    }
  }

  tab <- model$mcmccalcs$proj.dat
  ## Don't format the first column as it should be the TAC
  tab[, -1] <- f(tab[, -1], digits)
  ## Required to stop xtable from adding decimal points to TACs
  tab[, 1] <- f(tab[,1], 0)

  size.string <- latex.size.str(font.size, space.size)
  print(xtable(tab,
               caption = xcaption,
               label = xlabel,
               align = get.align(ncol(tab))),
        caption.placement = "top",
        include.rownames = FALSE,
        sanitize.text.function = function(x){x},
        size = size.string,
        table.placement = placement,
        booktabs = TRUE)
}
