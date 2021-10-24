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

git clone "https://github.com/aparna-ravindra/ac-load-test.git"

# setup load test script
echo "setup load test script"
cd ac-load-test
npm install
tsc

# create a payload file 
echo "create a payload file"
wget -m ftp://speedtest:speedtest@ftp.otenet.gr/test5Gb-a.db
mv ftp.otenet.gr/test5Gb-a.db ./caches.tgz



