library(tidyverse)

# Vaccine deliveries data ####

url_ita_doses_delivered <-
  'https://raw.githubusercontent.com/italia/covid19-opendata-vaccini/master/dati/consegne-vaccini-latest.csv'

read_csv(url_ita_doses_delivered) %>%
  mutate(area = as.factor(area)) -> ita_doses_delivered

ita_doses_delivered %>%
  write.csv('data/ita_doses_delivered.csv', row.names = F)

# Vaccinations data by age range and area ####

url_ita_data <-
  'https://raw.githubusercontent.com/italia/covid19-opendata-vaccini/master/dati/somministrazioni-vaccini-latest.csv'

read_csv(url_ita_data) %>%
  mutate(across(c(area, fascia_anagrafica), as.factor)) %>%
  rename_with( ~ str_remove(.x, 'categoria_')) -> 
  ita_data

ita_data %>%
  write.csv('data/ita_data.csv', row.names = F)


#####

# Data aggregated by area ####

ita_data %>%
  group_by(data_somministrazione, area) %>%
  summarise(across(where(is.numeric), sum)) %>%
  mutate(
    nuovi_vaccinati = sesso_maschile + sesso_femminile,
  ) %>%
  relocate(nuovi_vaccinati, .after = area) ->
  ita_aggregated_by_area

ita_aggregated_by_area %>%
  write.csv('data/ita_aggregated_by_area.csv', row.names = F)

# Data aggregated by age range ####

ita_data %>%
  group_by(data_somministrazione, fascia_anagrafica) %>%
  summarise(across(where(is.numeric), sum)) %>%
  mutate(
    nuovi_vaccinati = sesso_maschile + sesso_femminile,
  ) %>%
  relocate(nuovi_vaccinati, .after = fascia_anagrafica) ->
  ita_aggregated_by_age_range

ita_aggregated_by_age_range %>%
  write.csv('data/ita_aggregated_by_age_range.csv', row.names = F)

# Totals by age range ####

ita_aggregated_by_age_range %>%
  group_by(fascia_anagrafica) %>%
  summarise(across(where(is.numeric), sum)) ->
  ita_totals_by_age_range

ita_totals_by_age_range %>%
  write.csv('data/ita_totals_by_age_range.csv', row.names = F) 

# Totals by area ####

ita_aggregated_by_area %>%
  group_by(area) %>%
  summarise(across(where(is.numeric), sum)) %>%
  rename(totale_vaccinati = nuovi_vaccinati) %>%
  add_row(area = 'ITA',
          # the `.` indicates the object itself!
          totale_vaccinati = sum(.$totale_vaccinati),
          sesso_maschile = sum(.$sesso_maschile),
          sesso_femminile = sum(.$sesso_femminile),
          operatori_sanitari_sociosanitari = sum(.$operatori_sanitari_sociosanitari),
          personale_non_sanitario = sum(.$personale_non_sanitario),
          ospiti_rsa = sum(.$ospiti_rsa),
  ) -> ita_totals_by_area


#####

# Regional population data ####

population_data <- read_csv('data/regions_population.csv')

# group_by of vaccine deliveries data
ita_doses_delivered %>%
  group_by(area) %>%
  summarise(totale_dosi = sum(numero_dosi)) %>%
  inner_join(population_data, by = 'area') %>%
  relocate(nome) %>%
  add_row(
    nome = 'Italia',
    area = 'ITA',
    totale_dosi = sum(.$totale_dosi),
    popolazione_2020 = sum(.$popolazione_2020)
  ) -> ita_total_doses_delivered
  
ita_totals_by_area %>%
  inner_join(ita_total_doses_delivered, by = 'area') %>%
  relocate(nome) %>%
  relocate(popolazione_2020, .after = area) %>%
  relocate(totale_dosi, .after = popolazione_2020) %>%
  mutate(
    dosi_ogni_mille = round(totale_dosi / popolazione_2020 * 1000, digits = 2),
    vaccini_ogni_mille = round(totale_vaccinati / popolazione_2020 * 1000, digits = 2),
    percent_vaccini_somministrati = round(totale_vaccinati / totale_dosi, digits = 2),
  ) %>%
  relocate(popolazione_2020, .after = area) %>%
  relocate(dosi_ogni_mille, .after = totale_vaccinati) %>%
  relocate(vaccini_ogni_mille, .after = dosi_ogni_mille) %>%
  relocate(percent_vaccini_somministrati, .after = vaccini_ogni_mille)
  write.csv('data/ita_totals_by_area.csv', row.names = F)
