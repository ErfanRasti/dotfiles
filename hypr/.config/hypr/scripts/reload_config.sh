#!/bin/bash

waypaper --restore
killall waybar
waybar &
spicetify apply
