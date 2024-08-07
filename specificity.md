# Pipeline specificity analysis
Joanes Grandjean
2024-06-18

## load the all the libraries used on this notebook and set important variables

``` r
library(tidyverse)
library(ggpubr)
library(ggdist)
library(MetBrewer)

color.scheme <- "VanGogh2"
n.pipeline <- 4

met <- met.brewer(color.scheme, n.pipeline)
```

## populate the participants table with the results of the pipeline. Only run once to make the table.

``` r
# write a function that reads a table and returns the specificity of the pipeline
pipeline_specificity <- function(cor_file) {
  cor_tmp <- read_table(cor_file, col_names = FALSE, show_col_types = FALSE)
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


df <- read_tsv("assets/table/participants.tsv") %>% select(participant_id)

# SPM pipeline variables init
df$spm.s1 <- NA
df$spm.aca <- NA
df$spm.specificity <- NA

spm_cor_files <- list.files("/project/4180000.41/data/cas_export/corr", full.names = TRUE)

# RABIES pipeline variables init
df$rabies.s1 <- NA
df$rabies.aca <- NA
df$rabies.specificity <- NA

rabies_cor_files <- list.files("/project/4180000.41/data/rabies_export/corr", full.names = TRUE)

# DI1 pipeline variables init
df$di1.s1 <- NA
df$di1.aca <- NA
df$di1.specificity <- NA

di1_cor_files <- list.files("/project/4180000.41/data/di1_export/corr", full.names = TRUE)


# easymribrain pipeline variables init
df$easymribrain.s1 <- NA
df$easymribrain.aca <- NA
df$easymribrain.specificity <- NA

easymribrain_cor_files <- list.files("/project/4180000.41/data/garin_export/corr", full.names = TRUE)

# the big loop that populates the table

for (i in 1:nrow(df)) {
  j<- str_which(spm_cor_files, df$participant_id[i])
  if (length(j) == 1) {
  
  tmp <- pipeline_specificity(spm_cor_files[j])
  df$spm.specificity[i] <- tmp[1]
  df$spm.s1[i] <- tmp[2]
  df$spm.aca[i] <- tmp[3] 
  }

  j<- str_which(rabies_cor_files, df$participant_id[i])
  if (length(j) == 1) {

  tmp <- pipeline_specificity(rabies_cor_files[j])
  df$rabies.specificity[i] <- tmp[1]
  df$rabies.s1[i] <- tmp[2]
  df$rabies.aca[i] <- tmp[3]
  }

  j<- str_which(di1_cor_files, df$participant_id[i])
  if (length(j) == 1) {

  tmp <- pipeline_specificity(di1_cor_files[j])
  df$di1.specificity[i] <- tmp[1]
  df$di1.s1[i] <- tmp[2]
  df$di1.aca[i] <- tmp[3]
  }

  j<- str_which(easymribrain_cor_files, df$participant_id[i])
  if (length(j) == 1) {

  tmp <- pipeline_specificity(easymribrain_cor_files[j])
  df$easymribrain.specificity[i] <- tmp[1]
  df$easymribrain.s1[i] <- tmp[2]
  df$easymribrain.aca[i] <- tmp[3]
  } 
}


write_tsv(df, "assets/table/participants_specificity.tsv")
```

## Filter the participants by exclusion criteria and carry out specificity analysis

``` r
df <- read_tsv("assets/table/participants_specificity.tsv",, show_col_types = FALSE)
df_exclude <- read_tsv("assets/table/participants_exclude.tsv", , show_col_types = FALSE)

df <- df %>% full_join(df_exclude, by = "participant_id")

# transform the specificity variales into factors
df$spm.specificity <- as.factor(df$spm.specificity)
df$rabies.specificity <- as.factor(df$rabies.specificity)
df$di1.specificity <- as.factor(df$di1.specificity)
df$easymribrain.specificity <- as.factor(df$easymribrain.specificity)
```

``` r
# look at specificity without filtering for data exclusion
df %>% select(spm.specificity, rabies.specificity, di1.specificity, easymribrain.specificity) %>% summary()
```

         spm.specificity    rabies.specificity     di1.specificity
     no          : 12    no          : 22      no          : 22   
     non-specific:  4    non-specific:  4      non-specific:  7   
     specific    : 55    specific    :111      specific    :131   
     spurious    :136    spurious    : 58      spurious    : 49   
     NA's        :  2    NA's        : 14                         
     easymribrain.specificity
     no          :29         
     non-specific:11         
     specific    :78         
     spurious    :89         
     NA's        : 2         

