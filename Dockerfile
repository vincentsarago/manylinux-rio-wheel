FROM quay.io/pypa/manylinux1_x86_64

# Configure SHELL
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
ENV SHELL /bin/bash

RUN yum update -y && yum install -y json-c-devel

# Install apt dependencies
RUN yum install -y gcc \
                   gcc-c++ \
                   freetype-devel \
                   yum-utils \
                   findutils \
                   openssl-devel

RUN yum -y groupinstall development

RUN yum install -y \
   libjpeg-devel \
   zlib-devel \
   libpng-devel \
   freetype-devel \
   libcurl-devel \
   sqlite-devel.x86_64 \
   wget \
   zip \
   unzip \
   tar \
   gzip \
   libtool \
   cmake \
   git

ENV APP_DIR /tmp/app
RUN mkdir $APP_DIR

ENV PROJ_VERSION 4.9.3
RUN cd $APP_DIR \
    && curl -f -L -O http://download.osgeo.org/proj/proj-$PROJ_VERSION.tar.gz \
    && tar xzf proj-$PROJ_VERSION.tar.gz \
    && cd $APP_DIR/proj-$PROJ_VERSION \
    && ./configure --prefix=$APP_DIR/local \
    && make \
    && make install \
    && make clean \
    && rm -rf $APP_DIR/proj-$PROJ_VERSION.tar.gz $APP_DIR/proj.4-$PROJ_VERSION

ENV GEOS_VERSION 3.5.0
RUN cd $APP_DIR \
    && curl -f -L -O http://download.osgeo.org/geos/geos-$GEOS_VERSION.tar.bz2 \
    && tar jxf geos-$GEOS_VERSION.tar.bz2 \
    && cd $APP_DIR/geos-$GEOS_VERSION \
    && ./configure --prefix=$APP_DIR/local \
    && make \
    && make install \
    && rm -rf $APP_DIR/geos-$GEOS_VERSION $APP_DIR/geos-$GEOS_VERSION.tar.bz2

ENV CMAKE_VERSION 2.8.10.2
RUN cd $APP_DIR \
  && curl -f -L -O http://www.cmake.org/files/v2.8/cmake-$CMAKE_VERSION.tar.gz \
  && tar -zxvf cmake-$CMAKE_VERSION.tar.gz \
  && cd $APP_DIR/cmake-$CMAKE_VERSION \
  && ./configure --prefix=$APP_DIR/local \
  && make \
  && make install \
  && rm -rf $APP_DIR/cmake-$CMAKE_VERSION.tar.gz $APP_DIR/cmake-$CMAKE_VERSION

ENV PATH $APP_DIR/local/bin:$PATH
ENV LD_LIBRARY_PATH $APP_DIR/local/lib:$LD_LIBRARY_PATH

ENV OPENJPEG_VERSION 2.2.0
RUN cd $APP_DIR \
    && curl -f -L -O https://github.com/uclouvain/openjpeg/archive/v$OPENJPEG_VERSION.tar.gz  \
    && tar -zvxf v$OPENJPEG_VERSION.tar.gz \
    && cd $APP_DIR/openjpeg-$OPENJPEG_VERSION \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX=$APP_DIR/local .. \
    && make install && make clean \
    && rm -rf $APP_DIR/openjpeg-$OPENJPEG_VERSION $APP_DIR/$OPENJPEG_VERSION.tar.gz

RUN ln -s $APP_DIR/local/include/openjpeg-2.2 $APP_DIR/local/include/openjpeg-2.1

RUN cd $APP_DIR \
    && curl -f -L -O http://curl.askapache.com/download/curl-7.51.0.tar.bz2 \
    && tar jxf curl-7.51.0.tar.bz2 \
    && cd $APP_DIR/curl-7.51.0 \
    && LIBS=-ldl ./configure -prefix=$APP_DIR/local --with-ssl=/usr/local/ssl \
    && make \
    && make install \
    && rm -rf $APP_DIR/curl-7.51.0 curl-7.51.0.tar.bz2


# Build and install GDAL (minimal support geotiff and jp2 support, https://trac.osgeo.org/gdal/wiki/BuildingOnUnixWithMinimizedDrivers#no1)
ENV GDAL_VERSION 2.2.1
RUN cd $APP_DIR \
  && wget http://download.osgeo.org/gdal/$GDAL_VERSION/gdal${GDAL_VERSION//.}.zip \
  && unzip gdal${GDAL_VERSION//.}.zip \
  && cd $APP_DIR/gdal-$GDAL_VERSION \
  && ./configure \
      --prefix=$APP_DIR/local \
      --with-static-proj4=$APP_DIR/local \
      --with-geos=$APP_DIR/local/bin/geos-config \
      --with-openjpeg=$APP_DIR/local \
      --with-jpeg \
      --with-hide-internal-symbols \
      --with-curl=$APP_DIR/local/bin/curl-config \
      --without-bsb \
      --without-cfitsio \
      --without-cryptopp \
      --without-ecw \
      --without-expat \
      --without-fme \
      --without-freexl \
      --without-gif \
      --without-gif \
      --without-gnm \
      --without-grass \
      --without-grib \
      --without-hdf4 \
      --without-hdf5 \
      --without-idb \
      --without-ingres \
      --without-jasper \
      --without-jp2mrsid \
      --without-kakadu \
      --without-libgrass \
      --without-libkml \
      --without-libtool \
      --without-mrf \
      --without-mrsid \
      --without-mysql \
      --without-netcdf \
      --without-odbc \
      --without-ogdi \
      --without-pcidsk \
      --without-pcraster \
      --without-pcre \
      --without-perl \
      --without-pg \
      --without-php \
      --without-png \
      --without-python \
      --without-qhull \
      --without-sde \
      --without-sqlite3 \
      --without-webp \
      --without-xerces \
      --without-xml2 \
    && make && make install \
    && rm -rf $APP_DIR/gdal$m{GDAL_VERSION//.}.zip $APP_DIR/gdal-$GDAL_VERSION

ENV GDAL_DATA $APP_DIR/local/lib/gdal
ENV GDAL_CONFIG $APP_DIR/local/bin/gdal-config

ENV PY36_BIN /opt/python/cp36-cp36m/bin
RUN $PY36_BIN/pip install cython wheel numpy --no-binary numpy #numpy header are needed to build rasterio from source

RUN $PY36_BIN/pip install boto3

RUN git clone https://$GithubAccessToken:x-oauth-basic@github.com/mapbox/rasterio
ENV GDAL_VERSION 2.2.1
ENV PACKAGE_DATA 1
ENV PROJ_LIB $APP_DIR/local/share/proj
RUN $PY36_BIN/pip wheel -w /tmp/wheelhouse -e rasterio --no-deps

RUN auditwheel repair /tmp/wheelhouse/rasterio-1.0a10-cp36-cp36m-linux_x86_64.whl -w /tmp/wheelhouse
