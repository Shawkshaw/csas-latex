load.iscam.files <- function(model.dir,
                             verbose = FALSE){
  ## Load all the iscam files for output and input, and return the model object.
  ## If MCMC directory is present, load that and perform calculations for mcmc parameters.

  curr.func.name <- get.curr.func.name()
  model <- list()
  model$path <- model.dir
  ## Get the names of the input files
  inp.files <- fetch.file.names(model.dir, starter.file.name)
  model$dat.file <- inp.files[[1]]
  model$ctl.file <- inp.files[[2]]
  model$proj.file <- inp.files[[3]]

  ## Load the input files
  model$dat <- read.data.file(model$dat.file)
  model$ctl <- read.control.file(model$ctl.file,
                                 model$dat$num.gears,
                                 model$dat$num.age.gears)
  model$proj <- read.projection.file(model$proj.file)
  model$par <- read.par.file(file.path(model.dir, par.file))
  ## Load MPD results
  model$mpd <- read.report.file(file.path(model.dir, rep.file))
  model.dir.listing <- dir(model.dir)
  ## Set default mcmc members to NA. Later code depends on this.
  model$mcmc <- NA
  ## Set the mcmc path. This doesn't mean it exists.
  mcmc.dir <- file.path(model.dir, "mcmc")
  model$mcmcpath <- mcmc.dir

  ## If it has an 'mcmc' sub-directory, load that as well
  if(dir.exists(mcmc.dir)){
    model$mcmc <- read.mcmc(mcmc.dir)
  }
  ## Do the mcmc quantile calculations
  model$mcmccalcs <- calc.mcmc(model$mcmc)
  model
}

delete.rdata.files <- function(
           models.dir = model.dir ## Directory name for all models location
           ){
  ## Delete all rdata files found in the subdirectories of the models.dir
  ## directory.
  dirs <- dir(models.dir)
  rdata.files <- file.path(models.dir, dirs, paste0(dirs, ".rdata"))
  ans <- readline("This operation cannot be undone, are you sure (y/n)? ")
  if(ans == "Y" | ans == "y"){
    unlink(rdata.files, force = TRUE)
    cat(paste0("Deleted ", rdata.files, "\n"))
    cat("All rdata files were deleted.\n")
  }else{
    cat("No files were deleted.\n")
  }
}

create.rdata.file <- function(
           models.dir = model.dir,          ## Directory name for all models location
           model.name,                      ## Directory name of model to be loaded
           ovwrt.rdata = FALSE,             ## Overwrite the RData file if it exists?
           run.forecasts = FALSE,           ## Run forecasting metrics for this model? *This will overwrite any already run*
           fore.yrs = forecast.yrs,         ## Vector of years to run forecasting for if run.metrics = TRUE
           forecast.probs = forecast.probs, ## Vector of quantile values if run.metrics = TRUE
           forecast.catch.levels = catch.levels, ## List of catch levels to run forecasting for if run.forecasts = TRUE
           run.retros = FALSE,              ## Run retrospectives for this model? *This will overwrite any already run*
           my.retro.yrs = retro.yrs,        ## Vector of integers (positives) to run retrospectives for if run.retros = TRUE
           verbose = FALSE){
  ## Create an rdata file to hold the model's data and outputs.
  ## If an RData file exists, and overwrite is FALSE, return immediately.
  ## If no RData file exists, the model will be loaded from outputs into an R list
  ##  and saved as an RData file in the correct directory.
  ## When this function exits, an RData file will be located in the
  ##  directory given by model.name.
  ## Assumes the files model-setup.r, retrospective-setup.r, and forecast-catch-levels.r
  ##  have been sourced (for default values of args).
  ## Assumes utilities.r has been sourced.
  curr.func.name <- get.curr.func.name()
  model.dir <- file.path(models.dir, model.name)
  if(!dir.exists(model.dir)){
    stop(curr.func.name,"Error - the directory ", model.dir, " does not exist. ",
         "Fix the problem and try again.\n")
  }
  ## The RData file will have the same name as the directory it is in
  rdata.file <- file.path(model.dir, paste0(model.name, ".RData"))
  if(!ovwrt.rdata){
    if(run.forecasts){
      stop(curr.func.name,
           "Error - You have asked to run forecasting, ",
           "but set ovwrt.rdata to FALSE.\n",
           "Set ovwrt.rdata to TRUE and try again.")
    }
    if(run.retros){
      stop(curr.func.name,
           "Error - You have asked to run retrospectives, ",
           "but set ovwrt.rdata to FALSE.\n",
           "Set ovwrt.rdata to TRUE and try again.")
    }
  }
  if(file.exists(rdata.file)){
    if(ovwrt.rdata){
      ## Delete the RData file
      cat0(curr.func.name, "RData file found in ", model.dir,
           ". Deleting...\n")
      unlink(rdata.file, force = TRUE)
    }else{
      cat0(curr.func.name, "RData file found in ", model.dir, "\n")
      return(invisible())
    }
  }else{
    cat0(curr.func.name, "No RData file found in ", model.dir,
         ". Creating one now.\n")
  }

  ## If this point is reached, no RData file exists so it
  ##  has to be built from scratch
  model <- load.iscam.files(model.dir)

  ##----------------------------------------------------------------------------
  ## Run forecasts
  ## if(run.forecasts){
  ##   run.forecasts(model,
  ##                 fore.yrs,
  ##                 forecast.probs,
  ##                 forecast.catch.levels)
  ## }
  ##----------------------------------------------------------------------------

  ##----------------------------------------------------------------------------
  ## Run retrospectives
  ## model$retropath <- file.path(model$path, "retrospectives")
  ## if(is.null(model$retropath)){
  ##   model$retropath <- NA
  ## }
  ## if(run.retros){
  ##   run.retrospectives(model,
  ##                      yrs = my.retro.yrs,
  ##                      verbose = verbose)
  ## }
  ##----------------------------------------------------------------------------

  ##----------------------------------------------------------------------------
  ## Load forecasts.  If none are found or there is a problem, model$forecasts
  ##  will be NA
  ## model$forecasts <- fetch.forecasts(model$mcmcpath,
  ##                                    fore.yrs,
  ##                                    forecast.catch.levels,
  ##                                    fore.probs = forecast.probs)
  ## model$risks <- calc.risk(model$forecasts,
  ##                          fore.yrs)
  ##----------------------------------------------------------------------------

  ##----------------------------------------------------------------------------
  ## Load retrospectives. If none are found or there is a problem, model$retros
  ##  will be NA
  ## model$retros <- fetch.retros(model$retropath,
  ##                             my.retro.yrs,
  ##                             verbose = verbose)
  ##----------------------------------------------------------------------------

  ## Save the model as an RData file
  save(model, file = rdata.file)
  return(invisible())
}

