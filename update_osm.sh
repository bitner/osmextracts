#!/bin/bash
export PATH=$PATH:/usr/local/bin:/usr/bin
date
d=`date '+%Y%m%d'`
cd /workspace/osm/planet
minsize=4000000000
size=`du -b planet.us.osm.pbf | cut -f 1`
if [[ -s planet.us.osm.pbf && `du -b planet.us.osm.pbf | cut -f 1` -ge $minsize ]]
then
    time osmupdate --day --hour -v planet.us.osm.pbf planet-updated.us.osm.pbf -B=united_states.poly
    if [[ -s planet-updated.us.osm.pbf && `du -b planet-updated.us.osm.pbf | cut -f 1` -ge $minsize ]]
    then
        [ -s planet-2.us.osm.pbf ] && rm planet-2.us.osm.pbf
        [ -s planet-1.us.osm.pbf ] && mv planet-1.us.osm.pbf planet-2.us.osm.pbf
        [ -s planet.us.osm.pbf ] && mv planet.us.osm.pbf planet-1.us.osm.pbf
        mv planet-updated.us.osm.pbf planet.us.osm.pbf
        #OSM_CONFIG_FILE=osmconf.ini ogr2ogr -t_srs "EPSG:4326" -overwrite -where 'amenity="fire_station"' fire_stations.shp planet.us.osm.pbf points
        #OSM_CONFIG_FILE=osmconf.ini ogr2ogr -f "GeoJSON" -s_srs "EPSG:3857" -t_srs "EPSG:4326" -overwrite -where 'amenity="fire_station"' fire_stations.geojson planet.us.osm.pbf points
        #OSM_CONFIG_FILE=osmconf.ini ogr2ogr -t_srs "EPSG:4326" -overwrite -where 'amenity="hospital"' hospitals.shp planet.us.osm.pbf points
        #OSM_CONFIG_FILE=osmconf.ini ogr2ogr -f "GeoJSON" -s_srs "EPSG:3857" -t_srs "EPSG:4326" -overwrite -where 'amenity="hospital"' hospitals.geojson planet.us.osm.pbf points
	osmconvert planet.us.osm.pbf --drop-author -B=minnesota.poly --complete-ways -o=mn.pbf
	osmconvert planet.us.osm.pbf -B=bwcaw_3k.poly --complete-ways -o=bwcaw_$d.pbf
	OSM_CONFIG_FILE=osmconf.ini ogr2ogr -t_srs "EPSG:4326" -overwrite -where "other_tags ilike '%portage%'" portages.shp bwcaw_$d.pbf lines
	OSM_CONFIG_FILE=osmconf.ini ogr2ogr -t_srs "EPSG:4326" -overwrite -where "other_tags ilike '%camp%'" campsites.shp bwcaw_$d.pbf points
	
	rm *.geojson
	for i in *.shp; do
	 base=`basename $i`
	 ogr2ogr -f GeoJSON $base.geojson $i
        done
        git commit -a -m "Update Data for $d"
        git push origin master
    else
        echo "There was a problem with the processing"
    fi
fi

