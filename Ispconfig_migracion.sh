#!/bin/bash

# Solicita al usuario que ingrese las variables necesarias
read -p "Ingresa la IP del servidor origen: " SERVER_ORIGEN
read -p "Ingresa la IP del servidor destino: " SERVER_DESTINO
read -p "Ingresa el puerto SSH (presiona enter para usar el puerto 22 por defecto): " SSH_PORT
read -p "Ingresa la ruta al directorio de respaldo: " DIR_RESPALDO
read -p "Ingresa el nombre de usuario para el servidor origen: " USER_ORIGEN
read -s -p "Ingresa la contraseña para el servidor origen: " PASS_ORIGEN
echo
read -p "Ingresa el nombre de usuario para el servidor destino: " USER_DESTINO
read -s -p "Ingresa la contraseña para el servidor destino: " PASS_DESTINO
echo

# Usa el puerto 22 como predeterminado si el usuario no ingresa un puerto
SSH_PORT=${SSH_PORT:-22}

# Funciones para realizar las operaciones de migración
function backup_databases {
    # Respaldar todas las bases de datos en el servidor origen
    sshpass -p $PASS_ORIGEN ssh -p $SSH_PORT $USER_ORIGEN@$SERVER_ORIGEN "mysqldump --all-databases > $DIR_RESPALDO/all-databases.sql"
}

function backup_config_files {
    # Respaldar los archivos de configuración y los sitios web en el servidor origen
    sshpass -p $PASS_ORIGEN ssh -p $SSH_PORT $USER_ORIGEN@$SERVER_ORIGEN "tar -czvf $DIR_RESPALDO/config-files.tar.gz /etc /var/www"
}

function backup_email_data {
    # Respaldar los datos de correo electrónico en el servidor origen
    sshpass -p $PASS_ORIGEN ssh -p $SSH_PORT $USER_ORIGEN@$SERVER_ORIGEN "tar -czvf $DIR_RESPALDO/mail-data.tar.gz /var/vmail"
}

function transfer_backups {
    # Transferir los respaldos al servidor de destino
    sshpass -p $PASS_ORIGEN scp -P $SSH_PORT $DIR_RESPALDO/* $USER_DESTINO@$SERVER_DESTINO:$DIR_RESPALDO
}

function restore_backups {
    # Restaurar los respaldos en el servidor de destino
    sshpass -p $PASS_DESTINO ssh -p $SSH_PORT $USER_DESTINO@$SERVER_DESTINO "tar -xzvf $DIR_RESPALDO/config-files.tar.gz -C / && mysql < $DIR_RESPALDO/all-databases.sql && tar -xzvf $DIR_RESPALDO/mail-data.tar.gz -C /"
}

# Menú para elegir la operación a realizar
while :
do
    clear
    echo "--------------------------------------"
    echo " Menu de Migración ISPConfig"
    echo "--------------------------------------"
    echo "[1] Respaldo de Bases de Datos"
    echo "[2] Respaldo de Archivos de Configuración y Sitios Web"
    echo "[3] Respaldo de Datos de Correo Electrónico"
    echo "[4] Transferir Respaldos al Servidor Destino"
    echo "[5] Restaurar Respaldos en el Servidor Destino"
    echo "[q] Salir"
    echo "--------------------------------------"
    read -p "Elige una opción [1-5 or q]: " option

    case $option in
        1)
            backup_databases
            ;;
        2)
            backup_config_files
            ;;
        3)
            backup_email_data
            ;;
        4)
            transfer_backups
            ;;
        5)
            restore_backups
            ;;
        q)
            exit 0
            ;;
        *)
            echo "Opción incorrecta. Intenta de nuevo..."
            ;;
    esac
    read -p "Presiona [Enter] para continuar..."
done
