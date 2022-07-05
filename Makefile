USER := "cryptonerd"
HOSTNAME := "Gimli"


install-node:
	scp -r ./install/prerequisites.sh ${USER}@${HOSTNAME}:/tmp
	ssh ${USER}@${HOSTNAME} /tmp/prerequisites.sh ${HOSTNAME}

install-master:
	scp -r ./install/kPIs-master.sh ${USER}@${HOSTNAME}:/tmp
	ssh ${USER}@${HOSTNAME} /tmp/kPIs-master.sh