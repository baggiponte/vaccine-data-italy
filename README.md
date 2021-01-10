# COVID-19 Vaccine Data

This is Orizzonti Politici's open data repo about covid-19 vaccinations. The project is still a work in progress and we shall frequently update (and even overhaul) the structure of the repo.

As of now, we are just manually retrieving the data by Italy's [official vaccine data repository](https://github.com/italia/covid19-opendata-vaccini).

## Structure

The directory `data` contains the data we plan to automatically update. The script we use to retrieve the data shall be `get-data.R`. The data is taken from  the official Italian repo, as we wrote above.

Other notebooks are attempts of visualising and manipulating the data.

## Credits

One can never stop praising enough [OnData](https://ondata.it/). They are at the heart of the open data activism in Italy and have contributed enormously in demanding machine-readable open data and making it available to many of us.

In particular, as of now we are using (or planning to) the following data they made available:

* Italy's shapefiles in the EU's official [NUTS format](https://github.com/ondata/nuts) (Italian only).
	* This very same data is also available on [another repository](https://github.com/ondata/covid19italia) of theirs: `covid19italia/risorse/fileGeografici` (Italian only).
* Population data comes from the same repo as the one immediately above, but the file is `covid19italia/webservices/vaccini/risorse/popolazioneRegioni`.
* [This file](https://github.com/ondata/covid19italia/blob/master/webservices/vaccini/risorse/codiciTerritoriali.csv) in the directory `covid19italia/webservices/vaccini/risorse/` by Ondata provides a reference for all regional codes and their names: vital to do any kind of join by area.
