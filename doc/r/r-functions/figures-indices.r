make.index.fit.plot <- function(models,
                                model.names = NULL,
                                leg = NULL,
                                start.yr,
                                end.yr,
                                ind,
                                ylim = c(0, 20),
                                ind.letter = NULL){
  ## Plot the index fits for MPDs
  ##
  ## models - a list of  model objects (list can be length 1)
  ##  and the class must be model.list
  ## model.names - optional names for the legend. The length must match
  ##  the length of the models list.
  ## leg - location of legend (if model.names is present). e.g. "topright"
  ## ind - the index to plot. Must be a single value.

  if(class(models) != model.lst.class){
    stop("The models argument is not a '",
         model.lst.class, "' class.")
  }

  if(length(ind) > 1){
    stop("The length of ind cannot be greater than 1.")
  }

  ## Get index names for the models
  index.dat <- lapply(models,
                      function(x){
                        as.data.frame(x$dat$indices[[ind]])
                      })
  index.fit <- lapply(models,
                      function(x){
                        x$mpd$it_hat[ind,]
                      })
  index.fit <- do.call(rbind, index.fit)

  index.fit <- apply(index.fit,
                     1,
                     function(x){
                       x[!is.na(x)]})

  xlim <- c(start.yr, end.yr)
  yrs <- lapply(index.dat,
                function(x){
                  x$iyr})
  index <- lapply(index.dat,
                  function(x){
                    x$it})
  cv <- lapply(index.dat,
               function(x){
                 1 / x$wt})
  ## Plot the fit first
  plot.new()
  plot.window(xlim = xlim,
              ylim = ylim,
              xlab = "",
              ylab = "")

  p.lines <- lapply(1:length(yrs),
                    function(x){
                      lines(yrs[[x]],
                            index.fit[,x],
                            lwd = 2,
                            xlim = xlim,
                            ylim = ylim,
                            col = x)})
  ## Then the points and arrows for the index inputs
  p.pts <- lapply(1:length(yrs),
                  function(x){
                    points(yrs[[x]],
                           index[[x]],
                           pch = 3,
                           col = x,
                           lwd = 2)})
  p.arrows <- lapply(1:length(yrs),
                     function(x){
                       arrows(yrs[[x]],
                              index[[x]] + cv[[x]] * index[[x]],
                              yrs[[x]],
                              index[[x]] - cv[[x]] * index[[x]],
                              code = 3,
                              angle = 90,
                              length = 0.0,
                              col = 1,
                              lwd = 2)})
  axis(1,
       at = seq(min(xlim), max(xlim)),
       labels = seq(min(xlim), max(xlim)))
  axis(2)
  box()
  mtext("Year", 1, line = 3)
  mtext("1,000 t", 2, line = 3)

  if(!is.null(model.names) & !is.null(leg)){
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
