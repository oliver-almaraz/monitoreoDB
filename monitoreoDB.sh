# Funciones para monitoreo esencial de una base de datos Oracle
# que reside en un ambiente Linux y a la que se puede acceder
# por medio de SQLPlus. Se asume el uso de ASM.
# Estas funciones están pensadas para ser llamadas desde otro
# script.
# En estas funciones, un argumento es mandatorio: usr@ip para
# la sesión SSH.
# El segundo argumento SSH_OPTIONS es opcional.

# https://github.com/oliver-almaraz/monitoreoDB

function estadoPMON_SMON(){
    if [[ -z $1 ]]; then echo 'Pasar usr@ip como argumento' > /dev/stderr; return 1; fi
    LOGIN=$1
    SSH_OPTIONS=$2
    printf "Estado del PMON y SMON:\n"
    ssh ${SSH_OPTIONS:-'-xq'} ${LOGIN} "ps -fea | awk '\$8 ~ /^ora_[ps]mon_/{print \$8 \" up\"; FOUND++} \
        END{if (FOUND < 2) print \"Alerta: revisar estado de la DB\"}'"
}

function diskgroupsASM(){
    if [[ -z $1 ]]; then echo 'Pasar usr@ip como argumento' > /dev/stderr; return 1; fi
    LOGIN=$1
    SSH_OPTIONS=$2
    TABLE='v\$asm_diskgroup' # La única manera de tener '$' escapado en este nivel

    # Si el LOGIN es como root hay que cambiar usuario a oracle
    if [[ ${LOGIN} =~ root@|ROOT@ ]]; then SU="su - oracle -c '"; LAST="'"; fi

    printf "\nEstado de los Diskgroups ASM:\n"
    ssh ${SSH_OPTIONS:-'-xq'} ${LOGIN} "${SU} sqlplus -s / as sysdba << EOF
    whenever sqlerror exit sql.sqlcode;
    select name, total_mb, free_mb, free_mb/total_mb*100 as percentage_free from ${TABLE};
    exit;
EOF${LAST}" # EOF must be at ^
}

function openMode(){
    if [[ -z $1 ]]; then echo 'Pasar usr@ip como argumento' > /dev/stderr; return 1; fi
    LOGIN=$1
    SSH_OPTIONS=$2
    TABLE='v\$database' # La única manera de tener '$' escapado en este nivel

    # Si el LOGIN es como root hay que cambiar usuario a oracle
    if [[ ${LOGIN} =~ root@|ROOT@ ]]; then SU="su - oracle -c '"; LAST="'"; fi

    ssh ${SSH_OPTIONS:-'-xq'} ${LOGIN} "${SU} sqlplus -s / as sysdba << EOF
    whenever sqlerror exit sql.sqlcode;
    select open_mode from $TABLE;
    exit;
EOF${LAST}" # EOF must be at ^
}
