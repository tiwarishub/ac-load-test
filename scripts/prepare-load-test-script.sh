# install git, node and clone repo

echo "install git, node and clone repo"
sudo apt-get update
sudo apt-get install git -y

curl -sL https://deb.nodesource.com/setup_12.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh 
sudo apt-get install -y nodejs
sudo apt-get install npm -y

npm install typescript -g

cd /tmp

git clone "https://github.com/tiwarishub/ac-load-test.git"

# setup load test script
echo "setup load test script"
cd ac-load-test
npm install
tsc

# create a payload file 
echo "create a payload file"
wget https://test2.fibertelecom.it/5MB.zip
mv 5MB.zip caches_5MB.tgz

wget https://test2.fibertelecom.it/10MB.zip
mv 10MB.zip caches_10MB.tgz

wget https://test2.fibertelecom.it/5GB.zip
mv 5GB.zip caches_5000MB.tgz

wget http://speedtest.tele2.net/10GB.zip
mv 10GB.zip caches_10000MB.tgz

touch /tmp/saved_cache_result
chmod 666 /tmp/saved_cache_result
