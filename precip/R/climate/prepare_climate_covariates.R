#####################################################################################
#
# Make climate variables from quarterly climate 
#
#####################################################################################

rm(list = ls() )

library(dplyr)
library(tidyr)
library(ggplot2)
library(zoo)

# -- specify climate variables -------------------------------------------------------# 

clim_vars <- c('T.sp.1', 'T.sp.2', 'P.w.sp.1', 'P.w.sp.2', 'T.su.1', 'T.su.2', 'P.a.0', 'P.a.1')
clim_vars <- sort(clim_vars)

# ------- load files ------------------------------------------------------------------ 

quarterly_clim <- readRDS('data/temp_data/quarterly_climate.RDS')

# ------ calculate quarterly lags -----------------------------------------------------# 
#
#   Variable names follow these conventions: 
#   
#     First letter gives variable type: 
#       "P" is cumulative precipitation
#       "T" is average mean monthly temperature
#
#     Letters after the first period give the season aggregation window:
#
#       w  = winter (Q1) 
#       sp = spring (Q2)
#       su = summer (Q3)
#       f  = fall   (Q4)
#       a  = annual (Q1-4)
#
#     e.g. "P.sp" is the cumulative precipitation of the spring quarter and "P.w.sp" is
#     the cumulative precipitation of the winter and spring. 
#   
#     Number after the second period indicates the year of the transition, For example, 
#     "P.sp.1" gives the cumulative precipitation of the spring preceding the first year of the 
#     transition, whereas "T.f.w.2" gives the average temperature of the fall and winter 
#     preceding the second year of the transition. "0" refers to year before first year, 
#     i.e. "lag effect" (sensu Adler). 
#
# -------------------------------------------------------------------------------------# 
q_precip <- 
  quarterly_clim %>% 
  filter( var == 'TPCP_ttl') %>%
  group_by(Treatment) %>% 
  arrange(Treatment, year, quarter) %>%
  mutate(P.sp.2 = val, 
         P.sp.1 = lag(val, 4), 
         P.w.sp.2 = rollsum(val, 2, align = 'right', fill = NA), 
         P.w.sp.1 = lag(P.w.sp.2, 4), 
         P.su.2 = lag(val, 3), 
         P.su.1 = lag(P.su.2, 4),
         P.a.2 = rollsum(val, 4, align = 'right', fill = NA), 
         P.a.1 = lag(P.a.2, 4), 
         P.a.0 = lag(P.a.1, 4)) %>% 
  filter( quarter == 'Q2') %>% # plants are measured at the end of Q2 each year 
  select( Treatment, Period, year, quarter, starts_with("P"))

q_temp <- 
  quarterly_clim %>% 
  filter( var == 'MNTM_avg') %>% 
  group_by(Treatment) %>% 
  arrange(Treatment, year, quarter) %>% 
  mutate( T.sp.2 = val, 
          T.sp.1 = lag(T.sp.2, 4),
          T.sp.0 = lag(T.sp.1, 4), 
          T.w.sp.2 = rollapply(val, 2, 'mean', na.rm = TRUE, align = 'right', fill = NA), 
          T.w.sp.1 = lag(T.w.sp.2, 4),
          T.w.sp.0 = lag(T.w.sp.1, 4),
          T.su.2 = lag(val, 3),
          T.su.1 = lag(T.su.2, 4)) %>% 
  filter( quarter == 'Q2') %>% 
  select( Treatment, Period, year, quarter, starts_with("T"))

allClim <- 
  q_precip %>% 
  left_join ( q_temp, by = c('Treatment', 'Period', 'quarter', 'year')) %>% 
  arrange( Treatment, year) 

# -- calculate interactions --------------------------------------------------------------#

# make interactions: 
# test$TxP.sp.1 <- test$P.sp.1*test$T.sp.1
# test$TxP.sp.2 <- test$P.sp.2*test$T.sp.2


# ---- output ----------------------------------------------------------------------------# 

saveRDS( data.frame( allClim ) , 'data/temp_data/all_clim_covs.RDS')
