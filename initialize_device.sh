sudo apt-get update && sudo apt-get -y dist-upgrade
sudo apt-get install motion python-qrtools postfix
sudo pip install watchdog
sudo pip install ConfigParser
sudo crontab rm_old_files.cron
sudo rpi-update
