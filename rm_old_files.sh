sudo rm -f /var/lib/motion/*.avi
sudo find /var/lib/motion -name *.jpg -type f -mmin +5 -delete
