FROM mcr.microsoft.com/mssql/server:2019-latest
USER root
RUN apt-get -y update && apt-get install -y tzdata && ln -fs /usr/share/zoneinfo/Europe/Moscow /etc/localtime && dpkg-reconfigure -f noninteractive tzdata
CMD [ "/opt/mssql/bin/sqlservr" ]
