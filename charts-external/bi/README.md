# Midburn Business Intelligence

This chart is meant to provide a central point for getting business intelligence from multiple DB and other sources

## Metabase

[Metabase](https://www.metabase.com/) is a simple BI tool which allows to ask questions and get answers from multiple databases

It has a nice UI which allows to ask questions in a friendly way or to write SQL queries.

The Midburn metabase instance will combine data from 3 data sources:

* spark DB (mysql)
* volunteers DB (mongo)
* Profiles (Drupal / mysql)

Requires authentication, available on production at https://production.midburn.org/metabase
