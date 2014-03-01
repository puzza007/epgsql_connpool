DEPS_DIR=deps
DEPS=$(DEPS_DIR)/epgsql
DEPS_EBIN=$(patsubst %,%/ebin,$(DEPS))
ERL=erl

.PHONY: compile
compile: $(DEPS)
	@rebar compile

$(DEPS):
	@rebar get-deps

.PHONY: clean
clean:
	@rebar clean

.PHONY: distclean
distclean: clean
	@rebar delete-deps

.PHONY: eunit check
check: eunit
eunit: compile
	@rebar skip_deps=true eunit

.PHONY: xref
xref: compile
	@rebar skip_deps=true xref

.PHONY: docs
docs:
	@rebar skip_deps=true doc

.PHONY: dev
dev: compile
	@$(ERL) -name epgsql@127.0.0.1 -pa ebin $(DEPS_EBIN) \
	    -eval 'application:start(crypto)' \
	    -eval 'application:start(public_key)' \
	    -eval 'application:start(ssl)' \
	    -eval 'application:start(epgsql)' \
	    -eval 'application:start(epgsql_connpool)'

APPS=kernel stdlib sasl erts ssl tools os_mon runtime_tools crypto inets \
	xmerl webtool snmp public_key mnesia eunit syntax_tools compiler
COMBO_PLT=.combo_dialyzer_plt

.PHONY: check_plt
check_plt: $(COMBO_PLT)
	@dialyzer --check_plt --plt $(COMBO_PLT) --apps $(APPS)

$(COMBO_PLT):
	@dialyzer --build_plt --output_plt $(COMBO_PLT) --apps $(APPS)

.PHONY: dialyzer
dialyzer: compile $(COMBO_PLT)
	@dialyzer -Wno_return --plt $(COMBO_PLT) ebin $(DEPS_EBIN) | \
	    fgrep -v -f ./dialyzer.ignore-warnings
