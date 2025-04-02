#!/bin/bash

ltrace -f -e "*mkl*" python ./torch_mm.py > ltrace.log
