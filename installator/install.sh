#!/bin/bash
RED='\033[0;31m'
NC='\033[0m'
YELLOW='\033[1;33m'


serverTZ="Europe/London"


container_ver="3.1.0"
mega_install=1
change_hostname=0
serverHostname="my-cabal"




backup_file="./cabal_default_backup.tar.gz"
cabal_container="mikhailtsvetkov/hardcore-cabal-server:${container_ver}"
#cabal_container="hardcore-cabal-server:latest"

mega_install() {
	case $1 in
		Debian)
			echo -e "${RED}==> ${YELLOW}Install MEGAcmd...${NC}"
			os_ver=$(head -n1 /etc/issue | cut -f 3 -d ' ')
			sleep 1
			if [[ $os_ver -lt 11 ]]; then
				os_ver="${os_ver}.0"
			fi
			mega_inst="megacmd-${1}_${os_ver}_amd64.deb"
			wget https://mega.nz/linux/repo/${1}_${os_ver}/amd64/${mega_inst}
			apt -y install ./${mega_inst}
			;;
		CentOS)
			echo -e "${RED}==> ${YELLOW}Install MEGAcmd...${NC}"
			os_ver=$(grep -o "[0-9]" /etc/redhat-release |head -n1)
			if [[ $os_ver -lt 8 ]]; then
				yum="yum"
			else
				yum="dnf"
			fi
			sleep 1
			mega_inst="megacmd-${1}_${os_ver}.x86_64.rpm"
			wget https://mega.nz/linux/repo/${1}_${os_ver}/x86_64/${mega_inst}
			$yum -y install ./${mega_inst}
			;;
	esac
}


# Detect OS
case $(head -n1 /etc/issue | cut -f 1 -d ' ') in
    Debian)     type="Debian" ;;
    Ubuntu)     type="Ubuntu" ;;
    Amazon)     type="Amazon" ;;
    *)          type="rhel" ;;
esac

if [[ $type = "rhel" ]]; then
	type=$(head -n1 /etc/redhat-release | cut -f 1 -d ' ')
fi

case $type in
	Debian)
		os_ver=$(head -n1 /etc/issue | cut -f 3 -d ' ')

		chrony_daemon="chrony"
		cron_daemon="cron"
		profile_file="/root/.profile"
		
		# System update
		echo -e "${RED}==> ${YELLOW}System update...${NC}"
		sleep 1
		apt-get -y update

		# Install apps
		echo -e "${RED}==> ${YELLOW}Install apps...${NC}"
		sleep 1
		apt-get -y --no-install-recommends install cron curl wget tar htop mc chrony nano ftp nmap jq ca-certificates

		# Cleaning
		echo -e "${RED}==> ${YELLOW}Cleaning...${NC}"
		sleep 1
		apt-get clean

	;;
	CentOS)
		sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
		setenforce 0

		os_ver=$(grep -o "[0-9]" /etc/redhat-release |head -n1)
		if [[ $os_ver -lt 8 ]]; then
			yum="yum"
		else
			yum="dnf"
		fi

		chrony_daemon="chronyd"
		cron_daemon="crond"
		profile_file="/root/.bash_profile"
		
		# System update
		echo -e "${RED}==> ${YELLOW}System update...${NC}"
		sleep 1
		$yum -y update

		# Install apps
		echo -e "${RED}==> ${YELLOW}Install apps...${NC}"
		sleep 1
		$yum -y install curl wget tar htop mc chrony nano ftp nmap jq

		# Cleaning
		echo -e "${RED}==> ${YELLOW}Cleaning...${NC}"
		sleep 1
		$yum clean all
		
	;;
	
	Ubuntu)
		exit 0
	;;
	Amazon)
		exit 0
	;;
	*)
		exit 0
	;;
esac

# Set hostname
if [[ $change_hostname -eq 1 ]]; then
	echo -e "${RED}==> ${YELLOW}Setting hostname...${NC}"
	hostnamectl set-hostname $serverHostname
	sleep 1
fi

# Setting the time zone
echo -e "${RED}==> ${YELLOW}Setting the time zone...${NC}"
sleep 1
tz_chk=`timedatectl list-timezones | grep "$serverTZ" || echo 1`
if [[ $tz_chk == '1' ]]; then
	echo -e "\n${YELLOW}The $serverTZ time zone does not exist.${NC}"
	echo -e "${YELLOW}Please check the entered data (case sensitive).${NC}"
	echo -e "${YELLOW}Aborted.${NC}"
	exit 0
fi
timedatectl set-timezone $serverTZ

#wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
#add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-2019.list)"


