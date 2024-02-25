#!/usr/bin/env bash 
# 
# Bootstrap flux cluster 

flux bootstrap github \
    --owner=jrn90 \
    --repository=homelab \
    --branch=main \
    --personal \
    --path=cluster/heimat
