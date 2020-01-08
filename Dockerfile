FROM python:3.8.0-buster
RUN pip install python-cinderclient
RUN mkdir /root/backups
WORKDIR /root/backups
COPY create_snapshots.sh .
RUN chmod a+x create_snapshots.sh
ENTRYPOINT ["./create_snapshots.sh"]
CMD ["kubernetes.io/created-for/pvc/name", ""]
