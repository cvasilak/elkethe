# adapted from https://github.com/grafana/grafana-docker
#
# - replace 'toISOString()' with 'toLocaleString()' upon excel export
# 
FROM grafana/grafana:3.0.0-beta1
MAINTAINER Christos Vasilakis <cvasilak@gmail.com>

COPY boot.f3fb1341.js /usr/share/grafana/public/app/
COPY diversify_logo.png /usr/share/grafana/public/img/
COPY grafana_icon.png /usr/share/grafana/public/img/
COPY home.json /usr/share/grafana/public/dashboards
