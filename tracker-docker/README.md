### note on running the dockerized app

docker containers should be running one process only - therefore i didn't set the api up to run a demo_clean.py job in any way. demo_clean.py must be run separately. currently im running it as a cron job on the host as that is the simplest solution
