MKGMAP="mkgmap-r4899" # adjust to latest version (see www.mkgmap.org.uk)
SPLITTER="splitter-r651"

REGION="australia-oceania"
COUNTRY="new-zealand"

if [ ! -d tools ]; then
  mkdir tools
fi
pushd tools > /dev/null

if [ ! -d "${MKGMAP}" ]; then
    wget "http://www.mkgmap.org.uk/download/${MKGMAP}.zip"
    unzip "${MKGMAP}.zip"
fi
MKGMAPJAR="$(pwd)/${MKGMAP}/mkgmap.jar"

if [ ! -d "${SPLITTER}" ]; then
    wget "http://www.mkgmap.org.uk/download/${SPLITTER}.zip"
    unzip "${SPLITTER}.zip"
fi
SPLITTERJAR="$(pwd)/${SPLITTER}/splitter.jar"

popd > /dev/null

if stat --printf='' bounds/bounds_*.bnd 2> /dev/null; then
    echo "bounds already downloaded"
else
    echo "downloading bounds"
    rm -f bounds.zip  # just in case
    wget "http://osm.thkukuk.de/data/bounds-latest.zip"
    unzip "bounds-latest.zip" -d bounds
fi

BOUNDS="$(pwd)/bounds"

if stat --printf='' sea/sea_*.pbf 2> /dev/null; then
    echo "sea already downloaded"
else
    echo "downloading sea"
    rm -f sea.zip  # just in case
    wget "http://osm.thkukuk.de/data/sea-latest.zip"
    unzip "sea-latest.zip" -d sea
fi

SEA="$(pwd)/sea"

if [ ! -d data ]; then
  mkdir data
fi
pushd data > /dev/null

set -v
FILE=$COUNTRY-latest.osm.pbf
wget "https://download.geofabrik.de/$REGION/$FILE" -N

rm -f 6324*.pbf
#java -jar $SPLITTERJAR --precomp-sea=$SEA "$(pwd)/latest.osm.pbf"
#DATA="$(pwd)/6324*.pbf"
java -jar $SPLITTERJAR --precomp-sea=$SEA --wanted-admin-level=8 --status-freq=0 --output=o5m "$(pwd)/$FILE"
DATA="$(pwd)/6324*.o5m"

popd > /dev/null

# Contour map
#OPTIONS="$(pwd)/opentopomap_options"
#STYLEFILE="$(pwd)/style/opentopomap"
#OUTPUT="output/otm-$COUNTRY-contour.img"
#TYP="contours"
# Normal map
OPTIONS="$(pwd)/opentopomap_options"
STYLEFILE="$(pwd)/style/opentopomap"
OUTPUT="output/otm-$COUNTRY.img"
TYP="opentopomap"

pushd style/typ > /dev/null

java -jar $MKGMAPJAR --family-id=35 $TYP.txt
TYPFILE="$(pwd)/$TYP.typ"

popd > /dev/null

java -jar $MKGMAPJAR -c $OPTIONS --style-file=$STYLEFILE \
    --precomp-sea=$SEA --area-name=oceania \
    --country-name=newzealand --country-abbr=nz \
    --output-dir=output --bounds=$BOUNDS $DATA $TYPFILE

# optional: give map a useful name:
mv output/gmapsupp.img $OUTPUT
