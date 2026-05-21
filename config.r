#libraries to load
library(tidyverse)
library(ggpubr)
library(ggdist)
library(MetBrewer)

#define color scheme
color.scheme <- "VanGogh2"

#list pipelines and those available with nordic
pipeline_list<-c("spmcomcor", "spmgsr", "liming", "roam", "rabies", "rabies_icaaroma", "nonigsr", "aidamri", "ednixgd","ednixgsr", "di2", "di1", "zipp" )

nordic_list<-c( "liming_nordic", "roam_nordic", "rabies_icaaroma_nordic", "ednixgd_nordic","ednixgsr_nordic", "zipp_nordic" )

# set the color scheme
met <- met.brewer(color.scheme, length(pipeline_list))

# a function that reads a table and returns the specificity of the pipeline
pipeline_specificity <- function(cor_file) {
  cor_tmp <- read_table(cor_file, col_names = FALSE, show_col_types = FALSE)
  
#check if cor_tmp is empty and if so, return NA
  if(nrow(cor_tmp) == 0) {
    return(c(NA, NA, NA))
  }

  s1 <- cor_tmp$X2[1]
  aca <- cor_tmp$X3[2]
  
  if(abs(s1) < 0.1 & abs(aca) < 0.1) {
    return(c("no", s1, aca))
  } else if (s1 > 0.1 & aca < 0.1) {
    return(c("specific", s1, aca))
  } else if (s1 < 0.1 & aca > 0.1) {
    return(c("non-specific", s1, aca))
  } else {
    return(c("spurious", s1, aca))
  }
}

# a function that takes df, a path, and a string. Create columns in df with the specificity of the pipeline 
populate_specificity <- function(df, path, pipeline) {
  cor_files <- list.files(path, full.names = TRUE)
  for (i in 1:nrow(df)) {
    j<- str_which(cor_files, df$participant_id[i])
    if (length(j) == 1) {
      tmp <- pipeline_specificity(cor_files[j])
      df[[paste0(pipeline, ".specificity")]][i] <- tmp[1]
      df[[paste0(pipeline, ".s1")]][i] <- tmp[2]
      df[[paste0(pipeline, ".aca")]][i] <- tmp[3]
    }
    else{
      df[[paste0(pipeline, ".specificity")]][i] <- NA
      df[[paste0(pipeline, ".s1")]][i] <- NA
      df[[paste0(pipeline, ".aca")]][i] <- NA
    }
  }
  return(df)
}


