#!/bin/sh
cd ../proto
protoc -o../service/proto/all.bytes *.proto
cd ..
python tools/genProtoId.py --output=./service/proto/message_define.bytes ./proto/*.proto
