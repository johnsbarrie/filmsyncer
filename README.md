network drives -> mount all network drives disks

backup network -> local 'In Progress' (temp)
backup network -> local 'Validation' (temp)
backup network -> local 'Archive' (temp)

backup local -> externalDisk 'In Progress' (permanent)
backup local -> externalDisk 'Validation' (permanent)
backup local -> externalDisk 'Archive' (permanent)

 ln -s /etc/nginx/sites-available/hyde.kool-animation /etc/nginx/sites-enabled/hyde.kool-animation
  sudo ln -s /etc/nginx/sites-available/hyde.kool-animation /etc/nginx/sites-enabled/hyde.kool-animation
  
  sudo service nginx restart
  forever restart app.js