#
# Description:
#   Simple robot to provide communication with F5 iControl declarative interfaces via the F5 iWorkflow platform
#   Maintainer:
#   @npearce
#   http://github/com/npearce
#
# Notes:
#   Tested against iWorkflow v2.2.0 on AWS
#   Running on Docker container/alpine linux
#

module.exports = (robot) ->

  iapps = require "../iApps/iApps.json" # iApps and Service Templates available to install.
  DEBUG = false # [true|false] enable per '*.coffee' file.
  OPTIONS = rejectUnauthorized: false # ignore HTTPS reqiuest self-signed certs notices/errors

  robot.respond /create user (.*) (.*)/i, (res) ->

    IWF_ADDR = robot.brain.get('IWF_ADDR')
    IWF_USERNAME = robot.brain.get('IWF_USERNAME')
    IWF_TOKEN = robot.brain.get('IWF_TOKEN')
    IWF_ROLE = robot.brain.get('IWF_ROLE')

    IWF_NEW_USERNAME = res.match[1]
    IWF_NEW_USER_PASS = res.match[2]

    if IWF_ROLE is "Administrator"

      post_data = JSON.stringify({
        name: IWF_NEW_USERNAME,
        displayName: IWF_NEW_USERNAME,
        password: IWF_NEW_USER_PASS
      })

      if DEBUG then console.log "post_data: #{post_data}"

# /mgmt/shared/authz/users

      # Perform the POST to authn/login
      robot.http("https://#{IWF_ADDR}/mgmt/shared/authz/users/", OPTIONS)
        .headers('X-F5-Auth-Token': IWF_TOKEN, 'Accept': "application/json")
        .post(post_data) (err, resp, body) ->

          # Handle error
          if err
            res.reply "Encountered an error :( #{err}"
            return

          if resp.statusCode isnt 200
            if DEBUG
              console.log "resp.statusCode: #{resp.statusCode} - #{resp.statusMessage}"
              console.log "body.code: #{body.code} body.message: #{body.message} "
            jp_body = JSON.parse body
            res.reply "Something went wrong :( #{jp_body.code} - #{jp_body.message}"
            return
          else
            res.reply "Status: #{resp.statusCode} - #{resp.statusMessage}"
            if DEBUG then console.log "body: #{body}"
