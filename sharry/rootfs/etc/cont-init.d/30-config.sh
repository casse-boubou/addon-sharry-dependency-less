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
    fi
done




# --- SET UP DEFAULT STORE ---
# Be sure that at least one database is activated
if bashio::config.equals 'DefaultStore' 'database'; then
    if ! bashio::config.true 'use_maria_db'; then
        bashio::log.fatal
        bashio::log.fatal "Default-store is set to database but use Maria db is not activated"
        bashio::log.fatal
        bashio::exit.nok
    fi
elif bashio::config.equals 'DefaultStore' 'filesystem'; then
    if ! bashio::config.true 'use_local_db'; then
        bashio::log.fatal
        bashio::log.fatal "Default-store is set to filesystem but use local db is not activated"
        bashio::log.fatal
        bashio::exit.nok
    fi
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

# Maria_DB
if bashio::config.true 'use_maria_db'; then
    bashio::log.info "Sharry is using the Maria database"
else bashio::log.info "Maria database is not actived..."
    bashio::log.notice "If you want use Maria database please"
    bashio::log.notice "set use_maria_db to True in config"
fi

# Local_DB
if bashio::config.true 'use_local_db'; then
    bashio::log.info "Sharry is using the Local database"
    if bashio::config.is_empty 'local_db'; then
        bashio::log.fatal
        bashio::log.fatal 'Sharry is using local db but directory is not defined'
        bashio::log.fatal
        bashio::exit.nok
    fi
    bashio::log.notice "Sharry is using the Local database"
    bashio::log.notice "Please ensure that directory is included in your backups"
else bashio::log.info "Local database is not actived..."
    bashio::log.notice "If you want use local database please"
    bashio::log.notice "set use_local_db to True in config"
fi




# --- SET UP COPY-FILE ---
if bashio::config.true 'copy_db'; then
    if ! bashio::config.true 'use_maria_db'; then
        bashio::log.fatal
        bashio::log.fatal 'Copy-File is enabled but use Maria db is not activated'
        bashio::log.fatal
        bashio::exit.nok
    elif
        ! bashio::config.true 'use_local_db'; then
        bashio::log.fatal
        bashio::log.fatal 'Copy-File is enabled but use Local db is not activated'
        bashio::log.fatal
        bashio::exit.nok
    elif
        bashio::config.is_empty 'copy_db_source'; then
        bashio::log.fatal
        bashio::log.fatal 'Copy-File is enabled but no source is defined'
        bashio::log.fatal
        bashio::exit.nok
    elif
        bashio::config.is_empty 'copy_db_target'; then
        bashio::log.fatal
        bashio::log.fatal 'Copy-File is enabled but no target is defined'
        bashio::log.fatal
        bashio::exit.nok
    fi
fi
