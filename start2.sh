./rancher-compose --project-name api-gateway \
--url http://192.168.99.100:8080/v1/projects/1a5 \
--access-key FBAB038DE14B30A9A7DE \
--secret-key jPbprS4Fd2zDByeGsE9SBnvJGGK6EVyu41mQvaVs \
-f docker-compose.yml \
--verbose up \
-d --force-upgrade \
--confirm-upgrade
