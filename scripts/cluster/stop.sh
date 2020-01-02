#!/bin/bash
ps aux | grep "[a]bbr$1" | awk '{print $2}' | xargs sudo kill
echo "cluster stopped"
