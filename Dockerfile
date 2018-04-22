FROM centos:centos7
MAINTAINER team@nb.gallery

########################################################################
# Set up OS
########################################################################

EXPOSE 80 443
# WORKDIR /root
# 
# ENV CPPFLAGS=-s \
#     SHELL=/bin/bash
# 
# ENTRYPOINT ["/sbin/tini", "--"]
# CMD ["jupyter-notebook-secure"]
# 
# COPY util/* /usr/local/bin/
# COPY config/bashrc /root/.bashrc
# COPY patches /root/.patches
# COPY config/repositories /etc/apk/repositories
# COPY config/*.rsa.pub /etc/apk/keys/
# 

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER=jovyan \
    NB_UID=1000 \
    NB_GID=100 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

COPY util/fix-permissions /usr/local/bin/fix-permissions
# Create jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
USER root
RUN yum -y update \
    && yum -y install curl bzip2 sudo \
    && useradd -m -s /bin/bash -N -u $NB_UID $NB_USER \
    && mkdir -p $CONDA_DIR \
    && chown $NB_USER:$NB_GID $CONDA_DIR \
    && chmod g+w /etc/passwd /etc/group \
    && fix-permissions $HOME \
    && fix-permissions $CONDA_DIR \
    && echo "$NB_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/notebook

# miniconda installation
USER $NB_UID
RUN curl -sSL https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -bfp $CONDA_DIR \
    && rm -rf /tmp/miniconda.sh \
    && conda install -y python=3 \
    && conda update conda \
    && conda install -y \
       'jupyter' \
       'ipywidgets=6.*' \
    && conda clean --all --yes 
    

# cleanup
USER root
RUN rpm -e --nodeps curl bzip2 \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && rpm --rebuilddb 

