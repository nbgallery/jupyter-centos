FROM centos:latest as builder

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

# copy in necessary files
COPY util/* $CONDA_DIR/bin/
COPY config/jupyter /tmp/.jupyter/
COPY config/ipydeps /tmp/.config/ipydeps/
COPY kernels/installers/install_c_kernel $CONDA_DIR/share/jupyter/kernels/installers/

# initial installs and cleanup
USER root
RUN yum -y update \
    && yum -y install curl bzip2 sudo \
    # create jovyan user with UID=1000 and in the 'users' group
    # and make sure these dirs are writable by the `users` group.
    && echo "### Creation of jovyan user account" \
    && useradd -m -s /bin/bash -N -u $NB_UID $NB_USER \
    && mkdir -p $CONDA_DIR \
    && mv /tmp/.jupyter $HOME/.jupyter \
    && mv /tmp/.config $HOME/.config \
    && chown -R $NB_USER:$NB_GID $CONDA_DIR \
    && chown -R $NB_USER:$NB_GID $HOME \
    && fix-permissions $HOME \
    && fix-permissions $CONDA_DIR \
    && echo "$NB_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/notebook

# miniconda installation
USER $NB_UID
RUN curl -sSL https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && echo "### Installing miniconda" \
    && bash /tmp/miniconda.sh -bfp $CONDA_DIR \
    && rm -rf /tmp/miniconda.sh 
# core jupyter installation using conda
RUN conda update conda \
    && echo "### Installs using conda" \
    && conda install -y \
        python=3 \
        notebook=5.2 \
        ipywidgets=6.* \
		make \
		gcc \
		gxx_linux-64 \
		ruby 	

# additional desired packages using pip
RUN echo "### Installs using pip" \
    && pip --no-cache-dir install \
        bash_kernel \
        jupyter_c_kernel==1.0.0 \
        jupyter_dashboards \
        ordo \
        pypki2 \
        ipydeps \
        jupyter_nbextensions_configurator \
        http://github.com/nbgallery/nbgallery-extensions/tarball/master#egg=jupyter_nbgallery
# Add simple kernels (no extra apks)
RUN echo "### Activate simple kernels" \
    && python -m bash_kernel.install --prefix=$CONDA_DIR \
    && python $CONDA_DIR/share/jupyter/kernels/installers/install_c_kernel --prefix=$CONDA_DIR \
    # Other pip package installation and enabling
    && echo "### Activate jupyter extensions" \
    && jupyter nbextensions_configurator enable --prefix=$CONDA_DIR \
    && jupyter nbextension enable --py --sys-prefix widgetsnbextension \
    && jupyter serverextension enable --py jupyter_nbgallery \
    && jupyter nbextension install --prefix=$CONDA_DIR --py jupyter_nbgallery \
    && jupyter nbextension enable jupyter_nbgallery --py \
    && jupyter nbextension install --prefix=$CONDA_DIR --py ordo \
    && jupyter nbextension enable ordo --py 

# Patches? Do we still need them? They go here 
RUN echo "### Patching" \
    && sed -i 's/_max_upload_size_mb = [0-9][0-9]/_max_upload_size_mb = 50/g' \
         $CONDA_DIR/lib/python3*/site-packages/notebook/static/tree/js/notebooklist.js \
         $CONDA_DIR/lib/python3*/site-packages/notebook/static/tree/js/main.min.js \
         $CONDA_DIR/lib/python3*/site-packages/notebook/static/tree/js/main.min.js.map 

# another last cleanup
RUN echo "### Final stage-one cleanup" \
    && conda clean --all --yes \ 
    && clean-pyc-files $CONDA_DIR/ \
    && find $CONDA_DIR/ -regex ".*/tests?" -type d -print0 | xargs -r0 -- rm -r ; exit 0

COPY kernels/R_small $CONDA_DIR/share/jupyter/kernels/R_small
COPY kernels/R_big $CONDA_DIR/share/jupyter/kernels/R_big
COPY kernels/installers/dynamic* $CONDA_DIR/share/jupyter/kernels/installers/

########################################
# second layer
########################################
FROM centos:latest
MAINTAINER team@nb.gallery
 
# Add Tini
ENV TINI_VERSION=v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini

# resetup ENV variables
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

USER root
# second layer RUN
# RUN yum -y update \
RUN yum -y install sudo \
    && echo "### second layer cleanup" \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && rpm --rebuilddb \
    && rm /bin/bashbug \
    && rm -rf /usr/local/share/man/* \
    && rm /usr/bin/gprof  \
    && find /usr/share/terminfo -type f -delete \
    && chmod +x /tini \
    && echo "$NB_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/notebook \
    && echo "### Creation of jovyan user account" \
    && useradd -s /bin/bash -N -u $NB_UID $NB_USER \
    && rm -rf $HOME 
#    && echo "### Moving home directory into place" \
#    && mv $CONDA_DIR/$NB_USER /home/ 

COPY --chown=1000:100 --from=builder $CONDA_DIR $CONDA_DIR
COPY --chown=1000:100 --from=builder $HOME $HOME

EXPOSE 80 443
ENTRYPOINT ["/tini", "--"]
USER $NB_UID
WORKDIR $HOME
# start notebook
CMD ["jupyter-notebook-insecure"]
