curl -s https://deb.mkg20001.io/key.asc | sudo apt-key add -
echo "deb https://deb.mkg20001.io/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/mkg.list
