# nordic specificity analysis
Joanes Grandjean
2024-06-18

## load the all the libraries used on this notebook and set important variable

``` r
source("config.r")
```

# only run this once

``` r
df <- read_tsv("assets/table/participants.tsv") %>% select(participant_id)


for(i in 1:length(nordic_list)){
  print(c('processing ',nordic_list[i]))
  df <- populate_specificity(df, paste0("/project/4180000.41/data/", nordic_list[i], "/corr"), nordic_list[i])
}

write_tsv(df, "assets/table/participants_specificity_nordic.tsv")
```

``` r
df <- read_tsv("assets/table/participants_specificity_nordic.tsv",, show_col_types = FALSE)
df_exclude <- read_tsv("assets/table/participants_exclude.tsv", , show_col_types = FALSE)
df_baseline <- read_tsv("assets/table/participants_specificity.tsv",, show_col_types = FALSE)

df <- df %>% full_join (df_baseline, by = "participant_id") %>% full_join(df_exclude, by = "participant_id")

# for every column in df ending with .specificity, convert the column to a factor
for (i in 2:ncol(df)) {
  if (str_detect(colnames(df)[i], "specificity")) {
    df[[colnames(df)[i]]] <- as.factor(df[[colnames(df)[i]]])
  }
}
```

``` r
#for every column in df ending with _nordic.specificity, print the summary() of this column, and the summary() of the column without the _nordic sufix
for (i in 2:ncol(df)) {
  if (str_detect(colnames(df)[i], "_nordic.specificity")) {
    print(c("summary of ", colnames(df)[i]))
    print(summary(df[[colnames(df)[i]]]))
    
    baseline_col <- str_replace(colnames(df)[i], "_nordic", "")
    print(c("summary of ", baseline_col))
    print(summary(df[[baseline_col]]))
  }
}
```

``` r
nordic_specificity_plot <- function(df, pipeline){

  library(tidyverse)

  #rename in df all the columns that start with the pipeline variable, and rename to "select"
  p <- df %>% rename_with(~ str_replace(., paste0(pipeline, "."), "default."), starts_with(pipeline)) %>%
        filter(default.exclude != 0) %>% 
        select(participant_id, starts_with("default"), -ends_with("specificity"), -default.exclude) %>%
        rename_with(~ str_replace(., "default.nordic", "nordic")) %>%
        pivot_longer(cols = -participant_id, names_to = c("pipeline", "metric"), names_pattern = "(default|nordic).(s1|aca)") %>%
        pivot_wider(names_from = metric, values_from = value) %>%
        ggplot(aes(x = s1, y = aca)) +
          stat_density_2d(aes(colour = pipeline)) +
          geom_vline(xintercept = 0.1, linetype = "dashed", linewidth=0.2) + 
          geom_hline(yintercept = 0.1, linetype = "dashed", linewidth=0.2) + 
          geom_segment(aes(x=-0.1,xend=0.1,y=-0.1,yend=-0.1),linetype = "dashed", linewidth=0.2, colour='black') + 
          geom_segment(aes(x=-0.1,xend=-0.1,y=0.1,yend=-0.1),linetype = "dashed", linewidth=0.2, colour='black') + 
          xlim(-0.5, 1) + 
          ylim(-0.5, 1) + 
          scale_colour_manual(values=met[c(2,11)]) +
          theme_classic() +
          labs(title = pipeline) +
          theme(legend.position = "none", axis.text =element_blank(), axis.title = element_blank(), axis.ticks = element_blank(), plot.title = element_text(hjust = 0.5))  

  return(p)
}




for(i in 1:length(nordic_list)){
  pipeline <- str_replace(nordic_list[i],"_nordic", "")
  assign(paste0(pipeline, "_spec"), nordic_specificity_plot(df, pipeline))
}

combine_spec <- ggarrange(plotlist=mget(paste0(str_replace(nordic_list,"_nordic",""),"_spec")), labels = LETTERS[1:length(nordic_list)])

#make a tmp save of the plot
ggsave("assets/tmp/nordic.png",plot=combine_spec, height=2000, width=2000, units='px')
```