# Changes to OS settings for tcp connections
echo -e "${RED}==> ${YELLOW}Changes to OS settings for tcp connections...${NC}"
sleep 1
echo "20000" > /proc/sys/net/ipv4/tcp_max_syn_backlog
echo "1" > /proc/sys/net/ipv4/tcp_synack_retries
echo "30" > /proc/sys/net/ipv4/tcp_fin_timeout
echo "5" > /proc/sys/net/ipv4/tcp_keepalive_probes
echo "15" > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo "20000" > /proc/sys/net/core/netdev_max_backlog
echo "20000" > /proc/sys/net/core/somaxconn

# Creating directories
echo -e "${RED}==> ${YELLOW}Creating directories...${NC}"
sleep 1
mkdir -p /home/_server_backups/daily
mkdir -p /home/_server_backups/hourly
mkdir -p /home/_server_backups/manual
mkdir -p /home/_server_backups/monthly


# Docker installation
echo -e "${RED}==> ${YELLOW}Docker installation...${NC}"
sleep 1
curl -fsSL https://get.docker.com/ | sh
systemctl enable docker
systemctl start docker

# Time Synchronization Start
echo -e "${RED}==> ${YELLOW}Time Synchronization Start...${NC}"
sleep 1
systemctl start $chrony_daemon
systemctl enable $chrony_daemon

# Turning on the crontab
echo -e "${RED}==> ${YELLOW}Turning on the crontab...${NC}"
sleep 1
systemctl enable $cron_daemon
systemctl restart $cron_daemon





# Unpacking scripts
echo -e "${RED}==> ${YELLOW}Unpacking scripts...${NC}"
sleep 1
TMPDIR=/tmp/install_backup
mkdir $TMPDIR
tar -C $TMPDIR -zxf $backup_file
srv_data=$TMPDIR/_server_data.tar.gz
mkdir -p /home/_server_data
tar -C "/home/_server_data" -zxf $srv_data
/bin/bash -c "rm -rf $TMPDIR"

# Setting Permissions and Creating Symbolic Links
echo -e "${RED}==> ${YELLOW}Setting Permissions and Creating Symbolic Links...${NC}"
sleep 1
ln -sf /home/_server_data/sh/channels/channels_reload.sh /usr/bin/channels_reload
ln -sf /home/_server_data/sh/channels/channels_restart.sh /usr/bin/channels_restart
ln -sf /home/_server_data/sh/channels/channels_start.sh /usr/bin/channels_start
ln -sf /home/_server_data/sh/channels/channels_status.sh /usr/bin/channels_status
ln -sf /home/_server_data/sh/channels/channels_stop.sh /usr/bin/channels_stop

chmod 0700 /usr/bin/channels_reload
chmod 0700 /usr/bin/channels_restart
chmod 0700 /usr/bin/channels_start
chmod 0700 /usr/bin/channels_status
chmod 0700 /usr/bin/channels_stop

ln -sf /home/_server_data/sh/scripts/anticrash.sh /usr/bin/anticrash
ln -sf /home/_server_data/sh/scripts/autobackup.sh /usr/bin/autobackup
ln -sf /home/_server_data/sh/scripts/cabal_log_rotation.sh /usr/bin/cabal_log_rotation
ln -sf /home/_server_data/sh/scripts/chan.sh /usr/bin/chan
ln -sf /home/_server_data/sh/scripts/copy_db.sh /usr/bin/copy_db
ln -sf /home/_server_data/sh/scripts/create_backup.sh /usr/bin/create_backup
ln -sf /home/_server_data/sh/scripts/create_backup_daily.sh /usr/bin/create_backup_daily
ln -sf /home/_server_data/sh/scripts/create_backup_hourly.sh /usr/bin/create_backup_hourly
ln -sf /home/_server_data/sh/scripts/create_backup_monthly.sh /usr/bin/create_backup_monthly
ln -sf /home/_server_data/sh/scripts/gms_proxy_reexec.sh /usr/bin/gms_proxy_reexec
ln -sf /home/_server_data/sh/scripts/gms_restart.sh /usr/bin/gms_restart
ln -sf /home/_server_data/sh/scripts/guide.sh /usr/bin/cabal_comm_guide
ln -sf /home/_server_data/sh/scripts/server_create.sh /usr/bin/server_create
ln -sf /home/_server_data/sh/scripts/server_create_nosql.sh /usr/bin/server_create_nosql
ln -sf /home/_server_data/sh/scripts/server_remove.sh /usr/bin/server_remove
ln -sf /home/_server_data/sh/scripts/services_checker.sh /usr/bin/services_checker
ln -sf /home/_server_data/sh/scripts/set_sql_access.sh /usr/bin/set_sql_access
ln -sf /home/_server_data/sh/scripts/set_war_default.sh /usr/bin/set_war_default
ln -sf /home/_server_data/sh/scripts/set_war_flag.sh /usr/bin/set_war_flag
ln -sf /home/_server_data/sh/scripts/trash_clear.sh /usr/bin/trash_clear
ln -sf /home/_server_data/sh/scripts/webserver.sh /usr/bin/webserver
ln -sf /home/_server_data/sh/scripts/world_set_ip.sh /usr/bin/world_set_ip

