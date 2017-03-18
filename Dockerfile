FROM lsiobase/alpine:3.5
MAINTAINER sparklyballs

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# package version
ARG MEDIAINF_VER="0.7.91"

# copy patches
COPY patches/ /defaults/patches/

# install runtime packages
RUN \
NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} && \
 apk add --no-cache \
	ca-certificates \
	curl \
	fcgi \
	ffmpeg \
	geoip \
	gzip \
	logrotate \
	nginx \
	php7 \
	php7-cgi \
	php7-fpm \
	php7-json  \
	php7-mbstring \
	php7-pear \
	screen \
	tar \
	unrar \
	unzip \
	wget \
	zip && \

# install build packages
 apk add --no-cache --virtual=build-dependencies \
	autoconf \
	automake \
	binutils \
	build-base \
	cppunit-dev \
	curl-dev \
	file \
	g++ \
	gcc \
	git \
	libressl-dev \
	libtool \
	linux-headers \
	make \
	ncurses-dev \
	subversion && \

# install webui
 mkdir -p \
	/usr/share/webapps/rutorrent \
	/defaults/rutorrent-conf && \
 curl -o \
 /tmp/rutorrent.tar.gz -L \
	"https://github.com/Novik/ruTorrent/archive/master.tar.gz" && \
 tar xf \
 /tmp/rutorrent.tar.gz -C \
	/usr/share/webapps/rutorrent --strip-components=1 && \
 mv /usr/share/webapps/rutorrent/conf/* \
	/defaults/rutorrent-conf/ && \
 rm -rf \
	/defaults/rutorrent-conf/users && \

# patch snoopy.inc for rss fix
 cd /usr/share/webapps/rutorrent/php && \
 patch < /defaults/patches/snoopy.patch && \

# compile mediainfo packages
 curl -o \
 /tmp/libmediainfo.tar.gz -L \
	"http://mediaarea.net/download/binary/libmediainfo0/${MEDIAINF_VER}/MediaInfo_DLL_${MEDIAINF_VER}_GNU_FromSource.tar.gz" && \
 curl -o \
 /tmp/mediainfo.tar.gz -L \
	"http://mediaarea.net/download/binary/mediainfo/${MEDIAINF_VER}/MediaInfo_CLI_${MEDIAINF_VER}_GNU_FromSource.tar.gz" && \
 mkdir -p \
	/tmp/libmediainfo \
	/tmp/mediainfo && \
 tar xf /tmp/libmediainfo.tar.gz -C \
	/tmp/libmediainfo --strip-components=1 && \
 tar xf /tmp/mediainfo.tar.gz -C \
	/tmp/mediainfo --strip-components=1 && \

 cd /tmp/libmediainfo && \
	./SO_Compile.sh && \
 cd /tmp/libmediainfo/ZenLib/Project/GNU/Library && \
	make install && \
 cd /tmp/libmediainfo/MediaInfoLib/Project/GNU/Library && \
	make install && \
 cd /tmp/mediainfo && \
	./CLI_Compile.sh && \
 cd /tmp/mediainfo/MediaInfo/Project/GNU/CLI && \
	make install && \

# compile libtorrent and rtorrent
 cd /tmp/ && \
 svn checkout http://svn.code.sf.net/p/xmlrpc-c/code/stable xmlrpc-c && \
 git clone -b feature-bind https://github.com/rakshasa/libtorrent.git && \
 git clone -b feature-bind https://github.com/rakshasa/rtorrent.git && \
 cd /tmp/xmlrpc-c && ./configure && make -j ${NB_CORES} && make install && \
 cd /tmp/libtorrent && ./autogen.sh && ./configure && \
 make -j ${NB_CORES} && make install && \
 cd /tmp/rtorrent && ./autogen.sh && ./configure --with-xmlrpc-c && \
 make -j ${NB_CORES} && make install && \
 strip -s /usr/local/bin/rtorrent && \
 apk del ${BUILD_DEPS} && \
 deluser svn && delgroup svnusers && \

# cleanup
 apk del --purge \
	build-dependencies && \
 rm -rf \
	/etc/nginx/conf.d/default.conf \
	/tmp/* && \

# fix logrotate
 sed -i "s#/var/log/messages {}.*# #g" /etc/logrotate.conf

# add local files
COPY root/ /

# ports and volumes
EXPOSE 80
VOLUME /config /downloads
