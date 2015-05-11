class RouteRepositoriesController < RepositoriesController

  def set_product
    unless(session[:route_id].blank?)
      params[:namespace] = 'routes'
      super
      @namespace = 'pipeline'
      @base = @account.routes_dataset.where(:id => session[:route_id]).first
    end
    unless(@base)
      raise 'No pipeline currently selected!'
    end
  end

  def commit_hook_url
    File.join(
      Rails.application.config.settings.get(:fission, :rest_endpoint_ssl),
      'v1/github', @base.name
    )
  end

end
