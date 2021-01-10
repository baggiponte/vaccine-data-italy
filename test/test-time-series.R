# Test Time Series ####

vaccinations_aggregated_data %>%
  rename(nuovi_vaccinati = totale) %>%
  group_by(data_somministrazione) %>%
  summarise(across(where(is.numeric), sum)) %>%
  mutate(
    across(where(is.numeric), ~ .x)
  ) %>%
  select(-data_somministrazione) %>%
  rename_with( ~ str_c('diff_', .x)) -> first_differences

first_differences %>%
  mutate(across(where(is.numeric), ~ (.x - lag(.x)) / .x)) %>% View()
bind_cols(first_differences) 

vaccinations_aggregated_data %>%
  rename(nuovi_vaccinati = totale) %>%
  group_by(data_somministrazione) %>%
  summarise(across(where(is.numeric), sum)) %>%
  bind_cols(first_differences) ->
  vaccinations_time_series_italy