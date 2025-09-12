########################################################
#        Renku install section                         #

FROM renku/renkulab-r:4.3.1-0.25.0 as builder

ARG RENKU_VERSION=2.9.4

# Install renku from pypi or from github if a dev version
RUN if [ -n "$RENKU_VERSION" ] ; then \
        source .renku/venv/bin/activate ; \
        currentversion=$(renku --version) ; \
        if [ "$RENKU_VERSION" != "$currentversion" ] ; then \
            pip uninstall renku -y ; \
            gitversion=$(echo "$RENKU_VERSION" | sed -n "s/^[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+\(rc[[:digit:]]\+\)*\(\.dev[[:digit:]]\+\)*\(+g\([a-f0-9]\+\)\)*\(+dirty\)*$/\4/p") ; \
            if [ -n "$gitversion" ] ; then \
                pip install --no-cache-dir --force "git+https://github.com/SwissDataScienceCenter/renku-python.git@$gitversion" ;\
            else \
                pip install --no-cache-dir --force renku==${RENKU_VERSION} ;\
            fi \
        fi \
    fi

#             End Renku install section                #
########################################################
FROM renku/renkulab-r:4.3.1-0.25.0

WORKDIR /code

ARG DEBIAN_FRONTEND=noninteractive

USER root

RUN apt-get update && apt-get install -y \
    sudo \
    gdebi-core \
    libcairo2-dev \
    libxt-dev \
    libcurl4-openssl-dev libssl-dev \
    r-cran-rstan \
    libxml2-dev \
    default-jdk

# install the R dependencies
## make the renv install script and renv.lock file
## available in the working dir and run the install
COPY .renv_install.sh .
COPY renv.lock .
RUN bash .renv_install.sh
## ensure renv lock is in the project directory
COPY renv.lock /home/rstudio/renv.lock
COPY install.R /tmp/
RUN R -f /tmp/install.R
# Additionally run renv::restore here
RUN R -e "renv::restore()"

## Clean up the /home/rstudio directory to avoid confusion in nested R projects
RUN rm /home/rstudio/.Rprofile; rm /home/rstudio/renv.lock

COPY . /code/

COPY --from=builder ${HOME}/.renku/venv ${HOME}/.renku/venv
