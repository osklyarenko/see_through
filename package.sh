#!/bin/bash

VERSION=$(git rev-parse --short HEAD)

zip -r see_through_$VERSION * -x ".git" -x ".idea" -x "package.sh"