# strava-stats-viewer
iOS strava data viewer

Building:

Add file "credentials.json" to the Stravify target with the credentials for your Strava application

```
{
    "CLIENT_SECRET": "<secret>",
    "ACCESS_TOKEN": "<token>",
    "CLIENT_ID": "<client>"
}
```

Running:

Only logging in with email will work due to restrictions on oAuth. (TODO: fix oAuth login)