chmod 0700 /usr/bin/anticrash
chmod 0700 /usr/bin/autobackup
chmod 0700 /usr/bin/cabal_log_rotation
chmod 0700 /usr/bin/chan
chmod 0700 /usr/bin/copy_db
chmod 0700 /usr/bin/create_backup
chmod 0700 /usr/bin/create_backup_daily
chmod 0700 /usr/bin/create_backup_hourly
chmod 0700 /usr/bin/create_backup_monthly
chmod 0700 /usr/bin/gms_proxy_reexec
chmod 0700 /usr/bin/gms_restart
chmod 0700 /usr/bin/cabal_comm_guide
chmod 0700 /usr/bin/server_create
chmod 0700 /usr/bin/server_create_nosql
chmod 0700 /usr/bin/server_remove
chmod 0700 /usr/bin/services_checker
chmod 0700 /usr/bin/set_sql_access
chmod 0700 /usr/bin/set_war_default
chmod 0700 /usr/bin/set_war_flag
chmod 0700 /usr/bin/trash_clear
chmod 0700 /usr/bin/webserver
chmod 0700 /usr/bin/world_set_ip

ln -sf /home/_server_data/sh/server/cabal_reload.sh /usr/bin/cabal_reload
ln -sf /home/_server_data/sh/server/cabal_restart.sh /usr/bin/cabal_restart
ln -sf /home/_server_data/sh/server/cabal_start.sh /usr/bin/cabal_start
ln -sf /home/_server_data/sh/server/cabal_status.sh /usr/bin/cabal_status
ln -sf /home/_server_data/sh/server/cabal_stop.sh /usr/bin/cabal_stop

chmod 0700 /usr/bin/cabal_reload
chmod 0700 /usr/bin/cabal_restart
chmod 0700 /usr/bin/cabal_start
chmod 0700 /usr/bin/cabal_status
chmod 0700 /usr/bin/cabal_stop

ln -sf /home/_server_data/sh/services/ashop_reload.sh /usr/bin/ashop_reload
ln -sf /home/_server_data/sh/services/ashop_restart.sh /usr/bin/ashop_restart
ln -sf /home/_server_data/sh/services/ashop_start.sh /usr/bin/ashop_start
ln -sf /home/_server_data/sh/services/ashop_status.sh /usr/bin/ashop_status
ln -sf /home/_server_data/sh/services/ashop_stop.sh /usr/bin/ashop_stop
ln -sf /home/_server_data/sh/services/eventmgr_reload.sh /usr/bin/eventmgr_reload
ln -sf /home/_server_data/sh/services/eventmgr_restart.sh /usr/bin/eventmgr_restart
ln -sf /home/_server_data/sh/services/eventmgr_start.sh /usr/bin/eventmgr_start
ln -sf /home/_server_data/sh/services/eventmgr_status.sh /usr/bin/eventmgr_status
ln -sf /home/_server_data/sh/services/eventmgr_stop.sh /usr/bin/eventmgr_stop
ln -sf /home/_server_data/sh/services/login_reload.sh /usr/bin/login_reload
ln -sf /home/_server_data/sh/services/login_restart.sh /usr/bin/login_restart
ln -sf /home/_server_data/sh/services/login_start.sh /usr/bin/login_start
ln -sf /home/_server_data/sh/services/login_status.sh /usr/bin/login_status
ln -sf /home/_server_data/sh/services/login_stop.sh /usr/bin/login_stop

chmod 0700 /usr/bin/ashop_reload
chmod 0700 /usr/bin/ashop_restart
chmod 0700 /usr/bin/ashop_start
chmod 0700 /usr/bin/ashop_status
chmod 0700 /usr/bin/ashop_stop
chmod 0700 /usr/bin/eventmgr_reload
chmod 0700 /usr/bin/eventmgr_restart
chmod 0700 /usr/bin/eventmgr_start
chmod 0700 /usr/bin/eventmgr_status
chmod 0700 /usr/bin/eventmgr_stop
chmod 0700 /usr/bin/login_reload
chmod 0700 /usr/bin/login_restart
chmod 0700 /usr/bin/login_start
chmod 0700 /usr/bin/login_status
chmod 0700 /usr/bin/login_stop

ln -sf /home/_server_data/sh/tech_channel/tech_reload.sh /usr/bin/tech_reload
ln -sf /home/_server_data/sh/tech_channel/tech_restart.sh /usr/bin/tech_restart
ln -sf /home/_server_data/sh/tech_channel/tech_start.sh /usr/bin/tech_start
ln -sf /home/_server_data/sh/tech_channel/tech_status.sh /usr/bin/tech_status
ln -sf /home/_server_data/sh/tech_channel/tech_stop.sh /usr/bin/tech_stop

