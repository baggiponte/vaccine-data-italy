# suppress all messages
zz <- file('messages.Rout', open = 'wt')
sink(zz, type = 'message')

# if the file does not exist, then run the script
if(!file.exists('data_ita/population_2020_ita.csv')){
  source(file = 'scripts_R/ita_get_population.R')
  print('Population data fetched')  
}

# update doses data
source(file = 'scripts_R/ita_get_doses.R')
print('Doses data fetched')

# update vaccine data
source(file = 'scripts_R/ita_get_vaccinations.R')
print('Vaccine data fetched')

# remove file where we diverted messages
file.remove('messages.Rout')

# restore messages
sink()