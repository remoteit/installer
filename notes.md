# Tasks

- [x] Download connectd, place in "./assets"
- [ ] Download SChannel, place in "./assets"
- [ ] Download specific connectd git tag
- [ ] Build all platform binaries
- [ ] Have assets built automatically on git tag and PRs

## Service startup options

Systemd - `connectd.service` `/lib/systemd/system` (bulk/auto)
Sys-V - `/etc.init.d` (bulk/auto)
Cron - `sudo crontab -l` (interactive)
Upstart

https://unix.stackexchange.com/questions/121654/convenient-way-to-check-if-system-is-using-systemd-or-sysvinit-in-bash
