# v0.1.34
* UI cleanup

# v0.1.32
* [fix] Check for method alias prior to applying

# v0.1.30
* [fix] Properly auto-update account on job detail loading
* [fix] Resolve route edit issues with configuration setup

# v0.1.28
* Use product init helpers on startup
* Only perform jobs route lookup when required (removes persisting flash)
* Update navigation name for Repositories to Sources

# v0.1.26
* [fix] Provide full namespace to route model in custom callback

# v0.1.24
* Add status routing for jobs

# v0.1.22
* Only render graph on summary if data is available
* Always show last five jobs (remove time constraint on lookup)

# v0.1.20
* Styling and view updates
* Fix redirect on pipeline create

# v0.1.18
* Update views

# v0.1.16
* Support auto route generation without plan requirement

# v0.1.14
* Slice git SHA to reduce busting table constraints

# v0.1.12
* Always generate alpha prefixed string for graph DOM ID
* If job instance available, auto set route

# v0.1.10
* Fetch last job to include account id

# v0.1.8
* Force set account and route when specific job is provided

# v0.1.6
* Include graph generation setup delay

# v0.1.4
* Fix graph displays
* Add prebuilt route support
* Import payload matcher admin controls
* Validate accessibility of destination prior to redirect

# v0.1.2
* Fix redirect errors in callbacks
* Add support for prebuilt routes via service groups
* Confirm prior to deletion of routes
* Update naming on UI side (pipeline)

# v0.1.0
* Initial release
