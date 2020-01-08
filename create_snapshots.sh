#!/bin/bash
key=$1
pvc_name=$2
minimun_snapshots=$3
sufix=$4

volumes=($(cinder list | awk '{ print $2 }' | tail -n +4))
for volume in "${volumes[@]}"
do
  pvc=$(cinder metadata-show $volume | grep "\s$1\s" | awk '{ print $4}')
  if [ -z "$2" ] || [ "$pvc_name" = "$pvc" ]; then
    cinder snapshot-create $volume --force True --name $pvc$sufix$(date -u +%FT%T)
  fi
done

if [ -z "$minimun_snapshots" ]; then
  exit 0
fi

snapshots=($(cinder snapshot-list --sort created_at:asc | grep "$2$sufix" | awk '{ print $2}'))
snapshots_total=${#snapshots[@]}
snapshots_to_remove=$(($snapshots_total - $3))

if [ "$snapshots_to_remove" -gt "0" ]; then
  for (( i=0; i<$snapshots_to_remove; i++))
  do
    echo "Deleting snapshot ${snapshots[i]} ..."
    cinder snapshot-delete ${snapshots[i]}
    echo "Deleted."
  done
fi
