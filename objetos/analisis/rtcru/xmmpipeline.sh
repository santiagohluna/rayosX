#!/bin/bash

echo ' '
echo 'XMM Pipeline - Script para el reprocesamiento de observaciones de XMM-Newton'
echo ' '

heainit
sasinit

echo ' '
echo 'Ingrese el camino hacia el directorio donde se encuentran las observaciones:'
read path

export SAS_ODF=path
echo ' '

echo 'Las observaciones se encuentran en:'
echo $SAS_ODF

# echo '\nEjecutar tarea cifbuild\n'

# cifbuild

# echo 'Ejecutar tarea odfingest'

# export SAS_CCF=ccf.cif

# odfingest

# echo 'Ejecutar la tarea emproc'

# export SAS_ODF=*.SAS

# emproc

# echo 'Ejecutar la tarea epproc'

# epproc