``` r
# look at specificity after filtering for data exclusion
df %>% filter(global.exclude == 0) %>% select(spm.specificity, rabies.specificity, di1.specificity, easymribrain.specificity) %>% summary()
```

         spm.specificity    rabies.specificity     di1.specificity
     no          : 11    no          : 22      no          : 22   
     non-specific:  2    non-specific:  4      non-specific:  6   
     specific    : 50    specific    :107      specific    :122   
     spurious    :125    spurious    : 55      spurious    : 38   
                                                                  
     easymribrain.specificity
     no          :27         
     non-specific: 8         
     specific    :73         
     spurious    :79         
     NA's        : 1         

``` r
# are the difference in specificity related to raw functional connectivity between s1?
df %>% filter(global.exclude == 0) %>% select(spm.s1, rabies.s1, di1.s1, easymribrain.s1) %>% summary()
```

         spm.s1          rabies.s1            di1.s1         easymribrain.s1   
     Min.   :-0.1037   Min.   :-0.04058   Min.   :-0.08585   Min.   :-0.17283  
     1st Qu.: 0.2471   1st Qu.: 0.16810   1st Qu.: 0.13009   1st Qu.: 0.09401  
     Median : 0.4064   Median : 0.29782   Median : 0.29459   Median : 0.22118  
     Mean   : 0.4238   Mean   : 0.32903   Mean   : 0.31227   Mean   : 0.25622  
     3rd Qu.: 0.6084   3rd Qu.: 0.51494   3rd Qu.: 0.48682   3rd Qu.: 0.38048  
     Max.   : 0.8868   Max.   : 0.78714   Max.   : 0.78341   Max.   : 0.88179  
                                                             NA's   :1         

``` r
# are the difference in specificity related to raw functional connectivity between s1 and aca?
df %>% filter(global.exclude == 0) %>% select(spm.aca, rabies.aca, di1.aca, easymribrain.aca) %>% summary()
```

        spm.aca           rabies.aca          di1.aca         easymribrain.aca   
     Min.   :-0.11245   Min.   :-0.35826   Min.   :-0.59714   Min.   :-0.323180  
     1st Qu.: 0.06876   1st Qu.:-0.00710   1st Qu.:-0.12304   1st Qu.:-0.004245  
     Median : 0.19087   Median : 0.04566   Median :-0.03870   Median : 0.061360  
     Mean   : 0.20599   Mean   : 0.05625   Mean   :-0.02826   Mean   : 0.080732  
     3rd Qu.: 0.31884   3rd Qu.: 0.12019   3rd Qu.: 0.05076   3rd Qu.: 0.172740  
     Max.   : 0.70316   Max.   : 0.52546   Max.   : 0.71522   Max.   : 0.722300  
                                                              NA's   :1          

## this section plots pipeline specificity for each pipeline

``` r
pipeline_specificity_plot <- function(df, x, y, exclude, pipeline, met){
  
  library(tidyverse)
  library(ggExtra)

  p <- df %>% filter(!!sym(exclude) == 0) %>%
    ggplot(aes(x = !!sym(x), 
               y = !!sym(y), 
               color = as.factor(global.exclude))) + 
    geom_point(size = 0.1) + 
    geom_vline(xintercept = 0.1, linetype = "dashed", linewidth=0.3) + 
    geom_hline(yintercept = 0.1, linetype = "dashed", linewidth=0.3) + 
    geom_segment(aes(x=-0.1,xend=0.1,y=-0.1,yend=-0.1),linetype = "dashed", linewidth=0.3, colour='black') + 
    geom_segment(aes(x=-0.1,xend=-0.1,y=0.1,yend=-0.1),linetype = "dashed", linewidth=0.3, colour='black') + 
    xlim(-0.5, 1) + 
    ylim(-0.5, 1) + 
    #labs(title = pipeline, x = "S1 - S1 [r]", y = "S1 - ACA [r]") +
    scale_color_manual(values = c(met, "darkgrey")) +
    theme_classic() +
    theme(legend.position = "none", axis.text =element_blank(), axis.title = element_blank(), axis.ticks = element_blank()) 

  m <- ggMarginal(p, fill = met, color = NaN, size = 10) 

  return(m)
}



spm_spec <- pipeline_specificity_plot(df, "spm.s1", "spm.aca", "spm.exclude", "SPM", met[1])
rabies_spec <- pipeline_specificity_plot(df, "rabies.s1", "rabies.aca", "rabies.exclude", "RABIES", met[2])
easymribrain_spec <- pipeline_specificity_plot(df, "easymribrain.s1", "easymribrain.aca", "easymribrain.exclude", "easyMRIbrain", met[3])
di1_spec <- pipeline_specificity_plot(df, "di1.s1", "di1.aca", "di1.exclude", "DI1", met[4])
combine_spec <- ggarrange(spm_spec, rabies_spec, easymribrain_spec, di1_spec, ncol = 2, nrow = 2, labels = c("A", "B", "C", "D"))
```

