library(tidyverse)

url_regional_codes <-
  'https://raw.githubusercontent.com/ondata/covid19italia/master/webservices/vaccini/risorse/codiciTerritoriali.csv'

regional_codes <- read_csv(url_regional_codes)

url_regions_population <-
  'https://raw.githubusercontent.com/ondata/covid19italia/master/webservices/vaccini/risorse/popolazioneRegioni.csv'

read_csv(url_regions_population) %>%
  inner_join(regional_codes, by = 'Name') %>%
  select(Name, siglaRegione, NUTS2, OBS_VALUE) %>%
  rename(
    nome = Name,
    area = siglaRegione,
    popolazione_2020 = OBS_VALUE
  ) %>%
  write_csv('data/regions_population.csv')