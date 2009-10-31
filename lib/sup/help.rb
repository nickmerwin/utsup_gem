module Sup
    HELP_TEXT = <<-eos
  =======================================
  UtSup Client v.#{VERSION}
  by Nick Merwin (Lemur Heavy Industries)
  =======================================

  === Examples:
    sup setup

    cd /some-project/ && sup init
    sup in "whatup"
    sup
    sup "just chillin"
    sup out "later"

  === Commands:

    help                      # show this message
    version                   # show version

    setup <api_key>           # initializes global config file

    init <project name>       # initilize current directory

    "<message>"               # send status update for current project
    nm                        # destroy your last supdate

    (no command)              # get all user's current status
    all                       # get all user's statuses over the past day

    in "<message>"            # check in to project
    out "<message>"           # check out of project

    users                     # get list of users in company
    <user name>               # get last day's worth of status updates from specified user

    push                      # triggers a git push + update

    start                     # starts differ
    stop                      # stops differ
  eos
end