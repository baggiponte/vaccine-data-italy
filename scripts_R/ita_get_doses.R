library(dplyr)

# load data ####

url_doses_delivered_ita <-
  'https://raw.githubusercontent.com/italia/covid19-opendata-vaccini/master/dati/consegne-vaccini-latest.csv'

readr::read_csv(url_doses_delivered_ita, col_types = readr::cols(area = readr::col_factor())) %>%
  rename(
    dosi_consegnate = numero_dosi,
    data = data_consegna
  ) %>%
  relocate(data, .after = 'area') -> doses
  
# create the grid for filling implicit NAs ####

dates <- tidyr::expand_grid(
  data = seq.Date(from = min(doses$data), to = lubridate::today(tzone = 'UTC'), by = 'day'),
  area = forcats::fct_unique(doses$area)
)

# perform the join ####

doses %>%
  # pivot to the wider format
  tidyr::pivot_wider(
    # create new features out of the levels of the following column
    names_from = fornitore,
    # values of the new features come from the following column
    values_from = dosi_consegnate
  ) %>%
  # for simplicity, let's rename
  rename(
    dosi_pfizer = 'Pfizer/BioNTech',
    dosi_moderna = 'Moderna'
  ) %>%
  full_join(dates, by = c('data', 'area')) %>%
  # reorder dates
  arrange(area, data) %>%
  mutate(
    dosi_pfizer = coalesce(dosi_pfizer, 0),
    dosi_moderna = coalesce(dosi_moderna, 0),
  ) %>%
  group_by(area) %>%
  mutate(
    totale_pfizer = cumsum(dosi_pfizer),
    totale_moderna = cumsum(dosi_moderna),
    totale_dosi = totale_moderna + totale_pfizer
  ) -> doses_delivered_ita

# aggregate by area ####

population_data <- readr::read_csv('data_ita/population_2020_ita.csv')

doses_delivered_ita %>%
  group_by(area) %>%
  summarise(
    totale_pfizer = sum(dosi_pfizer),
    totale_moderna = sum(dosi_moderna)
  ) %>%
  mutate(
    totale_dosi = totale_pfizer + totale_moderna
  ) %>%
  inner_join(population_data, by = 'area') %>%
  relocate(
    nome, NUTS2, area, popolazione_2020
  ) %>%
  add_row(
    nome = 'Italia',
    area = 'ITA',
    popolazione_2020 = sum(.$popolazione_2020),
    totale_pfizer = sum(.$totale_pfizer),
    totale_moderna = sum(.$totale_moderna),
    totale_dosi = sum(.$totale_dosi),
  ) %>%
  mutate(
    dosi_ogni_mille = round(totale_dosi / popolazione_2020 * 1000, digits = 2)
  ) -> doses_by_area_ita

# aggregate by date ####

doses_delivered_ita %>%
  group_by(data) %>%
  summarise(
    totale_pfizer = sum(dosi_pfizer),
    totale_moderna = sum(dosi_moderna),
  ) %>%
  mutate(
    totale_dosi_consegnate = totale_pfizer + totale_moderna,
    totale_dosi = cumsum(totale_dosi_consegnate)
  ) -> doses_by_date_ita

# save the data #### 

doses_delivered_ita %>%
  readr::write_csv('data_ita/doses_delivered_ita.csv')

doses_by_area_ita %>%
  readr::write_csv('data_ita/doses_by_area_ita.csv')

doses_by_date_ita %>%
  readr::write_csv('data_ita/doses_by_date_ita.csv')