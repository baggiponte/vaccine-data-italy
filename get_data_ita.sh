# use the first zsh in the $PATH
#! /usr/bin/env zsh

echo 'Start fetching the data...'

[[ -e data_ita/population_ita_2020.csv ]] && Rscript scripts_R/ita_get_population.R

Rscript scripts_R/ita_get_doses.R

echo 'Doses data fetched ✅\n'
Rscript scripts_R/ita_get_vaccinations.R
echo 'Vaccinations data fetched ✅\n'