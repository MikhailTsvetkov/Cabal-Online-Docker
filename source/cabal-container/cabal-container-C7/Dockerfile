FROM mikhailtsvetkov/hardcore-cabal-server:c7image
MAINTAINER Mikhail Tsvetkov <haseldon2020@gmail.com>

ENV container=docker

WORKDIR /
EXPOSE 30000-40000

RUN yum -y install supervisor

COPY ./etc /etc/
COPY ./usr /usr/

RUN mkdir -p /var/log/cabal/backups && \
	mkdir -p /var/log/supervisor && \
	mkdir -p /etc/cabal && \
	mkdir -p /etc/cabal_bin && \
	ln -sf /etc/cabal_scripts/odbc/odbc.ini /etc/odbc.ini && \
	ln -sf /etc/cabal_scripts/odbc/odbcinst.ini /etc/odbcinst.ini && \
	chmod 0700 /etc/cabal_scripts/init.sh && \
	chmod 0700 /etc/cabal_scripts/autorun.sh

ENTRYPOINT ["/etc/cabal_scripts/autorun.sh"]

STOPSIGNAL SIGRTMIN+3
