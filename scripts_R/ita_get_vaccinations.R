library(dplyr)

# load data ####

url_data_ita <-
  'https://raw.githubusercontent.com/italia/covid19-opendata-vaccini/master/dati/somministrazioni-vaccini-latest.csv'

readr::read_csv(url_data_ita) %>%
  # transform as factors
  mutate(across(c(area, fascia_anagrafica), as.factor)) %>%
  # remove 'categoria' from several column names
  rename_with( ~ stringr::str_remove(.x, 'categoria_')) %>%
  # shorten some other variable names
  rename(
    operatori_sanitari = operatori_sanitari_sociosanitari,
    data = data_somministrazione
  ) %>%
  # create a new column with total vaccinations
  mutate(nuovi_vaccinati = sesso_maschile + sesso_femminile) %>%
  # reorder columns
  relocate(nuovi_vaccinati, .after = 'fascia_anagrafica') ->
  vaccinations_ita

# deal with implicitly missing values ####

vaccinations_ita %<>%
  full_join(vaccinations_ita %>% tidyr::expand(data, area, fornitore, fascia_anagrafica),
            by = c('data', 'area', 'fornitore', 'fascia_anagrafica')) %>%
  # sort data
  arrange(area, data) %>%
  # replace NAs that popped up  
  mutate(across(where(is.numeric), ~ tidyr::replace_na(.x, 0)))

# aggregate data by age range ####

vaccinations_ita %>%
  group_by(data, fascia_anagrafica, fornitore) %>%
  summarise(across(where(is.numeric), sum)) %>%
  mutate(across(where(is.numeric), list(totale = ~ cumsum(.x)))) %>%
  rename(vaccinati_totale = nuovi_vaccinati_totale) -> vaccinations_by_age_ita

vaccinations_by_age_ita %>%
  # remove cumulative sums, as they will be obtained via `summarise`:
  select(1:12) %>%
  group_by(fascia_anagrafica) %>%
  summarise(across(where(is.numeric), sum)) %>%
  rename(vaccinati_totale = nuovi_vaccinati) -> totals_by_age_ita

# aggregate data by area ####

vaccinations_ita %>%
  group_by(data, area, fornitore) %>%
  summarise(across(where(is.numeric), sum)) %>%
  relocate(nuovi_vaccinati, .after = area) %>%
  mutate(across(where(is.numeric), list(totale = ~ cumsum(.x)))) %>%
  rename(vaccinati_totale = nuovi_vaccinati_totale) %>%
  arrange(area) ->
  vaccinations_by_area_ita

# load population data

readr::read_csv('data_ita/doses_by_area_ita.csv') -> doses_by_area

vaccinations_by_area_ita %>%
  select(1:12, -fornitore) %>%
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
          over80 = sum(.$over80),
          prima_dose = sum(.$prima_dose),
          seconda_dose = sum(.$seconda_dose),
  ) %>%
  inner_join(doses_by_area, by = 'area') %>%
  relocate(
    nome, NUTS2, area, popolazione_2020
  ) %>%
  mutate(
    vaccinati_ogni_mille = round(vaccinati_totale / popolazione_2020 * 1000, digits = 2),
    percent_vaccini_usati = round(vaccinati_totale / totale_dosi * 100, digits = 2)
  ) -> totals_by_area_ita

# save data ####

vaccinations_ita %>%
  readr::write_csv('data_ita/vaccinations_ita.csv')

vaccinations_by_age_ita %>%
  readr::write_csv('data_ita/vaccinations_by_age_ita.csv')
totals_by_age_ita %>%
  readr::write_csv('data_ita/totals_by_age_ita.csv')

vaccinations_by_area_ita %>%
  readr::write_csv('data_ita/vaccinations_by_area_ita.csv')
totals_by_area_ita %>%
  readr::write_csv('data_ita/totals_by_area_ita.csv')