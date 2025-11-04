# st - simple terminal
# See LICENSE file for copyright and license details.
.POSIX:

include config.mk

SRC = st.c x.c
OBJ = $(SRC:.c=.o)

all: options st

options:
	@echo st build options:
	@echo "CFLAGS  = $(STCFLAGS)"
	@echo "LDFLAGS = $(STLDFLAGS)"
	@echo "CC      = $(CC)"

config.h:
	cp config.def.h config.h

.c.o:
	$(CC) $(STCFLAGS) -c $<

st.o: config.h st.h win.h
x.o: arg.h config.h st.h win.h

$(OBJ): config.h config.mk

st: $(OBJ)
	$(CC) -o $@ $(OBJ) $(STLDFLAGS)

clean:
	rm -f st $(OBJ) st-$(VERSION).tar.gz config.h

dist: clean
	mkdir -p st-$(VERSION)
	cp -R FAQ LEGACY TODO LICENSE Makefile README config.mk\
		config.def.h st.info st.1 arg.h st.h win.h $(SRC)\
		st-$(VERSION)
	tar -cf - st-$(VERSION) | gzip > st-$(VERSION).tar.gz
	rm -rf st-$(VERSION)

install: st
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp -f st $(DESTDIR)$(PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/st
	mkdir -p $(DESTDIR)$(MANPREFIX)/man1
	sed "s/VERSION/$(VERSION)/g" < st.1 > $(DESTDIR)$(MANPREFIX)/man1/st.1
	chmod 644 $(DESTDIR)$(MANPREFIX)/man1/st.1
	mkdir -p $(DESTDIR)/usr/share/applications
	cp -f st.desktop $(DESTDIR)/usr/share/applications
	chmod 644 $(DESTDIR)/usr/share/applications/st.desktop
	mkdir -p $(DESTDIR)/usr/share/pixmaps
	cp -f assets/st-48x48.png $(DESTDIR)/usr/share/pixmaps/st.png
	chmod 644 $(DESTDIR)/usr/share/pixmaps/st.png
	@echo "Installing icons in multiple sizes..."
	mkdir -p $(DESTDIR)/usr/share/icons/hicolor/16x16/apps
	convert assets/suckless-small-logo.png -resize 16x16 -background transparent -gravity center -extent 16x16 $(DESTDIR)/usr/share/icons/hicolor/16x16/apps/st.png
	chmod 644 $(DESTDIR)/usr/share/icons/hicolor/16x16/apps/st.png
	mkdir -p $(DESTDIR)/usr/share/icons/hicolor/32x32/apps
	convert assets/suckless-small-logo.png -resize 32x32 -background transparent -gravity center -extent 32x32 $(DESTDIR)/usr/share/icons/hicolor/32x32/apps/st.png
	chmod 644 $(DESTDIR)/usr/share/icons/hicolor/32x32/apps/st.png
	mkdir -p $(DESTDIR)/usr/share/icons/hicolor/48x48/apps
	cp -f assets/st-48x48.png $(DESTDIR)/usr/share/icons/hicolor/48x48/apps/st.png
	chmod 644 $(DESTDIR)/usr/share/icons/hicolor/48x48/apps/st.png
	mkdir -p $(DESTDIR)/usr/share/icons/hicolor/128x128/apps
	convert assets/suckless-small-logo.png -resize 128x128 -background transparent -gravity center -extent 128x128 $(DESTDIR)/usr/share/icons/hicolor/128x128/apps/st.png
	chmod 644 $(DESTDIR)/usr/share/icons/hicolor/128x128/apps/st.png
	@echo "Updating caches..."
	update-desktop-database $(DESTDIR)/usr/share/applications 2>/dev/null || true
	gtk-update-icon-cache -f -t $(DESTDIR)/usr/share/icons/hicolor 2>/dev/null || true
	@echo "Installation complete. Please run 'xfce4-panel -r' to refresh your panel."
	tic -sx st.info
	@echo Please see the README file regarding the terminfo entry of st.

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/st
	rm -f $(DESTDIR)$(MANPREFIX)/man1/st.1
	rm -f $(DESTDIR)/usr/share/applications/st.desktop
	rm -f $(DESTDIR)/usr/share/pixmaps/st.png
	rm -f $(DESTDIR)/usr/share/icons/hicolor/16x16/apps/st.png
	rm -f $(DESTDIR)/usr/share/icons/hicolor/32x32/apps/st.png
	rm -f $(DESTDIR)/usr/share/icons/hicolor/48x48/apps/st.png
	rm -f $(DESTDIR)/usr/share/icons/hicolor/128x128/apps/st.png

.PHONY: all options clean dist install uninstall
