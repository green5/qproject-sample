WP=/home/green/public_html/wp
NAME=qproject-sample
OUT=$(WP)/wp-content/plugins/$(NAME)
VERSION=$(shell grep Version: plug.php | cut -d " " -f 2)
VERSION=$(shell bash -c 'printf "1-%(%Y%m%d-%H)T" -1')
PWD=$(shell realpath .)
BACK=$(PWD)/../backup

TESTDIR=/tmp/test
DATADIR=$(OUT)/data
LOCALDB=$(DATADIR)/local.db

HXFLAGS+=-cp ../std -D use_rtti_doc
#HXFLAGS+=-debug
HXFLAGS+=--php-prefix X -D rot
HXFLAGS+=-D TEST -D LOCALDB=sqlite:$(LOCALDB) -D TagNoCache

hx=$(shell find . ../std -name *.hx)

all: pre $(OUT) $(OUT)/index.php $(OUT)/index.js $(OUT)/info.json files $(LOCALDB)

pre:
	@mkdir -p $(TESTDIR)

test: $(LOCALDB) ptest jtest

ptest: all $(LOCALDB) $(OUT)/index.php  
	php $(OUT)/index.php test

jtest: all $(LOCALDB) $(OUT)/index.js
	js -debug -e "window={isCli:true}" -f $(OUT)/index.js #rhino-js

files: $(OUT) ../ext/ plugin-updates/
	@rsync -va *.php *.txt $(OUT) 1>/dev/null
	@rsync -va plugin-updates/ $(OUT)/plugin-updates/ 1>/dev/null
	@rsync -va ../ext/ $(OUT)/ext/ 1>/dev/null

db $(LOCALDB): localdb.sql Makefile hxqp/LocalDB.hx $(OUT)/index.php
	@mkdir -p $(DATADIR)
	rm -f $(LOCALDB)
	sqlite3 $(LOCALDB) <localdb.sql
	chmod 777 $(DATADIR) $(LOCALDB)
	php $(OUT)/index.php db	

zip: 
	@mkdir -p $(BACK)
	zip -rq $(BACK)/$(NAME)-$(VERSION)-src.zip ./ 
	cd ..; zip -rq $(BACK)/$(NAME)-$(VERSION)-std.zip std/
	cd ..; zip -rq $(BACK)/$(NAME)-$(VERSION)-ext.zip ext/
	cd $(OUT)/..; zip -rq $(PWD)/$(NAME)-$(VERSION)-php.zip $(NAME)/

clean:
	rm -rf $(OUT)

$(OUT):
	mkdir -p $(OUT)

$(OUT)/index.php: $(hx) Makefile
	haxe3 -main hxqp.Main -php $(OUT) $(HXFLAGS)

$(OUT)/index.js: $(hx) Makefile
	haxe3 -main hxqp.Main -js $(OUT)/index.js $(HXFLAGS)

$(OUT)/info.json: info.sh plug.php
	bash info.sh plug.php $(OUT)/info.json	

sources:
	@echo $(hx)

tabs: $(hx)
	@for x in $?; do t=$$x.1; sed -e 's/^  /\t/g' $$x >$$t; diff -q $$x $$t; mv $$t $$x; done

