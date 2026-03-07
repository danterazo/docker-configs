#!/bin/bash

# only run for interactive shells
case $- in
	*i*) ;;
	*) return ;;
esac

# run fastfetch if available
if command -f fastfetch >/dev/null 2>&1; then
	fastfetch
fi
