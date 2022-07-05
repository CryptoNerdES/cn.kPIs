USER := 
HOSTNAME :=

install-node:
	scp -r ./install/prerequisites.sh ${USER}@${HOSTNAME}:/tmp
	ssh ${USER}@${HOSTNAME} /tmp/prerequisites.sh

install-master:
	scp -r ./install/kPis-master.sh ${USER}@${HOSTNAME}:/tmp
	ssh ${USER}@${HOSTNAME} /tmp/kPis-master.sh