# == Class: sensu_handlers::pagerduty
#
# Sensu handler for communicating with Pagerduty
#
class sensu_handlers::pagerduty (
  $dependencies = {
    'redphone' => { provider => $gem_provider },
  }
) inherits sensu_handlers {

  create_resources(
    package,
    $dependencies,
    { before => Sensu::Handler['pagerduty'] }
  )

  sensu::filter { 'page_filter':
    attributes => { 'check' => { 'page' => true } },
  } ->
  sensu::handler { 'pagerduty':
    type    => 'pipe',
    source  => 'puppet:///modules/sensu_handlers/pagerduty.rb',
    config  => {
      teams => $teams,
    },
    filters => [ 'page_filter' ],
  }

}