load.models <- function(model.dir,
                        model.dir.names,
                        ret.single.list = FALSE){
  ## Load model(s) and return as a list if more than one. If only one,
  ## return that object or if ret.single.list is TRUE, return a 1-element list.
  ret.list = NULL
  model.rdata.files <- file.path(model.dir, model.dir.names, paste0(model.dir.names, ".Rdata"))
  for(i in 1:length(model.rdata.files)){
    load(model.rdata.files[i])
    ret.list[[i]] <- model
    rm(model)
  }
  if(length(model.dir.names) == 1){
    if(ret.single.list){
      ret.list
    }else{
      ret.list[[1]]
    }
  }else{
    ret.list
  }
}

fetch.file.names <- function(path, ## Full path to the file
                             filename
                             ){
  ## Read the starter file and return a list with 3 elements:
  ## 1. Data file name
  ## 2. Control file name
  ## 3. Projection file name

  ## Get the path the file is in
  d <- readLines(file.path(path, filename), warn = FALSE)
  ## Remove comments
  d <- gsub("#.*", "", d)
  ## Remove trailing whitespace
  d <- gsub(" +$", "", d)
  list(file.path(path, d[1]),
       file.path(path, d[2]),
       file.path(path, d[3]))
}

read.report.file <- function(fn){
  # Read in the data from the REP file given as 'fn'.
  # File structure:
  # It is assumed that each text label will be on its own line,
  # followed by one or more lines of data.
  # If the label is followed by a single value or line of data,
  #  a vector will be created to hold the data.
  # If the label is followed by multiple lines of data,
  #  a matrix will be created to hold the data. The matrix might be
  #  ragged so a check is done ahead of time to ensure correct
  #  matrix dimensions.
  #
  # If a label has another label following it but no data,
  #  that label is thrown away and not included in the returned list.
  #
  # A label must start with an alphabetic character followed by
  # any number of alphanumeric characters (includes underscore and .)

  dat <- readLines(fn, warn = FALSE)
  # Remove preceeding and trailing whitespace on all elements,
  #  but not 'between' whitespace.
  dat <- gsub("^[[:blank:]]+", "", dat)
  dat <- gsub("[[:blank:]]+$", "", dat)

  # Find the line indices of the labels
  # Labels start with an alphabetic character followed by
  # zero or more alphanumeric characters
  idx  <- grep("^[[:alpha:]]+[[:alnum:]]*", dat)
  objs <- dat[idx]     # A vector of the object names
  nobj <- length(objs) # Number of objects
  ret  <- list()
  indname <- 0

  for(obj in 1:nobj){
    indname <- match(objs[obj], dat)
    if(obj != nobj){ # If this is the last object
      inddata <- match(objs[obj + 1], dat)
    }else{
      inddata <- length(dat) + 1 # Next row
    }
    # 'inddiff' is the difference between the end of data
    # and the start of data for this object. If it is zero,
    # throw away the label as there is no data associated with it.
    inddiff <- inddata - indname
    tmp <- NA
    if(inddiff > 1){
      if(inddiff == 2){
        # Create and populate a vector
        vecdat <- dat[(indname + 1) : (inddata - 1)]
        vecdat <- strsplit(vecdat,"[[:blank:]]+")[[1]]
        vecnum <- as.numeric(vecdat)
        ret[[objs[obj]]] <- vecnum
      }else if(inddiff > 2){
        # Create and populate a (possible ragged) matrix
        matdat <- dat[(indname + 1) : (inddata - 1)]
        matdat <- strsplit(c(matdat), "[[:blank:]]+")
        # Now we have a vector of strings, each representing a row
        # of the matrix, and not all may be the same length
        rowlengths <- unlist(lapply(matdat, "length"))
        nrow <- max(rowlengths)
        ncol <- length(rowlengths)
        # Create a new list with elements padded out by NAs
        matdat <- lapply(matdat, function(.ele){c(.ele, rep(NA, nrow))[1:nrow]})
        matnum <- do.call(rbind, matdat)
        mode(matnum) <- "numeric"
        ret[[objs[obj]]] <- matnum
      }
    }else{
      # Throw away this label since it has no associated data.
    }
  }
  return(ret)
}

