# ns2.lan scripts

Various administrative scripts for one of my routers that
runs on OpenWRT.

## usage

```shell
cd "~/Projects"
git clone "https://github.com/syn-net/ns2.lan_scripts.git" ns2.lan_scripts.git
cd ns2.lan_scripts.git
cp -av "bin/.env.dist" "bin/.env"
vim "bin/.env"
```

```shell
bin/toggle-smart-plug-pwr.sh <HOST> <query|toggle|on|off>
```
