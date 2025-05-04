#! /usr/bin/env bash
scp -r /mnt/tlvol/pipeline/ {{ local_user }}@{{ local_ip }}:{{ local_data_dir }}

# scp -r /mnt/tlvol/pipeline/ wischmcj@192.168.0.105:/media/penguaman/code/code/ActualCode/TreeLearn/remote_data/collective
