## Kubernetes snapshot volume for cinder

I use this docker to create snapshots in a remote cinder cluster from a kubernetes schedule and rotate the backups.

The next comand creates an snapshot of every volume in the cinder cluster:

```docker run --env OS_USERNAME=<user_name> --env OS_PASSWORD=<password> --env OS_TENANT_NAME=<project_name> --env OS_AUTH_URL=<api_url> --env OS_VOLUME_API_VERSION=3 --env OS_REGION_NAME=<region> --env OS_PROJECT_ID=<project_id> kubernetes-cinder-snapshot```

With the next one creates an snapshot of a specific volume with a metadata key 'kubernetes.io/created-for/pvc/name' and value 'website-content-pvc':
 
```docker run --env OS_USERNAME=<user_name> --env OS_PASSWORD=<password> --env OS_TENANT_NAME=<project_name> --env OS_AUTH_URL=<api_url> --env OS_VOLUME_API_VERSION=3 --env OS_REGION_NAME=<region> --env OS_PROJECT_ID=<project_id> kubernetes-cinder-snapshot kubernetes.io/created-for/pvc/name website-content-pvc```

And only allow a maximum of 5 snapshots for this volume, deleting the old ones:

```docker run --env OS_USERNAME=<user_name> --env OS_PASSWORD=<password> --env OS_TENANT_NAME=<project_name> --env OS_AUTH_URL=<api_url> --env OS_VOLUME_API_VERSION=3 --env OS_REGION_NAME=<region> --env OS_PROJECT_ID=<project_id> kubernetes-cinder-snapshot kubernetes.io/created-for/pvc/name website-content-pvc 5```

Add a suffix to snapshots:

```docker run --env OS_USERNAME=<user_name> --env OS_PASSWORD=<password> --env OS_TENANT_NAME=<project_name> --env OS_AUTH_URL=<api_url> --env OS_VOLUME_API_VERSION=3 --env OS_REGION_NAME=<region> --env OS_PROJECT_ID=<project_id> kubernetes-cinder-snapshot kubernetes.io/created-for/pvc/name website-content-pvc 5 -daily-```


Create a cron job in kubernetes to create a pv snapshot every day and keep the last 7 snapshots:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: cinder-secret
data:
  OS_USERNAME: <user_name>
  OS_PASSWORD: <password>
  OS_TENANT_NAME: <project_name>
  OS_AUTH_URL: <api_url>
  OS_VOLUME_API_VERSION: '3'
  OS_REGION_NAME: <region>
  OS_PROJECT_ID: <project_id>
---
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: erp-daily-backup
spec:
  schedule: "0 1 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: erp-daily-backup
            image: tlmak0/kubernetes-cinder-snapshot
            args:
            - kubernetes.io/created-for/pvc/name
            - erp-pvc
            - '7'
            - -daily-
            envFrom:
            - configMapRef:
                name: cinder-secret
          restartPolicy: OnFailure
```

# Development 

```docker build -t kubernetes-cinder-snapshot . && docker run -ti --env OS_USERNAME=<user_name> --env OS_PASSWORD=<password> --env OS_TENANT_NAME=<project_name> --env OS_AUTH_URL=<api_url> --env OS_VOLUME_API_VERSION=3 --env OS_REGION_NAME=<region> --env OS_PROJECT_ID=<project_id> -v $(pwd):/root/backups --entrypoint bash kubernetes-cinder-snapshot```

Then can edit local file ```create_snapshot.sh``` and run ```./create_snapshots.sh kubernetes.io/created-for/pvc/name website-content-pvc 4```
