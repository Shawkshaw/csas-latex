make.biomass.mcmc.plot <- function(models,
                                   model.names = NULL,
                                   ylim,
                                   opacity = 75,
                                   offset = 0.1,
                                   append.base.txt = NULL,
                                   show.bmsy.line = FALSE,
                                   show.bo.line = FALSE,
                                   ind.letter = NULL,
                                   leg = NULL,
                                   ...
                                   ){
  ## Plot the biomass with credibility intervals for the mcmc
  ##  case of the models
  ##
  ## y.max - upper limit for the y axis
  ## opacity - how opaque the envelope is
  ## bo.offset - offset to the left for the bo point an bars
  ## offset - the amount on the x-axis to offset each point and line for
  ##  multiple models
  ## append.base.txt - text to append to the name of the first model
  ## show.bmsy.line - show the reference lines 0.4 and 0.8bmsy
  ## show.bo.line - show the reference lines 0.2 and 0.4bo

  par(mar = c(5.1, 5.1, 4.1, 3.1))

  sbt.quants <- lapply(models,
                       function(x){
                         x$mcmccalcs$sbt.quants})
  r.quants <- lapply(models,
                     function(x){
                       x$mcmccalcs$r.quants})
  sbo.raw <- lapply(r.quants,
                    function(x){
                      x[rownames(x) == "bo", ]})
  sbo <- lapply(sbo.raw,
                function(x){
                  as.numeric(x[,2:4])})
  yrs <- lapply(sbt.quants,
                function(x){
                  as.numeric(colnames(x))})
  xlim <- lapply(1:length(yrs),
                 function(x){
                   c(min(yrs[[x]]), max(yrs[[x]]))})
  xlim <- do.call(rbind, xlim)
  xlim <- c(min(xlim), max(xlim))

  if(is.null(dev.list())){
    ## If layout() is used outside this function,
    ##  it calls plot.new and will mess up the figures
    ##  if we call it again
    plot.new()
  }
  plot.window(xlim = xlim,
              ylim = ylim,
              xlab = "",
              ylab = "")

  lapply(1:length(yrs),
         function(x){
           draw.envelope(yrs[[x]],
                         sbt.quants[[x]],
                         xlab = "",
                         ylab = "",
                         col = x,
                         las = 1,
                         xlim = xlim,
                         ylim = ylim,
                         opacity = opacity,
                         first = ifelse(x == 1, TRUE, FALSE),
                         ...)})
  ## Add sbo points and ci bars
  lapply(1:length(yrs),
         function(x){
           points(yrs[[x]][1] - (x - 1) * offset,
                  sbo[[x]][2],
                  pch = 19,
                  col = x)
           arrows(yrs[[x]][1] - (x - 1) * offset,
                  sbo[[x]][1],
                  yrs[[x]][1] - (x - 1) * offset,
                  sbo[[x]][3],
                  lwd = 2,
                  code = 0,
                  col = x)})

  if(show.bo.line){
    abline(h = 0.3 * sbo[[1]][2],
           col = "red",
           lty = 1,
           lwd = 2)
    mtext(expression("0.3B"[0]),
          4,
          at = 0.3 * sbo[[1]][2],
          col = "red",
          las = 1)
  }
  if(show.bmsy.line){
    sbmsy.raw <- r.quants[[1]][rownames(r.quants[[1]]) == "bmsy", ]
    sbmsy <- as.numeric(sbmsy.raw[2:4])
    abline(h = 0.4 * sbmsy[2],
           col = "red",
           lty = 1,
           lwd = 2)
    mtext(expression("0.4B"[MSY]),
          4,
          at = 0.4 * sbmsy[2],
          col = "red",
          las = 1)
    abline(h = 0.8 * sbmsy[2],
           col = "green",
           lty = 1,
           lwd = 2)
    mtext(expression("0.8B"[MSY]),
          4,
          at = 0.8 * sbmsy[2],
          col = "green",
          las = 1)
  }
  mtext("Year", 1, line = 3)
  mtext("Biomass (1000 mt)", 2, line = 3)

  if(!is.null(model.names) & !is.null(leg)){
    if(!is.null(append.base.txt)){
      model.names[[1]] <- paste0(model.names[[1]],
                                 append.base.txt)
    }
    legend(leg,
           model.names,
           bg = "transparent",
           col = 1:length(models),
           lty = 1,
           lwd = 2)
  }

  if(!is.null(ind.letter)){
    panel.letter(ind.letter)
  }
}