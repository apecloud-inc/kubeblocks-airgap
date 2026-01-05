#!/bin/bash

DIRECTORY="kb-charts/kubeblocks-image-list"
FILES_TO_READ=("kubeblocks-enterprise.txt" "ape-local-csi-driver.txt" "cert-manager.txt" "clickhouse.txt" "damengdb-arm.txt" "elasticsearch-arm.txt" "ingress-nginx.txt" "kafka.txt" "gaussdb.txt" "influxdb.txt" "kubebench.txt" "metallb.txt" "metrics-server.txt" "minio.txt" "mongodb.txt" "mssql.txt" "mysql-arm.txt" "oceanbase.txt" "postgres-operator.txt" "postgresql.txt" "qdrant.txt" "rabbitmq.txt" "redis.txt" "rocketmq.txt" "starrocks.txt" "tidb.txt" "vastbase.txt" "zookeeper.txt" "victoria-metrics.txt" "spiderpool.txt"  )
OUTPUT_FILE="kubeblocks-image-list.txt"
> "$OUTPUT_FILE"
for file_name in "${FILES_TO_READ[@]}"; do
    file_path="$DIRECTORY/$file_name"
    if [ ! -f "$file_path" ]; then
        echo "File $file_name not found in the directory."
        exit 1
    fi
    echo "Appending $file_name to $OUTPUT_FILE"
    cat "$file_path" >> "$OUTPUT_FILE"
done