read.data.file <- function(file = NULL,
                           verbose = FALSE){
  ## Read in the iscam datafile given by 'file'
  ## Parses the file into its constituent parts
  ## And returns a list of the contents

  data <- readLines(file, warn=FALSE)
  tmp <- list()
  ind <- 0

  # Remove any empty lines
  data <- data[data != ""]

  # remove preceeding whitespace if it exists
  data <- gsub("^[[:blank:]]+", "", data)

  # Get the element number for the "Gears" names if present
  dat <- grep("^#.*Gears:.+", data)
  tmp$has.gear.names <- FALSE
  if(length(dat > 0)){
    gear.names.str <- gsub("^#.*Gears:(.+)", "\\1", data[dat])
    gear.names <- strsplit(gear.names.str, ",")[[1]]
    tmp$gear.names <- gsub("^[[:blank:]]+", "", gear.names)
    tmp$has.gear.names <- TRUE
  }

  ## Get the element number for the "IndexGears" names if present
  ## dat <- grep("^#.*IndexGears:.+",data)
  ## tmp$hasIndexGearNames <- FALSE
  ## if(length(dat >0)){
  ##   # The gear names were in the file
  ##   indexGearNamesStr <- gsub("^#.*IndexGears:(.+)","\\1",data[dat])
  ##   indexGearNames <- strsplit(indexGearNamesStr,",")[[1]]
  ##   tmp$indexGearNames <- gsub("^[[:blank:]]+","",indexGearNames)
  ##   tmp$hasIndexGearNames <- TRUE
  ## }

  ## # Get the element number for the "AgeGears" names if present (gears with age comp data)
  ## dat <- grep("^#.*AgeGears:.+",data)
  ## tmp$hasAgeGearNames <- FALSE
  ## if(length(dat >0)){
  ##   # The gear names were in the file
  ##   ageGearNamesStr <- gsub("^#.*AgeGears:(.+)","\\1",data[dat])
  ##   ageGearNames <- strsplit(ageGearNamesStr,",")[[1]]
  ##   tmp$ageGearNames <- gsub("^[[:blank:]]+","",ageGearNames)
  ##   tmp$hasAgeGearNames <- TRUE
  ## }

  ## Get the element number for the "CatchUnits" if present
  dat <- grep("^#.*CatchUnits:.+", data)
  if(length(dat > 0)){
    catch.units.str <- gsub("^#.*CatchUnits:(.+)", "\\1", data[dat])
    tmp$catch.units <- gsub("^[[:blank:]]+", "", catch.units.str)
  }

  ## Get the element number for the "IndexUnits" if present
  dat <- grep("^#.*IndexUnits:.+", data)
  if(length(dat > 0)){
    index.units.str <- gsub("^#.*IndexUnits:(.+)", "\\1", data[dat])
    tmp$index.units <- gsub("^[[:blank:]]+", "", index.units.str)
  }

  ## Save the number of specimens per year (comment at end of each age comp
  ##  line), eg. #135 means 135 specimens contributed to the age proportions for
  ##  that year
  age.n <- vector()
  ## Match age comp lines which have N's as comments
  tmp$has.age.comp.n <- FALSE
  pattern <- "^[[:digit:]]{4}[[:space:]]+[[:digit:]][[:space:]]+[[:digit:]][[:space:]]+[[:digit:]][[:space:]]+[[:digit:]].*#([[:digit:]]+).*"
  dat <- data[grep(pattern, data)]
  if(length(dat) > 0){
    for(n in 1:length(dat)){
      age.n[n] <- sub(pattern, "\\1", dat[n])
    }
  }
  ## age.n is now a vector of values of N for the age comp data.
  ## The individual gears have not yet been parsed out, this will
  ##  happen later when the age comps are read in.

  ## Get the element numbers which start with #.
  dat <- grep("^#.*", data)
  ## Remove the lines that start with #.
  dat <- data[-dat]

  ## Remove comments which come at the end of a line
  dat <- gsub("#.*", "", dat)

  ## Remove preceeding and trailing whitespace
  dat <- gsub("^[[:blank:]]+", "", dat)
  dat <- gsub("[[:blank:]]+$", "", dat)

  ## Now we have a nice bunch of string elements which are the inputs for iscam.
  ## Here we parse them into a list structure
  ## This is dependent on the current format of the DAT file and needs to
  ##  be updated whenever the DAT file changes format
  tmp$num.areas  <- as.numeric(dat[ind <- ind + 1])
  tmp$num.groups <- as.numeric(dat[ind <- ind + 1])
  tmp$num.sex    <- as.numeric(dat[ind <- ind + 1])
  tmp$start.yr   <- as.numeric(dat[ind <- ind + 1])
  tmp$end.yr     <- as.numeric(dat[ind <- ind + 1])
  tmp$start.age  <- as.numeric(dat[ind <- ind + 1])
  tmp$end.age    <- as.numeric(dat[ind <- ind + 1])
  tmp$num.gears  <- as.numeric(dat[ind <- ind + 1])

  ## Gear allocation
  tmp$gear.alloc  <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  if(!tmp$has.gear.names){
    tmp$gear.names <- 1:length(tmp$gear.alloc)
  }

  ## Age-schedule and population parameters
  tmp$linf      <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  tmp$k         <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  tmp$to        <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  tmp$lw.alpha  <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  tmp$lw.beta   <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  tmp$age.at.50.mat <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  tmp$sd.at.50.mat  <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  tmp$use.mat   <- as.numeric(dat[ind <- ind + 1])
  tmp$mat.vec   <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])

  ## Delay-difference options
  tmp$dd.k.age   <- as.numeric(dat[ind <- ind + 1])
  tmp$dd.alpha.g <- as.numeric(dat[ind <- ind + 1])
  tmp$dd.rho.g   <- as.numeric(dat[ind <- ind + 1])
  tmp$dd.wk      <- as.numeric(dat[ind <- ind + 1])

  ## Catch data
  tmp$num.catch.obs <- as.numeric(dat[ind <- ind + 1])
  tmp$catch         <- matrix(NA, nrow = tmp$num.catch.obs, ncol = 7)

  for(row in 1:tmp$num.catch.obs){
    tmp$catch[row,] <- as.numeric(strsplit(dat[ind <- ind + 1], "[[:blank:]]+")[[1]])
  }
  colnames(tmp$catch) <- c("year", "gear", "area", "group", "sex", "type", "value")
  ## Abundance indices are a ragged object and are stored as a list of matrices
  tmp$num.indices     <- as.numeric(dat[ind <- ind + 1])
  tmp$num.index.obs   <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  tmp$survey.type <- as.numeric(strsplit(dat[ind <- ind + 1], "[[:blank:]]+")[[1]])
  ##nrows <- sum(tmp$nitnobs)
  tmp$indices <- list()
  for(index in 1:tmp$num.indices){
    nrows <- tmp$num.index.obs[index]
    ncols <- 8
    tmp$indices[[index]] <- matrix(NA, nrow = nrows, ncol = ncols)
    for(row in 1:nrows){
      tmp$indices[[index]][row,] <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
    }
    colnames(tmp$indices[[index]]) <- c("iyr","it","gear","area","group","sex","wt","timing")
  }
  ## Age composition data are a ragged object and are stored as a list of matrices
  tmp$num.age.gears <- as.numeric(dat[ind <- ind + 1])
  ##if(!tmp$hasAgeGearNames){
  ##  tmp$ageGearNames <- 1:length(tmp$nagears)
  ##}

  tmp$num.age.gears.vec       <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  tmp$num.age.gears.start.age <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  tmp$num.age.gears.end.age   <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  tmp$eff                     <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  tmp$age.comp.flag           <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  tmp$age.comps <- NULL
  ## One list element for each gear (tmp$nagears)
  ## Check to see if there are age comp data
  if(tmp$num.age.gears.vec[1] > 0){
   tmp$age.comps <- list()
   for(gear in 1:tmp$num.age.gears){
     nrows <- tmp$num.age.gears.vec[gear]
     ## 5 of the 6 here is for the header columns
     ncols <- tmp$num.age.gears.end.age[gear] - tmp$num.age.gears.start.age[gear] + 6
     tmp$age.comps[[gear]] <- matrix(NA, nrow = nrows, ncol = ncols)
     for(row in 1:nrows){
       tmp$age.comps[[gear]][row,] <- as.numeric(strsplit(dat[ind <- ind + 1], "[[:blank:]]+")[[1]])
     }
     colnames(tmp$age.comps[[gear]]) <- c("year",
                                          "gear",
                                          "area",
                                          "group",
                                          "sex",
                                          tmp$num.age.gears.start.age[gear]:tmp$num.age.gears.end.age[gear])
   }
  }
  ## Build a list of age comp gear N's
  tmp$age.gears.n <- list()
  start <- 1
  for(ng in 1:length(tmp$num.age.gears.vec)){
    end <- start + tmp$num.age.gears.vec[ng] - 1
    tmp$age.gears.n[[ng]] <- age.n[start:end]
    start <- end + 1
  }
  ## Empirical weight-at-age data
  tmp$num.weight.tab <- as.numeric(dat[ind <- ind + 1])
  tmp$num.weight.obs <- as.numeric(dat[ind <- ind + 1])
  tmp$waa <- NULL

  if(tmp$num.weight.obs > 0){
    ## Parse the weight-at-age data
    nrows       <- tmp$num.weight.obs
    ncols       <- tmp$end.age - tmp$start.age + 6
    tmp$weight.at.age <- matrix(NA, nrow = nrows, ncol = ncols)
    for(row in 1:nrows){
      tmp$weight.at.age[row,] <-
        as.numeric(strsplit(dat[ind <- ind + 1], "[[:blank:]]+")[[1]])
    }
    colnames(tmp$weight.at.age) <- c("year",
                                     "gear",
                                     "area",
                                     "group",
                                     "sex",
                                     tmp$start.age:tmp$end.age)
  }

  ## Annual Mean Weight data
  ## Catch data
  tmp$num.mean.weight <- as.numeric(dat[ind <- ind + 1])
  tmp$num.mean.weight.obs <- as.numeric(dat[ind <- ind + 1])
  if(tmp$num.mean.weight.obs >0){
    tmp$mean.weight.data  <- matrix(NA, nrow = sum(tmp$num.mean.weight.obs), ncol = 7)
    for(row in 1:sum(tmp$num.mean.weight.obs)){
      tmp$mean.weight.data[row,] <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
    }
    colnames(tmp$mean.weight.data) <- c("year",
                                        "meanwt",
                                        "gear",
                                        "area",
                                        "group",
                                        "sex",
                                        "timing")
  }
  tmp$eof <- as.numeric(dat[ind <- ind + 1])
  tmp
}

