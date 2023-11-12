#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

case $1 in
	install)
		apt-get -y update
		apt-get -y install apache2
		apt-get clean
		defaultConf='/etc/apache2/sites-available/000-default.conf'
		sed -i '/<\/VirtualHost>/ i\\t<Directory \/var\/www>' $defaultConf
		sed -i '/<\/VirtualHost>/ i\\tOptions Indexes FollowSymLinks MultiViews' $defaultConf
		sed -i '/<\/VirtualHost>/ i\\tAllowOverride All' $defaultConf
		sed -i '/<\/VirtualHost>/ i\\tRequire all granted' $defaultConf
		sed -i '/<\/VirtualHost>/ i\\t</Directory>' $defaultConf
		echo 'ServerName localhost' > /etc/apache2/conf-available/servername.conf
		a2enconf servername
		systemctl restart apache2
		#echo 'Require all denied' > /var/www/html/.htaccess
		echo 'Access denied' > /var/www/html/index.html
		systemctl status apache2
		echo -e "\n${GREEN}Webserver installed\n${NC}"
		;;
	uninstall)
		if [[ ! -d /etc/apache2 ]]; then
			echo -e "\n${YELLOW}Apache2 is not installed.${NC}"
			echo -e "${YELLOW}Use ${PINK}webserver install${YELLOW} to install this.\n${NC}"
			exit 0
		fi
		systemctl stop apache2
		apt-get purge apache2* -y
		apt-get autoremove -y
		/bin/bash -c "rm -rf /etc/apache2"
		/bin/bash -c "rm -rf /var/www/html"
		;;
	add)
		if [[ ! -d /etc/apache2 ]]; then
			echo -e "\n${YELLOW}Apache2 is not installed.${NC}"
			echo -e "${YELLOW}Use ${PINK}webserver install${YELLOW} to install this.\n${NC}"
			exit 0
		fi
		if [[ $2 == '' ]]; then
			echo -e "\n${YELLOW}Specify a domain name.${NC}"
			echo -e "${YELLOW}For example, ${PINK}webserver add testdomain.com\n${NC}"
			exit 0
		fi
		if [[ -f /etc/apache2/sites-available/$2.conf ]]; then
			echo -e "\n${YELLOW}The domain already exists.${NC}"
			echo -e "${YELLOW}Aborted.\n${NC}"
			exit 0
		fi
		mkdir -p /home/web_domains/$2/html
		mkdir -p /home/web_domains/$2/logs
		chmod -R 755 /home/web_domains/$2
		cat << EOF > /home/web_domains/$2/html/index.html
<html>
<head>
<title>Welcome to the page $2!</title>
</head>
<body>
<h1>You got Lucky! Your $2 server block is up!</h1>
</body>
</html>
EOF
		cat << EOF > /etc/apache2/sites-available/$2.conf
<VirtualHost *:80>
	ServerAdmin admin@$2
	ServerName $2
	ServerAlias www.$2
	DocumentRoot /home/web_domains/$2/html
	ErrorLog /home/web_domains/$2/logs/error.log
	CustomLog /home/web_domains/$2/logs/access.log combined
	<Directory /home/web_domains/$2/html>
		Options FollowSymLinks
		AllowOverride all
		Require all granted
	</Directory>
</VirtualHost>
EOF
		a2ensite $2.conf > /dev/null
		#a2dissite 000-default.conf > /dev/null
		#
		apache2ctl configtest
		
		if [[ $? -eq 0 ]]; then
			systemctl restart apache2
			echo -e "\n${GREEN}Domain $2 added successfully.${NC}"
			echo -e "${GREEN}Domain working directory:${NC}"
			echo -e "${PINK}/home/web_domains/$2/html\n${NC}"
		else
			/usr/bin/webserver remove $2 1>/dev/null 2>/dev/null
			echo -e "\n${YELLOW}Failed to add domain.${NC}"
			echo -e "${YELLOW}See the post above for details.${NC}"
			echo -e "${YELLOW}Aborted.\n${NC}"
		fi
		;;
	remove)
		if [[ ! -d /etc/apache2 ]]; then
			echo -e "\n${YELLOW}Apache2 is not installed.${NC}"
			echo -e "${YELLOW}Use ${PINK}webserver install${YELLOW} to install this.\n${NC}"
			exit 0
		fi
		a2dissite $2.conf > /dev/null
		/bin/bash -c "rm -rf /home/web_domains/$2"
		/bin/bash -c "rm -rf /etc/apache2/sites-available/$2.conf"
		systemctl restart apache2
		apache2ctl configtest
		;;
	start)
		if [[ ! -d /etc/apache2 ]]; then
			echo -e "\n${YELLOW}Apache2 is not installed.${NC}"
			echo -e "${YELLOW}Use ${PINK}webserver install${YELLOW} to install this.\n${NC}"
			exit 0
		fi
		systemctl start apache2
		;;
	stop)
		if [[ ! -d /etc/apache2 ]]; then
			echo -e "\n${YELLOW}Apache2 is not installed.${NC}"
			echo -e "${YELLOW}Use ${PINK}webserver install${YELLOW} to install this.\n${NC}"
			exit 0
		fi
		systemctl stop apache2
		;;
	restart)
		if [[ ! -d /etc/apache2 ]]; then
			echo -e "\n${YELLOW}Apache2 is not installed.${NC}"
			echo -e "${YELLOW}Use ${PINK}webserver install${YELLOW} to install this.\n${NC}"
			exit 0
		fi
		systemctl restart apache2
		;;
	reload)
		if [[ ! -d /etc/apache2 ]]; then
			echo -e "\n${YELLOW}Apache2 is not installed.${NC}"
			echo -e "${YELLOW}Use ${PINK}webserver install${YELLOW} to install this.\n${NC}"
			exit 0
		fi
		systemctl reload apache2
		;;
	status)
		if [[ ! -d /etc/apache2 ]]; then
			echo -e "\n${YELLOW}Apache2 is not installed.${NC}"
			echo -e "${YELLOW}Use ${PINK}webserver install${YELLOW} to install this.\n${NC}"
			exit 0
		fi
		systemctl status apache2
		;;
	enable)
		if [[ ! -d /etc/apache2 ]]; then
			echo -e "\n${YELLOW}Apache2 is not installed.${NC}"
			echo -e "${YELLOW}Use ${PINK}webserver install${YELLOW} to install this.\n${NC}"
			exit 0
		fi
		systemctl enable apache2
		;;
	disable)
		if [[ ! -d /etc/apache2 ]]; then
			echo -e "\n${YELLOW}Apache2 is not installed.${NC}"
			echo -e "${YELLOW}Use ${PINK}webserver install${YELLOW} to install this.\n${NC}"
			exit 0
		fi
		systemctl disable apache2
		;;
esac
