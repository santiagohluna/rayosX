#!/usr/bin/bash

# Inicialización de variables.

opt=0

# Definición de funciones.

function run_nupipeline {
    echo -e "\nEjecutando nupipeline.\n"
    #nupipeline indir=/home/shluna/Proyectos/RX/objetos/rtcru/observaciones/nustar/30901002002/ steminputs=nu30901002002 outdir =./out saacalc=3 saamode=strict tentacle=yes clobber=yes
    echo -e "\n¡Listo! Seleccionar regiones con ds9.\n"
}

function run_nuproducts {
    while [[ $opt -ne 4 ]]
    do

    echo -e "\nOpciones de nuproducts\n====================== \n\t1. Background sin stray light.\n\t2. Stray light como background.\n\t3. Stray light como fuente.\n\t4. Volver al menú principal."
    read op

        if [[ $op -eq 1 ]]
        then
            echo -e "\nEjecutar nuproducts considerando el fondo sin stray light.\n"
            #nuproducts srcregionfile=./out/srcA.reg bkgregionfile=./out/bckA.reg indir=./out outdir=./products_rtcru_back_A instrument=FPMA steminputs=nu30901002002 stemout=src_bck_A bkgextract=yes clobber=yes
            echo -e "\n¡Listo!\n"
        elif [[ $op -eq 2 ]]
        then
            echo -e "\nEjecutar nuproducts considerando la stray light como background.\n"
            #nuproducts srcregionfile=./out/srcA.reg bkgregionfile=./out/SLA.reg indir=./out outdir=./products_rtcru_SL_A instrument=FPMA steminputs=nu30901002002 stemout=src_SL_A bkgextract=yes clobber=yes
            echo -e "\n¡Listo!\n"
        elif [[ $op -eq 3 ]]
        then
            echo -e "\nEjecutar nuproducts considerando la straylight como fuente.\n"
            #nuproducts srcregionfile=./out/SLA.reg bkgregionfile=./out/bckA.reg indir=./out outdir=./products_SL_back_A instrument=FPMA steminputs=nu30901002002 stemout=SL_bck_A bkgextract=yes clobber=yes
            echo -e "\n¡Listo!\n"
        elif [[ $op -eq 4 ]]
        then
            break
        else
            echo -e "\nError en el parámetro de opción. Debe ingresar 1, 2, 3 o 4.\n"
        fi

    done
}

# Menú de opciones.

clear

while [[ $opt -ne 3 ]]
do
    echo -e "\n========================================================"
    echo -e "Script para ejecutar análisis de observaciones de NuSTAR"
    echo      "========================================================"
    echo -e "\nMenú principal\n============== \n\t1. Ejecutar nupipeline.\n\t2. Ejecutar nuproducts.\n\t3. Salir."
    read opt
    if [[ $opt -eq 1 ]]
    then
        run_nupipeline
    elif [[ $opt -eq 2 ]]
    then
        run_nuproducts 
    elif [[ $opt -eq 3 ]]
    then
        break
    else
        echo "Debe ingresar 1, 2 o 3."
    fi
done