chmod 0700 /usr/bin/tech_reload
chmod 0700 /usr/bin/tech_restart
chmod 0700 /usr/bin/tech_start
chmod 0700 /usr/bin/tech_status
chmod 0700 /usr/bin/tech_stop

ln -sf /home/_server_data/sh/war_channels/war_crond.sh /usr/bin/war_crond
ln -sf /home/_server_data/sh/war_channels/war_reload.sh /usr/bin/war_reload
ln -sf /home/_server_data/sh/war_channels/war_restart.sh /usr/bin/war_restart
ln -sf /home/_server_data/sh/war_channels/war_start.sh /usr/bin/war_start
ln -sf /home/_server_data/sh/war_channels/war_status.sh /usr/bin/war_status
ln -sf /home/_server_data/sh/war_channels/war_stop.sh /usr/bin/war_stop

chmod 0700 /usr/bin/war_crond
chmod 0700 /usr/bin/war_reload
chmod 0700 /usr/bin/war_restart
chmod 0700 /usr/bin/war_start
chmod 0700 /usr/bin/war_status
chmod 0700 /usr/bin/war_stop

ln -sf /home/_server_data/sql/backup_dbs.sh /usr/bin/backup_dbs
ln -sf /home/_server_data/sql/check_db_log.sh /usr/bin/check_db_log
ln -sf /home/_server_data/sql/create_dbs.sh /usr/bin/create_dbs
ln -sf /home/_server_data/sql/reset_online.sh /usr/bin/reset_online
ln -sf /home/_server_data/sql/restore_dbs.sh /usr/bin/restore_dbs
ln -sf /home/_server_data/sql/set_flag.sh /usr/bin/set_flag
ln -sf /home/_server_data/sql/shrink_dbs.sh /usr/bin/shrink_dbs
ln -sf /home/_server_data/sql/cabal_db.sh /usr/bin/cabal_db

chmod 0700 /usr/bin/backup_dbs
chmod 0700 /usr/bin/check_db_log
chmod 0700 /usr/bin/create_dbs
chmod 0700 /usr/bin/reset_online
chmod 0700 /usr/bin/restore_dbs
chmod 0700 /usr/bin/set_flag
chmod 0700 /usr/bin/shrink_dbs
chmod 0700 /usr/bin/cabal_db

chmod 0700 /home/_server_data/sh/container_scripts/init.sh
chmod 0700 /home/_server_data/sh/container_scripts/proxy.py
chmod 0700 /home/_server_data/sh/container_scripts/services_checker.sh
chmod 0700 /home/_server_data/sh/container_scripts/status.sh

echo "/usr/bin/cabal_comm_guide">>$profile_file

# # Docker login
# echo -e "${RED}==> ${YELLOW}Docker login...${NC}"
# sleep 1
# chkDockerAuth=''
# while [[ $chkDockerAuth = '' ]]
# do
# 	docker login
# 	chkDockerAuth=`cat /root/.docker/config.json | grep '"auth": "*"'`
# done

# Pulling Cabal container
echo -e "${RED}==> ${YELLOW}Pulling Cabal container...${NC}"
sleep 1
docker pull $cabal_container
# docker logout

# Pulling MSSQL container
echo -e "${RED}==> ${YELLOW}Pulling MSSQL container...${NC}"
sleep 1
mkdir -p mssql
cd mssql

cat > Dockerfile <<EOF 
FROM mcr.microsoft.com/mssql/server:2019-latest
USER root
RUN apt-get -y update && \
apt-get install -y tzdata && \
ln -fs /usr/share/zoneinfo/${serverTZ} /etc/localtime && \
dpkg-reconfigure -f noninteractive tzdata
CMD [ "/opt/mssql/bin/sqlservr" ]
EOF
docker build --rm --no-cache -t mssql-tz-2019 .

cat > Dockerfile <<EOF 
FROM mcr.microsoft.com/mssql/server:2022-latest
USER root
RUN apt-get -y update && \
apt-get install -y tzdata && \
ln -fs /usr/share/zoneinfo/${serverTZ} /etc/localtime && \
dpkg-reconfigure -f noninteractive tzdata
CMD [ "/opt/mssql/bin/sqlservr" ]
EOF
docker build --rm --no-cache -t mssql-tz-2022 .

cd

# Cleaning
echo -e "${RED}==> ${YELLOW}Cleaning...${NC}"
sleep 1
/bin/bash -c "rm -rf mssql"


# Install MEGAcmd
if [[ $mega_install -eq 1 ]]; then
	mega_install $type
	/bin/bash -c "rm -f ./${mega_inst}"
fi

echo -e "${RED}==> ${YELLOW}Installation completed.${NC}"










