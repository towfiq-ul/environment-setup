#!/bin/bash
shopt -s dotglob
sudo du -sh -- * | sort -h -r
