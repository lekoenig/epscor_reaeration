## The objective of this script is to estimate the mean reach travel time from raw YSI data files
## Last updated 4 October 2019 by LE Koenig

# Enter ysi file name:
file.name <- "170921_WHB_L2.csv"



## --------------- Load packages --------------- ##
  library(lubridate)      # work with date/time formats
  library(janitor)        # clean column names


## --------------- Load raw YSI data --------------- ##

  # load data file and adjust column names:
  ysi.dat <- read.table(paste("./data/raw_data_ysi/",file.name,sep=""),sep=",",header=TRUE,fileEncoding="latin1") %>%
             clean_names()

  # format date/timestamps:
  ysi.dat$datetime <- paste(ysi.dat$date,ysi.dat$time,sep=" ")
  ysi.dat$date <- lubridate::mdy(ysi.dat$date)
  ysi.dat$datetime <- lubridate::mdy_hms(ysi.dat$datetime)
  
  # load experiment summary excel file that lists start and end times for each experiment:
  summary.dat <- read_excel("./data/ar_experiments_summary.xlsx",
                            col_types = c("text","date","date","date","numeric")) %>%
                 as.data.frame(.) %>%
                 #return the TIME column to the way it is written in Excel
                 mutate(STARTTIME = as.character(gsub(".* ","",StartTime_24hourformat)),
                        ENDTIME = as.character(gsub(".* ","",EndTime_24hourformat)),
                        # format dates:
                        DATE = as.character(ExperimentDate))
  
  summary.dat$datetime_start <- paste(as.character(summary.dat$ExperimentDate),summary.dat$STARTTIME,sep=" ")
  summary.dat$datetime_end <- paste(as.character(summary.dat$ExperimentDate),summary.dat$ENDTIME,sep=" ")
  summary.dat$ExperimentDate <- as.Date(summary.dat$DATE)
  summary.dat$datetime_start <- lubridate::ymd_hms(summary.dat$datetime_start)
  summary.dat$datetime_end <- lubridate::ymd_hms(summary.dat$datetime_end)
  
  # find experiment that matches ysi date:
  InjStartTime <- summary.dat$datetime_start[which(summary.dat$ExperimentDate %in% ysi.dat$date)]
  InjEndTime <- summary.dat$datetime_end[which(summary.dat$ExperimentDate %in% ysi.dat$date)]
  
  
## --------------- Calculate mean reach travel time --------------- ##

  # Trim ysi data to only include measurements taken within experimental timeframe (as opposed to during transit back to lab, etc.):
  ysi.dat <- ysi.dat[which(ysi.dat$datetime>InjStartTime & ysi.dat$datetime < InjEndTime),]
  
  # Calculate time elapsed since start of injection (in minutes):
  ysi.dat$TimeElapsed <- as.numeric(difftime(ysi.dat$datetime, InjStartTime, units = c("mins")))
  
  # Calculate percent change in conductance for every timestep:
  ysi.dat$dSpC.dt <- ((ysi.dat$sp_cond_µ_s_cm - lag(ysi.dat$sp_cond_µ_s_cm,1))/lag(ysi.dat$sp_cond_µ_s_cm,1))*100
  quantile(ysi.dat$dSpC.dt,na.rm=T)
  
  # Identify datetime of peak percent change in SpC (this should lie near the middle of the experiment):
  peakdelta <- ysi.dat$datetime[which.max(ysi.dat$dSpC.dt)]

  # Estimate plateau spC:
  plateau_spC <- median(ysi.dat$sp_cond_µ_s_cm[which(ysi.dat$datetime > peakdelta & abs(ysi.dat$dSpC.dt)<0.2)])
  background_spC <- median(ysi.dat$sp_cond_µ_s_cm[which(ysi.dat$datetime < peakdelta & abs(ysi.dat$dSpC.dt)<0.2)])
  spC_halfmass <- background_spC + ((plateau_spC-background_spC)/2)
  
  # Calculate median travel time
  # Tmed is equivalent to the time at which 1⁄2 of the plateau concentration is realized (e.g. Runkel 2002, JNABS):
  Tmed <- ysi.dat$TimeElapsed[which.min(abs(ysi.dat$sp_cond_µ_s_cm-spC_halfmass))]
  
  
## --------------- Visualize specific conductance data --------------- ##
  
  par(mfrow=c(1,2))
  plot(ysi.dat$TimeElapsed,ysi.dat$sp_cond_µ_s_cm)
  abline(v = Tmed,lwd=1,lty=2,col="red")
  plot(ysi.dat$TimeElapsed,ysi.dat$dSpC.dt)
  abline(v = Tmed,lwd=1,lty=2,col="red")
  
  
## --------------- Calculate mean water temperature --------------- ##
  
  ysi.dat$temp_c <- (ysi.dat$temp_f-32)*5/9
  MeanTempC <- mean(ysi.dat$temp_c)
  
  # calculate difference in measured water temperature over the experiment:
  temp_diff <- (max(ysi.dat$temp_c) - min(ysi.dat$temp_c))
  
  if(temp_diff > 2){
    print("note: temperature during the experiment differs by more than 2 degrees C")
  }

## --------------- Populate experiment summary file --------------- ##
  
  # load output summary experiment file to add in results:
  output <- read.table("./output/ar_experiments_summary_output.csv",sep=",",header=T,
                       colClasses = c("character","character","character","character",
                                      "integer","numeric","numeric","numeric","numeric",
                                      "numeric","numeric"))

  # subset summary.dat input file for this experiment:
  exp.subset <- summary.dat[which(summary.dat$ExperimentDate %in% ysi.dat$date),]
  
  # populate columns (site, start time, end time, reach length, water temperature)
  output[nrow(output)+1,] <- NA
  
  output$Site[nrow(output)] <- exp.subset$Site
  output$ExperimentDate[nrow(output)] <- as.character(exp.subset$ExperimentDate)
  output$StartTime_24hourformat[nrow(output)] <- exp.subset$STARTTIME
  output$EndTime_24hourformat[nrow(output)] <- exp.subset$ENDTIME
  output$ReachLength_m[nrow(output)] <- exp.subset$ReachLength_m
  output$MedianTravelTime_min[nrow(output)] <- Tmed
  output$AvgWaterTemp_C[nrow(output)] <- MeanTempC
  
  # save new file:
  write.csv(output,"./output/ar_experiments_summary_output.csv",row.names=FALSE)
  
  
  
  
  