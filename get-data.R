library(tidyverse)

# Vaccine Deliveries ####

url_vaccine_deliveries_ita <-
  'https://raw.githubusercontent.com/italia/covid19-opendata-vaccini/master/dati/consegne-vaccini-latest.csv'

vaccine_deliveries_ita <- read_csv(url_vaccine_deliveries_ita) %>%
  mutate(area = as.factor(area))

vaccine_deliveries_ita %>%
  write.csv('data/ita_vaccine_deliveries.csv', row.names = F)

# Vaccinations Data by Demography ####

url_vaccininations_demographic_data <-
  'https://raw.githubusercontent.com/italia/covid19-opendata-vaccini/master/dati/somministrazioni-vaccini-latest.csv'

vaccininations_demographic_data <- read_csv(url_vaccininations_demographic_data) %>%
  mutate(across(c(area, fascia_anagrafica), as.factor))

vaccininations_demographic_data %>%
  write.csv('data/ita_vaccinations_demographic_data.csv', row.names = F)

# Aggregate Vaccinations Data ####

vaccinations_aggregated_data <-
  vaccininations_demographic_data %>%
  group_by(data_somministrazione, area) %>%
  summarise(across(where(is.numeric), sum)) %>%
  mutate(totale = sesso_maschile + sesso_femminile) %>%
  relocate(totale, .after = area)

vaccinations_aggregated_data %>%
  write.csv('data/ita_vaccinations_aggregated_data.csv', row.names = F)

# Cumulative Data ####

vaccinations_cumulative_italy <-
  vaccinations_aggregated_data %>%
  group_by(area) %>%
  summarise(totale = sum(totale)) %>%
  add_row(area = 'ITA',
          totale = sum(vaccinations_aggregated_data$totale)) 

vaccinations_cumulative_italy %>%
  write.csv('data/ita_vaccinations_cumulative_total.csv', row.names = F)