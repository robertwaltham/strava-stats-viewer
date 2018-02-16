# strava-stats-viewer
iOS strava data viewer

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