read.control.file <- function(file = NULL,
                              num.gears = NULL,
                              num.age.gears = NULL,
                              verbose = FALSE){
  ## Read in the iscam control file given by 'file'
  ## Parses the file into its constituent parts and returns a list of the
  ##  contents.
  ## num.gears is the total number of gears in the datafile
  ## num.age.gears in the number of gears with age composition information in the
  ##  datafile

  curr.func <- get.curr.func.name()
  if(is.null(num.gears)){
    cat0(curr.func,
         "You must supply the total number of gears (num.gears). ",
         "Returning NULL.")
    return(NULL)
  }
  if(is.null(num.age.gears)){
    cat0(curr.func,
         "You must supply the number of gears with age composition ",
         "(num.age.gears). Returning NULL.")
    return(NULL)
  }

  data <- readLines(file, warn = FALSE)

  ## Remove any empty lines
  data <- data[data != ""]

  ## Remove preceeding whitespace if it exists
  data <- gsub("^[[:blank:]]+", "", data)

  ## Get the element numbers which start with #.
  dat <- grep("^#.*", data)
  ## Remove the lines that start with #.
  dat <- data[-dat]

  ## Save the parameter names, since they are comments and will be deleted in
  ##  subsequent steps.
  ## To get the npar, remove any comments and preceeding and trailing
  ##  whitespace for it.
  dat1 <- gsub("#.*", "", dat[1])
  dat1 <- gsub("^[[:blank:]]+", "", dat1)
  dat1 <- gsub("[[:blank:]]+$", "", dat1)
  n.par <- as.numeric(dat1)
  param.names <- vector()
  ## Lazy matching with # so that the first instance matches, not any other
  pattern <- "^.*?#([[:alnum:]]+_*[[:alnum:]]*).*"
  for(param.name in 1:n.par){
    ## Each parameter line in dat which starts at index 2,
    ##  retrieve the parameter name for that line
    param.names[param.name] <- sub(pattern, "\\1", dat[param.name + 1])
  }
  ## Now that parameter names are stored, parse the file.
  ##  remove comments which come at the end of a line
  dat <- gsub("#.*", "", dat)

  ## Remove preceeding and trailing whitespace
  dat <- gsub("^[[:blank:]]+", "", dat)
  dat <- gsub("[[:blank:]]+$", "", dat)

  ## Now we have a nice bunch of string elements which are the inputs for iscam.
  ## Here we parse them into a list structure.
  ## This is dependent on the current format of the CTL file and needs to
  ## be updated whenever the CTL file changes format.
  tmp <- list()
  ind <- 0
  tmp$num.params <- as.numeric(dat[ind <- ind + 1])
  tmp$params <- matrix(NA, nrow = tmp$num.params, ncol = 7)
  for(param in 1:tmp$num.params){
    tmp$params[param,] <-
      as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  }
  colnames(tmp$params) <- c("ival","lb","ub","phz","prior","p1","p2")
  ## param.names is retreived at the beginning of this function
  rownames(tmp$params) <- param.names

  ## Age and size composition control parameters and likelihood types
  nrows <- 8
  ncols <- num.age.gears
  tmp$age.size <- matrix(NA, nrow = nrows, ncol = ncols)
  for(row in 1:nrows){
    tmp$age.size[row,] <-
      as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  }
  ## Rownames here are hardwired, so if you add a new row you must add a name
  ##  for it here
  rownames(tmp$age.size) <- c("gearind",
                              "likelihoodtype",
                              "minprop",
                              "comprenorm",
                              "logagetau2phase",
                              "phi1phase",
                              "phi2phase",
                              "degfreephase")
  ## Ignore the int check value
  ind <- ind + 1

  ## Selectivity parameters for all gears
  nrows <- 10
  ncols <- num.gears
  tmp$sel <- matrix(NA, nrow = nrows, ncol = ncols)
  for(row in 1:nrows){
    tmp$sel[row,] <-
      as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  }
  ## Rownames here are hardwired, so if you add a new row you must add a name
  ##  for it here
  rownames(tmp$sel) <- c("iseltype",
                         "agelen50log",
                         "std50log",
                         "nagenodes",
                         "nyearnodes",
                         "estphase",
                         "penwt2nddiff",
                         "penwtdome",
                         "penwttvs",
                         "nselblocks")

  ## Start year for time blocks, one for each gear
  max.block <- max(tmp$sel[10,])
  tmp$start.yr.time.block <- matrix(nrow = num.gears, ncol = max.block)
  for(ng in 1:num.gears){
    ## Pad the vector with NA's to make it the right size if it isn't
    ##  maxblocks size.
    tmp.vec <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
    if(length(tmp.vec) < max.block){
      for(i in (length(tmp.vec) + 1):max.block){
        tmp.vec[i] <- NA
      }
    }
    tmp$start.yr.time.block[ng,] <- tmp.vec
  }

  ## Priors for survey Q, one column for each survey
  tmp$num.indices <- as.numeric(dat[ind <- ind + 1])
  nrows <- 3
  ncols <- tmp$num.indices
  tmp$surv.q <- matrix(NA, nrow = nrows, ncol = ncols)
  for(row in 1:nrows){
    tmp$surv.q[row,] <-
      as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])
  }
  ## Rownames here are hardwired, so if you add a new row you must add a name
  ##  for it here.
  rownames(tmp$surv.q) <- c("priortype",
                            "priormeanlog",
                            "priorsd")

  ## Controls for fitting to mean weight data
  tmp$fit.mean.weight <- as.numeric(dat[ind <- ind + 1])
  tmp$num.mean.weight.cv <- as.numeric(dat[ind <- ind + 1])
  n.vals <- tmp$num.mean.weight.cv
  tmp$weight.sig <-  vector(length = n.vals)
  for(val in 1:n.vals){
    tmp$weight.sig[val] <- as.numeric(dat[ind <- ind + 1])
  }

  ## Miscellaneous controls
  n.rows <- 16
  tmp$misc <- matrix(NA, nrow = n.rows, ncol = 1)
  for(row in 1:n.rows){
    tmp$misc[row, 1] <- as.numeric(dat[ind <- ind + 1])
  }
  ## Rownames here are hardwired, so if you add a new row you must add a name
  ##  for it here.
  rownames(tmp$misc) <- c("verbose",
                          "rectype",
                          "sdobscatchfirstphase",
                          "sdobscatchlastphase",
                          "unfishedfirstyear",
                          "maternaleffects",
                          "meanF",
                          "sdmeanFfirstphase",
                          "sdmeanFlastphase",
                          "mdevphase",
                          "sdmdev",
                          "mnumestnodes",
                          "fracZpriorspawn",
                          "agecompliketype",
                          "IFDdist",
                          "fitToMeanWeight")
  tmp$eof <- as.numeric(dat[ind <- ind + 1])
  tmp
}

