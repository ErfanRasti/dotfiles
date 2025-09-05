#!/bin/bash

waypaper --restore

pkill waybar
waybar &

spicetify apply
