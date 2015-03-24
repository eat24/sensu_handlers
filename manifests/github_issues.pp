# == Class: sensu_handlers::github_issues
#
# Sensu handler to open and close github issues for you.
#
class sensu_handlers::github_issues inherits sensu_handlers {

  package { 'octokit': provider => sensu_gem, } ->
  sensu::handler { 'github_issues':
    type    => 'pipe',
    source  => 'puppet:///modules/sensu_handlers/github_issues.rb',
    config  => {
      teams        => $teams,
      username     => $github_username,
      access_token => $github_access_token,
    },
  }

}
