########################################################
#        Renku install section                         #
FROM renku/renkulab-r:4.3.1-0.25.0 as builder

ARG RENKU_VERSION=2.9.4
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

ARG DEBIAN_FRONTEND=noninteractive

# System deps
USER root
RUN apt-get update && apt-get install -y \
    sudo \
    gdebi-core \
    libcairo2-dev \
    libxt-dev \
    libcurl4-openssl-dev libssl-dev \
    r-cran-rstan \
    libxml2-dev \
    default-jdk \
  && rm -rf /var/lib/apt/lists/*

# ---- R/renv setup runs as NB_USER in /home/rstudio ----
USER ${NB_USER}
WORKDIR /home/rstudio

# Copy only what's needed for package restore (better caching)
COPY --chown=${NB_USER}:${NB_USER} .renv_install.sh renv.lock ./
COPY --chown=${NB_USER}:${NB_USER} install.R /tmp/install.R

# Install R packages (install.R may set repos, etc.)
RUN R -f /tmp/install.R

# Restore from lockfile in home (no project path shenanigans)
RUN R -e 'install.packages("renv", repos="https://cloud.r-project.org"); renv::restore(lockfile="renv.lock")'

# Clean up home to avoid nested-project confusion
RUN rm -f /home/rstudio/.Rprofile /home/rstudio/renv.lock

# ---- App code (after deps for better layer cache) ----
WORKDIR /code
USER root
COPY . /code/
RUN chown -R ${NB_USER}:${NB_USER} /code
USER ${NB_USER}

# bring Renku venv from builder
COPY --from=builder ${HOME}/.renku/venv ${HOME}/.renku/venv
