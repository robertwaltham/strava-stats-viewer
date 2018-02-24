# strava-stats-viewer
iOS strava data viewer

**HeatMaps**

Generates a heat map of your recent activities 

<p align="center"><img width="50%" vspace="20" src="https://raw.githubusercontent.com/robertwaltham/strava-stats-viewer/master/Screenshots/heatmap_1.png"></p>

**Weather**

Downloads historical weather data from the [Environment Canada](http://climate.weather.gc.ca/historical_data/search_historic_data_e.html) and displays the conditions of the closest weather station to the activity start. (NOTE: only works for Canadian cities) 

<p align="center"><img width="50%" vspace="20" src="https://raw.githubusercontent.com/robertwaltham/strava-stats-viewer/master/Screenshots/weather_1.png"></p>

Building:

1) Add file "credentials.json" to the Stravify target with the credentials for your Strava application

```
{
    "CLIENT_SECRET": "<secret>",
    "ACCESS_TOKEN": "<token>",
    "CLIENT_ID": "<client>"
    "GMAPS_API": "<google maps api key>"
}
```

2) install cocoapods dependencies
3) install carthage dependencies 
4) open Stravify.xcworkspace and build Stravify target 

Running:

Only logging in with email will work due to restrictions on oAuth. (TODO: fix oAuth login)
