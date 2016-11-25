sudo cp easymeter.service /etc/systemd/system
sudo cp easymeter.timer /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable easymeter.timer
sudo systemctl start easymeter.timer
sudo systemctl status easymeter

