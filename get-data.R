library(tidyverse)

# Vaccine Deliveries ####

url_vaccine_deliveries_ita <-
  'https://raw.githubusercontent.com/italia/covid19-opendata-vaccini/master/dati/consegne-vaccini-latest.csv'

read_csv(url_vaccine_deliveries_ita) %>%
  mutate(area = as.factor(area)) -> vaccine_deliveries_ita

vaccine_deliveries_ita %>%
  write.csv('data/ita_vaccine_deliveries.csv', row.names = F)

# Vaccinations Data by Demography ####

url_vaccinations_demographic_data <-
  'https://raw.githubusercontent.com/italia/covid19-opendata-vaccini/master/dati/somministrazioni-vaccini-latest.csv'

read_csv(url_vaccinations_demographic_data) %>%
  mutate(across(c(area, fascia_anagrafica), as.factor)) -> 
  vaccinations_demographic_data

vaccinations_demographic_data %>%
  write.csv('data/ita_vaccinations_per_age_range.csv', row.names = F)

# Aggregate Vaccinations Data ####

vaccinations_aggregated_data <-
  vaccinations_demographic_data %>%
  group_by(data_somministrazione, area) %>%
  summarise(across(where(is.numeric), sum)) %>%
  mutate(
    totale = sesso_maschile + sesso_femminile,
  ) %>%
  relocate(totale, .after = area)

vaccinations_aggregated_data %>%
  write.csv('data/ita_vaccinations_aggregated.csv', row.names = F)

# Cumulative Vaccination Data ####

vaccinations_cumulative_italy <-
  vaccinations_aggregated_data %>%
  group_by(area) %>%
  summarise(totale = sum(totale)) %>%
  add_row(area = 'ITA',
          totale = sum(.$totale)) # the `.` indicates the file itself!

# Create two new columns for cumulative data ####

# group_by of vaccine deliveries data
cumulative_vaccine_deliveries <-
  vaccine_deliveries_ita %>%
  group_by(area) %>%
  summarise(totale_dosi = sum(numero_dosi)) %>%
  add_row(
    area = 'ITA',
    totale_dosi = sum(.$totale_dosi) 
  )

# retrieve regional population data thanks to OnData:

url_regions_population <-
  'https://raw.githubusercontent.com/ondata/covid19italia/master/webservices/vaccini/risorse/popolazioneRegioni.csv'

regions_population <-
  read_csv(url_regions_population) %>%
  # order them before making an unorthodox merge
  arrange(Name) %>%
  bind_cols(
    # since they are both sorted, add this column from another dataset
    cumulative_vaccine_deliveries[1:21, 1]
  ) %>%
  select(area, OBS_VALUE) %>%
  add_row(
    area= 'ITA',
    OBS_VALUE = sum(.$OBS_VALUE)
  ) %>%
  rename(popolazione_2020 = OBS_VALUE)


# append vaccine deliveries data
vaccinations_cumulative_italy %>%
  inner_join(cumulative_vaccine_deliveries, by = 'area') %>%
  inner_join(regions_population, by = 'area') %>%
  rename(
    vaccinazioni_eseguite = totale,
    dosi_consegnate = totale_dosi
  ) %>%
  mutate(
    percentuale_somministrata = round(vaccinazioni_eseguite / dosi_consegnate, digits = 2),
    vaccinati_su_centomila = round(vaccinazioni_eseguite / popolazione_2020, digits = 3) * 100000
  ) %>%
  write.csv('data/ita_vaccinations_cumulative.csv', row.names = F)
