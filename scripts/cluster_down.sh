#!/usr/bin/env bash
set -euo pipfail
k3d cluster delete dev || true
