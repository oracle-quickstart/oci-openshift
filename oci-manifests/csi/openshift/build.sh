#!/bin/bash

OUTFILE=machineconfig-csi.yml
echo "" > $OUTFILE
for f in $(ls *.yaml); do
  echo "# $f" >> $OUTFILE
  cat $f >> $OUTFILE
  echo '' >> $OUTFILE
  echo '---' >> $OUTFILE
  echo '' >> $OUTFILE
done