all: lint

sync-from-ns2:
	scp -O root@ns2:/root/bin/toggle-smart-plug-pwr.sh ./bin/toggle-smart-plug-pwr.sh
	scp -O root@ns2:/root/bin/.env ./bin/.env
sync-to-ns2:
	scp -O bin/toggle-smart-plug-pwr.sh root@ns2:/root/bin/toggle-smart-plug-pwr.sh
	scp -O bin/.env root@ns2:/root/bin/.env
lint:
	shellcheck --external-sources --shell=dash bin/toggle-smart-plug-pwr.sh
