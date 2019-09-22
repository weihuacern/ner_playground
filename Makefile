HIDE:=@
CP = $(HIDE)cp
MKDIR = $(HIDE)mkdir
RM = $(HIDE)rm
MV = $(HIDE)mv

VENV := $(shell pwd)/build
PWD = $(shell pwd)
FDBUTIL := ./app
TARGET=$(PWD)/target

PROTOAPPDIR := ./app/protoutils
PROTOSRCBASE := ./protos
PROTOSRCLIST := $(shell find ./${PROTOSRCBASE}/* -maxdepth 1 -type d | rev | cut -d '/' -f1 | rev)

## all                    : Compile all the modules
##                          modules: ner
all: prep ner

## venv                   : Prepare virtualenv
venv:
	$(HIDE)virtualenv -p python3 $(VENV) > /dev/null 2>&1
	$(HIDE)$(VENV)/bin/pip3 install --upgrade pip > /dev/null 2>&1
	$(HIDE)$(VENV)/bin/pip3 install pylint --upgrade > /dev/null 2>&1
	$(HIDE)$(VENV)/bin/pip3 install -r requirements.txt > /dev/null 2>&1

## prep                   : Do the preparation for the compile work
prep:
	$(MKDIR) -p out
	$(MKDIR) -p $(TARGET)
	$(RM) -rf out/*

## ner_pylint      : Pylint check for ner module
ner_pylint:
	$(HIDE)pushd ./app > /dev/null 2>&1 ;$(VENV)/bin/pylint -j4 --rcfile=../pylint.conf --reports=n --output-format=colorized --msg-template='{path}:{line}: [{msg_id}({symbol}), {obj}] {msg}' *; \
        if [ $$? != 0 ]; then popd; exit -1; fi;popd > /dev/null 2>&1

## proto_python           : Compile protocol buffer for python
proto_python:
	$(foreach PROTOSRC, $(PROTOSRCLIST), protoc -I=${PROTOSRCBASE}/${PROTOSRC} --python_out=${PROTOAPPDIR} ${PROTOSRCBASE}/${PROTOSRC}/*.proto &&) true

## ner             : Fake database with PII
ner: proto_python ner_pylint
	rm -rf out/*
	cp -rf $(FDBUTIL) out/. && \
	python3 -m zipapp out -m "app.ner_entry:entry" -o $(TARGET)/ner.pyz; \
	rm -rf out/app

## test            : Run test programs
test:
	python3 app/test/test_pii_factory.py

help: Makefile
	@sed -n 's/^##//p' $<

## clean                  : Delete all the object files and executables
clean: 
	$(HIDE)find . -name '*.pyc' | xargs rm -f
	$(HIDE)find . -name '*.pyz' | xargs rm -f
	$(HIDE)find . -name '*~' | xargs rm -f
	$(HIDE)find . -name '__pycache__' | xargs rm -rf
	$(RM) -rf ${PROTOAPPDIR}/*pb2.py
	$(RM) -rf out

.PHONY: help all clean test prep proto_python ner ner_pylint
