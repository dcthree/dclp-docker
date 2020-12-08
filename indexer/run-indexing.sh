#!/bin/bash

LOCK_PATH="/srv/data/papyri.info/lockfiles/indexer"
LOCK_FILE="${LOCK_PATH}/indexing_done.lock"

until [ -e "/srv/data/papyri.info/lockfiles/navigator/mapping_done.lock" ]; do
  sleep 1
done
echo "navigator mapping_done lock detected"

if [ ! -d "/srv/data/papyri.info/git/navigator" ]; then
  echo "/srv/data/papyri.info/git/navigator not found! This directory should be copied in by the navigator docker container"
  exit 1
fi

if [ ! -d "/srv/data/papyri.info/git/navigator/epidoc-xslt" ]; then
  echo "Copying epidoc-xslt"
  mkdir -p /srv/data/papyri.info/git/navigator && cp -Rv /epidoc-xslt /srv/data/papyri.info/git/navigator/epidoc-xslt
fi

if [ ! -e "${LOCK_FILE}" ]; then
  mkdir -p ${LOCK_PATH}
  sed -i -e 's/localhost:8090/fuseki:8090/' /srv/data/papyri.info/git/navigator/pn-indexer/docs/uberdoc.html
  sed -i -e 's/localhost:8090/fuseki:8090/' /srv/data/papyri.info/git/navigator/pn-indexer/src/info/papyri/indexer.clj
  sed -i -e 's/localhost:8983/solr:8983/' /srv/data/papyri.info/git/navigator/pn-indexer/src/info/papyri/indexer.clj
  sed -i -e 's/Xmx1G/Xmx8G/' /srv/data/papyri.info/git/navigator/pn-indexer/project.clj
  cd /srv/data/papyri.info/git/navigator/pn-indexer && /root/wait-for-it.sh -t 9999 solr:8983 -- sleep 30 && lein run && touch $LOCK_FILE
  echo "indexing done"
fi
