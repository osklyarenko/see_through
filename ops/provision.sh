echo "------ Provision package lists ------"

sudo apt-get -y update

echo "------ Install ruby ------"

curl -L https://get.rvm.io | bash -s stable --ruby=2.2.1-dev

sudo apt-get install -y ruby-all-dev

echo "------ Install gems ------"

sudo gem install activerecord
sudo gem install octokit
sudo apt-get install libsqlite3-dev
sudo apt-get install sqlite3
sudo gem install sqlite3
sudo gem install json
sudo gem install sinatra
sudo gem install haml
sudo gem install time_difference

echo "------ Install git ------"

sudo apt-get -y install git

echo "------ Add cron jobs ------   "

echo "0 * * * * /home/ubuntu/box/see_through/daily_report.sh
*/15 * * * * /home/ubuntu/box/see_through/conflict_checker.sh" | crontab -