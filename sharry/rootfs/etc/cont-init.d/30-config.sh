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
for var in $(bashio::config '1_conf_overrides|keys'); do
    property=$(bashio::config "1_conf_overrides[${var}].property")
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
    if bashio::config.is_empty '3_local_db'; then
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
if ! bashio::config.is_empty '5_remote_db_host'; then
    bashio::log.debug 'Setting up remote database.'
    bashio::config.require '4_remote_db_type' "'5_remote_db_host' is specified"
    bashio::config.require '9_remote_db_database' "'5_remote_db_host' is specified"
    bashio::config.require '7_remote_db_username' "'5_remote_db_host' is specified"
    bashio::config.require '8_remote_db_password' "'5_remote_db_host' is specified"
    bashio::config.require '6_remote_db_port' "'5_remote_db_host' is specified"

    host=$(bashio::config '5_remote_db_host')
    port=$(bashio::config '6_remote_db_port')
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
if bashio::config.true '10_copy_db'; then
    if  bashio::config.is_empty '11_copy_db_source'; then
        bashio::log.fatal
        bashio::log.fatal 'Copy-File is enabled but no source is defined.'
        bashio::log.fatal
        bashio::exit.nok
    elif
        bashio::config.is_empty '12_copy_db_target'; then
        bashio::log.fatal
        bashio::log.fatal 'Copy-File is enabled but no target is defined.'
        bashio::log.fatal
        bashio::exit.nok
    elif
        bashio::config.equals '11_copy_db_source' "$(bashio::config '12_copy_db_target')"; then
        bashio::log.fatal
        bashio::log.fatal 'Copy-File is enabled but source and target are same.'
        bashio::log.fatal
        bashio::exit.nok
    elif
        bashio::config.equals '11_copy_db_source' 'filesystem'; then
        if bashio::config.is_empty '3_local_db'; then
            bashio::log.fatal
            bashio::log.fatal 'Sharry is copy from local db but directory is not defined'
            bashio::log.fatal
            bashio::exit.nok
        fi
    elif
        bashio::config.equals '12_copy_db_target' 'filesystem'; then
        if bashio::config.is_empty '3_local_db'; then
            bashio::log.fatal
            bashio::log.fatal 'Sharry is copy to local db but directory is not defined'
            bashio::log.fatal
            bashio::exit.nok
        fi
    fi
fi
