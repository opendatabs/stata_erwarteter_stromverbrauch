FROM rocker/rstudio:4.3.3
WORKDIR /code

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    sudo \
    gdebi-core \
    libcairo2-dev \
    libxt-dev \
    libcurl4-openssl-dev libssl-dev \
    r-cran-rstan \
    libxml2-dev \
    default-jdk

RUN R -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))"

COPY . /code/

ENV RENV_PATHS_LIBRARY=/opt/renv/library

RUN R -e "renv::restore()"

CMD ["Rscript", "Stromverbrauch_OGD.R"]

