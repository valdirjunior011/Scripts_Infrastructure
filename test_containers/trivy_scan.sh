#!/bin/bash

trivy image valdirjunior011/linuxtips-giropops-senhas:4.0 -q --exit-code 1 | sed -n '/^Total:/,$p' | head -n 1 > giropops_trivy_output.txt
trivy image cgr.dev/chainguard/redis -q --exit-code 1 | sed -n '/^Total:/,$p' | head -n 1 > redis_trivy_output.txt
