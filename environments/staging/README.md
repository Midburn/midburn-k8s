# Midburn staging environment

## Main entrypoints

* Spark - https://spark.staging.midburn.org/
  * Deployed on push to `master` branch of https://github.com/Midburn/spark
* Adminer - https://staging.midburn.org/adminer
* Volunteers - https://volunteers.staging.midburn.org/
  * Deployed on push to `develop` branch of https://github.com/Midburn/Volunteers
* Volunteers DB UI - https://staging.midburn.org/volunteers/mongoexpress
* Profiles - https://profiles.staging.midburn.org/
  * DEployed on push to `master` branch of https://github.com/orihoch/midburn-profiles-drupal
* Profiles Adminer - https://staging.midburn.org/profiles/adminer

## Secrets

Secrets are created using the `environments/staging/secrets.sh` script (Which is not committeed to git)
