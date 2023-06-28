all: lint

sync-from-ns2:
	scp -O root@ns2:/root/bin/toggle-smart-plug-pwr.sh bin/toggle-smart-plug-pwr.sh
sync-to-ns2:
	scp -O bin/toggle-smart-plug-pwr.sh root@ns2:/root/bin/toggle-smart-plug-pwr.sh
lint:
	shellcheck --shell=dash bin/toggle-smart-plug-pwr.sh
