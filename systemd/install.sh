sudo cp easymeter.service /etc/systemd/system
sudo cp easymeter.timer /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable easymeter
sudo systemctl start easymeter
sudo systemctl status easymeter