# RUN \
#   min-apk binutils && \
#   min-apk \
#     bash \
#     bzip2 \
#     curl \
#     file \
#     gcc \
#     g++ \
#     git \
#     libressl \
#     libsodium-dev \
#     make \
#     openssh-client \
#     patch \
#     readline-dev \
#     tar \
#     tini && \
#   echo "### Install specific version of zeromq from source" && \
#   min-package https://archive.org/download/zeromq_4.0.4/zeromq-4.0.4.tar.gz && \
#   ln -s /usr/local/lib/libzmq.so.3 /usr/local/lib/libzmq.so.4 && \
#   strip --strip-unneeded --strip-debug /usr/local/bin/curve_keygen && \
#   echo "### Alpine compatibility patch for various packages" && \
#   if [ ! -f /usr/include/xlocale.h ]; then echo '#include <locale.h>' > /usr/include/xlocale.h; fi && \
#   echo "### Cleanup unneeded files" && \
#   clean-terminfo && \
#   rm /bin/bashbug && \
#   rm /usr/local/share/man/*/zmq* && \
#   rm -rf /usr/include/c++/*/java && \
#   rm -rf /usr/include/c++/*/javax && \
#   rm -rf /usr/include/c++/*/gnu/awt && \
#   rm -rf /usr/include/c++/*/gnu/classpath && \
#   rm -rf /usr/include/c++/*/gnu/gcj && \
#   rm -rf /usr/include/c++/*/gnu/java && \
#   rm -rf /usr/include/c++/*/gnu/javax && \
#   rm /usr/libexec/gcc/x86_64-alpine-linux-musl/*/cc1obj && \
#   rm /usr/bin/gcov* && \
#   rm /usr/bin/gprof && \
#   rm /usr/bin/*gcj
# 
# 
# ########################################################################
# # Install python2 kernel
# ########################################################################
# 
# RUN \
#   min-apk \
#     py2-cffi \
#     py2-cparser \
#     py2-cryptography \
#     py2-dateutil \
#     py2-decorator \
#     py2-jinja2 \
#     py2-openssl \
#     py2-pip \
#     py2-ptyprocess \
#     py2-six \
#     py2-tornado \
#     py2-zmq \
#     python2 \
#     python2-dev && \
#   pip install --no-cache-dir --upgrade setuptools pip && \
#   min-pip2 entrypoints ipykernel ipywidgets==6.0.1 pypki2 ipydeps && \
#   echo "### Cleanup unneeded files" && \
#   rm -rf /usr/lib/python2*/*/tests && \
#   rm -rf /usr/lib/python2*/ensurepip && \
#   rm -rf /usr/lib/python2*/idlelib && \
#   rm -rf /usr/share/man/* && \
#   clean-pyc-files /usr/lib/python2*
# 
# 
# ########################################################################
# # Install Python3, Jupyter, ipydeps
# ########################################################################
# 
# COPY config/jupyter /root/.jupyter/
# COPY config/ipydeps /root/.config/ipydeps/
# 
# # TODO: decorator conflicts with the c++ kernel apk, which we are
# # having trouble re-building.  Just let pip install it for now.
# #    py3-decorator \
# 
# RUN \
#   min-apk \
#     libffi-dev \
#     py3-pygments \
#     py3-cffi \
#     py3-cryptography \
#     py3-jinja2 \
#     py3-openssl \
#     py3-pexpect \
#     py3-tornado \
#     python3 \
#     python3-dev && \
#   pip3 install --no-cache-dir --upgrade setuptools pip && \
#   mkdir -p `python -m site --user-site` && \
#   min-pip3 jupyter ipywidgets==6.0.1 jupyter_dashboards pypki2 ipydeps ordo && \
#   pip3 install http://github.com/nbgallery/nbgallery-extensions/tarball/master#egg=jupyter_nbgallery && \
#   echo "### Install jupyter extensions" && \
#   jupyter nbextension enable --py --sys-prefix widgetsnbextension && \
#   jupyter serverextension enable --py jupyter_nbgallery && \
#   jupyter nbextension install --py jupyter_nbgallery && \
#   jupyter nbextension enable jupyter_nbgallery --py && \
#   jupyter dashboards quick-setup --sys-prefix && \
#   jupyter nbextension install --py ordo && \
#   jupyter nbextension enable ordo --py && \
#   echo "### Cleanup unneeded files" && \
#   rm -rf /usr/lib/python3*/*/tests && \
#   rm -rf /usr/lib/python3*/ensurepip && \
#   rm -rf /usr/lib/python3*/idlelib && \
#   rm -f /usr/lib/python3*/distutils/command/*exe && \
#   rm -rf /usr/share/man/* && \
#   clean-pyc-files /usr/lib/python3* && \
#   echo "### Apply patches" && \
#   cd / && \
#   sed -i 's/_max_upload_size_mb = [0-9][0-9]/_max_upload_size_mb = 50/g' \
#     /usr/lib/python3*/site-packages/notebook/static/tree/js/notebooklist.js \
#     /usr/lib/python3*/site-packages/notebook/static/tree/js/main.min.js \
#     /usr/lib/python3*/site-packages/notebook/static/tree/js/main.min.js.map && \
#   patch -p0 < /root/.patches/ipykernel_displayhook && \
#   patch -p0 < /root/.patches/websocket_keepalive
# 
# 
# ########################################################################
# # Add dynamic kernels
# ########################################################################
# 
# ADD kernels /usr/share/jupyter/kernels/
# ENV JAVA_HOME=/usr/lib/jvm/default-jvm \
#     SPARK_HOME=/usr/spark \
#     GOPATH=/go
# ENV PATH=$PATH:$JAVA_HOME/bin:$SPARK_HOME/bin:$GOPATH/bin:/usr/share/jupyter/kernels/installers \
#     LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$JAVA_HOME/jre/lib/amd64/server
# 
# 
# ########################################################################
# # Add simple kernels (no extra apks)
# ########################################################################
# 
# RUN \
#   min-pip3 bash_kernel jupyter_c_kernel==1.0.0 && \
#   python3 -m bash_kernel.install && \
#   clean-pyc-files /usr/lib/python3*
# 
# 
# ########################################################################
# # Metadata
# ########################################################################
# 
# ENV NBGALLERY_CLIENT_VERSION=7.0.3
# 
# LABEL gallery.nb.version=$NBGALLERY_CLIENT_VERSION \
#       gallery.nb.description="Minimal centos-based Jupyter notebook server" \
#       gallery.nb.URL="https://github.com/nbgallery"