read.projection.file <- function(file = NULL,
                                 verbose = FALSE){
  ## Read in the projection file given by 'file'
  ## Parses the file into its constituent parts
  ##  and returns a list of the contents

  data <- readLines(file, warn = FALSE)

  ## Remove any empty lines
  data <- data[data != ""]

  ## remove preceeding whitespace if it exists
  data <- gsub("^[[:blank:]]+", "", data)

  ## Get the element numbers which start with #.
  dat <- grep("^#.*", data)
  ## remove the lines that start with #.
  dat <- data[-dat]

  ## remove comments which come at the end of a line
  dat <- gsub("#.*", "", dat)

  ## remove preceeding and trailing whitespace
  dat <- gsub("^[[:blank:]]+", "", dat)
  dat <- gsub("[[:blank:]]+$", "", dat)

  ## Now we have a nice bunch of string elements which are the inputs for iscam.
  ## Here we parse them into a list structure.
  ## This is dependent on the current format of the DAT file and needs to
  ##  be updated whenever the proj file changes format.
  tmp <- list()
  ind <- 0

  ## Get the TAC values
  tmp$num.tac  <- as.numeric(dat[ind <- ind + 1])
  for(tac in 1:tmp$num.tac){
    ## Read in the tacs, one, per line
    tmp$tac.vec[tac] <- as.numeric(dat[ind <- ind + 1])
  }

  ## If the tac vector is on one line
  ##tmp$tac.vec <- as.numeric(strsplit(dat[ind <- ind + 1],"[[:blank:]]+")[[1]])

  ## Get the control options vector
  tmp$num.ctl.options <- as.numeric(dat[ind <- ind + 1])
  n.rows <- tmp$num.ctl.options
  n.cols <- 1
  tmp$ctl.options  <- matrix (NA, nrow = n.rows, ncol = n.cols)
  for(row in 1:n.rows){
    tmp$ctl.options[row, 1] <- as.numeric(dat[ind <- ind + 1])
  }
  ## Rownames here are hardwired, so if you add a new row you must add a name
  ##  or it here.
  option.names <- c("syrmeanm",
                    "nyrmeanm",
                    "syrmeanfecwtageproj",
                    "nyrmeanfecwtageproj",
                    "syrmeanrecproj",
                    "nyrmeanrecproj",
                    "shortcntrlpts",
                    "longcntrlpts",
                    "bmin")
  rownames(tmp$ctl.options) <- option.names[1:tmp$num.ctl.options]
  tmp$eof <- as.numeric(dat[ind <- ind + 1])
  tmp
}

