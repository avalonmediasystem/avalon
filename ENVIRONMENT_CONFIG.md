# Configuring Avalon Using Environment Variables
Most of Avalon's configuration settings can be replaced by environment variables. The following is a list of files and the variables that serve the same functions.

## Configuration Files and Equivalent Environment Variables 
* `avalon.yml`: (*NOTE*: If `avalon.yml` exists, it will be used and the following variables ignored)
  * `APP_NAME`
  * `BASE_URL`: Base URL for the Avalon server
  * `DROPBOX_PATH`: Base path for Avalon dropbox
  * `DROPBOX_URI`: Base URI for Avalon dropbox
  * `FEDORA_NAMESPACE`: Fedora PID prefix
  * `MEDIAINFO_PATH`
  * Streaming server settings:
    * `STREAM_BASE`
    * `STREAM_SERVER`: `adobe`, `wowza`, or `generic`
    * `STREAM_TOKEN_TTL`
    * `STREAM_RTMP_BASE`
    * `STREAM_HTTP_BASE`
    * `STREAM_DEFAULT_QUALITY`
  * `SYSTEM_GROUPS`
  * `MASTER_FILE_STRATEGY`: `delete`, `move`, or `none`
  * `MASTER_FILE_PATH`: If strategy is `move`
  * `FFMPEG_PATH`: Path to `ffmpeg` binary
  * `CONTROLLED_VOCABULARY`: Path to controlled vocabulary file
  * Outgoing email addresses for comments, notifications, and support:
    * `EMAIL_COMMENTS`
    * `EMAIL_NOTIFICATION`
    * `EMAIL_SUPPORT`
    * `SMTP_ADDRESS`
  * SMTP settings for outgoing email:
    * `SMTP_PORT`
    * `SMTP_DOMAIN`
    * `SMTP_USER_NAME`
    * `SMTP_PASSWORD`
    * `SMTP_AUTHENTICATION`
    * `SMTP_ENABLE_STARTTLS_AUTO`
    * `SMTP_OPENSSL_VERIFY_MODE`
  * To import bib records via SRU, use the following settings:
    * `SRU_URL`
    * `SRU_QUERY`
    * `SRU_NAMESPACE`
  * To import bib records via Z39.50, use the following settings:
    * `Z3950_HOST`
    * `Z3950_PORT`
    * `Z3950_DATABASE`
    * `Z3950_ATTRIBUTE`
* `authentication.yml`:
  * `LTI_AUTH_KEY`: The `key` half of the LTI OAuth pair
  * `LTI_AUTH_SECRET`: The `secret` half of the LTI OAuth pair
* `database.yml`:
  * `DATABASE_URL`: A URL describing the database connection Avalon should use (see [Configuring a Database](http://edgeguides.rubyonrails.org/configuring.html#configuring-a-database) in the Rails Configuration Guide)
* `fedora.yml`:
  * `FEDORA_URL`: The URL and credentials of the Avalon Fedora server (e.g., `http://fedoraAdmin:fedoraAdmin@localhost:8983/fedora`)
* `matterhorn.yml`:
  * `MATTERHORN_URL`: The URL and credentials of the Matterhorn service interface (e.g., `http://matterhorn_system_account:CHANGE_ME@localhost:8080/`)
* `secrets.yml`:
  * `SECRET_KEY_BASE`
* `solr.yml`:
  * `SOLR_URL`: The URL of the Avalon Solr core (e.g., `http://localhost:8983/solr/avalon`)

## Implementation Note

Due to the manner in which certain components are initialized, the order of precedence is inconsistent. The process works as follows:

  * If `avalon.yml` exists, its values will be used and associated environment variables ignored.
  * If `database.yml` exists, it will be loaded and `DATABASE_URL` ignored.
  * If `FEDORA_URL`, `SOLR_URL`, or `MATTERHORN_URL` exists, its value will be used and the corresponding `fedora.yml`, `solr.yml`, or `matterhorn.yml` ignored.
  * If `SECRET_KEY_BASE` exists, it will be used instead of the value in `secrets.yml`.
