#! /bin/bash

cd /home/ubuntu/app
export TF_VAR_DB_HOST=${db_host}
pm2 start app.js