## this section plots S1 - S1 correlations across pipelines

``` r
# select the s1 colums and global exclude from df and pivot the table
df_s1 <- df %>% select(participant_id, spm.s1, rabies.s1, di1.s1, easymribrain.s1, global.exclude) %>% pivot_longer(cols = c(spm.s1, rabies.s1, di1.s1, easymribrain.s1), names_to = "pipeline", values_to = "s1")

# rename the pipelines to remove the .s1 and capitalize all
df_s1$pipeline <- str_to_upper(df_s1$pipeline)
df_s1$pipeline <- str_remove(df_s1$pipeline, ".S1")

s1_plot <- df_s1 %>% ggplot(aes(x = s1, y = pipeline, group = pipeline, fill = pipeline)) + 
  stat_slab(aes(thickness = after_stat(pdf*n)), scale = 0.5) + 
  stat_dotsinterval(side = "bottom", scale = 0.2, slab_linewidth = NA) +
  geom_vline(xintercept = 0.1, linetype = "dashed", linewidth=0.3) +
  scale_fill_manual(values = rev(met)) +
  xlim(-0.5, 1) +
  theme_classic() + 
  theme(legend.position = "none", axis.title.y=element_blank()) +
  labs(title = "Specific correlation", x = "S1 - S1 [r]", y = "Pipeline")
```

## this section plots S1 - ACA correlation across pipelines

``` r
# select the aca colums and global exclude from df and pivot the table
df_aca <- df %>% select(participant_id, spm.aca, rabies.aca, di1.aca, easymribrain.aca, global.exclude) %>% pivot_longer(cols = c(spm.aca, rabies.aca, di1.aca, easymribrain.aca), names_to = "pipeline", values_to = "aca")

# rename the pipelines to remove the .aca and capitalize all
df_aca$pipeline <- str_to_upper(df_aca$pipeline)
df_aca$pipeline <- str_remove(df_aca$pipeline, ".ACA")


aca_plot <- df_aca %>% ggplot(aes(y = aca, x = pipeline, group = pipeline, fill = pipeline)) + 
  stat_slab(aes(thickness = after_stat(pdf*n)), scale = 0.5) + 
  stat_dotsinterval(side = "bottom", scale = 0.2, slab_linewidth = NA) +
  geom_hline(yintercept = 0.1, linetype = "dashed", linewidth=0.3) + 
  scale_fill_manual(values = rev(met)) +
  ylim(-0.5, 1) +
  theme_classic() + 
  theme(legend.position = "none", axis.title.x = element_blank()) + 
  labs(title = "Non-specific correlation", y = "S1 - ACA [r]")
```

``` r
# select the specificity colums from df and pivot the table
df_spec <- df %>% select(participant_id, spm.specificity, rabies.specificity, di1.specificity, easymribrain.specificity) %>% pivot_longer(cols = c(spm.specificity, rabies.specificity, di1.specificity, easymribrain.specificity), names_to = "pipeline", values_to = "specific")

df_spec$pipeline <- str_remove(df_spec$pipeline, ".specificity")
df_spec$pipeline <- str_to_upper(df_spec$pipeline)

summary_plot <- df_spec %>% ggplot(aes(x = pipeline,  
                       group = specific, 
                       fill = specific)) + 
  geom_bar() +
  scale_fill_manual(values = met.brewer("VanGogh2",5)) +
  theme_classic() + 
  theme(legend.position = "none", 
        axis.title.x = element_blank(), 
        axis.line.x = element_blank(), 
        axis.ticks.x = element_blank()) +
  labs(y = "# scans")
```

## puts all the figures together

``` r
combine_plot <- ggarrange(combine_spec, s1_plot, aca_plot, summary_plot, labels = c("", "E", "F", "G"), ncol = 2, nrow = 2)

ggsave("assets/figures/pipeline_specificity.svg", plot=combine_plot, width = 180, height = 120, unit = 'mm', dpi = 300)
```

![figure_specificity](assets/figures/pipeline_specificity.svg)
