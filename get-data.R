library(tidyverse)

# Vaccine deliveries data ####

url_doses_delivered_ita <-
  'https://raw.githubusercontent.com/italia/covid19-opendata-vaccini/master/dati/consegne-vaccini-latest.csv'

read_csv(url_doses_delivered_ita) %>%
  rename(consegnate = numero_dosi) %>%
  relocate(data_consegna, .after = 'area') %>%
  rename(data = data_consegna) %>%
  pivot_wider(names_from = fornitore, values_from = consegnate) %>%
  rename(
    dosi_pfizer = 'Pfizer/BioNTech',
    dosi_moderna = Moderna
  ) %>%
  group_by(area) %>%
  mutate(
    area = as.factor(area),
    dosi_pfizer = coalesce(dosi_pfizer, 0),
    dosi_moderna = coalesce(dosi_moderna, 0),
    totale_pfizer = cumsum(dosi_pfizer),
    totale_moderna = cumsum(dosi_moderna),
  ) -> doses_delivered_ita

doses_delivered_ita %>%
  write_csv('data_italy/doses_delivered_ita.csv')

# Vaccinations data by age range and area ####

url_data_italy <-
  'https://raw.githubusercontent.com/italia/covid19-opendata-vaccini/master/dati/somministrazioni-vaccini-latest.csv'

read_csv(url_data_italy) %>%
  mutate(across(c(area, fascia_anagrafica), as.factor)) %>%
  rename_with( ~ str_remove(.x, 'categoria_')) %>%
  rename(
    operatori_sanitari = operatori_sanitari_sociosanitari,
    data = data_somministrazione
  ) %>%
  mutate(nuovi_vaccinati = sesso_maschile + sesso_femminile) %>%
  relocate(nuovi_vaccinati, .after = 'fascia_anagrafica') -> 
  vaccine_data_italy

vaccine_data_italy %>%
  write_csv('data_italy/vaccine_data_italy.csv')


#####

# Data aggregated by area ####

vaccine_data_italy %>%
  group_by(data, area) %>%
  summarise(across(where(is.numeric), sum)) %>%
  relocate(nuovi_vaccinati, .after = area) %>%
  group_by(area) %>%
  mutate(across(where(is.numeric), list(totale = ~ cumsum(.x)))) %>%
  rename(vaccinati_totale = nuovi_vaccinati_totale) %>%
  arrange(area) ->
  aggregated_by_area_ita

aggregated_by_area_ita %>%
  write_csv('data_italy/aggregated_by_area_ita.csv')

# Data aggregated by age range ####

vaccine_data_italy %>%
  group_by(data, fascia_anagrafica) %>%
  summarise(across(where(is.numeric), sum)) %>%
  relocate(nuovi_vaccinati, .after = fascia_anagrafica) %>%
  group_by(fascia_anagrafica) %>%
  mutate(across(where(is.numeric), list(totale = ~ cumsum(.x)))) %>%
  rename(vaccinati_totale = nuovi_vaccinati_totale) ->
  aggregated_by_age_range_ita

aggregated_by_age_range_ita %>%
  write_csv('data_italy/aggregated_by_age_range_ita.csv')

# Totals by age range ####

aggregated_by_age_range_ita %>%
  select(1:8) %>%
  group_by(fascia_anagrafica) %>%
  summarise(across(where(is.numeric), sum)) %>%
  rename(vaccinati_totale = nuovi_vaccinati) ->
  totals_by_age_range_ita

totals_by_age_range_ita %>%
  write_csv('data_italy/totals_by_age_range_ita.csv') 

# Totals by area ####

aggregated_by_area_ita %>%
  select(1:8) %>%
  group_by(area) %>%
  summarise(across(where(is.numeric), sum)) %>%
  rename(vaccinati_totale = nuovi_vaccinati) %>%
  add_row(area = 'ITA',
          # the `.` indicates the object itself!
          vaccinati_totale = sum(.$vaccinati_totale),
          sesso_maschile = sum(.$sesso_maschile),
          sesso_femminile = sum(.$sesso_femminile),
          operatori_sanitari = sum(.$operatori_sanitari),
          personale_non_sanitario = sum(.$personale_non_sanitario),
          ospiti_rsa = sum(.$ospiti_rsa),
  ) -> ita_quasi_totals


#####

# Regional population data ####

population_data <- read_csv('data_italy/regions_population.csv')

# group_by of vaccine deliveries data
doses_delivered_ita %>%
  select(-totale_pfizer, -totale_moderna) %>%
  group_by(area) %>%
  summarise(across(where(is.numeric), sum)) %>%
  inner_join(population_data, by = 'area') %>%
  select(-NUTS2) %>%
  relocate(nome) %>%
  relocate(popolazione_2020, .after = area) %>%
  mutate(
    dosi_totale = dosi_pfizer + dosi_moderna
  ) %>%
  relocate(dosi_totale, .after = dosi_moderna) %>%
  add_row(
    nome = 'Italia',
    area = 'ITA',
    dosi_pfizer = sum(.$dosi_pfizer),
    dosi_moderna = sum(.$dosi_moderna),
    dosi_totale = sum(.$dosi_totale),
    popolazione_2020 = sum(.$popolazione_2020)
  ) -> total_doses_ita
  
ita_quasi_totals %>%
  inner_join(total_doses_ita, by = 'area') %>%
  relocate(nome, area, popolazione_2020, dosi_pfizer, dosi_moderna, dosi_totale) %>%
  mutate(
    dosi_ogni_mille = round(dosi_totale / popolazione_2020 * 1000, digits = 2),
    vaccini_ogni_mille = round(vaccinati_totale / popolazione_2020 * 1000, digits = 2),
    percent_vaccini_somministrati = round(vaccinati_totale / dosi_totale, digits = 2),
  ) %>%
  relocate(popolazione_2020, .after = area) %>%
  relocate(dosi_ogni_mille, .after = vaccinati_totale) %>%
  relocate(vaccini_ogni_mille, .after = dosi_ogni_mille) %>%
  relocate(percent_vaccini_somministrati, .after = vaccini_ogni_mille) ->
  totals_by_area_ita

totals_by_area_ita %>%
  write_csv('data_italy/totals_by_area_ita.csv')
