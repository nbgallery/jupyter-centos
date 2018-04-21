# jupyter-centos

This is a minimal [Centos](https://www.centos.org/)-based [docker](https://www.docker.com/) image for running the Jupyter notebook server.  It is an overly-optimistic redesign of the original [Alpine-based version](https://hub.docker.com/r/nbgallery/jupyter-alpine/) used by the nbgallery team.  For more information about the team and project overall, please check out [this post](https://nbgallery.github.io/Jupyter-Docker.html) on our [github.io](https://nbgallery.github.io) site.

## Goals

* base the image off of Centos7
* replicate the core functionality of the Alpine-based version:
    - launch a secure Jupyter notebook on startup
    - support Py3 kernel out of the box
    - include the nbgallery additions to Jupyter
    - allow for dynamic kernel installation for other languages
* attempt to keep the size low (< 1G)
    - This will not be as small as the Alpine version
* incorporate conda for package management
* launch into a user account rather than root
    - unclear if this is necessary, but we'll see

## Reasons

Alpine is small. That's about its only benefit. If that's the main consideration, then use it. Through usage, however, the limitations of using Alpine as the base system for a complex and dynamic environment meant to support flexible data-science efforts have started to show up. There were a lot of tweaks that needed to be done to allow the core systems to work correctly, and in order to manage the post-container, on-demand installation of python packages, a home-grown package management system (ipydeps) was created. It tries to leverage Alpine packages (apks) when it can and pip packages when it can't, but regular problems are encountered by pip packages that need libraries Alpine doesn't have, and the challenge of maintaining an independent package management system has led to questions about whether the trade-offs that have been made just for size are worth it. 

This branch is an exploration of an alternative. It may not work, but should at least be attempted to determine if a small enough non-Alpine-based image can be created in a way to make the other pieces easier and allow us to leverage a python package system with a larger community.


## Carry-over notes

To build the image from source, clone or download the repo.  Then build with something like this:

```
docker build -t nbgallery/jupyter-centos:<version> <source-directory>
```

## Running the image

You will usually launch a container something like this:

```
docker run --rm -p 443:443 nbgallery/jupyter-centos
```

The default entrypoint is [jupyter-notebook-secure](util/jupyter-notebook-secure), which will generate a self-signed certificate and then launch the jupyter notebook server under HTTPS with an automatically-generated [authentication token](http://jupyter-notebook.readthedocs.io/en/stable/security.html).