read.par.file <- function(file = NULL,
                          verbose = FALSE){
  ## Read in the parameter estimates file given by 'file'
  ## Parses the file into its constituent parts
  ## And returns a list of the contents

  data <- readLines(file, warn = FALSE)
  tmp <- list()
  ind <- 0

  ## Remove preceeding #
  conv.check <- gsub("^#[[:blank:]]*", "", data[1])
  ## Remove all letters, except 'e'
  ##convCheck <- gsub("[[:alpha:]]+","",convCheck)
  convCheck <- gsub("[abcdfghijklmnopqrstuvwxyz]",
                    "",
                    conv.check,
                    ignore.case = TRUE)
  ## Remove the equals signs
  conv.check <- gsub("=", "", conv.check)
  ## Remove all preceeding and trailing whitespace
  conv.check <- gsub("^[[:blank:]]+", "", conv.check)
  conv.check <- gsub("[[:blank:]]+$", "", conv.check)
  ## Remove the non-numeric parts
  conv.check <- strsplit(conv.check, " +")[[1]]
  conv.check <- conv.check[grep("^[[:digit:]]", conv.check)]
  ## The following values are saved for appending to the tmp list later

  num.params   <- conv.check[1]
  obj.fun.val <-  format(conv.check[2], digits = 6, scientific = FALSE)
  max.gradient <-  format(conv.check[3], digits = 8, scientific = FALSE)

  ##Remove the first line from the par data since we already parsed it and saved the values
  data <- data[-1]

  ## At this point, every odd line is a comment and every even line is the value.
  ## Parse the names from the odd lines (oddData) and parse the
  ## values from the even lines (evenData)
  odd.elem <- seq(1, length(data), 2)
  even.elem <- seq(2, length(data), 2)
  odd.data <- data[odd.elem]
  even.data <- data[even.elem]

  ## Remove preceeding and trailing whitespace if it exists from both
  ##  names and values.
  names <- gsub("^[[:blank:]]+", "", odd.data)
  names <- gsub("[[:blank:]]+$", "", names)
  values <- gsub("^[[:blank:]]+", "", even.data)
  values <- gsub("[[:blank:]]+$", "", values)

  ## Remove the preceeding # and whitespace and the trailing : from the names
  pattern <- "^#[[:blank:]]*(.*)[[:blank:]]*:"
  names <- sub(pattern, "\\1", names)

  ## Remove any square brackets from the names
  names <- gsub("\\[|\\]", "", names)

  data.length <- length(names)
  for(item in 1:(data.length)){
    tmp[[item]] <-
      as.numeric(strsplit(values[ind <- ind + 1], "[[:blank:]]+")[[1]])
  }

  names(tmp) <- names
  tmp$num.params <- num.params
  tmp$obj.fun.val <- as.numeric(obj.fun.val)
  tmp$max.gradient <- as.numeric(max.gradient)
  tmp
}

