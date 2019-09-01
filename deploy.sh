#!/bin/bash
# prepare
ports=(`seq 6379 100 6879`)
docker_net=redis-net
template=redis.conf.template
for port in ${ports[*]}
do
	mkdir -p ${port}/data;
	PORT=${port} envsubst < ${template} > ${port}/redis.conf;
done

# create redis
docker network create ${docker_net}
for port in ${ports[@]}
do
	docker run -d --rm -ti \
		-v `pwd`/${port}/redis.conf:/usr/local/etc/redis/redis.conf \
		-v `pwd`/${port}/data:/data \
		--net ${docker_net} \
		--name redis-${port} \
		redis redis-server /usr/local/etc/redis/redis.conf
done

# start replaction
docker_ips=(`docker inspect redis-net | grep IPv4Address | grep -oP '\d+\.\d+\.\d+\.\d'|sort`)
instances=''
for ((index=0; index<${#docker_ips[@]}; ++index));
do
	instances="${instances} ${docker_ips[$index]}:${ports[$index]}"
done
docker exec -ti redis-${ports[0]} sh -c "redis-cli --cluster create ${instances} --cluster-replicas 1"
