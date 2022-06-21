#/bin/sh
# USAGE: bash laravel-deploy.sh folderName

echo "██████ START THE BUILD"
cd /var/www/html/$1
echo "Pulling changes from git repo .."
git pull
echo "Installing composer .."
composer install --no-interaction --no-dev
chown www-data:www-data -R /var/www/html/$1

echo "██████ DEPLOY"
php artisan migrate --force
php artisan optimize:clear
php artisan cache:clear
#php artisan config:clear
#php artisan config:cache