read.mcmc <- function(model.dir = NULL,
                      verbose = TRUE){
  ## Read in the MCMC results from an iscam model run found in the directory
  ##  model.dir.
  ## Returns a list of the mcmc outputs, or NULL if there was a problem or
  ##  there are no MCMC outputs.

  curr.func <- get.curr.func.name()
  if(is.null(model.dir)){
    cat0(curr.func,
         "You must supply a directory name (model.dir). Returning NULL.")
    return(NULL)
  }
  mcmcfn     <- file.path(model.dir, mcmc.file)
  mcmcsbtfn  <- file.path(model.dir, mcmc.biomass.file)
  mcmcrtfn   <- file.path(model.dir, mcmc.recr.file)
  mcmcrdevfn <- file.path(model.dir, mcmc.recr.devs.file)
  mcmcftfn   <- file.path(model.dir, mcmc.fishing.mort.file)
  mcmcutfn   <- file.path(model.dir, mcmc.fishing.mort.u.file)
  mcmcvbtfn  <- file.path(model.dir, mcmc.vuln.biomass.file)
  mcmcprojfn <- file.path(model.dir, mcmc.proj.file)

  tmp        <- list()
  if(file.exists(mcmcfn)){
    tmp$params <- read.csv(mcmcfn)
  }
  if(file.exists(mcmcsbtfn)){
    sbt        <- read.csv(mcmcsbtfn)
    tmp$sbt    <- extract.group.matrices(sbt, prefix = "sbt")
  }
  if(file.exists(mcmcrtfn)){
    rt         <- read.csv(mcmcrtfn)
    tmp$rt     <- extract.group.matrices(rt, prefix = "rt")
  }
  if(file.exists(mcmcftfn)){
    ft         <- read.csv(mcmcftfn)
    tmp$ft     <- extract.area.sex.matrices(ft, prefix = "ft")
  }
  if(file.exists(mcmcutfn)){
    ut         <- read.csv(mcmcutfn)
    tmp$ut     <- extract.area.sex.matrices(ut, prefix = "ut")
  }
  if(file.exists(mcmcrdevfn)){
    rdev       <- read.csv(mcmcrdevfn)
    tmp$rdev   <- extract.group.matrices(rdev, prefix = "rdev")
  }
  if(file.exists(mcmcvbtfn)){
    vbt        <- read.csv(mcmcvbtfn)
    tmp$vbt    <- extract.area.sex.matrices(vbt, prefix = "vbt")
  }
  tmp$proj <- NULL
  if(file.exists(mcmcprojfn)){
    tmp$proj   <- read.csv(mcmcprojfn)
  }
  tmp
}

extract.group.matrices <- function(data = NULL,
                                   prefix = NULL){
  ## Extract the data frame given (data) by unflattening into a list of matrices
  ## by group. The group number is located in the names of the columns of the
  ## data frame in this format: "prefix[groupnum]_year" where [groupnum] is one
  ## or more digits representing the group number and prefix is the string
  ## given as an argument to the function.
  ## Returns a list of matrices, one element per group.

  curr.func.name <- get.curr.func.name()
  if(is.null(data) || is.null(prefix)){
    cat0(curr.func.name,
         "You must give two arguments (data & prefix). Returning NULL.")
    return(NULL)
  }
  tmp <- list()

  names <- names(data)
  pattern <- paste0(prefix, "([[:digit:]]+)_[[:digit:]]+")
  groups  <- sub(pattern, "\\1", names)
  unique.groups <- unique(as.numeric(groups))
  tmp <- vector("list", length = length(unique.groups))
  ## This code assumes that the groups are numbered sequentially from 1,2,3...N
  for(group in 1:length(unique.groups)){
    ## Get all the column names (group.names) for this group by making a specific
    ##  pattern for it
    group.pattern <- paste0(prefix, group, "_[[:digit:]]+")
    group.names   <- names[grep(group.pattern, names)]
    ## Remove the group number in the name, as it is not needed anymore
    pattern      <- paste0(prefix, "[[:digit:]]+_([[:digit:]]+)")
    group.names   <- sub(pattern, "\\1", group.names)

    # Now, the data must be extracted
    # Get the column numbers that this group are included in
    dat <- data[,grep(group.pattern, names)]
    colnames(dat) <- group.names
    tmp[[group]]  <- dat
  }
  tmp
}

extract.area.sex.matrices <- function(data = NULL,
                                      prefix = NULL){
  ## Extract the data frame given (data) by unflattening into a list of matrices
  ##  by area-sex and gear. The area-sex number is located in the names of the
  ##  columns of the data frame in this format:
  ##  "prefix[areasexnum]_gear[gearnum]_year" where [areasexnum] and [gearnum]
  ##  are one or more digits and prefix is the string given as an argument
  ##  to the function.
  ## Returns a list (area-sex) of lists (gears) of matrices, one element
  ##  per group.

  curr.func.name <- get.curr.func.name()
  if(is.null(data) || is.null(prefix)){
    cat0(curr.func.name,
         "You must give two arguments (data & prefix). Returning NULL.")
    return(NULL)
  }

  names <- names(data)
  pattern <- paste0(prefix, "([[:digit:]]+)_gear[[:digit:]]+_[[:digit:]]+")
  groups  <- sub(pattern, "\\1", names)
  unique.groups <- unique(as.numeric(groups))
  tmp <- vector("list", length = length(unique.groups))
  ## This code assumes that the groups are numbered sequentially from 1,2,3...N
  for(group in 1:length(unique.groups)){
    ## Get all the column names (group.names) for this group by making a
    ##  specific pattern for it
    group.pattern <- paste0(prefix, group, "_gear[[:digit:]]+_[[:digit:]]+")
    group.names <- names[grep(group.pattern, names)]
    ## Remove the group number in the name, as it is not needed anymore
    pattern <- paste0(prefix, "[[:digit:]]+_gear([[:digit:]]+_[[:digit:]]+)")
    group.names <- sub(pattern, "\\1", group.names)
    ## At this point, group.names' elements look like this: 1_1963
    ## The first value is the gear, and the second, the year.
    ## Get the unique gears for this area-sex group
    pattern <- "([[:digit:]]+)_[[:digit:]]+"
    gears <- sub(pattern, "\\1", group.names)
    unique.gears <- unique(as.numeric(gears))
    tmp2 <- vector("list", length = length(unique.gears))
    for(gear in 1:length(unique.gears)){
      gear.pattern <- paste0(prefix, group,"_gear", gear, "_[[:digit:]]+")
      ## Now, the data must be extracted
      ## Get the column numbers that this group are included in
      dat <- data[,grep(gear.pattern, names)]
      ##colnames(dat) <- groupNames
      tmp2[[gear]] <- dat
    }
    tmp[[group]] <- tmp2
  }
  tmp
}

