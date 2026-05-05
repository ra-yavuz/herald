PREFIX ?= /usr
BINDIR = $(DESTDIR)$(PREFIX)/bin
DATADIR = $(DESTDIR)$(PREFIX)/share/herald
DOCDIR  = $(DESTDIR)$(PREFIX)/share/doc/herald
UNITDIR = $(DESTDIR)/lib/systemd/system

.PHONY: all install uninstall lint check deb clean

all:
	@echo "Run 'make install' (or 'make deb' / 'make lint')."

deb:
	bash scripts/build-deb.sh

install:
	install -d $(BINDIR) $(DATADIR) $(DOCDIR) $(UNITDIR) $(DESTDIR)/etc/profile.d $(DESTDIR)/etc/update-motd.d
	install -m 0755 bin/herald                            $(BINDIR)/herald
	install -m 0644 lib/herald/quotes.json                $(DATADIR)/quotes.json
	install -m 0644 profile.d/50-herald.sh                $(DESTDIR)/etc/profile.d/50-herald.sh
	install -m 0644 update-motd.d/95-herald               $(DESTDIR)/etc/update-motd.d/95-herald
	install -m 0644 systemd/herald-refresh.service        $(UNITDIR)/herald-refresh.service
	install -m 0644 systemd/herald-refresh.timer          $(UNITDIR)/herald-refresh.timer
	install -m 0644 README.md                             $(DOCDIR)/README.md
	install -m 0644 LICENSE                               $(DOCDIR)/LICENSE

uninstall:
	rm -f $(BINDIR)/herald
	rm -rf $(DATADIR)
	rm -f $(DESTDIR)/etc/profile.d/50-herald.sh
	rm -f $(DESTDIR)/etc/update-motd.d/95-herald
	rm -f $(UNITDIR)/herald-refresh.service $(UNITDIR)/herald-refresh.timer
	rm -rf $(DOCDIR)

lint:
	shellcheck -x bin/herald scripts/build-deb.sh scripts/get.sh debian/postinst debian/postrm install.sh profile.d/50-herald.sh update-motd.d/95-herald

check: lint

clean:
	rm -rf dist
