#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Home Assistant Add-on: Sharry
# This validates config, creates the database and sets up app files/folders
# ==============================================================================
declare host
declare port
declare property



# --- ADDITIONAL VALIDATION ---
for var in $(bashio::config 'conf_overrides|keys'); do
    property=$(bashio::config "conf_overrides[${var}].property")
    if [[ ${property} =~ ^sharry[.]restserver[.]backend[.]auth[.]command ]]; then
        bashio::log.fatal
        bashio::log.fatal "Your config attempts to override settings in the command"
        bashio::log.fatal "auth module. This is not allowed as it would break the ability"
        bashio::log.fatal "of this addon to authenticate users with Home Assistant."
        bashio::log.fatal
        bashio::log.fatal "Remove any conf_overrides you have added with a property"
        bashio::log.fatal "matching this pattern and try again:"
        bashio::log.fatal "'sharry.restserver.backend.auth.command.*'"
        bashio::log.fatal
        bashio::exit.nok

    elif [[ ${property} =~ ^sharry[.]restserver[.]backend[.]files ]]; then
        bashio::log.fatal
        bashio::log.fatal "Your config attempts to override settings in the files module."
        bashio::log.fatal "This is not allowed as it could break the addon."
        bashio::log.fatal
        bashio::log.fatal "Remove any conf_overrides you have added with a property"
        bashio::log.fatal "matching this pattern and try again:"
        bashio::log.fatal "'sharry.restserver.backend.files.*'"
        bashio::log.fatal
        bashio::exit.nok

    # Prevent break of Nginx reverse proxy
    elif [[ ${property} =~ ^sharry[.]restserver[.]bind ]]; then
        bashio::log.fatal
        bashio::log.fatal "Your config attempts to override settings in the bind module."
        bashio::log.fatal "This is not allowed as it could break the addon."
        bashio::log.fatal
        bashio::log.fatal "Remove any conf_overrides you have added with a property"
        bashio::log.fatal "matching this pattern and try again:"
        bashio::log.fatal "'sharry.restserver.bind.*'"
        bashio::log.fatal
        bashio::exit.nok

    # Warning when changing chunk-size because of Nginx client_max_body_size parameter
    elif [[ ${property} =~ ^sharry[.]restserver[.]webapp[.]chunk-size ]]; then
        bashio::log.fatal
        bashio::log.fatal "WARNING"
        bashio::log.fatal "Your config attempts to override settings in the CHUNK-SIZE value."
        bashio::log.fatal "Do NOT exceed the value of 100M."
        bashio::log.fatal "This is not allowed as it could break the addon."
        bashio::log.fatal
        bashio::log.fatal
    fi
done




# --- SET UP DEFAULT STORE ---
# Be sure that at least one database is activated
if bashio::config.equals 'defaultStore' 'database'; then
    bashio::log.info "Sharry is using the Maria database storage"
    bashio::log.notice "Please ensure that addon is included in your backups"
    bashio::log.notice "Uninstalling the Maria DB addon will also remove Sharry's data"
else
    bashio::log.info "Maria database storage is not actived..."
    bashio::log.notice "If you want use Maria database for data storage please"
    bashio::log.notice "set DefaultStore to database in Add-on config"
fi
if bashio::config.equals 'defaultStore' 'filesystem'; then
    if bashio::config.is_empty 'local_db'; then
        bashio::log.fatal
        bashio::log.fatal 'Sharry is using local db but directory is not defined'
        bashio::log.fatal
        bashio::exit.nok
    fi
    bashio::log.info "Sharry is using the Local database storage"
    bashio::log.notice "Please ensure that directory is included in your backups"
    bashio::log.notice "Uninstalling the Maria DB addon will also remove Sharry's data"
else bashio::log.info "Local database storage is not actived..."
    bashio::log.notice "If you want use local database storage please"
    bashio::log.notice "set DefaultStore to filesystem in Add-on config"
fi




# --- SET UP DATABASE ---
# Use user-provided remote db
if ! bashio::config.is_empty 'remote_db_host'; then
    bashio::log.debug 'Setting up remote database.'
    bashio::config.require 'remote_db_type' "'remote_db_host' is specified"
    bashio::config.require 'remote_db_database' "'remote_db_host' is specified"
    bashio::config.require 'remote_db_username' "'remote_db_host' is specified"
    bashio::config.require 'remote_db_password' "'remote_db_host' is specified"
    bashio::config.require 'remote_db_port' "'remote_db_host' is specified"

    host=$(bashio::config 'remote_db_host')
    port=$(bashio::config 'remote_db_port')
    bashio::log.info "Using remote database at ${host}:${port}"

    # Wait until db is available.
    connected=false
    for _ in {1..30}; do
        if nc -w1 "${host}" "${port}" > /dev/null 2>&1; then
            connected=true
            break
        fi
        sleep 1
    done

    if [ $connected = false ]; then
        bashio::log.fatal
        bashio::log.fatal "Cannot connect to remote database at ${host}:${port}!"
        bashio::log.fatal "Exiting after retrying for 30 seconds."
        bashio::log.fatal
        bashio::log.fatal "Please ensure the config is set correctly and"
        bashio::log.fatal "the database is available at the specified host and port."
        bashio::log.fatal
        bashio::exit.nok
    fi
fi




# --- SET UP COPY-FILE ---
if bashio::config.true 'copy_db'; then
    if  bashio::config.is_empty 'copy_db_source'; then
        bashio::log.fatal
        bashio::log.fatal 'Copy-File is enabled but no source is defined.'
        bashio::log.fatal
        bashio::exit.nok
    elif
        bashio::config.is_empty 'copy_db_target'; then
        bashio::log.fatal
        bashio::log.fatal 'Copy-File is enabled but no target is defined.'
        bashio::log.fatal
        bashio::exit.nok
    elif
        bashio::config.equals 'copy_db_source' "$(bashio::config 'copy_db_target')"; then
        bashio::log.fatal
        bashio::log.fatal 'Copy-File is enabled but source and target are same.'
        bashio::log.fatal
        bashio::exit.nok
    elif
        bashio::config.equals 'copy_db_source' 'filesystem'; then
        if bashio::config.is_empty 'local_db'; then
            bashio::log.fatal
            bashio::log.fatal 'Sharry is copy from local db but directory is not defined'
            bashio::log.fatal
            bashio::exit.nok
        fi
    elif
        bashio::config.equals 'copy_db_target' 'filesystem'; then
        if bashio::config.is_empty 'local_db'; then
            bashio::log.fatal
            bashio::log.fatal 'Sharry is copy to local db but directory is not defined'
            bashio::log.fatal
            bashio::exit.nok
        fi
    fi
fi