calc.mcmc <- function(mcmc = NULL,     ## mcmc is the output of the read.mcmc
                                       ##  function
                      lower = 0.025,   ## Lower quantile for confidence interval calcs
                      upper = 0.975    ## Upper quantile for confidence interval calcs
                      ){
  ## Do the mcmc calculations, e.g. quantiles for sbt, recr, recdevs, F, U, vbt
  ## Returns a list of them all

  curr.func.name <- get.curr.func.name()
  if(is.null(mcmc)){
    cat0(curr.func.name,
         "The mcmc list was null. Check read.mcmc function. Returning NULL.")
    return(NULL)
  }

  ## Quantiles for the parameters will be in a data frame of 3 rows
  param.quants <- apply(mcmc$params, 2, quantile, prob = c(lower, 0.5, upper))

  ## Spawning biomass
  sbt.lower <- apply(mcmc$sbt[[1]], 2, quantile, prob = lower)
  sbt.med   <- apply(mcmc$sbt[[1]], 2, quantile, prob = 0.5)
  sbt.upper <- apply(mcmc$sbt[[1]], 2, quantile, prob = upper)

  ## Depletion
  depl   <- apply(mcmc$sbt[[1]], 2, function(x){x/mcmc$params$bo})
  depl.lower <- apply(depl, 2, quantile, prob = lower)
  depl.med   <- apply(depl, 2, quantile, prob = 0.5)
  depl.upper <- apply(depl, 2, quantile, prob = upper)

  ## Recruitment
  recr.mean <- apply(mcmc$rt[[1]], 2, mean)
  recr.lower <- apply(mcmc$rt[[1]], 2, quantile, prob = lower)
  recr.med <- apply(mcmc$rt[[1]], 2, quantile, prob = 0.5)
  recr.upper <- apply(mcmc$rt[[1]], 2, quantile, prob = upper)

  ## Recruitment deviations
  recr.devs.lower <- apply(mcmc$rdev[[1]], 2, quantile, prob = lower)
  recr.devs.med <- apply(mcmc$rdev[[1]], 2, quantile, prob = 0.5)
  recr.devs.upper <- apply(mcmc$rdev[[1]], 2, quantile, prob = upper)

  ## Vulnerable biomass by gear (list of data frames)
  vuln.biomass.lower <- lapply(mcmc$vbt[[1]],
                               function(x){apply(x,
                                                 2,
                                                 quantile,
                                                 prob = lower,
                                                 na.rm = TRUE)})
  vuln.biomass.med <- lapply(mcmc$vbt[[1]],
                             function(x){apply(x,
                                               2,
                                               quantile,
                                               prob = 0.5,
                                               na.rm = TRUE)})
  vuln.biomass.upper <- lapply(mcmc$vbt[[1]],
                               function(x){apply(x,
                                                 2,
                                                 quantile,
                                                 prob = upper,
                                                 na.rm = TRUE)})

  ## Fishing mortalities by gear (list of data frames)
  f.lower <- lapply(mcmc$ft[[1]],
                    function(x){apply(x,
                                      2,
                                      quantile,
                                      prob = lower,
                                      na.rm = TRUE)})
  f.med <- lapply(mcmc$ft[[1]],
                    function(x){apply(x,
                                      2,
                                      quantile,
                                      prob = 0.5,
                                      na.rm = TRUE)})
  f.upper <- lapply(mcmc$ft[[1]],
                    function(x){apply(x,
                                      2,
                                      quantile,
                                      prob = upper,
                                      na.rm = TRUE)})
  u.lower <- lapply(mcmc$ut[[1]],
                    function(x){apply(x,
                                      2,
                                      quantile,
                                      prob = lower,
                                      na.rm = TRUE)})
  u.med <- lapply(mcmc$ut[[1]],
                    function(x){apply(x,
                                      2,
                                      quantile,
                                      prob = 0.5,
                                      na.rm = TRUE)})
  u.upper <- lapply(mcmc$ut[[1]],
                    function(x){apply(x,
                                      2,
                                      quantile,
                                      prob = upper,
                                      na.rm = TRUE)})
  list(sbt.lower = sbt.lower,
       sbt.med = sbt.med,
       sbt.upper = sbt.upper,
       depl.lower = depl.lower,
       depl.med = depl.med,
       depl.upper = depl.upper,
       recr.mean = recr.mean,
       recr.lower = recr.lower,
       recr.med = recr.med,
       recr.upper = recr.upper,
       recr.devs.lower = recr.devs.lower,
       recr.devs.med = recr.devs.med,
       recr.devs.upper = recr.devs.upper,
       vuln.biomass.lower = vuln.biomass.lower,
       vuln.biomass.med = vuln.biomass.med,
       vuln.biomass.upper = vuln.biomass.upper,
       f.lower = f.lower,
       f.med = f.med,
       f.upper = f.upper,
       u.lower = u.lower,
       u.med = u.med,
       u.upper = u.upper)
}
